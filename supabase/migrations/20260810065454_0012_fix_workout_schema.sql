-- Migration: 20260810065454_0012_fix_workout_schema.sql
-- Descrição: Padroniza colunas em português para inglês e adiciona soft delete às tabelas de presets e prontuários

-- 1. Renomear colunas na tabela workout_sheets
alter table public.workout_sheets rename column academia to gym_name;
alter table public.workout_sheets rename column mes to month;
alter table public.workout_sheets rename column observacoes to general_notes;

-- 2. Adicionar soft delete em custom_presets e student_records
alter table public.custom_presets add column deleted_at timestamptz;
alter table public.student_records add column deleted_at timestamptz;
