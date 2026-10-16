import '../support/student_fixtures.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valex_app/models/finance_models.dart';
import 'package:valex_app/repositories/finance_repository.dart';
import 'package:valex_app/services/student_context_service.dart';
import 'package:valex_app/theme/app_theme.dart';
import 'package:valex_app/views/dashboard/dashboard_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dashboard calcula indicadores a partir dos dados persistidos', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'valex_finance_state_v3_signed-out': jsonEncode({
        'schemaVersion': 3,
        'plans': <Object>[],
        'subscriptions': [
          {
            'id': 'sub-1',
            'studentId': 'st_1',
            'studentName': 'Carlos Silva',
            'planId': 'plan-1',
            'planName': 'Mensal',
            'status': 'active',
            'contractedValue': 275.0,
            'startDate': '2026-09-01',
            'autoRenew': true,
          },
        ],
        'invoices': [
          {
            'id': 'inv-paid',
            'studentId': 'st_1',
            'studentName': 'Carlos Silva',
            'planName': 'Mensal',
            'type': 'subscription',
            'originalAmount': 275.0,
            'finalAmount': 275.0,
            'dueDate': '2026-09-05',
            'status': 'paid',
          },
          {
            'id': 'inv-overdue',
            'studentId': 'st_2',
            'studentName': 'Mariana Costa',
            'planName': 'Mensal',
            'type': 'subscription',
            'originalAmount': 95.0,
            'finalAmount': 95.0,
            'dueDate': '2026-08-05',
            'status': 'overdue',
          },
        ],
        'payments': <Object>[],
        'cashFlow': [
          {
            'id': 'cash-in',
            'type': 'inflow',
            'amount': 275.0,
            'date': '2026-09-05',
            'category': 'Mensalidade',
            'description': 'Pagamento',
            'createdAt': '2026-09-05T10:00:00.000',
          },
          {
            'id': 'cash-out',
            'type': 'outflow',
            'amount': 40.0,
            'date': '2026-09-06',
            'category': 'Ferramentas',
            'description': 'Despesa',
            'createdAt': '2026-09-06T10:00:00.000',
          },
        ],
        'auditLog': <Object>[],
      }),
    });

    final repository = FinanceRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: DashboardView(
          studentContext: StudentContextService.forTesting(
            initialStudents: testStudents,
          ),
          financeRepository: repository,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('2'), findsOneWidget);
    expect(find.text('R\$ 275,00'), findsNWidgets(2));
    expect(find.text('R\$ 95,00'), findsOneWidget);
    expect(find.text('R\$ 235,00'), findsOneWidget);
    expect(find.text('R\$ 720,00'), findsNothing);
    await repository.saveState(FinanceState());
    await tester.pump();
    expect(find.text('R\$ 275,00'), findsNothing);
    expect(find.text('R\$ 0,00'), findsNWidgets(4));
  });
}
