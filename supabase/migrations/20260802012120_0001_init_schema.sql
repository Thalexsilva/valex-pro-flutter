-- Migration: 20260802012120_0001_init_schema.sql
-- Descricao: Schema relacional oficial da Fase 1 com FKs compostas por trainer_id

create extension if not exists "pgcrypto";

-- 1. ENUMs Oficiais
create type subscription_status as enum (
  'draft',
  'active',
  'paused',
  'cancelled',
  'expired'
);

create type invoice_status as enum (
  'draft',
  'pending',
  'overdue',
  'paid',
  'cancelled'
);

create type payment_status as enum (
  'confirmed',
  'refunded'
);

-- 2. Tabela: students (status: 'active' | 'archived')
create table students (
  id uuid primary key default gen_random_uuid(),
  trainer_id uuid not null references auth.users(id),
  name text not null,
  date date default current_date,
  teacher text,
  status text not null default 'active' check (status in ('active', 'archived')),
  cpf text,
  phone text,
  email text,
  address text,
  niche text,
  prontuario_text text,
  evolucao text,
  academia text,
  mes text,
  instructor_notes text,
  days jsonb default '[]'::jsonb,
  cardio_options jsonb default '[]'::jsonb,
  observacoes jsonb default '[]'::jsonb,
  versions jsonb default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, trainer_id)
);

-- 3. Tabela: plans
create table plans (
  id uuid primary key default gen_random_uuid(),
  trainer_id uuid not null references auth.users(id),
  name text not null,
  description text,
  category text,
  type text not null check (type in ('subscription', 'one_time')),
  price numeric(10,2) not null check (price >= 0),
  interval text default 'Mensal',
  active boolean not null default true,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  unique (id, trainer_id)
);

-- 4. Tabela: subscriptions
create table subscriptions (
  id uuid primary key default gen_random_uuid(),
  trainer_id uuid not null references auth.users(id),
  student_id uuid not null,
  plan_id uuid not null,
  status subscription_status not null default 'draft',
  contracted_value numeric(10,2) not null check (contracted_value >= 0),
  discount numeric(10,2) not null default 0 check (discount >= 0),
  readjustment numeric(10,2) not null default 0,
  cycle text not null default 'Mensal',
  start_date date not null default current_date,
  auto_renew boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, trainer_id),
  foreign key (student_id, trainer_id) references students(id, trainer_id),
  foreign key (plan_id, trainer_id) references plans(id, trainer_id)
);

-- 5. Tabela: one_time_sales
create table one_time_sales (
  id uuid primary key default gen_random_uuid(),
  trainer_id uuid not null references auth.users(id),
  student_id uuid not null,
  plan_id uuid,
  title text not null,
  amount numeric(10,2) not null check (amount >= 0),
  date date not null default current_date,
  status text not null default 'issued',
  created_at timestamptz not null default now(),
  unique (id, trainer_id),
  foreign key (student_id, trainer_id) references students(id, trainer_id),
  foreign key (plan_id, trainer_id) references plans(id, trainer_id)
);

-- 6. Tabela: invoices
create table invoices (
  id uuid primary key default gen_random_uuid(),
  trainer_id uuid not null references auth.users(id),
  student_id uuid not null,
  subscription_id uuid,
  one_time_sale_id uuid,
  plan_id uuid,
  type text not null check (type in ('subscription', 'one_time')),
  plan_snapshot jsonb,
  student_snapshot jsonb,
  original_amount numeric(10,2) not null check (original_amount >= 0),
  discount numeric(10,2) not null default 0 check (discount >= 0),
  fine numeric(10,2) not null default 0 check (fine >= 0),
  interest numeric(10,2) not null default 0 check (interest >= 0),
  final_amount numeric(10,2) not null check (final_amount >= 0),
  due_date date,
  status invoice_status not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, trainer_id),
  foreign key (student_id, trainer_id) references students(id, trainer_id),
  foreign key (subscription_id, trainer_id) references subscriptions(id, trainer_id),
  foreign key (one_time_sale_id, trainer_id) references one_time_sales(id, trainer_id),
  foreign key (plan_id, trainer_id) references plans(id, trainer_id),
  constraint check_invoice_snapshots check (
    (status = 'draft') or (plan_snapshot is not null and student_snapshot is not null)
  ),
  constraint check_invoice_due_date check (
    (status = 'draft') or (due_date is not null)
  )
);

