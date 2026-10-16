import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/student_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/student_invite.dart';
import '../../utils/whatsapp_link.dart';

class AnamneseLinkGeneratorDialog extends StatefulWidget {
  final Student student;

  const AnamneseLinkGeneratorDialog({super.key, required this.student});

  @override
  State<AnamneseLinkGeneratorDialog> createState() =>
      _AnamneseLinkGeneratorDialogState();
}

class _AnamneseLinkGeneratorDialogState
    extends State<AnamneseLinkGeneratorDialog> {
  late final String _generatedUrl;
  late final String _whatsappMessage;

  @override
  void initState() {
    super.initState();
    _generatedUrl = StudentInvite.portalUrl;
    _whatsappMessage = StudentInvite.firstAssessment(widget.student);
  }

  Future<void> _openWhatsApp() async {
    final opened = await WhatsAppLink.open(
      phone: widget.student.phone,
      message: _whatsappMessage,
    );
    if (!mounted) return;
    if (opened) {
      Navigator.pop(context);
      return;
    }
    _copyToClipboard(
      _whatsappMessage,
      'Não foi possível abrir o WhatsApp. A mensagem foi copiada.',
    );
  }

  void _copyToClipboard(String text, String successMsg) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.emerald,
        content: Text(successMsg),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.carbon,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.vibrantBlue,
                  child: Icon(Icons.link, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Convite para a Avaliação 360°',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Envio para ${widget.student.name}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Link URL Box
            const Text(
              'Portal do aluno',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.carbon2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _generatedUrl,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.vibrantBlue,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: 'Copiar Link',
                    onPressed: () => _copyToClipboard(
                      _generatedUrl,
                      '🔗 Link copiado para a área de transferência!',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // WhatsApp Message Preview Box
            const Text(
              'Mensagem Pronta para WhatsApp',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.carbon2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                _whatsappMessage,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar Texto'),
                    onPressed: () => _copyToClipboard(
                      _whatsappMessage,
                      '📋 Mensagem completa copiada para o WhatsApp!',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                    ),
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text(
                      'Abrir WhatsApp',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _openWhatsApp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
