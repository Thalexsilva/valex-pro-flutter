import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/models/workout_model.dart';

void main() {
  group('WorkoutModel Data Serialization & Tonnage Tests', () {
    test('WorkoutSheet volumeSummary calculates correct tonnage', () {
      final sheet = WorkoutSheet(
        studentId: '123',
        studentName: 'Test Student',
        days: [
          WorkoutDay(
            dow: 'A',
            muscle: 'Chest',
            exercises: [
              Exercise(
                title: 'Bench Press',
                loadKg: '30.5',
                sets: ['10', '10', '10'],
              ), // 3 * 30.5 = 91.5
              Exercise(
                title: 'Fly',
                loadKg: '15',
                sets: ['12', '12'],
              ), // 2 * 15 = 30
            ],
          ),
          WorkoutDay(
            dow: 'B',
            muscle: 'Back',
            exercises: [
              Exercise(
                title: 'Pullup',
                loadKg: '0',
                sets: ['10', '10', '10'],
              ), // 3 * 0 = 0
              Exercise(
                title: 'Row',
                loadKg: '40,5',
                sets: ['10', '10', '10', '10'],
              ), // 4 * 40.5 = 162
            ],
          ),
        ],
      );

      final summary = sheet.volumeSummary;
      expect(summary['totalEx'], equals(4));
      expect(summary['totalSets'], equals(12));
      expect(
        summary['totalTonnageKg'],
        closeTo(91.5 + 30 + 0 + 162, 0.001),
      ); // 283.5
    });

    test(
      'Data model serialization (toJson / fromJson) correctly handles comma and decimal loads',
      () {
        final sheet = WorkoutSheet(
          studentId: '123',
          studentName: 'Test Student',
          days: [
            WorkoutDay(
              dow: 'A',
              muscle: 'Chest',
              exercises: [
                Exercise(
                  title: 'Bench Press',
                  loadKg: '30,5',
                  sets: ['10', '10', '10'],
                ),
              ],
            ),
          ],
        );

        final json = sheet.toJson();
        final restored = WorkoutSheet.fromJson(json);

        expect(restored.days.first.exercises.first.loadKg, equals('30,5'));
      },
    );
  });
}
