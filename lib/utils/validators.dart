/// Validações de formulário compartilhadas pelas telas de autenticação e perfil.
class Validators {
  Validators._();

  static const int minNameLength = 3;
  static const int minPasswordLength = 8;

  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static bool isValidEmail(String value) => _email.hasMatch(value.trim());

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Informe seu e-mail.';
    if (!isValidEmail(text)) return 'Informe um e-mail válido.';
    return null;
  }

  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Informe seu nome.';
    if (text.length < minNameLength) {
      return 'O nome deve ter pelo menos $minNameLength caracteres.';
    }
    return null;
  }

  static String? phone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Informe seu telefone.';
    if (digits.length < 10 || digits.length > 13) {
      return 'Informe um telefone válido com DDD.';
    }
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Informe uma senha.';
    if (text.length < minPasswordLength) {
      return 'Use pelo menos $minPasswordLength caracteres.';
    }
    return null;
  }

  static String? passwordConfirmation(String? value, String password) {
    if ((value ?? '').isEmpty) return 'Confirme sua senha.';
    if (value != password) return 'As senhas precisam ser iguais.';
    return null;
  }
}
