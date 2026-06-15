-- TAKEN IN PARIS - exploration state.
-- Round 2 makes Paris roamable: which hidden notes you found, which optional activities
-- you completed, which leads you chased and who you trust now ride on the existing
-- per-user progress row as a single jsonb blob. No new tables. Idempotent.

alter table public."usr_nmexs7bytxq2_taken_in_paris_progress"
  add column if not exists flags jsonb not null default '{}'::jsonb;

-- (RLS, policy and grants from 0001 already cover every column on this table.)
select pg_notify('pgrst', 'reload schema');
