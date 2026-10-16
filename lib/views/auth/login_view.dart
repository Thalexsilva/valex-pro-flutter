import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_motion.dart';
import '../../widgets/carbon_card.dart';
import '../../utils/validators.dart';
import 'password_recovery_view.dart';
import 'sign_up_view.dart';

/// LoginView — 100% fiel ao design Stitch Carbon Pro Premium (Screen: `Login - VALEX Pro`).
class LoginView extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback? onStudentLoginSuccess;

  const LoginView({
    super.key,
    required this.onLoginSuccess,
    this.onStudentLoginSuccess,
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  // A maioria dos acessos é de alunos; o instrutor troca para "Instrutor".
  bool _studentAccess = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Validações locais antes de qualquer acesso ao servidor (RF001).
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Por favor, preencha e-mail e senha.');
      return;
    }
    if (!Validators.isValidEmail(email)) {
      setState(() => _errorMessage = 'Informe um e-mail em formato válido.');
      return;
    }
    if (!SupabaseConfig.isInitialized) {
      setState(
        () => _errorMessage =
            'Não foi possível iniciar a conexão. Reinicie o aplicativo ou entre em contato com o suporte.',
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;
      if (response.session != null) {
        if (_studentAccess && widget.onStudentLoginSuccess != null) {
          widget.onStudentLoginSuccess!();
        } else {
          widget.onLoginSuccess();
        }
      } else {
        setState(() {
          _errorMessage =
              'Confirme seu email pelo link enviado e depois faça login.';
        });
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = switch (e.code) {
          'invalid_credentials' =>
            'E-mail ou senha incorretos. Confira os dados e tente novamente.',
          'email_not_confirmed' =>
            'Confirme seu e-mail pelo link enviado antes de entrar.',
          'over_request_rate_limit' || 'over_email_send_rate_limit' =>
            'Muitas tentativas. Aguarde alguns minutos e tente novamente.',
          _
              when e.message.toLowerCase().contains(
                'invalid login credentials',
              ) =>
            'E-mail ou senha incorretos. Confira os dados e tente novamente.',
          _ =>
            'Não foi possível entrar. Verifique seus dados e tente novamente.',
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = SupabaseConfig.isConfigured
            ? 'Não foi possível conectar ao VALEX. Verifique sua internet e tente novamente.'
            : 'Este aplicativo ainda não foi configurado. Entre em contato com o suporte.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openSignUp() async {
    setState(() => _errorMessage = null);
    final signedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SignUpView(
          initialEmail: _emailController.text.trim(),
          studentAccount: _studentAccess,
        ),
      ),
    );
    if (!mounted || signedIn != true) return;
    if (_studentAccess && widget.onStudentLoginSuccess != null) {
      widget.onStudentLoginSuccess!();
    } else {
      widget.onLoginSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Ambient Background Radial Gradient ────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.2,
                colors: [Color(0xFF1B202A), Color(0xFF101319)],
              ),
            ),
          ),

          // ── Atmospheric Glow Elements ─────────────────────────────────────
          // Gradiente radial (não um círculo sólido) para não deixar uma
          // borda dura visível sobre o cabelo da personagem atrás dele.
          if (size.width >= 800)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.vibrantBlue.withValues(alpha: 0.12),
                      AppColors.vibrantBlue.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

          // A arte complementa o formulário apenas quando há espaço lateral.
          if (size.width >= 800)
            Positioned(
              right: 32,
              bottom: 0,
              width: size.width * 0.38,
              height: size.height * 0.75,
              child: Opacity(
                opacity: 0.62,
                child: ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black],
                    stops: [0.0, 0.4],
                  ).createShader(rect),
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    'assets/images/character.png',
                    excludeFromSemantics: true,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),

          // ── Form Content ──────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo Section
                    Image.asset(
                      'assets/images/logo.png',
                      semanticLabel: 'VALEX Pro',
                      height: 68,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 32),

                    // Glass Panel Container
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: CarbonCard(
                        solid: false,
                        premiumBorder: true,
                        padding: EdgeInsets.all(size.width < 400 ? 20 : 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'ACESSO DA CONTA',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : AppMotion.standard,
                              child: Text(
                                _studentAccess
                                    ? 'Acesse sua avaliação e seus treinos.'
                                    : 'Insira suas credenciais para acessar o painel',
                                key: ValueKey(_studentAccess),
                                style: AppTheme.bodyMd(),
                              ),
                            ),
                            const SizedBox(height: 24),

                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: false,
                                  label: Text('Instrutor'),
                                  icon: Icon(Icons.person_outline),
                                ),
                                ButtonSegment(
                                  value: true,
                                  label: Text('Aluno'),
                                  icon: Icon(Icons.fitness_center),
                                ),
                              ],
                              selected: {_studentAccess},
                              onSelectionChanged: _isLoading
                                  ? null
                                  : (value) => setState(() {
                                      _studentAccess = value.first;
                                      _errorMessage = null;
                                    }),
                            ),
                            const SizedBox(height: 20),

                            if (_errorMessage != null) ...[
                              Semantics(
                                liveRegion: true,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.crimson.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.crimson.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    style: AppTheme.bodyMd(
                                      color: AppColors.crimsonText,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Treinador Mode Form
                            // Email Field
                            ExcludeSemantics(
                              child: Text(
                                'E-MAIL',
                                style: AppTheme.bodySm(
                                  color: AppColors.steelLight,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Semantics(
                              label: 'E-mail',
                              child: TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.username],
                                autocorrect: false,
                                enableSuggestions: false,
                                style: AppTheme.inputText(),
                                decoration: InputDecoration(
                                  hintText: 'seu@email.com',
                                  prefixIcon: const Icon(
                                    Icons.mail_outline_rounded,
                                    color: AppColors.vibrantBlue,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.surfaceContainerLowest,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                ExcludeSemantics(
                                  child: Text(
                                    'SENHA',
                                    style: AppTheme.bodySm(
                                      color: AppColors.steelLight,
                                    ).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Semantics(
                              label: 'Senha',
                              child: TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                autocorrect: false,
                                enableSuggestions: false,
                                onSubmitted: (_) => _submit(),
                                style: AppTheme.inputText(),
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: AppColors.vibrantBlue,
                                  ),
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePassword
                                        ? 'Mostrar senha'
                                        : 'Ocultar senha',
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppColors.onSurfaceVariant,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.surfaceContainerLowest,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Submit Button
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                PasswordRecoveryView(
                                                  initialEmail: _emailController
                                                      .text
                                                      .trim(),
                                                ),
                                          ),
                                        );
                                      },
                                child: const Text('Esqueceu a senha?'),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blueAction,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'ENTRAR',
                                          style:
                                              AppTheme.bodyMd(
                                                color: Colors.white,
                                              ).copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                            ),
                            const SizedBox(height: 12),

                            if (_studentAccess)
                              const Text(
                                'O instrutor pode consultar seus acessos ao app, incluindo IP, plataforma e região aproximada estimada por um serviço de geolocalização de IP.',
                                style: TextStyle(
                                  color: AppColors.steelDim,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),

                            const SizedBox(height: 20),
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    'Ainda não tem uma conta?',
                                    style: AppTheme.bodyMd(),
                                  ),
                                  TextButton(
                                    key: const ValueKey('login_open_signup'),
                                    onPressed: _isLoading ? null : _openSignUp,
                                    child: const Text('Criar conta'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
