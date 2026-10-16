import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UrlSanitizerFormatter extends TextInputFormatter {
  static final RegExp _maliciousRegex = RegExp(
    r'(javascript:|vbscript:|data:|<script|%)',
    caseSensitive: false,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Remove malicious patterns immediately
    if (_maliciousRegex.hasMatch(newValue.text)) {
      return oldValue;
    }

    // Allow typing only if it loosely matches a safe URL character set
    // This allows typing intermediate strings before they form a complete valid URL.
    if (!RegExp(r'^[\w\:\/\.\-=\?\&\%\+]*$').hasMatch(newValue.text)) {
      return oldValue;
    }

    return newValue;
  }
}

class Formatters {
  static String generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  static const _accented = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  static const _plain = 'aaaaaeeeeiiiiooooouuuucn';

  /// Texto para busca: minúsculo e sem acentos ("João" encontra "joao").
  static String normalizeSearch(String value) {
    final lower = value.toLowerCase().trim();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      final index = _accented.indexOf(char);
      buffer.write(index < 0 ? char : _plain[index]);
    }
    return buffer.toString();
  }

  static String digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

  static String formatBRL(double amount) {
    final str = amount.toStringAsFixed(2).replaceAll('.', ',');
    final parts = str.split(',');
    final whole = parts[0];
    final decimal = parts[1];

    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    final formattedWhole = whole.replaceAll(reg, '.');

    return 'R\$ $formattedWhole,$decimal';
  }

  static String formatDateBR(String isoDate) {
    if (isoDate.isEmpty) return '-';
    try {
      final clean = isoDate.split('T')[0];
      final parts = clean.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (_) {}
    return isoDate;
  }

  static String translateFinanceStatus(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'Rascunho';
      case 'pending':
        return 'Pendente';
      case 'overdue':
        return 'Atrasado';
      case 'paid':
        return 'Pago';
      case 'cancelled':
        return 'Cancelado';
      case 'active':
        return 'Ativo';
      case 'paused':
        return 'Pausado';
      case 'expired':
        return 'Expirado';
      case 'confirmed':
        return 'Confirmado';
      case 'refunded':
        return 'Estornado';
      default:
        return status;
    }
  }

  static String translatePaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'pix':
        return 'PIX';
      case 'cartao':
      case 'credit':
        return 'Cartão de Crédito';
      case 'debit':
        return 'Cartão de Débito';
      case 'dinheiro':
      case 'cash':
        return 'Dinheiro';
      case 'transfer':
        return 'Transferência Bancária';
      default:
        return method.toUpperCase();
    }
  }

  static Color getFinanceStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'active':
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.blueAccent;
      case 'overdue':
        return Colors.redAccent;
      case 'paused':
      case 'draft':
        return Colors.amber;
      case 'cancelled':
      case 'expired':
      case 'refunded':
        return Colors.grey;
      default:
        return Colors.white70;
    }
  }

  static String buildWhatsAppBillingMessage({
    required String studentName,
    required String planName,
    required double amount,
    required String dueDate,
    String? pixKey,
  }) {
    final valorStr = formatBRL(amount);
    final dataStr = formatDateBR(dueDate);
    final keyStr = pixKey != null && pixKey.isNotEmpty
        ? '\nChave PIX: $pixKey'
        : '';

    return Uri.encodeComponent(
      'Olá $studentName, tudo bem?\n\n'
      'Sua cobrança referente ao plano *$planName* no valor de *$valorStr* '
      'com vencimento em *$dataStr* já está disponível.$keyStr\n\n'
      'Qualquer dúvida estou à disposição!',
    );
  }

  // ── Helpers do Módulo de Vendas / CRM ──────────────────────────────────────

  static String translateLeadStatus(String status) {
    switch (status.toLowerCase()) {
      case 'new':
      case 'newlead':
        return 'Novo Lead';
      case 'anamnese_sent':
      case 'anamnesesent':
        return 'Anamnese Enviada';
      case 'proposal_sent':
      case 'proposalsent':
        return 'Proposta Enviada';
      case 'negotiating':
        return 'Em Negociação';
      case 'won':
        return 'Convertido (Aluno)';
      case 'lost':
        return 'Perdido';
      default:
        return status;
    }
  }

  static Color getLeadStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'won':
        return const Color(0xFF34D399); // emerald
      case 'proposal_sent':
      case 'negotiating':
        return const Color(0xFF6FC4FF); // blueLight
      case 'anamnese_sent':
      case 'new':
      case 'newlead':
        return const Color(0xFFFBBF24); // amber
      case 'lost':
        return const Color(0xFFEF4444); // crimson
      default:
        return Colors.white70;
    }
  }

  static String translateLeadPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'hot':
        return 'Quente 🔥';
      case 'warm':
        return 'Morno ⚡';
      case 'cold':
        return 'Frio ❄️';
      default:
        return priority;
    }
  }

  static Color getLeadPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'hot':
        return const Color(0xFFEF4444); // crimson
      case 'warm':
        return const Color(0xFFFBBF24); // amber
      case 'cold':
        return const Color(0xFFAAB4C0); // steel
      default:
        return Colors.white70;
    }
  }

  static String buildWhatsAppPitchMessage({
    required String leadName,
    String? trainerName,
    String? planName,
    double? value,
    String? pixKey,
  }) {
    final tName = trainerName ?? 'Seu Treinador';
    final pName = planName ?? 'Consultoria Personalizada';
    final vStr = value != null && value > 0
        ? '\nInvestimento: *${formatBRL(value)}*'
        : '';
    final pixStr = pixKey != null && pixKey.isNotEmpty
        ? '\nChave PIX: $pixKey'
        : '';

    return Uri.encodeComponent(
      'Fala $leadName, aqui é o $tName!\n\n'
      'Montei a proposta da sua consultoria exclusiva no sistema VALEX:\n'
      '• Protocolo: *$pName*$vStr$pixStr\n'
      '• Ficha interativa com vídeos e acompanhamento de cargas\n'
      '• Suporte e correções direto comigo no WhatsApp\n\n'
      'Podemos confirmar sua vaga e liberar o questionário de anamnese agora?',
    );
  }

  static String buildWhatsAppFollowUpMessage({
    required String leadName,
    int followUpStage = 1,
    String? trainerName,
  }) {
    final tName = trainerName ?? 'Seu Treinador';
    if (followUpStage == 1) {
      // 24h follow up
      return Uri.encodeComponent(
        'Oi $leadName, tudo bem? Aqui é o $tName.\n\n'
        'Ficou alguma dúvida sobre o formato do nosso acompanhamento ou a forma de pagamento?\n'
        'Estou por aqui para te ajudar!',
      );
    } else {
      // 48h urgency follow up
      return Uri.encodeComponent(
        'Fala $leadName! Estou fechando as vagas de consultoria desta semana para conseguir dar atenção total a cada ficha.\n\n'
        'Quer que eu reserve a sua vaga antes de liberar para o próximo da lista?',
      );
    }
  }

  static String buildWhatsAppScheduledReturnMessage({
    required String leadName,
    String? trainerName,
    String? note,
  }) {
    final tName = trainerName ?? 'Seu Treinador';
    final reasonStr = note != null && note.isNotEmpty
        ? ' (Referente a: $note)'
        : '';

    return Uri.encodeComponent(
      'Fala $leadName! Aqui é o $tName.\n\n'
      'Conforme combinamos, estou passando para dar continuidade no seu planejamento de treino$reasonStr!\n\n'
      'Como estão os planos para começarmos essa semana?',
    );
  }

  static String buildFollowUp24hMessage({
    required String leadName,
    String? trainerName,
  }) {
    return buildWhatsAppFollowUpMessage(
      leadName: leadName,
      followUpStage: 1,
      trainerName: trainerName,
    );
  }

  static String buildFollowUp48hMessage({
    required String leadName,
    String? trainerName,
  }) {
    return buildWhatsAppFollowUpMessage(
      leadName: leadName,
      followUpStage: 2,
      trainerName: trainerName,
    );
  }

  static String translateChannel(String channel) {
    switch (channel.toLowerCase()) {
      case 'meta_ads':
      case 'meta':
        return 'Meta Ads (Instagram/FB)';
      case 'indicacao':
        return 'Indicação de Aluno';
      case 'whatsapp':
        return 'WhatsApp Direto';
      case 'instagram_direct':
        return 'Instagram Direct';
      case 'google':
        return 'Google / YouTube';
      case 'tiktok':
        return 'TikTok';
      case 'link_bio':
        return 'Link da Bio';
      default:
        return channel.isNotEmpty ? channel : 'Não informado';
    }
  }

  static String formatFollowUpDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final now = DateTime.now();
      final isToday =
          dt.year == now.year && dt.month == now.month && dt.day == now.day;
      final isTomorrow =
          dt.year == now.year &&
          dt.month == now.month &&
          dt.day == (now.day + 1);

      final timeStr =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      if (isToday) {
        return 'Hoje às $timeStr';
      } else if (isTomorrow) {
        return 'Amanhã às $timeStr';
      } else {
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} às $timeStr';
      }
    } catch (_) {
      return isoDate;
    }
  }
}
