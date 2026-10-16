import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/models/workout_model.dart';

void main() {
  group('Paridade do Editor de Treinos & Cálculos de Volume', () {
    test('Cálculo de Tonnage (Séries x Carga) por Grupo Muscular', () {
      final dayA = WorkoutDay(
        dow: 'Treino A',
        muscle: 'Peito',
        exercises: [
          Exercise(
            title: 'Supino Reto',
            loadKg: '30',
            sets: ['10', '10', '10'],
          ), // 3 * 30 = 90 kg
          Exercise(
            title: 'Crucifixo',
            loadKg: '15',
            sets: ['10', '10'],
          ), // 2 * 15 = 30 kg
        ],
      );

      double totalTonnage = 0;
      for (var ex in dayA.exercises) {
        final setNum = ex.sets.length;
        final baseKg = double.tryParse(ex.loadKg) ?? 0;
        totalTonnage += setNum * baseKg;
      }

      expect(totalTonnage, equals(120.0));
    });

    test('Clonagem Profunda de Dia de Treino (Duplicação)', () {
      final original = WorkoutDay(
        dow: 'Treino A',
        muscle: 'Peito',
        exercises: [
          Exercise(title: 'Supino Reto', loadKg: '30', sets: ['12', '10']),
        ],
      );

      final clone = WorkoutDay(
        dow: '${original.dow} (Cópia)',
        muscle: original.muscle,
        cardio: original.cardio,
        exercises: original.exercises
            .map<Exercise>((e) => e.copyWith())
            .toList(),
      );

      // Alterar clone não deve afetar original
      clone.exercises[0].title = 'Supino Inclinado';
      clone.exercises[0].sets.add('8');

      expect(original.exercises[0].title, equals('Supino Reto'));
      expect(original.exercises[0].sets.length, equals(2));
      expect(clone.exercises[0].title, equals('Supino Inclinado'));
      expect(clone.exercises[0].sets.length, equals(3));
    });
  });
}
