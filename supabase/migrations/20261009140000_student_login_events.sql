begin;

create table public.student_login_events (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null,
  trainer_id uuid not null,
  student_user_id uuid not null references auth.users(id) on delete cascade,
  occurred_at timestamptz not null default now(),
  auth_sign_in_at timestamptz not null,
  ip_address inet,
  city text,
  region text,
  country text,
  platform text,
  time_zone text,
  constraint student_login_events_student_owner_fk
    foreign key (student_id, trainer_id)
    references public.students(id, trainer_id) on delete cascade
);

create index student_login_events_trainer_recent_idx
  on public.student_login_events(trainer_id, occurred_at desc);
create index student_login_events_student_recent_idx
  on public.student_login_events(student_id, occurred_at desc);
create unique index student_login_events_one_per_sign_in_idx
  on public.student_login_events(student_user_id, auth_sign_in_at);

alter table public.student_login_events enable row level security;

create policy student_login_events_trainer_read
  on public.student_login_events for select to authenticated
  using (trainer_id = (select auth.uid()));

revoke all on public.student_login_events from anon, authenticated;
grant select on public.student_login_events to authenticated;
grant all on public.student_login_events to service_role;

create function public.student_login_summary(p_days integer default 30)
returns table(total_logins bigint, students_with_access bigint)
language sql stable security invoker
set search_path = public
as $$
  select count(*)::bigint, count(distinct student_id)::bigint
  from public.student_login_events
  where trainer_id = (select auth.uid())
    and occurred_at >= now() - make_interval(days => least(greatest(p_days, 1), 90));
$$;

revoke all on function public.student_login_summary(integer) from public, anon;
grant execute on function public.student_login_summary(integer) to authenticated;

comment on table public.student_login_events is
  'Successful student app logins. IP and network location are approximate; only the linked trainer can read events.';

commit;
