// Supabase Edge Functions - Financial Domain Types (TypeScript)
// Fonte de verdade: docs/FinanceiroV3.md & docs/supabase-schema.md

export type SubscriptionStatus = 'draft' | 'active' | 'paused' | 'cancelled' | 'expired';
export type InvoiceStatus = 'draft' | 'pending' | 'overdue' | 'paid' | 'cancelled';
export type PaymentStatus = 'confirmed' | 'refunded';
export type PaymentMethod = 'pix' | 'cartao' | 'dinheiro' | 'credit' | 'debit' | 'cash' | 'transfer';
export type PlanType = 'subscription' | 'one_time';
export type CashFlowType = 'inflow' | 'outflow';
export type StudentStatus = 'active' | 'archived';

export interface Plan {
  id: string;
  trainerId?: string;
  name: string;
  description?: string;
  category?: string;
  type: PlanType;
  price: number;
  interval?: string;
  active: boolean;
  status: 'active' | 'archived';
  createdAt: string;
}

export interface Subscription {
  id: string;
  trainerId?: string;
  studentId: string;
  planId: string;
  status: SubscriptionStatus;
  contractedValue: number;
  discount: number;
  readjustment: number;
  cycle: string;
  startDate: string;
  autoRenew: boolean;
  createdAt: string;
  updatedAt?: string;
}

export interface OneTimeSale {
  id: string;
  trainerId?: string;
  studentId: string;
  planId?: string | null;
  title: string;
  amount: number;
  date: string;
  status: string;
  createdAt: string;
}

export interface PlanSnapshot {
  id: string;
  name: string;
  description?: string;
  category?: string;
  type: PlanType;
  price: number;
}

export interface StudentSnapshot {
  id: string;
  name: string;
  phone?: string;
  email?: string;
}

export interface Invoice {
  id: string;
  trainerId?: string;
  studentId: string;
  subscriptionId?: string | null;
  oneTimeSaleId?: string | null;
  planId?: string | null;
  type: PlanType;
  planSnapshot?: PlanSnapshot | null;
  studentSnapshot?: StudentSnapshot | null;
  originalAmount: number;
  discount: number;
  fine: number;
  interest: number;
  finalAmount: number;
  dueDate: string;
  status: InvoiceStatus;
  createdAt: string;
  updatedAt?: string;
}

export interface Payment {
  id: string;
  trainerId?: string;
  invoiceId: string;
  studentId: string;
  amount: number;
  paymentDate: string;
  paymentMethod: PaymentMethod | string;
  status: PaymentStatus;
  notes?: string;
  createdAt: string;
}

export interface CashFlowEntry {
  id: string;
  trainerId?: string;
  type: CashFlowType;
  amount: number;
  date: string;
  category: string;
  description?: string;
  referenceId?: string | null;
  invoiceId?: string | null;
  createdAt?: string;
}

export interface AuditLogEntry {
  id: string;
  trainerId?: string;
  timestamp: string;
  entityType: string;
  entityId: string;
  action: string;
  description?: string;
  performedBy: string;
  oldValue?: unknown;
  newValue?: unknown;
  schemaVersion: number;
}

export interface StudentTimelineEntry {
  id: string;
  trainerId?: string;
  studentId: string;
  timestamp: string;
  title: string;
  description?: string;
  referenceType?: string | null;
  referenceId?: string | null;
}

export interface SubscriptionHistoryEntry {
  id: string;
  trainerId?: string;
  subscriptionId: string;
  studentId: string;
  timestamp: string;
  action: string;
  fromStatus?: string | null;
  toStatus?: string | null;
  description?: string;
}

export interface StudentSheet {
  student: {
    id: string;
    name: string;
    date?: string;
    teacher?: string;
    status?: StudentStatus | string;
    extra?: {
      cpf?: string;
      telEmergencia?: string;
      email?: string;
      endereco?: string;
      nicho?: string;
    };
    email?: string;
  };
  academia?: string;
  mes?: string;
  instructorNotes?: string;
}

export interface FinanceState {
  schemaVersion: number;
  plans: Plan[];
  subscriptions: Subscription[];
  oneTimeSales: OneTimeSale[];
  invoices: Invoice[];
  payments: Payment[];
  cashFlow: CashFlowEntry[];
  auditLog: AuditLogEntry[];
  studentTimeline: StudentTimelineEntry[];
  subscriptionHistory: SubscriptionHistoryEntry[];
}

export interface SystemState {
  students?: Record<string, StudentSheet>;
  finance: FinanceState;
}

export interface FinancialMetrics {
  mrr: number;
  arr: number;
  receitaPrevista: number;
  receitaRecebida: number;
  receitaAberto: number;
  receitaAtrasada: number;
  saldoCaixa: number;
  ticketMedio: number;
  inadimplenciaPercentual: number;
  activeSubsCount: number;
  paymentsCount: number;
  pendingCount: number;
  overdueCount: number;
}
