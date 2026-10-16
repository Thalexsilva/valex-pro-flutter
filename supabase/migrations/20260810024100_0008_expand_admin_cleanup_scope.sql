-- Migration: 20260810024100_0008_expand_admin_cleanup_scope.sql
-- Descrição: Expande admin_cleanup_test_data para limpar student_records e student_timeline
--            além de workout_sheets e sheet_versions.
--            Adiciona suporte a busca por prefixo de marcador (p_marker LIKE prefix%).

CREATE OR REPLACE FUNCTION public.admin_cleanup_test_data(p_student_id uuid, p_marker text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
declare
  v_versions_count int;
  v_sheets_count int;
  v_records_count int;
  v_timeline_count int;
begin
  -- Ordem de deleção respeita FKs: dependentes primeiro
  delete from public.sheet_versions where student_id = p_student_id;
  get diagnostics v_versions_count = row_count;

  delete from public.workout_sheets
    where student_id = p_student_id
       or instructor_notes like p_marker || '%';
  get diagnostics v_sheets_count = row_count;

  delete from public.student_timeline where student_id = p_student_id;
  get diagnostics v_timeline_count = row_count;

  delete from public.student_records where student_id = p_student_id;
  get diagnostics v_records_count = row_count;

  return jsonb_build_object(
    'sheet_versions_deleted', v_versions_count,
    'workout_sheets_deleted', v_sheets_count,
    'student_records_deleted', v_records_count,
    'student_timeline_deleted', v_timeline_count
  );
end;
$$;

-- Mantém ACL estrita: apenas service_role e postgres
REVOKE ALL ON FUNCTION public.admin_cleanup_test_data(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_cleanup_test_data(uuid, text) FROM anon;
REVOKE ALL ON FUNCTION public.admin_cleanup_test_data(uuid, text) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.admin_cleanup_test_data(uuid, text) TO service_role;
