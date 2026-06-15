extends Node
## Global state, the CASE DOSSIER spine, and cloud persistence (Supabase via Net/bridge.js).
## Autoloaded as "Game"; survives level scene reloads so progress + evidence persist.

signal auth_changed
signal evidence_changed
signal progress_changed
signal toast(text: String)

# --- account / session ---
var signed_in := false
var guest := false
var user_id := ""
var codename := "Operative"

# --- campaign progress (mirrors the Supabase row) ---
var furthest_level := 1            # highest district unlocked (1..5)
var clues_solved := 0              # number of CORRECT deductions made (drives the finale)
var evidence: Array = []           # collected clue cards: {id,level,title,text,kind}
var current_level := 1
var flags: Dictionary = {}         # exploration state: notes read, locks picked, leads, trust

# --- rescue timer (global fastest-rescue leaderboard) ---
var run_elapsed := 0.0
var timing_active := false
var _last_save_ms := 0
var _solved_levels: Dictionary = {}

# Canonical clue cards. Level scripts place nodes by id; the dossier reads title/text here.
const CLUES := {
	"l1_van":     {"level": 1, "kind": "physical",  "title": "Black Van Plate",   "text": "A black panel van, plate 75-MGX-13, idling by the funicular."},
	"l1_route":   {"level": 1, "kind": "physical",  "title": "Rooftop Chalk Route","text": "Chalk arrows across the zinc roofs, heading east toward the Marais."},
	"l1_receipt": {"level": 1, "kind": "physical",  "title": "Burner Receipt",     "text": "A torn receipt: 'Le Corbeau, rue des Rosiers - 23h.'"},
	"l2_ledger":  {"level": 2, "kind": "physical",  "title": "Bistro Ledger",      "text": "A reservation under 'Corbeau': the private cellar, party of three."},
	"l2_matches": {"level": 2, "kind": "physical",  "title": "Staff Matchbook",    "text": "A matchbook from the Louvre staff bar - Porte des Lions."},
	"l2_waiter":  {"level": 2, "kind": "testimony", "title": "Waiter's Testimony",  "text": "The 'guests' arrived with crates marked DCRI archives, bound for the Louvre after closing."},
	"l3_cipher_a":{"level": 3, "kind": "cipher",    "title": "Cipher Fragment A",  "text": "Numbers etched under a frame: 6-13-24, repeating."},
	"l3_cipher_b":{"level": 3, "kind": "cipher",    "title": "Gallery Map",        "text": "A floor map with one room circled: Egyptian antiquities, sub-level."},
	"l3_keycard": {"level": 3, "kind": "physical",  "title": "Service Keycard",    "text": "Catacombs maintenance access - Denfert-Rochereau."},
	"l4_note":    {"level": 4, "kind": "physical",  "title": "Ransom Note",        "text": "'She is already moved. Eiffel, pilier sud, 02h. Come alone.' - it reads like bait."},
	"l4_charge":  {"level": 4, "kind": "physical",  "title": "Shaped Charge",      "text": "Demolition charges wired to seal the tunnels. This was always a trap."},
	"l5_manifest":{"level": 5, "kind": "physical",  "title": "Flight Manifest",    "text": "A rotor-craft manifest: one passenger, wheels-up at 02h sharp."},
}

# Per-level deduction: linking these two cards cracks the case and opens the exit.
const DEDUCTIONS := {
	1: {"pair": ["l1_van", "l1_receipt"],     "title": "LEAD: the Marais bistro",   "text": "The van plate and the receipt put the handoff at Le Corbeau, rue des Rosiers."},
	2: {"pair": ["l2_matches", "l2_waiter"],  "title": "LEAD: the Louvre, after hours", "text": "The staff matchbook and the waiter's tip point to the Louvre, Porte des Lions."},
	3: {"pair": ["l3_cipher_a", "l3_cipher_b"], "title": "CIPHER CRACKED: the Catacombs", "text": "6-13-24 resolves to a depth and gallery: the route drops into the Catacombs at Denfert."},
	4: {"pair": ["l4_note", "l4_charge"],     "title": "LEAD: the Eiffel rendezvous","text": "The note and the charges: the catacombs were a kill-box. The real handoff is the Eiffel Tower, south pillar."},
}

