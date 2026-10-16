-- Run as postgres after migrations. Fixtures are rolled back.
begin;
select set_config('valex_test.trainer_a', gen_random_uuid()::text, true);
select set_config('valex_test.trainer_b', gen_random_uuid()::text, true);
select set_config('valex_test.student_user', gen_random_uuid()::text, true);
select set_config('valex_test.claim_user', gen_random_uuid()::text, true);
select set_config('valex_test.student', gen_random_uuid()::text, true);
select set_config('valex_test.claim_a', gen_random_uuid()::text, true);
select set_config('valex_test.claim_b', gen_random_uuid()::text, true);
select set_config('valex_test.assessment', gen_random_uuid()::text, true);
select set_config('valex_test.email', gen_random_uuid()::text || '@example.test', true);

insert into auth.users (id, email, email_confirmed_at) values
  (current_setting('valex_test.trainer_a')::uuid, null, null),
  (current_setting('valex_test.trainer_b')::uuid, null, null),
  (current_setting('valex_test.student_user')::uuid, null, null),
  (current_setting('valex_test.claim_user')::uuid,
   current_setting('valex_test.email'), now());
insert into public.students (id, trainer_id, name, email, student_user_id) values
  (current_setting('valex_test.student')::uuid,
   current_setting('valex_test.trainer_a')::uuid, 'Assessment student', null,
   current_setting('valex_test.student_user')::uuid),
  (current_setting('valex_test.claim_a')::uuid,
   current_setting('valex_test.trainer_a')::uuid, 'Claim candidate A',
   current_setting('valex_test.email'), null),
  (current_setting('valex_test.claim_b')::uuid,
   current_setting('valex_test.trainer_b')::uuid, 'Claim candidate B',
   current_setting('valex_test.email'), null);

set local role authenticated;
select set_config('request.jwt.claim.sub', current_setting('valex_test.student_user'), true);
select set_config('request.jwt.claims', json_build_object(
  'sub', current_setting('valex_test.student_user'), 'role', 'authenticated')::text, true);

insert into public.student_anamneses
  (id, student_id, trainer_id, name, is_draft, instructor_notes, prontuario_text)
values
  (current_setting('valex_test.assessment'), current_setting('valex_test.student'),
   current_setting('valex_test.trainer_a')::uuid, 'Draft', true,
   'forged trainer note', 'forged chart');
do $$
begin
  if exists (
    select 1 from public.student_anamneses
    where id = current_setting('valex_test.assessment')
      and (instructor_notes is not null or prontuario_text is not null)
  ) then
    raise exception 'FAIL: student inserted trainer-authored fields';
  end if;
end $$;

select set_config('request.jwt.claim.sub', current_setting('valex_test.trainer_a'), true);
select set_config('request.jwt.claims', json_build_object(
  'sub', current_setting('valex_test.trainer_a'), 'role', 'authenticated')::text, true);
update public.student_anamneses
set instructor_notes = 'trainer note', prontuario_text = 'trainer chart'
where id = current_setting('valex_test.assessment');

select set_config('request.jwt.claim.sub', current_setting('valex_test.student_user'), true);
select set_config('request.jwt.claims', json_build_object(
  'sub', current_setting('valex_test.student_user'), 'role', 'authenticated')::text, true);
update public.student_anamneses
set name = 'Updated draft', instructor_notes = 'forged again',
    prontuario_text = 'forged chart again'
where id = current_setting('valex_test.assessment');
do $$
begin
  if not exists (
    select 1 from public.student_anamneses
    where id = current_setting('valex_test.assessment')
      and name = 'Updated draft'
      and instructor_notes = 'trainer note'
      and prontuario_text = 'trainer chart'
  ) then
    raise exception 'FAIL: draft update or trainer-field protection';
  end if;
end $$;

do $$
declare affected integer;
begin
  update public.student_anamneses set is_draft = false
  where id = current_setting('valex_test.assessment');
  get diagnostics affected = row_count;
  if affected <> 1 then
    raise exception 'FAIL: student could not submit a draft';
  end if;
  if not exists (
    select 1 from public.student_anamneses
    where id = current_setting('valex_test.assessment') and is_draft is false
  ) then
    raise exception 'FAIL: draft was not finalized';
  end if;
  update public.student_anamneses set name = 'Forged final edit'
  where id = current_setting('valex_test.assessment');
  get diagnostics affected = row_count;
  if affected <> 0 then
    raise exception 'FAIL: student changed finalized assessment';
  end if;
end $$;

select set_config('request.jwt.claim.sub', current_setting('valex_test.claim_user'), true);
select set_config('request.jwt.claims', json_build_object(
  'sub', current_setting('valex_test.claim_user'), 'role', 'authenticated')::text, true);
do $$
begin
  if public.claim_student_account() is not null then
    raise exception 'FAIL: ambiguous email was claimed';
  end if;
end $$;

reset role;
do $$
begin
  if exists (
    select 1 from public.students
    where id in (current_setting('valex_test.claim_a')::uuid,
                 current_setting('valex_test.claim_b')::uuid)
      and student_user_id is not null
  ) then
    raise exception 'FAIL: ambiguous claim linked a student';
  end if;
end $$;
update public.students set status = 'archived'
where id = current_setting('valex_test.claim_b')::uuid;

set local role authenticated;
select set_config('request.jwt.claim.sub', current_setting('valex_test.claim_user'), true);
select set_config('request.jwt.claims', json_build_object(
  'sub', current_setting('valex_test.claim_user'), 'role', 'authenticated')::text, true);
do $$
begin
  if public.claim_student_account() is distinct from
     current_setting('valex_test.claim_a')::uuid then
    raise exception 'FAIL: unique email did not claim the student';
  end if;
  if public.claim_student_account() is distinct from
     current_setting('valex_test.claim_a')::uuid then
    raise exception 'FAIL: repeated claim was not idempotent';
  end if;
end $$;

select 'PASS: student assessment and claim guards; fixtures rolled back' as result;
rollback;
