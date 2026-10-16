import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const migrationPath =
      'supabase/migrations/20260902175645_harden_student_documents_storage.sql';

  late String migration;
  late String repository;

  setUpAll(() {
    // Checkouts no Windows podem gravar CRLF; as asserções usam '\n'.
    migration = File(
      migrationPath,
    ).readAsStringSync().replaceAll('\r\n', '\n').toLowerCase();
    repository = File(
      'lib/repositories/anamnese_repository.dart',
    ).readAsStringSync().replaceAll('\r\n', '\n');
  });

  test('student documents bucket is made private', () {
    expect(migration, contains("set public = false"));
    expect(migration, contains("where id = 'student-documents'"));
  });

  test('legacy bucket-wide policies are removed', () {
    expect(
      RegExp(r'drop policy if exists').allMatches(migration),
      hasLength(4),
    );
  });

  test('all storage operations require authenticated student ownership', () {
    for (final operation in ['select', 'insert', 'update', 'delete']) {
      expect(
        migration,
        contains('for $operation\n  to authenticated'),
        reason: '$operation must be restricted to authenticated users',
      );
    }

    expect(
      RegExp(r"bucket_id = 'student-documents'").allMatches(migration).length,
      greaterThanOrEqualTo(5),
    );
    expect(
      RegExp(
        r'\(storage\.foldername\(objects\.name\)\)\[1\]',
      ).allMatches(migration).length,
      greaterThanOrEqualTo(5),
    );
    expect(
      RegExp(
        r'students\.trainer_id = \(select auth\.uid\(\)\)',
      ).allMatches(migration).length,
      greaterThanOrEqualTo(5),
    );
  });

  test('update checks both the existing and resulting object path', () {
    final updatePolicy = RegExp(
      r'create policy student_documents_update_own_students[\s\S]*?;',
    ).firstMatch(migration)!.group(0)!;

    expect(updatePolicy, contains('using ('));
    expect(updatePolicy, contains('with check ('));
  });

  test('flutter stores private paths and resolves signed URLs for display', () {
    expect(repository, isNot(contains('.getPublicUrl(')));
    expect(repository, contains("'storage://student-documents/'"));
    expect(repository, contains('.createSignedUrl(path, 3600)'));
    expect(repository, contains('/object/public/student-documents/'));
  });
}
