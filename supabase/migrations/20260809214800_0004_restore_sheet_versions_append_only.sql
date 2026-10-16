-- Migration: 20260809214800_0004_restore_sheet_versions_append_only.sql
-- Descrição: Restauração estrita do contrato Append-Only para sheet_versions (ON DELETE RESTRICT)

-- 1. Remove a Foreign Key com CASCADE caso tenha sido aplicada anteriormente
ALTER TABLE public.sheet_versions
    DROP CONSTRAINT IF EXISTS sheet_versions_workout_sheet_id_trainer_id_fkey;

-- 2. Recria a Foreign Key garantindo ON DELETE RESTRICT (append-only estrito)
ALTER TABLE public.sheet_versions
    ADD CONSTRAINT sheet_versions_workout_sheet_id_trainer_id_fkey
    FOREIGN KEY (workout_sheet_id, trainer_id)
    REFERENCES public.workout_sheets (id, trainer_id)
    ON DELETE RESTRICT;

-- 3. Remoção de policy permissiva de DELETE em workout_sheets para preservar integridade relacional
DROP POLICY IF EXISTS workout_sheets_delete_policy ON public.workout_sheets;
