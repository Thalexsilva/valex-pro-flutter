// Supabase Edge Functions - Financial Domain Services (TypeScript)
// Fonte de verdade: docs/FinanceiroV3.md

import type {
  Plan,
  Subscription,
  OneTimeSale,
  Invoice,
  Payment,
  CashFlowEntry,
  SystemState,
  FinancialMetrics,
  PlanType,
  PaymentMethod,
} from './types.ts';
import {
  generateUUID,
  todayISO,
  nowISO,
  money,
  normalizeStatus,
  transition,
  planMonthlyValue,
  resolvePlan,
  resolveStudent,
  planSnapshot,
  studentSnapshot,
  appendAudit,
  appendStudentTimeline,
  appendSubscriptionHistory,
  calculateMetrics,
} from './domain.ts';

export class PlanService {
  static createPlan(
    state: SystemState,
    data: {
      name: string;
      description?: string;
      category?: string;
      type?: PlanType;
      price: number;
      interval?: string;
      trainerId?: string;
    }
  ): Plan {
    const plan: Plan = {
      id: generateUUID(),
      trainerId: data.trainerId,
      name: data.name,
      description: data.description || '',
      category: data.category || '',
      type: data.type || 'subscription',
      price: money(data.price),
      interval: data.type === 'subscription' ? data.interval || 'Mensal' : '0',
      active: true,
      status: 'active',
      createdAt: nowISO(),
    };
    state.finance.plans.push(plan);
    appendAudit(state, 'plan', plan.id, 'CREATE_PLAN', `Plano criado: ${plan.name}`, null, plan, data.trainerId);
    return plan;
  }
}

export class SubscriptionService {
  static createSubscription(
    state: SystemState,
    studentId: string,
    planId: string,
    opts: {
      valorContratado?: number;
      desconto?: number;
      reajuste?: number;
      ciclo?: string;
      inicio?: string;
      renovacaoAutomatica?: boolean;
      trainerId?: string;
    } = {}
  ): Subscription | null {
    const plan = resolvePlan(state, planId);
    const student = resolveStudent(state, studentId);
    if (!student || !plan) return null;

    const sub: Subscription = {
      id: generateUUID(),
      trainerId: opts.trainerId,
      studentId,
      planId: plan.id,
      status: 'draft',
      contractedValue: money(opts.valorContratado ?? planMonthlyValue(plan, null)),
      discount: money(opts.desconto),
      readjustment: money(opts.reajuste),
      cycle: opts.ciclo || 'Mensal',
      startDate: opts.inicio || todayISO(),
      autoRenew: opts.renovacaoAutomatica !== false,
      createdAt: nowISO(),
    };

    transition(sub, 'subscription', 'active');
    state.finance.subscriptions.push(sub);

    appendSubscriptionHistory(state, sub.id, studentId, 'CREATE_SUBSCRIPTION', 'draft', 'active', `Plano ${plan.name} contratado`, opts.trainerId);
    appendStudentTimeline(state, studentId, 'Plano Contratado', `Assinatura ativa do plano ${plan.name}`, 'subscription', sub.id, opts.trainerId);
    appendAudit(state, 'subscription', sub.id, 'CREATE_SUBSCRIPTION', `Assinatura criada para ${plan.name}`, null, sub, opts.trainerId);

    return sub;
  }

  static changeStatus(state: SystemState, subscriptionId: string, toStatus: string, trainerId?: string): boolean {
    const sub = state.finance.subscriptions.find((item) => item.id === subscriptionId);
    if (!sub) return false;
    const normalized = normalizeStatus(toStatus, toStatus);
    const fromStatus = sub.status;
    if (!transition(sub, 'subscription', normalized)) return false;

    appendSubscriptionHistory(state, sub.id, sub.studentId, 'CHANGE_SUBSCRIPTION_STATUS', fromStatus, normalized, '', trainerId);
    appendStudentTimeline(state, sub.studentId, 'Status da Assinatura', `Status alterado de ${fromStatus} para ${normalized}`, 'subscription', sub.id, trainerId);
    appendAudit(state, 'subscription', sub.id, 'CHANGE_SUBSCRIPTION_STATUS', `Assinatura ${fromStatus} -> ${normalized}`, null, null, trainerId);
    return true;
  }

  static pause(state: SystemState, subId: string, trainerId?: string): boolean {
    return this.changeStatus(state, subId, 'paused', trainerId);
  }

  static cancel(state: SystemState, subId: string, trainerId?: string): boolean {
    return this.changeStatus(state, subId, 'cancelled', trainerId);
  }

