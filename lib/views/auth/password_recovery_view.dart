import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';
import '../../utils/validators.dart';
import '../../widgets/carbon_card.dart';

class PasswordRecoveryView extends StatefulWidget {
  const PasswordRecoveryView({
    super.key,
    this.initialEmail = '',
    this.updatePassword = false,
    this.onFinished,
  });

  final String initialEmail;
  final bool updatePassword;
  final VoidCallback? onFinished;

  @override
  State<PasswordRecoveryView> createState() => _PasswordRecoveryViewState();
}

class _PasswordRecoveryViewState extends State<PasswordRecoveryView> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  bool _complete = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.updatePassword) {
        if (!SupabaseConfig.hasAuthenticatedUser) {
          throw const AuthException(
            'Link inválido ou expirado. Solicite um novo link.',
          );
        }
        await SupabaseConfig.client.auth.updateUser(
          UserAttributes(password: _password.text),
        );
        _password.clear();
        _confirmation.clear();
      } else {
        await SupabaseConfig.client.auth.resetPasswordForEmail(
          _email.text.trim(),
          redirectTo: SupabaseConfig.passwordRecoveryRedirect,
        );
      }
      if (mounted) setState(() => _complete = true);
    } on AuthException catch (error) {
      if (mounted) {
        setState(
          () => _error = switch (error.statusCode == '429'
              ? 'over_request_rate_limit'
              : error.code) {
            'over_email_send_rate_limit' || 'over_request_rate_limit' =>
              'Aguarde alguns minutos antes de tentar novamente.',
            'same_password' => 'Escolha uma senha diferente da anterior.',
            'weak_password' =>
              'Escolha uma senha mais forte, com letras, números e símbolos.',
            'otp_expired' || 'session_not_found' || 'refresh_token_not_found' =>
              'Link inválido ou expirado. Solicite um novo link.',
            _ =>
              'Não foi possível concluir. Verifique os dados e tente novamente.',
          },
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Não foi possível conectar. Verifique sua internet e tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _back() {
    if (widget.onFinished != null) {
      widget.onFinished!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final invalidLink =
        widget.updatePassword && !SupabaseConfig.hasAuthenticatedUser;
    return PopScope(
      canPop: !_busy && !widget.updatePassword,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            widget.updatePassword ? 'Nova senha' : 'Esqueceu a senha?',
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: CarbonCard(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_complete)
                          Text(
                            widget.updatePassword
                                ? 'Senha atualizada. Volte ao login e entre com sua nova senha.'
                                : 'Se houver uma conta com este e-mail, você receberá um link para criar uma nova senha. Confira também a caixa de spam.',
                          )
                        else if (invalidLink)
                          const Text(
                            'Link inválido ou expirado. Volte ao login e solicite um novo link em “Esqueceu a senha?”.',
                          )
                        else ...[
                          Text(
                            widget.updatePassword
                                ? 'Crie uma nova senha com pelo menos 8 caracteres.'
                                : 'Informe o e-mail da sua conta para receber o link de recuperação.',
                          ),
                          const SizedBox(height: 24),
                          if (!widget.updatePassword)
                            TextFormField(
                              controller: _email,
                              enabled: !_busy,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.email],
                              autocorrect: false,
                              decoration: const InputDecoration(
                                labelText: 'E-mail cadastrado',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                              ),
                              validator: Validators.email,
                              onFieldSubmitted: (_) => _submit(),
                            )
                          else ...[
                            TextFormField(
                              controller: _password,
                              enabled: !_busy,
                              obscureText: _obscure,
                              autocorrect: false,
                              enableSuggestions: false,
                              autofillHints: const [AutofillHints.newPassword],
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Nova senha',
                                suffixIcon: IconButton(
                                  tooltip: _obscure
                                      ? 'Mostrar senha'
                                      : 'Ocultar senha',
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                ),
                              ),
                              validator: (value) => (value?.length ?? 0) < 8
                                  ? 'Use pelo menos 8 caracteres.'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmation,
                              enabled: !_busy,
                              obscureText: _obscure,
                              autocorrect: false,
                              enableSuggestions: false,
                              autofillHints: const [AutofillHints.newPassword],
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Confirmar nova senha',
                              ),
                              validator: (value) => value != _password.text
                                  ? 'As senhas precisam ser iguais.'
                                  : null,
                              onFieldSubmitted: (_) => _submit(),
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    widget.updatePassword
                                        ? 'Salvar nova senha'
                                        : 'Enviar link de recuperação',
                                  ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _busy ? null : _back,
                          child: const Text('Voltar ao login'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
