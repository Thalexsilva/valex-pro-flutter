// Supabase Edge Functions - Financial Domain Logic & State Machines (TypeScript)
// Fonte de verdade: docs/FinanceiroV3.md

import type {
  SubscriptionStatus,
  InvoiceStatus,
  PaymentStatus,
  Plan,
  Subscription,
  Invoice,
  Payment,
  PlanSnapshot,
  StudentSnapshot,
  SystemState,
  StudentSheet,
  FinancialMetrics,
} from './types.ts';

export const SUB_STATUSES: SubscriptionStatus[] = ['draft', 'active', 'paused', 'cancelled', 'expired'];
export const INV_STATUSES: InvoiceStatus[] = ['draft', 'pending', 'overdue', 'paid', 'cancelled'];
export const PAY_STATUSES: PaymentStatus[] = ['confirmed', 'refunded'];

export const TRANSITIONS: Record<string, Record<string, string[]>> = {
  subscription: {
    draft: ['active'],
    active: ['paused', 'cancelled', 'expired'],
    paused: ['active', 'cancelled'],
    cancelled: [],
    expired: [],
  },
  invoice: {
    draft: ['pending'],
    pending: ['overdue', 'paid', 'cancelled'],
    overdue: ['paid', 'cancelled'],
    paid: [],
    cancelled: [],
  },
  payment: {
    confirmed: ['refunded'],
    refunded: [],
  },
};

export const STATUS_MAP: Record<string, string> = {
  ativa: 'active',
  ativo: 'active',
  active: 'active',
  pausada: 'paused',
  paused: 'paused',
  cancelada: 'cancelled',
  cancelado: 'cancelled',
  cancelled: 'cancelled',
  expirada: 'expired',
  expired: 'expired',
  gerada: 'pending',
  pendente: 'pending',
  pending: 'pending',
  vencida: 'overdue',
  atrasada: 'overdue',
  overdue: 'overdue',
  pago: 'paid',
  paga: 'paid',
  paid: 'paid',
  refunded: 'refunded',
  confirmed: 'confirmed',
};