const LEVELS := {
	1: {"key": "montmartre", "name": "Montmartre", "tagline": "Roam the square. Tail the crew. Don't be seen.", "script": "res://scripts/level1.gd"},
	2: {"key": "marais",     "name": "The Marais",  "tagline": "Le Corbeau. Lift the evidence. Make the waiter talk.", "script": "res://scripts/level2.gd"},
	3: {"key": "louvre",     "name": "Louvre After Hours",   "tagline": "Cameras and lasers. Crack the cipher.", "script": "res://scripts/level3.gd"},
	4: {"key": "catacombs",  "name": "The Catacombs",        "tagline": "A rescue that is a trap. Run before it seals.", "script": "res://scripts/level4.gd"},
	5: {"key": "eiffel",     "name": "Eiffel Tower Finale",  "tagline": "The mastermind. The clock. Margaux.", "script": "res://scripts/level5.gd"},
}

func _process(delta: float) -> void:
	if timing_active and not get_tree().paused:
		run_elapsed += delta

# ---------------------------------------------------------------- account

func try_resume() -> Dictionary:
	var r := await Net.request("session")
	if r.get("ok", false):
		var data: Variant = r.get("data")
		if data is Dictionary and data.has("user_id"):
			var d: Dictionary = data
			user_id = str(d.get("user_id", ""))
			codename = str(d.get("codename", "Operative"))
			signed_in = true
			guest = false
			await load_progress()
			auth_changed.emit()
			return {"ok": true}
	return {"ok": false}

func sign_up(email: String, password: String, name: String) -> Dictionary:
	var r := await Net.request("signUp", {"email": email, "password": password, "codename": name})
	if r.get("ok", false):
		var d: Dictionary = r.get("data", {}) if r.get("data") is Dictionary else {}
		user_id = str(d.get("user_id", ""))
		codename = name if name != "" else "Operative"
		signed_in = true
		guest = false
		await load_progress()
		auth_changed.emit()
	return r

func sign_in(email: String, password: String) -> Dictionary:
	var r := await Net.request("signIn", {"email": email, "password": password})
	if r.get("ok", false):
		var d: Dictionary = r.get("data", {}) if r.get("data") is Dictionary else {}
		user_id = str(d.get("user_id", ""))
		codename = str(d.get("codename", "Operative"))
		signed_in = true
		guest = false
		await load_progress()
		auth_changed.emit()
	return r

func play_as_guest() -> void:
	guest = true
	signed_in = false
	codename = "Guest"
	auth_changed.emit()

func sign_out() -> void:
	if Net.is_web():
		await Net.request("signOut")
	signed_in = false
	guest = false
	user_id = ""
	codename = "Operative"
	furthest_level = 1
	clues_solved = 0
	evidence = []
	flags = {}
	current_level = 1
	run_elapsed = 0.0
	auth_changed.emit()

# ---------------------------------------------------------------- persistence

func load_progress() -> void:
	var r := await Net.request("loadProgress")
	if r.get("ok", false) and r.get("data") is Dictionary:
		var d: Dictionary = r.get("data")
		furthest_level = clampi(int(d.get("furthest_level", 1)), 1, 5)
		clues_solved = maxi(0, int(d.get("clues_solved", 0)))
		var ev: Variant = d.get("evidence", [])
		if ev is Array:
			evidence = ev
		elif ev is String and ev != "":
			var parsed: Variant = JSON.parse_string(ev)
			evidence = parsed if parsed is Array else []
		var fl: Variant = d.get("flags", {})
		if fl is Dictionary:
			flags = fl
		elif fl is String and fl != "":
			var pf: Variant = JSON.parse_string(fl)
			flags = pf if pf is Dictionary else {}
		else:
			flags = {}
		progress_changed.emit()
		evidence_changed.emit()

func save_progress(force: bool = false) -> void:
	if guest or not signed_in:
		return
	var now := Time.get_ticks_msec()
	if not force and now - _last_save_ms < 1200:
		return
	_last_save_ms = now
	await Net.request("saveProgress", {
		"furthest_level": furthest_level,
		"clues_solved": clues_solved,
		"evidence": evidence,
		"flags": flags,
	})

