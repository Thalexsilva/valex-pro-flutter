import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/models/sales_model.dart';
import 'package:valex_app/theme/app_theme.dart';
import 'package:valex_app/views/sales/lead_form_dialog.dart';

void main() {
  testWidgets('lead exige WhatsApp utilizável antes de cadastrar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    LeadItem? saved;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) =>
                    LeadFormDialog(onSave: (lead, _) => saved = lead),
              ),
              child: const Text('Abrir cadastro'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir cadastro'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Maria');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.ensureVisible(find.text('CADASTRAR LEAD'));
    await tester.tap(find.text('CADASTRAR LEAD'));
    await tester.pump();

    expect(saved, isNull);
    expect(
      find.text('Número inválido. Use DDD + número, ex.: (11) 99999-9999'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextFormField).at(1), '(11) 99999-9999');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('CADASTRAR LEAD'));
    await tester.tap(find.text('CADASTRAR LEAD'));
    await tester.pumpAndSettle();

    expect(saved?.phone, '(11) 99999-9999');
    expect(find.byType(LeadFormDialog), findsNothing);
  });
}
