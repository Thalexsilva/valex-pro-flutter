-- Preserve legacy rows, but never expose unowned or mismatched health records.
begin;

alter table public.student_anamneses enable row level security;

drop policy if exists "Treinador pode visualizar anamneses de seus alunos"
  on public.student_anamneses;
drop policy if exists "Treinador pode inserir/atualizar anamneses de seus alunos"
  on public.student_anamneses;
drop policy if exists "Treinador e aluno podem visualizar anamneses"
  on public.student_anamneses;
drop policy if exists "Treinador e aluno podem inserir/atualizar anamneses"
  on public.student_anamneses;

-- The restrictive guard also constrains any additional permissive policies.
create policy student_anamneses_tenant_guard
  on public.student_anamneses as restrictive for all
  to authenticated
  using (
    trainer_id = (select auth.uid())
    and exists (
      select 1 from public.students
      where students.id::text = student_anamneses.student_id
        and students.trainer_id = (select auth.uid())
    )
  )
  with check (
    trainer_id = (select auth.uid())
    and exists (
      select 1 from public.students
      where students.id::text = student_anamneses.student_id
        and students.trainer_id = (select auth.uid())
    )
  );

create policy student_anamneses_manage_own
  on public.student_anamneses for all
  to authenticated
  using (trainer_id = (select auth.uid()))
  with check (trainer_id = (select auth.uid()));

revoke all on public.student_anamneses from anon;
grant select, insert, update, delete on public.student_anamneses to authenticated;
grant all on public.student_anamneses to service_role;

commit;
