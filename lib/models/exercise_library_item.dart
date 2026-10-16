/// Metadados da biblioteca, separados da prescrição do aluno.
class ExerciseLibraryItem {
  final String id;
  final String title;
  final String muscle;
  final String cue;
  final String video;
  final String animationUrl;
  final String equipment;
  final String level;
  final String category;
  final String source;
  final String language;
  final List<String> aliases;
  final List<String> instructions;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;

  const ExerciseLibraryItem({
    this.id = '',
    required this.title,
    required this.muscle,
    required this.cue,
    this.video = '',
    this.animationUrl = '',
    this.equipment = 'Não informado',
    this.level = 'Não informado',
    this.category = '',
    this.source = 'VALEX',
    this.language = 'pt-BR',
    this.aliases = const [],
    this.instructions = const [],
    this.primaryMuscles = const [],
    this.secondaryMuscles = const [],
  });

  factory ExerciseLibraryItem.fromJson(Map<String, dynamic> json) =>
      ExerciseLibraryItem(
        id: json['id'] as String,
        title: json['title'] as String,
        muscle: json['muscle'] as String,
        cue: json['cue'] as String? ?? '',
        video: json['video'] as String? ?? '',
        animationUrl: json['animationUrl'] as String? ?? '',
        equipment: json['equipment'] as String? ?? 'Não informado',
        level: json['level'] as String? ?? 'Não informado',
        category: json['category'] as String? ?? '',
        source: json['source'] as String? ?? 'VALEX',
        language: json['language'] as String? ?? 'pt-BR',
        aliases: List<String>.from(json['aliases'] as List? ?? []),
        instructions: List<String>.from(json['instructions'] as List? ?? []),
        primaryMuscles: List<String>.from(
          json['primaryMuscles'] as List? ?? [],
        ),
        secondaryMuscles: List<String>.from(
          json['secondaryMuscles'] as List? ?? [],
        ),
      );

  Map<String, dynamic> toJson({bool includeInstructions = true}) => {
    'id': id,
    'title': title,
    'muscle': muscle,
    'cue': cue,
    'video': video,
    if (animationUrl.isNotEmpty) 'animationUrl': animationUrl,
    'equipment': equipment,
    'level': level,
    'category': category,
    'source': source,
    'language': language,
    'aliases': aliases,
    'primaryMuscles': primaryMuscles,
    'secondaryMuscles': secondaryMuscles,
    if (includeInstructions) 'instructions': instructions,
  };

  /// The pinned source contains two photographs for every older upstream ID.
  /// Its three newer kettlebell records and VALEX-only records have no photos.
  List<String> get images {
    if (id.isEmpty ||
        id.startsWith('valex-') ||
        id.startsWith('gymvisual-') ||
        id == 'Kettlebell_Halo' ||
        id == 'Kettlebell_Halo_With_Overhead_Extension' ||
        id == 'Kettlebell_Overhead_Triceps_Extension') {
      return const [];
    }
    const base =
        'https://raw.githubusercontent.com/yuhonas/free-exercise-db/'
        'a859101d633a01c4a1a920d6a8ce41dabba0705f/exercises/';
    final path = Uri.encodeComponent(id);
    return ['$base$path/0.jpg', '$base$path/1.jpg'];
  }

  String get categoryLabel => switch (category) {
    'cardio' => 'Cardio',
    'stretching' => 'Mobilidade e alongamento',
    'plyometrics' => 'Pliometria',
    'olympic weightlifting' => 'Levantamento olímpico',
    'powerlifting' => 'Levantamento de potência',
    'strongman' => 'Strongman',
    _ => 'Musculação',
  };

  static String normalize(String value) {
    const accents = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const letters = 'aaaaaeeeeiiiiooooouuuuc';
    var result = value.toLowerCase().trim();
    for (var i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], letters[i]);
    }
    return result;
  }

  bool matchesSearch(String query) {
    final searchable = normalize(
      [
        title,
        muscle,
        equipment,
        categoryLabel,
        ...aliases,
        ...primaryMuscles,
        ...secondaryMuscles,
      ].join(' '),
    );
    return normalize(query).split(RegExp(r'\s+')).every(searchable.contains);
  }
}

typedef ExerciseLibItem = ExerciseLibraryItem;
