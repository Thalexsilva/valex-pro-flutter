-- Migration: 0007_add_workout_indexes.sql
-- Descrição: Índices compostos para acelerar consultas filtradas por tenant (trainer_id) e FKs nas tabelas de treino

-- 1. Índices para workout_sheets
CREATE INDEX IF NOT EXISTS idx_workout_sheets_trainer_student ON public.workout_sheets(trainer_id, student_id);
CREATE INDEX IF NOT EXISTS idx_workout_sheets_trainer_status ON public.workout_sheets(trainer_id, status);

-- 2. Índices para sheet_versions
CREATE INDEX IF NOT EXISTS idx_sheet_versions_trainer_workout_sheet ON public.sheet_versions(trainer_id, workout_sheet_id);
CREATE INDEX IF NOT EXISTS idx_sheet_versions_trainer_student ON public.sheet_versions(trainer_id, student_id);

-- 3. Índices para custom_presets
CREATE INDEX IF NOT EXISTS idx_custom_presets_trainer ON public.custom_presets(trainer_id);

-- 4. Índices para student_records
CREATE INDEX IF NOT EXISTS idx_student_records_trainer_student ON public.student_records(trainer_id, student_id);
