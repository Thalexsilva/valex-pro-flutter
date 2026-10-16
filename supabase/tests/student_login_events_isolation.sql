-- Run as postgres after 20261009140000. All fixtures are rolled back.
begin;

select set_config('valex_test.access_trainer_a', gen_random_uuid()::text, true);
select set_config('valex_test.access_trainer_b', gen_random_uuid()::text, true);
select set_config('valex_test.access_student_user', gen_random_uuid()::text, true);
select set_config('valex_test.access_student', gen_random_uuid()::text, true);

insert into auth.users (id) values
  (current_setting('valex_test.access_trainer_a')::uuid),
  (current_setting('valex_test.access_trainer_b')::uuid),
  (current_setting('valex_test.access_student_user')::uuid);

insert into public.students (id, trainer_id, name, student_user_id) values
  (current_setting('valex_test.access_student')::uuid,
   current_setting('valex_test.access_trainer_a')::uuid,
   'Access test student',
   current_setting('valex_test.access_student_user')::uuid);

insert into public.student_login_events
  (student_id, trainer_id, student_user_id, auth_sign_in_at, ip_address, platform)
values
  (current_setting('valex_test.access_student')::uuid,
   current_setting('valex_test.access_trainer_a')::uuid,
   current_setting('valex_test.access_student_user')::uuid,
   now(), '192.0.2.10', 'Web');

do $$
begin
  insert into public.student_login_events
    (student_id, trainer_id, student_user_id, auth_sign_in_at)
  select student_id, trainer_id, student_user_id, auth_sign_in_at
  from public.student_login_events
  where student_id = current_setting('valex_test.access_student')::uuid;
  raise exception 'FAIL: duplicate login was accepted';
exception when unique_violation then
  null;
end $$;

set local role authenticated;
select set_config('request.jwt.claim.sub', current_setting('valex_test.access_trainer_a'), true);
select set_config('request.jwt.claims', json_build_object(
  'sub', current_setting('valex_test.access_trainer_a'), 'role', 'authenticated')::text, true);
do $$
begin
  if (select count(*) from public.student_login_events) <> 1 then
    raise exception 'FAIL: owner cannot read access';
  end if;
  if (select total_logins from public.student_login_summary(30)) <> 1 then
    raise exception 'FAIL: owner summary is incorrect';
  end if;
  if has_table_privilege('authenticated', 'public.student_login_events', 'INSERT') then
    raise exception 'FAIL: client may forge an access';
  end if;
end $$;

select set_config('request.jwt.claim.sub', current_setting('valex_test.access_trainer_b'), true);
select set_config('request.jwt.claims', json_build_object(
  'sub', current_setting('valex_test.access_trainer_b'), 'role', 'authenticated')::text, true);
do $$
begin
  if exists (select 1 from public.student_login_events) then
    raise exception 'FAIL: another trainer can read access';
  end if;
  if (select total_logins from public.student_login_summary(30)) <> 0 then
    raise exception 'FAIL: another trainer sees summary';
  end if;
end $$;

select set_config('request.jwt.claim.sub', current_setting('valex_test.access_student_user'), true);
select set_config('request.jwt.claims', json_build_object(
  'sub', current_setting('valex_test.access_student_user'), 'role', 'authenticated')::text, true);
do $$
begin
  if exists (select 1 from public.student_login_events) then
    raise exception 'FAIL: student can read access history';
  end if;
end $$;

rollback;
