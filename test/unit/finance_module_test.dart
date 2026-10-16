import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valex_app/models/finance_models.dart';
import 'package:valex_app/repositories/finance_repository.dart';

const _storageKey = 'valex_finance_state_v3_signed-out';

FinanceState _repositoryState() => FinanceState(
  plans: [
    PlanItem(
      id: 'plan_1',
      name: 'Acompanhamento Mensal',
      type: 'subscription',
      price: 200,
    ),
  ],
  invoices: [
    InvoiceItem(
      id: 'inv_pending',
      studentId: 'student_1',
      studentName: 'Ana Souza',
      planName: 'Acompanhamento Mensal',
      type: 'subscription',
      originalAmount: 200,
      finalAmount: 200,
      dueDate: '2026-10-05',
      status: 'pending',
    ),
    InvoiceItem(
      id: 'inv_paid',
      studentId: 'student_2',
      studentName: 'Bruno Lima',
      planName: 'Acompanhamento Mensal',
      type: 'subscription',
      originalAmount: 180,
      finalAmount: 180,
      dueDate: '2026-08-05',
      status: 'paid',
    ),
  ],
  payments: [
    PaymentItem(
      id: 'pay_paid',
      invoiceId: 'inv_paid',
      studentId: 'student_2',
      studentName: 'Bruno Lima',
      amount: 180,
      paymentDate: '2026-08-04',
      paymentMethod: 'pix',
      status: 'confirmed',
    ),
  ],
  cashFlow: [
    CashFlowItem(
      id: 'cash_paid',
      type: 'inflow',
      amount: 180,
      date: '2026-08-04',
      category: 'Mensalidade',
      description: 'Recebimento de Bruno Lima',
      referenceInvoiceId: 'inv_paid',
    ),
  ],
);

