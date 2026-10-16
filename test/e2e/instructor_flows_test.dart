import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/services/student_context_service.dart';
import 'package:valex_app/theme/app_theme.dart';
import 'package:valex_app/views/main_navigation_view.dart';

import '../support/e2e_fixtures.dart';
import '../support/fake_supabase_backend.dart';

/// Instructor journeys against the real repositories and an in-memory backend.
void main() {
  late FakeSupabaseBackend backend;

  setUpAll(loadAppFonts);

  setUp(() async {
    await resetAppSingletons();
    backend = FakeSupabaseBackend();
    seedTrainerWorkspace(backend);
    // Inicializado fora do corpo do teste: dentro do tempo simulado o
    // encerramento do cliente nunca conclui.
    await backend.start();
  });

  tearDown(() async {
    await resetAppSingletons();
    await backend.stop();
  });

  Future<void> openApp(WidgetTester tester, {Size size = phone}) async {
    setViewport(tester, size);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: MainNavigationView(onLogout: () {}),
      ),
    );
    await settleFrames(tester, frames: 8);
  }

  Future<void> goTo(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar).hitTestable(),
        matching: find.text(label),
      ),
    );
    await settleFrames(tester);
  }

  Future<void> goToOnDesktop(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text(label),
      ),
    );
    await settleFrames(tester);
  }

  Map<String, dynamic> studentInBackend(String id) =>
      backend.table('students').firstWhere((row) => row['id'] == id);

  testWidgets('instructor shell opens immediately when the server is down', (
    tester,
  ) async {
    backend.failAll = true;
    setViewport(tester, phone);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: MainNavigationView(onLogout: () {}),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    // The shell no longer waits for retried requests before rendering.
    expect(find.byType(NavigationBar), findsOneWidget);

    await settleFrames(tester, frames: 60);
    await goTo(tester, 'Alunos');
    expect(find.text('Não foi possível carregar seus alunos'), findsOneWidget);
    expect(find.text('Nenhum aluno cadastrado ainda'), findsNothing);

    backend.failAll = false;
    await tester.tap(find.text('Tentar novamente').hitTestable().first);
    await settleFrames(tester, frames: 12);
    expect(find.text('Ana Beatriz Souza'), findsOneWidget);
  });

  testWidgets('student search ignores accents and punctuation', (tester) async {
    await openApp(tester);
    await goTo(tester, 'Alunos');

    final search = find.widgetWithText(TextField, 'Buscar alunos');
    await tester.enterText(search, 'joao pedro');
    await tester.pump();
    expect(find.text(longName), findsOneWidget);
    expect(find.text('Ana Beatriz Souza'), findsNothing);

    await tester.enterText(search, '41999990000');
    await tester.pump();
    expect(find.text('Ana Beatriz Souza'), findsOneWidget);

    await tester.enterText(search, 'ninguém com esse nome');
    await tester.pump();
    expect(find.text('Nenhum aluno encontrado'), findsOneWidget);
    await tester.tap(find.text('Limpar busca e filtro'));
    await tester.pump();
    expect(find.text('Ana Beatriz Souza'), findsOneWidget);
  });

  testWidgets('student detail reflects edits and reports failed archiving', (
    tester,
  ) async {
    await openApp(tester);
    await goTo(tester, 'Alunos');
    await tester.tap(find.text('Abrir').first);
    await settleFrames(tester, frames: 8);
    expect(find.text('Ana Beatriz Souza'), findsWidgets);

    await tester.tap(find.text('Perfil'));
    await settleFrames(tester, frames: 3);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome Completo *'),
      'Ana B. Souza',
    );
    await tester.tap(find.text('Salvar'));
    await settleFrames(tester, frames: 6);
    expect(find.text('Ana B. Souza'), findsWidgets);
    expect(studentInBackend(anaId)['name'], 'Ana B. Souza');

    backend.failing.add('students');
    await tester.tap(find.text('Arquivar'));
    await settleFrames(tester, frames: 6);
    expect(find.textContaining('Não foi possível atualizar'), findsOneWidget);
    expect(find.text('Ativo'), findsWidgets);
    expect(studentInBackend(anaId)['status'], 'active');
  });

  testWidgets('student detail scrolls on a short phone without overflow', (
    tester,
  ) async {
    await openApp(tester, size: const Size(360, 640));
    await goTo(tester, 'Alunos');
    final errors = await collectFlutterErrors(() async {
      await tester.ensureVisible(find.text('Abrir').first);
      await tester.pump();
      await tester.tap(find.text('Abrir').first);
      await settleFrames(tester, frames: 8);
      await tester.dragFrom(const Offset(180, 400), const Offset(0, -400));
      await settleFrames(tester, frames: 2);
      await tester.ensureVisible(find.text('Comentários'));
      await tester.tap(find.text('Comentários'));
      await settleFrames(tester, frames: 4);
    });
    expect(errors, isEmpty, reason: describeErrors(errors));
    expect(find.textContaining('Treino A concluído'), findsOneWidget);
    expect(find.textContaining('esforço 8/10'), findsOneWidget);
  });

  testWidgets('reassessment request is only confirmed after the server saves', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await openApp(tester);
    await goTo(tester, 'Alunos');
    await tester.tap(find.text('Abrir').first);
    await settleFrames(tester, frames: 8);

    backend.failing.add('students');
    await tester.tap(find.text('Avaliação 360°'));
    await settleFrames(tester, frames: 3);
    await tester.tap(find.text('Solicitar no Próximo Acesso / WhatsApp'));
    await settleFrames(tester, frames: 6);
    expect(
      find.textContaining('Não foi possível registrar a reavaliação'),
      findsOneWidget,
    );
    expect(studentInBackend(anaId)['needs_reassessment'], false);

    backend.failing.remove('students');
    await tester.tap(find.text('Solicitar no Próximo Acesso / WhatsApp'));
    await settleFrames(tester, frames: 6);
    expect(find.textContaining('Reavaliação 360° solicitada'), findsOneWidget);
    expect(studentInBackend(anaId)['needs_reassessment'], true);
    // A mensagem leva ao portal publicado e ao e-mail de login do aluno.
    expect(copied, contains('https://valexapp.vercel.app/'));
    expect(copied, contains('ana@example.com'));
    expect(copied, isNot(contains('app.valex.com.br')));
  });

  testWidgets('autosave keeps the exercise being edited open', (tester) async {
    await openApp(tester, size: const Size(1280, 900));
    await goToOnDesktop(tester, 'Editor Ativo');
    expect(find.text('Supino Reto com Barra'), findsWidgets);

    await tester.ensureVisible(find.text('Editar detalhes').first);
    await tester.tap(find.text('Editar detalhes').first);
    await settleFrames(tester, frames: 2);
    final title = find.descendant(
      of: find.byType(RawAutocomplete<String>),
      matching: find.byType(TextField),
    );
    await tester.enterText(title.first, 'Supino Reto Pegada Fechada');
    await settleFrames(tester, frames: 12);

    // Before the fix each autosave rebuilt the cards and closed the editor.
    expect(find.text('Concluir edição'), findsOneWidget);
    final saved = backend.table('workout_sheets').single;
    final exercises = (saved['days'] as List).first['exercises'] as List;
    expect(exercises.first['title'], 'Supino Reto Pegada Fechada');
  });

  testWidgets(
    'editor blocks a blank sheet when the prescription fails to load',
    (tester) async {
      backend.failing.add('workout_sheets');
      await openApp(tester, size: const Size(1280, 900));
      await goToOnDesktop(tester, 'Editor Ativo');
      await settleFrames(tester, frames: 40);
      expect(find.text('Não foi possível carregar a ficha'), findsOneWidget);
      expect(find.text('Criar primeiro treino'), findsNothing);

      backend.failing.remove('workout_sheets');
      await tester.tap(find.text('Tentar novamente'));
      await settleFrames(tester, frames: 10);
      expect(find.text('Supino Reto com Barra'), findsWidgets);
    },
  );

  testWidgets('dashboard shows what students did and pending assessments', (
    tester,
  ) async {
    await openApp(tester);
    await tester.scrollUntilVisible(
      find.textContaining('Ana Beatriz Souza enviou uma mensagem'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.textContaining('Ana Beatriz Souza enviou uma mensagem'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Ana Beatriz Souza concluiu Treino A'),
      findsOneWidget,
    );
    expect(find.textContaining('esforço 8/10'), findsOneWidget);
    expect(
      find.textContaining('Avaliação 360° pendente: $longName'),
      findsOneWidget,
    );
  });

  test('deleting a custom preset removes it from the server', () async {
    final context = StudentContextService();
    await context.init();
    expect(context.customPresets.map((p) => p.studentName), [
      'Hipertrofia Iniciante',
    ]);
    expect(await context.deleteCustomPreset('Hipertrofia Iniciante'), isTrue);
    expect(backend.table('custom_presets'), isEmpty);

    context.clearSessionMemory();
    await context.init();
    expect(context.customPresets, isEmpty);
  });
}

const phone = Size(390, 844);
