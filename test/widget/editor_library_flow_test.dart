import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/models/training_methods.dart';
import 'package:valex_app/models/workout_model.dart';
import 'package:valex_app/services/student_context_service.dart';
import 'package:valex_app/theme/app_theme.dart';
import 'package:valex_app/views/editor/dialogs/exercise_library_sheet.dart';
import 'package:valex_app/views/editor/widgets/exercise_prescription_form.dart';

const strength = ExerciseLibraryItem(
  title: 'Supino Reto com Barra',
  muscle: 'Peito',
  cue: 'Controle de cadência',
  video: 'https://example.com/video',
);
const cardio = ExerciseLibraryItem(title: 'Esteira', muscle: 'Cardio', cue: '');

Finder field(String id) => find.descendant(
  of: find.byKey(ValueKey('prescription-$id')),
  matching: find.byType(TextFormField),
);

Future<void> enter(WidgetTester tester, String id, String text) async {
  await tester.ensureVisible(field(id));
  await tester.pumpAndSettle();
  await tester.enterText(field(id), text);
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> mountForm(
  WidgetTester tester,
  ValueChanged<Exercise> onSubmit, {
  ExerciseLibraryItem item = strength,
}) async {
  await tester.binding.setSurfaceSize(const Size(720, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ExercisePrescriptionForm(
            item: item,
            onSubmit: onSubmit,
            onBack: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> mountLibrary(
  WidgetTester tester,
  ValueChanged<Exercise> onAdd, {
  Size size = const Size(800, 900),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              constraints: const BoxConstraints(maxWidth: 720),
              builder: (_) =>
                  ExerciseLibrarySheet(onAdd: onAdd, dayLabel: 'Treino A'),
            ),
            child: const Text('Abrir biblioteca'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir biblioteca'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('formulário cabe no celular com teclado e pode ser cancelado', (
    tester,
  ) async {
    final added = <Exercise>[];
    await mountLibrary(tester, added.add, size: const Size(375, 740));
    await tester.ensureVisible(
      find.byKey(const ValueKey('exercise-library-item-Supino Reto com Barra')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('exercise-library-item-Supino Reto com Barra')),
    );
    await tester.pumpAndSettle();
    tester.view.viewInsets = FakeViewPadding(
      bottom: 300 * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await enter(tester, 'sets', '3');
    await enter(tester, 'reps', '12');
    expect(tester.takeException(), isNull);
    expect(
      tester
          .getBottomRight(find.byKey(const ValueKey('prescription-submit')))
          .dy,
      lessThanOrEqualTo(440),
    );
    await tester.tap(find.byKey(const ValueKey('exercise-library-close')));
    await tester.pumpAndSettle();
    expect(added, isEmpty);
    expect(find.byType(ExerciseLibrarySheet), findsNothing);
  });

  testWidgets('valida antes de adicionar e mantém carga decimal e descanso', (
    tester,
  ) async {
    final added = <Exercise>[];
    await mountForm(tester, added.add);
    await tester.tap(find.byKey(const ValueKey('prescription-submit')));
    await tester.pumpAndSettle();
    expect(added, isEmpty);
    expect(find.text('Informe de 1 a 20 séries.'), findsOneWidget);
    await enter(tester, 'sets', '3');
    await enter(tester, 'reps', '8-12');
    await enter(tester, 'rest', '60');
    await enter(tester, 'load', '12,5');
    await tester.tap(find.byKey(const ValueKey('prescription-submit')));
    await tester.pumpAndSettle();
    expect(added, hasLength(1));
    expect(added.single.loadKg, '12,5');
    expect(
      added.single.sets,
      List.filled(3, '[work]8-12 reps · descanso 60 s'),
    );
    expect(added.single.video, strength.video);
    expect(added.single.cue, strength.cue);
    await tester.tap(find.byKey(const ValueKey('prescription-submit')));
    expect(added, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('cardio pede duração e ritmo sem carga automática', (
    tester,
  ) async {
    Exercise? added;
    await mountForm(tester, (exercise) => added = exercise, item: cardio);
    expect(field('load'), findsNothing);
    expect(field('reps'), findsNothing);
    await enter(tester, 'duration', '15');
    await enter(tester, 'intensity', 'Ritmo confortável');
    await tester.tap(find.byKey(const ValueKey('prescription-submit')));
    await tester.pumpAndSettle();
    expect(added!.loadKg, isEmpty);
    expect(added!.sets, ['[work]15 min — Ritmo confortável']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('peso corporal mantém carga numérica compatível com PDF', (
    tester,
  ) async {
    Exercise? added;
    await mountForm(tester, (exercise) => added = exercise);
    await enter(tester, 'sets', '2');
    await enter(tester, 'reps', '10');
    await tapVisible(
      tester,
      find.byKey(const ValueKey('prescription-bodyweight')),
    );
    await tester.tap(find.byKey(const ValueKey('prescription-submit')));
    await tester.pumpAndSettle();
    expect(added!.loadKg, '0');
    expect(added!.cue, contains('Peso corporal, sem carga externa.'));
  });

  testWidgets('método avançado conserva percentuais e tipos de série', (
    tester,
  ) async {
    Exercise? added;
    await mountForm(tester, (exercise) => added = exercise);
    await tapVisible(tester, find.byKey(const ValueKey('prescription-method')));
    await tester.tap(find.text('Pirâmide Crescente').last);
    await tester.pumpAndSettle();
    expect(field('sets'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('prescription-submit')));
    await tester.pumpAndSettle();
    expect(
      added!.sets,
      TrainingMethods.generateSetsForMethod('piramide_crescente'),
    );
    expect(added!.loadKg, isEmpty);
  });

  testWidgets('busca vazia permite limpar filtros e cancelar sem adicionar', (
    tester,
  ) async {
    final added = <Exercise>[];
    await mountLibrary(tester, added.add, size: const Size(375, 740));
    await tester.enterText(
      find.byKey(const ValueKey('exercise-library-search')),
      'inexistente123',
    );
    await tester.pumpAndSettle();
    expect(find.text('Nenhum exercício encontrado'), findsOneWidget);
    await tapVisible(
      tester,
      find.byKey(const ValueKey('exercise-library-clear-filters')),
    );
    expect(
      find.byKey(const ValueKey('exercise-library-item-Supino Reto com Barra')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('exercise-library-close')));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseLibrarySheet), findsNothing);
    expect(added, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'voltar preserva busca e rascunho, confirmação adiciona uma vez',
    (tester) async {
      final added = <Exercise>[];
      await mountLibrary(tester, added.add);
      final search = find.byKey(const ValueKey('exercise-library-search'));
      const itemKey = ValueKey('exercise-library-item-Supino Reto com Barra');
      await tester.enterText(search, 'supino reto barra');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(itemKey));
      await tester.pumpAndSettle();
      expect(added, isEmpty);
      await enter(tester, 'sets', '4');
      await enter(tester, 'reps', '10');
      await tapVisible(tester, find.byKey(const ValueKey('prescription-back')));
      expect(
        tester.widget<TextField>(search).controller!.text,
        'supino reto barra',
      );
      await tester.tap(find.byKey(itemKey));
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(field('sets')).controller!.text, '4');
      await tester.tap(find.byKey(const ValueKey('prescription-submit')));
      await tester.pumpAndSettle();
      expect(added, hasLength(1));
      expect(added.single.sets, List.filled(4, '[work]10 reps'));
      expect(find.byType(ExerciseLibrarySheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
