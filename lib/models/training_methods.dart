class TrainingMethod {
  final String id;
  final String name;
  final String icon;
  final String description;
  final String category; // musculacao, cardio ou mobilidade
  final List<String> goals;
  final String level;
  final String guidance;
  final List<String> aliases;
  final bool requiresCompanionExercises;
  final bool requiresPosition;
  final List<String> exerciseKeywords;
  final List<String> sets;

  const TrainingMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.category,
    required this.sets,
    this.goals = const [],
    this.level = 'Intermediário',
    this.guidance = '',
    this.aliases = const [],
    this.requiresCompanionExercises = false,
    this.requiresPosition = false,
    this.exerciseKeywords = const [],
  });

  String get dropdownLabel => icon.isEmpty ? name : '$icon $name';

  factory TrainingMethod.fromJson(Map<String, dynamic> json) => TrainingMethod(
    id: json['id'] as String,
    name: json['name'] as String,
    icon: json['icon'] as String? ?? '',
    description: json['description'] as String,
    category: json['category'] as String,
    sets: List<String>.from(json['sets'] as List),
    goals: List<String>.from(json['goals'] as List? ?? []),
    level: json['level'] as String? ?? 'Intermediário',
    guidance: json['guidance'] as String? ?? '',
    aliases: List<String>.from(json['aliases'] as List? ?? []),
    requiresCompanionExercises: json['requiresCompanionExercises'] == true,
    requiresPosition: json['requiresPosition'] == true,
    exerciseKeywords: List<String>.from(
      json['exerciseKeywords'] as List? ?? [],
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'description': description,
    'category': category,
    'sets': sets,
    'goals': goals,
    'level': level,
    'guidance': guidance,
    'aliases': aliases,
    'requiresCompanionExercises': requiresCompanionExercises,
    'requiresPosition': requiresPosition,
    'exerciseKeywords': exerciseKeywords,
  };
}

class TrainingMethods {
  TrainingMethods._();

  static List<TrainingMethod> _all = const [];
  static List<TrainingMethod> get all => _all;

  /// Installed together with a validated catalog release by CatalogService.
  static void install(List<TrainingMethod> methods) {
    _all = List.unmodifiable(methods);
  }

  /// Uses the source category before falling back to legacy muscle labels.
  static String categoryForExercise(String category, {String muscle = ''}) {
    final normalized = category.trim().toLowerCase();
    if (normalized == 'stretching' || normalized == 'mobilidade') {
      return 'mobilidade';
    }
    if (normalized == 'cardio') return 'cardio';
    if (normalized.isNotEmpty) return 'musculacao';
    final legacyMuscle = muscle.trim().toLowerCase();
    if (legacyMuscle == 'cardio' ||
        legacyMuscle == 'aeróbico' ||
        legacyMuscle == 'aerobico') {
      return 'cardio';
    }
    return 'musculacao';
  }

  static bool isCompatibleWithExercise(
    TrainingMethod method,
    String category, {
    String muscle = '',
    String title = '',
    String equipment = '',
  }) {
    if (method.category != categoryForExercise(category, muscle: muscle)) {
      return false;
    }
    if (method.exerciseKeywords.isEmpty) return true;
    final words = '$title $equipment'.toLowerCase().split(
      RegExp(r'[^a-zá-ú]+'),
    );
    return method.exerciseKeywords.any(words.contains);
  }

  static TrainingMethod getMethod(String methodId) {
    if (all.isEmpty) {
      throw StateError('Carregue a biblioteca antes de escolher um método.');
    }
    return all.firstWhere((m) => m.id == methodId, orElse: () => all.first);
  }

  static List<String> generateSetsForMethod(String methodId) {
    return List<String>.from(getMethod(methodId).sets);
  }
}
