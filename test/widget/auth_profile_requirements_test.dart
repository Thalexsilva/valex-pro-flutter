import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:valex_app/config/app_info.dart';
import 'package:valex_app/controllers/user_profile_controller.dart';
import 'package:valex_app/utils/validators.dart';
import 'package:valex_app/views/about/about_view.dart';
import 'package:valex_app/views/auth/login_view.dart';
import 'package:valex_app/views/auth/password_recovery_view.dart';
import 'package:valex_app/views/auth/sign_up_view.dart';
import 'package:valex_app/views/profile/profile_view.dart';

Map<String, dynamic> _user({String name = 'Maria Souza'}) => {
  'id': 'user-1',
  'aud': 'authenticated',
  'email': 'maria@example.com',
  'app_metadata': <String, dynamic>{},
  'user_metadata': {'name': name, 'phone': '(41) 99999-0000'},
  'created_at': '2026-01-01T00:00:00Z',
};

Map<String, dynamic> _session(Map<String, dynamic> user) => {
  'access_token': 'token',
  'refresh_token': 'refresh',
  'expires_in': 3600,
  'token_type': 'bearer',
  'user': user,
};

void main() {
  final requests = <http.Request>[];

  setUp(() async {
    requests.clear();
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
        final path = request.url.path;
        if (path.endsWith('/signup')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final data = body['data'] as Map<String, dynamic>;
          return http.Response(
            jsonEncode(_session(_user(name: data['name'] as String))),
            200,
          );
        }
        if (path.endsWith('/token')) {
          return http.Response(jsonEncode(_session(_user())), 200);
        }
        if (path.endsWith('/user') && request.method == 'PUT') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final data = body['data'] as Map<String, dynamic>;
          return http.Response(
            jsonEncode(_user(name: data['name'] as String)),
            200,
          );
        }
        return http.Response('{}', 200);
      }),
    );
  });

  tearDown(() async {
    UserProfileController().clear();
    await Supabase.instance.dispose();
  });

  test('validators cover required, format, size and confirmation', () {
    expect(Validators.email(''), 'Informe seu e-mail.');
    expect(Validators.email('a@b'), 'Informe um e-mail válido.');
    expect(Validators.email(' a@b.com '), isNull);
    expect(Validators.name('Jo'), contains('pelo menos 3'));
    expect(Validators.name('  '), 'Informe seu nome.');
    expect(Validators.phone('123'), contains('telefone válido'));
    expect(Validators.phone('(41) 99999-0000'), isNull);
    expect(Validators.passwordConfirmation('abc', 'abd'), contains('iguais'));
  });

  testWidgets('login validates email format before calling the API', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(home: LoginView(onLoginSuccess: () {})),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Esqueceu a senha?'), findsOneWidget);
    expect(find.text('ENTRAR'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);

    await tester.tap(find.text('ENTRAR'));
    await tester.pump();
    expect(find.text('Por favor, preencha e-mail e senha.'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'email-invalido');
    await tester.enterText(fields.at(1), 'senha123');
    await tester.tap(find.text('ENTRAR'));
    await tester.pump();
    expect(find.text('Informe um e-mail em formato válido.'), findsOneWidget);
    expect(requests, isEmpty);

    await tester.tap(find.text('Esqueceu a senha?'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(PasswordRecoveryView), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('sign up validates fields and returns to app when session', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var loggedIn = false;
    await tester.pumpWidget(
      MaterialApp(home: LoginView(onLoginSuccess: () => loggedIn = true)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    // O login abre em "Aluno"; este fluxo é o cadastro do instrutor.
    await tester.tap(find.text('Instrutor'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('login_open_signup')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SignUpView), findsOneWidget);

    await tester.tap(find.text('Cadastrar'));
    await tester.pump();
    expect(find.text('Informe seu nome.'), findsOneWidget);
    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(find.text('Informe seu telefone.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('signup_name')),
      'Maria Souza',
    );
    await tester.enterText(
      find.byKey(const ValueKey('signup_email')),
      'maria@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('signup_phone')),
      '(41) 99999-0000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('signup_password')),
      'Senha-forte-1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('signup_confirmation')),
      'Senha-diferente',
    );
    await tester.tap(find.text('Cadastrar'));
    await tester.pump();
    expect(find.text('As senhas precisam ser iguais.'), findsOneWidget);
    expect(requests, isEmpty);

    await tester.enterText(
      find.byKey(const ValueKey('signup_confirmation')),
      'Senha-forte-1',
    );
    await tester.tap(find.text('Cadastrar'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    final signup = requests.singleWhere((r) => r.url.path.endsWith('/signup'));
    final body = jsonDecode(signup.body) as Map<String, dynamic>;
    expect(body['email'], 'maria@example.com');
    expect(body['data'], {'name': 'Maria Souza', 'phone': '(41) 99999-0000'});
    expect(loggedIn, isTrue);
    expect(find.byType(SignUpView), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('profile validates name, keeps email read-only and saves', (
    tester,
  ) async {
    await Supabase.instance.client.auth.signInWithPassword(
      email: 'maria@example.com',
      password: 'Senha-forte-1',
    );
    final profile = UserProfileController()..loadFromAuth();
    expect(profile.displayName, 'Maria');

    await tester.pumpWidget(const MaterialApp(home: ProfileView()));
    await tester.pumpAndSettle();
    final email = tester.widget<TextFormField>(
      find.byKey(const ValueKey('profile_email')),
    );
    expect(email.enabled, isTrue);
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const ValueKey('profile_email')),
              matching: find.byType(TextField),
            ),
          )
          .readOnly,
      isTrue,
    );
    expect(find.text('maria@example.com'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('profile_name')), 'Al');
    await tester.tap(find.text('Salvar'));
    await tester.pump();
    expect(find.textContaining('pelo menos 3'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    expect(find.widgetWithText(TextFormField, 'Maria Souza'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('profile_name')),
      'Ana Paula',
    );
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    final update = requests.singleWhere((r) => r.method == 'PUT');
    expect(jsonDecode(update.body)['data'], {'name': 'Ana Paula'});
    expect(find.text('Perfil atualizado com sucesso.'), findsOneWidget);
    expect(profile.name, 'Ana Paula');
    expect(profile.displayName, 'Ana');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('about shows objective and team', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutView()));
    await tester.pumpAndSettle();
    expect(find.text('Objetivo'), findsOneWidget);
    expect(find.text(AppInfo.objective), findsOneWidget);
    expect(find.text('Equipe de desenvolvimento'), findsOneWidget);
    for (final member in AppInfo.team) {
      expect(find.text(member), findsOneWidget);
    }
  });
}
