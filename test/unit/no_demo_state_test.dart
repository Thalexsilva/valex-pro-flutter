import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valex_app/services/student_context_service.dart';
import 'package:valex_app/models/student_model.dart';
import 'package:valex_app/models/workout_model.dart';
import 'package:valex_app/repositories/marketing_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'signed-out context ignores legacy demo cache and refuses writes',
    () async {
      SharedPreferences.setMockInitialValues({
        'valex_students': jsonEncode([
          Student(id: 'legacy', name: 'Legacy demo').toJson(),
        ]),
      });
      final context = StudentContextService();
      context.clearSessionMemory();
      await context.init();
      expect(context.allStudents, isEmpty);
      expect(context.getActiveSheet().studentId, isEmpty);
      expect(context.getActiveSheet().days, isEmpty);
      expect(
        await context.saveStudent(Student(id: 'blocked', name: 'Blocked')),
        false,
      );
      expect(
        await context.saveActiveSheet(
          WorkoutSheet(studentId: 'blocked', studentName: 'Blocked'),
        ),
        false,
      );
      expect(context.allStudents, isEmpty);
    },
  );

  test('new account has no fabricated campaign metrics', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = MarketingRepository(accountId: () => 'new-trainer');
    expect(await repository.getCampaigns(), isEmpty);
  });
}
