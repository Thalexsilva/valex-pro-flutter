import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:valex_app/config/supabase_config.dart';
import 'package:valex_app/main.dart';
import 'package:valex_app/views/auth/login_view.dart';
import 'package:valex_app/views/auth/password_recovery_view.dart';

void main() {
  final requests = <http.Request>[];
  var failRequest = false;
  final user = {
    'id': 'recovery-user',
    'aud': 'authenticated',
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
    'created_at': '2026-01-01T00:00:00Z',
  };

  setUp(() async {
    requests.clear();
    failRequest = false;
    SupabaseConfig.openedFromAuthCallback = false;
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-key',
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
        autoRefreshToken: false,
        localStorage: EmptyLocalStorage(),
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) async {
        requests.add(request);
        if (failRequest) {
          return http.Response(
            '{"code":"over_email_send_rate_limit","message":"Rate limit"}',
            429,
          );
        }
        if (request.url.path.endsWith('/user')) {
          return http.Response(jsonEncode(user), 200);
        }
        return http.Response('{}', 200);
      }),
    );
  });

  tearDown(() async {
    SupabaseConfig.openedFromAuthCallback = false;
    await Supabase.instance.dispose();
  });

  Future<void>
  recoverySession() => SupabaseConfig.client.auth.getSessionFromUrl(
    Uri.parse(
      'https://valexapp.vercel.app/#access_token=test-token&refresh_token=test-refresh&expires_in=3600&token_type=bearer&type=recovery',
    ),
  );

  test('callback detection distinguishes recovery from ordinary login', () {
    expect(
      SupabaseConfig.isRecoveryCallback(
        Uri.parse('https://valexapp.vercel.app/#type=recovery&access_token=x'),
      ),
      isTrue,
    );
    expect(
      SupabaseConfig.isRecoveryCallback(
        Uri.parse(
          'https://valexapp.vercel.app/#error=access_denied&error_code=otp_expired',
        ),
      ),
      isTrue,
    );
    expect(
      SupabaseConfig.isRecoveryCallback(
        Uri.parse('https://valexapp.vercel.app/#type=signup'),
      ),
      isFalse,
    );
    expect(
      SupabaseConfig.isRecoveryCallback(
        Uri.parse('https://valexapp.vercel.app/'),
      ),
      isFalse,
    );
  });

  testWidgets(
    'recovery validates email and submits public redirect without device verifier',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PasswordRecoveryView()));
      await tester.tap(find.text('Enviar link de recuperação'));
      await tester.pump();
      expect(find.text('Informe seu e-mail.'), findsOneWidget);
      expect(requests, isEmpty);
      await tester.enterText(find.byType(TextFormField), 'invalido@');
      await tester.tap(find.text('Enviar link de recuperação'));
      await tester.pump();
      expect(find.text('Informe um e-mail válido.'), findsOneWidget);
      expect(requests, isEmpty);
      await tester.enterText(
        find.byType(TextFormField),
        ' tester@example.com ',
      );
      await tester.tap(find.text('Enviar link de recuperação'));
      await tester.pumpAndSettle();
      final request = requests.single;
      expect(request.url.path, '/auth/v1/recover');
      expect(
        request.url.queryParameters['redirect_to'],
        SupabaseConfig.passwordRecoveryRedirect,
      );
      expect(jsonDecode(request.body)['email'], 'tester@example.com');
      expect(jsonDecode(request.body)['code_challenge'], isNull);
      expect(find.textContaining('Se houver uma conta'), findsOneWidget);
    },
  );

  testWidgets('rate limit allows retry without claiming email was sent', (
    tester,
  ) async {
    failRequest = true;
    await tester.pumpWidget(
      const MaterialApp(
        home: PasswordRecoveryView(initialEmail: 'tester@example.com'),
      ),
    );
    await tester.tap(find.text('Enviar link de recuperação'));
    await tester.pumpAndSettle();
    expect(
      find.text('Aguarde alguns minutos antes de tentar novamente.'),
      findsOneWidget,
    );
    expect(find.textContaining('Se houver uma conta'), findsNothing);
    failRequest = false;
    await tester.tap(find.text('Enviar link de recuperação'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Se houver uma conta'), findsOneWidget);
  });

  testWidgets('expired callback cannot submit a new password', (tester) async {
    SupabaseConfig.openedFromAuthCallback = true;
    await tester.pumpWidget(const ValexApp());
    await tester.pumpAndSettle();
    expect(find.textContaining('Link inválido ou expirado'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    await tester.tap(find.text('Voltar ao login'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.byType(LoginView), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'cold-start callback validates password and updates authenticated user',
    (tester) async {
      await recoverySession();
      SupabaseConfig.openedFromAuthCallback = true;
      await tester.pumpWidget(const ValexApp());
      await tester.pumpAndSettle();
      expect(find.byType(PasswordRecoveryView), findsOneWidget);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'short');
      await tester.enterText(fields.at(1), 'different');
      await tester.tap(find.text('Salvar nova senha'));
      await tester.pumpAndSettle();
      expect(find.text('Use pelo menos 8 caracteres.'), findsOneWidget);
      expect(find.text('As senhas precisam ser iguais.'), findsOneWidget);
      expect(requests.where((r) => r.method == 'PUT'), isEmpty);
      await tester.enterText(fields.at(0), ' Strong-password-42! ');
      await tester.enterText(fields.at(1), ' Strong-password-42! ');
      await tester.tap(find.text('Salvar nova senha'));
      await tester.pumpAndSettle();
      final update = requests.singleWhere((r) => r.method == 'PUT');
      expect(update.url.path, '/auth/v1/user');
      expect(jsonDecode(update.body)['password'], ' Strong-password-42! ');
      expect(find.textContaining('Senha atualizada.'), findsOneWidget);
      await tester.tap(find.text('Voltar ao login'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(SupabaseConfig.client.auth.currentSession, isNull);
      expect(find.byType(LoginView), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('recovery event interrupts the login page', (tester) async {
    await tester.pumpWidget(const ValexApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await recoverySession();
    await tester.pumpAndSettle();
    expect(find.text('Salvar nova senha'), findsOneWidget);
    expect(find.byType(LoginView), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
