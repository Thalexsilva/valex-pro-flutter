import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

/// Prontuário privado do aluno (.instructor-notes-container) — não sai na
/// impressão do PDF.
class EditorInstructorNotesBox extends StatelessWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const EditorInstructorNotesBox({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paperCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.blue, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 18,
                    color: AppColors.paperBlue,
                  ),
                  Text(
                    'Prontuário Privado do Aluno',
                    style: AppTheme.labelCaps(color: AppColors.paperBlue),
                  ),
                ],
              ),
              Text(
                'Área do personal • Não sai na impressão',
                style: AppTheme.bodyMd(color: AppColors.paperMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: initialValue,
            style: AppTheme.bodyMd(color: AppColors.ink),
            minLines: 4,
            maxLines: 7,
            decoration: const InputDecoration(
              hintText:
                  'Anotações biomecânicas, histórico de lesões e evolução confidencial...',
              hintStyle: TextStyle(color: AppColors.paperMuted),
              filled: true,
              fillColor: AppColors.paper,
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
