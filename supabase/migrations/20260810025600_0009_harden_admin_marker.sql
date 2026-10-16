-- Migration: 20260810025600_0009_harden_admin_marker.sql
-- Descrição: Endurece a função admin_cleanup_test_data para evitar que marcadores
--            vazios, nulos ou genéricos apaguem registros acidentalmente.

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
  -- Validação estrita do marcador de integração para fail-closed
  if p_marker is null
     or length(p_marker) < 16
     or p_marker not like 'TESTE_REAL_PROVA_%'
  then
    raise exception 'invalid integration-test marker: must match TESTE_REAL_PROVA_ prefix and have sufficient length';
  end if;

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

REVOKE ALL ON FUNCTION public.admin_cleanup_test_data(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_cleanup_test_data(uuid, text) FROM anon;
REVOKE ALL ON FUNCTION public.admin_cleanup_test_data(uuid, text) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.admin_cleanup_test_data(uuid, text) TO service_role;
