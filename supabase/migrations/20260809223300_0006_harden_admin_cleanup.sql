-- Migration: 20260809223300_0006_harden_admin_cleanup.sql
-- Descrição: Hardening de segurança com search_path seguro e qualificadores explícitos de schema

CREATE OR REPLACE FUNCTION public.admin_cleanup_test_data(p_student_id uuid, p_marker text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
declare
  v_versions_count int;
  v_sheets_count int;
begin
  delete from public.sheet_versions where student_id = p_student_id;
  get diagnostics v_versions_count = row_count;

  delete from public.workout_sheets where student_id = p_student_id or instructor_notes = p_marker;
  get diagnostics v_sheets_count = row_count;

  return jsonb_build_object(
    'sheet_versions_deleted', v_versions_count,
    'workout_sheets_deleted', v_sheets_count
  );
end;
$$;

-- 1. Revoga privilégios de execução de PUBLIC, anon e authenticated
REVOKE ALL ON FUNCTION public.admin_cleanup_test_data(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_cleanup_test_data(uuid, text) FROM anon;
REVOKE ALL ON FUNCTION public.admin_cleanup_test_data(uuid, text) FROM authenticated;

-- 2. Concede EXECUTE exclusivamente para a service_role
GRANT EXECUTE ON FUNCTION public.admin_cleanup_test_data(uuid, text) TO service_role;
