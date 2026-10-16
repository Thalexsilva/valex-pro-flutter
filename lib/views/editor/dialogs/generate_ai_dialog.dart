import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

/// Gerador Inteligente de Treino por IA Biomecânica.
///
/// Coleta o resumo da anamnese/lesões/objetivos e devolve o texto via
/// [onGenerate] — a geração da ficha em si (via `AiWorkoutEngine`) e a
/// gravação ficam a cargo de quem abriu o diálogo.
class GenerateAiDialog extends StatefulWidget {
  final String initialText;
  final String studentName;
  final ValueChanged<String> onGenerate;

  const GenerateAiDialog({
    super.key,
    required this.initialText,
    required this.studentName,
    required this.onGenerate,
  });

  @override
  State<GenerateAiDialog> createState() => _GenerateAiDialogState();
}

class _GenerateAiDialogState extends State<GenerateAiDialog> {
  late final TextEditingController anamneseController;

  @override
  void initState() {
    super.initState();
    anamneseController = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    anamneseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.carbon2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🪄 ', style: TextStyle(fontSize: 22)),
                    Text(
                      'Gerador Inteligente de Treino (IA)',
                      style: AppTheme.headlineMd(color: AppColors.blueLight),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.steel),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
                'O algoritmo usa a anamnese, o nível de experiência e a frequência para sugerir uma ficha com exercícios e métodos da biblioteca. Revise a sugestão antes de aplicar ao aluno.',
              style: AppTheme.bodyMd(color: AppColors.steel),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.carbon3,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    'ALUNO: ',
                    style: AppTheme.labelCaps(color: AppColors.blueLight),
                  ),
                  Text(
                    widget.studentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: anamneseController,
              maxLines: 4,
              style: AppTheme.inputText(),
              decoration: const InputDecoration(
                labelText: 'Resumo da Anamnese / Lesões / Objetivos',
                hintText:
                    'Ex: Aluno intermediário, 4 dias por semana, desconforto leve no joelho...',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.bolt, size: 16),
                  label: const Text('⚡ Gerar Ficha Completa'),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onGenerate(anamneseController.text);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
