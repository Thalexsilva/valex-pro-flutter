import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/models/one_rm_engine.dart';
import 'package:valex_app/models/ai_workout_engine.dart';

void main() {
  group('OneRmEngine - Scientific Formulations & Intensity Zones', () {
    test('Calculates 1RM using Epley formula correctly', () {
      // 1RM = 100 * (1 + 10/30) = 100 * 1.333 = 133 kg
      final rm = OneRmEngine.calculate1RM(100, 10, formula: 'epley');
      expect(rm, 133);
    });

    test('Calculates 1RM using Brzycki formula correctly', () {
      // 1RM = 100 / (1.0278 - (0.0278 * 10)) = 100 / 0.7498 = 133 kg
      final rm = OneRmEngine.calculate1RM(100, 10, formula: 'brzycki');
      expect(rm, 133);
    });

    test('Calculates 1RM using Lander formula correctly', () {
      // 1RM = (100 * 100) / (101.3 - (2.67123 * 10)) = 10000 / 74.5877 = 134 kg
      final rm = OneRmEngine.calculate1RM(100, 10, formula: 'lander');
      expect(rm, 134);
    });

    test('Generates all 10 Intensity Zones with accurate target loads', () {
      final zones = OneRmEngine.getIntensityZones(100);
      expect(zones.length, 10);
      expect(zones[0].pct, 100);
      expect(zones[0].targetKg, 100);
      expect(zones[0].zone, 'Força Máxima');

      expect(zones[3].pct, 85);
      expect(zones[3].targetKg, 85);
      expect(zones[3].zone, 'Hipertrofia Densa');

      expect(zones[9].pct, 50);
      expect(zones[9].targetKg, 50);
      expect(zones[9].zone, 'Preparação Articular');
    });

    test('Handles edge cases (0 load or 1 rep)', () {
      expect(OneRmEngine.calculate1RM(0, 10), 0);
      expect(OneRmEngine.calculate1RM(100, 1), 100);
    });
  });

  group('AiWorkoutEngine - Clinical Prescription & Biomechanical Filtering', () {
    test(
      'Filters out knee-compromised exercises when knee pain is reported',
      () {
        final result = AiWorkoutEngine.generateSheetFromAnamnese(
          anamneseText:
              'Aluno com condromalácia patelar e dor crônica no joelho direito.',
          studentName: 'Atleta Teste',
        );

        expect(result.days.isNotEmpty, true);
        expect(result.summaryNotes, contains('⚠️ Ajuste por dor articular'));

        // Verifica se nenhum exercício contraindicado foi inserido
        for (var day in result.days) {
          for (var ex in day.exercises) {
            expect(ex.title.toLowerCase().contains('sissy'), false);
            expect(ex.title.toLowerCase().contains('passada'), false);
          }
        }
      },
    );

    test('Structures 4-day split (ABCD) when 4x/week is requested', () {
      final result = AiWorkoutEngine.generateSheetFromAnamnese(
        anamneseText:
            'Frequência de 4 dias na semana, foco em hipertrofia avançada.',
        studentName: 'Atleta Teste',
      );

      expect(result.days.length, 4);
      expect(result.days[0].dow, 'Treino A');
      expect(result.days[1].dow, 'Treino B');
      expect(result.days[2].dow, 'Treino C');
      expect(result.days[3].dow, 'Treino D');
    });

    test('Structures 2-day split (AB) when 2x/week is requested', () {
      final result = AiWorkoutEngine.generateSheetFromAnamnese(
        anamneseText: 'Disponibilidade de 2x por semana.',
        studentName: 'Atleta Teste',
      );

      expect(result.days.length, 2);
      expect(result.days[0].dow, 'Treino A');
      expect(result.days[1].dow, 'Treino B');
    });
  });
}
