import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/models/training_methods.dart';
import 'package:valex_app/models/workout_model.dart';

void main() {
  group('TrainingMethods - Catálogo de métodos', () {
    test(
      'caminhada e corrida não são oferecidas para outros aparelhos cardio',
      () {
        final method = TrainingMethods.getMethod('caminhada_corrida');
        expect(
          TrainingMethods.isCompatibleWithExercise(
            method,
            'cardio',
            title: 'Corrida na esteira',
          ),
          isTrue,
        );
        expect(
          TrainingMethods.isCompatibleWithExercise(
            method,
            'cardio',
            title: 'Bicicleta ergométrica',
          ),
          isFalse,
        );
        expect(
          TrainingMethods.isCompatibleWithExercise(
            method,
            'cardio',
            title: 'Remo seco',
          ),
          isFalse,
        );
        expect(
          TrainingMethods.getMethod('pausa_isometrica').requiresPosition,
          isTrue,
        );
        expect(
          TrainingMethods.getMethod('mobilidade_ativa').requiresPosition,
          isTrue,
        );
      },
    );
    test('abrange as técnicas existentes e as novas famílias', () {
      expect(TrainingMethods.all.length, greaterThanOrEqualTo(40));
      expect(
        TrainingMethods.all.map((m) => m.id).toSet(),
        containsAll([
          'tradicional',
          'piramide_crescente',
          'piramide_invertida',
          'repeticao_forcada',
          'progressao_carga',
          'drop_set',
          'rest_pause',
          'cluster_set',
          'bi_set',
          'hiit_tiros',
          'tabata_cardio',
          'liss_continuo',
          'fartlek_variado',
          'piramide_aerobica',
          'hill_climb_resistencia',
          'superset_antagonista',
          'tri_set',
          'giant_set',
          'circuito_resistido',
          'alongamento_estatico',
          'mobilidade_dinamica',
        ]),
      );
    });

    test('cada método oferece contexto e séries editáveis identificadas', () {
      final ids = <String>{};
      for (final method in TrainingMethods.all) {
        expect(
          ids.add(method.id),
          isTrue,
          reason: 'ID duplicado: ${method.id}',
        );
        expect(method.goals, isNotEmpty);
        expect(method.level, isNotEmpty);
        expect(method.guidance, isNotEmpty);
        expect(method.aliases, isNotEmpty);
        expect(method.sets, isNotEmpty);
        for (final set in method.sets) {
          expect(set, matches(r'^\[(work|prep|warmup)\].+'));
        }
      }
    });

    test(
      'categoria explícita orienta compatibilidade, com fallback legado',
      () {
        expect(
          TrainingMethods.categoryForExercise('stretching', muscle: 'Peito'),
          'mobilidade',
        );
        expect(
          TrainingMethods.categoryForExercise('cardio', muscle: 'Pernas'),
          'cardio',
        );
        expect(
          TrainingMethods.categoryForExercise('', muscle: 'Cardio'),
          'cardio',
        );
        expect(
          TrainingMethods.categoryForExercise('', muscle: 'Aeróbico'),
          'cardio',
        );
        expect(
          TrainingMethods.categoryForExercise('strength', muscle: 'Cardio'),
          'musculacao',
        );
        expect(
          TrainingMethods.isCompatibleWithExercise(
            TrainingMethods.getMethod('drop_set'),
            'stretching',
          ),
          isFalse,
        );
        expect(
          TrainingMethods.isCompatibleWithExercise(
            TrainingMethods.getMethod('alongamento_estatico'),
            'stretching',
          ),
          isTrue,
        );
      },
    );

    test('prescrições geradas não alteram os modelos da biblioteca', () {
      final original = TrainingMethods.getMethod('cluster_set').sets.first;
      final generated = TrainingMethods.generateSetsForMethod('cluster_set');
      generated[0] = '[work]Prescrição personalizada';
      expect(TrainingMethods.getMethod('cluster_set').sets.first, original);
    });

    test('métodos combinados exigem identificação dos parceiros', () {
      for (final id in [
        'bi_set',
        'tri_set',
        'giant_set',
        'superset_antagonista',
        'pre_exaustao',
        'pos_exaustao',
        'drop_mecanico',
        'circuito_resistido',
      ]) {
        expect(
          TrainingMethods.getMethod(id).requiresCompanionExercises,
          isTrue,
          reason: id,
        );
      }
    });

    test('Should correctly identify Strength methods vs Cardio methods', () {
      final strengthMethods = TrainingMethods.all
          .where((m) => m.category == 'musculacao')
          .toList();
      final cardioMethods = TrainingMethods.all
          .where((m) => m.category == 'cardio')
          .toList();

      expect(strengthMethods.length, greaterThanOrEqualTo(26));
      expect(cardioMethods.length, greaterThanOrEqualTo(10));
      expect(
        TrainingMethods.all.where((m) => m.category == 'mobilidade').length,
        4,
      );
    });

    test(
      'Should generate formatted sets with tags for "piramide_crescente"',
      () {
        final sets = TrainingMethods.generateSetsForMethod(
          'piramide_crescente',
        );
        expect(sets.length, 4);
        expect(sets[0], contains('[prep]'));
        expect(sets[1], contains('[work]'));
        expect(sets[2], contains('[work]'));
        expect(sets[3], contains('[work]'));
      },
    );

    test('Should generate formatted sets with tags for "drop_set"', () {
      final sets = TrainingMethods.generateSetsForMethod('drop_set');
      expect(sets.length, 3);
      expect(sets[0], contains('[prep]'));
      expect(sets[1], contains('[work]'));
      expect(sets[2], contains('Drop-Set'));
    });

    test('Should generate formatted aerobic blocks for "hiit_tiros"', () {
      final sets = TrainingMethods.generateSetsForMethod('hiit_tiros');
      expect(sets.length, 3);
      expect(sets[0], contains('[warmup]'));
      expect(sets[1], contains('Tiros 1 a 8'));
      expect(sets[2], contains('[warmup]Desaquecimento'));
    });

    test('Should fallback to default method if unknown ID provided', () {
      final method = TrainingMethods.getMethod('non_existent_method');
      expect(method.id, 'tradicional');
    });
  });

  group('WorkoutSheet - Dynamic Volume & Tonnage Breakdown', () {
    test('Should calculate sets and tonnage per muscle group correctly', () {
      final sheet = WorkoutSheet(
        studentId: 'st_test',
        studentName: 'Atleta Teste',
        days: [
          WorkoutDay(
            dow: 'Treino A',
            muscle: 'Peito & Tríceps',
            exercises: [
              Exercise(
                title: 'Supino Reto',
                muscle: 'Peito',
                loadKg: '100',
                sets: [
                  '[prep]10 reps @ 60kg',
                  '[work]8 reps @ 100kg',
                  '[work]8 reps @ 100kg',
                ],
              ),
              Exercise(
                title: 'Tríceps Corda',
                muscle: 'Tríceps',
                loadKg: '30',
                sets: ['10 reps', '10 reps', '10 reps'],
              ),
            ],
          ),
          WorkoutDay(
            dow: 'Treino B',
            muscle: 'Costas',
            exercises: [
              Exercise(
                title: 'Puxada Frontal',
                muscle: 'Costas',
                loadKg: '70',
                sets: ['12 reps', '10 reps', '8 reps', '8 reps'],
              ),
            ],
          ),
        ],
      );

      final summary = sheet.volumeSummary;
      expect(summary['totalEx'], 3);
      expect(summary['totalSets'], 10);
      expect(summary['totalTonnageKg'], greaterThan(0));

      final muscleSets = summary['muscleSets'] as Map<String, int>;
      expect(muscleSets['Peito'], 3);
      expect(muscleSets['Tríceps'], 3);
      expect(muscleSets['Costas'], 4);

      final muscleTonnage = summary['muscleTonnage'] as Map<String, double>;
      expect(muscleTonnage['Peito'], 260.0); // 60 + 100 + 100
      expect(muscleTonnage['Tríceps'], 90.0); // 30 * 3
      expect(muscleTonnage['Costas'], 280.0); // 70 * 4
    });
  });
}
