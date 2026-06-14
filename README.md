# TAKEN IN PARIS

A third-person **stealth-thriller** built in **Godot 4.6.3** for mobile web
(Compatibility / WebGL2, single-threaded `nothreads` export).

You are **Étienne Vasseur**, a disgraced French intelligence operative. Your daughter
**Margaux** has been taken and you have 72 hours before she is moved out of the country.
The only way to find her is to *read Paris itself*.

## Play
Open the preview link on a phone or desktop browser, tap to start, sign in (or play as a
guest), and work through five Parisian districts.

- **Move:** left thumb (on-screen joystick) / `WASD` / arrow keys.
- **Look:** drag the right side of the screen / hold left-mouse + move.
- **Sneak:** the crouch button / `Shift` — slower, quieter, harder to spot.
- **Interact:** hold the `[+]` button / hold `E` — collect glowing clue nodes, talk to people.
- **Takedown:** the takedown button / `F` — silently neutralize a guard from close behind.
- **Dossier:** the case button / `Q` — review evidence and **link two clue cards** into the
  deduction that unlocks the next district.

## The campaign
1. **Montmartre Rooftops** — tail the kidnapper without being spotted.
2. **Marais Bistro** — lift evidence and interrogate the waiter.
3. **Louvre After Hours** — dodge camera cones and laser tripwires, crack a cipher.
4. **Catacombs** — a rescue that's a trap: an alarm trips and the tunnels seal in a timed sprint.
5. **Eiffel Tower Finale** — the mastermind, and a helicopter spool-up clock. How it ends
   depends on how many clues you actually solved.

## The spine: the CASE DOSSIER
Sneak past guard vision-cones, hold-interact to collect glowing **clue nodes**, interrogate
informants and suspects in **free-form conversation** (they answer in character and drop
real clues), then physically **link two clue cards** into a deduction — that deduction is
literally the key to the next level.

## Cloud save + leaderboard
Progress, your furthest-unlocked district, and collected evidence are saved to your account
in **Supabase**, so you pick up exactly where you left off on any device. A global
**fastest-rescue leaderboard** ranks your best campaign time against everyone else.

## Tech
- Godot 4.6.3, GDScript, Compatibility renderer, web `nothreads` export.
- Supabase (auth + Postgres + RLS) via `web/bridge.js` (supabase-js) and `JavaScriptBridge`.
- LLM-powered NPC interrogation via the shared `npc.myapping.com/chat` brain.
- Custom characters + landmarks generated with Meshy; world dressed from the CC0 model library.

Backend table prefix and Supabase config live in `.env` / `.env.example`
(`VITE_TABLE_PREFIX=usr_nmexs7bytxq2_taken_in_paris`).
