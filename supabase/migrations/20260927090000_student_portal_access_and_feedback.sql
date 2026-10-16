-- Student accounts use their own confirmed Supabase identity. A trainer keeps
-- ownership of the student record and prescription.
alter table public.students
  add column if not exists student_user_id uuid references auth.users(id);

create index if not exists idx_students_student_user_id
  on public.students(student_user_id) where student_user_id is not null;

create or replace function public.claim_student_account()
returns uuid
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  account_email text;
  claimed_id uuid;
begin
  select lower(trim(email)) into account_email
  from auth.users
  where id = auth.uid() and email_confirmed_at is not null;

  if account_email is null then return null; end if;

  select id into claimed_id
  from public.students
  where student_user_id = auth.uid() and status = 'active'
  order by created_at limit 1;
  if claimed_id is not null then return claimed_id; end if;

  select id into claimed_id
  from public.students
  where lower(trim(email)) = account_email
    and student_user_id is null
    and trainer_id <> auth.uid()
    and status = 'active'
  order by created_at limit 1;

  if claimed_id is not null then
    update public.students
      set student_user_id = auth.uid()
      where id = claimed_id and student_user_id is null;
  end if;
  return claimed_id;
end;
$$;

revoke all on function public.claim_student_account() from public, anon;
grant execute on function public.claim_student_account() to authenticated;

create policy students_student_read on public.students for select to authenticated
  using (student_user_id = (select auth.uid()));

create policy workout_sheets_student_read on public.workout_sheets for select to authenticated
  using (exists (
    select 1 from public.students s
    where s.id = workout_sheets.student_id
      and s.student_user_id = (select auth.uid())
  ));

-- Replace the earlier trainer-only restrictive guard with a tenant guard
-- that also recognizes a linked student. The trainer policy remains intact.
drop policy if exists student_anamneses_tenant_guard on public.student_anamneses;
create policy student_anamneses_tenant_guard
  on public.student_anamneses as restrictive for all to authenticated
  using (
    (trainer_id = (select auth.uid()) and exists (
      select 1 from public.students s
      where s.id::text = student_anamneses.student_id
        and s.trainer_id = (select auth.uid())
    )) or exists (
      select 1 from public.students s
      where s.id::text = student_anamneses.student_id
        and s.trainer_id = student_anamneses.trainer_id
        and s.student_user_id = (select auth.uid())
    )
  )
  with check (
    (trainer_id = (select auth.uid()) and exists (
      select 1 from public.students s
      where s.id::text = student_anamneses.student_id
        and s.trainer_id = (select auth.uid())
    )) or exists (
      select 1 from public.students s
      where s.id::text = student_anamneses.student_id
        and s.trainer_id = student_anamneses.trainer_id
        and s.student_user_id = (select auth.uid())
    )
  );

create policy student_anamneses_student_read on public.student_anamneses
  for select to authenticated using (exists (
    select 1 from public.students s
    where s.id::text = student_anamneses.student_id
      and s.trainer_id = student_anamneses.trainer_id
      and s.student_user_id = (select auth.uid())
  ));
create policy student_anamneses_student_insert on public.student_anamneses
  for insert to authenticated with check (exists (
    select 1 from public.students s
    where s.id::text = student_anamneses.student_id
      and s.trainer_id = student_anamneses.trainer_id
      and s.student_user_id = (select auth.uid())
  ));
create policy student_anamneses_student_update on public.student_anamneses
  for update to authenticated
  using (exists (
    select 1 from public.students s
    where s.id::text = student_anamneses.student_id
      and s.trainer_id = student_anamneses.trainer_id
      and s.student_user_id = (select auth.uid())
  ))
  with check (exists (
    select 1 from public.students s
    where s.id::text = student_anamneses.student_id
      and s.trainer_id = student_anamneses.trainer_id
      and s.student_user_id = (select auth.uid())
  ));

create policy student_documents_student_upload on storage.objects
  for insert to authenticated with check (
    bucket_id = 'student-documents' and exists (
      select 1 from public.students s
      where s.id::text = (storage.foldername(name))[1]
        and s.student_user_id = (select auth.uid())
    )
  );
create policy student_documents_student_read on storage.objects
  for select to authenticated using (
    bucket_id = 'student-documents' and exists (
      select 1 from public.students s
      where s.id::text = (storage.foldername(name))[1]
        and s.student_user_id = (select auth.uid())
    )
  );

create table if not exists public.student_workout_sessions (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null,
  trainer_id uuid not null,
  kind text not null check (kind in ('session', 'comment')),
  workout_day text,
  completed_sets jsonb not null default '{}'::jsonb,
  duration_seconds integer not null default 0 check (duration_seconds >= 0),
  rpe integer check (rpe between 1 and 10),
  feedback text not null default '' check (char_length(feedback) <= 2000),
  created_at timestamptz not null default now(),
  foreign key (student_id, trainer_id) references public.students(id, trainer_id),
  check (kind = 'session' or char_length(trim(feedback)) > 0)
);
create index if not exists idx_student_workout_sessions_student_created
  on public.student_workout_sessions(student_id, created_at desc);
alter table public.student_workout_sessions enable row level security;
create policy student_workout_sessions_read on public.student_workout_sessions
  for select to authenticated using (
    trainer_id = (select auth.uid()) or exists (
      select 1 from public.students s
      where s.id = student_workout_sessions.student_id
        and s.trainer_id = student_workout_sessions.trainer_id
        and s.student_user_id = (select auth.uid())
    )
  );
create policy student_workout_sessions_student_insert on public.student_workout_sessions
  for insert to authenticated with check (exists (
    select 1 from public.students s
    where s.id = student_workout_sessions.student_id
      and s.trainer_id = student_workout_sessions.trainer_id
      and s.student_user_id = (select auth.uid())
  ));
grant select, insert on public.student_workout_sessions to authenticated;

create or replace function public.mark_student_assessment_complete()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.is_draft = false then
    update public.students
      set needs_reassessment = false,
          anamnese_pending = false,
          last_anamnese_date = new.created_at::text
      where id::text = new.student_id and trainer_id = new.trainer_id;
  end if;
  return new;
end;
$$;
drop trigger if exists trg_student_assessment_complete on public.student_anamneses;
create trigger trg_student_assessment_complete
  after insert or update on public.student_anamneses
  for each row execute function public.mark_student_assessment_complete();
