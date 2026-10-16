-- Make clinical documents private and scope every object operation to the
-- authenticated trainer who owns the student in the first path segment.

update storage.buckets
set public = false
where id = 'student-documents';

drop policy if exists "Permitir upload autenticado de fotos e laudos"
  on storage.objects;
drop policy if exists "Permitir visualização pública/autenticada de fotos e laudos"
  on storage.objects;
drop policy if exists "Permitir upload de fotos e laudos de bioimpedancia"
  on storage.objects;
drop policy if exists "Permitir visualizacao de fotos e laudos de bioimpedancia"
  on storage.objects;

create policy student_documents_select_own_students
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'student-documents'
    and exists (
      select 1
      from public.students
      where students.id::text = (storage.foldername(objects.name))[1]
        and students.trainer_id = (select auth.uid())
    )
  );

create policy student_documents_insert_own_students
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'student-documents'
    and exists (
      select 1
      from public.students
      where students.id::text = (storage.foldername(objects.name))[1]
        and students.trainer_id = (select auth.uid())
    )
  );

create policy student_documents_update_own_students
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'student-documents'
    and exists (
      select 1
      from public.students
      where students.id::text = (storage.foldername(objects.name))[1]
        and students.trainer_id = (select auth.uid())
    )
  )
  with check (
    bucket_id = 'student-documents'
    and exists (
      select 1
      from public.students
      where students.id::text = (storage.foldername(objects.name))[1]
        and students.trainer_id = (select auth.uid())
    )
  );

create policy student_documents_delete_own_students
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'student-documents'
    and exists (
      select 1
      from public.students
      where students.id::text = (storage.foldername(objects.name))[1]
        and students.trainer_id = (select auth.uid())
    )
  );
