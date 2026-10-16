import '../config/supabase_config.dart';

class FinanceApiService {
  /// Executa todas as mutações financeiras estritamente via Supabase Edge Function 'finance'
  static Future<Map<String, dynamic>> invokeEdgeFunction({
    required String action,
    required Map<String, dynamic> state,
    required Map<String, dynamic> payload,
  }) async {
    if (!SupabaseConfig.isConfigured || !SupabaseConfig.hasAuthenticatedUser) {
      throw const FinanceApiException(
        'Entre na sua conta para sincronizar o financeiro.',
      );
    }
    final res = await SupabaseConfig.client.functions.invoke(
      'finance',
      body: {'action': action, 'state': state, 'payload': payload},
    );
    if (res.status != 200) {
      throw FinanceApiException(
        'A operacao financeira remota falhou (${res.status}).',
        response: res.data,
      );
    }
    final data = res.data;
    if (data is! Map) {
      throw FinanceApiException('A API financeira retornou dados invalidos.');
    }
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> processPayment({
    required Map<String, dynamic> state,
    required String invoiceId,
    required String paymentDate,
    required String paymentMethod,
    double? desconto,
    double? multa,
    double? juros,
  }) async {
    return invokeEdgeFunction(
      action: 'process_payment',
      state: state,
      payload: {
        'invoiceId': invoiceId,
        'opts': {
          'paymentDate': paymentDate,
          'paymentMethod': paymentMethod,
          'desconto': desconto,
          'multa': multa,
          'juros': juros,
        },
      },
    );
  }

  static Future<Map<String, dynamic>> refundPayment({
    required Map<String, dynamic> state,
    required String invoiceId,
  }) async {
    return invokeEdgeFunction(
      action: 'refund_payment',
      state: state,
      payload: {'invoiceId': invoiceId},
    );
  }

  static Future<Map<String, dynamic>> cancelSubscription({
    required Map<String, dynamic> state,
    required String subscriptionId,
  }) async {
    return invokeEdgeFunction(
      action: 'cancel_subscription',
      state: state,
      payload: {'subscriptionId': subscriptionId},
    );
  }

  static Future<Map<String, dynamic>> generateInvoices({
    required Map<String, dynamic> state,
    String? dueDate,
  }) async {
    return invokeEdgeFunction(
      action: 'generate_subscription_invoices',
      state: state,
      payload: {'dueDate': dueDate},
    );
  }
}

class FinanceApiException implements Exception {
  final String message;
  final Object? response;

  const FinanceApiException(this.message, {this.response});

  @override
  String toString() => message;
}
