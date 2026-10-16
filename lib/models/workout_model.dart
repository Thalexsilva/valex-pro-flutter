class Exercise {
  String title;
  String muscle;
  String cue;
  String video;
  String image;
  String mediaAttribution;
  String loadKg;
  List<String> sets;

  /// Descanso definido pelo instrutor. Nulo mantém prescrições antigas por série.
  int? restSeconds;

  String get videoUrl => video;
  set videoUrl(String val) => video = val;

  Exercise({
    required this.title,
    this.muscle = '',
    this.cue = '',
    this.video = '',
    String? videoUrl,
    this.image = '',
    this.mediaAttribution = '',
    this.loadKg = '',
    List<String>? sets,
    this.restSeconds,
  }) : sets = sets ?? ['12', '12', '10', '8'] {
    if (videoUrl != null && videoUrl.isNotEmpty) {
      video = videoUrl;
    }
  }

  Exercise copyWith({
    String? title,
    String? muscle,
    String? cue,
    String? video,
    String? image,
    String? mediaAttribution,
    String? loadKg,
    List<String>? sets,
    int? restSeconds,
  }) {
    return Exercise(
      title: title ?? this.title,
      muscle: muscle ?? this.muscle,
      cue: cue ?? this.cue,
      video: video ?? this.video,
      image: image ?? this.image,
      mediaAttribution: mediaAttribution ?? this.mediaAttribution,
      loadKg: loadKg ?? this.loadKg,
      sets: sets != null ? List.from(sets) : List.from(this.sets),
      restSeconds: restSeconds ?? this.restSeconds,
    );
  }

  Exercise deepCopy() => Exercise.fromJson(toJson());

  int restSecondsForSet(int index) {
    if (restSeconds != null) return restSeconds!.clamp(0, 600);
    if (index >= 0 && index < sets.length) {
      final match = RegExp(
        r'descanso\s*(\d+)\s*s',
        caseSensitive: false,
      ).firstMatch(sets[index]);
      final prescribed = int.tryParse(match?.group(1) ?? '');
      if (prescribed != null) return prescribed.clamp(0, 600);
    }
    return 60;
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'muscle': muscle,
    'cue': cue,
    'video': video,
    'image': image,
    if (mediaAttribution.isNotEmpty) 'mediaAttribution': mediaAttribution,
    'loadKg': loadKg,
    'sets': List<String>.from(sets),
    if (restSeconds != null) 'restSeconds': restSeconds,
  };

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      title: json['title'] as String? ?? 'Exercício',
      muscle: json['muscle'] as String? ?? '',
      cue: json['cue'] as String? ?? '',
      video: json['video'] as String? ?? json['videoUrl'] as String? ?? '',
      image: json['image'] as String? ?? '',
      mediaAttribution: json['mediaAttribution'] as String? ?? '',
      loadKg: json['loadKg'] as String? ?? '',
      sets:
          (json['sets'] as List?)?.map((e) => e.toString()).toList() ??
          ['12', '12', '10', '8'],
      restSeconds: int.tryParse(json['restSeconds']?.toString() ?? ''),
    );
  }
}

typedef WorkoutExercise = Exercise;