  static expire(state: SystemState, subId: string, trainerId?: string): boolean {
    return this.changeStatus(state, subId, 'expired', trainerId);
  }
}

export class BillingService {
  static createInvoice(
    state: SystemState,
    params: {
      id?: string;
      type?: PlanType;
      studentId: string;
      subscriptionId?: string | null;
      oneTimeSaleId?: string | null;
      planId?: string | null;
      valorOriginal?: number;
      customAmount?: number;
      desconto?: number;
      multa?: number;
      juros?: number;
      valorFinal?: number;
      dueDate?: string;
      trainerId?: string;
    }
  ): Invoice {
    const plan = resolvePlan(state, params.planId);
    const rawAmount = money(params.valorOriginal ?? params.customAmount ?? plan?.price);
    const invoice: Invoice = {
      id: params.id || `inv_${generateUUID().slice(0, 8)}`,
      trainerId: params.trainerId,
      type: params.type || 'subscription',
      studentId: params.studentId,
      subscriptionId: params.subscriptionId || null,
      oneTimeSaleId: params.oneTimeSaleId || null,
      planId: params.planId || null,
      planSnapshot: planSnapshot(plan),
      studentSnapshot: studentSnapshot(state, params.studentId),
      originalAmount: rawAmount,
      discount: money(params.desconto),
      fine: money(params.multa),
      interest: money(params.juros),
      finalAmount: money(params.valorFinal ?? rawAmount - money(params.desconto) + money(params.multa) + money(params.juros)),
      dueDate: params.dueDate || todayISO(),
      status: 'draft',
      createdAt: nowISO(),
    };

    transition(invoice, 'invoice', 'pending');
    if (invoice.status === 'pending' && invoice.dueDate < todayISO()) {
      invoice.status = 'overdue';
    }

    state.finance.invoices.push(invoice);
    appendStudentTimeline(state, params.studentId, 'Fatura Emitida', `Fatura de ${invoice.planSnapshot?.name || 'serviço'} emitida`, 'invoice', invoice.id, params.trainerId);
    appendAudit(state, 'invoice', invoice.id, 'CREATE_INVOICE', 'Fatura emitida', null, invoice, params.trainerId);
    return invoice;
  }

  static generateSubscriptionInvoices(state: SystemState, dueDate?: string | null, trainerId?: string): { created: number; skipped: number } {
    const currentMonth = (dueDate || todayISO()).slice(0, 7);
    const result = { created: 0, skipped: 0 };

    state.finance.subscriptions.forEach((sub) => {
      if (sub.status !== 'active') return;
      const plan = resolvePlan(state, sub.planId);
      if (!plan) return;

      const existing = state.finance.invoices.some(
        (inv) => inv.subscriptionId === sub.id && inv.dueDate && inv.dueDate.startsWith(currentMonth)
      );
      if (existing) {
        result.skipped++;
        return;
      }

      this.createInvoice(state, {
        type: 'subscription',
        studentId: sub.studentId,
        subscriptionId: sub.id,
        planId: sub.planId,
        valorOriginal: sub.contractedValue || plan.price,
        desconto: sub.discount || 0,
        dueDate: dueDate || todayISO(),
        trainerId,
      });
      result.created++;
    });

    return result;
  }
}

export class OneTimeSaleService {
  static createOneTimeSale(
    state: SystemState,
    params: {
      studentId: string;
      planId?: string | null;
      title?: string;
      amount?: number;
      date?: string;
      dueDate?: string;
      desconto?: number;
      trainerId?: string;
    }
  ): { sale: OneTimeSale; invoice: Invoice } {
    const plan = resolvePlan(state, params.planId);
    const amount = money(params.amount ?? plan?.price);
    const sale: OneTimeSale = {
      id: generateUUID(),
      trainerId: params.trainerId,
      studentId: params.studentId,
      planId: params.planId || null,
      title: params.title || plan?.name || 'Venda Avulsa',
      amount,
      date: params.date || todayISO(),
      status: 'issued',
      createdAt: nowISO(),
    };
    state.finance.oneTimeSales.push(sale);

    const invoice = BillingService.createInvoice(state, {
      type: 'one_time',
      studentId: sale.studentId,
      planId: sale.planId,
      oneTimeSaleId: sale.id,
      valorOriginal: amount,
      desconto: params.desconto || 0,
      dueDate: params.dueDate || todayISO(),
      trainerId: params.trainerId,
    });

    appendAudit(state, 'one_time_sale', sale.id, 'CREATE_ONE_TIME_SALE', `Venda avulsa criada: ${sale.title}`, null, sale, params.trainerId);
    return { sale, invoice };
  }
}

