begin;

-- A student may finish a draft, but may not rewrite a submitted assessment.
drop policy if exists student_anamneses_student_update on public.student_anamneses;
create policy student_anamneses_student_update on public.student_anamneses
  for update to authenticated
  using (
    is_draft is true
    and exists (
      select 1 from public.students s
      where s.id::text = student_anamneses.student_id
        and s.trainer_id = student_anamneses.trainer_id
        and s.student_user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.students s
      where s.id::text = student_anamneses.student_id
        and s.trainer_id = student_anamneses.trainer_id
        and s.student_user_id = (select auth.uid())
    )
  );

-- RLS is row based; protect trainer-authored columns across INSERT and UPDATE.
-- The current client sends derived notes on every upsert, so ignore those
-- supplied values for student writes while preserving their submitted data.
create or replace function public.protect_student_assessment_fields()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  -- Service/database maintenance writes are outside the client RLS contract.
  -- An authenticated request with no uid must never bypass this guard.
  if current_user <> 'authenticated' or auth.uid() = new.trainer_id then
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.instructor_notes := null;
    new.prontuario_text := null;
  else
    if old.is_draft is not true then
      raise exception 'Submitted assessment cannot be edited by a student'
        using errcode = '42501';
    end if;
    if new.id is distinct from old.id
       or new.student_id is distinct from old.student_id
       or new.trainer_id is distinct from old.trainer_id
       or new.created_at is distinct from old.created_at then
      raise exception 'Assessment identity cannot be changed by a student'
        using errcode = '42501';
    end if;
    new.instructor_notes := old.instructor_notes;
    new.prontuario_text := old.prontuario_text;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_protect_student_assessment_fields
  on public.student_anamneses;
create trigger trg_protect_student_assessment_fields
  before insert or update on public.student_anamneses
  for each row execute function public.protect_student_assessment_fields();

-- Email alone may match records owned by different trainers. Only claim when
-- there is exactly one active eligible record, and return the row actually won.
create or replace function public.claim_student_account()
returns uuid
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  account_email text;
  linked_ids uuid[];
  eligible_ids uuid[];
  claimed_id uuid;
begin
  select lower(trim(email)) into account_email
  from auth.users
  where id = auth.uid() and email_confirmed_at is not null;

  if account_email is null then return null; end if;

  select array_agg(id order by created_at, id) into linked_ids
  from public.students
  where student_user_id = auth.uid() and status = 'active';
  if coalesce(array_length(linked_ids, 1), 0) > 1 then return null; end if;
  if array_length(linked_ids, 1) = 1 then return linked_ids[1]; end if;

  select array_agg(id order by created_at, id) into eligible_ids
  from public.students
  where lower(trim(email)) = account_email
    and student_user_id is null
    and trainer_id <> auth.uid()
    and status = 'active';
  if array_length(eligible_ids, 1) is distinct from 1 then return null; end if;

  update public.students
    set student_user_id = auth.uid()
    where id = eligible_ids[1] and student_user_id is null
    returning id into claimed_id;
  return claimed_id;
end;
$$;

revoke all on function public.claim_student_account() from public, anon;
grant execute on function public.claim_student_account() to authenticated;

commit;
