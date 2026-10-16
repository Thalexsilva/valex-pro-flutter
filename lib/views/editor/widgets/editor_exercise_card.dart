import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/catalog_service.dart';
import '../../../models/workout_model.dart';
import '../../../services/student_context_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../../utils/prescription_load.dart';

/// Resumo do exercício com edição progressiva. A ficha e o autosave continuam
/// sob responsabilidade dos callbacks do editor; este estado é apenas visual.
class EditorExerciseCard extends StatefulWidget {
  final Exercise exercise;
  final int displayIndex;
  final List<MapEntry<int, String>> otherDaysForMove;
  final void Function(VoidCallback mutation) mutate;
  final VoidCallback markDirty;
  final void Function(int? setIndex) onOpenCalcLoad;
  final void Function(int setIndex) onToggleSetType;
  final void Function(int setIndex, String type) onSetTypeExplicit;
  final void Function(int setIndex, int delta) onMoveSet;
  final void Function(int setIndex) onDeleteSet;
  final VoidCallback onAddSet;
  final VoidCallback onDuplicate;
  final void Function(int delta) onMove;
  final void Function(int targetDayIndex) onMoveToDay;
  final VoidCallback onDelete;

  const EditorExerciseCard({
    super.key,
    required this.exercise,
    required this.displayIndex,
    required this.otherDaysForMove,
    required this.mutate,
    required this.markDirty,
    required this.onOpenCalcLoad,
    required this.onToggleSetType,
    required this.onSetTypeExplicit,
    required this.onMoveSet,
    required this.onDeleteSet,
    required this.onAddSet,
    required this.onDuplicate,
    required this.onMove,
    required this.onMoveToDay,
    required this.onDelete,
  });

  @override
  State<EditorExerciseCard> createState() => _EditorExerciseCardState();
}

