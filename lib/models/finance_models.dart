/// Plano de Treino / Consultoria
class PlanItem {
  final String id;
  final String name;
  final String description;
  final String category;
  final String type; // 'subscription' | 'one_time'
  final double price;
  final String interval;
  final bool active;
  final String status; // 'active' | 'archived'
  final String createdAt;

  PlanItem({
    required this.id,
    required this.name,
    this.description = '',
    this.category = '',
    required this.type,
    required this.price,
    this.interval = 'Mensal',
    this.active = true,
    this.status = 'active',
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  PlanItem copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? type,
    double? price,
    String? interval,
    bool? active,
    String? status,
    String? createdAt,
  }) {
    return PlanItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      type: type ?? this.type,
      price: price ?? this.price,
      interval: interval ?? this.interval,
      active: active ?? this.active,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category,
    'type': type,
    'price': price,
    'interval': interval,
    'active': active,
    'status': status,
    'createdAt': createdAt,
  };

  factory PlanItem.fromJson(Map<String, dynamic> json) {
    return PlanItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      type: json['type']?.toString() ?? 'subscription',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      interval: json['interval']?.toString() ?? 'Mensal',
      active: json['active'] as bool? ?? true,
      status: json['status']?.toString() ?? 'active',
      createdAt: json['createdAt']?.toString(),
    );
  }
}

/// Assinatura de Aluno
class SubscriptionItem {
  final String id;
  final String studentId;
  final String studentName;
  final String planId;
  final String planName;
  final String
  status; // 'draft' | 'active' | 'paused' | 'cancelled' | 'expired'
  final double contractedValue;
  final double discount;
  final double readjustment;
  final String cycle;
  final String startDate;
  final bool autoRenew;
  final String createdAt;
  final String? updatedAt;

