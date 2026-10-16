import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';
import '../../utils/validators.dart';
import '../../widgets/carbon_card.dart';

/// Cadastro de novo usuário (RF002).
///
/// Retorna `true` via [Navigator.pop] quando o cadastro já gera uma sessão
/// ativa, permitindo que o login siga direto para a tela principal.
class SignUpView extends StatefulWidget {
  const SignUpView({
    super.key,
    this.initialEmail = '',
    this.studentAccount = false,
  });

  final String initialEmail;
  final bool studentAccount;

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  bool _awaitingConfirmation = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) {
      setState(() => _error = 'Corrija os campos destacados para continuar.');
      return;
    }
    if (!SupabaseConfig.isInitialized) {
      setState(
        () => _error =
            'Não foi possível iniciar a conexão. Reinicie o aplicativo ou entre em contato com o suporte.',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final response = await SupabaseConfig.client.auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        data: {
          'name': _name.text.trim(),
          'phone': _phone.text.trim(),
          if (widget.studentAccount) 'account_type': 'student',
        },
      );
      if (!mounted) return;
      if (response.session != null) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _awaitingConfirmation = true);
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(
        () => _error = switch (error.code) {
          'user_already_exists' ||
          'email_exists' => 'Já existe uma conta com este e-mail.',
          'weak_password' =>
            'Escolha uma senha mais forte, com letras, números e símbolos.',
          'over_email_send_rate_limit' || 'over_request_rate_limit' =>
            'Aguarde alguns minutos antes de tentar novamente.',
          _ =>
            'Não foi possível criar sua conta. Confira os dados e tente novamente.',
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error =
            'Não foi possível conectar. Verifique sua internet e tente novamente.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
      );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Criar conta')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: CarbonCard(
                  padding: const EdgeInsets.all(24),
                  child: _awaitingConfirmation
                      ? _buildConfirmation()
                      : _buildForm(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmation() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Icon(Icons.mark_email_read_outlined, size: 48),
      const SizedBox(height: 16),
      Text(
        'Conta criada! Enviamos um link de confirmação para '
        '${_email.text.trim()}. Confirme o e-mail e depois faça login.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Voltar ao login'),
      ),
    ],
  );

  Widget _buildForm() => Form(
    key: _formKey,
    child: AutofillGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.studentAccount
                ? 'Use o mesmo e-mail cadastrado pelo seu instrutor.'
                : 'Preencha seus dados para acessar o VALEX Pro.',
          ),
          const SizedBox(height: 24),
          TextFormField(
            key: const ValueKey('signup_name'),
            controller: _name,
            enabled: !_busy,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            decoration: _decoration('Nome', Icons.person_outline),
            validator: Validators.name,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('signup_email'),
            controller: _email,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            decoration: _decoration('E-mail', Icons.mail_outline_rounded),
            validator: Validators.email,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('signup_phone'),
            controller: _phone,
            enabled: !_busy,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9()+\-\s]')),
            ],
            decoration: _decoration(
              'Telefone',
              Icons.phone_outlined,
            ).copyWith(hintText: '(16) 99999-9999'),
            validator: Validators.phone,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('signup_password'),
            controller: _password,
            enabled: !_busy,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            decoration: _decoration(
              'Senha',
              Icons.lock_outline_rounded,
              suffix: IconButton(
                tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: Validators.password,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('signup_confirmation'),
            controller: _confirmation,
            enabled: !_busy,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            decoration: _decoration(
              'Confirmar senha',
              Icons.lock_reset_outlined,
            ),
            validator: (value) =>
                Validators.passwordConfirmation(value, _password.text),
            onFieldSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _busy ? null : _submit,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Cadastrar'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
            child: const Text('Já tenho conta. Fazer login'),
          ),
        ],
      ),
    ),
  );
}
