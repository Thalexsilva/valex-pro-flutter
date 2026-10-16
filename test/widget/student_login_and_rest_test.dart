import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/models/workout_model.dart';
import 'package:valex_app/theme/app_theme.dart';
import 'package:valex_app/views/auth/login_view.dart';
import 'package:valex_app/views/auth/sign_up_view.dart';
import 'package:valex_app/views/students/workout_session_runner_view.dart';
import 'package:valex_app/widgets/exercise_media.dart';

void main() {
  testWidgets('volume uses the completed set index', (tester) async {
    final day = WorkoutDay(
      dow: 'Treino A',
      muscle: 'Peito',
      exercises: [
        Exercise(title: 'Supino', sets: ['5', '10', '20'], loadKg: '100'),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: WorkoutSessionRunnerView(
          workoutDay: day,
          studentName: 'Aluno',
          onFinish: () {},
        ),
      ),
    );
    final thirdSet = find.text('Série 3: 20 reps');
    await tester.ensureVisible(thirdSet);
    await tester.tap(thirdSet);
    await tester.pump();
    expect(find.text('Volume: 2,00 toneladas'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('aluno escolhe seu acesso e cadastro com o e-mail do instrutor', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: LoginView(onLoginSuccess: () {}),
      ),
    );
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel(RegExp('E-mail')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Senha')), findsOneWidget);
    await tester.tap(find.text('Aluno'));
    await tester.pumpAndSettle();
    expect(find.text('Acesse sua avaliação e seus treinos.'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('login_open_signup')));
    await tester.tap(find.byKey(const ValueKey('login_open_signup')));
    await tester.pumpAndSettle();
    expect(find.byType(SignUpView), findsOneWidget);
    expect(
      find.text('Use o mesmo e-mail cadastrado pelo seu instrutor.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    semantics.dispose();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('série prescrita inicia o descanso de 90 segundos', (
    tester,
  ) async {
    final day = WorkoutDay(
      dow: 'Treino A',
      muscle: 'Peito',
      exercises: [
        Exercise(title: 'Supino', sets: ['[work]8-12 reps · descanso 90 s']),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: WorkoutSessionRunnerView(
          workoutDay: day,
          studentName: 'Aluno',
          onFinish: () {},
        ),
      ),
    );
    await tester.tap(find.textContaining('Série 1:'));
    await tester.pump();
    expect(find.text('INTERVALO DE DESCANSO'), findsOneWidget);
    expect(find.text('90'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('séries exibem a prescrição sem marcadores internos', (
    tester,
  ) async {
    final day = WorkoutDay(
      dow: 'Treino A',
      muscle: 'Peito',
      exercises: [
        Exercise(
          title: 'Supino',
          sets: ['  [prep]1ª Série: 12 reps @ 60%', ' [work]2ª Série: 10 reps'],
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: WorkoutSessionRunnerView(
          workoutDay: day,
          studentName: 'Aluno',
          onFinish: () {},
        ),
      ),
    );
    expect(find.text('Série 1: 12 reps @ 60%'), findsOneWidget);
    expect(find.text('Série 2: 10 reps'), findsOneWidget);
    expect(find.textContaining('[prep]'), findsNothing);
    expect(find.textContaining('[work]'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('duas fotos do exercício cabem lado a lado no celular', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(32),
            child: ExerciseMedia(
              images: [
                'https://example.com/position-1.png',
                'https://example.com/position-2.png',
              ],
            ),
          ),
        ),
      ),
    );
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(images, hasLength(2));
    expect(images[0].width, lessThan(160));
    expect(images[1].width, lessThan(160));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('cards, descanso e conclusão cabem em celular estreito', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    final day = WorkoutDay(
      dow: 'Treino A',
      muscle: 'Peito',
      exercises: [
        Exercise(title: 'Supino', sets: ['[work]12 reps']),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: WorkoutSessionRunnerView(
          workoutDay: day,
          studentName: 'Aluno',
          onFinish: () {},
        ),
      ),
    );
    expect(find.text('Supino'), findsOneWidget);
    expect(find.text('Concluir Treino'), findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel(RegExp('Série 1 de 1')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.textContaining('Série 1:'));
    await tester.pump();
    expect(find.text('INTERVALO DE DESCANSO'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    semantics.dispose();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'dia sem exercícios mostra orientação no lugar de cronômetro vazio',
    (tester) async {
      final day = WorkoutDay(dow: 'Treino A', muscle: 'Peito');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: WorkoutSessionRunnerView(
            workoutDay: day,
            studentName: 'Aluno',
            onFinish: () {},
          ),
        ),
      );
      expect(
        find.textContaining('Este treino ainda não tem exercícios'),
        findsOneWidget,
      );
      expect(find.text('Concluir Treino'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('zero séries não vira treino concluído', (tester) async {
    final day = WorkoutDay(
      dow: 'Treino A',
      muscle: 'Peito',
      exercises: [
        Exercise(title: 'Supino', sets: ['10']),
      ],
    );
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: WorkoutSessionRunnerView(
          workoutDay: day,
          studentName: 'Aluno',
          onFinish: () => finished = true,
        ),
      ),
    );
    await tester.tap(find.text('Concluir Treino'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma série concluída'), findsOneWidget);
    expect(find.text('TREINO CONCLUÍDO!'), findsNothing);
    expect(find.text('Salvar & Finalizar Sessão'), findsNothing);
    expect(finished, isFalse);
  });
}
