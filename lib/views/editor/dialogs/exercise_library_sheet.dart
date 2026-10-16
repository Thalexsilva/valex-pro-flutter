import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../models/training_methods.dart';
import '../../../models/workout_model.dart';
import '../../../services/student_context_service.dart';
import '../../../services/catalog_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../widgets/exercise_prescription_form.dart';

/// Catálogo sob demanda compartilhado pelo editor e pela página de biblioteca.
/// A seleção apenas abre um rascunho; adicionar exige revisar a prescrição.
class ExerciseLibrarySheet extends StatefulWidget {
  final ValueChanged<Exercise>? onAdd;
  final Future<bool> Function(Exercise)? onAddAsync;
  final String? dayLabel;
  final bool embedded;

  const ExerciseLibrarySheet({
    super.key,
    this.onAdd,
    this.onAddAsync,
    this.dayLabel,
    this.embedded = false,
  }) : assert(onAdd != null || onAddAsync != null);

  @override
  State<ExerciseLibrarySheet> createState() => _ExerciseLibrarySheetState();
}

class _ExerciseLibrarySheetState extends State<ExerciseLibrarySheet> {
  final _searchController = TextEditingController();
  final _methodSearchController = TextEditingController();
  final _exerciseScroll = ScrollController();
  final _methodScroll = ScrollController();
  final _catalog = CatalogService.instance;
  List<ExerciseLibraryItem>? _indexedItems;
  Map<ExerciseLibraryItem, String> _searchIndex = {};

  void _indexCatalog() {
    if (identical(_indexedItems, _catalog.items)) return;
    _indexedItems = _catalog.items;
    _searchIndex = {
      for (final item in StudentContextService.exerciseLibrary)
        item: _normalize(
          [
            item.title,
            item.muscle,
            item.cue,
            item.equipment,
            item.categoryLabel,
            ...item.aliases,
            ...item.primaryMuscles,
            ...item.secondaryMuscles,
          ].join(' '),
        ),
    };
  }

  String _selectedMuscle = 'Todos';
  String _selectedEquipment = 'Todos';
  String _selectedCategory = 'Todos';
  String _selectedGoal = 'Todos';
  bool _filtersExpanded = false;
  bool _methodsTab = false;
  String? _previewMethodId;
  TrainingMethod? _selectedMethod;
  ExerciseLibraryItem? _selectedItem;
  bool _configuring = false;
  bool _submitted = false;
  int _draftVersion = 0;

  @override
  void initState() {
    super.initState();
    _indexCatalog();
    _catalog.addListener(_catalogChanged);
    Future.microtask(() {
      if (mounted) _catalog.ensureLoaded();
    });
  }

  void _catalogChanged() {
    if (mounted) setState(_indexCatalog);
  }

  @override
  void dispose() {
    _catalog.removeListener(_catalogChanged);
    _searchController.dispose();
    _methodSearchController.dispose();
    _exerciseScroll.dispose();
    _methodScroll.dispose();
    super.dispose();
  }

  static String _normalize(String value) {
    const accents = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const letters = 'aaaaaeeeeiiiiooooouuuuc';
    var normalized = value.toLowerCase().trim();
    for (var i = 0; i < accents.length; i++) {
      normalized = normalized.replaceAll(accents[i], letters[i]);
    }
    return normalized;
  }

  static const _categoryNames = {
    'strength': 'Musculação',
    'cardio': 'Cardio',
    'stretching': 'Alongamento e mobilidade',
    'plyometrics': 'Pliometria',
    'powerlifting': 'Levantamentos de força',
    'olympic_weightlifting': 'Levantamento olímpico',
    'olympic weightlifting': 'Levantamento olímpico',
    'strongman': 'Strongman',
  };

  String _category(ExerciseLibraryItem item) => item.category.isNotEmpty
      ? item.category
      : TrainingMethods.categoryForExercise('', muscle: item.muscle) == 'cardio'
      ? 'cardio'
      : 'strength';

  int get _filterCount => [
    _selectedMuscle,
    _selectedEquipment,
    _selectedCategory,
  ].where((value) => value != 'Todos').length;