func submit_score() -> void:
	if guest or not signed_in:
		return
	await Net.request("submitScore", {
		"codename": codename,
		"time_seconds": roundf(run_elapsed * 100.0) / 100.0,
		"clues_solved": clues_solved,
	})

func leaderboard() -> Array:
	var r := await Net.request("leaderboard", {"limit": 25})
	if r.get("ok", false) and r.get("data") is Array:
		return r.get("data")
	return []

# ---------------------------------------------------------------- dossier logic

func clue_def(id: String) -> Dictionary:
	return CLUES.get(id, {})

func has_clue(id: String) -> bool:
	for c in evidence:
		if c is Dictionary and str(c.get("id", "")) == id:
			return true
	return false

func add_clue(id: String) -> bool:
	if not CLUES.has(id) or has_clue(id):
		return false
	var def: Dictionary = CLUES[id]
	var card := {"id": id, "level": def.get("level", 0), "title": def.get("title", id), "text": def.get("text", ""), "kind": def.get("kind", "physical")}
	evidence.append(card)
	evidence_changed.emit()
	toast.emit("Evidence logged: " + str(def.get("title", id)))
	save_progress()
	return true

func deduction_solved(level: int) -> bool:
	if not DEDUCTIONS.has(level):
		return true
	return _solved_levels.has(level)

## Returns true if the linked pair cracks the current level's deduction.
func try_link(id_a: String, id_b: String, level: int) -> bool:
	if not DEDUCTIONS.has(level):
		return false
	var pair: Array = DEDUCTIONS[level]["pair"]
	var ok: bool = (str(id_a) == str(pair[0]) and str(id_b) == str(pair[1])) or (str(id_a) == str(pair[1]) and str(id_b) == str(pair[0]))
	if ok and not _solved_levels.has(level):
		_solved_levels[level] = true
		clues_solved += 1
		progress_changed.emit()
		save_progress(true)
	return ok

## Mark a level's deduction solved without the dossier (used by the catacombs' in-the-moment
## realization). Counts toward clues_solved, which drives the finale.
func force_solve(level: int) -> void:
	if DEDUCTIONS.has(level) and not _solved_levels.has(level):
		_solved_levels[level] = true
		clues_solved += 1
		progress_changed.emit()
		save_progress(true)

func unlock_level(level: int) -> void:
	if level > furthest_level:
		furthest_level = clampi(level, 1, 5)
		progress_changed.emit()
		save_progress(true)

func deduction_def(level: int) -> Dictionary:
	return DEDUCTIONS.get(level, {})

func clues_for_level(level: int) -> Array:
	var out: Array = []
	for id in CLUES:
		if int(CLUES[id]["level"]) == level:
			out.append(id)
	return out

# ---------------------------------------------------------------- exploration flags / leads

func set_flag(key: String, value: Variant = true) -> void:
	flags[key] = value
	progress_changed.emit()
	save_progress()

func has_flag(key: String) -> bool:
	return flags.has(key) and bool(flags[key])

func get_flag(key: String, default_value: Variant = null) -> Variant:
	return flags.get(key, default_value)

## Record a lead the player has uncovered by exploring (notes, photos, eavesdropping,
## picked locks). Drives the "investigative thoroughness" the finale acknowledges.
func add_lead(id: String) -> void:
	var raw: Variant = flags.get("leads", [])
	var arr: Array = raw if raw is Array else []
	if not arr.has(id):
		arr.append(id)
		flags["leads"] = arr
		progress_changed.emit()
		save_progress()

func leads_found() -> Array:
	var raw: Variant = flags.get("leads", [])
	return raw if raw is Array else []

func adjust_trust(npc: String, delta: int) -> void:
	var raw: Variant = flags.get("trust", {})
	var tr: Dictionary = raw if raw is Dictionary else {}
	tr[npc] = int(tr.get(npc, 0)) + delta
	flags["trust"] = tr
	save_progress()

func trust_of(npc: String) -> int:
	var raw: Variant = flags.get("trust", {})
	var tr: Dictionary = raw if raw is Dictionary else {}
	return int(tr.get(npc, 0))

func reset_run_timer() -> void:
	run_elapsed = 0.0
	timing_active = false

func format_time(sec: float) -> String:
	var total := int(sec)
	var m := total / 60
	var s := total % 60
	return "%02d:%02d" % [m, s]
