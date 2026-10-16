import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

/// Confirmação de "Resetar Ficha de Treino" para o padrão em branco.
class ResetSheetDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const ResetSheetDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.carbon2,
      title: Text(
        'Resetar Ficha de Treino',
        style: AppTheme.headlineMd(color: AppColors.crimson),
      ),
      content: Text(
        'Deseja realmente resetar esta ficha para o padrão em branco? Todas as alterações não salvas serão perdidas.',
        style: AppTheme.bodyMd(color: AppColors.steel),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: const Text('Resetar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
