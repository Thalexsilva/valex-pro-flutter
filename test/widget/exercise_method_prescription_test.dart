import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/models/training_methods.dart';
import 'package:valex_app/models/workout_model.dart';
import 'package:valex_app/services/student_context_service.dart';
import 'package:valex_app/theme/app_theme.dart';
import 'package:valex_app/views/editor/widgets/exercise_prescription_form.dart';

Finder field(String id) => find.descendant(
  of: find.byKey(ValueKey('prescription-$id')),
  matching: find.byType(TextFormField),
);

Future<void> mountForm(
  WidgetTester tester,
  ValueChanged<Exercise> onSubmit, {
  String? method,
  Future<bool> Function(Exercise)? onSubmitAsync,
  ExerciseLibraryItem item = const ExerciseLibraryItem(
    title: 'Supino reto',
    muscle: 'Peito',
    cue: 'Controle o movimento.',
  ),
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
            initialMethodId: method,
            onSubmit: onSubmit,
            onSubmitAsync: onSubmitAsync,
            onBack: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'salvamento pendente bloqueia duplicação e cancelamento preserva rascunho',
    (tester) async {
      final firstSave = Completer<bool>();
      final secondSave = Completer<bool>();
      final submissions = <Exercise>[];
      await mountForm(
        tester,
        (_) => fail('callback síncrono não deveria executar'),
        method: 'cluster_set',
        onSubmitAsync: (exercise) {
          submissions.add(exercise);
          return submissions.length == 1 ? firstSave.future : secondSave.future;
        },
      );
      await tester.ensureVisible(field('method-cluster_set-0'));
      await tester.enterText(
        field('method-cluster_set-0'),
        'Preparação personalizada: 10 reps',
      );
      final submit = find.byKey(const ValueKey('prescription-submit'));
      await tester.tap(submit);
      await tester.pump();
      await tester.tap(submit);
      expect(submissions, hasLength(1));
      expect(find.text('Adicionando…'), findsOneWidget);
      firstSave.complete(false);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(field('method-cluster_set-0'))
            .controller!
            .text,
        'Preparação personalizada: 10 reps',
      );
      await tester.tap(submit);
      await tester.pump();
      expect(submissions, hasLength(2));
      expect(
        submissions.last.sets.first,
        '[prep]Preparação personalizada: 10 reps',
      );
      secondSave.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('Adicionado ao treino'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('falha ao salvar permite tentar novamente com os mesmos dados', (
    tester,
  ) async {
    var attempts = 0;
    await mountForm(
      tester,
      (_) {},
      method: 'tradicional',
      onSubmitAsync: (_) async {
        if (++attempts == 1) throw StateError('Falha simulada');
        return true;
      },
    );
    final submit = find.byKey(const ValueKey('prescription-submit'));
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Não foi possível adicionar. Seus dados foram mantidos; tente novamente.',
      ),
      findsOneWidget,
    );
    expect(find.text('Adicionar ao treino'), findsOneWidget);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Adicionado ao treino'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('método de pausa exige a posição e a salva na ficha', (
    tester,
  ) async {
    Exercise? result;
    await mountForm(
      tester,
      (exercise) => result = exercise,
      method: 'pausa_isometrica',
    );
    final submit = find.byKey(const ValueKey('prescription-submit'));
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(
      find.text('Descreva a posição em que o aluno deve pausar.'),
      findsOneWidget,
    );
    await tester.ensureVisible(field('position'));
    await tester.enterText(field('position'), 'Na metade da subida');
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(result!.cue, contains('Posição da pausa: Na metade da subida'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('método da biblioteca inicia visível e mantém tags ao salvar', (
    tester,
  ) async {
    Exercise? result;
    await mountForm(
      tester,
      (exercise) => result = exercise,
      method: 'cluster_set',
    );
    expect(find.byKey(const ValueKey('prescription-method')), findsOneWidget);
    expect(field('sets'), findsNothing);
    expect(field('method-cluster_set-0'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('prescription-submit')));
    await tester.pumpAndSettle();
    expect(result!.sets, TrainingMethods.generateSetsForMethod('cluster_set'));
    expect(result!.loadKg, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'método incompatível ou inexistente preserva preenchimento manual',
    (tester) async {
      await mountForm(
        tester,
        (_) {},
        method: 'drop_set',
        item: const ExerciseLibraryItem(
          title: 'Bicicleta',
          muscle: 'Quadríceps',
          cue: '',
          category: 'cardio',
        ),
      );
      expect(field('duration'), findsOneWidget);
      expect(field('load'), findsNothing);
      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byKey(const ValueKey('prescription-method')),
      );
      expect(dropdown.initialValue, 'simple');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('mobilidade começa por tempo sem campos de cardio ou carga', (
    tester,
  ) async {
    Exercise? result;
    await mountForm(
      tester,
      (exercise) => result = exercise,
      item: const ExerciseLibraryItem(
        title: 'Alongamento de peitoral',
        muscle: 'Peito',
        cue: '',
        category: 'stretching',
      ),
    );
    expect(field('intensity'), findsNothing);
    expect(field('load'), findsNothing);
    expect(field('time'), findsOneWidget);
    await tester.ensureVisible(field('sets'));
    await tester.enterText(field('sets'), '2');
    await tester.ensureVisible(field('time'));
    await tester.enterText(field('time'), '20');
    await tester.tap(find.byKey(const ValueKey('prescription-submit')));
    await tester.pumpAndSettle();
    expect(result!.sets, ['[work]20 s', '[work]20 s']);
    expect(result!.loadKg, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('método combinado exige sequência e a grava nas orientações', (
    tester,
  ) async {
    Exercise? result;
    await mountForm(tester, (exercise) => result = exercise, method: 'bi_set');
    await tester.tap(find.byKey(const ValueKey('prescription-submit')));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(
      find.text('Informe os exercícios que compõem a sequência e sua ordem.'),
      findsOneWidget,
    );
    await tester.ensureVisible(field('companions'));
    await tester.enterText(
      field('companions'),
      '1. Supino reto → 2. Crucifixo',
    );
    await tester.tap(find.byKey(const ValueKey('prescription-submit')));
    await tester.pumpAndSettle();
    expect(
      result!.cue,
      contains('Sequência de exercícios: 1. Supino reto → 2. Crucifixo'),
    );
    expect(result!.sets, TrainingMethods.generateSetsForMethod('bi_set'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('instruções completas ficam disponíveis sem aumentar a ficha', (
    tester,
  ) async {
    Exercise? result;
    await mountForm(
      tester,
      (exercise) => result = exercise,
      method: 'tradicional',
      item: const ExerciseLibraryItem(
        title: 'Supino reto',
        muscle: 'Peito',
        cue: 'Controle o movimento.',
        instructions: [
          'Posicione os pés no chão.',
          'Retorne de forma controlada.',
        ],
      ),
    );
    final details = find.text('Orientações e observações');
    await tester.ensureVisible(details);
    await tester.tap(details);
    await tester.pumpAndSettle();
    expect(find.text('1. Posicione os pés no chão.'), findsOneWidget);
    expect(find.text('2. Retorne de forma controlada.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('prescription-submit')));
    await tester.pumpAndSettle();
    expect(result!.cue, 'Controle o movimento.');
    expect(tester.takeException(), isNull);
  });
}
