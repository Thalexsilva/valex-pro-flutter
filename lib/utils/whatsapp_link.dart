import 'package:url_launcher/url_launcher.dart';

/// Abre uma conversa do WhatsApp com a mensagem preenchida.
class WhatsAppLink {
  WhatsAppLink._();

  /// Número no formato internacional exigido pelo wa.me. Telefones
  /// brasileiros com DDD (10 ou 11 dígitos) recebem o código 55.
  static String? normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10 || digits.length == 11) return '55$digits';
    if (digits.length >= 12 && digits.length <= 13) return digits;
    return null;
  }

  static Uri uri({required String phone, required String message}) {
    final number = normalizePhone(phone);
    return Uri.https('wa.me', number == null ? '/' : '/$number', {
      'text': message,
    });
  }

  static Future<bool> open({
    required String phone,
    required String message,
  }) async {
    try {
      return await launchUrl(
        uri(phone: phone, message: message),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}
