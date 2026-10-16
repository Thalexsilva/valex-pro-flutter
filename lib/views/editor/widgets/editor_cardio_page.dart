import 'package:flutter/material.dart';
import '../../../models/workout_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

/// Página final (Cardio & Observações) da ficha virtual — equivalente a
/// `.page.day-page#page-cardio` no modelo legado (`js/pdf.js#renderCardioPage`).
class EditorCardioPage extends StatelessWidget {
  final WorkoutSheet sheet;
  final int pageNo;
  final int totalPages;
  final void Function(VoidCallback mutation) mutate;
  final VoidCallback markDirty;
  final VoidCallback onBackToIndex;

  const EditorCardioPage({
    super.key,
    required this.sheet,
    required this.pageNo,
    required this.totalPages,
    required this.mutate,
    required this.markDirty,
    required this.onBackToIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.paperCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.carbon,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/logo.png', height: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'FICHA DE TREINO',
                        style: AppTheme.labelCaps(color: AppColors.blueLight),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🫀 ', style: TextStyle(fontSize: 16)),
                    Flexible(
                      child: Text(
                        'Protocolo de Cardio',
                        style: AppTheme.labelCaps(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text(
                      'OPÇÕES AERÓBICAS',
                      style: AppTheme.labelCaps(color: AppColors.paperBlue),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('➕ Adicionar Protocolo'),
                      onPressed: () {
                        mutate(() {
                          sheet.cardioOptions.add(
                            'Opção ${sheet.cardioOptions.length + 1}: Esteira 20 min HIIT',
                          );
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.paperBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                ...sheet.cardioOptions.asMap().entries.map((e) {
                  final idx = e.key;
                  final opt = e.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        const Text('🏃', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: opt,
                            style: AppTheme.bodyLg(color: AppColors.ink),
                            decoration: const InputDecoration(
                              filled: false,
                              isDense: true,
                              border: InputBorder.none,
                            ),
                            onChanged: (v) {
                              sheet.cardioOptions[idx] = v;
                              markDirty();
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: AppColors.crimson,
                          ),
                          onPressed: () {
                            mutate(() {
                              sheet.cardioOptions.removeAt(idx);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 24),

                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text(
                      'OBSERVAÇÕES GERAIS',
                      style: AppTheme.labelCaps(color: AppColors.paperGold),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('➕ Adicionar Obs'),
                      onPressed: () {
                        mutate(() {
                          sheet.generalNotes.add(
                            'Nova observação técnica para o aluno...',
                          );
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                ...sheet.generalNotes.asMap().entries.map((e) {
                  final idx = e.key;
                  final obs = e.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: AppColors.paperGreen,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: obs,
                            style: AppTheme.bodyMd(color: AppColors.ink),
                            decoration: const InputDecoration(
                              filled: false,
                              isDense: true,
                              border: InputBorder.none,
                            ),
                            onChanged: (v) {
                              sheet.generalNotes[idx] = v;
                              markDirty();
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 14,
                            color: AppColors.crimson,
                          ),
                          onPressed: () {
                            mutate(() {
                              sheet.generalNotes.removeAt(idx);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  'VALEX · Biomechanics & Rehabilitation',
                  style: AppTheme.labelCaps(color: AppColors.paperMuted),
                ),
                InkWell(
                  onTap: onBackToIndex,
                  child: Text(
                    'Voltar ao índice',
                    style: AppTheme.bodyMd(color: AppColors.paperBlue),
                  ),
                ),
                Text(
                  'Página $pageNo de $totalPages',
                  style: AppTheme.bodyMd(color: AppColors.paperMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
