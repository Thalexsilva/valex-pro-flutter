import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/main.dart';

void main() {
  testWidgets('VALEX App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ValexApp());
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(ValexApp), findsOneWidget);
  });
}
