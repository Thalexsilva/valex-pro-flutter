-- Run as postgres after migrations. All fixtures are rolled back.
begin;
select set_config('valex_test.a', gen_random_uuid()::text, true);
select set_config('valex_test.b', gen_random_uuid()::text, true);
select set_config('valex_test.sa', gen_random_uuid()::text, true);
select set_config('valex_test.sb', gen_random_uuid()::text, true);
insert into auth.users (id) values
  (current_setting('valex_test.a')::uuid),
  (current_setting('valex_test.b')::uuid);
insert into public.students (id, trainer_id, name) values
  (current_setting('valex_test.sa')::uuid, current_setting('valex_test.a')::uuid, 'RLS test A'),
  (current_setting('valex_test.sb')::uuid, current_setting('valex_test.b')::uuid, 'RLS test B');
insert into public.student_anamneses (id, student_id, trainer_id, name) values
  (current_setting('valex_test.sa'), current_setting('valex_test.sa'), current_setting('valex_test.a')::uuid, 'Own'),
  (current_setting('valex_test.sb'), current_setting('valex_test.sb'), current_setting('valex_test.b')::uuid, 'Foreign'),
  (current_setting('valex_test.sa') || '-orphan', current_setting('valex_test.sa'), null, 'Orphan');

insert into storage.objects (bucket_id, name) values
  ('student-documents', current_setting('valex_test.sb') || '/rls-test.pdf');

set local role authenticated;
select set_config('request.jwt.claim.sub', current_setting('valex_test.a'), true);
select set_config('request.jwt.claims', json_build_object('sub', current_setting('valex_test.a'), 'role', 'authenticated')::text, true);
do $$
declare affected integer;
begin
  if (select count(*) from public.student_anamneses
      where student_id in (current_setting('valex_test.sa'), current_setting('valex_test.sb'))) <> 1 then
    raise exception 'FAIL: foreign or orphan anamnese visible';
  end if;
  update public.student_anamneses set name = 'Own updated'
    where id = current_setting('valex_test.sa');
  get diagnostics affected = row_count;
  if affected <> 1 then raise exception 'FAIL: own update denied'; end if;
  delete from public.student_anamneses where id = current_setting('valex_test.sb');
  get diagnostics affected = row_count;
  if affected <> 0 then raise exception 'FAIL: foreign delete allowed'; end if;
  begin
    insert into public.student_anamneses (id, student_id, trainer_id, name)
    values (gen_random_uuid()::text, current_setting('valex_test.sb'), current_setting('valex_test.a')::uuid, 'Forged ownership');
    raise exception 'FAIL: foreign student accepted';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.student_anamneses set student_id = current_setting('valex_test.sb')
      where id = current_setting('valex_test.sa');
    raise exception 'FAIL: student reassignment allowed';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.student_anamneses (id, student_id, trainer_id, name)
    values (gen_random_uuid()::text, current_setting('valex_test.sa'), null, 'Unowned');
    raise exception 'FAIL: null trainer accepted';
  exception when insufficient_privilege then null;
  end;
end $$;

insert into storage.objects (bucket_id, name) values
  ('student-documents', current_setting('valex_test.sa') || '/rls-test.pdf');
do $$
begin
  if (select count(*) from storage.objects
      where bucket_id = 'student-documents'
        and name in (current_setting('valex_test.sa') || '/rls-test.pdf',
                     current_setting('valex_test.sb') || '/rls-test.pdf')) <> 1 then
    raise exception 'FAIL: foreign storage object visible';
  end if;
  begin
    insert into storage.objects (bucket_id, name)
    values ('student-documents', current_setting('valex_test.sb') || '/forged.pdf');
    raise exception 'FAIL: upload into foreign student folder allowed';
  exception when insufficient_privilege then null;
  end;
  begin
    update storage.objects set name = current_setting('valex_test.sb') || '/moved.pdf'
      where bucket_id = 'student-documents'
        and name = current_setting('valex_test.sa') || '/rls-test.pdf';
    raise exception 'FAIL: moving object into foreign folder allowed';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;
do $$
begin
  if (select public from storage.buckets where id = 'student-documents') is distinct from false then
    raise exception 'FAIL: clinical documents bucket is not private';
  end if;
  if has_table_privilege('anon', 'public.student_anamneses', 'SELECT') then
    raise exception 'FAIL: anonymous role retains anamnese SELECT privilege';
  end if;
end $$;
select 'PASS: anamnese and storage tenant isolation; fixtures rolled back' as result;
rollback;