  void _choose(ExerciseLibraryItem item) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedItem = item;
      _configuring = true;
    });
  }

  void _backToLibrary() {
    FocusScope.of(context).unfocus();
    setState(() => _configuring = false);
  }

  void _clearFilters() {
    FocusScope.of(context).unfocus();
    _searchController.clear();
    setState(() {
      _selectedMuscle = 'Todos';
      _selectedEquipment = 'Todos';
      _selectedCategory = 'Todos';
      _selectedMethod = null;
    });
    if (_exerciseScroll.hasClients) _exerciseScroll.jumpTo(0);
  }

  void _chooseMethod(TrainingMethod method) {
    FocusScope.of(context).unfocus();
    _searchController.clear();
    setState(() {
      _selectedMethod = method;
      _methodsTab = false;
      _selectedMuscle = 'Todos';
      _selectedEquipment = 'Todos';
      _selectedCategory = 'Todos';
      _selectedItem = null;
    });
    if (_exerciseScroll.hasClients) _exerciseScroll.jumpTo(0);
  }

  Future<bool> _submit(Exercise exercise) async {
    if (_submitted) return false;
    setState(() => _submitted = true);
    bool accepted;
    try {
      if (widget.onAddAsync != null) {
        accepted = await widget.onAddAsync!(exercise);
      } else {
        widget.onAdd!(exercise);
        accepted = true;
      }
    } catch (_) {
      if (mounted) setState(() => _submitted = false);
      rethrow;
    }
    if (!mounted) return accepted;
    if (!accepted) {
      setState(() => _submitted = false);
      return false;
    }
    if (widget.embedded) {
      setState(() {
        _selectedItem = null;
        _configuring = false;
        _submitted = false;
        _draftVersion++;
      });
    } else {
      Navigator.of(context).pop();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final content = Theme(
      data: AppTheme.darkTheme,
      child: Material(
        color: AppColors.carbon2,
        borderRadius: BorderRadius.vertical(
          top: const Radius.circular(24),
          bottom: Radius.circular(widget.embedded ? 24 : 0),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          bottom: !widget.embedded,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              media.size.width < 480 ? 16 : 24,
              16,
              media.size.width < 480 ? 16 : 24,
              12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                Expanded(
                  child: IndexedStack(
                    sizing: StackFit.expand,
                    index: _configuring ? 1 : 0,
                    children: [
                      ExcludeFocus(
                        excluding: _configuring,
                        child: _catalog.isReady
                            ? _buildCatalogWithStatus()
                            : _buildLoading(),
                      ),
                      if (_selectedItem != null)
                        ExcludeFocus(
                          excluding: !_configuring,
                          child: ExercisePrescriptionForm(
                            key: ValueKey(
                              '${_selectedItem!.id.isEmpty ? _selectedItem!.title : _selectedItem!.id}:${_selectedMethod?.id}:$_draftVersion',
                            ),
                            item: _selectedItem!,
                            initialMethodId: _selectedMethod?.id,
                            onSubmit: (_) {},
                            onSubmitAsync: _submit,
                            onBack: _backToLibrary,
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (widget.embedded) return content;
    // AnimatedPadding já reserva o espaço do teclado; descontá-lo aqui
    // reduziria o conteúdo duas vezes e esconderia o formulário no celular.
    final availableHeight = math.max(
      0.0,
      media.size.height - media.padding.top,
    );
    return PopScope(
      canPop: !_configuring && !_submitted,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _configuring && !_submitted) _backToLibrary();
      },
      child: AnimatedPadding(
        duration: media.disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 150),
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          height: math.min(800.0, availableHeight * 0.94),
          child: content,
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Etapa ${_configuring ? 2 : 1} de 2',
              style: AppTheme.bodyMd(color: AppColors.blueLight),
            ),
            const SizedBox(height: 4),
            Semantics(
              header: true,
              child: Text(
                _configuring ? 'Definir prescrição' : 'Escolher exercício',
                style: AppTheme.headlineSm(),
              ),
            ),
            if (widget.dayLabel?.isNotEmpty ?? false) ...[
              const SizedBox(height: 4),
              Text(
                'Adicionar em ${widget.dayLabel}',
                style: AppTheme.bodyMd(color: AppColors.steel),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
      if (!widget.embedded) ...[
        const SizedBox(width: 8),
        IconButton(
          key: const ValueKey('exercise-library-close'),
          tooltip: 'Fechar biblioteca',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _submitted ? null : () => Navigator.of(context).pop(),
        ),
      ],
    ],
  );

  Widget _buildLoading() => Center(
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_catalog.loading || _catalog.error == null) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Carregando biblioteca…', style: AppTheme.bodyLg()),
          ] else ...[
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.steelLight,
              size: 36,
            ),
            const SizedBox(height: 16),
            Text(
              _catalog.error!,
              textAlign: TextAlign.center,
              style: AppTheme.bodyLg(),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _catalog.ensureLoaded(force: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _buildCatalogWithStatus() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_catalog.error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _catalog.error!,
                  style: AppTheme.bodyMd(color: AppColors.steelLight),
                ),
              ),
              IconButton(
                tooltip: 'Atualizar biblioteca',
                onPressed: _catalog.loading
                    ? null
                    : () => _catalog.ensureLoaded(force: true),
                icon: const Icon(Icons.refresh, color: AppColors.steelLight),
              ),
            ],
          ),
        ),
      if (_catalog.loading) const LinearProgressIndicator(),
      Expanded(child: _buildCatalog()),
    ],
  );

  Widget _buildCatalog() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(
            value: false,
            label: Text('Exercícios'),
            icon: Icon(Icons.fitness_center, size: 18),
          ),
          ButtonSegment(
            value: true,
            label: Text('Métodos'),
            icon: Icon(Icons.tune, size: 18),
          ),
        ],
        selected: {_methodsTab},
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          minimumSize: const Size(44, 48),
          foregroundColor: AppColors.steel,
          selectedForegroundColor: Colors.white,
          selectedBackgroundColor: AppColors.paperBlue,
        ),
        onSelectionChanged: (values) {
          FocusScope.of(context).unfocus();
          setState(() => _methodsTab = values.single);
        },
      ),
      const SizedBox(height: 12),
      Expanded(
        child: IndexedStack(
          index: _methodsTab ? 1 : 0,
          sizing: StackFit.expand,
          children: [
            ExcludeFocus(excluding: _methodsTab, child: _buildLibrary()),
            ExcludeFocus(excluding: !_methodsTab, child: _buildMethods()),
          ],
        ),
      ),
    ],
  );

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: AppTheme.bodyLg(color: AppColors.steel),
    floatingLabelStyle: AppTheme.bodyLg(color: AppColors.blueLight),
    filled: true,
    fillColor: AppColors.carbon3,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  Widget _searchField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String key,
  }) => TextField(
    key: ValueKey(key),
    controller: controller,
    style: AppTheme.bodyLg(),
    textInputAction: TextInputAction.search,
    onSubmitted: (_) => FocusScope.of(context).unfocus(),
    decoration: _decoration(label).copyWith(
      hintText: hint,
      hintStyle: AppTheme.bodyMd(color: AppColors.steel),
      prefixIcon: const Icon(Icons.search, color: AppColors.steel),
      suffixIcon: controller.text.isEmpty
          ? null
          : IconButton(
              tooltip: 'Limpar busca',
              icon: const Icon(Icons.close, color: AppColors.steel),
              onPressed: () {
                controller.clear();
                setState(() {});
              },
            ),
    ),
    onChanged: (_) => setState(() {}),
  );

  Widget _filter({
    required String id,
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
    Map<String, String> labels = const {},
  }) => DropdownButtonFormField<String>(
    key: ValueKey('exercise-library-$id-$value'),
    initialValue: value,
    isExpanded: true,
    dropdownColor: AppColors.carbon3,
    style: AppTheme.bodyLg(),
    iconEnabledColor: AppColors.steel,
    decoration: _decoration(label),
    items: ['Todos', ...options]
        .map(
          (option) => DropdownMenuItem(
            value: option,
            child: Text(
              labels[option] ?? option,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList(),
    onChanged: (next) {
      if (next == null) return;
      FocusScope.of(context).unfocus();
      setState(() => onChanged(next));
    },
  );

  Widget _buildLibrary() {
    final library = StudentContextService.exerciseLibrary;
    final words = _normalize(_searchController.text).split(RegExp(r'\s+'));
    final filtered = library.where((item) {
      return (_selectedMuscle == 'Todos' || item.muscle == _selectedMuscle) &&
          (_selectedEquipment == 'Todos' ||
              item.equipment == _selectedEquipment) &&
          (_selectedCategory == 'Todos' ||
              _category(item) == _selectedCategory) &&
          (_selectedMethod == null ||
              TrainingMethods.isCompatibleWithExercise(
                _selectedMethod!,
                item.category,
                muscle: item.muscle,
                title: item.title,
                equipment: item.equipment,
              )) &&
          words.every((word) => _searchIndex[item]!.contains(word));
    }).toList();
    final muscles =
        library
            .map((item) => item.muscle)
            .where((v) => v.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final equipment =
        library
            .map((item) => item.equipment)
            .where((v) => v.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final categories = library.map(_category).toSet().toList()..sort();
    return CustomScrollView(
      key: const PageStorageKey('exercise-library-results'),
      controller: _exerciseScroll,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_selectedMethod != null) ...[
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.carbon3,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.blueLight),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_selectedMethod!.name}\nEscolha um exercício compatível e revise as séries.',
                          style: AppTheme.bodyMd(color: AppColors.steelLight),
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('exercise-library-remove-method'),
                        tooltip: 'Remover método selecionado',
                        onPressed: () => setState(() => _selectedMethod = null),
                        icon: const Icon(Icons.close, color: AppColors.steel),
                      ),
                    ],
                  ),
                ),
              ],
              _searchField(
                controller: _searchController,
                label: 'Buscar exercício',
                hint: 'Nome, músculo ou equipamento',
                key: 'exercise-library-search',
              ),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      key: const ValueKey('exercise-library-filters'),
                      onPressed: () =>
                          setState(() => _filtersExpanded = !_filtersExpanded),
                      icon: const Icon(Icons.filter_list),
                      label: Text(
                        _filterCount == 0
                            ? 'Filtrar exercícios'
                            : 'Filtros ativos: $_filterCount',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.blueLight,
                        alignment: Alignment.centerLeft,
                        minimumSize: const Size(44, 48),
                      ),
                    ),
                  ),
                  if (_filterCount > 0)
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Limpar'),
                    ),
                ],
              ),
              if (_filtersExpanded) ...[
                _filter(
                  id: 'muscle',
                  label: 'Grupo muscular',
                  value: _selectedMuscle,
                  options: muscles,
                  onChanged: (value) => _selectedMuscle = value,
                  labels: const {'Todos': 'Todos os grupos'},
                ),
                const SizedBox(height: 12),
                _filter(
                  id: 'equipment',
                  label: 'Equipamento',
                  value: _selectedEquipment,
                  options: equipment,
                  onChanged: (value) => _selectedEquipment = value,
                  labels: const {'Todos': 'Todos os equipamentos'},
                ),
                const SizedBox(height: 12),
                _filter(
                  id: 'category',
                  label: 'Tipo de exercício',
                  value: _selectedCategory,
                  options: categories,
                  onChanged: (value) => _selectedCategory = value,
                  labels: {'Todos': 'Todos os tipos', ..._categoryNames},
                ),
                const SizedBox(height: 16),
              ],
              if (_filterCount > 0 && !_filtersExpanded)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    [
                      _selectedMuscle,
                      _selectedEquipment,
                      _categoryNames[_selectedCategory] ?? _selectedCategory,
                    ].where((value) => value != 'Todos').join(' · '),
                    style: AppTheme.bodyMd(color: AppColors.steel),
                  ),
                ),
              Semantics(
                liveRegion: true,
                child: Text(
                  '${filtered.length} ${filtered.length == 1 ? 'exercício encontrado' : 'exercícios encontrados'}',
                  style: AppTheme.bodyMd(color: AppColors.steel),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: _empty(
              title: 'Nenhum exercício encontrado',
              description:
                  'Tente outro nome ou remova os filtros para ver a biblioteca.',
              onClear: _clearFilters,
              key: 'exercise-library-clear-filters',
            ),
          )
        else
          SliverList.separated(
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, index) => _buildExercise(filtered[index]),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
      ],
    );
  }

  Widget _empty({
    required String title,
    required String description,
    required VoidCallback onClear,
    required String key,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        const Icon(Icons.search_off, size: 36, color: AppColors.steel),
        const SizedBox(height: 12),
        Text(title, textAlign: TextAlign.center, style: AppTheme.bodyLg()),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: AppTheme.bodyLg(color: AppColors.steel),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          key: ValueKey(key),
          onPressed: onClear,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.blueLight,
            minimumSize: const Size(44, 48),
          ),
          icon: const Icon(Icons.filter_alt_off_outlined),
          label: const Text('Limpar filtros'),
        ),
      ],
    ),
  );

  Widget _buildExercise(ExerciseLibraryItem item) => Material(
    color: AppColors.carbon3,
    borderRadius: BorderRadius.circular(12),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: ValueKey('exercise-library-item-${item.title}'),
      onTap: () => _choose(item),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: AppTheme.bodyLg()),
                  const SizedBox(height: 4),
                  Text(
                    [
                      item.muscle,
                      if (item.equipment != 'Não informado') item.equipment,
                      if (item.level != 'Não informado') item.level,
                      if (_category(item) != 'strength')
                        _categoryNames[_category(item)] ?? _category(item),
                    ].where((v) => v.isNotEmpty).join(' · '),
                    style: AppTheme.bodyMd(color: AppColors.blueLight),
                  ),
                  if (item.cue.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.cue,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyMd(color: AppColors.steel),
                    ),
                  ],
                  if (item.language == 'en') ...[
                    const SizedBox(height: 6),
                    Text(
                      'Conteúdo em inglês',
                      style: AppTheme.bodyMd(color: AppColors.steel),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, color: AppColors.steel),
          ],
        ),
      ),
    ),
  );

  Widget _buildMethods() {
    final words = _normalize(
      _methodSearchController.text,
    ).split(RegExp(r'\s+'));
    final methods = TrainingMethods.all.where((method) {
      final searchable = _normalize(
        [
          method.name,
          method.description,
          ...method.aliases,
          ...method.goals,
        ].join(' '),
      );
      return (_selectedGoal == 'Todos' ||
              method.goals.contains(_selectedGoal)) &&
          words.every(searchable.contains);
    }).toList();
    final goals =
        TrainingMethods.all.expand((method) => method.goals).toSet().toList()
          ..sort();
    return CustomScrollView(
      key: const PageStorageKey('exercise-library-method-results'),
      controller: _methodScroll,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _searchField(
                controller: _methodSearchController,
                label: 'Buscar método',
                hint: 'Pirâmide, cluster set, HIIT...',
                key: 'exercise-library-method-search',
              ),
              const SizedBox(height: 12),
              _filter(
                id: 'goal',
                label: 'Objetivo',
                value: _selectedGoal,
                options: goals,
                onChanged: (value) => _selectedGoal = value,
                labels: const {'Todos': 'Todos os objetivos'},
              ),
              const SizedBox(height: 12),
              Text(
                'Escolha uma estrutura e adapte as séries ao aluno.',
                style: AppTheme.bodyMd(color: AppColors.steel),
              ),
              if (_selectedGoal == 'Emagrecimento') ...[
                const SizedBox(height: 8),
                Text(
                  'Combine força e atividade aeróbica no planejamento. Nenhum método isolado garante emagrecimento.',
                  style: AppTheme.bodyMd(color: AppColors.steel),
                ),
              ],
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  '${methods.length} ${methods.length == 1 ? 'método encontrado' : 'métodos encontrados'}',
                  style: AppTheme.bodyMd(color: AppColors.steel),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        if (methods.isEmpty)
          SliverToBoxAdapter(
            child: _empty(
              title: 'Nenhum método encontrado',
              description: 'Busque outro nome ou explore todos os objetivos.',
              key: 'exercise-library-clear-method-filters',
              onClear: () {
                FocusScope.of(context).unfocus();
                _methodSearchController.clear();
                setState(() => _selectedGoal = 'Todos');
                if (_methodScroll.hasClients) _methodScroll.jumpTo(0);
              },
            ),
          )
        else
          SliverList.separated(
            itemCount: methods.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, index) => _buildMethod(methods[index]),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
      ],
    );
  }

  Widget _buildMethod(TrainingMethod method) {
    final expanded = _previewMethodId == method.id;
    return Material(
      color: AppColors.carbon3,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            key: ValueKey('exercise-library-method-${method.id}'),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(method.name, style: AppTheme.bodyLg()),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${method.level} · ${method.goals.join(' · ')}',
                style: AppTheme.bodyMd(color: AppColors.steel),
              ),
            ),
            trailing: Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              color: AppColors.steel,
            ),
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() => _previewMethodId = expanded ? null : method.id);
            },
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    method.description,
                    style: AppTheme.bodyLg(color: AppColors.steelLight),
                  ),
                  if (method.guidance.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      method.guidance,
                      style: AppTheme.bodyMd(color: AppColors.steel),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Estrutura inicial • você poderá editar',
                    style: AppTheme.bodyMd(color: AppColors.blueLight),
                  ),
                  const SizedBox(height: 8),
                  for (final (index, set) in method.sets.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '${index + 1}. ${set.replaceAll(RegExp(r'\[\w+\]'), '').trim()}',
                        style: AppTheme.bodyMd(color: AppColors.steel),
                      ),
                    ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: ValueKey('exercise-library-use-method-${method.id}'),
                    onPressed: () => _chooseMethod(method),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.paperBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(44, 48),
                    ),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Escolher exercício para este método'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
