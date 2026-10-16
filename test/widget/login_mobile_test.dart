import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:valex_app/views/auth/login_view.dart';

void main() {
  testWidgets(
    'mobile keyboard submits the exact password and stays on auth error',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      Map<String, dynamic>? credentials;
      await tester.runAsync(
        () => Supabase.initialize(
          url: 'https://example.supabase.co',
          publishableKey: 'test-key',
          debug: false,
          authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient((request) async {
            credentials = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              '{"message":"Invalid login credentials"}',
              400,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      );
      addTearDown(() => tester.runAsync(() => Supabase.instance.dispose()));
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var loggedIn = false;
      await tester.pumpWidget(
        MaterialApp(home: LoginView(onLoginSuccess: () => loggedIn = true)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), ' mobile@example.com ');
      await tester.enterText(fields.at(1), ' password with spaces ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(credentials?['email'], 'mobile@example.com');
      expect(credentials?['password'], ' password with spaces ');
      expect(loggedIn, isFalse);
      expect(
        find.text(
          'E-mail ou senha incorretos. Confira os dados e tente novamente.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
