import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import '../models/finance_models.dart';
import '../models/student_model.dart';
import '../services/finance_api_service.dart';
import '../services/student_context_service.dart';
import '../utils/formatters.dart';

class FinanceDataException implements Exception {
  final String message;
  final Object cause;

  const FinanceDataException(this.message, this.cause);

  @override
  String toString() => message;
}

class FinanceRepository extends ChangeNotifier {
  FinanceRepository({
    FinanceRemoteCall? remoteCall,
    bool Function()? isRemote,
    String Function()? accountId,
  }) : _remoteCall = remoteCall ?? FinanceApiService.invokeEdgeFunction,
       _isRemote = isRemote ?? (() => SupabaseConfig.hasAuthenticatedUser),
       _accountId = accountId ?? _defaultAccountId;

  final FinanceRemoteCall _remoteCall;
  final bool Function() _isRemote;
  final String Function() _accountId;
  bool get usesRemoteValidation => _isRemote();
  Map<String, dynamic> _extraState = {};
  static const String _storageKey = 'valex_finance_state_v3';

  FinanceState _state = FinanceState();
  bool _initialized = false;
  String? _lastSyncError;
  DateTime? _lastSyncedAt;
  bool _usingCachedData = false;

  FinanceState get state => _state;
  FinanceMetricsData get metrics => _state.metrics;
  String? get lastSyncError => _lastSyncError;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  bool get usingCachedData => _usingCachedData;

  static String _defaultAccountId() {
    try {
      return SupabaseConfig.client.auth.currentUser?.id ?? 'signed-out';
    } catch (_) {
      return 'signed-out';
    }
  }

  String get _currentStorageKey {
    final account = _accountId().trim();
    return '${_storageKey}_${account.isEmpty ? 'signed-out' : account}';
  }

