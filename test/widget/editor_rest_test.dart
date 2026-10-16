import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/models/workout_model.dart';
import 'package:valex_app/views/editor/widgets/editor_exercise_card.dart';
import 'package:valex_app/views/students/workout_session_runner_view.dart';

void main() {
  testWidgets(
    'instrutor define descanso e aluno recebe o cronômetro prescrito',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final exercise = Exercise(title: 'Supino', sets: ['[work]12 reps']);
      var dirty = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EditorExerciseCard(
                exercise: exercise,
                displayIndex: 0,
                otherDaysForMove: const [],
                mutate: (change) => change(),
                markDirty: () => dirty = true,
                onOpenCalcLoad: (_) {},
                onToggleSetType: (_) {},
                onSetTypeExplicit: (_, _) {},
                onMoveSet: (_, _) {},
                onDeleteSet: (_) {},
                onAddSet: () {},
                onDuplicate: () {},
                onMove: (_) {},
                onMoveToDay: (_) {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Editar detalhes'));
      await tester.pumpAndSettle();
      final restField = find.byKey(const ValueKey('exercise-rest-seconds'));
      await tester.ensureVisible(restField);
      await tester.enterText(restField, '95');
      await tester.pump();
      expect(exercise.restSeconds, 95);
      expect(dirty, isTrue);
      expect(Exercise.fromJson(exercise.toJson()).restSeconds, 95);

      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutSessionRunnerView(
            workoutDay: WorkoutDay(
              dow: 'Treino A',
              muscle: 'Peito',
              exercises: [exercise],
            ),
            studentName: 'Aluno',
            onFinish: () {},
          ),
        ),
      );
      await tester.tap(find.textContaining('Série 1:'));
      await tester.pump();
      expect(find.text('95'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('descanso zero conclui série sem iniciar cronômetro', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WorkoutSessionRunnerView(
          workoutDay: WorkoutDay(
            dow: 'Treino B',
            muscle: 'Mobilidade',
            exercises: [
              Exercise(
                title: 'Mobilidade',
                sets: ['[work]30 s'],
                restSeconds: 0,
              ),
            ],
          ),
          studentName: 'Aluno',
          onFinish: () {},
        ),
      ),
    );
    await tester.tap(find.textContaining('Série 1:'));
    await tester.pump();
    expect(find.text('INTERVALO DE DESCANSO'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
