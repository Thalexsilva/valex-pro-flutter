import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/models/student_model.dart';
import 'package:valex_app/repositories/student_repository.dart';
import 'package:valex_app/repositories/workout_repository.dart';
import 'package:valex_app/repositories/preset_repository.dart';

void main() {
  group('Testes de Repositórios Supabase (Student, Workout, Preset)', () {
    test('StudentRepository deve tratar estado sem sessão gracioso', () async {
      final repo = StudentRepository();
      final students = await repo.fetchStudents();
      expect(students, isA<List<Student>>());

      final record = await repo.fetchStudentRecord('st_1');
      expect(record, isNull);

      final timeline = await repo.fetchTimeline('st_1');
      expect(timeline, isEmpty);

      final finance = await repo.fetchFinancialSummary('st_1');
      expect(finance.badge, FinancialBadge.noInvoice);
    });

    test('WorkoutRepository deve tratar estado sem sessão gracioso', () async {
      final repo = WorkoutRepository();
      final sheet = await repo.fetchActiveSheet('st_1');
      expect(sheet, isNull);

      final versions = await repo.fetchVersionHistory('st_1');
      expect(versions, isEmpty);
    });

    test('PresetRepository deve tratar estado sem sessão gracioso', () async {
      final repo = PresetRepository();
      final presets = await repo.fetchPresets();
      expect(presets, isEmpty);
    });
  });
}
