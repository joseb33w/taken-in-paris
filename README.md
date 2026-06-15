# TAKEN IN PARIS

A third-person **stealth-thriller** built in **Godot 4.6.3** for mobile web
(Compatibility / WebGL2, single-threaded `nothreads` export).

You are **Étienne Vasseur**, a disgraced French intelligence operative. Your daughter
**Margaux** has been taken and you have 72 hours before she is moved out of the country.
The only way to find her is to *read Paris itself* — so go and read it: each district is a
**living, roamable neighborhood**, not a corridor.

## Play
Open the preview link on a phone or desktop browser, tap to start, sign in (or play as a
guest), and work through five Parisian districts.

- **Move:** left thumb (on-screen joystick) / `WASD` / arrow keys.
- **Look:** drag the right side of the screen / hold left-mouse + move.
- **Sneak:** the crouch button / `Shift` — slower, quieter, harder to spot.
- **Interact:** the `[+]` button / `E` — hold to collect clue nodes; tap to talk, read a
  note, pick a lock, or photograph evidence.
- **Takedown:** the takedown button / `F` — silently neutralize a guard from close behind.
- **Dossier:** the case button / `Q` — review evidence and **link two clue cards** into the
  deduction that unlocks the next district.

## The living city
Every district is dressed as a real neighborhood — Haussmann blocks, streetlights, benches,
kiosks, parked cars, plane trees, café tables, market stalls, signage — and given its **own
light and mood**: a golden-evening Montmartre, a neon-night Marais, the cold marble of the
Louvre, candle-lit catacombs, a blue-night Eiffel plaza.

The streets are full of **Parisians you can walk up to and TALK to** — a café waiter, a
flower-seller, a busker, a nervous informant, a cop, kids playing. Conversations are
free-form (an LLM brain), **voiced aloud** (browser text-to-speech, with subtitles), and a
few of them know something about Margaux while most are just Parisian life.

Between objectives there are **optional things to do**: read hidden clue notes, pick locks
(a timing minigame), photograph evidence, and eavesdrop on overheard conversations. The
leads you chase are saved, and your investigative thoroughness changes the finale.

## The campaign
1. **Montmartre** — roam the square, tail the van crew, photograph the plate, read the city.
2. **The Marais** — Le Corbeau bistro: lift evidence past the waiter, pick the cellar, talk.
3. **Louvre After Hours** — dodge camera cones and laser tripwires, crack a cipher.
4. **The Catacombs** — a rescue that's a trap: an alarm trips and the tunnels seal — run.
5. **Eiffel Tower Finale** — the mastermind and a helicopter spool-up clock. How it ends
   depends on how many clues you solved and how thoroughly you investigated.

## The spine: the CASE DOSSIER
Sneak past guard vision-cones, collect glowing **clue nodes**, interrogate informants and
suspects in **voiced free-form conversation**, then physically **link two clue cards** into a
deduction — that deduction is literally the key to the next level.

## Audio
A full synthesized soundscape: per-district Parisian ambience (traffic, café chatter, an
accordion busker, pigeons, crypt drips), tension-reactive music that swells as you're nearly
spotted, and action SFX (locks, takedowns, the alarm, the helicopter rotor). NPC dialogue is
spoken aloud via the browser speech engine with on-screen subtitles.

## Cloud save + leaderboard
Account progress, your furthest-unlocked district, collected evidence, **and your exploration
state (notes read, locks picked, leads found, who you trust)** are saved to your account in
**Supabase**, so you pick up exactly where you left off on any device. A global
**fastest-rescue leaderboard** ranks your best campaign time.

## Tech
- Godot 4.6.3, GDScript, Compatibility renderer, web `nothreads` export.
- Mobile soft keyboard enabled for the login fields (`experimental_virtual_keyboard`).
- Supabase (auth + Postgres + RLS) via `web/bridge.js` (supabase-js) and `JavaScriptBridge`.
- LLM-powered NPC interrogation via the shared `npc.myapping.com/chat` brain.
- Voiced dialogue via the Web Speech API; soundscape synthesized in `audio/synth.py`.
- Characters + landmarks generated with Meshy; world dressed from the CC0 model library
  (kk_city street kit, Quaternius trees, Vostok realistic props). Re-fetch every asset with
  `models/fetch_assets.sh`.

Backend table prefix and Supabase config live in `.env` / `.env.example`
(`VITE_TABLE_PREFIX=usr_nmexs7bytxq2_taken_in_paris`).
