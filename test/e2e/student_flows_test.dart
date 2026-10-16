import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/models/student_model.dart';
import 'package:valex_app/repositories/student_workout_repository.dart';
import 'package:valex_app/theme/app_theme.dart';
import 'package:valex_app/views/students/student_portal_view.dart';
import 'package:valex_app/views/students/workout_session_runner_view.dart';

import '../support/e2e_fixtures.dart';
import '../support/fake_supabase_backend.dart';

class _RefreshFailsAfterComment extends StudentWorkoutRepository {
  bool sent = false;

  @override
  Future<void> sendComment(Student student, String body) async {
    await super.sendComment(student, body);
    sent = true;
  }

  @override
  Future<List<StudentWorkoutEntry>> fetchEntries(String studentId) {
    if (sent) throw StateError('Falha apenas na atualização da atividade');
    return super.fetchEntries(studentId);
  }
}

class _ActivityFailsUntilRetry extends StudentWorkoutRepository {
  bool fail = true;

  @override
  Future<List<StudentWorkoutEntry>> fetchEntries(String studentId) {
    if (fail) throw StateError('Atividade temporariamente indisponível');
    return super.fetchEntries(studentId);
  }
}

/// Student portal journeys against the real repositories and an in-memory
/// backend, signed in as the student account linked to Ana.
void main() {
  late FakeSupabaseBackend backend;

  setUpAll(loadAppFonts);

  setUp(() async {
    await resetAppSingletons();
    backend = FakeSupabaseBackend(
      userId: 'student-ana',
      email: 'ana@example.com',
    );
    seedTrainerWorkspace(backend);
    backend
            .table('students')
            .firstWhere((row) => row['id'] == anaId)['student_user_id'] =
        'student-ana';
    backend.rpcs['claim_student_account'] = (_) => anaId;
    await backend.start();
  });

  tearDown(() async {
    await resetAppSingletons();
    await backend.stop();
  });

  Student ana() => Student.fromJson(
    backend.table('students').firstWhere((row) => row['id'] == anaId),
  );

  Future<void> openPortal(
    WidgetTester tester, {
    StudentWorkoutRepository? activityRepository,
  }) async {
    setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: StudentPortalView(
          student: ana(),
          onLogout: () {},
          activityRepository: activityRepository,
        ),
      ),
    );
    await settleFrames(tester, frames: 8);
  }

  Future<void> expandDay(WidgetTester tester, String label) async {
    final tile = find.textContaining(label).first;
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await settleFrames(tester, frames: 3);
  }

  testWidgets('portal shows the plan, teacher and last completed workout', (
    tester,
  ) async {
    await openPortal(tester);
    expect(find.text('BEM-VINDO(A) AO VALEX!'), findsNothing);
    expect(
      find.textContaining('Treino A — Peitoral e Tríceps'),
      findsOneWidget,
    );
    expect(find.textContaining('último em 07/10'), findsOneWidget);
    expect(find.textContaining('ainda não realizado'), findsOneWidget);

    await expandDay(tester, 'Treino A — Peitoral e Tríceps');
    // Exercício sem carga prescrita não mostra "kg" vazio.
    expect(find.text('3 séries'), findsOneWidget);
    expect(find.text('3 séries • 40 kg'), findsOneWidget);
    expect(find.text('Iniciar Treino A'), findsOneWidget);
  });

  testWidgets('a full workout is saved with sets, effort and comment', (
    tester,
  ) async {
    await openPortal(tester);
    await expandDay(tester, 'Treino A — Peitoral e Tríceps');
    await tester.ensureVisible(find.text('Iniciar Treino A'));
    await tester.tap(find.text('Iniciar Treino A'));
    await settleFrames(tester, frames: 4);
    expect(find.byType(WorkoutSessionRunnerView), findsOneWidget);

    await tester.tap(find.textContaining('Série 1:').first);
    await settleFrames(tester, frames: 2);
    expect(find.text('INTERVALO DE DESCANSO'), findsOneWidget);

    // Voltar no meio do treino pede confirmação em vez de descartar.
    await tester.tap(find.byType(BackButton));
    await settleFrames(tester, frames: 2);
    expect(find.text('Sair sem salvar o treino?'), findsOneWidget);
    await tester.tap(find.text('Continuar treino'));
    await settleFrames(tester, frames: 2);
    expect(find.byType(WorkoutSessionRunnerView), findsOneWidget);

    await tester.tap(find.text('Concluir Treino'));
    await settleFrames(tester, frames: 2);
    expect(find.text('Comentário para Profa. Teste'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Comentário para Profa. Teste'),
      'Supino pesado hoje',
    );
    expect(find.text('Selecione o esforço para salvar'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, '7'));
    await settleFrames(tester, frames: 2);
    await tester.tap(find.text('Salvar & Finalizar Sessão'));
    await settleFrames(tester, frames: 8);

    expect(find.byType(WorkoutSessionRunnerView), findsNothing);
    final sessions = backend
        .table('student_workout_sessions')
        .where((row) => row['kind'] == 'session')
        .toList();
    final saved = sessions.last;
    expect(saved['workout_day'], 'Treino A');
    expect(saved['feedback'], 'Supino pesado hoje');
    expect(saved['rpe'], 7);
    expect(saved['completed_sets'], {
      '0': [0],
    });
    expect(saved['trainer_id'], trainerId);
  });

  testWidgets('leaving after confirming discards the session', (tester) async {
    await openPortal(tester);
    await expandDay(tester, 'Treino A — Peitoral e Tríceps');
    await tester.ensureVisible(find.text('Iniciar Treino A'));
    await tester.tap(find.text('Iniciar Treino A'));
    await settleFrames(tester, frames: 4);
    await tester.tap(find.textContaining('Série 1:').first);
    await settleFrames(tester, frames: 2);

    await tester.tap(find.byType(BackButton));
    await settleFrames(tester, frames: 2);
    await tester.tap(find.text('Sair sem salvar'));
    await settleFrames(tester, frames: 4);
    expect(find.byType(WorkoutSessionRunnerView), findsNothing);
    expect(
      backend.writesTo('student_workout_sessions'),
      isEmpty,
      reason: 'Nenhum treino deve ser registrado ao sair sem salvar.',
    );
  });

  testWidgets('session save error is announced and keeps the form open', (
    tester,
  ) async {
    await openPortal(tester);
    await expandDay(tester, 'Treino A — Peitoral e Tríceps');
    await tester.ensureVisible(find.text('Iniciar Treino A'));
    await tester.tap(find.text('Iniciar Treino A'));
    await settleFrames(tester, frames: 4);
    await tester.tap(find.textContaining('Série 1:').first);
    await settleFrames(tester, frames: 2);
    await tester.tap(find.text('Concluir Treino'));
    await settleFrames(tester, frames: 2);
    await tester.tap(find.widgetWithText(ChoiceChip, '6'));
    await settleFrames(tester, frames: 2);
    backend.failing.add('student_workout_sessions');
    final semantics = tester.ensureSemantics();
    await tester.tap(find.text('Salvar & Finalizar Sessão'));
    await settleFrames(tester, frames: 6);
    expect(
      find.text('Não foi possível salvar a sessão. Tente novamente.'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Não foi possível salvar a sessão')),
      findsOneWidget,
    );
    expect(find.text('Salvar & Finalizar Sessão'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a failed assessment lookup does not block training', (
    tester,
  ) async {
    backend.failing.add('student_anamneses');
    await openPortal(tester);
    await settleFrames(tester, frames: 40);
    expect(find.text('BEM-VINDO(A) AO VALEX!'), findsNothing);
    expect(
      find.textContaining('Não foi possível verificar sua Avaliação 360°'),
      findsOneWidget,
    );
    await expandDay(tester, 'Treino A — Peitoral e Tríceps');
    final start = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Iniciar Treino A'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(start.onPressed, isNotNull);
  });

  testWidgets('a student without assessment is guided to the 360 flow', (
    tester,
  ) async {
    backend.table('student_anamneses').clear();
    await openPortal(tester);
    expect(find.text('BEM-VINDO(A) AO VALEX!'), findsOneWidget);
    expect(find.textContaining('por Profa. Teste'), findsOneWidget);
    await tester.tap(find.text('Ver meu portal'));
    await settleFrames(tester, frames: 3);
    expect(find.text('FLUXO 360° PENDENTE'), findsOneWidget);
  });

  testWidgets('a comment reaches the instructor', (tester) async {
    await openPortal(tester);
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Mensagem ao instrutor'),
    );
    await settleFrames(tester, frames: 3);
    await tester.enterText(
      find.widgetWithText(TextField, 'Mensagem ao instrutor'),
      'Posso treinar pela manhã?',
    );
    await tester.ensureVisible(find.text('Enviar comentário'));
    await tester.tap(find.text('Enviar comentário'));
    await settleFrames(tester, frames: 6);
    expect(find.text('Comentário enviado ao instrutor.'), findsOneWidget);
    final comment = backend.table('student_workout_sessions').last;
    expect(comment['kind'], 'comment');
    expect(comment['feedback'], 'Posso treinar pela manhã?');
  });

  testWidgets('failed activity refresh does not report comment send failure', (
    tester,
  ) async {
    final repository = _RefreshFailsAfterComment();
    await openPortal(tester, activityRepository: repository);
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Mensagem ao instrutor'),
    );
    await settleFrames(tester, frames: 3);
    await tester.enterText(
      find.widgetWithText(TextField, 'Mensagem ao instrutor'),
      'Mensagem entregue',
    );
    await tester.ensureVisible(find.text('Enviar comentário'));
    await tester.tap(find.text('Enviar comentário'));
    await settleFrames(tester, frames: 6);

    expect(repository.sent, isTrue);
    expect(
      find.textContaining('Comentário enviado, mas a atividade'),
      findsOneWidget,
    );
    expect(
      find.text('Não foi possível enviar. Tente novamente.'),
      findsNothing,
    );
    expect(
      backend
          .table('student_workout_sessions')
          .where((row) => row['feedback'] == 'Mensagem entregue'),
      hasLength(1),
    );
  });

  testWidgets('activity error is visible and can be retried', (tester) async {
    final repository = _ActivityFailsUntilRetry();
    await openPortal(tester, activityRepository: repository);
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Mensagem ao instrutor'),
    );
    await settleFrames(tester, frames: 3);

    expect(
      find.text('Não foi possível atualizar a atividade recente.'),
      findsOneWidget,
    );
    repository.fail = false;
    await tester.tap(find.text('Tentar novamente'));
    await settleFrames(tester, frames: 4);

    expect(
      find.text('Não foi possível atualizar a atividade recente.'),
      findsNothing,
    );
    expect(find.text('Atividade recente'), findsOneWidget);
  });
}