void _seedRepositoryState() {
  SharedPreferences.setMockInitialValues({
    _storageKey: jsonEncode(_repositoryState().toJson()),
  });
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Finance Module 3.0 — Domain Models & Dynamic KPI Calculations', () {
    test('Calculates MRR, ARR, Cashflow and Inadimplência dynamically', () {
      final subs = [
        SubscriptionItem(
          id: 's1',
          studentId: 'st1',
          studentName: 'Aluno A',
          planId: 'p1',
          planName: 'Mensal',
          status: 'active',
          contractedValue: 200.0,
          startDate: '2026-01-01',
        ),
        SubscriptionItem(
          id: 's2',
          studentId: 'st2',
          studentName: 'Aluno B',
          planId: 'p2',
          planName: 'Trimestral',
          status: 'active',
          contractedValue: 150.0,
          startDate: '2026-01-01',
        ),
        SubscriptionItem(
          id: 's3',
          studentId: 'st3',
          studentName: 'Aluno C',
          planId: 'p1',
          planName: 'Mensal',
          status: 'cancelled',
          contractedValue: 200.0,
          startDate: '2026-01-01',
        ),
      ];

      final invoices = [
        InvoiceItem(
          id: 'inv1',
          studentId: 'st1',
          studentName: 'Aluno A',
          planName: 'Mensal',
          type: 'subscription',
          originalAmount: 200.0,
          finalAmount: 200.0,
          dueDate: '2026-07-05',
          status: 'paid',
        ),
        InvoiceItem(
          id: 'inv2',
          studentId: 'st2',
          studentName: 'Aluno B',
          planName: 'Trimestral',
          type: 'subscription',
          originalAmount: 150.0,
          finalAmount: 150.0,
          dueDate: '2026-08-01',
          status: 'overdue',
        ),
        InvoiceItem(
          id: 'inv3',
          studentId: 'st1',
          studentName: 'Aluno A',
          planName: 'Mensal',
          type: 'subscription',
          originalAmount: 200.0,
          finalAmount: 200.0,
          dueDate: '2026-08-05',
          status: 'pending',
        ),
      ];

      final cashFlow = [
        CashFlowItem(
          id: 'cf1',
          type: 'inflow',
          amount: 200.0,
          date: '2026-07-04',
          category: 'Mensalidade',
          description: 'Recebimento',
        ),
        CashFlowItem(
          id: 'cf2',
          type: 'outflow',
          amount: 50.0,
          date: '2026-07-10',
          category: 'Taxa',
          description: 'Taxa Gateway',
        ),
      ];

      final metrics = FinanceMetricsData.calculate(
        subscriptions: subs,
        invoices: invoices,
        cashFlow: cashFlow,
        // Antes do vencimento de inv3 (05/08): ela ainda é receita prevista.
        today: DateTime(2026, 7, 15),
      );

      // MRR deve considerar apenas as 2 assinaturas ativas (200 + 150 = 350)
      expect(metrics.mrr, equals(350.0));
      expect(metrics.arr, equals(4200.0));
      expect(metrics.receitaRecebida, equals(200.0));
      expect(metrics.receitaAtrasada, equals(150.0));
      expect(metrics.receitaPrevista, equals(200.0));
      expect(metrics.saldoCaixa, equals(150.0)); // 200 - 50 = 150
      // Inadimplência: 150 / (200 + 200 + 150) * 100 = 150 / 550 * 100 = 27.27%
      expect(metrics.inadimplenciaPercentual, closeTo(27.27, 0.05));
    });

    test('Serializes and deserializes FinanceState accurately', () {
      final original = FinanceState(
        schemaVersion: 3,
        plans: [
          PlanItem(
            id: 'p1',
            name: 'Plano VIP',
            type: 'subscription',
            price: 299.9,
          ),
        ],
        subscriptions: [
          SubscriptionItem(
            id: 'sub1',
            studentId: 'st1',
            studentName: 'João',
            planId: 'p1',
            planName: 'Plano VIP',
            status: 'active',
            contractedValue: 299.9,
            startDate: '2026-06-01',
          ),
        ],
        invoices: [
          InvoiceItem(
            id: 'inv1',
            studentId: 'st1',
            studentName: 'João',
            planName: 'Plano VIP',
            type: 'subscription',
            originalAmount: 299.9,
            finalAmount: 299.9,
            dueDate: '2026-06-05',
            status: 'pending',
          ),
        ],
      );

      final json = original.toJson();
      final restored = FinanceState.fromJson(json);

      expect(restored.schemaVersion, equals(3));
      expect(restored.plans.length, equals(1));
      expect(restored.plans.first.name, equals('Plano VIP'));
      expect(restored.subscriptions.length, equals(1));
      expect(restored.subscriptions.first.contractedValue, equals(299.9));
      expect(restored.invoices.length, equals(1));
      expect(restored.invoices.first.dueDate, equals('2026-06-05'));
    });
  });

  group('FinanceRepository Lifecycle & Mutations', () {
    test('Finance API never fabricates remote success', () {
      final source = File(
        'lib/services/finance_api_service.dart',
      ).readAsStringSync();

      expect(source, isNot(contains("'mock': true")));
      expect(source, isNot(contains("'success': true")));
      expect(source, contains('throw FinanceApiException'));
    });

    test('Starts empty instead of fabricating financial records', () async {
      final state = await FinanceRepository().loadState();

      expect(state.plans, isEmpty);
      expect(state.subscriptions, isEmpty);
      expect(state.invoices, isEmpty);
      expect(state.payments, isEmpty);
      expect(state.cashFlow, isEmpty);
      expect(state.metrics.saldoCaixa, equals(0));
    });

    test('Reports corrupt persisted data instead of replacing it', () async {
      SharedPreferences.setMockInitialValues({_storageKey: '{invalid-json'});

      await expectLater(
        FinanceRepository().loadState(),
        throwsA(isA<FinanceDataException>()),
      );
    });

    test('isolates financial cache by account', () async {
      final accountA = FinanceRepository(accountId: () => 'account-a');
      final accountB = FinanceRepository(accountId: () => 'account-b');

      await accountA.saveState(
        FinanceState(
          plans: [
            PlanItem(
              id: 'plan-a',
              name: 'Plano da conta A',
              type: 'subscription',
              price: 150,
            ),
          ],
        ),
      );
      await accountB.saveState(
        FinanceState(
          plans: [
            PlanItem(
              id: 'plan-b',
              name: 'Plano da conta B',
              type: 'subscription',
              price: 250,
            ),
          ],
        ),
      );

      final restoredA = await FinanceRepository(
        accountId: () => 'account-a',
      ).loadState();
      final restoredB = await FinanceRepository(
        accountId: () => 'account-b',
      ).loadState();

      expect(restoredA.plans.single.name, 'Plano da conta A');
      expect(restoredB.plans.single.name, 'Plano da conta B');
    });

    test(
      'keeps scoped cache visible when remote sync is unavailable',
      () async {
        final cached = FinanceState(
          plans: [
            PlanItem(
              id: 'cached-plan',
              name: 'Plano salvo',
              type: 'subscription',
              price: 100,
            ),
          ],
        );
        SharedPreferences.setMockInitialValues({
          'valex_finance_state_v3_offline-account': jsonEncode(cached.toJson()),
        });
        final repository = FinanceRepository(
          accountId: () => 'offline-account',
          isRemote: () => true,
        );

        final restored = await repository.loadState();

        expect(restored.plans.single.name, 'Plano salvo');
        expect(repository.usingCachedData, isTrue);
        expect(repository.lastSyncError, isNotNull);
      },
    );

    test(
      'Loads initial state and confirms payment with ledger recording',
      () async {
        _seedRepositoryState();
        final repo = FinanceRepository();
        final state = await repo.loadState();

        expect(state.invoices, hasLength(2));
        final pendingInv = state.invoices.firstWhere(
          (i) => i.status == 'pending',
        );

        final ok = await repo.confirmPayment(
          invoiceId: pendingInv.id,
          paymentMethod: 'pix',
          discount: 10.0,
        );

        expect(ok, isTrue);

        final updatedState = repo.state;
        final paidInv = updatedState.invoices.firstWhere(
          (i) => i.id == pendingInv.id,
        );

        expect(paidInv.status, equals('paid'));
        expect(paidInv.discount, equals(10.0));
        expect(paidInv.finalAmount, equals(pendingInv.originalAmount - 10.0));

        // Verifica entrada criada no Livro Caixa
        final cashFlowEntry = updatedState.cashFlow.firstWhere(
          (c) => c.referenceInvoiceId == pendingInv.id,
        );
        expect(cashFlowEntry.type, equals('inflow'));
        expect(cashFlowEntry.amount, equals(paidInv.finalAmount));

        // Verifica pagamentos
        final payment = updatedState.payments.firstWhere(
          (p) => p.invoiceId == pendingInv.id,
        );
        expect(payment.status, equals('confirmed'));
        expect(payment.amount, equals(paidInv.finalAmount));
      },
    );

    test('Refunds payment and records cash outflow', () async {
      _seedRepositoryState();
      final repo = FinanceRepository();
      await repo.loadState();

      // Pega uma fatura paga
      final paidInv = repo.state.invoices.firstWhere((i) => i.status == 'paid');

      final ok = await repo.refundPayment(paidInv.id);
      expect(ok, isTrue);

      final updatedInv = repo.state.invoices.firstWhere(
        (i) => i.id == paidInv.id,
      );
      expect(updatedInv.status, equals('pending'));

      // Verifica saída no Livro Caixa
      final outflow = repo.state.cashFlow.firstWhere(
        (c) => c.referenceInvoiceId == paidInv.id && c.type == 'outflow',
      );
      expect(outflow.amount, equals(paidInv.finalAmount));
    });

    test(
      'changes a subscription plan without rewriting invoice history',
      () async {
        final original = _repositoryState();
        final state = FinanceState(
          plans: [
            ...original.plans,
            PlanItem(
              id: 'plan_2',
              name: 'Plano trimestral',
              type: 'subscription',
              price: 450,
              interval: 'Trimestral',
            ),
          ],
          subscriptions: [
            SubscriptionItem(
              id: 'sub_1',
              studentId: 'student_1',
              studentName: 'Ana Souza',
              planId: 'plan_1',
              planName: 'Acompanhamento Mensal',
              status: 'active',
              contractedValue: 200,
              startDate: '2026-01-01',
            ),
          ],
          invoices: original.invoices,
          payments: original.payments,
          cashFlow: original.cashFlow,
        );
        SharedPreferences.setMockInitialValues({
          _storageKey: jsonEncode(state.toJson()),
        });
        final repo = FinanceRepository();
        await repo.loadState();

        expect(await repo.changeSubscriptionPlan('sub_1', 'plan_2'), isTrue);
        expect(repo.state.subscriptions.single.planId, 'plan_2');
        expect(repo.state.subscriptions.single.contractedValue, 450);
        expect(repo.state.subscriptions.single.cycle, 'Trimestral');
        expect(
          repo.state.invoices.map((item) => item.toJson()).toList(),
          original.invoices.map((item) => item.toJson()).toList(),
        );
        expect(repo.state.payments.length, original.payments.length);
        expect(repo.state.cashFlow.length, original.cashFlow.length);

        expect(await repo.cancelSubscription('sub_1'), isTrue);
        expect(repo.state.subscriptions.single.status, 'cancelled');
        expect(repo.state.subscriptions.single.autoRenew, isFalse);
        expect(repo.state.invoices.length, original.invoices.length);
        expect(repo.state.payments.length, original.payments.length);
        expect(repo.state.cashFlow.length, original.cashFlow.length);
      },
    );

    test('Exports CSV and JSON without exceptions', () async {
      _seedRepositoryState();
      final repo = FinanceRepository();
      await repo.loadState();

      final csv = repo.exportInvoicesCsv();
      expect(csv, contains('ID,Aluno,Plano'));
      expect(csv, contains('Ana Souza'));

      final json = repo.exportJson();
      expect(json, contains('"schemaVersion": 3'));
      expect(json, contains('Acompanhamento Mensal'));
    });
  });
}