  /// Inicializa e carrega estado financeiro do armazenamento persistente
  Future<FinanceState> loadState() async {
    var hasCache = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_currentStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _extraState = json;
        _state = FinanceState.fromJson(json);
        hasCache = true;
      } else {
        _state = FinanceState();
      }
    } catch (error) {
      _initialized = false;
      throw FinanceDataException(
        'Não foi possível ler os dados financeiros salvos.',
        error,
      );
    }

    if (_isRemote()) {
      try {
        final remote = await _fetchRemoteState();
        _lastSyncError = null;
        _lastSyncedAt = DateTime.now();
        _usingCachedData = false;
        if (!await _cacheState(remote)) {
          throw StateError('O cache local recusou a gravação.');
        }
      } catch (error) {
        _lastSyncError = 'Sem conexão com o financeiro. Exibindo dados salvos.';
        _usingCachedData = hasCache;
        if (!hasCache) {
          _initialized = false;
          throw FinanceDataException(
            'Não foi possível sincronizar os dados financeiros.',
            error,
          );
        }
      }
    } else {
      _lastSyncError = null;
      _usingCachedData = false;
    }
    _initialized = true;
    notifyListeners();
    return _state;
  }

  /// Salva o estado atual no SharedPreferences
  Future<bool> saveState(FinanceState newState) async {
    final saved = await _cacheState(newState);
    if (saved) notifyListeners();
    return saved;
  }

  Future<bool> _cacheState(FinanceState newState) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setString(
        _currentStorageKey,
        jsonEncode({..._extraState, ...newState.toJson()}),
      );
      if (!saved) return false;
      _state = newState;
      _initialized = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearCurrentAccountCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentStorageKey);
    _state = FinanceState();
    _extraState = {};
    _initialized = false;
    _lastSyncError = null;
    _lastSyncedAt = null;
    _usingCachedData = false;
    notifyListeners();
  }

  Future<Map<String, String>> loadStudents() async {
    if (!_isRemote()) {
      final contextual = {
        for (final student in StudentContextService().allStudents)
          if (student.status == StudentStatus.active) student.id: student.name,
      };
      return {
        ...contextual,
        for (final sub in _state.subscriptions) sub.studentId: sub.studentName,
        for (final inv in _state.invoices) inv.studentId: inv.studentName,
      };
    }
    try {
      final user = SupabaseConfig.client.auth.currentUser!;
      final rows = await SupabaseConfig.client
          .from('students')
          .select('id,name')
          .eq('trainer_id', user.id);
      return {
        for (final row in rows) row['id'] as String: row['name'] as String,
      };
    } catch (error) {
      throw FinanceDataException('Não foi possível carregar os alunos.', error);
    }
  }

  Future<FinanceState> _fetchRemoteState() async {
    final client = SupabaseConfig.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw FinanceDataException(
        'Entre na sua conta para sincronizar o financeiro.',
        StateError('Sessão ausente'),
      );
    }

    final rows = await Future.wait<dynamic>([
      client.from('students').select('id,name').eq('trainer_id', userId),
      client.from('plans').select().eq('trainer_id', userId),
      client.from('subscriptions').select().eq('trainer_id', userId),
      client.from('invoices').select().eq('trainer_id', userId),
      client.from('payments').select().eq('trainer_id', userId),
      client.from('cash_flow').select().eq('trainer_id', userId),
      client.from('audit_log').select().eq('trainer_id', userId),
    ]);
    final students = {
      for (final row in rows[0] as List)
        row['id'].toString(): row['name']?.toString() ?? '',
    };
    final plans = (rows[1] as List)
        .map(
          (row) => PlanItem.fromJson({
            ...Map<String, dynamic>.from(row as Map),
            'createdAt': row['created_at'],
          }),
        )
        .toList();
    final planNames = {for (final plan in plans) plan.id: plan.name};
    final subscriptions = (rows[2] as List).map((value) {
      final row = Map<String, dynamic>.from(value as Map);
      return SubscriptionItem.fromJson({
        'id': row['id'],
        'studentId': row['student_id'],
        'studentName': students[row['student_id'].toString()] ?? '',
        'planId': row['plan_id'],
        'planName': planNames[row['plan_id'].toString()] ?? '',
        'status': row['status'],
        'contractedValue': row['contracted_value'],
        'discount': row['discount'],
        'readjustment': row['readjustment'],
        'cycle': row['cycle'],
        'startDate': row['start_date'],
        'autoRenew': row['auto_renew'],
        'createdAt': row['created_at'],
        'updatedAt': row['updated_at'],
      });
    }).toList();
    final invoices = (rows[3] as List).map((value) {
      final row = Map<String, dynamic>.from(value as Map);
      return InvoiceItem.fromJson({
        'id': row['id'],
        'studentId': row['student_id'],
        'studentName':
            (row['student_snapshot'] as Map?)?['name'] ??
            students[row['student_id'].toString()] ??
            '',
        'subscriptionId': row['subscription_id'],
        'planId': row['plan_id'],
        'planName':
            (row['plan_snapshot'] as Map?)?['name'] ??
            planNames[row['plan_id'].toString()] ??
            '',
        'type': row['type'],
        'originalAmount': row['original_amount'],
        'discount': row['discount'],
        'fine': row['fine'],
        'interest': row['interest'],
        'finalAmount': row['final_amount'],
        'dueDate': row['due_date'],
        'status': row['status'],
        'createdAt': row['created_at'],
        'updatedAt': row['updated_at'],
      });
    }).toList();
    final payments = (rows[4] as List).map((value) {
      final row = Map<String, dynamic>.from(value as Map);
      return PaymentItem.fromJson({
        'id': row['id'],
        'invoiceId': row['invoice_id'],
        'studentId': row['student_id'],
        'studentName': students[row['student_id'].toString()] ?? '',
        'amount': row['amount'],
        'paymentDate': row['payment_date'],
        'paymentMethod': row['payment_method'],
        'status': row['status'],
        'notes': row['notes'],
        'createdAt': row['created_at'],
      });
    }).toList();
    final cashFlow = (rows[5] as List).map((value) {
      final row = Map<String, dynamic>.from(value as Map);
      return CashFlowItem.fromJson({
        'id': row['id'],
        'type': row['type'],
        'amount': row['amount'],
        'date': row['date'],
        'category': row['category'],
        'description': row['description'],
        'referenceInvoiceId': row['invoice_id'],
        'createdAt': row['created_at'],
      });
    }).toList();

    return FinanceState(
      plans: plans,
      subscriptions: subscriptions,
      invoices: invoices,
      payments: payments,
      cashFlow: cashFlow,
      auditLog: (rows[6] as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
    );
  }

  void _validateAmount(double value) {
    if (!value.isFinite || value < 0) {
      throw ArgumentError('Informe um valor válido, maior ou igual a zero.');
    }
  }

  void _validateDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
        parsed == null ||
        parsed.toIso8601String().split('T').first != value) {
      throw ArgumentError('Informe uma data válida.');
    }
  }

  FinanceState _withRecords({
    List<PlanItem>? plans,
    List<SubscriptionItem>? subscriptions,
    List<InvoiceItem>? invoices,
  }) => FinanceState(
    schemaVersion: _state.schemaVersion,
    plans: plans ?? _state.plans,
    subscriptions: subscriptions ?? _state.subscriptions,
    invoices: invoices ?? _state.invoices,
    payments: _state.payments,
    cashFlow: _state.cashFlow,
    auditLog: _state.auditLog,
  );

  Future<bool> createPlan({
    required String name,
    required double price,
    String type = 'subscription',
    String interval = 'Mensal',
  }) async {
    if (!_initialized) await loadState();
    _validateAmount(price);
    if (name.trim().isEmpty || !['subscription', 'one_time'].contains(type)) {
      throw ArgumentError('Informe nome e tipo de plano válidos.');
    }
    final plan = PlanItem(
      id: Formatters.generateUuidV4(),
      name: name.trim(),
      type: type,
      price: price,
      interval: type == 'one_time' ? '0' : interval,
    );
    return _commit(
      'create_plan',
      plan.toJson(),
      _withRecords(plans: [..._state.plans, plan]),
    );
  }

  Future<bool> createSubscription({
    required String studentId,
    required String studentName,
    required String planId,
    required String startDate,
    required double amount,
    bool autoRenew = true,
  }) async {
    if (!_initialized) await loadState();
    _validateAmount(amount);
    _validateDate(startDate);
    final plan = _state.plans
        .where(
          (p) =>
              p.id == planId &&
              p.active &&
              p.status == 'active' &&
              p.type == 'subscription',
        )
        .firstOrNull;
    if (plan == null || studentId.isEmpty || studentName.trim().isEmpty) {
      throw ArgumentError('Selecione aluno e plano recorrente ativo.');
    }
    if (_state.subscriptions.any(
      (sub) =>
          sub.studentId == studentId &&
          (sub.status == 'active' || sub.status == 'paused'),
    )) {
      throw StateError('O aluno já possui uma assinatura vigente.');
    }
    final sub = SubscriptionItem(
      id: Formatters.generateUuidV4(),
      studentId: studentId,
      studentName: studentName,
      planId: plan.id,
      planName: plan.name,
      status: 'active',
      contractedValue: amount,
      startDate: startDate,
      cycle: plan.interval,
      autoRenew: autoRenew,
    );
    return _commit('create_subscription', {
      'id': sub.id,
      'studentId': studentId,
      'planId': planId,
      'amount': amount,
      'startDate': startDate,
      'cycle': plan.interval,
      'autoRenew': autoRenew,
    }, _withRecords(subscriptions: [..._state.subscriptions, sub]));
  }

  Future<bool> createInvoice({
    required String studentId,
    required String studentName,
    required String planId,
    required String dueDate,
    required double amount,
  }) async {
    if (!_initialized) await loadState();
    _validateAmount(amount);
    _validateDate(dueDate);
    final plan = _state.plans
        .where((p) => p.id == planId && p.active && p.status == 'active')
        .firstOrNull;
    if (plan == null || studentId.isEmpty || studentName.trim().isEmpty) {
      throw ArgumentError('Selecione aluno e plano ativos.');
    }
    final invoice = InvoiceItem(
      id: Formatters.generateUuidV4(),
      studentId: studentId,
      studentName: studentName,
      planId: plan.id,
      planName: plan.name,
      type: plan.type,
      originalAmount: amount,
      finalAmount: amount,
      dueDate: dueDate,
      status:
          dueDate.compareTo(DateTime.now().toIso8601String().split('T').first) <
              0
          ? 'overdue'
          : 'pending',
    );
    return _commit('create_invoice', {
      'id': invoice.id,
      'studentId': studentId,
      'planId': planId,
      'amount': amount,
      'dueDate': dueDate,
    }, _withRecords(invoices: [..._state.invoices, invoice]));
  }

  Future<bool> _commit(
    String action,
    Map<String, dynamic> payload,
    FinanceState localState,
  ) async {
    if (!_isRemote()) return saveState(localState);
    try {
      final response = await _remoteCall(
        action: action,
        state: {'finance': _state.toJson()},
        payload: payload,
      );
      if (response['success'] != true || response['error'] != null) {
        throw const FormatException('Operação recusada ou resposta inválida.');
      }
      final remoteState = await _fetchRemoteState();
      _lastSyncError = null;
      _usingCachedData = false;
      _lastSyncedAt = DateTime.now();
      if (!await _cacheState(remoteState)) {
        throw const FormatException(
          'Não foi possível salvar o resultado neste dispositivo.',
        );
      }
      notifyListeners();
      return true;
    } catch (error) {
      _lastSyncError = 'A última alteração não foi sincronizada.';
      notifyListeners();
      throw FinanceDataException(
        'Operação financeira não concluída. Nenhuma confirmação local foi gravada.',
        error,
      );
    }
  }

  /// Baixa / Confirma pagamento de fatura
  Future<bool> confirmPayment({
    required String invoiceId,
    String paymentMethod = 'pix',
    String? paymentDate,
    double discount = 0.0,
    double fine = 0.0,
    double interest = 0.0,
  }) async {
    if (!_initialized) await loadState();

    final invIndex = _state.invoices.indexWhere((i) => i.id == invoiceId);
    if (invIndex < 0) return false;

    final inv = _state.invoices[invIndex];
    if (inv.status == 'paid') return true;
    if (!['pending', 'overdue'].contains(inv.status)) return false;
    for (final value in [discount, fine, interest]) {
      _validateAmount(value);
    }

    final date = paymentDate ?? DateTime.now().toIso8601String().split('T')[0];
    _validateDate(date);
    final finalAmount = inv.originalAmount - discount + fine + interest;
    if (finalAmount < 0) {
      throw ArgumentError('O desconto não pode superar o valor da fatura.');
    }

    // 1. Atualiza Fatura
    final updatedInvoice = inv.copyWith(
      status: 'paid',
      discount: discount,
      fine: fine,
      interest: interest,
      finalAmount: finalAmount,
      updatedAt: DateTime.now().toIso8601String(),
    );

    final newInvoices = List<InvoiceItem>.from(_state.invoices);
    newInvoices[invIndex] = updatedInvoice;

    // 2. Registra Pagamento
    final payment = PaymentItem(
      id: Formatters.generateUuidV4(),
      invoiceId: invoiceId,
      studentId: inv.studentId,
      studentName: inv.studentName,
      amount: finalAmount,
      paymentDate: date,
      paymentMethod: paymentMethod,
      status: 'confirmed',
    );
    final newPayments = List<PaymentItem>.from(_state.payments)..add(payment);

    // 3. Registra Entrada no Livro Caixa
    final cashEntry = CashFlowItem(
      id: Formatters.generateUuidV4(),
      type: 'inflow',
      amount: finalAmount,
      date: date,
      category: 'Mensalidade',
      description:
          'Recebimento de ${inv.studentName} (${inv.planName}) via ${paymentMethod.toUpperCase()}',
      referenceInvoiceId: invoiceId,
    );
    final newCashFlow = List<CashFlowItem>.from(_state.cashFlow)
      ..add(cashEntry);

    // 4. Registra Auditoria
    final audit = {
      'id': Formatters.generateUuidV4(),
      'action': 'payment_confirmed',
      'invoiceId': invoiceId,
      'amount': finalAmount,
      'timestamp': DateTime.now().toIso8601String(),
    };
    final newAudit = List<Map<String, dynamic>>.from(_state.auditLog)
      ..add(audit);

    final newState = FinanceState(
      schemaVersion: _state.schemaVersion,
      plans: _state.plans,
      subscriptions: _state.subscriptions,
      invoices: newInvoices,
      payments: newPayments,
      cashFlow: newCashFlow,
      auditLog: newAudit,
    );

    return _commit('process_payment', {
      'invoiceId': invoiceId,
      'paymentDate': date,
      'paymentMethod': paymentMethod,
      'discount': discount,
      'fine': fine,
      'interest': interest,
    }, newState);
  }

  /// Estorna um pagamento
  Future<bool> refundPayment(String invoiceId) async {
    if (!_initialized) await loadState();

    final invIndex = _state.invoices.indexWhere((i) => i.id == invoiceId);
    if (invIndex < 0) return false;

    final inv = _state.invoices[invIndex];
    if (inv.status != 'paid') return false;

    final date = DateTime.now().toIso8601String().split('T')[0];

    // 1. Reverte fatura para pendente
    final updatedInvoice = inv.copyWith(
      status: 'pending',
      updatedAt: DateTime.now().toIso8601String(),
    );
    final newInvoices = List<InvoiceItem>.from(_state.invoices);
    newInvoices[invIndex] = updatedInvoice;

    // 2. Atualiza pagamentos associados para refunded
    final newPayments = _state.payments.map((p) {
      if (p.invoiceId == invoiceId) {
        return PaymentItem(
          id: p.id,
          invoiceId: p.invoiceId,
          studentId: p.studentId,
          studentName: p.studentName,
          amount: p.amount,
          paymentDate: p.paymentDate,
          paymentMethod: p.paymentMethod,
          status: 'refunded',
          notes: 'Estornado em $date',
        );
      }
      return p;
    }).toList();

    // 3. Adiciona saída correspondente no Livro Caixa
    final cashOut = CashFlowItem(
      id: Formatters.generateUuidV4(),
      type: 'outflow',
      amount: inv.finalAmount,
      date: date,
      category: 'Estorno',
      description:
          'Estorno de pagamento de ${inv.studentName} (Fatura: $invoiceId)',
      referenceInvoiceId: invoiceId,
    );
    final newCashFlow = List<CashFlowItem>.from(_state.cashFlow)..add(cashOut);

    final newState = FinanceState(
      schemaVersion: _state.schemaVersion,
      plans: _state.plans,
      subscriptions: _state.subscriptions,
      invoices: newInvoices,
      payments: newPayments,
      cashFlow: newCashFlow,
      auditLog: _state.auditLog,
    );

    return _commit('refund_payment', {'invoiceId': invoiceId}, newState);
  }

  /// Troca o plano vigente sem alterar cobranças já emitidas.
  Future<bool> changeSubscriptionPlan(
    String subscriptionId,
    String planId,
  ) async {
    if (!_initialized) await loadState();

    final subIndex = _state.subscriptions.indexWhere(
      (sub) => sub.id == subscriptionId,
    );
    if (subIndex < 0) return false;
    final sub = _state.subscriptions[subIndex];
    if (sub.status != 'active' && sub.status != 'paused') return false;

    final plan = _state.plans
        .where(
          (item) =>
              item.id == planId &&
              item.active &&
              item.status == 'active' &&
              item.type == 'subscription',
        )
        .firstOrNull;
    if (plan == null) {
      throw ArgumentError('Selecione um plano recorrente ativo.');
    }
    if (sub.planId == plan.id) return true;

    final newSubs = List<SubscriptionItem>.from(_state.subscriptions);
    newSubs[subIndex] = sub.copyWith(
      planId: plan.id,
      planName: plan.name,
      contractedValue: plan.price,
      discount: 0,
      readjustment: 0,
      cycle: plan.interval,
      updatedAt: DateTime.now().toIso8601String(),
    );
    return _commit('change_subscription_plan', {
      'subscriptionId': subscriptionId,
      'planId': planId,
    }, _withRecords(subscriptions: newSubs));
  }

  /// Cancela uma assinatura
  Future<bool> cancelSubscription(String subscriptionId) async {
    if (!_initialized) await loadState();

    final subIndex = _state.subscriptions.indexWhere(
      (s) => s.id == subscriptionId,
    );
    if (subIndex < 0) return false;

    final sub = _state.subscriptions[subIndex];
    final updatedSub = sub.copyWith(
      status: 'cancelled',
      autoRenew: false,
      updatedAt: DateTime.now().toIso8601String(),
    );

    final newSubs = List<SubscriptionItem>.from(_state.subscriptions);
    newSubs[subIndex] = updatedSub;

    final newState = FinanceState(
      schemaVersion: _state.schemaVersion,
      plans: _state.plans,
      subscriptions: newSubs,
      invoices: _state.invoices,
      payments: _state.payments,
      cashFlow: _state.cashFlow,
      auditLog: _state.auditLog,
    );

    return _commit('cancel_subscription', {
      'subscriptionId': subscriptionId,
    }, newState);
  }

  /// Gera representação CSV de faturas para exportação
  String exportInvoicesCsv() {
    final buffer = StringBuffer();
    buffer.writeln(
      'ID,Aluno,Plano,Tipo,Valor Original,Valor Final,Vencimento,Status',
    );
    for (final inv in _state.invoices) {
      buffer.writeln(
        '"${inv.id}","${inv.studentName}","${inv.planName}","${inv.type}",'
        '${inv.originalAmount.toStringAsFixed(2)},${inv.finalAmount.toStringAsFixed(2)},'
        '"${inv.dueDate}","${inv.status}"',
      );
    }
    return buffer.toString();
  }

  /// Gera representação JSON completa para exportação
  String exportJson() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(_state.toJson());
  }
}

typedef FinanceRemoteCall =
    Future<Map<String, dynamic>> Function({
      required String action,
      required Map<String, dynamic> state,
      required Map<String, dynamic> payload,
    });
