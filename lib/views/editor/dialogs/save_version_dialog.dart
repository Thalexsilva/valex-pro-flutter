import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Diálogo "Salvar Snapshot de Versão".
///
/// [onSave] deve persistir o snapshot e devolver `true` em caso de sucesso
/// (o diálogo então se fecha) ou `false` em caso de falha (permanece aberto
/// com o texto preenchido, para nova tentativa). O feedback ao usuário
/// (snackbars) fica a cargo de quem chamou o diálogo.
class SaveVersionDialog extends StatefulWidget {
  final String initialName;
  final Future<bool> Function(String name) onSave;

  const SaveVersionDialog({
    super.key,
    required this.initialName,
    required this.onSave,
  });

  @override
  State<SaveVersionDialog> createState() => _SaveVersionDialogState();
}

class _SaveVersionDialogState extends State<SaveVersionDialog> {
  late final TextEditingController controller;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialName);
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
                'Salvar Snapshot de Versão',
                style: TextStyle(color: Colors.white),
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.blueLight,
                ),
              ),
          ],
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Identificação da Versão',
          ),
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
                    final name = controller.text.trim();
                    if (name.isNotEmpty) {
                      setState(() => isLoading = true);
                      final ok = await widget.onSave(name);
                      if (!context.mounted) return;
                      setState(() => isLoading = false);
                      if (ok) {
                        Navigator.pop(context);
                      }
                    }
                  },
            child: const Text('Salvar Snapshot'),
          ),
        ],
      ),
    );
  }
}
