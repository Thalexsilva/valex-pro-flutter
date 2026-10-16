import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valex_app/models/finance_models.dart';
import 'package:valex_app/repositories/finance_repository.dart';
import 'package:valex_app/services/student_context_service.dart';
import 'package:valex_app/theme/app_theme.dart';
import 'package:valex_app/views/dashboard/dashboard_view.dart';
import 'package:valex_app/views/editor/editor_view.dart';
import 'package:valex_app/views/presets/presets_view.dart';

class _FailedFinanceRepository extends FinanceRepository {
  @override
  Future<FinanceState> loadState() async => throw StateError('offline');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('painel mostra primeira tarefa com carteira vazia', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = StudentContextService.forTesting(allowOfflineWrites: true);
    await service.init();
    var openStudentsCalls = 0;
    final finance = _FailedFinanceRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: DashboardView(
          studentContext: service,
          financeRepository: finance,
          onOpenStudents: () => openStudentsCalls++,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Comece pelo primeiro aluno'), findsOneWidget);
    await tester.tap(find.text('Cadastrar primeiro aluno'));
    expect(openStudentsCalls, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    finance.dispose();
    service.dispose();
  });

  testWidgets('painel não mostra zero quando financeiro falha', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final finance = _FailedFinanceRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: DashboardView(
          studentContext: StudentContextService.forTesting(),
          financeRepository: finance,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Não foi possível carregar o financeiro.'),
      findsOneWidget,
    );
    expect(find.text('Indisponível'), findsNWidgets(4));
    expect(find.text('R\$ 0,00'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    finance.dispose();
  });

  testWidgets('editor vazio oferece caminho para escolher aluno', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = StudentContextService.forTesting(allowOfflineWrites: true);
    await service.init();
    var openStudentsCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: EditorView(
          contextService: service,
          onOpenStudents: () => openStudentsCalls++,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Nenhum aluno selecionado'), findsOneWidget);
    await tester.tap(find.text('Escolher aluno'));
    expect(openStudentsCalls, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    service.dispose();
  });

  testWidgets('abas da biblioteca anunciam seleção', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: PresetsView(contextService: StudentContextService.forTesting()),
      ),
    );
    await tester.pumpAndSettle();

    final libraryTab = find
        .ancestor(
          of: find.text('Exercícios e métodos'),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Semantics && widget.properties.selected != null,
          ),
        )
        .first;
    expect(tester.widget<Semantics>(libraryTab).properties.selected, isFalse);
    await tester.tap(find.text('Exercícios e métodos'));
    await tester.pumpAndSettle();
    expect(tester.widget<Semantics>(libraryTab).properties.selected, isTrue);
  });
}
