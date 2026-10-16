import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Estado global do usuário autenticado (nome, e-mail, telefone).
///
/// Os dados vêm do `user_metadata` do Supabase Auth. Telas que identificam o
/// usuário escutam este controller para refletir alterações feitas no Perfil.
class UserProfileController extends ChangeNotifier {
  UserProfileController._();
  static final UserProfileController _instance = UserProfileController._();
  factory UserProfileController() => _instance;

  String _name = '';
  String _email = '';
  String _phone = '';
  bool _saving = false;

  String get name => _name;
  String get email => _email;
  String get phone => _phone;
  bool get isSaving => _saving;

  /// Primeiro nome para saudações; "Treinador" quando não informado.
  String get displayName {
    final first = _name.trim().split(RegExp(r'\s+')).first;
    return first.isEmpty ? 'Treinador' : first;
  }

  /// Carrega os dados do usuário da sessão atual.
  void loadFromAuth() {
    User? user;
    try {
      user = SupabaseConfig.client.auth.currentUser;
    } catch (_) {
      user = null;
    }
    if (user == null) {
      clear();
      return;
    }
    applyUser(user);
  }

  @visibleForTesting
  void applyUser(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    _name = (metadata['name'] ?? metadata['full_name'] ?? '').toString();
    _phone = (metadata['phone'] ?? user.phone ?? '').toString();
    _email = user.email ?? '';
    notifyListeners();
  }

  /// Atualiza o nome no Supabase Auth e notifica as telas dependentes.
  Future<void> updateName(String newName) async {
    final trimmed = newName.trim();
    _saving = true;
    notifyListeners();
    try {
      final response = await SupabaseConfig.client.auth.updateUser(
        UserAttributes(data: {'name': trimmed}),
      );
      final user = response.user;
      if (user != null) {
        applyUser(user);
      } else {
        _name = trimmed;
      }
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  void clear() {
    _name = '';
    _email = '';
    _phone = '';
    _saving = false;
    notifyListeners();
  }
}
