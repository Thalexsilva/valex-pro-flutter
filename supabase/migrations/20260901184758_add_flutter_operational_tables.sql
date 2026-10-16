-- Structures consumed by the Flutter CRM and student financial summary.

create table if not exists public.leads (
  id text primary key,
  trainer_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  phone text not null default '',
  instagram text not null default '',
  email text not null default '',
  objective text not null default '',
  origin_channel text not null default 'meta_ads',
  target_plan_id text,
  target_plan_name text not null default '',
  estimated_value numeric(12, 2) not null default 0 check (estimated_value >= 0),
  score integer not null default 0 check (score between 0 and 100),
  status text not null default 'new',
  priority text not null default 'cold',
  loss_reason text,
  notes jsonb not null default '[]'::jsonb,
  utm_source text,
  utm_medium text,
  utm_campaign text,
  utm_content text,
  scheduled_follow_up_date timestamptz,
  scheduled_follow_up_note text,
  follow_up_step integer not null default 0 check (follow_up_step between 0 and 7),
  last_contact_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, trainer_id)
);

create index if not exists leads_trainer_score_idx
  on public.leads (trainer_id, score desc);
create index if not exists leads_trainer_follow_up_idx
  on public.leads (trainer_id, scheduled_follow_up_date)
  where scheduled_follow_up_date is not null;

alter table public.leads enable row level security;

create policy leads_select_own
  on public.leads for select
  to authenticated
  using ((select auth.uid()) = trainer_id);

create policy leads_insert_own
  on public.leads for insert
  to authenticated
  with check ((select auth.uid()) = trainer_id);

create policy leads_update_own
  on public.leads for update
  to authenticated
  using ((select auth.uid()) = trainer_id)
  with check ((select auth.uid()) = trainer_id);

create policy leads_delete_own
  on public.leads for delete
  to authenticated
  using ((select auth.uid()) = trainer_id);

grant select, insert, update, delete on public.leads to authenticated;
grant all on public.leads to service_role;

create or replace view public.student_financial_summary
with (security_invoker = true)
as
select
  student.id as student_id,
  student.trainer_id,
  coalesce(plan.name, 'Sem plano ativo') as plan_name,
  coalesce(subscription.status::text, 'Nenhum') as subscription_status,
  coalesce(to_char(invoice_summary.next_due_date, 'DD/MM/YYYY'), '-') as next_due_date,
  coalesce(invoice_summary.total_open, 0)::numeric(12, 2) as total_open,
  coalesce(invoice_summary.total_overdue, 0)::numeric(12, 2) as total_overdue,
  coalesce(to_char(payment_summary.last_payment_date, 'DD/MM/YYYY'), '-') as last_payment_date,
  case
    when coalesce(invoice_summary.total_overdue, 0) > 0 then 'overdue'
    when invoice_summary.has_due_today then 'dueToday'
    when payment_summary.last_payment_date is not null then 'paid'
    else 'noInvoice'
  end as badge
from public.students as student
left join lateral (
  select current_subscription.*
  from public.subscriptions as current_subscription
  where current_subscription.student_id = student.id
    and current_subscription.trainer_id = student.trainer_id
    and current_subscription.status in ('active', 'paused')
  order by current_subscription.created_at desc
  limit 1
) as subscription on true
left join public.plans as plan
  on plan.id = subscription.plan_id
 and plan.trainer_id = subscription.trainer_id
left join lateral (
  select
    min(invoice.due_date) filter (
      where invoice.status in ('pending', 'overdue')
    ) as next_due_date,
    coalesce(sum(invoice.final_amount) filter (
      where invoice.status in ('pending', 'overdue')
    ), 0) as total_open,
    coalesce(sum(invoice.final_amount) filter (
      where invoice.status = 'overdue'
    ), 0) as total_overdue,
    coalesce(bool_or(
      invoice.status = 'pending' and invoice.due_date = current_date
    ), false) as has_due_today
  from public.invoices as invoice
  where invoice.student_id = student.id
    and invoice.trainer_id = student.trainer_id
) as invoice_summary on true
left join lateral (
  select max(payment.payment_date) as last_payment_date
  from public.payments as payment
  where payment.student_id = student.id
    and payment.trainer_id = student.trainer_id
    and payment.status = 'confirmed'
) as payment_summary on true;

grant select on public.student_financial_summary to authenticated;
grant select on public.student_financial_summary to service_role;
