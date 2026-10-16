import 'package:flutter/material.dart';
import '../../../models/workout_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

/// Toolbar principal do editor (.editor-toolbar): identidade/autosave,
/// campos do aluno (Aluno/Data/Professora) e comandos principais.
class EditorToolbar extends StatelessWidget {
  final WorkoutSheet activeSheet;
  final bool isSaving;
  final bool isDirty;

  /// Mensagem da última falha do salvamento automático; nula quando salvo.
  final String? saveError;
  final Future<bool> Function()? onRetrySave;

  /// Aplica uma mutação nos dados do cabeçalho e força rebuild (os campos
  /// refletem imediatamente na capa, por isso passam por `setState`, ao
  /// contrário das edições dentro das páginas de dia/exercício).
  final void Function(VoidCallback mutation) mutate;

  final VoidCallback onAddWorkoutDay;
  final VoidCallback onOpenGenerateAi;
  final VoidCallback onOpenNewCycle;
  final VoidCallback onOpenVersionHistory;
  final VoidCallback onOpenPdfPreview;
  final VoidCallback onResetSheet;
  final VoidCallback onSaveSnapshot;
  final VoidCallback onSaveCustomPreset;

  const EditorToolbar({
    super.key,
    required this.activeSheet,
    required this.isSaving,
    required this.isDirty,
    this.saveError,
    this.onRetrySave,
    required this.mutate,
    required this.onAddWorkoutDay,
    required this.onOpenGenerateAi,
    required this.onOpenNewCycle,
    required this.onOpenVersionHistory,
    required this.onOpenPdfPreview,
    required this.onResetSheet,
    required this.onSaveSnapshot,
    required this.onSaveCustomPreset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.carbon2, AppColors.carbon3.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1080;
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildIdentity(),
                const SizedBox(width: 12),
                Expanded(child: _buildFields()),
                const SizedBox(width: 12),
                SizedBox(width: 560, child: _buildActions(context)),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIdentity(),
              const SizedBox(height: 12),
              _buildFields(),
              const SizedBox(height: 12),
              _buildActions(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIdentity() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.blue.withValues(alpha: 0.4)),
          ),
          child: Text(
            'EDITOR ATIVO',
            style: AppTheme.labelCaps(color: AppColors.steelLight),
          ),
        ),
        if (saveError != null && !isSaving)
          Semantics(
            liveRegion: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: AppColors.crimsonText,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Não salvo no servidor',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.crimsonText,
                  ),
                ),
                if (onRetrySave != null)
                  TextButton(
                    onPressed: onRetrySave,
                    child: const Text('Tentar novamente'),
                  ),
              ],
            ),
          )
        else
          Text(
            isSaving
                ? 'Gravando...'
                : (isDirty ? 'Alterações pendentes' : '✓ Salvo'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSaving
                  ? AppColors.gold
                  : (isDirty ? AppColors.steel : AppColors.green),
            ),
          ),
      ],
    );
  }

  Widget _buildFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Em telas estreitas cada campo ocupa a linha inteira; com larguras
        // fixas o nome da professora ficava cortado.
        final narrow = constraints.maxWidth < 520;
        double fieldWidth(double preferred) =>
            narrow ? constraints.maxWidth : preferred;
        return _fieldsWrap(fieldWidth);
      },
    );
  }

  Widget _fieldsWrap(double Function(double preferred) fieldWidth) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _editorField(
          label: 'Aluno',
          width: fieldWidth(188),
          child: TextFormField(
            initialValue: activeSheet.studentName,
            style: AppTheme.inputText(),
            decoration: const InputDecoration(isDense: true),
            onChanged: (value) => mutate(() => activeSheet.studentName = value),
          ),
        ),
        _editorField(
          label: 'Data',
          width: fieldWidth(166),
          child: TextFormField(
            initialValue: activeSheet.month,
            style: AppTheme.inputText(),
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'dd/mm/aaaa',
            ),
            onChanged: (value) => mutate(() => activeSheet.month = value),
          ),
        ),
        _editorField(
          label: 'Professora',
          width: fieldWidth(196),
          child: TextFormField(
            initialValue: activeSheet.teacher,
            style: AppTheme.inputText(),
            decoration: const InputDecoration(isDense: true),
            onChanged: (value) => mutate(() => activeSheet.teacher = value),
          ),
        ),
      ],
    );
  }

  Widget _editorField({
    required String label,
    required double width,
    required Widget child,
  }) {
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: AppTheme.labelCaps(color: AppColors.steel),
          ),
          const SizedBox(width: 6),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final version = activeSheet.currentVersionName.split(' - ').first;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Novo treino'),
          onPressed: onAddWorkoutDay,
          style: _compactElevatedButtonStyle(context),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.auto_awesome, size: 16),
          label: const Text('IA Treino'),
          onPressed: onOpenGenerateAi,
          style: _compactOutlinedButtonStyle(context),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_month, size: 16),
          label: const Text('Novo Ciclo'),
          onPressed: onOpenNewCycle,
          style: _compactOutlinedButtonStyle(context),
        ),
        Tooltip(
          message: 'Histórico de Versões',
          child: OutlinedButton.icon(
            icon: const Icon(Icons.history, size: 16),
            label: Text(version),
            onPressed: onOpenVersionHistory,
            style: _compactOutlinedButtonStyle(context),
          ),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.print, size: 16),
          label: const Text('Imprimir'),
          onPressed: onOpenPdfPreview,
          style: _compactElevatedButtonStyle(context),
        ),
        OutlinedButton(
          onPressed: onResetSheet,
          style: _compactOutlinedButtonStyle(
            context,
            foregroundColor: const Color(0xFFFCA5A5),
          ),
          child: const Text('Resetar'),
        ),
        PopupMenuButton<String>(
          tooltip: 'Mais ações do editor',
          icon: const Icon(Icons.more_vert, color: AppColors.steel),
          color: AppColors.carbon2,
          onSelected: (value) {
            if (value == 'snapshot') onSaveSnapshot();
            if (value == 'preset') onSaveCustomPreset();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'snapshot', child: Text('Salvar snapshot')),
            PopupMenuItem(value: 'preset', child: Text('Salvar como preset')),
          ],
        ),
      ],
    );
  }

  ButtonStyle _compactOutlinedButtonStyle(
    BuildContext context, {
    Color foregroundColor = Colors.white,
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: foregroundColor,
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
    );
  }

  ButtonStyle _compactElevatedButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.paperBlue,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
    );
  }
}
