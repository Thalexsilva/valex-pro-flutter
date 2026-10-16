create or replace function public.unlink_student_when_email_changes()
returns trigger language plpgsql set search_path = public as $$
begin
  if lower(trim(coalesce(new.email, ''))) is distinct from
     lower(trim(coalesce(old.email, ''))) then
    new.student_user_id := null;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_unlink_student_when_email_changes on public.students;
create trigger trg_unlink_student_when_email_changes
  before update of email on public.students
  for each row execute function public.unlink_student_when_email_changes();
