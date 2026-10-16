-- Link a converted lead to its student and perform both writes atomically.

alter table public.leads
  add column if not exists converted_student_id uuid;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'leads_converted_student_owner_fk'
      and conrelid = 'public.leads'::regclass
  ) then
    alter table public.leads
      add constraint leads_converted_student_owner_fk
      foreign key (converted_student_id, trainer_id)
      references public.students(id, trainer_id);
  end if;
end;
$$;

create index if not exists leads_converted_student_idx
  on public.leads (trainer_id, converted_student_id)
  where converted_student_id is not null;

create or replace function public.convert_lead_to_student(
  p_lead_id text,
  p_student jsonb
)
returns jsonb
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_trainer uuid := auth.uid();
  v_lead public.leads%rowtype;
  v_student public.students%rowtype;
  v_student_id uuid;
begin
  if v_trainer is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  select * into v_lead
  from public.leads
  where id = p_lead_id
    and trainer_id = v_trainer
  for update;
  if not found then
    raise exception 'LEAD_NOT_FOUND' using errcode = 'P0002';
  end if;

  if v_lead.converted_student_id is not null then
    select * into v_student
    from public.students
    where id = v_lead.converted_student_id
      and trainer_id = v_trainer;
    if found then
      return to_jsonb(v_student);
    end if;
  end if;

  v_student_id := coalesce(
    nullif(p_student->>'id', '')::uuid,
    gen_random_uuid()
  );

  insert into public.students (
    id,
    trainer_id,
    name,
    date,
    teacher,
    status,
    cpf,
    phone,
    email,
    address,
    niche,
    prontuario_text,
    evolucao,
    academia,
    mes,
    instructor_notes
  ) values (
    v_student_id,
    v_trainer,
    coalesce(nullif(p_student->>'name', ''), v_lead.name),
    coalesce(nullif(p_student->>'date', '')::date, current_date),
    coalesce(p_student->>'teacher', ''),
    'active',
    coalesce(p_student->>'cpf', ''),
    coalesce(nullif(p_student->>'phone', ''), v_lead.phone, ''),
    coalesce(nullif(p_student->>'email', ''), v_lead.email, ''),
    coalesce(p_student->>'address', ''),
    coalesce(nullif(p_student->>'niche', ''), v_lead.objective, 'Consultoria Online'),
    coalesce(p_student->>'prontuario_text', ''),
    coalesce(p_student->>'evolucao', ''),
    coalesce(p_student->>'academia', 'VALEX Consultoria'),
    coalesce(p_student->>'mes', ''),
    coalesce(p_student->>'instructor_notes', '')
  )
  returning * into v_student;

  update public.leads
  set status = 'won',
      converted_student_id = v_student.id,
      scheduled_follow_up_date = null,
      scheduled_follow_up_note = null,
      updated_at = now()
  where id = v_lead.id
    and trainer_id = v_trainer;

  return to_jsonb(v_student);
end;
$$;

revoke all on function public.convert_lead_to_student(text, jsonb) from public;
revoke all on function public.convert_lead_to_student(text, jsonb) from anon;
grant execute on function public.convert_lead_to_student(text, jsonb) to authenticated;
