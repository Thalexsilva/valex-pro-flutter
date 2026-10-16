import '../support/student_fixtures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valex_app/models/workout_model.dart';
import 'package:valex_app/services/student_context_service.dart';
import 'package:valex_app/views/editor/editor_view.dart';

class FakeStudentContextService extends StudentContextService {
  FakeStudentContextService() : super.forTesting(initialStudents: testStudents);

  bool mockSuccess = true;
  int saveSnapshotCallCount = 0;
  int savePresetCallCount = 0;
  int saveActiveSheetCallCount = 0;

  String? lastSnapshotName;
  String? lastPresetTitle;
  WorkoutSheet? lastSavedSheet;
  Duration asyncDelay = const Duration(milliseconds: 100);

  @override
  Future<bool> saveVersionSnapshot(
    WorkoutSheet sheet,
    String versionName,
  ) async {
    saveSnapshotCallCount++;
    lastSnapshotName = versionName;
    if (asyncDelay > Duration.zero) {
      await Future.delayed(asyncDelay);
    }
    return mockSuccess;
  }

  @override
  Future<bool> saveCustomPreset(WorkoutSheet sheet, String presetTitle) async {
    savePresetCallCount++;
    lastPresetTitle = presetTitle;
    if (asyncDelay > Duration.zero) {
      await Future.delayed(asyncDelay);
    }
    return mockSuccess;
  }

  @override
  Future<bool> saveActiveSheet(WorkoutSheet sheet) async {
    saveActiveSheetCallCount++;
    lastSavedSheet = sheet;
    if (asyncDelay > Duration.zero) {
      await Future.delayed(asyncDelay);
    }
    return mockSuccess;
  }

  @override
  List<WorkoutSheet> getVersionHistory(String studentId) {
    return [
      WorkoutSheet(
        studentId: studentId,
        studentName: 'Aluno Teste',
        currentVersionName: 'v1 - FICHA_RESTAURADA',
        instructorNotes: 'VERSAO_ANTERIOR',
      ),
      WorkoutSheet(
        studentId: studentId,
        studentName: 'Aluno Teste',
        currentVersionName: 'v2 - SEGUNDA_OPCAO',
      ),
    ];
  }
}

