import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/student_model.dart';
import '../../repositories/anamnese_repository.dart';
import '../../services/student_context_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/student_invite.dart';
import 'anamnese_form_wizard_view.dart';

/// RequestReassessmentDialog — Permite ao instrutor solicitar uma nova avaliação 360° ou refazê-la presencialmente a qualquer momento.
class RequestReassessmentDialog extends StatefulWidget {
  final Student student;
  final VoidCallback? onReassessmentTriggered;

  const RequestReassessmentDialog({
    super.key,
    required this.student,
    this.onReassessmentTriggered,
  });

  @override
  State<RequestReassessmentDialog> createState() =>
      _RequestReassessmentDialogState();
}

class _RequestReassessmentDialogState extends State<RequestReassessmentDialog> {
  final _reasonController = TextEditingController(
    text: 'Reavaliação periódica de periodização e bioimpedância',
  );
  bool _isLoading = false;

  void _startInPersonAssessment() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnamneseFormWizardView(
          student: widget.student,
          onCompleted: () {
            StudentContextService().completeStudentAnamnese(widget.student.id);
            if (widget.onReassessmentTriggered != null) {
              widget.onReassessmentTriggered!();
            }
          },
        ),
      ),
    );
  }

  Future<void> _requestRemoteAssessment() async {
    setState(() => _isLoading = true);
    final reason = _reasonController.text.trim();

    final requested = await AnamneseRepository().requestReassessment(
      widget.student.id,
      reason: reason,
    );
    if (!mounted) return;
    if (!requested) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível registrar a reavaliação. Verifique a conexão e '
              'tente novamente.',
            ),
          ),
        );
      return;
    }

    widget.onReassessmentTriggered?.call();
    var copied = true;
    try {
      await Clipboard.setData(
        ClipboardData(text: StudentInvite.reassessment(widget.student)),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {
      copied = false;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    final messenger = ScaffoldMessenger.of(context);
    if (Navigator.canPop(context)) Navigator.pop(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.emerald,
        content: Text(
          copied
              ? 'Reavaliação 360° solicitada. Mensagem para o aluno copiada.'
              : 'Reavaliação 360° solicitada. O aluno verá o pedido ao entrar.',
          style: const TextStyle(color: AppColors.carbon1),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;

    return Dialog(
      backgroundColor: AppColors.carbon2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.sync_rounded,
                      color: AppColors.blueLight,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Refazer Fluxo 360°',
                          style: AppTheme.headlineMd(color: Colors.white),
                        ),
                        Text(
                          'Aluno(a): ${student.name}',
                          style: AppTheme.bodyMd(color: AppColors.steel),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.steel),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Info Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.carbon3,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'O instrutor pode solicitar ou refazer a Anamnese 360° a qualquer momento para atualizar dores articulares, novas metas, biometria e laudos de bioimpedância.',
                      style: AppTheme.bodyMd(color: Colors.white),
                    ),
                    if (student.lastAnamneseDate != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Última avaliação: ${student.lastAnamneseDate}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.steel,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Reason input
              TextField(
                controller: _reasonController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Motivo da Reavaliação (Opcional)',
                  hintText:
                      'Ex: Troca de ciclo, dor no ombro, nova bioimpedância',
                ),
              ),
              const SizedBox(height: 24),

              // Action Options
              Text(
                'ESCOLHA COMO PROCEDER:',
                style: AppTheme.labelCaps(color: AppColors.blueLight),
              ),
              const SizedBox(height: 12),

              // Option 1: In Person
              InkWell(
                key: const Key('btn_start_in_person_assessment'),
                onTap: _isLoading ? null : _startInPersonAssessment,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.carbon,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.blue.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.blue,
                        child: Icon(
                          Icons.person_pin_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Iniciar Avaliação Presencial Agora',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Preencher as respostas e fotos diretamente na tela com o aluno.',
                              style: AppTheme.bodyMd(color: AppColors.steel),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.steel,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Option 2: Remote / Next Login
              InkWell(
                key: const Key('btn_request_remote_assessment'),
                onTap: _isLoading ? null : _requestRemoteAssessment,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.carbon,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.emerald,
                        child: Icon(
                          Icons.send_to_mobile_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Solicitar no Próximo Acesso / WhatsApp',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Exigir no próximo login do aluno e copiar a mensagem com o endereço do portal.',
                              style: AppTheme.bodyMd(color: AppColors.steel),
                            ),
                          ],
                        ),
                      ),
                      if (_isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.steel,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
