-- Migration: 20260802020000_0002_workout_and_records_schema.sql
-- Descrição: Schema relacional oficial para persistência de Fichas de Treino, Histórico de Versões, Presets e Prontuários com FKs compostas por tenant (trainer_id)

-- 1. Tabela: workout_sheets (Fichas de Treino Ativas por Aluno)
create table if not exists public.workout_sheets (
    id uuid primary key default gen_random_uuid(),
    trainer_id uuid not null references auth.users(id),
    student_id uuid not null,
    student_name text not null,
    academia text,
    mes text,
    instructor_notes text,
    status text not null default 'active' check (status in ('active', 'archived')),
    days jsonb not null default '[]'::jsonb,
    cardio_options jsonb not null default '[]'::jsonb,
    observacoes jsonb not null default '[]'::jsonb,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (id, trainer_id),
    constraint uq_workout_sheets_student_tenant unique (student_id, trainer_id),
    foreign key (student_id, trainer_id) references public.students(id, trainer_id)
);

-- 2. Tabela: sheet_versions (Histórico de Versões Append-Only vinculado a Ficha e Aluno)
create table if not exists public.sheet_versions (
    id uuid primary key default gen_random_uuid(),
    trainer_id uuid not null references auth.users(id),
    workout_sheet_id uuid not null,
    student_id uuid not null,
    version_name text not null,
    sheet_data jsonb not null,
    created_at timestamptz not null default now(),
    unique (id, trainer_id),
    foreign key (workout_sheet_id, trainer_id) references public.workout_sheets(id, trainer_id),
    foreign key (student_id, trainer_id) references public.students(id, trainer_id)
);

-- 3. Tabela: custom_presets (Presets Personalizados do Treinador)
create table if not exists public.custom_presets (
    id uuid primary key default gen_random_uuid(),
    trainer_id uuid not null references auth.users(id),
    preset_title text not null,
    description text,
    sheet_data jsonb not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (id, trainer_id)
);

-- 4. Tabela: student_records (Prontuário & Anamnese do Aluno)
create table if not exists public.student_records (
    id uuid primary key default gen_random_uuid(),
    trainer_id uuid not null references auth.users(id),
    student_id uuid not null,
    medical_notes text,
    body_perception text,
    health_history text,
    limitations text,
    current_activity text,
    diet_habits text,
    lifestyle_habits text,
    physical_assessment text,
    exercise_preferences text,
    has_professional_assistance text,
    student_additional_notes text,
    target_muscles text,
    birth_date date,
    anamnese_full_data jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (id, trainer_id),
    constraint uq_student_records_tenant unique (student_id, trainer_id),
    foreign key (student_id, trainer_id) references public.students(id, trainer_id)
);

comment on table public.student_records is 'Fonte de verdade da anamnese: colunas nomeadas tipadas. anamnese_full_data atua como staging bruto (dado original como veio, sem tratamento) para fallback.';

-- Habilitar Row Level Security (RLS) em 100% das tabelas
alter table public.workout_sheets enable row level security;
alter table public.sheet_versions enable row level security;
alter table public.custom_presets enable row level security;
alter table public.student_records enable row level security;

-- Policies para workout_sheets (Select, Insert, Update)
create policy workout_sheets_select_policy on public.workout_sheets for select using (trainer_id = auth.uid());
create policy workout_sheets_insert_policy on public.workout_sheets for insert with check (trainer_id = auth.uid());
create policy workout_sheets_update_policy on public.workout_sheets for update using (trainer_id = auth.uid());

-- Policies para sheet_versions (Append-Only: Select, Insert apenas)
create policy sheet_versions_select_policy on public.sheet_versions for select using (trainer_id = auth.uid());
create policy sheet_versions_insert_policy on public.sheet_versions for insert with check (trainer_id = auth.uid());

-- Policies para custom_presets (Select, Insert, Update)
create policy custom_presets_select_policy on public.custom_presets for select using (trainer_id = auth.uid());
create policy custom_presets_insert_policy on public.custom_presets for insert with check (trainer_id = auth.uid());
create policy custom_presets_update_policy on public.custom_presets for update using (trainer_id = auth.uid());

-- Policies para student_records (Select, Insert, Update)
create policy student_records_select_policy on public.student_records for select using (trainer_id = auth.uid());
create policy student_records_insert_policy on public.student_records for insert with check (trainer_id = auth.uid());
create policy student_records_update_policy on public.student_records for update using (trainer_id = auth.uid());
