-- Migration: 0013_add_delete_policies.sql
-- Description: Add missing DELETE policies for workout_sheets, custom_presets, and student_records to fully enforce trainer_id isolation.

-- Add DELETE policy for workout_sheets
drop policy if exists workout_sheets_delete_policy on public.workout_sheets;
create policy workout_sheets_delete_policy on public.workout_sheets for delete to authenticated using (trainer_id = auth.uid());

-- Add DELETE policy for custom_presets
drop policy if exists custom_presets_delete_policy on public.custom_presets;
create policy custom_presets_delete_policy on public.custom_presets for delete to authenticated using (trainer_id = auth.uid());

-- Add DELETE policy for student_records
drop policy if exists student_records_delete_policy on public.student_records;
create policy student_records_delete_policy on public.student_records for delete to authenticated using (trainer_id = auth.uid());
