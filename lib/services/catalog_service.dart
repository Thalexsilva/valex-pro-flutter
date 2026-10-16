import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/exercise_library_item.dart';
import '../models/catalog_media_item.dart';
import '../models/training_methods.dart';

abstract class CatalogSource {
  Future<Map<String, dynamic>> release();
  Future<List<Map<String, dynamic>>> exercises(
    String version,
    int from,
    int to,
  );
  Future<List<Map<String, dynamic>>> methods(String version);
  Future<List<String>> instructions(String version, String id);
  Future<Map<String, dynamic>?> mediaForExercise(String id) async => null;
  Future<List<Map<String, dynamic>>> searchMedia(String query) async =>
      const [];
  Future<List<Map<String, dynamic>>> trainerExercises(String trainerId) async =>
      const [];
}

class SupabaseCatalogSource implements CatalogSource {
  SupabaseCatalogSource({this.client});
  final SupabaseClient? client;
  SupabaseClient get _client => client ?? SupabaseConfig.client;
  @override
  Future<Map<String, dynamic>> release() => _client
      .from('catalog_releases')
      .select('version, exercise_count, method_count')
      .eq('active', true)
      .single();

  @override
  Future<List<Map<String, dynamic>>> exercises(
    String version,
    int from,
    int to,
  ) async {
    final rows = await _client
        .from('catalog_exercises')
        .select('summary')
        .eq('release_version', version)
        .order('sort_order', ascending: true)
        .range(from, to);
    return rows
        .map((row) => Map<String, dynamic>.from(row['summary'] as Map))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> methods(String version) async {
    final rows = await _client
        .from('catalog_training_methods')
        .select('content')
        .eq('release_version', version)
        .order('sort_order', ascending: true);
    return rows
        .map((row) => Map<String, dynamic>.from(row['content'] as Map))
        .toList();
  }

  @override
  Future<List<String>> instructions(String version, String id) async {
    final row = await _client
        .from('catalog_exercises')
        .select('instructions')
        .eq('release_version', version)
        .eq('id', id)
        .single();
    return List<String>.from(row['instructions'] as List);
  }

  @override
  Future<Map<String, dynamic>?> mediaForExercise(String id) async {
    final rows = await _client
        .from('catalog_exercise_media')
        .select('id,name,equipment,thumbnail_url,animation_url,attribution')
        .eq('catalog_exercise_id', id)
        .limit(1);
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  @override
  Future<List<Map<String, dynamic>>> searchMedia(String query) async {
    final rows = await _client
        .from('catalog_exercise_media')
        .select('id,name,equipment,thumbnail_url,animation_url,attribution')
        .ilike('search_name', '%$query%')
        .order('name')
        .limit(20);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> trainerExercises(String trainerId) async {
    final rows = await _client
        .from('trainer_exercises')
        .select('id,title')
        .eq('trainer_id', trainerId)
        .order('title');
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }
}

abstract class CatalogCache {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class PreferencesCatalogCache implements CatalogCache {
  @override
  Future<String?> read(String key) async =>
      (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> write(String key, String value) async {
    await (await SharedPreferences.getInstance()).setString(key, value);
  }
}

/// Public reference data. No student records or authentication tokens are cached here.
/// Summaries load on first library use; full instructions are fetched individually.
class CatalogService extends ChangeNotifier {
  static CatalogService instance = CatalogService(
    source: SupabaseCatalogSource(),
    cache: PreferencesCatalogCache(),
  );

  CatalogService({required this.source, required this.cache});

  @visibleForTesting
  factory CatalogService.seeded(
    List<ExerciseLibraryItem> items,
    List<TrainingMethod> methods,
  ) {
    final service = CatalogService(
      source: SupabaseCatalogSource(),
      cache: PreferencesCatalogCache(),
    );
    service._items = List.unmodifiable(items);
    service._rebuildItems();
    service._methods = List.unmodifiable(methods);
    service._seeded = true;
    TrainingMethods.install(methods);
    return service;
  }

  final CatalogSource source;
  final CatalogCache cache;
  List<ExerciseLibraryItem> _items = const [];
  List<ExerciseLibraryItem> _trainerItems = const [];
  List<ExerciseLibraryItem> _combinedItems = const [];
  String? _loadedTrainerId;
  List<TrainingMethod> _methods = const [];
  String? _version;
  Map<String, dynamic>? _manifest;
  Future<bool>? _pending;
  DateTime? _lastCheck;
  bool _cacheRead = false;
  bool _seeded = false;
  bool loading = false;
  bool usingCachedCopy = false;
  String? error;
  final Map<String, List<String>> _details = {};
  final Map<String, Future<CatalogMediaItem?>> _media = {};
  final Map<String, Future<List<String>>> _pendingDetails = {};
  Future<void>? _detailsRestored;
  Future<void> _detailWrites = Future.value();

  List<ExerciseLibraryItem> get items => _combinedItems;
  bool get isReady => _items.isNotEmpty && _methods.isNotEmpty;
  String? get version => _version;
  String get _cacheKey => 'public_catalog_v2:${SupabaseConfig.url}';

  Future<bool> ensureLoaded({bool force = false}) {
    if (_seeded) return Future.value(true);
    if (_pending != null) return _pending!;
    return _pending = _refresh(force).whenComplete(() => _pending = null);
  }

  Future<bool> _refresh(bool force) async {
    final trainerId = SupabaseConfig.hasAuthenticatedUser
        ? SupabaseConfig.client.auth.currentUser?.id
        : null;
    if (trainerId != _loadedTrainerId || force) {
      _loadedTrainerId = trainerId;
      _trainerItems = const [];
      _rebuildItems();
      notifyListeners();
      if (trainerId != null) {
        try {
          final rows = await source
              .trainerExercises(trainerId)
              .timeout(const Duration(seconds: 12));
          _trainerItems = List.unmodifiable(
            rows.map(
              (row) => ExerciseLibraryItem(
                id: 'trainer-${row['id']}',
                title: row['title'] as String,
                muscle: 'Outros',
                cue: '',
                source: 'Meu acervo',
              ),
            ),
          );
          _rebuildItems();
          notifyListeners();
        } catch (_) {
          _loadedTrainerId = null;
        }
      }
    }
    if (!force &&
        isReady &&
        _lastCheck != null &&
        DateTime.now().difference(_lastCheck!) < const Duration(minutes: 15)) {
      return Future.value(true);
    }
    return _load();
  }

  void _rebuildItems() {
    final publicTitles = _items
        .map((item) => ExerciseLibraryItem.normalize(item.title))
        .toSet();
    _combinedItems = List.unmodifiable([
      ..._items,
      ..._trainerItems.where(
        (item) =>
            !publicTitles.contains(ExerciseLibraryItem.normalize(item.title)),
      ),
    ]);
  }

  Future<bool> _load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      if (!_cacheRead) {
        _cacheRead = true;
        try {
          final raw = await cache.read(_cacheKey);
          if (raw != null) {
            _install(Map<String, dynamic>.from(jsonDecode(raw) as Map));
            usingCachedCopy = true;
            notifyListeners();
          }
        } catch (_) {
          // A missing, obsolete or corrupt cache is replaced by a complete release.
        }
      }
      final release = await source.release().timeout(
        const Duration(seconds: 12),
      );
      final version = release['version'] as String;
      if (version != _version || !isReady) {
        final count = release['exercise_count'] as int;
        if (count < 1 || count > 20000) {
          throw const FormatException('Invalid catalog count');
        }
        final pages = <Future<List<Map<String, dynamic>>>>[
          for (var offset = 0; offset < count; offset += 500)
            source
                .exercises(version, offset, offset + 499)
                .timeout(const Duration(seconds: 20)),
        ];
        final results = await Future.wait([
          Future.wait(
            pages,
          ).then((pages) => pages.expand((page) => page).toList()),
          source.methods(version).timeout(const Duration(seconds: 20)),
        ]);
        final snapshot = <String, dynamic>{
          'release': release,
          'exercises': results[0],
          'methods': results[1],
        };
        _install(snapshot);
        try {
          // Instructions never enter the bulk snapshot, even if supplied by a source.
          await cache.write(
            _cacheKey,
            jsonEncode({
              'release': _manifest,
              'exercises': _items
                  .map((item) => item.toJson(includeInstructions: false))
                  .toList(),
              'methods': _methods.map((method) => method.toJson()).toList(),
            }),
          );
        } catch (_) {
          // A full browser/device cache must not prevent using downloaded data.
        }
      }
      usingCachedCopy = false;
      _lastCheck = DateTime.now();
    } catch (_) {
      usingCachedCopy = isReady;
      error = isReady
          ? 'Usando a biblioteca salva neste dispositivo. Não foi possível verificar atualizações.'
          : 'Não foi possível carregar a biblioteca. Verifique sua conexão e tente novamente.';
    } finally {
      loading = false;
      notifyListeners();
    }
    return isReady;
  }

  void _install(Map<String, dynamic> snapshot) {
    final release = Map<String, dynamic>.from(snapshot['release'] as Map);
    final exercises = (snapshot['exercises'] as List)
        .map(
          (item) => ExerciseLibraryItem.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
    final methods = (snapshot['methods'] as List)
        .map(
          (item) =>
              TrainingMethod.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    if ((release['version'] as String).isEmpty ||
        exercises.isEmpty ||
        methods.isEmpty ||
        exercises.length != release['exercise_count'] ||
        methods.length != release['method_count'] ||
        exercises.map((item) => item.id).toSet().length != exercises.length ||
        methods.map((item) => item.id).toSet().length != methods.length ||
        exercises.any((item) => item.id.isEmpty || item.title.isEmpty) ||
        methods.any((item) => item.id.isEmpty || item.sets.isEmpty)) {
      throw const FormatException('Incomplete catalog release');
    }
    _manifest = release;
    _version = release['version'] as String;
    _items = List.unmodifiable(exercises);
    _rebuildItems();
    _methods = List.unmodifiable(methods);
    TrainingMethods.install(methods);
  }

  Future<List<String>> instructionsFor(ExerciseLibraryItem item) async {
    if (item.instructions.isNotEmpty || _seeded) return item.instructions;
    if (item.id.startsWith('trainer-')) return const [];
    final releaseVersion = _version;
    if (releaseVersion == null || item.id.isEmpty) return const [];
    final key = '$releaseVersion:${item.id}';
    await (_detailsRestored ??= _restoreDetails());
    if (_details.containsKey(key)) return _details[key]!;
    return _pendingDetails.putIfAbsent(
      key,
      () => _loadInstructions(releaseVersion, item.id, key).whenComplete(() {
        _pendingDetails.remove(key);
      }),
    );
  }

  Future<CatalogMediaItem?> mediaFor(ExerciseLibraryItem item) {
    if (item.id.isEmpty || item.id.startsWith('trainer-')) {
      return Future.value(null);
    }
    return _media.putIfAbsent(item.id, () async {
      try {
        final row = await source
            .mediaForExercise(item.id)
            .timeout(const Duration(seconds: 12));
        return row == null ? null : CatalogMediaItem.fromJson(row);
      } catch (_) {
        _media.remove(item.id);
        return null;
      }
    });
  }

  Future<List<CatalogMediaItem>> searchMedia(String query) async {
    final normalized = ExerciseLibraryItem.normalize(
      query,
    ).replaceAll(RegExp(r'[^a-z0-9 ]'), ' ').trim();
    if (normalized.length < 3) return const [];
    final rows = await source
        .searchMedia(normalized)
        .timeout(const Duration(seconds: 12));
    return rows.map(CatalogMediaItem.fromJson).toList();
  }

  Future<void> _restoreDetails() async {
    try {
      final raw = await cache.read('$_cacheKey:details');
      if (raw == null) return;
      final values = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      for (final entry in values.entries.take(100)) {
        _details[entry.key] = List<String>.unmodifiable(entry.value as List);
      }
    } catch (_) {
      _details.clear();
    }
  }

  Future<List<String>> _loadInstructions(
    String version,
    String id,
    String key,
  ) async {
    final steps = List<String>.unmodifiable(
      await source
          .instructions(version, id)
          .timeout(const Duration(seconds: 12)),
    );
    _details[key] = steps;
    while (_details.length > 100) {
      _details.remove(_details.keys.first);
    }
    // Serialize writes so concurrent selections cannot overwrite a newer cache.
    _detailWrites = _detailWrites.then((_) async {
      try {
        await cache.write('$_cacheKey:details', jsonEncode(_details));
      } catch (_) {}
    });
    await _detailWrites;
    return steps;
  }
}
