import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:valex_app/repositories/workout_repository.dart';
import 'package:valex_app/services/backup_service.dart';
import 'package:valex_app/services/student_context_service.dart';
import 'package:valex_app/models/workout_model.dart';
import '../support/student_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('remote workout reads current and legacy general notes', () async {
    var legacy = false;
    var missing = false;
    var failed = false;
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-key',
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        localStorage: EmptyLocalStorage(),
      ),
      httpClient: MockClient(
        (request) async => http.Response(
          failed
              ? 'server error'
              : jsonEncode(
                  missing
                      ? []
                      : [
                          {
                            'student_id': 'student-1',
                            if (legacy)
                              'observacoes': ['Legado']
                            else
                              'general_notes': ['Descanso de 60 segundos'],
                          },
                        ],
                ),
          failed ? 503 : 200,
          request: request,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    addTearDown(() => Supabase.instance.dispose());
    final repository = WorkoutRepository();
    expect((await repository.fetchActiveSheet('student-1'))!.generalNotes, [
      'Descanso de 60 segundos',
    ]);
    legacy = true;
    expect((await repository.fetchActiveSheet('student-1'))!.generalNotes, [
      'Legado',
    ]);
    missing = true;
    expect(
      (await repository.fetchActiveSheetResult('student-1')).status,
      ActiveWorkoutLoadStatus.empty,
    );
    failed = true;
    expect(
      (await repository.fetchActiveSheetResult('student-1')).status,
      ActiveWorkoutLoadStatus.error,
    );
  });

  test('backup rejects unknown schema versions', () async {
    final result = await BackupService().importFullBackup(
      jsonEncode({
        'schemaVersion': 999,
        'data': {'students': []},
      }),
    );
    expect(result['success'], false);
  });

  test(
    'offline backup, versions and presets preserve the complete sheet',
    () async {
      final context = StudentContextService.forTesting(
        allowOfflineWrites: true,
        initialStudents: testStudents,
      );
      await context.init();
      final sheet = WorkoutSheet(
        studentId: 'st_1',
        studentName: 'Carlos Silva',
        generalNotes: ['Observação beta'],
        cardioOptions: ['Caminhada'],
        days: [
          WorkoutDay(
            dow: 'A',
            muscle: 'Core',
            exercises: [
              Exercise(
                title: 'Prancha',
                image: 'https://example.com/image.png',
              ),
            ],
          ),
        ],
      );
      expect(await context.saveActiveSheet(sheet), true);
      expect(await context.saveVersionSnapshot(sheet, 'Beta'), true);
      expect(await context.saveCustomPreset(sheet, 'Beta preset'), true);
      for (final copy in [
        context.getVersionHistory('st_1').first,
        context.customPresets.last,
      ]) {
        expect(copy.generalNotes, sheet.generalNotes);
        expect(copy.cardioOptions, sheet.cardioOptions);
        expect(
          copy.days.first.exercises.first.image,
          sheet.days.first.exercises.first.image,
        );
      }
      final backup =
          jsonDecode(
                await BackupService(
                  studentContext: context,
                  salesRepository: EmptySalesRepository(),
                ).exportFullBackup(),
              )
              as Map;
      final restored = WorkoutSheet.fromJson(
        Map<String, dynamic>.from(backup['data']['workouts']['st_1'] as Map),
      );
      expect(restored.generalNotes, sheet.generalNotes);
    },
  );

  test('backup rejects workout assigned to a different student', () async {
    final result = await BackupService().importFullBackup(
      jsonEncode({
        'schemaVersion': 3,
        'data': {
          'workouts': {
            'student-a': {'studentId': 'student-b', 'days': []},
          },
        },
      }),
    );
    expect(result['success'], false);
  });
}
