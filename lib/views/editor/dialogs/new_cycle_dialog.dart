import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

/// Diálogo "Iniciar Novo Ciclo de Treino".
///
/// Apenas coleta a identificação do novo ciclo; salvar o snapshot anterior,
/// atualizar a ficha ativa e o autosave ficam a cargo de [onConfirm].
class NewCycleDialog extends StatefulWidget {
  final String initialCycleName;
  final ValueChanged<String> onConfirm;

  const NewCycleDialog({
    super.key,
    required this.initialCycleName,
    required this.onConfirm,
  });

  @override
  State<NewCycleDialog> createState() => _NewCycleDialogState();
}

class _NewCycleDialogState extends State<NewCycleDialog> {
  late final TextEditingController cycleController;

  @override
  void initState() {
    super.initState();
    cycleController = TextEditingController(text: widget.initialCycleName);
  }

  @override
  void dispose() {
    cycleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.carbon2,
      title: Row(
        children: [
          const Text('📅 ', style: TextStyle(fontSize: 22)),
          Text(
            'Iniciar Novo Ciclo de Treino',
            style: AppTheme.headlineMd(color: Colors.white),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Esta ação salvará um snapshot da ficha atual no histórico de versões e atualizará o ciclo de treino do aluno.',
            style: AppTheme.bodyMd(color: AppColors.steel),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: cycleController,
            style: AppTheme.inputText(),
            decoration: const InputDecoration(
              labelText: 'Identificação do Novo Ciclo',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final newName = cycleController.text.trim();
            if (newName.isNotEmpty) {
              Navigator.pop(context);
              widget.onConfirm(newName);
            }
          },
          child: const Text('Confirmar Novo Ciclo'),
        ),
      ],
    );
  }
}
