import 'package:flutter/material.dart';

import '../../../models/training_methods.dart';
import '../../../models/catalog_media_item.dart';
import '../../../models/workout_model.dart';
import '../../../services/student_context_service.dart';
import '../../../services/catalog_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/exercise_media.dart';

/// Collects a prescription without changing the workout until confirmation.
/// The containing sheet keeps this widget mounted when returning to the library.
class ExercisePrescriptionForm extends StatefulWidget {
  final ExerciseLibraryItem item;
  final ValueChanged<Exercise> onSubmit;
  final VoidCallback onBack;
  final String? initialMethodId;
  final Future<bool> Function(Exercise)? onSubmitAsync;

  const ExercisePrescriptionForm({
    super.key,
    required this.item,
    required this.onSubmit,
    required this.onBack,
    this.initialMethodId,
    this.onSubmitAsync,
  });

  @override
  State<ExercisePrescriptionForm> createState() =>
      _ExercisePrescriptionFormState();
}

class _ExercisePrescriptionFormState extends State<ExercisePrescriptionForm> {
  static const _simpleMethod = 'simple';
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _fieldKeys = <String, GlobalKey<FormFieldState<String>>>{};
  final _focusNodes = <String, FocusNode>{};
  final _inputScrollControllers = <String, ScrollController>{};
  final _methodDrafts = <String, List<_MethodSetDraft>>{};
  String _methodId = _simpleMethod;
  bool _timed = false;
  bool _bodyweight = false;
  bool _attemptedSubmit = false;
  bool _confirmed = false;
  String? _submissionError;
  bool _submitting = false;
  List<String>? _instructions;
  bool _loadingInstructions = false;
  bool _instructionsFailed = false;
  CatalogMediaItem? _media;

  Future<void> _loadMedia() async {
    final item = widget.item;
    final media = await CatalogService.instance.mediaFor(item);
    if (mounted && identical(item, widget.item) && _media == null) {
      setState(() => _media = media);
    }
  }

  Future<void> _chooseMedia() async {
    final controller = TextEditingController();
    Future<List<CatalogMediaItem>> results = Future.value(const []);
    final chosen = await showModalBottomSheet<CatalogMediaItem>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, update) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.7,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Escolher demonstração', style: AppTheme.headlineSm()),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Buscar movimento em inglês',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => update(() {
                      results = CatalogService.instance.searchMedia(value);
                    }),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: FutureBuilder<List<CatalogMediaItem>>(
                      future: results,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text(
                              'Não foi possível buscar demonstrações.',
                            ),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              'Digite pelo menos 3 letras para buscar.',
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final media = snapshot.data![index];
                            return ListTile(
                              leading: Image.network(
                                media.thumbnailUrl,
                                width: 48,
                                height: 48,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.fitness_center),
                              ),
                              title: Text(media.name),
                              subtitle: Text(media.equipment),
                              onTap: () =>
                                  Navigator.of(sheetContext).pop(media),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    controller.dispose();
    if (chosen != null && mounted) setState(() => _media = chosen);
  }

  Future<void> _loadInstructions() async {
    if (_loadingInstructions || _instructions != null) return;
    setState(() {
      _loadingInstructions = true;
      _instructionsFailed = false;
    });
    try {
      final steps = await CatalogService.instance.instructionsFor(widget.item);
      if (mounted) setState(() => _instructions = steps);
    } catch (_) {
      if (mounted) setState(() => _instructionsFailed = true);
    } finally {
      if (mounted) setState(() => _loadingInstructions = false);
    }
  }

  String get _methodCategory => TrainingMethods.categoryForExercise(
    widget.item.category,
    muscle: widget.item.muscle,
  );
  bool get _isCardio => _methodCategory == 'cardio';
  bool get _isMobility => _methodCategory == 'mobilidade';
  bool get _usesMethod => _methodId != _simpleMethod;
  List<TrainingMethod> get _methods => TrainingMethods.all
      .where(
        (method) => TrainingMethods.isCompatibleWithExercise(
          method,
          widget.item.category,
          muscle: widget.item.muscle,
          title: widget.item.title,
          equipment: widget.item.equipment,
        ),
      )
      .toList();

  @override
  void initState() {
    super.initState();
    _timed = _isMobility;
    _applyInitialMethod();
    Future.microtask(_loadMedia);
  }

