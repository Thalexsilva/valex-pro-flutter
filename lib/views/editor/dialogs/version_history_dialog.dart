import 'package:flutter/material.dart';
import '../../../models/workout_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

/// Histórico de Versões da Ficha.
///
/// [onRestore] deve clonar/salvar a versão escolhida e devolver `true`
/// quando a restauração foi persistida com sucesso (o diálogo então se
/// fecha) ou `false` em caso de falha (o diálogo permanece aberto). Toda
/// mutação da ficha ativa e o feedback ao usuário (snackbars) ficam a cargo
/// de quem chamou o diálogo, já que dependem do `BuildContext` da tela
/// principal, não do diálogo.
class VersionHistoryDialog extends StatefulWidget {
  final List<WorkoutSheet> history;
  final Future<bool> Function(WorkoutSheet version) onRestore;
  final VoidCallback onSaveSnapshotManual;

  const VersionHistoryDialog({
    super.key,
    required this.history,
    required this.onRestore,
    required this.onSaveSnapshotManual,
  });

  @override
  State<VersionHistoryDialog> createState() => _VersionHistoryDialogState();
}

class _VersionHistoryDialogState extends State<VersionHistoryDialog> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isLoading,
      child: AlertDialog(
        backgroundColor: AppColors.carbon2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Histórico de Versões da Ficha',
                style: AppTheme.headlineMd(color: AppColors.blueLight),
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
              )
            else
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.steel),
                onPressed: () => Navigator.pop(context),
              ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.history.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: Text(
                    'Nenhum snapshot de versão salvo para este aluno ainda.',
                    style: AppTheme.bodyMd(color: AppColors.steel),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.history.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (c, idx) {
                      final version = widget.history[idx];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.carbon3,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    version.currentVersionName,
                                    style: AppTheme.bodyLg(color: Colors.white),
                                  ),
                                  Text(
                                    '${version.days.length} dias de treino',
                                    style: AppTheme.bodyMd(
                                      color: AppColors.steelDim,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      setState(() => isLoading = true);
                                      final success = await widget.onRestore(
                                        version,
                                      );
                                      if (!context.mounted) return;
                                      setState(() => isLoading = false);
                                      if (success) {
                                        Navigator.pop(context);
                                      }
                                    },
                              child: const Text('Restaurar'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.bookmark_add_outlined, size: 18),
            label: const Text('Salvar Snapshot Manual'),
            onPressed: () {
              Navigator.pop(context);
              widget.onSaveSnapshotManual();
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
