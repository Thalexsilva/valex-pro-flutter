import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Diálogo "Salvar como Preset Personalizado".
///
/// [onSave] deve persistir o preset e devolver `true` em caso de sucesso (o
/// diálogo então se fecha) ou `false` em caso de falha (permanece aberto com
/// o texto preenchido, para nova tentativa). O feedback ao usuário
/// (snackbars) fica a cargo de quem chamou o diálogo.
class SavePresetDialog extends StatefulWidget {
  final String initialTitle;
  final Future<bool> Function(String title) onSave;

  const SavePresetDialog({
    super.key,
    required this.initialTitle,
    required this.onSave,
  });

  @override
  State<SavePresetDialog> createState() => _SavePresetDialogState();
}

class _SavePresetDialogState extends State<SavePresetDialog> {
  late final TextEditingController controller;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isLoading,
      child: AlertDialog(
        backgroundColor: AppColors.carbon2,
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'Salvar como Preset Personalizado',
                style: TextStyle(color: Colors.white),
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.gold,
                ),
              ),
          ],
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Título do Preset'),
        ),
        actions: [
          TextButton(
            onPressed: isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: isLoading
                ? null
                : () async {
                    final title = controller.text.trim();
                    if (title.isNotEmpty) {
                      setState(() => isLoading = true);
                      final ok = await widget.onSave(title);
                      if (!context.mounted) return;
                      setState(() => isLoading = false);
                      if (ok) {
                        Navigator.pop(context);
                      }
                    }
                  },
            child: const Text('Salvar Preset'),
          ),
        ],
      ),
    );
  }
}