  SubscriptionItem({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.planId,
    required this.planName,
    required this.status,
    required this.contractedValue,
    this.discount = 0.0,
    this.readjustment = 0.0,
    this.cycle = 'Mensal',
    required this.startDate,
    this.autoRenew = true,
    String? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  SubscriptionItem copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? planId,
    String? planName,
    String? status,
    double? contractedValue,
    double? discount,
    double? readjustment,
    String? cycle,
    String? startDate,
    bool? autoRenew,
    String? createdAt,
    String? updatedAt,
  }) {
    return SubscriptionItem(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      status: status ?? this.status,
      contractedValue: contractedValue ?? this.contractedValue,
      discount: discount ?? this.discount,
      readjustment: readjustment ?? this.readjustment,
      cycle: cycle ?? this.cycle,
      startDate: startDate ?? this.startDate,
      autoRenew: autoRenew ?? this.autoRenew,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'planId': planId,
    'planName': planName,
    'status': status,
    'contractedValue': contractedValue,
    'discount': discount,
    'readjustment': readjustment,
    'cycle': cycle,
    'startDate': startDate,
    'autoRenew': autoRenew,
    'createdAt': createdAt,
    if (updatedAt != null) 'updatedAt': updatedAt,
  };

  factory SubscriptionItem.fromJson(Map<String, dynamic> json) {
    return SubscriptionItem(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      planId: json['planId']?.toString() ?? '',
      planName: json['planName']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      contractedValue: (json['contractedValue'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      readjustment: (json['readjustment'] as num?)?.toDouble() ?? 0.0,
      cycle: json['cycle']?.toString() ?? 'Mensal',
      startDate: json['startDate']?.toString() ?? '',
      autoRenew: json['autoRenew'] as bool? ?? true,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}

/// Fatura / Cobrança
class InvoiceItem {
  final String id;
  final String studentId;
  final String studentName;
  final String? subscriptionId;
  final String? planId;
  final String planName;
  final String type; // 'subscription' | 'one_time'
  final double originalAmount;
  final double discount;
  final double fine;
  final double interest;
  final double finalAmount;
  final String dueDate;
  final String status; // 'draft' | 'pending' | 'overdue' | 'paid' | 'cancelled'
  final String createdAt;
  final String? updatedAt;

  /// Status exibido: fatura pendente com vencimento passado está atrasada,
  /// mesmo que o registro no servidor ainda diga "pending".
  String effectiveStatus([DateTime? today]) {
    if (status != 'pending') return status;
    final due = DateTime.tryParse(dueDate);
    if (due == null) return status;
    final now = today ?? DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    return DateTime(due.year, due.month, due.day).isBefore(day)
        ? 'overdue'
        : status;
  }

  InvoiceItem({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.subscriptionId,
    this.planId,
    required this.planName,
    required this.type,
    required this.originalAmount,
    this.discount = 0.0,
    this.fine = 0.0,
    this.interest = 0.0,
    required this.finalAmount,
    required this.dueDate,
    required this.status,
    String? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  InvoiceItem copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? subscriptionId,
    String? planId,
    String? planName,
    String? type,
    double? originalAmount,
    double? discount,
    double? fine,
    double? interest,
    double? finalAmount,
    String? dueDate,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      type: type ?? this.type,
      originalAmount: originalAmount ?? this.originalAmount,
      discount: discount ?? this.discount,
      fine: fine ?? this.fine,
      interest: interest ?? this.interest,
      finalAmount: finalAmount ?? this.finalAmount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    if (subscriptionId != null) 'subscriptionId': subscriptionId,
    if (planId != null) 'planId': planId,
    'planName': planName,
    'type': type,
    'originalAmount': originalAmount,
    'discount': discount,
    'fine': fine,
    'interest': interest,
    'finalAmount': finalAmount,
    'dueDate': dueDate,
    'status': status,
    'createdAt': createdAt,
    if (updatedAt != null) 'updatedAt': updatedAt,
  };

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      studentName:
          json['studentName']?.toString() ??
          (json['studentSnapshot']?['name']?.toString() ?? ''),
      subscriptionId: json['subscriptionId']?.toString(),
      planId: json['planId']?.toString(),
      planName:
          json['planName']?.toString() ??
          (json['planSnapshot']?['name']?.toString() ?? ''),
      type: json['type']?.toString() ?? 'subscription',
      originalAmount: (json['originalAmount'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      fine: (json['fine'] as num?)?.toDouble() ?? 0.0,
      interest: (json['interest'] as num?)?.toDouble() ?? 0.0,
      finalAmount:
          (json['finalAmount'] as num?)?.toDouble() ??
          (json['originalAmount'] as num?)?.toDouble() ??
          0.0,
      dueDate: json['dueDate']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}

/// Pagamento Realizado
class PaymentItem {
  final String id;
  final String invoiceId;
  final String studentId;
  final String studentName;
  final double amount;
  final String paymentDate;
  final String paymentMethod; // 'pix' | 'cartao' | 'dinheiro' | 'transfer'
  final String status; // 'confirmed' | 'refunded'
  final String? notes;
  final String createdAt;

  PaymentItem({
    required this.id,
    required this.invoiceId,
    this.studentId = '',
    required this.studentName,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    required this.status,
    this.notes,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toJson() => {
    'id': id,
    'invoiceId': invoiceId,
    'studentId': studentId,
    'studentName': studentName,
    'amount': amount,
    'paymentDate': paymentDate,
    'paymentMethod': paymentMethod,
    'status': status,
    if (notes != null) 'notes': notes,
    'createdAt': createdAt,
  };

  factory PaymentItem.fromJson(Map<String, dynamic> json) {
    return PaymentItem(
      id: json['id']?.toString() ?? '',
      invoiceId: json['invoiceId']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: json['paymentDate']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? 'pix',
      status: json['status']?.toString() ?? 'confirmed',
      notes: json['notes']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}

/// Movimentação do Livro Caixa (Append-Only)
class CashFlowItem {
  final String id;
  final String type; // 'inflow' | 'outflow'
  final double amount;
  final String date;
  final String category;
  final String description;
  final String? referenceInvoiceId;
  final String createdAt;

  CashFlowItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.category,
    required this.description,
    this.referenceInvoiceId,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'amount': amount,
    'date': date,
    'category': category,
    'description': description,
    if (referenceInvoiceId != null) 'referenceInvoiceId': referenceInvoiceId,
    'createdAt': createdAt,
  };

  factory CashFlowItem.fromJson(Map<String, dynamic> json) {
    return CashFlowItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'inflow',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Receita',
      description: json['description']?.toString() ?? '',
      referenceInvoiceId: json['referenceInvoiceId']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}

/// Métricas Financeiras Consolidadas
class FinanceMetricsData {
  final double mrr;
  final double arr;
  final double receitaRecebida;
  final double receitaPrevista;
  final double receitaAtrasada;
  final double saldoCaixa;
  final double inadimplenciaPercentual;

  FinanceMetricsData({
    this.mrr = 0.0,
    this.arr = 0.0,
    this.receitaRecebida = 0.0,
    this.receitaPrevista = 0.0,
    this.receitaAtrasada = 0.0,
    this.saldoCaixa = 0.0,
    this.inadimplenciaPercentual = 0.0,
  });

  factory FinanceMetricsData.calculate({
    required List<SubscriptionItem> subscriptions,
    required List<InvoiceItem> invoices,
    required List<CashFlowItem> cashFlow,
    DateTime? today,
  }) {
    // 1. MRR: Soma dos valores contratados de assinaturas ativas
    double mrr = 0.0;
    for (final sub in subscriptions) {
      if (sub.status == 'active') {
        mrr += sub.contractedValue;
      }
    }
    final arr = mrr * 12.0;

    // 2. Faturas
    double receitaRecebida = 0.0;
    double receitaPrevista = 0.0;
    double receitaAtrasada = 0.0;

    for (final inv in invoices) {
      final status = inv.effectiveStatus(today);
      if (status == 'paid') {
        receitaRecebida += inv.finalAmount;
      } else if (status == 'pending') {
        receitaPrevista += inv.finalAmount;
      } else if (status == 'overdue') {
        receitaAtrasada += inv.finalAmount;
      }
    }

    // 3. Saldo de Caixa
    double saldoCaixa = 0.0;
    for (final cf in cashFlow) {
      if (cf.type == 'inflow') {
        saldoCaixa += cf.amount;
      } else {
        saldoCaixa -= cf.amount;
      }
    }

    // 4. Inadimplência
    final totalEmitido = receitaRecebida + receitaPrevista + receitaAtrasada;
    final inadimplenciaPercentual = totalEmitido > 0
        ? (receitaAtrasada / totalEmitido) * 100.0
        : 0.0;

    return FinanceMetricsData(
      mrr: mrr,
      arr: arr,
      receitaRecebida: receitaRecebida,
      receitaPrevista: receitaPrevista,
      receitaAtrasada: receitaAtrasada,
      saldoCaixa: saldoCaixa,
      inadimplenciaPercentual: inadimplenciaPercentual,
    );
  }
}

/// Estado Completo do Módulo Financeiro
class FinanceState {
  final int schemaVersion;
  final List<PlanItem> plans;
  final List<SubscriptionItem> subscriptions;
  final List<InvoiceItem> invoices;
  final List<PaymentItem> payments;
  final List<CashFlowItem> cashFlow;
  final List<Map<String, dynamic>> auditLog;

  FinanceState({
    this.schemaVersion = 3,
    this.plans = const [],
    this.subscriptions = const [],
    this.invoices = const [],
    this.payments = const [],
    this.cashFlow = const [],
    this.auditLog = const [],
  });

  FinanceMetricsData get metrics => FinanceMetricsData.calculate(
    subscriptions: subscriptions,
    invoices: invoices,
    cashFlow: cashFlow,
  );

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'plans': plans.map((p) => p.toJson()).toList(),
    'subscriptions': subscriptions.map((s) => s.toJson()).toList(),
    'invoices': invoices.map((i) => i.toJson()).toList(),
    'payments': payments.map((p) => p.toJson()).toList(),
    'cashFlow': cashFlow.map((c) => c.toJson()).toList(),
    'auditLog': auditLog,
  };

  factory FinanceState.fromJson(Map<String, dynamic> json) {
    return FinanceState(
      schemaVersion: json['schemaVersion'] as int? ?? 3,
      plans: (json['plans'] as List<dynamic>? ?? const [])
          .map((p) => PlanItem.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList(),
      subscriptions: (json['subscriptions'] as List<dynamic>? ?? const [])
          .map(
            (s) =>
                SubscriptionItem.fromJson(Map<String, dynamic>.from(s as Map)),
          )
          .toList(),
      invoices: (json['invoices'] as List<dynamic>? ?? const [])
          .map((i) => InvoiceItem.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList(),
      payments: (json['payments'] as List<dynamic>? ?? const [])
          .map((p) => PaymentItem.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList(),
      cashFlow: (json['cashFlow'] as List<dynamic>? ?? const [])
          .map(
            (c) => CashFlowItem.fromJson(Map<String, dynamic>.from(c as Map)),
          )
          .toList(),
      auditLog: (json['auditLog'] as List<dynamic>? ?? const [])
          .map((a) => Map<String, dynamic>.from(a as Map))
          .toList(),
    );
  }
}
