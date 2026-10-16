import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File(
    'supabase/migrations/20260907021000_harden_anamnese_tenant_access.sql',
  ).readAsStringSync().toLowerCase();

  test('removes all four legacy anamnese policies', () {
    expect(RegExp('drop policy if exists').allMatches(sql), hasLength(4));
    expect(sql, isNot(contains('or trainer_id is null')));
  });

  test('restrictive guard validates both old and new student ownership', () {
    expect(sql, contains('as restrictive for all'));
    expect(sql, contains('to authenticated'));
    expect(sql, contains('using ('));
    expect(sql, contains('with check ('));
    expect(
      RegExp('students.id::text = student_anamneses.student_id').allMatches(sql),
      hasLength(2),
    );
    expect(
      RegExp(r'students.trainer_id = \(select auth.uid\(\)\)').allMatches(sql),
      hasLength(2),
    );
  });

  test('anonymous access is revoked and existing data is preserved', () {
    expect(sql, contains('revoke all on public.student_anamneses from anon'));
    expect(sql, isNot(contains('delete from')));
    expect(sql, isNot(contains('drop table')));
    expect(sql.trim(), endsWith('commit;'));
  });
}
