import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/views/auth/login_view.dart';

void main() {
  testWidgets('login has no demo or student identifier bypass', (tester) async {
    var entered = false;
    await tester.pumpWidget(
      MaterialApp(home: LoginView(onLoginSuccess: () => entered = true)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Demo'), findsNothing);
    expect(find.textContaining('Offline'), findsNothing);
    expect(find.textContaining('Área do Aluno'), findsNothing);
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.enterText(find.byType(TextField).first, 'unknown@example.com');
    await tester.enterText(find.byType(TextField).last, 'test-password');
    await tester.ensureVisible(find.text('ENTRAR'));
    await tester.tap(find.text('ENTRAR'));
    await tester.pump();
    expect(entered, false);
    expect(
      find.textContaining('Não foi possível iniciar a conexão'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