export function generateUUID(): string {
  if (typeof crypto !== 'undefined' && crypto.randomUUID) {
    return crypto.randomUUID();
  }
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

export function todayISO(): string {
  return new Date().toISOString().split('T')[0];
}

export function nowISO(): string {
  return new Date().toISOString();
}

export function money(value: unknown): number {
  const num = Number(value);
  return isNaN(num) ? 0 : Math.round(num * 100) / 100;
}

export function normalizeStatus<T extends string>(status: unknown, fallback: T): T {
  const str = String(status || '').toLowerCase().trim();
  return (STATUS_MAP[str] as T) || fallback;
}

export function canTransition(type: 'subscription' | 'invoice' | 'payment', fromStatus: string, toStatus: string): boolean {
  const allowed = TRANSITIONS[type]?.[fromStatus] || [];
  return allowed.includes(toStatus);
}

export function transition<T extends { status: string; updatedAt?: string }>(
  entity: T,
  type: 'subscription' | 'invoice' | 'payment',
  toStatus: string
): boolean {
  const fromStatus = entity.status;
  if (fromStatus === toStatus) return true;
  if (!canTransition(type, fromStatus, toStatus)) {
    return false;
  }
  entity.status = toStatus;
  entity.updatedAt = nowISO();
  return true;
}

export function planMonthlyValue(plan: Plan | null, subscription?: Subscription | null): number {
  if (subscription && subscription.contractedValue != null && subscription.contractedValue > 0) {
    return money(subscription.contractedValue);
  }
  if (!plan) return 0;
  const price = money(plan.price);
  let interval = 1;
  if (typeof plan.interval === 'number' && (plan.interval as number) > 0) {
    interval = plan.interval as number;
  } else if (typeof plan.interval === 'string') {
    const l = (plan.interval as string).toLowerCase().trim();
    if (l.includes('bimestral')) interval = 2;
    else if (l.includes('trimestral')) interval = 3;
    else if (l.includes('semestral')) interval = 6;
    else if (l.includes('anual')) interval = 12;
    else {
      const parsed = parseFloat(l);
      if (!isNaN(parsed) && parsed > 0) interval = parsed;
    }
  }
  return price / interval;
}

export function resolveStudent(state: SystemState, studentId: string): StudentSheet['student'] | null {
  return state.students?.[studentId]?.student || null;
}

export function resolvePlan(state: SystemState, planId?: string | null): Plan | null {
  if (!planId) return null;
  const plans = state.finance?.plans || [];
  let match = plans.find((p) => p.id === planId);
  if (!match) {
    const key = String(planId).trim().toLowerCase();
    match = plans.find((p) => String(p.id || '').trim().toLowerCase() === key || String(p.name || '').trim().toLowerCase() === key);
  }
  return match || null;
}

export function studentSnapshot(state: SystemState, studentId: string): StudentSnapshot | null {
  const st = resolveStudent(state, studentId);
  if (!st) return null;
  return {
    id: st.id || studentId,
    name: st.name || 'Desconhecido',
    phone: st.extra?.telEmergencia || '',
    email: st.extra?.email || st.email || '',
  };
}

export function planSnapshot(plan: Plan | null): PlanSnapshot | null {
  if (!plan) return null;
  return {
    id: plan.id,
    name: plan.name,
    description: plan.description || '',
    category: plan.category || '',
    type: plan.type || 'subscription',
    price: money(plan.price),
  };
}

export function appendAudit(
  state: SystemState,
  entityType: string,
  entityId: string,
  action: string,
  description?: string,
  oldValue: unknown = null,
  newValue: unknown = null,
  trainerId?: string
): void {
  if (!Array.isArray(state.finance.auditLog)) state.finance.auditLog = [];
  state.finance.auditLog.push({
    id: generateUUID(),
    trainerId,
    timestamp: nowISO(),
    entityType,
    entityId,
    action,
    description,
    performedBy: 'Sistema',
    oldValue,
    newValue,
    schemaVersion: 3,
  });
}

export function appendStudentTimeline(
  state: SystemState,
  studentId: string,
  title: string,
  description?: string,
  referenceType: string | null = null,
  referenceId: string | null = null,
  trainerId?: string
): void {
  if (!Array.isArray(state.finance.studentTimeline)) state.finance.studentTimeline = [];
  state.finance.studentTimeline.push({
    id: generateUUID(),
    trainerId,
    studentId,
    timestamp: nowISO(),
    title,
    description,
    referenceType,
    referenceId,
  });
}

export function appendSubscriptionHistory(
  state: SystemState,
  subscriptionId: string,
  studentId: string,
  action: string,
  fromStatus?: string | null,
  toStatus?: string | null,
  description: string = '',
  trainerId?: string
): void {
  if (!Array.isArray(state.finance.subscriptionHistory)) state.finance.subscriptionHistory = [];
  state.finance.subscriptionHistory.push({
    id: generateUUID(),
    trainerId,
    subscriptionId,
    studentId,
    timestamp: nowISO(),
    action,
    fromStatus,
    toStatus,
    description,
  });
}

export function calculateMetrics(state: SystemState, filters: { startDate?: string; endDate?: string } = {}): FinancialMetrics {
  const f = state.finance;
  const periodStart = filters.startDate || '';
  const periodEnd = filters.endDate || '';
  const inPeriod = (date: string) => (!periodStart || date >= periodStart) && (!periodEnd || date <= periodEnd);

  const activeSubs = (f.subscriptions || []).filter((sub) => sub.status === 'active');
  const mrr = activeSubs.reduce((sum, sub) => sum + planMonthlyValue(resolvePlan(state, sub.planId), sub), 0);
  const payments = (f.payments || []).filter((payment) => payment.status === 'confirmed' && inPeriod(payment.paymentDate || ''));
  const pendingInvoices = (f.invoices || []).filter((inv) => inv.status === 'pending' && inPeriod(inv.dueDate || ''));
  const overdueInvoices = (f.invoices || []).filter((inv) => inv.status === 'overdue' && inPeriod(inv.dueDate || ''));
  const issuedInvoices = (f.invoices || []).filter((inv) => inPeriod(inv.dueDate || ''));

  const receitaRecebida = payments.reduce((sum, payment) => sum + money(payment.amount), 0);
  const receitaPrevista = pendingInvoices.reduce((sum, inv) => sum + money(inv.finalAmount), 0);
  const receitaAtrasada = overdueInvoices.reduce((sum, inv) => sum + money(inv.finalAmount), 0);
  const cashBalance = (f.cashFlow || [])
    .filter((entry) => inPeriod(entry.date || ''))
    .reduce((sum, entry) => sum + (entry.type === 'outflow' ? -money(entry.amount) : money(entry.amount)), 0);

  return {
    mrr: money(mrr),
    arr: money(mrr * 12),
    receitaPrevista: money(receitaPrevista),
    receitaRecebida: money(receitaRecebida),
    receitaAberto: money(receitaPrevista),
    receitaAtrasada: money(receitaAtrasada),
    saldoCaixa: money(cashBalance),
    ticketMedio: payments.length ? money(receitaRecebida / payments.length) : 0,
    inadimplenciaPercentual: issuedInvoices.length ? money((overdueInvoices.length / issuedInvoices.length) * 100) : 0,
    activeSubsCount: activeSubs.length,
    paymentsCount: payments.length,
    pendingCount: pendingInvoices.length,
    overdueCount: overdueInvoices.length,
  };
}
