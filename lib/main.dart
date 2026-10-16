import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'controllers/user_profile_controller.dart';
import 'models/student_model.dart';
import 'repositories/student_repository.dart';

import 'services/student_context_service.dart';
import 'services/idle_session_service.dart';
import 'services/student_access_tracker.dart';
import 'theme/app_theme.dart';
import 'views/auth/login_view.dart';
import 'views/auth/password_recovery_view.dart';
import 'views/main_navigation_view.dart';
import 'views/splash/splash_view.dart';
import 'views/students/student_portal_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  await StudentContextService().init();
  const enableDevicePreview = bool.fromEnvironment('DEVICE_PREVIEW');
  runApp(
    DevicePreview(
      enabled: !kReleaseMode && enableDevicePreview,
      builder: (context) => const ValexApp(),
    ),
  );
}

class ValexApp extends StatefulWidget {
  const ValexApp({super.key});

  @override
  State<ValexApp> createState() => _ValexAppState();
}

class _ValexAppState extends State<ValexApp> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final IdleSessionService _idleSession;
  bool _showSplash = true;
  bool _isAuthenticated = false;
  bool _resolvingAccount = false;
  String? _accountError;
  Student? _studentAccount;
  bool _studentRequested = false;

  /// O login abre em "Aluno". Uma conta que não é de aluno pode seguir para
  /// o painel do instrutor sem precisar sair e entrar de novo.
  bool _offerInstructorAccess = false;
  bool _isPasswordRecovery = SupabaseConfig.openedFromAuthCallback;

  StreamSubscription<dynamic>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _idleSession = IdleSessionService(onExpired: _onLogout);
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
    try {
      _authSubscription = SupabaseConfig.client.auth.onAuthStateChange.listen(
        (event) {
          if (!mounted) return;
          if (event.event == AuthChangeEvent.signedOut) {
            _clearSession();
          } else if (event.event == AuthChangeEvent.passwordRecovery) {
            _idleSession.stop();
            _navigatorKey.currentState?.popUntil((route) => route.isFirst);
            setState(() {
              _isPasswordRecovery = true;
              _isAuthenticated = false;
              _showSplash = false;
            });
          }
        },
        onError: (Object error) {
          if (!mounted) return;
          // Invalid/expired links must not become unhandled stream errors.
          if (SupabaseConfig.openedFromAuthCallback || _isPasswordRecovery) {
            setState(() => _isPasswordRecovery = true);
          }
        },
      );
    } catch (_) {
      // Configuration errors keep the app on the login screen.
    }
  }

  @override
  void dispose() {
    _idleSession.stop();
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    _authSubscription?.cancel();
    super.dispose();
  }

  bool _onKeyEvent(KeyEvent event) {
    _idleSession.recordActivity();
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _idleSession.checkExpired();
    }
  }

  void _onSplashComplete() {
    setState(() {
      _showSplash = false;
    });
  }

  Future<void> _onLoginSuccess({bool studentRequested = false}) async {
    if (!SupabaseConfig.hasAuthenticatedUser) return;
    _studentRequested = studentRequested;
    final userId = SupabaseConfig.client.auth.currentUser!.id;
    setState(() {
      _resolvingAccount = true;
      _accountError = null;
    });
    try {
      final student = await StudentRepository().fetchStudentForCurrentAccount();
      if (!mounted || SupabaseConfig.client.auth.currentUser?.id != userId) {
        return;
      }
      _studentAccount = student;
      if (student != null) {
        // Analytics must never delay or block the student's login.
        unawaited(StudentAccessTracker().recordLogin().catchError((_) {}));
      }
      final isStudentAccount =
          SupabaseConfig
              .client
              .auth
              .currentUser
              ?.userMetadata?['account_type'] ==
          'student';
      if (student == null && (studentRequested || isStudentAccount)) {
        setState(() {
          _resolvingAccount = false;
          _offerInstructorAccess = !isStudentAccount;
          _accountError = isStudentAccount
              ? 'Seu e-mail ainda não está vinculado a um aluno ativo. Peça ao instrutor para cadastrá-lo com este mesmo e-mail.'
              : 'Este e-mail não está vinculado a um aluno ativo. Se você é '
                    'instrutor, entre no painel do instrutor. Se é aluno, peça '
                    'ao instrutor para cadastrá-lo com este mesmo e-mail.';
        });
        return;
      }
    } catch (_) {
      if (!mounted || SupabaseConfig.client.auth.currentUser?.id != userId) {
        return;
      }
      setState(() {
        _resolvingAccount = false;
        _accountError =
            'Não foi possível verificar o acesso desta conta. Tente novamente.';
      });
      return;
    }
    _idleSession.start();
    if (_studentAccount == null) UserProfileController().loadFromAuth();
    setState(() {
      _isAuthenticated = true;
      _resolvingAccount = false;
    });
  }

  void _openInstructorPanel() {
    if (!SupabaseConfig.hasAuthenticatedUser) return;
    _idleSession.start();
    UserProfileController().loadFromAuth();
    setState(() {
      _studentAccount = null;
      _studentRequested = false;
      _offerInstructorAccess = false;
      _accountError = null;
      _isAuthenticated = true;
    });
  }

  void _onLogout() async {
    _clearSession();
    try {
      await SupabaseConfig.client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {}
  }

  void _clearSession() {
    SupabaseConfig.openedFromAuthCallback = false;
    _idleSession.stop();
    StudentContextService().clearSessionMemory();
    UserProfileController().clear();
    if (!mounted) return;
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    setState(() {
      _isAuthenticated = false;
      _studentAccount = null;
      _studentRequested = false;
      _offerInstructorAccess = false;
      _resolvingAccount = false;
      _accountError = null;
      _isPasswordRecovery = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget homeWidget;
    if (_isPasswordRecovery) {
      homeWidget = PasswordRecoveryView(
        updatePassword: true,
        onFinished: () {
          _showSplash = false;
          _onLogout();
        },
      );
    } else if (_showSplash) {
      homeWidget = SplashView(onComplete: _onSplashComplete);
    } else if (_resolvingAccount) {
      homeWidget = const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (_accountError != null) {
      homeWidget = Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    liveRegion: true,
                    child: Text(_accountError!, textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 16),
                  if (_offerInstructorAccess) ...[
                    FilledButton.icon(
                      onPressed: _openInstructorPanel,
                      icon: const Icon(Icons.person_outline),
                      label: const Text('Entrar como instrutor'),
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextButton(
                    onPressed: () =>
                        _onLoginSuccess(studentRequested: _studentRequested),
                    child: const Text('Tentar novamente'),
                  ),
                  TextButton(onPressed: _onLogout, child: const Text('Sair')),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (_isAuthenticated) {
      homeWidget = _studentAccount == null
          ? MainNavigationView(onLogout: _onLogout)
          : StudentPortalView(student: _studentAccount!, onLogout: _onLogout);
    } else {
      homeWidget = LoginView(
        onLoginSuccess: _onLoginSuccess,
        onStudentLoginSuccess: () => _onLoginSuccess(studentRequested: true),
      );
    }

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'VALEX Pro',
      locale: DevicePreview.locale(context),
      builder: (context, child) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _idleSession.recordActivity(),
        onPointerMove: (_) => _idleSession.recordActivity(),
        onPointerHover: (_) => _idleSession.recordActivity(),
        onPointerSignal: (_) => _idleSession.recordActivity(),
        child: DevicePreview.appBuilder(context, child),
      ),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: homeWidget,
    );
  }
}
