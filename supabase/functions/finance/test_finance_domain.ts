// Teste Automatizado da Edge Function Financeira em TypeScript
// Equivalente 1:1 a test_finance_domain.js

import type { SystemState } from '../_shared/types.ts';
import {
  PlanService,
  SubscriptionService,
  BillingService,
  OneTimeSaleService,
  PaymentService,
  MetricsService,
} from '../_shared/services.ts';

function assert(condition: boolean, message: string): void {
  if (!condition) throw new Error(message);
}

function makeState(): SystemState {
  return {
    students: {
      st_1: {
        student: {
          id: 'st_1',
          name: 'Aluno V3',
          date: '2026-07-01',
          teacher: 'Valesca',
          status: 'active',
          extra: {
            telEmergencia: '(11) 99999-8888',
            email: 'aluno@example.test',
          },
          email: 'aluno@example.test',
        },
        academia: 'Academia',
        mes: 'Julho 2026',
      },
    },
    finance: {
      schemaVersion: 3,
      plans: [],
      subscriptions: [],
      oneTimeSales: [],
      invoices: [],
      payments: [],
      cashFlow: [],
      auditLog: [],
      studentTimeline: [],
      subscriptionHistory: [],
    },
  };
}

const failures: string[] = [];

function test(name: string, fn: () => void): void {
  try {
    fn();
    console.log(`OK ${name}`);
  } catch (err: any) {
    failures.push(`${name}: ${err.message}`);
    console.error(`FAIL ${name}: ${err.message}`);
  }
}

console.log('--- Executando Suíte de Testes TypeScript (Supabase Edge Function) ---\n');

test('runs official financial lifecycle with separated entities in TS', () => {
  const state = makeState();

  const plan = PlanService.createPlan(state, {
    name: 'Consultoria Mensal',
    type: 'subscription',
    price: 180,
    category: 'Consultoria Online',
  });
  const sub = SubscriptionService.createSubscription(state, 'st_1', plan.id);
  const result = BillingService.generateSubscriptionInvoices(state, '2026-07-05');
  const invoice = state.finance.invoices[0];
  const payment = PaymentService.processPayment(state, invoice.id, {
    paymentDate: '2026-07-04',
    paymentMethod: 'pix',
  });

  assert(state.finance.schemaVersion === 3, 'schemaVersion should be 3');
  assert(state.finance.plans.length === 1, 'plan was not created');
  assert(sub !== null && sub.status === 'active', 'subscription should become active');
  assert(result.created === 1, 'subscription invoice was not generated');
  assert(invoice.status === 'paid', 'invoice should be paid after payment');
  assert(invoice.planSnapshot?.name === 'Consultoria Mensal', 'invoice plan snapshot missing');
  assert(invoice.studentSnapshot?.name === 'Aluno V3', 'invoice student snapshot missing');
  assert(payment !== null && payment.status === 'confirmed', 'payment should be confirmed');
  assert(state.finance.cashFlow.length === 1 && state.finance.cashFlow[0].type === 'inflow', 'cashflow inflow missing');
  assert(state.finance.auditLog.length >= 4, 'audit log should record lifecycle events');
  assert(state.finance.studentTimeline.length >= 3, 'student timeline should record lifecycle events');
});

test('prevents terminal subscription state from returning to active in TS', () => {
  const state = makeState();
  const plan = PlanService.createPlan(state, { name: 'Plano', type: 'subscription', price: 100 });
  const sub = SubscriptionService.createSubscription(state, 'st_1', plan.id);

  assert(sub !== null, 'subscription must be created');
  const cancelled = SubscriptionService.cancel(state, sub.id);
  const reactivated = SubscriptionService.changeStatus(state, sub.id, 'active');

  assert(cancelled, 'subscription should be cancellable from active');
  assert(!reactivated, 'cancelled subscription must not return to active');
  assert(sub.status === 'cancelled', 'subscription terminal status changed unexpectedly');
});

test('refund creates negative cashflow without reopening paid invoice in TS', () => {
  const state = makeState();
  const plan = PlanService.createPlan(state, { name: 'Avulso', type: 'one_time', price: 90 });
  const { invoice } = OneTimeSaleService.createOneTimeSale(state, {
    studentId: 'st_1',
    planId: plan.id,
    dueDate: '2026-07-03',
  });
  PaymentService.processPayment(state, invoice.id, { paymentDate: '2026-07-02', paymentMethod: 'pix' });
  const refunded = PaymentService.refundPayment(state, invoice.id);

  assert(refunded, 'payment should be refundable');
  assert(state.finance.payments[0].status === 'refunded', 'payment status should be refunded');
  assert(invoice.status === 'paid', 'paid invoice should remain terminal/immutable');
  assert(state.finance.cashFlow.some((entry) => entry.type === 'outflow'), 'refund outflow missing');
});

test('calculates correct MRR, Receita Recebida, and Cash Balance in TS', () => {
  const state = makeState();
  const plan = PlanService.createPlan(state, { name: 'Plano Anual', type: 'subscription', price: 1200, interval: '12' });
  const sub = SubscriptionService.createSubscription(state, 'st_1', plan.id, { valorContratado: 100 });
  BillingService.generateSubscriptionInvoices(state, '2026-07-01');
  const invoice = state.finance.invoices[0];
  PaymentService.processPayment(state, invoice.id, { paymentDate: '2026-07-01', paymentMethod: 'pix' });

  const metrics = MetricsService.calculate(state);
  assert(metrics.mrr === 100, `MRR should be 100, got ${metrics.mrr}`);
  assert(metrics.arr === 1200, `ARR should be 1200, got ${metrics.arr}`);
  assert(metrics.receitaRecebida === 100, `Receita Recebida should be 100, got ${metrics.receitaRecebida}`);
  assert(metrics.saldoCaixa === 100, `Saldo Caixa should be 100, got ${metrics.saldoCaixa}`);
});

if (failures.length > 0) {
  console.error('\nTypeScript finance domain tests failed:');
  failures.forEach((failure) => console.error(`- ${failure}`));

} else {
  console.log('\nAll TypeScript finance domain tests passed successfully.');
}
