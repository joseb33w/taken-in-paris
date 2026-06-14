# TAKEN IN PARIS — build plan

A third-person stealth-thriller built in **Godot 4.6.3**, exported to mobile web
(Compatibility / WebGL2, `nothreads`). You are Étienne Vasseur, a disgraced French
intelligence operative with 72 hours to find your kidnapped daughter Margaux by
"reading Paris itself."

## Goal
A genuinely fun, tense, mobile-playable campaign of **five Parisian districts**,
unlock-gated, spined by a **CASE DOSSIER**: sneak past guard vision-cones, hold-interact
to collect glowing clue nodes, interrogate informants in free-form conversation, then
physically link two clue cards into a **deduction** that unlocks the next district. The
finale changes based on how many clues were actually solved. Cloud-saved per account so
progress + evidence survive across devices, plus a global fastest-rescue leaderboard.

## Levels (each a distinct stealth mechanic, compact for mobile pacing)
1. **Montmartre Rooftops** — tail the kidnapper without entering vision cones; deduce -> L2.
2. **Marais Bistro** — lift evidence past the waiter's cone, interrogate him; deduce -> L3.
3. **Louvre After Hours** — dodge camera cones + laser tripwires; crack a cipher -> L4.
4. **Catacombs** — reach Margaux; it's a trap, alarm trips, timed sprint out; escape -> L5.
5. **Eiffel Tower Finale** — the mastermind + a helicopter-spool-up clock. Outcome scales
   with clues solved.

## Cast (bespoke, Meshy, rigged idle/walk/run)
- spy_hero.glb (empty hands), daughter.glb, henchman.glb. Guards: reskinned `realistic`
  library humanoids.

## Custom landmarks (Meshy)
- eiffel_tower.glb (skyline + finale), haussmann_cafe.glb (Marais).

## Backend — Supabase (per-app prefix usr_nmexs7bytxq2_taken_in_paris)
- Instant email+password accounts via app_register RPC (confirmation is on; anon is off).
- `<prefix>_progress` (own rows) + `<prefix>_scores` (public read, write-own leaderboard).
- Frontend talks to Supabase through web/bridge.js via JavaScriptBridge.

## Verification
- Backend: Node + supabase-js round-trip (schema, RLS +/-, leaderboard) with real creds.
- Game: Godot web export -> smoke verifier + targeted §6 checks; independent QA pass.

## Out of scope (this session)
- Shooting/combat — hero stays empty-handed by design ("hand him a pistol later").
- A continue session polishes UI; save + leaderboard wiring stays stable for it.
