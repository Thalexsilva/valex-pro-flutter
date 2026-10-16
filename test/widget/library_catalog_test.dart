import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/models/training_methods.dart';
import 'package:valex_app/models/workout_model.dart';
import 'package:valex_app/services/student_context_service.dart';
import 'package:valex_app/theme/app_theme.dart';
import 'package:valex_app/views/presets/presets_view.dart';
import 'package:valex_app/widgets/exercise_media.dart';

import '../support/student_fixtures.dart';
import 'editor_library_flow_test.dart' as flow;

Future<void> search(WidgetTester tester, String value) async {
  final finder = find.byKey(const ValueKey('exercise-library-search'));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'busca alias inglês mostra título português e equipamento filtra',
    (tester) async {
      await flow.mountLibrary(tester, (_) {});
      await search(tester, 'medium grip bench press');
      expect(find.text('Supino Reto com Barra'), findsOneWidget);
      await flow.tapVisible(
        tester,
        find.byKey(const ValueKey('exercise-library-filters')),
      );
      await flow.tapVisible(
        tester,
        find.byKey(const ValueKey('exercise-library-equipment-Todos')),
      );
      await tester.tap(find.text('Kettlebell').last);
      await tester.pumpAndSettle();
      expect(find.text('Nenhum exercício encontrado'), findsOneWidget);
      await flow.tapVisible(
        tester,
        find.byKey(const ValueKey('exercise-library-clear-filters')),
      );
      expect(find.text('2029 exercícios encontrados'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Cluster Set é escolhido na biblioteca antes da prescrição', (
    tester,
  ) async {
    final added = <Exercise>[];
    await flow.mountLibrary(tester, added.add);
    await tester.tap(find.text('Métodos'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('exercise-library-method-search')),
      'cluster sete',
    );
    await tester.pumpAndSettle();
    expect(find.text('1 método encontrado'), findsOneWidget);
    await flow.tapVisible(
      tester,
      find.byKey(const ValueKey('exercise-library-method-cluster_set')),
    );
    await flow.tapVisible(
      tester,
      find.byKey(const ValueKey('exercise-library-use-method-cluster_set')),
    );
    expect(
      find.byKey(const ValueKey('exercise-library-remove-method')),
      findsOneWidget,
    );
    await search(tester, 'supino reto barra');
    await flow.tapVisible(
      tester,
      find.byKey(const ValueKey('exercise-library-item-Supino Reto com Barra')),
    );
    expect(find.text('Definir prescrição'), findsOneWidget);
    expect(find.byType(ExerciseMedia), findsOneWidget);
    expect(flow.field('sets'), findsNothing);
    expect(added, isEmpty);
    await tester.tap(find.byKey(const ValueKey('prescription-submit')));
    await tester.pumpAndSettle();
    expect(
      added.single.sets,
      TrainingMethods.generateSetsForMethod('cluster_set'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('filtro por objetivo recupera busca vazia no celular', (
    tester,
  ) async {
    await flow.mountLibrary(tester, (_) {}, size: const Size(375, 740));
    await tester.tap(find.text('Métodos'));
    await tester.pumpAndSettle();
    await flow.tapVisible(
      tester,
      find.byKey(const ValueKey('exercise-library-goal-Todos')),
    );
    await tester.tap(find.text('Emagrecimento').last);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Nenhum método isolado garante'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('exercise-library-method-search')),
      'inexistente',
    );
    await tester.pumpAndSettle();
    await flow.tapVisible(
      tester,
      find.byKey(const ValueKey('exercise-library-clear-method-filters')),
    );
    expect(find.text('40 métodos encontrados'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'destino cancelado mantém prescrição e cache local evita duplicação',
    (tester) async {
      final service = _LibraryContext();
      await tester.binding.setSurfaceSize(const Size(1000, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: PresetsView(contextService: service),
        ),
      );
      await tester.pumpAndSettle();
      await flow.tapVisible(tester, find.text('Exercícios e métodos'));
      await search(tester, 'supino reto barra');
      await flow.tapVisible(
        tester,
        find.byKey(
          const ValueKey('exercise-library-item-Supino Reto com Barra'),
        ),
      );
      await flow.enter(tester, 'sets', '3');
      await flow.enter(tester, 'reps', '10');
      await flow.tapVisible(
        tester,
        find.byKey(const ValueKey('prescription-submit')),
      );
      expect(find.text('Adicionar em qual treino?'), findsOneWidget);
      await tester.tap(find.text('Cancelar').last);
      await tester.pumpAndSettle();
      expect(service.saves, 0);
      expect(
        tester.widget<TextFormField>(flow.field('sets')).controller!.text,
        '3',
      );
      await flow.tapVisible(
        tester,
        find.byKey(const ValueKey('prescription-submit')),
      );
      await tester.tap(find.text('Treino B').last);
      await tester.pumpAndSettle();
      expect(service.saves, 1);
      expect(service.sheet.days[0].exercises, isEmpty);
      expect(service.sheet.days[1].exercises, hasLength(1));
      expect(
        find.textContaining('adicionado neste dispositivo'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('prescription-submit')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

class _LibraryContext extends StudentContextService {
  _LibraryContext() : super.forTesting(initialStudents: testStudents);
  int saves = 0;
  late WorkoutSheet sheet = WorkoutSheet(
    studentId: testStudents.first.id,
    studentName: testStudents.first.name,
    days: [
      WorkoutDay(dow: 'Treino A', muscle: 'Peito', exercises: []),
      WorkoutDay(dow: 'Treino B', muscle: 'Costas', exercises: []),
    ],
  );

  @override
  WorkoutSheet getActiveSheet() => sheet;

  @override
  Future<bool> saveActiveSheet(WorkoutSheet updated) async {
    saves++;
    sheet = updated.deepCopy();
    notifyListeners();
    return false; // Same local-first behavior as a failed remote synchronization.
  }
}