void main() {
  SharedPreferences.setMockInitialValues({});

  Widget buildTestableWidget(FakeStudentContextService fakeService) {
    return MaterialApp(
      home: Scaffold(body: EditorView(contextService: fakeService)),
    );
  }

  Future<void> openOverflowAction(
    WidgetTester tester,
    String actionLabel,
  ) async {
    await tester.tap(find.byTooltip('Mais ações do editor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(actionLabel));
    await tester.pumpAndSettle();
  }

  group('Suíte de Testes dos Diálogos do Editor', () {
    // --- SNAPSHOT ---
    testWidgets('Salvar snapshot - sucesso', (WidgetTester tester) async {
      final fakeService = FakeStudentContextService()
        ..mockSuccess = true
        ..asyncDelay = Duration.zero;
      await tester.pumpWidget(buildTestableWidget(fakeService));
      await tester.pumpAndSettle();

      await openOverflowAction(tester, 'Salvar snapshot');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar Snapshot'));
      await tester.pumpAndSettle();

      expect(find.text('Salvar Snapshot de Versão'), findsNothing);
      expect(find.textContaining('salvo no histórico'), findsOneWidget);
    });

    testWidgets('Salvar snapshot - falha', (WidgetTester tester) async {
      final fakeService = FakeStudentContextService()
        ..mockSuccess = false
        ..asyncDelay = Duration.zero;
      await tester.pumpWidget(buildTestableWidget(fakeService));
      await tester.pumpAndSettle();

      await openOverflowAction(tester, 'Salvar snapshot');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar Snapshot'));
      await tester.pumpAndSettle();

      expect(find.text('Salvar Snapshot de Versão'), findsOneWidget);
      expect(
        find.text('Não foi possível salvar no servidor. Tente novamente.'),
        findsOneWidget,
      );
    });

    testWidgets('Salvar snapshot - texto vazio nao dispara save', (
      WidgetTester tester,
    ) async {
      final fakeService = FakeStudentContextService()
        ..asyncDelay = Duration.zero;
      await tester.pumpWidget(buildTestableWidget(fakeService));
      await tester.pumpAndSettle();

      await openOverflowAction(tester, 'Salvar snapshot');

      await tester.enterText(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextField),
            )
            .first,
        '',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar Snapshot'));
      await tester.pumpAndSettle();

      expect(fakeService.saveSnapshotCallCount, equals(0));
      expect(find.text('Salvar Snapshot de Versão'), findsOneWidget);
    });

    testWidgets('Salvar snapshot - espacos em branco sao removidos via trim', (
      WidgetTester tester,
    ) async {
      final fakeService = FakeStudentContextService()
        ..asyncDelay = Duration.zero;
      await tester.pumpWidget(buildTestableWidget(fakeService));
      await tester.pumpAndSettle();

      await openOverflowAction(tester, 'Salvar snapshot');

      await tester.enterText(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextField),
            )
            .first,
        '   Versao Trim   ',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar Snapshot'));
      await tester.pumpAndSettle();

      expect(fakeService.lastSnapshotName, equals('Versao Trim'));
    });

    testWidgets('Salvar snapshot - texto permanece preenchido apos falha', (
      WidgetTester tester,
    ) async {
      final fakeService = FakeStudentContextService()
        ..mockSuccess = false
        ..asyncDelay = Duration.zero;
      await tester.pumpWidget(buildTestableWidget(fakeService));
      await tester.pumpAndSettle();

      await openOverflowAction(tester, 'Salvar snapshot');

      await tester.enterText(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextField),
            )
            .first,
        'Snapshot Customizado',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar Snapshot'));
      await tester.pumpAndSettle();

      expect(find.text('Snapshot Customizado'), findsOneWidget);
      expect(find.text('Salvar Snapshot de Versão'), findsOneWidget);
    });

    // --- PRESET ---
    testWidgets('Salvar preset - sucesso', (WidgetTester tester) async {
      final fakeService = FakeStudentContextService()
        ..mockSuccess = true
        ..asyncDelay = Duration.zero;
      await tester.pumpWidget(buildTestableWidget(fakeService));
      await tester.pumpAndSettle();

      await openOverflowAction(tester, 'Salvar como preset');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar Preset'));
      await tester.pumpAndSettle();

      expect(find.text('Salvar como Preset Personalizado'), findsNothing);
      expect(find.textContaining('salvo com sucesso'), findsOneWidget);
    });

    testWidgets('Salvar preset - falha', (WidgetTester tester) async {
      final fakeService = FakeStudentContextService()
        ..mockSuccess = false
        ..asyncDelay = Duration.zero;
      await tester.pumpWidget(buildTestableWidget(fakeService));
      await tester.pumpAndSettle();

      await openOverflowAction(tester, 'Salvar como preset');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar Preset'));
      await tester.pumpAndSettle();

      expect(find.text('Salvar como Preset Personalizado'), findsOneWidget);
      expect(
        find.text('Não foi possível salvar no servidor. Tente novamente.'),
        findsOneWidget,
      );
    });

    testWidgets('Salvar preset - texto vazio nao dispara save', (
      WidgetTester tester,
    ) async {
      final fakeService = FakeStudentContextService()
        ..asyncDelay = Duration.zero;
      await tester.pumpWidget(buildTestableWidget(fakeService));
      await tester.pumpAndSettle();

      await openOverflowAction(tester, 'Salvar como preset');

      await tester.enterText(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextField),
            )
            .first,
        '',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar Preset'));
      await tester.pumpAndSettle();

      expect(fakeService.savePresetCallCount, equals(0));
    });

    testWidgets('Salvar preset - espacos em branco sao removidos via trim', (
      WidgetTester tester,
    ) async {
      final fakeService = FakeStudentContextService()
        ..asyncDelay = Duration.zero;
      await tester.pumpWidget(buildTestableWidget(fakeService));
      await tester.pumpAndSettle();

      await openOverflowAction(tester, 'Salvar como preset');

      await tester.enterText(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextField),
            )
            .first,
        '   Preset Trim   ',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar Preset'));
      await tester.pumpAndSettle();

      expect(fakeService.lastPresetTitle, equals('Preset Trim'));
    });

    testWidgets('Salvar preset - texto permanece preenchido apos falha', (
      WidgetTester tester,
    ) async {
      final fakeService = FakeStudentContextService()
        ..mockSuccess = false
        ..asyncDelay = Duration.zero;
      await tester.pumpWidget(buildTestableWidget(fakeService));
      await tester.pumpAndSettle();

      await openOverflowAction(tester, 'Salvar como preset');

      await tester.enterText(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextField),
            )
            .first,
        'Preset Persistente',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar Preset'));
      await tester.pumpAndSettle();

      expect(find.text('Preset Persistente'), findsOneWidget);
    });

    testWidgets('Salvar preset - dialogo nao fecha durante loading', (
      WidgetTester tester,
    ) async {
      final fakeService = FakeStudentContextService()
        ..asyncDelay = const Duration(milliseconds: 300);
      await tester.pumpWidget(buildTestableWidget(fakeService));
      await tester.pumpAndSettle();

      await openOverflowAction(tester, 'Salvar como preset');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar Preset'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Salvar como Preset Personalizado'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('Salvar preset - indicador de progresso aparece e desaparece', (
      WidgetTester tester,
    ) async {
      final fakeService = FakeStudentContextService()
        ..asyncDelay = const Duration(milliseconds: 200);
      await tester.pumpWidget(buildTestableWidget(fakeService));
      await tester.pumpAndSettle();

      await openOverflowAction(tester, 'Salvar como preset');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar Preset'));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    // --- RESTAURACAO ---
    testWidgets(
      'Restaurar versao - sucesso altera a ficha somente apos retorno true',
      (WidgetTester tester) async {
        final fakeService = FakeStudentContextService()
          ..mockSuccess = true
          ..asyncDelay = const Duration(milliseconds: 100);
        await tester.pumpWidget(buildTestableWidget(fakeService));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Histórico de Versões'));
        await tester.pumpAndSettle();

        final restoreBtn = find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.widgetWithText(ElevatedButton, 'Restaurar'),
            )
            .first;
        await tester.tap(restoreBtn);
        await tester.pump(const Duration(milliseconds: 30));

        // Durante a chamada, as notas da ficha na tela principal ainda não são as da ficha restaurada
        expect(find.text('VERSAO_ANTERIOR'), findsNothing);

        await tester.pumpAndSettle();

        // Após retorno true, o diálogo fecha
        expect(find.text('Histórico de Versões da Ficha'), findsNothing);
        expect(find.textContaining('restaurada'), findsOneWidget);
      },
    );

    testWidgets('Restaurar versao - falha preserva a ficha original', (
      WidgetTester tester,
    ) async {
      final fakeService = FakeStudentContextService()
        ..mockSuccess = false
        ..asyncDelay = Duration.zero;
      await tester.pumpWidget(buildTestableWidget(fakeService));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Histórico de Versões'));
      await tester.pumpAndSettle();

      final restoreBtn = find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.widgetWithText(ElevatedButton, 'Restaurar'),
          )
          .first;
      await tester.tap(restoreBtn);
      await tester.pumpAndSettle();

      expect(find.text('Histórico de Versões da Ficha'), findsOneWidget);
      expect(
        find.text('Não foi possível salvar no servidor. Tente novamente.'),
        findsOneWidget,
      );
    });

    testWidgets('Restaurar versao - dialogo permanece aberto na falha', (
      WidgetTester tester,
    ) async {
      final fakeService = FakeStudentContextService()
        ..mockSuccess = false
        ..asyncDelay = Duration.zero;
      await tester.pumpWidget(buildTestableWidget(fakeService));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Histórico de Versões'));
      await tester.pumpAndSettle();

      final restoreBtn = find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.widgetWithText(ElevatedButton, 'Restaurar'),
          )
          .first;
      await tester.tap(restoreBtn);
      await tester.pumpAndSettle();

      expect(find.text('Histórico de Versões da Ficha'), findsOneWidget);
    });

    testWidgets('Restaurar versao - duplo clique gera apenas uma chamada', (
      WidgetTester tester,
    ) async {
      final fakeService = FakeStudentContextService()
        ..asyncDelay = const Duration(milliseconds: 200);
      await tester.pumpWidget(buildTestableWidget(fakeService));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Histórico de Versões'));
      await tester.pumpAndSettle();

      final btn = find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.widgetWithText(ElevatedButton, 'Restaurar'),
          )
          .first;
      await tester.tap(btn);
      await tester.pump(const Duration(milliseconds: 10));
      await tester.tap(btn, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(fakeService.saveActiveSheetCallCount, equals(1));
    });

    testWidgets(
      'Restaurar versao - apenas um botao de restauracao permanece ativo',
      (WidgetTester tester) async {
        final fakeService = FakeStudentContextService()
          ..asyncDelay = const Duration(milliseconds: 300);
        await tester.pumpWidget(buildTestableWidget(fakeService));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Histórico de Versões'));
        await tester.pumpAndSettle();

        final btn1 = find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.widgetWithText(ElevatedButton, 'Restaurar'),
            )
            .first;
        await tester.tap(btn1);
        await tester.pump(const Duration(milliseconds: 50));

        final dialogButtons = tester.widgetList<ElevatedButton>(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(ElevatedButton),
          ),
        );
        for (var b in dialogButtons) {
          expect(b.onPressed, isNull);
        }
        await tester.pumpAndSettle();
      },
    );

    testWidgets('Restaurar versao - spinner permanece durante a Future', (
      WidgetTester tester,
    ) async {
      final fakeService = FakeStudentContextService()
        ..asyncDelay = const Duration(milliseconds: 200);
      await tester.pumpWidget(buildTestableWidget(fakeService));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Histórico de Versões'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Restaurar').first);
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets(
      'Restaurar versao - botao Voltar nao fecha durante a operacao',
      (WidgetTester tester) async {
        final fakeService = FakeStudentContextService()
          ..asyncDelay = const Duration(milliseconds: 300);
        await tester.pumpWidget(buildTestableWidget(fakeService));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Histórico de Versões'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Restaurar').first,
        );
        await tester.pump(const Duration(milliseconds: 50));

        // Simula tentativa de pop pelo botão Voltar
        final popResult = await tester.binding.handlePopRoute();
        expect(popResult, isTrue); // Interceptado por PopScope

        expect(find.text('Histórico de Versões da Ficha'), findsOneWidget);
        await tester.pumpAndSettle();
      },
    );
  });
}
