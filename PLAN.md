# TAKEN IN PARIS — expansion plan (round 2: "a living, explorable Paris")

Building on the shipped 5-district stealth campaign (PR #1). NOT a rewrite — the
`LevelBase` framework, `Game` spine, Supabase backend, LLM-NPC chat and dual-input
controller all stay; this round makes the world roamable, alive, audible and voiced.

## Goal
Turn each district from a single-objective corridor into a roamable, densely-dressed
Parisian neighborhood you investigate: streets full of props, NPCs you can walk up to and
TALK to (voiced, with subtitles), optional things to DO between objectives, a full
soundscape, and per-district lighting/mood — kept smooth on mobile web.

## Files to touch
- `export_presets.cfg` — enable `html/experimental_virtual_keyboard` so the mobile soft
  keyboard appears on the login fields (explicit user request).
- `scripts/game.gd` — exploration flags + leads persistence (Supabase `flags` jsonb).
- `scripts/audio.gd` (NEW, autoload `Audio`) — ambience beds, tension-reactive music,
  one-shot SFX pool; synthesized OGG assets under `audio/`.
- `scripts/voice.gd` (NEW, autoload `Voice`) + `web/bridge.js` — Web Speech TTS so NPC
  lines are SPOKEN, plus a subtitle bar.
- `scripts/dressing.gd` (NEW) — kk_city street-furniture / cars / trees dressing helpers.
- `scripts/note_node.gd`, `scripts/lock_minigame.gd`, `scripts/eavesdrop_zone.gd` (NEW) —
  optional activities: hidden clue notes, a lock-pick minigame, eavesdropping.
- `scripts/char_visual.gd` — talk/gesture/sit/lean locomotion states.
- `scripts/talk_npc.gd`, `scripts/chat_panel.gd` — voiced replies, ambient barks, seated/
  talking poses, richer roster wiring.
- `scripts/level_base.gd` — per-district environment mood + dressing + activity hooks.
- `scripts/level1..5.gd` — roamable layouts, dense dressing, full NPC casts, activities.
- `models/` — bespoke realistic rigged cast from Meshy + kk_city dressing; fetch_assets.sh.
- `supabase/migrations/0003_exploration.sql` — `flags jsonb` on the progress table.
- `audio/` (NEW) — synthesized ambience/music/SFX OGGs.

## Verification approach
- Backend: node + supabase-js round-trip — apply 0003, prove `flags` saves/loads, RLS
  +/- on progress & scores, leaderboard; clean up the test user.
- Game: Godot web export → smoke verifier + targeted checks (clip-resolution, player +
  NPC facing under driven movement, collision-vs-mesh, every trigger/activity fires,
  two-aspect mobile fill, NPC-chat contract + panel-opens headless, audio buses present,
  keyboard flag in the shipped artifact). Screenshot-critique each district's mood.
- Independent adversarial QA pass on the exported build.

## Out of scope (this round)
- Shooting/combat — Étienne stays empty-handed by design.
- Pre-recorded voice-acting — dialogue is spoken via the browser TTS engine + subtitles.
- New backend tables — exploration state rides on the existing progress row (`flags`).