/// Replica a heurística de `resolveExerciseMuscle` de `js/ui-editor.js`:
/// usa `ex.muscle` quando definido; caso contrário infere pelo título via
/// palavras-chave, igual ao legado, em vez de herdar o rótulo combinado
/// do dia (ex.: "Peito e Tríceps"), que mistura grupos musculares distintos
/// no resumo de volume.
String resolveExerciseMuscleCategory(Exercise ex) {
  final declared = ex.muscle.trim();
  if (declared.isNotEmpty &&
      declared != 'Geral' &&
      declared != 'Personalizado') {
    return declared;
  }

  final t = ex.title.trim().toLowerCase();
  if (t.isEmpty) return 'Outros';

  bool any(List<String> needles) => needles.any((n) => t.contains(n));

  if (any([
    'supino',
    'peck deck',
    'crucifixo',
    'flexão de braço',
    'cross over',
  ])) {
    return 'Peito';
  }
  if (any(['puxada', 'remada', 'pulldown', 'barra fixa', 'dorsal'])) {
    return 'Costas';
  }
  if (any([
    'desenvolvimento',
    'elevação lateral',
    'elevação frontal',
    'ombro',
    'deltoide',
    'trapezoide',
    'encolhimento',
  ])) {
    return 'Ombros';
  }
  if (any(['rosca', 'bíceps', 'biceps', 'scott', 'concentrada', 'martelo'])) {
    return 'Bíceps';
  }
  if (any(['tríceps', 'triceps', 'testa', 'francesa', 'paralela'])) {
    return 'Tríceps';
  }
  if (any([
    'agachamento',
    'leg press',
    'extensora',
    'afundo',
    'hack',
    'sissy',
  ])) {
    return 'Quadríceps';
  }
  if (any(['glúteo', 'gluteo', 'pélvica', 'pelvica', 'abdução', 'abductor'])) {
    return 'Glúteos';
  }
  if (any(['stiff', 'flexora', 'posterior', 'romeno', 'good morning'])) {
    return 'Posterior';
  }
  if (any(['panturrilha', 'gêmeos', 'gemeos'])) {
    return 'Panturrilha';
  }
  if (any(['abdominal', 'infra', 'supra', 'prancha', 'vacuum', 'core'])) {
    return 'Abdômen';
  }
  if (any([
    'esteira',
    'escada',
    'bike',
    'remo',
    'cardio',
    'hiit',
    'elíptico',
  ])) {
    return 'Cardio';
  }
  return 'Outros';
}

class WorkoutDay {
  String dow; // e.g. "Treino A"
  String muscle; // e.g. "Peito e Tríceps"
  String icon;
  bool cardio;
  List<Exercise> exercises;

  WorkoutDay({
    required this.dow,
    required this.muscle,
    this.icon = 'chest',
    this.cardio = true,
    List<Exercise>? exercises,
  }) : exercises = exercises ?? [];

  WorkoutDay copyWith({
    String? dow,
    String? muscle,
    String? icon,
    bool? cardio,
    List<Exercise>? exercises,
  }) {
    return WorkoutDay(
      dow: dow ?? this.dow,
      muscle: muscle ?? this.muscle,
      icon: icon ?? this.icon,
      cardio: cardio ?? this.cardio,
      exercises: exercises != null
          ? exercises.map((e) => e.copyWith()).toList()
          : this.exercises.map((e) => e.copyWith()).toList(),
    );
  }

  WorkoutDay deepCopy() => WorkoutDay.fromJson(toJson());

