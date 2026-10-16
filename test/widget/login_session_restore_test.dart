import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valex_app/config/supabase_config.dart';
import 'package:valex_app/main.dart';
import 'package:valex_app/views/auth/login_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('opening the app ignores a previously saved session', (
    tester,
  ) async {
    final project = Uri.parse(SupabaseConfig.url).host.split('.').first;
    SharedPreferences.setMockInitialValues({
      'sb-$project-auth-token': jsonEncode({
        'access_token': 'cached-token',
        'refresh_token': 'cached-refresh-token',
        'token_type': 'bearer',
        'expires_at': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
        'user': {
          'id': 'saved-user',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'aud': 'authenticated',
          'created_at': '2026-01-01T00:00:00Z',
        },
      }),
    });
    await tester.runAsync(() => SupabaseConfig.initialize());
    if (SupabaseConfig.isInitialized) {
      addTearDown(() => tester.runAsync(() => Supabase.instance.dispose()));
      expect(SupabaseConfig.client.auth.currentSession, isNull);
    }
    await tester.pumpWidget(const ValexApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.byType(LoginView), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
