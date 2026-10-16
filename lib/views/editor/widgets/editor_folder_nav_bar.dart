import 'package:flutter/material.dart';
import '../../../models/student_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

/// Barra de contexto do editor (.folder-nav-bar): seletor do aluno em
/// edição, Presets de Ficha e Backup do Sistema.
class EditorFolderNavBar extends StatelessWidget {
  final List<Student> students;
  final String? activeStudentId;
  final ValueChanged<String> onSelectStudent;
  final VoidCallback onOpenPresets;

  /// Gera o JSON de backup somente quando o botão é pressionado (evita
  /// serializar a ficha a cada rebuild da barra).
  final String Function() getBackupJson;

  const EditorFolderNavBar({
    super.key,
    required this.students,
    required this.activeStudentId,
    required this.onSelectStudent,
    required this.onOpenPresets,
    required this.getBackupJson,
  });

  void _showBackupDialog(BuildContext context) {
    final stateJson = getBackupJson();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.carbon2,
        title: const Text(
          'Backup da Ficha (JSON)',
          style: TextStyle(color: Colors.white),
        ),
        content: SelectableText(
          stateJson,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            color: AppColors.steel,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.carbon2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              const Icon(Icons.person, color: AppColors.blueLight, size: 18),
              Text(
                'Aluno em Edição: ',
                style: AppTheme.labelCaps(color: AppColors.steel),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: students.any((s) => s.id == activeStudentId)
                      ? activeStudentId
                      : (students.isNotEmpty ? students.first.id : null),
                  dropdownColor: AppColors.carbon3,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  underline: const SizedBox(),
                  items: students.map((s) {
                    return DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (newId) {
                    if (newId != null && newId != activeStudentId) {
                      onSelectStudent(newId);
                    }
                  },
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.bolt, size: 16, color: AppColors.gold),
                label: const Text('Presets de Ficha'),
                onPressed: onOpenPresets,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: AppColors.gold.withValues(alpha: 0.4),
                  ),
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(
                  Icons.save_alt,
                  size: 16,
                  color: AppColors.blueLight,
                ),
                label: const Text('Backup do Sistema'),
                onPressed: () => _showBackupDialog(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: AppColors.blue.withValues(alpha: 0.4),
                  ),
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
