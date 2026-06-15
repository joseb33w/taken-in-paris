// TAKEN IN PARIS - Supabase bridge. Loaded after the supabase-js UMD CDN script.
// Exposes window.gogiCall(method, argsJson) -> request id, and window.gogiPoll(id) -> JSON
// string of {ok,data}/{ok,error} once resolved (GDScript polls it each frame).
// The anon/publishable key is safe in the client; the service-role key is NEVER here.
(function () {
  "use strict";
  var SUPABASE_URL = "https://xhhmxabftbyxrirvvihn.supabase.co";
  var SUPABASE_ANON = "sb_publishable_NZHoIxqqpSvVBP8MrLHCYA_gmg1AbN-";
  var PREFIX = "usr_nmexs7bytxq2_taken_in_paris";
  var T_PROGRESS = PREFIX + "_progress";
  var T_SCORES = PREFIX + "_scores";

  var client = null;
  function sb() {
    if (client) return client;
    if (!window.supabase || !window.supabase.createClient) {
      throw new Error("supabase sdk not loaded");
    }
    client = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON, {
      auth: { persistSession: true, autoRefreshToken: true }
    });
    return client;
  }

  async function currentUser() {
    var res = await sb().auth.getUser();
    return res && res.data && res.data.user ? res.data.user : null;
  }
  function codenameFromUser(u) {
    return (u && u.user_metadata && u.user_metadata.codename) ? u.user_metadata.codename : "Operative";
  }

  var handlers = {
    async session() {
      var res = await sb().auth.getSession();
      if (!res || !res.data || !res.data.session || !res.data.session.user) return null;
      var u = res.data.session.user;
      return { user_id: u.id, codename: codenameFromUser(u) };
    },
    async signUp(a) {
      var c = sb();
      // email confirmation is ON for this shared project, so use the server-side register
      // RPC (creates a pre-confirmed account), then sign in normally for an instant session.
      var reg = await c.rpc("app_register", {
        p_email: a.email, p_password: a.password, p_codename: a.codename || "Operative"
      });
      if (reg.error) throw new Error(reg.error.message);
      if (!reg.data || !reg.data.ok) {
        var err = (reg.data && reg.data.error) ? reg.data.error : "registration failed";
        if (err === "email_taken") throw new Error("That email is already registered - sign in instead.");
        if (err === "weak_password") throw new Error("Password must be at least 6 characters.");
        if (err === "invalid_email") throw new Error("Enter a valid email.");
        throw new Error(err);
      }
      var si = await c.auth.signInWithPassword({ email: a.email, password: a.password });
      if (si.error) throw new Error(si.error.message);
      return { user_id: si.data.user.id, codename: a.codename || "Operative" };
    },
    async signIn(a) {
      var res = await sb().auth.signInWithPassword({ email: a.email, password: a.password });
      if (res.error) throw new Error(res.error.message);
      return { user_id: res.data.user.id, codename: codenameFromUser(res.data.user) };
    },
    async signOut() { await sb().auth.signOut(); return true; },

    async loadProgress() {
      var u = await currentUser();
      if (!u) throw new Error("not signed in");
      var res = await sb().from(T_PROGRESS)
        .select("furthest_level,clues_solved,evidence,flags").eq("user_id", u.id).maybeSingle();
      if (res.error) throw new Error(res.error.message);
      if (!res.data) return { furthest_level: 1, clues_solved: 0, evidence: [], flags: {} };
      return res.data;
    },
    async saveProgress(a) {
      var u = await currentUser();
      if (!u) throw new Error("not signed in");
      var row = {
        user_id: u.id, furthest_level: a.furthest_level | 0,
        clues_solved: a.clues_solved | 0, evidence: a.evidence || [],
        flags: a.flags || {},
        updated_at: new Date().toISOString()
      };
      var res = await sb().from(T_PROGRESS).upsert(row, { onConflict: "user_id" });
      if (res.error) throw new Error(res.error.message);
      return true;
    },
    async submitScore(a) {
      var u = await currentUser();
      if (!u) throw new Error("not signed in");
      var existing = await sb().from(T_SCORES)
        .select("best_time_seconds").eq("user_id", u.id).maybeSingle();
      if (existing && existing.data && typeof existing.data.best_time_seconds === "number"
        && existing.data.best_time_seconds <= a.time_seconds) {
        return true;
      }
      var row = {
        user_id: u.id, codename: a.codename || "Operative",
        best_time_seconds: a.time_seconds, clues_solved: a.clues_solved | 0,
        updated_at: new Date().toISOString()
      };
      var res = await sb().from(T_SCORES).upsert(row, { onConflict: "user_id" });
      if (res.error) throw new Error(res.error.message);
      return true;
    },
    async leaderboard(a) {
      var res = await sb().from(T_SCORES)
        .select("codename,best_time_seconds,clues_solved")
        .order("best_time_seconds", { ascending: true })
        .limit((a && a.limit) ? a.limit : 25);
      if (res.error) throw new Error(res.error.message);
      return res.data || [];
    }
  };

  window.__gogiResults = {};
  window.__gogiNextId = 0;
  window.gogiCall = function (method, argsJson) {
    var id = ++window.__gogiNextId;
    var args = {};
    try { args = argsJson ? JSON.parse(argsJson) : {}; } catch (e) { args = {}; }
    (async function () {
      try {
        var fn = handlers[method];
        if (!fn) throw new Error("unknown method " + method);
        var data = await fn(args);
        window.__gogiResults[id] = JSON.stringify({ ok: true, data: data });
      } catch (e) {
        window.__gogiResults[id] = JSON.stringify({ ok: false, error: String(e && e.message ? e.message : e) });
      }
    })();
    return id;
  };
  window.gogiPoll = function (id) {
    var r = window.__gogiResults[id];
    if (r === undefined) return "";
    delete window.__gogiResults[id];
    return r;
  };

  // ---- Voiced dialogue (Web Speech API). GDScript calls window.gogiSpeak(text, profileJson)
  // so NPC lines are spoken aloud (a French voice when the device ships one).
  var __voices = [];
  function loadVoices() {
    try { __voices = (window.speechSynthesis && window.speechSynthesis.getVoices()) || []; } catch (e) { __voices = []; }
  }
  if (window.speechSynthesis) {
    loadVoices();
    try { window.speechSynthesis.onvoiceschanged = loadVoices; } catch (e) {}
  }
  function pickVoice(lang) {
    if (!__voices.length) loadVoices();
    var want = (lang || "fr").slice(0, 2).toLowerCase();
    for (var i = 0; i < __voices.length; i++) {
      var v = __voices[i];
      if (v.lang && v.lang.slice(0, 2).toLowerCase() === want) return v;
    }
    return __voices.length ? __voices[0] : null;
  }
  window.gogiSpeak = function (text, profileJson) {
    try {
      if (!window.speechSynthesis || !window.SpeechSynthesisUtterance) return 0;
      var p = {};
      try { p = profileJson ? JSON.parse(profileJson) : {}; } catch (e) { p = {}; }
      window.speechSynthesis.cancel();
      var u = new SpeechSynthesisUtterance(String(text || ""));
      u.rate = p.rate || 1.0;
      u.pitch = p.pitch || 1.0;
      u.volume = (p.volume != null) ? p.volume : 1.0;
      u.lang = p.lang || "fr-FR";
      var v = pickVoice(u.lang);
      if (v) u.voice = v;
      window.speechSynthesis.speak(u);
      return 1;
    } catch (e) { return 0; }
  };
  window.gogiStopSpeak = function () {
    try { if (window.speechSynthesis) window.speechSynthesis.cancel(); } catch (e) {}
    return 1;
  };
})();
