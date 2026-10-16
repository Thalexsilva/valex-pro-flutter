import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/services/finance_api_service.dart';

void main() {
  group('Auditoria & Testes das Chamadas a Edge Functions Supabase', () {
    test(
      'processPayment rejeita operacao remota sem sessao',
      () async {
        final result = FinanceApiService.processPayment(
          state: {'mrr': 720.0},
          invoiceId: 'inv_test_001',
          paymentDate: '2026-08-01',
          paymentMethod: 'pix',
        );

        await expectLater(result, throwsA(isA<FinanceApiException>()));
      },
    );

    test(
      'invokeEdgeFunction nao simula sucesso quando indisponivel',
      () async {
        final result = FinanceApiService.invokeEdgeFunction(
          action: 'get_financial_metrics',
          state: {},
          payload: {'period': 'current_month'},
        );

        await expectLater(result, throwsA(isA<FinanceApiException>()));
      },
    );
  });
}