-- 7. Tabela: payments
create table payments (
  id uuid primary key default gen_random_uuid(),
  trainer_id uuid not null references auth.users(id),
  invoice_id uuid not null,
  student_id uuid not null,
  amount numeric(10,2) not null check (amount >= 0),
  payment_date date not null default current_date,
  payment_method text not null,
  status payment_status not null default 'confirmed',
  notes text,
  created_at timestamptz not null default now(),
  foreign key (invoice_id, trainer_id) references invoices(id, trainer_id),
  foreign key (student_id, trainer_id) references students(id, trainer_id)
);

-- 8. Tabela: cash_flow (Append-only)
create table cash_flow (
  id uuid primary key default gen_random_uuid(),
  trainer_id uuid not null references auth.users(id),
  type text not null check (type in ('inflow', 'outflow')),
  amount numeric(10,2) not null check (amount >= 0),
  date date not null default current_date,
  category text not null,
  description text,
  reference_id uuid,
  invoice_id uuid,
  created_at timestamptz not null default now(),
  foreign key (invoice_id, trainer_id) references invoices(id, trainer_id)
);

-- 9. Tabela: audit_log (Append-only)
create table audit_log (
  id uuid primary key default gen_random_uuid(),
  trainer_id uuid not null references auth.users(id),
  timestamp timestamptz not null default now(),
  entity_type text not null,
  entity_id uuid not null,
  action text not null,
  description text,
  performed_by text not null,
  old_value jsonb,
  new_value jsonb,
  schema_version integer not null default 3
);

-- 10. Tabela: student_timeline (Append-only)
create table student_timeline (
  id uuid primary key default gen_random_uuid(),
  trainer_id uuid not null references auth.users(id),
  student_id uuid not null,
  timestamp timestamptz not null default now(),
  title text not null,
  description text,
  reference_type text,
  reference_id uuid,
  foreign key (student_id, trainer_id) references students(id, trainer_id)
);

-- 11. Tabela: subscription_history (Append-only)
create table subscription_history (
  id uuid primary key default gen_random_uuid(),
  trainer_id uuid not null references auth.users(id),
  subscription_id uuid not null,
  student_id uuid not null,
  timestamp timestamptz not null default now(),
  action text not null,
  from_status text,
  to_status text,
  foreign key (subscription_id, trainer_id) references subscriptions(id, trainer_id),
  foreign key (student_id, trainer_id) references students(id, trainer_id)
);

-- Trigger de Integridade Financeira 9a
create or replace function check_paid_invoice_has_payment()
returns trigger as $$
begin
  if new.status = 'paid' then
    if not exists (
      select 1 from payments
      where invoice_id = new.id
        and status = 'confirmed'
    ) then
      raise exception 'paid invoice requires a confirmed payment';
    end if;
  end if;
  return new;
end;
$$ language plpgsql;

create trigger trigger_check_paid_invoice_has_payment
before insert or update of status on invoices
for each row
execute function check_paid_invoice_has_payment();