class _EditorExerciseCardState extends State<EditorExerciseCard> {
  bool _editing = false;
  late final TextEditingController _titleController;
  late final TextEditingController _cueController;
  late final TextEditingController _videoController;
  late final TextEditingController _restController;
  String? _restError;
  final _titleFocus = FocusNode();
  final List<TextEditingController> _setControllers = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.exercise.title);
    _cueController = TextEditingController(text: widget.exercise.cue);
    _videoController = TextEditingController(text: widget.exercise.videoUrl);
    _restController = TextEditingController(
      text: widget.exercise.restSecondsForSet(0).toString(),
    );
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant EditorExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise != widget.exercise) {
      _syncText(
        _restController,
        widget.exercise.restSecondsForSet(0).toString(),
      );
    }
    _syncControllers();
  }

  static final _setMarker = RegExp(r'^\[(warmup|prep|work)\]');

  /// O tipo da série fica no seletor "Tipo"; o campo mostra só a descrição.
  static String _setDescription(String set) => set.replaceFirst(_setMarker, '');

  static String _setMarkerOf(String set) => _setMarker.stringMatch(set) ?? '';

  void _syncText(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _syncControllers() {
    final ex = widget.exercise;
    _syncText(_titleController, ex.title);
    _syncText(_cueController, ex.cue);
    _syncText(_videoController, ex.videoUrl);
    while (_setControllers.length > ex.sets.length) {
      _setControllers.removeLast().dispose();
    }
    for (var index = 0; index < ex.sets.length; index++) {
      final description = _setDescription(ex.sets[index]);
      if (index == _setControllers.length) {
        _setControllers.add(TextEditingController(text: description));
      } else {
        _syncText(_setControllers[index], description);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _cueController.dispose();
    _videoController.dispose();
    _restController.dispose();
    _titleFocus.dispose();
    for (final controller in _setControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _setType(String line) {
    final value = line.toLowerCase();
    if (value.contains('[warmup]')) return 'warmup';
    if (value.contains('[prep]')) return 'prep';
    if (value.contains('[work]')) return 'work';
    if (value.contains('aquecimento')) return 'warmup';
    if (value.contains('prepara')) return 'prep';
    return 'work';
  }

  String _typeLabel(String type) => switch (type) {
    'warmup' => 'Aquecimento',
    'prep' => 'Preparação',
    _ => 'Trabalho',
  };

  String _readableSet(String line) => line
      .replaceAll(RegExp(r'\[(?:warmup|prep|work)\]', caseSensitive: false), '')
      .trim();

  @override
  Widget build(BuildContext context) {
    final inherited = Theme.of(context);
    final paperTheme = inherited.copyWith(
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.paperBlue,
        onPrimary: Colors.white,
        surface: AppColors.paperCard,
        onSurface: AppColors.ink,
        onSurfaceVariant: AppColors.paperMuted,
        outline: AppColors.paperMuted,
        error: Color(0xFFB91C1C),
      ),
      textTheme: inherited.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paperCard,
        labelStyle: TextStyle(color: AppColors.paperMuted, fontSize: 14),
        floatingLabelStyle: TextStyle(color: AppColors.paperBlue, fontSize: 14),
        hintStyle: TextStyle(color: AppColors.paperMuted, fontSize: 14),
        helperStyle: TextStyle(color: AppColors.paperMuted, fontSize: 14),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.paperMuted),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.paperBlue,
        selectionColor: AppColors.paperBlue.withValues(alpha: 0.2),
        selectionHandleColor: AppColors.paperBlue,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.paperCard,
        textStyle: TextStyle(color: AppColors.ink, fontSize: 14),
      ),
      iconTheme: const IconThemeData(color: AppColors.paperMuted),
    );
    return Theme(
      data: paperTheme,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.paperCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 12),
            if (_editing) _details() else _summary(),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                FocusScope.of(context).unfocus();
                setState(() => _editing = !_editing);
              },
              icon: Icon(
                _editing ? Icons.check : Icons.edit_outlined,
                size: 20,
              ),
              label: Text(_editing ? 'Concluir edição' : 'Editar detalhes'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.paperBlue,
                minimumSize: const Size(44, 48),
                textStyle: AppTheme.bodyMd(color: AppColors.paperBlue),
                side: const BorderSide(color: AppColors.paperBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final ex = widget.exercise;
    final muscle = resolveExerciseMuscleCategory(ex);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${widget.displayIndex + 1}'.padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ex.title.trim().isEmpty ? 'Exercício sem nome' : ex.title,
                style: AppTheme.headlineSm(color: AppColors.ink),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  muscle,
                  if (ex.loadKg.trim().isNotEmpty) 'Carga: ${ex.loadKg} kg',
                  'Descanso: ${ex.restSecondsForSet(0)} s',
                ].join(' · '),
                style: AppTheme.bodyMd(color: AppColors.paperMuted),
              ),
            ],
          ),
        ),
        _exerciseMenu(),
      ],
    );
  }

  Widget _summary() {
    final ex = widget.exercise;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ex.cue.trim().isNotEmpty) ...[
          Text(ex.cue, style: AppTheme.bodyMd(color: AppColors.paperMuted)),
          const SizedBox(height: 12),
        ],
        if (ex.sets.isEmpty)
          Text(
            'Nenhuma série definida. Use Editar detalhes para adicionar.',
            style: AppTheme.bodyMd(color: AppColors.paperMuted),
          )
        else
          ...ex.sets.asMap().entries.map((entry) {
            final text = _readableSet(entry.value);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${entry.key + 1}.',
                      style: AppTheme.bodyMd(color: AppColors.paperMuted),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _typeLabel(_setType(entry.value)),
                          style: AppTheme.bodyMd(color: AppColors.paperMuted),
                        ),
                        Text(
                          text.isEmpty ? 'Série sem descrição' : text,
                          style: AppTheme.bodyLg(color: AppColors.ink),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        if (ex.videoUrl.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.video_library_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vídeo de execução vinculado',
                  style: AppTheme.bodyMd(color: AppColors.paperMuted),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _details() {
    final ex = widget.exercise;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RawAutocomplete<String>(
          textEditingController: _titleController,
          focusNode: _titleFocus,
          optionsBuilder: (value) async {
            if (value.text.trim().isEmpty) {
              return const Iterable<String>.empty();
            }
            await CatalogService.instance.ensureLoaded();
            return StudentContextService.exerciseLibrary
                .map((item) => item.title)
                .where(
                  (title) =>
                      title.toLowerCase().contains(value.text.toLowerCase()),
                );
          },
          onSelected: (selection) {
            widget.mutate(() {
              ex.title = selection;
              final match = StudentContextService.exerciseLibrary.firstWhere(
                (item) => item.title == selection,
              );
              ex.cue = match.cue;
              if (match.video.isNotEmpty) ex.videoUrl = match.video;
              if (match.muscle.isNotEmpty) ex.muscle = match.muscle;
            });
          },
          fieldViewBuilder: (context, controller, focusNode, onSubmit) =>
              TextFormField(
                controller: controller,
                focusNode: focusNode,
                style: AppTheme.bodyLg(color: AppColors.ink),
                decoration: const InputDecoration(
                  labelText: 'Nome do exercício',
                ),
                onChanged: (value) {
                  ex.title = value;
                  final match = StudentContextService.exerciseLibrary
                      .firstWhere(
                        (item) =>
                            item.title.toLowerCase() ==
                            value.trim().toLowerCase(),
                        orElse: () => const ExerciseLibraryItem(
                          title: '',
                          muscle: '',
                          cue: '',
                          video: '',
                        ),
                      );
                  if (match.title.isNotEmpty) {
                    if (ex.cue.isEmpty || ex.cue == 'Controle de cadência') {
                      ex.cue = match.cue;
                      _syncText(_cueController, ex.cue);
                    }
                    if (ex.videoUrl.isEmpty && match.video.isNotEmpty) {
                      ex.videoUrl = match.video;
                      _syncText(_videoController, ex.videoUrl);
                    }
                  }
                  widget.markDirty();
                },
              ),
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 6,
              color: AppColors.paperCard,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width < 400 ? 250 : 320,
                  maxHeight: 240,
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  shrinkWrap: true,
                  children: options
                      .map(
                        (option) => ListTile(
                          title: Text(
                            option,
                            style: AppTheme.bodyMd(color: AppColors.ink),
                          ),
                          onTap: () => onSelected(option),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cueController,
          minLines: 2,
          maxLines: null,
          style: AppTheme.bodyLg(color: AppColors.ink),
          decoration: const InputDecoration(
            labelText: 'Orientações de execução',
          ),
          onChanged: (value) {
            ex.cue = value;
            widget.markDirty();
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _videoController,
          style: AppTheme.bodyMd(color: AppColors.ink),
          inputFormatters: [UrlSanitizerFormatter()],
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Vídeo de execução (opcional)',
            prefixIcon: Icon(Icons.video_library_outlined),
          ),
          onChanged: (value) {
            ex.videoUrl = value;
            widget.markDirty();
          },
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => widget.onOpenCalcLoad(null),
          icon: const Icon(Icons.fitness_center, size: 20),
          label: Text(
            ex.loadKg.isEmpty ? 'Definir carga' : 'Carga: ${ex.loadKg} kg',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.paperBlue,
            minimumSize: const Size(44, 48),
            textStyle: AppTheme.bodyMd(color: AppColors.paperBlue),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const ValueKey('exercise-rest-seconds'),
          controller: _restController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 3,
          style: AppTheme.bodyLg(color: AppColors.ink),
          decoration: InputDecoration(
            labelText: 'Descanso entre séries (segundos)',
            helperText: 'De 0 a 600 s. Use 0 para não iniciar o cronômetro.',
            errorText: _restError,
          ),
          onChanged: (value) {
            final seconds = int.tryParse(value);
            if (seconds == null || seconds > 600) {
              setState(() => _restError = 'Informe de 0 a 600 segundos.');
              return;
            }
            widget.exercise.restSeconds = seconds;
            widget.markDirty();
            setState(() => _restError = null);
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Séries do exercício',
          style: AppTheme.headlineSm(color: AppColors.ink),
        ),
        const SizedBox(height: 4),
        Text(
          'Ajuste cada série mantendo as orientações do treino.',
          style: AppTheme.bodyMd(color: AppColors.paperMuted),
        ),
        const SizedBox(height: 12),
        ...ex.sets.asMap().entries.map(
          (entry) => _editableSet(entry.key, entry.value),
        ),
        OutlinedButton.icon(
          onPressed: widget.onAddSet,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Adicionar série'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.paperBlue,
            minimumSize: const Size(44, 48),
            textStyle: AppTheme.bodyMd(color: AppColors.paperBlue),
          ),
        ),
      ],
    );
  }

  Widget _editableSet(int index, String line) {
    final type = _setType(line);
    final baseKg =
        double.tryParse(widget.exercise.loadKg.replaceAll(',', '.')) ?? 0;
    final pct = prescriptionLoadPercentage(line);
    final calculatedLoad = baseKg > 0 && pct != null
        ? (baseKg * pct / 100).round()
        : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Série ${index + 1}',
                  style: AppTheme.bodyLg(color: AppColors.ink),
                ),
              ),
              _setMenu(index),
            ],
          ),
          PopupMenuButton<String>(
            tooltip: 'Alterar tipo da série ${index + 1}',
            initialValue: type,
            color: AppColors.paperCard,
            onSelected: (value) => widget.onSetTypeExplicit(index, value),
            itemBuilder: (context) => ['warmup', 'prep', 'work']
                .map(
                  (value) => PopupMenuItem(
                    value: value,
                    child: Text(
                      _typeLabel(value),
                      style: AppTheme.bodyMd(color: AppColors.ink),
                    ),
                  ),
                )
                .toList(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tipo: ${_typeLabel(type)}',
                    style: AppTheme.bodyMd(color: AppColors.paperBlue),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.expand_more,
                    color: AppColors.paperBlue,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _setControllers[index],
            minLines: 2,
            maxLines: null,
            style: AppTheme.bodyLg(color: AppColors.ink),
            decoration: InputDecoration(
              labelText: 'Descrição da série ${index + 1}',
            ),
            onChanged: (value) {
              final sets = widget.exercise.sets;
              // Um marcador colado no texto é descartado; vale o seletor.
              sets[index] =
                  '${_setMarkerOf(sets[index])}${_setDescription(value)}';
              widget.markDirty();
            },
          ),
          if (calculatedLoad != null) ...[
            const SizedBox(height: 8),
            Text(
              'Carga calculada: ≈ $calculatedLoad kg',
              style: AppTheme.bodyMd(color: AppColors.paperGreen),
            ),
          ],
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    String label,
    IconData icon, {
    bool destructive = false,
  }) {
    final color = destructive ? const Color(0xFFB91C1C) : AppColors.ink;
    return PopupMenuItem(
      value: value,
      height: 48,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Flexible(
            child: Text(label, style: AppTheme.bodyMd(color: color)),
          ),
        ],
      ),
    );
  }

  Widget _exerciseMenu() => PopupMenuButton<String>(
    tooltip: 'Ações do exercício',
    color: AppColors.paperCard,
    icon: const Icon(Icons.more_vert, color: AppColors.paperMuted),
    constraints: const BoxConstraints(minWidth: 240, maxWidth: 300),
    onSelected: (value) {
      if (value == 'duplicate') widget.onDuplicate();
      if (value == 'up') widget.onMove(-1);
      if (value == 'down') widget.onMove(1);
      if (value == 'delete') widget.onDelete();
      if (value.startsWith('day:')) {
        widget.onMoveToDay(int.parse(value.substring(4)));
      }
    },
    itemBuilder: (context) => [
      _menuItem('duplicate', 'Duplicar exercício', Icons.copy_outlined),
      _menuItem('up', 'Mover para cima', Icons.arrow_upward),
      _menuItem('down', 'Mover para baixo', Icons.arrow_downward),
      ...widget.otherDaysForMove.map(
        (day) => _menuItem(
          'day:${day.key}',
          'Mover para ${day.value}',
          Icons.drive_file_move_outline,
        ),
      ),
      const PopupMenuDivider(),
      _menuItem(
        'delete',
        'Excluir exercício',
        Icons.delete_outline,
        destructive: true,
      ),
    ],
  );

  Widget _setMenu(int index) => PopupMenuButton<String>(
    tooltip: 'Opções da série ${index + 1}',
    color: AppColors.paperCard,
    icon: const Icon(Icons.more_vert, color: AppColors.paperMuted),
    onSelected: (value) {
      if (value == 'calc') widget.onOpenCalcLoad(index);
      if (value == 'up') widget.onMoveSet(index, -1);
      if (value == 'down') widget.onMoveSet(index, 1);
      if (value == 'delete') widget.onDeleteSet(index);
    },
    itemBuilder: (context) => [
      _menuItem('calc', 'Calcular % de carga', Icons.percent),
      _menuItem('up', 'Subir série', Icons.arrow_upward),
      _menuItem('down', 'Descer série', Icons.arrow_downward),
      _menuItem(
        'delete',
        'Excluir série',
        Icons.delete_outline,
        destructive: true,
      ),
    ],
  );
}
