import '../support/student_fixtures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valex_app/models/student_model.dart';
import 'package:valex_app/services/backup_service.dart';
import 'package:valex_app/services/student_context_service.dart';

void main() {
  late StudentContextService studentContext;
  BackupService service() => BackupService(
    studentContext: studentContext,
    salesRepository: EmptySalesRepository(),
  );
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    studentContext = StudentContextService.forTesting(allowOfflineWrites: true);
  });

  group('BackupService — Export, Validation, Import & Diagnostics', () {
    test('Exports full system backup with schemaVersion 3', () async {
      await studentContext.init();
      await studentContext.saveStudent(
        Student(
          id: 'std_test_1',
          name: 'Aluno Backup Teste',
          date: '2026-09-01',
          cpf: '12345678900',
          phone: '11999998888',
          email: 'teste@valex.app',
          address: 'Rua Teste, 100',
          niche: 'Hipertrofia',
          prontuarioText: 'Prontuário teste',
          gymName: 'Academia Valex',
          status: StudentStatus.active,
        ),
      );

      final backupService = service();
      final backupJson = await backupService.exportFullBackup();

      expect(backupJson, contains('"schemaVersion": 3'));
      expect(backupJson, contains('"valex_backup_version": 3'));
      expect(backupJson, contains('Aluno Backup Teste'));
      expect(backupJson, contains('"students":'));
      expect(backupJson, contains('"finance":'));
    });

    test('Validates and rejects malformed or empty backup payloads', () async {
      final backupService = service();

      final emptyRes = await backupService.importFullBackup('');
      expect(emptyRes['success'], isFalse);
      expect(emptyRes['message'], contains('vazio'));

      final invalidJsonRes = await backupService.importFullBackup(
        '{invalid_json}',
      );
      expect(invalidJsonRes['success'], isFalse);

      final missingVersionRes = await backupService.importFullBackup(
        '{"students": []}',
      );
      expect(missingVersionRes['success'], isFalse);
      expect(missingVersionRes['message'], contains('schema'));
    });

    test(
      'Imports valid backup and populates repositories accurately',
      () async {
        final validPayload = '''
{
  "valex_backup_version": 3,
  "schemaVersion": 3,
  "data": {
    "students": [
      {
        "id": "std_restored_1",
        "name": "Aluno Restaurado",
        "date": "2026-09-01",
        "cpf": "",
        "phone": "11988887777",
        "email": "restaurado@valex.app",
        "address": "",
        "niche": "Consultoria",
        "prontuarioText": "",
        "gymName": "Academia Central",
        "status": "active"
      }
    ],
    "presets": [],
    "leads": [],
    "finance": {
      "schemaVersion": 3,
      "plans": [],
      "subscriptions": [],
      "invoices": [],
      "payments": [],
      "cashFlow": []
    }
  }
}
''';

        final backupService = service();
        final importRes = await backupService.importFullBackup(validPayload);

        expect(importRes['success'], isTrue);

        await studentContext.init();
        expect(
          studentContext.allStudents.any((s) => s.id == 'std_restored_1'),
          isTrue,
        );
      },
    );

    test('Collects live diagnostics without errors', () async {
      final backupService = service();
      final diag = await backupService.getDiagnostics();

      expect(diag.schemaVersion, equals(3));
      expect(diag.appVersion, '1.0.0+1');
      expect(diag.cacheIntegrity, 'Não verificada');
    });
  });
}
