import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/views/splash/splash_view.dart';

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    testWidgets('splash fits ${size.width}x${size.height} and completes once', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var completions = 0;
      await tester.pumpWidget(
        MaterialApp(home: SplashView(onComplete: () => completions++)),
      );

      expect(find.text('PREPARANDO SEU TREINO'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(completions, 1);
      await tester.pump(const Duration(seconds: 3));
      expect(completions, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('splash respects reduced motion', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: SplashView(onComplete: () {})),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