-- Índices
create index idx_students_trainer_status on students(trainer_id, status);
create index idx_plans_trainer_status on plans(trainer_id, status);
create index idx_subscriptions_trainer_student on subscriptions(trainer_id, student_id);
create index idx_subscriptions_trainer_status on subscriptions(trainer_id, status);
create index idx_subscriptions_trainer_plan on subscriptions(trainer_id, plan_id);
create index idx_one_time_sales_trainer_student on one_time_sales(trainer_id, student_id);
create index idx_one_time_sales_trainer_status on one_time_sales(trainer_id, status);
create index idx_one_time_sales_trainer_date on one_time_sales(trainer_id, date);
create index idx_invoices_trainer_student on invoices(trainer_id, student_id);
create index idx_invoices_trainer_status on invoices(trainer_id, status);
create index idx_invoices_trainer_due_date on invoices(trainer_id, due_date);
create index idx_invoices_trainer_type on invoices(trainer_id, type);
create index idx_payments_trainer_student on payments(trainer_id, student_id);
create index idx_payments_trainer_invoice on payments(trainer_id, invoice_id);
create index idx_payments_trainer_status on payments(trainer_id, status);
create index idx_payments_trainer_date on payments(trainer_id, payment_date);
create index idx_payments_trainer_method on payments(trainer_id, payment_method);
create index idx_cash_flow_trainer_type on cash_flow(trainer_id, type);
create index idx_cash_flow_trainer_date on cash_flow(trainer_id, date);
create index idx_audit_log_trainer_entity_type on audit_log(trainer_id, entity_type);
create index idx_audit_log_trainer_entity_id on audit_log(trainer_id, entity_id);
create index idx_student_timeline_trainer_student on student_timeline(trainer_id, student_id);
create index idx_subscription_history_trainer_sub on subscription_history(trainer_id, subscription_id);
create index idx_subscription_history_trainer_student on subscription_history(trainer_id, student_id);

-- RLS
alter table students enable row level security;
alter table plans enable row level security;
alter table subscriptions enable row level security;
alter table one_time_sales enable row level security;
alter table invoices enable row level security;
alter table payments enable row level security;
alter table cash_flow enable row level security;
alter table audit_log enable row level security;
alter table student_timeline enable row level security;
alter table subscription_history enable row level security;

-- Policies Mutáveis (Select, Insert, Update)
create policy students_select_policy on students for select using (trainer_id = auth.uid());
create policy students_insert_policy on students for insert with check (trainer_id = auth.uid());
create policy students_update_policy on students for update using (trainer_id = auth.uid());

create policy plans_select_policy on plans for select using (trainer_id = auth.uid());
create policy plans_insert_policy on plans for insert with check (trainer_id = auth.uid());
create policy plans_update_policy on plans for update using (trainer_id = auth.uid());

create policy subscriptions_select_policy on subscriptions for select using (trainer_id = auth.uid());
create policy subscriptions_insert_policy on subscriptions for insert with check (trainer_id = auth.uid());
create policy subscriptions_update_policy on subscriptions for update using (trainer_id = auth.uid());

create policy one_time_sales_select_policy on one_time_sales for select using (trainer_id = auth.uid());
create policy one_time_sales_insert_policy on one_time_sales for insert with check (trainer_id = auth.uid());
create policy one_time_sales_update_policy on one_time_sales for update using (trainer_id = auth.uid());

create policy invoices_select_policy on invoices for select using (trainer_id = auth.uid());
create policy invoices_insert_policy on invoices for insert with check (trainer_id = auth.uid());
create policy invoices_update_policy on invoices for update using (trainer_id = auth.uid());

create policy payments_select_policy on payments for select using (trainer_id = auth.uid());
create policy payments_insert_policy on payments for insert with check (trainer_id = auth.uid());
create policy payments_update_policy on payments for update using (trainer_id = auth.uid());

-- cash_flow é ledger append-only; correção financeira é por novo lançamento de estorno, nunca edição retroativa (mesmo princípio de invoice paga e audit_log)
create policy cash_flow_select_policy on cash_flow for select using (trainer_id = auth.uid());
create policy cash_flow_insert_policy on cash_flow for insert with check (trainer_id = auth.uid());

-- Policies Append-Only (Select, Insert apenas)
create policy audit_log_select_policy on audit_log for select using (trainer_id = auth.uid());
create policy audit_log_insert_policy on audit_log for insert with check (trainer_id = auth.uid());

create policy student_timeline_select_policy on student_timeline for select using (trainer_id = auth.uid());
create policy student_timeline_insert_policy on student_timeline for insert with check (trainer_id = auth.uid());

create policy subscription_history_select_policy on subscription_history for select using (trainer_id = auth.uid());
create policy subscription_history_insert_policy on subscription_history for insert with check (trainer_id = auth.uid());
