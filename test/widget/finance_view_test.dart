import 'package:valex_app/models/student_model.dart';
import 'package:valex_app/services/student_context_service.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valex_app/models/finance_models.dart';
import 'package:valex_app/repositories/finance_repository.dart';
import 'package:valex_app/views/finance/finance_view.dart';

const _storageKey = 'valex_finance_state_v3_signed-out';

class _FailingFinanceRepository extends FinanceRepository {
  @override
  Future<FinanceState> loadState() async {
    throw const FinanceDataException('Falha de leitura', FormatException());
  }
}

class _DelayedFinanceRepository extends FinanceRepository {
  final completer = Completer<FinanceState>();

  @override
  Future<FinanceState> loadState() => completer.future;
}

void _seedFinanceData() {
  final state = FinanceState(
    plans: [
      PlanItem(
        id: 'plan_1',
        name: 'Plano Essencial',
        type: 'subscription',
        price: 200,
      ),
      PlanItem(
        id: 'plan_2',
        name: 'Plano Avançado',
        type: 'subscription',
        price: 300,
      ),
    ],
    subscriptions: [
      SubscriptionItem(
        id: 'sub_1',
        studentId: 'student_1',
        studentName: 'Ana Souza',
        planId: 'plan_1',
        planName: 'Plano Essencial',
        status: 'active',
        contractedValue: 200,
        startDate: '2026-08-01',
      ),
    ],
    invoices: [
      InvoiceItem(
        id: 'inv_1',
        studentId: 'student_1',
        studentName: 'Ana Souza',
        planName: 'Plano Essencial',
        type: 'subscription',
        originalAmount: 200,
        finalAmount: 200,
        dueDate: '2026-09-10',
        status: 'pending',
      ),
    ],
  );
  SharedPreferences.setMockInitialValues({
    _storageKey: jsonEncode(state.toJson()),
  });
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    StudentContextService().addStudent(
      Student(id: 'st_1', name: 'Carlos Silva'),
    );
  });

  testWidgets('FinanceView renders KPI bar, invoices list and tabs properly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    _seedFinanceData();
    final repo = FinanceRepository();

    await tester.pumpWidget(MaterialApp(home: FinanceView(repository: repo)));

    await tester.pumpAndSettle();

    // 1. Verifica AppBar e Tabs
    expect(find.text('Financeiro'), findsOneWidget);
    expect(find.text('Faturas'), findsOneWidget);
    expect(find.text('Assinaturas'), findsOneWidget);
    expect(find.text('Planos'), findsOneWidget);
    expect(find.text('Livro Caixa'), findsOneWidget);
    expect(find.text('Relatórios'), findsOneWidget);

    // 2. Verifica KPIs do Topo
    expect(find.text('MRR'), findsOneWidget);
    expect(find.text('ARR'), findsOneWidget);
    expect(find.text('Saldo Caixa'), findsOneWidget);

    // 3. Verifica Faturas carregadas
    expect(find.text('Ana Souza'), findsWidgets);

    // 4. Navega para aba Assinaturas
    await tester.tap(find.text('Assinaturas'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Plano Essencial'), findsWidgets);

    // 5. Navega para aba Relatórios
    await tester.tap(find.text('Relatórios'));
    await tester.pumpAndSettle();
    expect(find.text('Exportar Relatório (CSV)'), findsOneWidget);
    expect(find.text('Exportar Relatório (JSON)'), findsOneWidget);
  });

  testWidgets('FinanceView shows an honest empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: FinanceView(repository: FinanceRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhum dado financeiro cadastrado.'), findsOneWidget);
    expect(find.text('Ana Souza'), findsNothing);
  });

  testWidgets('cancelamento exige confirmação e preserva a fatura', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    _seedFinanceData();
    final repo = FinanceRepository();
    await tester.pumpWidget(MaterialApp(home: FinanceView(repository: repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assinaturas'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Gerenciar assinatura de Ana Souza'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar assinatura'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelar assinatura?'), findsOneWidget);
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();
    expect(repo.state.subscriptions.single.status, 'active');

    await tester.tap(find.byTooltip('Gerenciar assinatura de Ana Souza'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar assinatura'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar cancelamento'));
    await tester.pumpAndSettle();
    expect(repo.state.subscriptions.single.status, 'cancelled');
    expect(repo.state.invoices.single.status, 'pending');
  });

  testWidgets('permite alterar plano sem alterar fatura existente', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    _seedFinanceData();
    final repo = FinanceRepository();
    await tester.pumpWidget(MaterialApp(home: FinanceView(repository: repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assinaturas'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Gerenciar assinatura de Ana Souza'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alterar plano'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Plano Avançado').last);
    await tester.pumpAndSettle();
    expect(repo.state.subscriptions.single.planId, 'plan_2');
    expect(repo.state.invoices.single.planName, 'Plano Essencial');
    expect(repo.state.invoices.single.status, 'pending');
  });

  testWidgets(
    'creates plan, subscription and invoice from an empty mobile view',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(home: FinanceView(repository: FinanceRepository())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Criar primeiro plano'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome do plano'),
        'Plano Mobile',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Valor'),
        '219,90',
      );
      await tester.tap(find.text('Criar plano'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Planos'));
      await tester.tap(find.text('Planos'));
      await tester.pumpAndSettle();
      expect(find.text('Plano Mobile'), findsOneWidget);

      await tester.tap(find.byTooltip('Criar registro financeiro'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nova assinatura'));
      await tester.pumpAndSettle();
      expect(find.text('Carlos Silva'), findsOneWidget);
      await tester.tap(find.text('Criar assinatura'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Assinaturas'));
      await tester.tap(find.text('Assinaturas'));
      await tester.pumpAndSettle();
      expect(find.text('Carlos Silva'), findsOneWidget);

      await tester.tap(find.byTooltip('Criar registro financeiro'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nova fatura'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Emitir fatura'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Faturas'));
      await tester.tap(find.text('Faturas'));
      await tester.pumpAndSettle();
      expect(find.text('Carlos Silva'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('FinanceView announces the loading state', (tester) async {
    final repository = _DelayedFinanceRepository();
    await tester.pumpWidget(
      MaterialApp(home: FinanceView(repository: repository)),
    );

    expect(
      find.bySemanticsLabel('Carregando dados financeiros'),
      findsOneWidget,
    );

    repository.completer.complete(FinanceState());
    await tester.pumpAndSettle();
  });

  testWidgets('FinanceView exposes load errors and retry action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: FinanceView(repository: _FailingFinanceRepository())),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar os dados financeiros.'),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