  @override
  void didUpdateWidget(covariant ExercisePrescriptionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMethodId != widget.initialMethodId ||
        oldWidget.item != widget.item) {
      _timed = _isMobility;
      _applyInitialMethod();
      _media = null;
      Future.microtask(_loadMedia);
    }
  }

  void _applyInitialMethod() {
    final id = widget.initialMethodId;
    if (id != null && _methods.any((method) => method.id == id)) {
      _prepareMethod(id);
      _methodId = id;
    } else {
      _methodId = _simpleMethod;
    }
  }

  TextEditingController _controller(String id) =>
      _controllers.putIfAbsent(id, TextEditingController.new);

  String _value(String id) => _controller(id).text.trim();

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    for (final controller in _inputScrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _prepareMethod(String id) {
    _methodDrafts.putIfAbsent(id, () {
      final method = TrainingMethods.getMethod(id);
      return List.generate(method.sets.length, (index) {
        final raw = method.sets[index];
        final tag = RegExp(r'^\[[^\]]+\]').firstMatch(raw)?.group(0) ?? '';
        final fieldId = 'method-$id-$index';
        _controller(fieldId).text = raw.substring(tag.length);
        return _MethodSetDraft(tag: tag, fieldId: fieldId);
      });
    });
  }

  void _selectMethod(String? id) {
    if (id == null || id == _methodId) return;
    if (id != _simpleMethod) {
      if (!_methods.any((method) => method.id == id)) return;
      _prepareMethod(id);
    }
    setState(() => _methodId = id);
  }

  String? _validateSets(String? raw) {
    final count = int.tryParse((raw ?? '').trim());
    if (count == null || count < 1 || count > 20) {
      return 'Informe de 1 a 20 séries.';
    }
    return null;
  }

  String? _validateReps(String? raw) {
    final value = (raw ?? '').trim();
    final match = RegExp(r'^(\d+)(?:\s*[-–]\s*(\d+))?$').firstMatch(value);
    if (match == null) return 'Use um número ou intervalo, como 8-12.';
    final first = int.tryParse(match.group(1)!);
    final last = int.tryParse(match.group(2) ?? match.group(1)!);
    if (first == null || last == null || first < 1 || last < first) {
      return 'Use valores maiores que zero, em ordem crescente.';
    }
    return null;
  }

  String? _validateNumber(
    String? raw, {
    required String label,
    bool optional = false,
    bool allowZero = false,
  }) {
    final text = (raw ?? '').trim();
    if (text.isEmpty && optional) return null;
    final value = double.tryParse(text.replaceAll(',', '.'));
    if (!RegExp(r'^\d+(?:[.,]\d+)?$').hasMatch(text) ||
        value == null ||
        !value.isFinite ||
        (allowZero ? value < 0 : value <= 0)) {
      return '$label ${allowZero ? 'zero ou um valor positivo' : 'um valor maior que zero'}.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_confirmed || _submitting) return;
    setState(() => _attemptedSubmit = true);
    if (!_formKey.currentState!.validate()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        for (final entry in _fieldKeys.entries) {
          if (entry.value.currentState?.hasError ?? false) {
            _focusNodes[entry.key]?.requestFocus();
            final fieldContext = entry.value.currentContext;
            if (fieldContext != null) {
              Scrollable.ensureVisible(fieldContext, alignment: 0.2);
            }
            break;
          }
        }
      });
      return;
    }

    final List<String> sets;
    if (_usesMethod) {
      sets = _methodDrafts[_methodId]!
          .map((draft) => '${draft.tag}${_value(draft.fieldId)}')
          .toList();
    } else if (_isCardio) {
      sets = ['[work]${_value('duration')} min — ${_value('intensity')}'];
    } else {
      final quantity = _timed
          ? '${_value('time')} s'
          : '${_value('reps')} reps';
      final rest = _value('rest');
      final prescription =
          '[work]$quantity${rest.isEmpty ? '' : ' · descanso $rest s'}';
      sets = List.filled(int.parse(_value('sets')), prescription);
    }

    final notes = _value('notes');
    final cue = [
      if (widget.item.cue.trim().isNotEmpty) widget.item.cue,
      if (!_isCardio && !_isMobility && _bodyweight)
        'Peso corporal, sem carga externa.',
      if (_usesMethod &&
          TrainingMethods.getMethod(_methodId).requiresCompanionExercises)
        'Sequência de exercícios: ${_value('companions')}',
      if (_usesMethod && TrainingMethods.getMethod(_methodId).requiresPosition)
        'Posição da pausa: ${_value('position')}',
      if (notes.isNotEmpty) 'Observações: $notes',
    ].join('\n');
    final exercise = Exercise(
      title: widget.item.title,
      muscle: widget.item.muscle,
      cue: cue,
      video: widget.item.video,
      image:
          _media?.animationUrl ??
          (widget.item.animationUrl.isNotEmpty
              ? widget.item.animationUrl
              : widget.item.images.firstOrNull ?? ''),
      mediaAttribution: _media?.attribution ?? '',
      loadKg: (_isCardio || _isMobility)
          ? ''
          : (_bodyweight ? '0' : _value('load')),
      sets: sets,
      restSeconds: _value('rest').isEmpty ? null : int.parse(_value('rest')),
    );
    if (widget.onSubmitAsync == null) {
      setState(() => _confirmed = true);
      widget.onSubmit(exercise);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _submissionError = null;
    });
    try {
      final saved = await widget.onSubmitAsync!(exercise);
      if (mounted) setState(() => _confirmed = saved);
    } catch (_) {
      if (mounted) {
        setState(
          () => _submissionError =
              'Não foi possível adicionar. Seus dados foram mantidos; tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _decoration(String label, {String? hint, String? helper}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 3,
        errorMaxLines: 3,
        filled: true,
        fillColor: AppColors.carbon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        labelStyle: AppTheme.bodyLg(color: AppColors.steel),
        floatingLabelStyle: AppTheme.bodyLg(color: AppColors.steelLight),
        hintStyle: AppTheme.bodyLg(color: AppColors.steelDim),
        helperStyle: AppTheme.bodyMd(color: AppColors.steel),
        errorStyle: AppTheme.bodyMd(color: const Color(0xFFFFB4AB)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.steelDim),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.blueLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFFB4AB)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFFB4AB), width: 2),
        ),
      );

  Widget _field(
    String id,
    String label, {
    String? hint,
    String? helper,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) => Padding(
    key: ValueKey('prescription-$id'),
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: _fieldKeys.putIfAbsent(id, GlobalKey<FormFieldState<String>>.new),
      focusNode: _focusNodes.putIfAbsent(id, FocusNode.new),
      controller: _controller(id),
      scrollController: _inputScrollControllers.putIfAbsent(
        id,
        () => ScrollController(keepScrollOffset: false),
      ),
      enabled: !_submitting,
      style: AppTheme.bodyLg(color: AppColors.steelLight),
      cursorColor: AppColors.blueLight,
      decoration: _decoration(label, hint: hint, helper: helper),
      keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType,
      textInputAction: maxLines == 1
          ? TextInputAction.next
          : TextInputAction.newline,
      maxLines: maxLines,
      validator: validator,
      autovalidateMode: _attemptedSubmit
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
    ),
  );

  Widget _pair(Widget first, Widget second) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth >= 520
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              const SizedBox(width: 16),
              Expanded(child: second),
            ],
          )
        : Column(children: [first, second]),
  );

  Widget _basicFields() {
    if (_isCardio) {
      return Column(
        children: [
          _field(
            'duration',
            'Duração (minutos)',
            hint: 'Informe a duração',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) => _validateNumber(value, label: 'Informe'),
          ),
          _field(
            'intensity',
            'Ritmo ou intensidade',
            hint: 'Descreva o ritmo planejado',
            maxLines: 2,
            validator: (value) => (value ?? '').trim().isEmpty
                ? 'Descreva o ritmo ou a intensidade.'
                : null,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DropdownButtonFormField<bool>(
            key: const ValueKey('prescription-measure'),
            initialValue: _timed,
            decoration: _decoration('Como medir cada série'),
            dropdownColor: AppColors.carbon2,
            style: AppTheme.bodyLg(color: AppColors.steelLight),
            iconEnabledColor: AppColors.steel,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: false, child: Text('Repetições')),
              DropdownMenuItem(value: true, child: Text('Tempo por série')),
            ],
            onChanged: _submitting
                ? null
                : (value) => setState(() => _timed = value ?? false),
          ),
        ),
        _pair(
          _field(
            'sets',
            'Número de séries',
            hint: 'De 1 a 20',
            keyboardType: TextInputType.number,
            validator: _validateSets,
          ),
          _timed
              ? _field(
                  'time',
                  'Tempo por série (segundos)',
                  hint: 'Informe o tempo',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) =>
                      _validateNumber(value, label: 'Informe'),
                )
              : _field(
                  'reps',
                  'Repetições por série',
                  hint: 'Ex.: 10 ou 8-12',
                  validator: _validateReps,
                ),
        ),
        _field(
          'rest',
          'Descanso (segundos, opcional)',
          hint: 'Não definido',
          helper: 'De 0 a 600 segundos. Use 0 para não iniciar o cronômetro.',
          keyboardType: TextInputType.number,
          validator: (value) {
            final text = (value ?? '').trim();
            if (text.isEmpty) return null;
            final seconds = int.tryParse(text);
            return seconds == null || seconds < 0 || seconds > 600
                ? 'Informe de 0 a 600 segundos.'
                : null;
          },
        ),
      ],
    );
  }

  Widget _loadFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (!_bodyweight)
        _field(
          'load',
          'Carga (kg, opcional)',
          hint: 'Não definida',
          helper: 'Aceita vírgula, como 2,5. Use 0 para indicar sem carga.',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) => _validateNumber(
            value,
            label: 'Use',
            optional: true,
            allowZero: true,
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FilterChip(
          key: const ValueKey('prescription-bodyweight'),
          label: const Text('Peso corporal'),
          labelStyle: AppTheme.bodyLg(
            color: _bodyweight ? AppColors.carbon1 : AppColors.steelLight,
          ),
          selected: _bodyweight,
          selectedColor: AppColors.blueLight,
          backgroundColor: AppColors.carbon,
          checkmarkColor: AppColors.carbon1,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          onSelected: _submitting
              ? null
              : (value) => setState(() => _bodyweight = value),
        ),
      ),
    ],
  );

  Widget _methodSelector() => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: DropdownButtonFormField<String>(
      key: const ValueKey('prescription-method'),
      initialValue: _methodId,
      decoration: _decoration(
        'Método de treino',
        helper: 'Escolha um modelo para ajustar ou preencha manualmente.',
      ),
      dropdownColor: AppColors.carbon2,
      style: AppTheme.bodyLg(color: AppColors.steelLight),
      iconEnabledColor: AppColors.steel,
      isExpanded: true,
      menuMaxHeight: 360,
      items: [
        const DropdownMenuItem(
          value: _simpleMethod,
          child: Text('Definir manualmente'),
        ),
        ..._methods.map(
          (method) => DropdownMenuItem(
            value: method.id,
            child: Text(method.name, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: _submitting ? null : _selectMethod,
    ),
  );

  Widget _methodFields() {
    final method = TrainingMethods.getMethod(_methodId);
    final drafts = _methodDrafts[_methodId]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(method.name, style: AppTheme.headlineSm()),
        const SizedBox(height: 4),
        Text(
          '${method.level} · ${method.goals.join(' · ')}',
          style: AppTheme.bodyMd(color: AppColors.steel),
        ),
        const SizedBox(height: 8),
        Text(
          method.description,
          style: AppTheme.bodyLg(color: AppColors.steel),
        ),
        const SizedBox(height: 8),
        Text(method.guidance, style: AppTheme.bodyLg(color: AppColors.steel)),
        const SizedBox(height: 12),
        Text(
          'Modelo editável: revise cada ${_isCardio ? 'etapa' : 'série'} antes de adicionar.',
          style: AppTheme.bodyLg(color: AppColors.steel),
        ),
        const SizedBox(height: 20),
        if (method.requiresCompanionExercises)
          _field(
            'companions',
            'Exercícios e ordem da sequência',
            hint: 'Ex.: 1. Supino reto → 2. Remada baixa',
            helper:
                'Inclua os parceiros na ficha. Este campo registra a ordem, mas não adiciona os outros exercícios.',
            maxLines: 2,
            validator: (value) => (value ?? '').trim().isEmpty
                ? 'Informe os exercícios que compõem a sequência e sua ordem.'
                : null,
          ),
        if (method.requiresPosition)
          _field(
            'position',
            'Posição da pausa',
            hint: 'Descreva o ponto do movimento em que deve pausar',
            maxLines: 2,
            validator: (value) => (value ?? '').trim().isEmpty
                ? 'Descreva a posição em que o aluno deve pausar.'
                : null,
          ),
        for (var index = 0; index < drafts.length; index++)
          _field(
            drafts[index].fieldId,
            '${_isCardio ? 'Etapa' : 'Série'} ${index + 1}${_tagLabel(drafts[index].tag)}',
            maxLines: 3,
            validator: (value) => (value ?? '').trim().isEmpty
                ? 'Preencha a orientação desta ${_isCardio ? 'etapa' : 'série'}.'
                : null,
          ),
      ],
    );
  }

  String _tagLabel(String tag) => switch (tag) {
    '[prep]' => ' · Preparação',
    '[warmup]' => ' · Aquecimento',
    '[work]' => ' · Trabalho',
    _ => '',
  };

  Widget _details() => ExpansionTile(
    key: const PageStorageKey('prescription-details'),
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(top: 12),
    iconColor: AppColors.steelLight,
    collapsedIconColor: AppColors.steel,
    title: Text('Orientações e observações', style: AppTheme.bodyLg()),
    onExpansionChanged: (expanded) {
      if (expanded) _loadInstructions();
    },
    children: [
      if (_loadingInstructions) const LinearProgressIndicator(),
      if (_instructionsFailed) ...[
        Text(
          'Não foi possível buscar as instruções completas. Sua prescrição está preservada.',
          style: AppTheme.bodyMd(color: AppColors.steelLight),
        ),
        TextButton.icon(
          onPressed: _loadInstructions,
          icon: const Icon(Icons.refresh),
          label: const Text('Buscar instruções novamente'),
        ),
      ],
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${widget.item.equipment} · ${widget.item.level}\nFonte: ${widget.item.source}',
            style: AppTheme.bodyMd(color: AppColors.steel),
          ),
        ),
      ),
      if ((_instructions ?? widget.item.instructions).isNotEmpty) ...[
        for (
          var index = 0;
          index < (_instructions ?? widget.item.instructions).length;
          index++
        )
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${index + 1}. ${(_instructions ?? widget.item.instructions)[index]}',
                style: AppTheme.bodyLg(color: AppColors.steel),
              ),
            ),
          ),
      ] else if (widget.item.cue.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.item.cue,
              style: AppTheme.bodyLg(color: AppColors.steel),
            ),
          ),
        ),
      _field(
        'notes',
        'Observações (opcional)',
        hint: 'Orientações específicas para este aluno',
        maxLines: 3,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: const ValueKey('prescription-back'),
          onPressed: _submitting ? null : widget.onBack,
          icon: const Icon(Icons.arrow_back, size: 20),
          label: const Text('Trocar exercício'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.steelLight,
            minimumSize: const Size(44, 48),
            textStyle: AppTheme.bodyLg(),
          ),
        ),
      ),
      Expanded(
        child: SingleChildScrollView(
          key: const ValueKey('prescription-scroll'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.item.title, style: AppTheme.headlineSm()),
                const SizedBox(height: 4),
                Text(
                  widget.item.muscle,
                  style: AppTheme.bodyLg(color: AppColors.steel),
                ),
                const SizedBox(height: 12),
                Text(
                  _isCardio
                      ? 'Defina a duração e o ritmo do exercício.'
                      : _isMobility
                      ? 'Defina o tempo ou as repetições do movimento.'
                      : 'Defina como o aluno fará este exercício.',
                  style: AppTheme.bodyLg(color: AppColors.steel),
                ),
                if (_media != null ||
                    widget.item.images.isNotEmpty ||
                    widget.item.animationUrl.isNotEmpty ||
                    widget.item.video.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ExerciseMedia(
                    images: _media == null ? widget.item.images : const [],
                    animationUrl:
                        _media?.animationUrl ?? widget.item.animationUrl,
                    videoUrl: widget.item.video,
                    attribution: _media?.attribution ?? '',
                  ),
                ],
                TextButton.icon(
                  onPressed: _chooseMedia,
                  icon: const Icon(Icons.slow_motion_video_outlined),
                  label: Text(
                    _media == null
                        ? 'Buscar GIF de execução'
                        : 'Trocar GIF de execução',
                  ),
                ),
                const SizedBox(height: 24),
                _methodSelector(),
                if (!_usesMethod) _basicFields(),
                if (_usesMethod) _methodFields(),
                if (!_isCardio && !_isMobility) ...[
                  const SizedBox(height: 12),
                  _loadFields(),
                ],
                _details(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      Container(
        decoration: const BoxDecoration(
          color: AppColors.carbon2,
          border: Border(top: BorderSide(color: AppColors.dividerColor)),
        ),
        padding: const EdgeInsets.only(top: 16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_submissionError != null)
                Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _submissionError!,
                      style: AppTheme.bodyMd(color: const Color(0xFFFFB4AB)),
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('prescription-submit'),
                  onPressed: _confirmed || _submitting ? null : _submit,
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(
                    _submitting
                        ? 'Adicionando…'
                        : _confirmed
                        ? 'Adicionado ao treino'
                        : 'Adicionar ao treino',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blueLight,
                    foregroundColor: AppColors.carbon1,
                    minimumSize: const Size(44, 52),
                    textStyle: AppTheme.bodyLg().copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _MethodSetDraft {
  final String tag;
  final String fieldId;

  const _MethodSetDraft({required this.tag, required this.fieldId});
}
