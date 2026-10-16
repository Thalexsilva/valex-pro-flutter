-- Migration: 20260809221000_0005_lock_down_admin_cleanup.sql
-- Descrição: Lock down completo da função administrativa admin_cleanup_test_data para uso exclusivo da service_role

CREATE OR REPLACE FUNCTION public.admin_cleanup_test_data(p_student_id uuid, p_marker text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
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

-- 2. Concede EXECUTE exclusivamente para a service_role (usada unicamente no test harness isolado)
GRANT EXECUTE ON FUNCTION public.admin_cleanup_test_data(uuid, text) TO service_role;