export class PaymentService {
  static processPayment(
    state: SystemState,
    invoiceId: string,
    opts: {
      paymentDate?: string;
      paymentMethod?: PaymentMethod | string;
      notes?: string;
      desconto?: number;
      multa?: number;
      juros?: number;
      trainerId?: string;
    } = {}
  ): Payment | null {
    const invoice = state.finance.invoices.find((inv) => inv.id === invoiceId);
    if (!invoice || (invoice.status !== 'pending' && invoice.status !== 'overdue')) return null;

    const original = money(invoice.originalAmount);
    invoice.discount = money(opts.desconto ?? invoice.discount);
    invoice.fine = money(opts.multa ?? invoice.fine);
    invoice.interest = money(opts.juros ?? invoice.interest);
    invoice.finalAmount = Math.max(0, original - invoice.discount + invoice.fine + invoice.interest);

    if (!transition(invoice, 'invoice', 'paid')) return null;

    const payment: Payment = {
      id: `pay_${generateUUID().slice(0, 10)}`,
      trainerId: opts.trainerId,
      invoiceId: invoice.id,
      studentId: invoice.studentId,
      amount: invoice.finalAmount,
      paymentDate: opts.paymentDate || todayISO(),
      paymentMethod: opts.paymentMethod || 'pix',
      status: 'confirmed',
      notes: opts.notes || '',
      createdAt: nowISO(),
    };

    state.finance.payments.push(payment);
    state.finance.cashFlow.push({
      id: `cf_${payment.id}`,
      trainerId: opts.trainerId,
      type: 'inflow',
      amount: payment.amount,
      date: payment.paymentDate,
      category: 'Recebimento de Fatura',
      description: `Pagamento de ${invoice.studentSnapshot?.name || 'Aluno'}`,
      referenceId: payment.id,
      invoiceId: invoice.id,
      createdAt: nowISO(),
    });

    appendStudentTimeline(state, invoice.studentId, 'Pagamento Confirmado', `Pagamento de ${invoice.finalAmount.toFixed(2)} confirmado`, 'payment', payment.id, opts.trainerId);
    appendAudit(state, 'payment', payment.id, 'CONFIRM_PAYMENT', 'Pagamento confirmado', null, payment, opts.trainerId);
    return payment;
  }

  static refundPayment(state: SystemState, invoiceId: string, trainerId?: string): boolean {
    const payment = state.finance.payments.find((item) => item.invoiceId === invoiceId && item.status === 'confirmed');
    if (!payment) return false;
    if (!transition(payment, 'payment', 'refunded')) return false;

    state.finance.cashFlow.push({
      id: `cf_refund_${payment.id}`,
      trainerId,
      type: 'outflow',
      amount: payment.amount,
      date: todayISO(),
      category: 'Estorno de Fatura',
      description: `Estorno de fatura ${invoiceId}`,
      referenceId: payment.id,
      invoiceId,
      createdAt: nowISO(),
    });

    appendStudentTimeline(state, payment.studentId, 'Pagamento Estornado', `Estorno de ${payment.amount.toFixed(2)}`, 'payment', payment.id, trainerId);
    appendAudit(state, 'payment', payment.id, 'REFUND_PAYMENT', 'Pagamento estornado', null, payment, trainerId);
    return true;
  }
}

export class CashFlowService {
  static recordEntry(
    state: SystemState,
    type: 'inflow' | 'outflow',
    amount: number,
    date?: string,
    category?: string,
    description?: string,
    referenceId: string | null = null,
    trainerId?: string
  ): CashFlowEntry {
    const entry: CashFlowEntry = {
      id: `cf_${generateUUID().slice(0, 8)}`,
      trainerId,
      type: type === 'outflow' ? 'outflow' : 'inflow',
      amount: money(amount),
      date: date || todayISO(),
      category: category || 'Geral',
      description: description || '',
      referenceId,
      createdAt: nowISO(),
    };
    state.finance.cashFlow.push(entry);
    appendAudit(state, 'cashflow', entry.id, 'CREATE_CASHFLOW_ENTRY', entry.description, null, entry, trainerId);
    return entry;
  }
}

export class MetricsService {
  static calculate(state: SystemState, filters: { startDate?: string; endDate?: string } = {}): FinancialMetrics {
    return calculateMetrics(state, filters);
  }
}
