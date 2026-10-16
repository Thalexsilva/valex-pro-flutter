-- Migration: 20260810032500_0011_scope_cleanup_to_exact_run.sql
-- Descrição: Restringe o cleanup administrativo exclusivamente aos registros criados pela própria
--            run de integração, evitando limpeza indiscriminada de todo o histórico da fixture dedicada.
--            Remove student_records e student_timeline que estão fora do escopo da suíte live.

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
  if p_student_id != 'b2c3d4e5-f6a7-8901-bcde-f23456789012'::uuid then
    raise exception 'invalid integration-test student';
  end if;

  if p_marker is null
     or length(p_marker) <= 17
     or p_marker not like 'TESTE_REAL_PROVA_%'
  then
    raise exception 'invalid integration-test marker';
  end if;
  
  if p_marker = 'TESTE_REAL_PROVA_' then
    raise exception 'invalid integration-test marker';
  end if;

  delete from public.sheet_versions 
    where student_id = p_student_id
      and version_name = p_marker;
  get diagnostics v_versions_count = row_count;

  delete from public.workout_sheets
    where student_id = p_student_id
      and instructor_notes = p_marker;
  get diagnostics v_sheets_count = row_count;

  return jsonb_build_object(
    'sheet_versions_deleted', v_versions_count,
    'workout_sheets_deleted', v_sheets_count
  );
end;
$$;

REVOKE ALL ON FUNCTION public.admin_cleanup_test_data(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_cleanup_test_data(uuid, text) FROM anon;
REVOKE ALL ON FUNCTION public.admin_cleanup_test_data(uuid, text) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.admin_cleanup_test_data(uuid, text) TO service_role;
