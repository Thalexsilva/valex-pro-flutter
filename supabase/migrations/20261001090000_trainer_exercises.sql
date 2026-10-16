-- Preserve each instructor's private exercise names from the legacy editor.
create table if not exists public.trainer_exercises (
  id uuid primary key default gen_random_uuid(),
  trainer_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (length(btrim(title)) between 1 and 160),
  created_at timestamptz not null default now(),
  unique (trainer_id, title)
);

create index if not exists trainer_exercises_trainer_idx
  on public.trainer_exercises (trainer_id);

alter table public.trainer_exercises enable row level security;

create policy trainer_exercises_select on public.trainer_exercises
  for select to authenticated using (trainer_id = auth.uid());
create policy trainer_exercises_insert on public.trainer_exercises
  for insert to authenticated with check (trainer_id = auth.uid());
create policy trainer_exercises_update on public.trainer_exercises
  for update to authenticated using (trainer_id = auth.uid())
  with check (trainer_id = auth.uid());
create policy trainer_exercises_delete on public.trainer_exercises
  for delete to authenticated using (trainer_id = auth.uid());

grant select, insert, update, delete on public.trainer_exercises to authenticated;
