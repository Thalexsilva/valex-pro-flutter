-- Migration: 20260810030500_0010_harden_integration_cleanup_identity.sql
-- Descrição: Trava o cleanup administrativo no student ID dedicado de integração
--            e exige um marker único exato gerado para o run atual, impedindo
--            prefix matching amplo ou IDs de alunos reais.

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
  -- Travar o ID do estudante à fixture dedicada para testes de integração
  if p_student_id != 'b2c3d4e5-f6a7-8901-bcde-f23456789012'::uuid then
    raise exception 'invalid integration-test student';
  end if;

  -- Validação estrita do marcador de integração para fail-closed (Run ID único)
  if p_marker is null
     or length(p_marker) <= 17
     or p_marker not like 'TESTE_REAL_PROVA_%'
  then
    raise exception 'invalid integration-test marker';
  end if;
  
  if p_marker = 'TESTE_REAL_PROVA_' then
    raise exception 'invalid integration-test marker';
  end if;

  -- Ordem de deleção respeita FKs: dependentes primeiro
  delete from public.sheet_versions where student_id = p_student_id;
  get diagnostics v_versions_count = row_count;

  -- Limpeza exata de workout_sheets usando AND ao invés de OR amplo
  delete from public.workout_sheets
    where student_id = p_student_id
      and instructor_notes = p_marker;
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
