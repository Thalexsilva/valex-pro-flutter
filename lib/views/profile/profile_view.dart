import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';
import '../../controllers/user_profile_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';

/// Perfil do usuário autenticado (RF005): nome editável, e-mail somente leitura.
class ProfileView extends StatefulWidget {
  const ProfileView({super.key, this.controller});

  final UserProfileController? controller;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final UserProfileController _profile =
      widget.controller ?? UserProfileController();
  late final _name = TextEditingController(text: _profile.name);
  late final _email = TextEditingController(text: _profile.email);

  @override
  void initState() {
    super.initState();
    _profile.addListener(_syncFromController);
  }

  @override
  void dispose() {
    _profile.removeListener(_syncFromController);
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  /// Mantém o formulário alinhado ao estado global enquanto não há edição.
  void _syncFromController() {
    if (_email.text != _profile.email) _email.text = _profile.email;
    if (!_hasChanges && _name.text != _profile.name) {
      _name.text = _profile.name;
    }
  }

  bool get _hasChanges => _name.text.trim() != _profile.name.trim();

  void _cancel() {
    FocusScope.of(context).unfocus();
    setState(() => _name.text = _profile.name);
    _formKey.currentState?.validate();
  }

  Future<void> _save() async {
    if (_profile.isSaving) return;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (!_formKey.currentState!.validate()) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Verifique o nome informado.')),
      );
      return;
    }
    if (!SupabaseConfig.hasAuthenticatedUser) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sessão expirada. Faça login novamente.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    try {
      await _profile.updateName(_name.text);
      if (!mounted) return;
      setState(() => _name.text = _profile.name);
      messenger.showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso.')),
      );
    } on AuthException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Não foi possível salvar: ${error.message}')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível salvar. Verifique sua internet e tente novamente.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.carbon,
      body: ListenableBuilder(
        listenable: Listenable.merge([_profile, _name]),
        builder: (context, _) {
          final saving = _profile.isSaving;
          final initial = _profile.displayName.characters.first.toUpperCase();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Card(
                    color: AppColors.carbon2,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: CircleAvatar(
                                radius: 36,
                                backgroundColor: AppColors.blue,
                                child: Text(
                                  initial,
                                  style: AppTheme.headlineMd(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _profile.name.isEmpty
                                  ? 'Meu perfil'
                                  : _profile.name,
                              textAlign: TextAlign.center,
                              style: AppTheme.headlineSm(),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              key: const ValueKey('profile_name'),
                              controller: _name,
                              enabled: !saving,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Nome',
                                prefixIcon: Icon(Icons.person_outline),
                                helperText:
                                    'Mínimo de ${Validators.minNameLength} caracteres.',
                              ),
                              validator: Validators.name,
                              onFieldSubmitted: (_) => _save(),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              key: const ValueKey('profile_email'),
                              controller: _email,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'E-mail (login)',
                                helperText:
                                    'O e-mail de login não pode ser alterado.',
                                prefixIcon: const Icon(
                                  Icons.mail_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  tooltip: 'Copiar e-mail',
                                  icon: const Icon(Icons.copy_outlined),
                                  onPressed: _email.text.isEmpty
                                      ? null
                                      : () async {
                                          await Clipboard.setData(
                                            ClipboardData(text: _email.text),
                                          );
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                            ..hideCurrentSnackBar()
                                            ..showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'E-mail copiado.',
                                                ),
                                              ),
                                            );
                                        },
                                ),
                              ),
                            ),
                            if (_profile.phone.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.phone_outlined,
                                  color: AppColors.steel,
                                ),
                                title: const Text(
                                  'Telefone',
                                  style: TextStyle(color: AppColors.steel),
                                ),
                                subtitle: Text(
                                  _profile.phone,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: saving || !_hasChanges
                                        ? null
                                        : _cancel,
                                    icon: const Icon(Icons.close),
                                    label: const Text('Cancelar'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: saving ? null : _save,
                                    icon: saving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.save_outlined),
                                    label: const Text('Salvar'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
