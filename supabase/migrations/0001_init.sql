-- TAKEN IN PARIS - Supabase schema (shared Gogi project, per-app prefix).
-- Apply with the service role (exec_sql RPC) or psql. Idempotent.

-- Per-user campaign progress (cloud save across devices).
create table if not exists public."usr_nmexs7bytxq2_taken_in_paris_progress" (
  user_id text primary key,
  furthest_level int not null default 1,
  clues_solved int not null default 0,
  evidence jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public."usr_nmexs7bytxq2_taken_in_paris_progress" enable row level security;
drop policy if exists "own_progress" on public."usr_nmexs7bytxq2_taken_in_paris_progress";
create policy "own_progress" on public."usr_nmexs7bytxq2_taken_in_paris_progress"
  for all to authenticated using (auth.uid()::text = user_id) with check (auth.uid()::text = user_id);
grant select, insert, update, delete on public."usr_nmexs7bytxq2_taken_in_paris_progress" to authenticated;
grant select, insert, update, delete on public."usr_nmexs7bytxq2_taken_in_paris_progress" to service_role;

-- Global fastest-rescue leaderboard (public read; write only your own row).
create table if not exists public."usr_nmexs7bytxq2_taken_in_paris_scores" (
  user_id text primary key,
  codename text not null default 'Operative',
  best_time_seconds numeric not null,
  clues_solved int not null default 0,
  updated_at timestamptz not null default now()
);
alter table public."usr_nmexs7bytxq2_taken_in_paris_scores" enable row level security;
drop policy if exists "scores_read_all" on public."usr_nmexs7bytxq2_taken_in_paris_scores";
create policy "scores_read_all" on public."usr_nmexs7bytxq2_taken_in_paris_scores"
  for select to anon, authenticated using (true);
drop policy if exists "scores_insert_own" on public."usr_nmexs7bytxq2_taken_in_paris_scores";
create policy "scores_insert_own" on public."usr_nmexs7bytxq2_taken_in_paris_scores"
  for insert to authenticated with check (auth.uid()::text = user_id);
drop policy if exists "scores_update_own" on public."usr_nmexs7bytxq2_taken_in_paris_scores";
create policy "scores_update_own" on public."usr_nmexs7bytxq2_taken_in_paris_scores"
  for update to authenticated using (auth.uid()::text = user_id) with check (auth.uid()::text = user_id);
drop policy if exists "scores_delete_own" on public."usr_nmexs7bytxq2_taken_in_paris_scores";
create policy "scores_delete_own" on public."usr_nmexs7bytxq2_taken_in_paris_scores"
  for delete to authenticated using (auth.uid()::text = user_id);
grant select on public."usr_nmexs7bytxq2_taken_in_paris_scores" to anon;
grant select, insert, update, delete on public."usr_nmexs7bytxq2_taken_in_paris_scores" to authenticated;
grant select, insert, update, delete on public."usr_nmexs7bytxq2_taken_in_paris_scores" to service_role;