  Map<String, dynamic> toJson() => {
    'dow': dow,
    'muscle': muscle,
    'icon': icon,
    'cardio': cardio,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    return WorkoutDay(
      dow: json['dow'] as String? ?? 'Treino',
      muscle: json['muscle'] as String? ?? 'Geral',
      icon: json['icon'] as String? ?? 'fitness',
      cardio: json['cardio'] as bool? ?? true,
      exercises:
          (json['exercises'] as List?)
              ?.map((e) => Exercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class WorkoutSheet {
  String studentId;
  String studentName;
  String gymName;
  String month;
  String teacher;
  String instructorNotes;
  String currentVersionName;
  List<WorkoutDay> days;
  List<String> cardioOptions;
  List<String> generalNotes;

  WorkoutSheet({
    required this.studentId,
    required this.studentName,
    this.gymName = '',
    this.month = '',
    this.teacher = 'Prof. Valesca',
    this.instructorNotes = '',
    this.currentVersionName = 'v1 - Original',
    List<WorkoutDay>? days,
    List<String>? cardioOptions,
    List<String>? generalNotes,
  }) : days = days ?? [],
       cardioOptions = cardioOptions ?? [],
       generalNotes = generalNotes ?? [];

  WorkoutSheet copyWith({
    String? studentId,
    String? studentName,
    String? gymName,
    String? month,
    String? teacher,
    String? instructorNotes,
    List<WorkoutDay>? days,
    List<String>? cardioOptions,
    List<String>? generalNotes,
  }) {
    return WorkoutSheet(
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      gymName: gymName ?? this.gymName,
      month: month ?? this.month,
      teacher: teacher ?? this.teacher,
      instructorNotes: instructorNotes ?? this.instructorNotes,
      days: days != null
          ? days.map((d) => d.copyWith()).toList()
          : this.days.map((d) => d.copyWith()).toList(),
      cardioOptions: cardioOptions != null
          ? List.from(cardioOptions)
          : List.from(this.cardioOptions),
      generalNotes: generalNotes != null
          ? List.from(generalNotes)
          : List.from(this.generalNotes),
    );
  }

  WorkoutSheet deepCopy() => WorkoutSheet.fromJson(toJson());

  Map<String, dynamic> get volumeSummary {
    int totalEx = 0;
    int totalSets = 0;
    double totalTonnageKg = 0;
    final Map<String, int> muscleSets = {};
    final Map<String, double> muscleTonnage = {};

    for (var day in days) {
      for (var ex in day.exercises) {
        totalEx++;
        final setsCount = ex.sets.length;
        totalSets += setsCount;

        final m = resolveExerciseMuscleCategory(ex);
        muscleSets[m] = (muscleSets[m] ?? 0) + setsCount;

        double baseKg = double.tryParse(ex.loadKg.replaceAll(',', '.')) ?? 0;
        double exTonnage = 0;
        for (var s in ex.sets) {
          final setKgMatch = RegExp(
            r'(\d+[\.,]?\d*)\s*kg',
            caseSensitive: false,
          ).firstMatch(s);
          if (setKgMatch != null) {
            final parsedKg =
                double.tryParse(setKgMatch.group(1)!.replaceAll(',', '.')) ??
                baseKg;
            exTonnage += parsedKg > 0 ? parsedKg : baseKg;
          } else {
            exTonnage += baseKg;
          }
        }
        totalTonnageKg += exTonnage;
        muscleTonnage[m] = (muscleTonnage[m] ?? 0) + exTonnage;
      }
    }

    return {
      'totalEx': totalEx,
      'totalSets': totalSets,
      'totalTonnageKg': totalTonnageKg,
      'muscleSets': muscleSets,
      'muscleTonnage': muscleTonnage,
    };
  }

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'studentName': studentName,
    'gym_name': gymName,
    'month': month,
    'teacher': teacher,
    'instructorNotes': instructorNotes,
    'currentVersionName': currentVersionName,
    'days': days.map((d) => d.toJson()).toList(),
    'cardioOptions': List<String>.from(cardioOptions),
    'general_notes': List<String>.from(generalNotes),
  };

  factory WorkoutSheet.fromJson(Map<String, dynamic> json) {
    return WorkoutSheet(
      studentId: json['studentId'] as String? ?? '',
      studentName: json['studentName'] as String? ?? 'Aluno',
      gymName: json['gym_name'] as String? ?? json['academia'] as String? ?? '',
      month: json['month'] as String? ?? json['mes'] as String? ?? '',
      teacher:
          json['teacher'] as String? ??
          json['student']?['teacher'] as String? ??
          'Prof. Valesca',
      instructorNotes: json['instructorNotes'] as String? ?? '',
      currentVersionName:
          json['currentVersionName'] as String? ?? 'v1 - Original',
      days:
          (json['days'] as List?)
              ?.map((d) => WorkoutDay.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      cardioOptions:
          (json['cardioOptions'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      generalNotes:
          (json['general_notes'] as List?)?.map((e) => e.toString()).toList() ??
          (json['observacoes'] as List?)?.map((e) => e.toString()).toList() ??
          [],
    );
  }
}
