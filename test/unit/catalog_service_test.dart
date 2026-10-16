import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:valex_app/services/catalog_service.dart';
import 'package:valex_app/models/workout_model.dart';

class MemoryCache implements CatalogCache {
  final data = <String, String>{};
  bool failWrites = false;
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw StateError('Storage full');
    data[key] = value;
  }
}

class FakeCatalog extends CatalogSource {
  int count = 501;
  String version = 'v1';
  bool offline = false;
  bool incomplete = false;
  int releaseCalls = 0;
  int detailCalls = 0;
  final ranges = <(int, int)>[];
  Completer<void>? gate;
  @override
  Future<Map<String, dynamic>> release() async {
    releaseCalls++;
    if (gate != null) await gate!.future;
    if (offline) throw StateError('Offline');
    return {'version': version, 'exercise_count': count, 'method_count': 1};
  }

  @override
  Future<List<Map<String, dynamic>>> exercises(
    String version,
    int from,
    int to,
  ) async {
    ranges.add((from, to));
    return [
      for (var i = from; i <= to && i < count - (incomplete ? 1 : 0); i++)
        {
          'id': 'exercise-$i',
          'title': 'Exercício $i',
          'muscle': 'Peito',
          'cue': 'Orientação curta',
        },
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> methods(String version) async => [
    {
      'id': 'tradicional',
      'name': 'Tradicional',
      'description': 'Séries normais',
      'category': 'musculacao',
      'sets': ['[work]8 a 12 reps'],
    },
  ];
  @override
  Future<List<String>> instructions(String version, String id) async {
    detailCalls++;
    if (offline) throw StateError('Offline');
    return ['Instrução completa de $id'];
  }
}

void main() {
  test('private exercise query is scoped to the signed-in trainer', () async {
    http.Request? seen;
    final client = SupabaseClient(
      'https://catalog.example.test',
      'public-test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        seen = request;
        return http.Response(
          jsonEncode([
            {'id': 'one', 'title': 'Exercício particular'},
          ]),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    final rows = await SupabaseCatalogSource(
      client: client,
    ).trainerExercises('trainer-one');
    expect(rows.single['title'], 'Exercício particular');
    expect(seen?.url.path, '/rest/v1/trainer_exercises');
    expect(seen?.url.queryParameters['trainer_id'], 'eq.trainer-one');
  });

  test(
    'media is queried on demand and attribution survives a saved workout',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://catalog.example.test',
        'public-test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode([
              {
                'id': '0025',
                'name': 'barbell bench press',
                'equipment': 'barbell',
                'thumbnail_url': 'https://example.test/bench.jpg',
                'animation_url': 'https://example.test/bench.gif',
                'attribution': '© Gym visual — https://gymvisual.com/',
              },
            ]),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      final source = SupabaseCatalogSource(client: client);
      final row = await source.mediaForExercise('Barbell_Bench_Press');
      expect(row?['animation_url'], 'https://example.test/bench.gif');
      expect(requests.single.url.path, '/rest/v1/catalog_exercise_media');
      expect(
        requests.single.url.queryParameters['catalog_exercise_id'],
        'eq.Barbell_Bench_Press',
      );
      final exercise = Exercise(
        title: 'Supino',
        image: row!['animation_url'] as String,
        mediaAttribution: row['attribution'] as String,
      );
      expect(
        exercise.deepCopy().mediaAttribution,
        '© Gym visual — https://gymvisual.com/',
      );
    },
  );

  test(
    'Supabase queries keep curated order and fetch instructions separately',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://catalog.example.test',
        'public-test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          requests.add(request);
          final select = request.url.queryParameters['select'];
          final body = switch (select) {
            'summary' => [
              {
                'summary': {
                  'id': 'exercise-0',
                  'title': 'Supino',
                  'muscle': 'Peito',
                },
              },
            ],
            'content' => [
              {
                'content': {'id': 'tradicional'},
              },
            ],
            'instructions' => {
              'instructions': ['Primeira orientação'],
            },
            _ => {'version': 'v1', 'exercise_count': 1, 'method_count': 1},
          };
          return http.Response(
            jsonEncode(body),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      final source = SupabaseCatalogSource(client: client);
      await source.release();
      await source.exercises('v1', 500, 999);
      await source.methods('v1');
      expect(requests[0].url.queryParameters['active'], 'eq.true');
      for (final request in requests.skip(1)) {
        expect(
          request.url.queryParameters['order'],
          startsWith('sort_order.asc'),
        );
        expect(request.url.queryParameters['release_version'], 'eq.v1');
        expect(
          request.url.queryParameters['select'],
          isNot(contains('instructions')),
        );
      }
      expect(requests[1].url.queryParameters['offset'], '500');
      expect(requests[1].url.queryParameters['limit'], '500');
      expect(await source.instructions('v1', 'exercise-0'), [
        'Primeira orientação',
      ]);
      expect(requests.last.url.queryParameters['id'], 'eq.exercise-0');
    },
  );

  test(
    'loads on demand, pages summaries and deduplicates concurrent requests',
    () async {
      final source = FakeCatalog()..gate = Completer<void>();
      final cache = MemoryCache();
      final service = CatalogService(source: source, cache: cache);
      expect(source.releaseCalls, 0);
      final first = service.ensureLoaded();
      final second = service.ensureLoaded();
      expect(identical(first, second), isTrue);
      source.gate!.complete();
      expect(await first, isTrue);
      expect(source.releaseCalls, 1);
      expect(source.ranges, [(0, 499), (500, 999)]);
      expect(service.items.length, 501);
      expect(source.detailCalls, 0);
      final stored = jsonDecode(cache.data.values.single) as Map;
      expect(
        (stored['exercises'] as List).every(
          (item) => !(item as Map).containsKey('instructions'),
        ),
        isTrue,
      );
      await service.ensureLoaded();
      expect(source.releaseCalls, 1);
    },
  );

  test(
    'downloads instructions only on request and reuses them offline after restart',
    () async {
      final source = FakeCatalog()..count = 2;
      final cache = MemoryCache();
      final service = CatalogService(source: source, cache: cache);
      await service.ensureLoaded();
      final details = await Future.wait([
        service.instructionsFor(service.items.first),
        service.instructionsFor(service.items.first),
      ]);
      expect(details.first, ['Instrução completa de exercise-0']);
      expect(source.detailCalls, 1);
      source.offline = true;
      final restarted = CatalogService(source: source, cache: cache);
      expect(await restarted.ensureLoaded(), isTrue);
      expect(restarted.usingCachedCopy, isTrue);
      expect(
        await restarted.instructionsFor(restarted.items.first),
        details.first,
      );
      expect(source.detailCalls, 1);
      await expectLater(
        restarted.instructionsFor(restarted.items.last),
        throwsStateError,
      );
    },
  );

  test('retains the complete release when an update is incomplete', () async {
    final source = FakeCatalog()..count = 2;
    final cache = MemoryCache();
    final service = CatalogService(source: source, cache: cache);
    await service.ensureLoaded();
    final oldCache = Map.of(cache.data);
    source
      ..version = 'v2'
      ..incomplete = true;
    expect(await service.ensureLoaded(force: true), isTrue);
    expect(service.version, 'v1');
    expect(service.items.length, 2);
    expect(service.usingCachedCopy, isTrue);
    expect(cache.data, oldCache);
  });

  test('retries a cold failure without installing partial data', () async {
    final source = FakeCatalog()..incomplete = true;
    final service = CatalogService(source: source, cache: MemoryCache());
    expect(await service.ensureLoaded(), isFalse);
    expect(service.isReady, isFalse);
    expect(service.error, contains('Tente'.toLowerCase()));
    source.incomplete = false;
    expect(await service.ensureLoaded(force: true), isTrue);
    expect(service.error, isNull);
  });

  test(
    'refreshes once per release and keys instruction cache by release',
    () async {
      final source = FakeCatalog()..count = 2;
      final service = CatalogService(source: source, cache: MemoryCache());
      await service.ensureLoaded();
      await service.instructionsFor(service.items.first);
      await service.ensureLoaded(force: true);
      expect(source.ranges.length, 1);
      source.version = 'v2';
      await service.ensureLoaded(force: true);
      await service.instructionsFor(service.items.first);
      expect(source.ranges.length, 2);
      expect(source.detailCalls, 2);
      expect(service.version, 'v2');
    },
  );

  test(
    'recovers a corrupt cache and keeps downloads usable when storage is full',
    () async {
      final source = FakeCatalog()..count = 2;
      final cache = MemoryCache();
      final first = CatalogService(source: source, cache: cache);
      await first.ensureLoaded();
      cache.data[cache.data.keys.single] = '{broken';
      cache.failWrites = true;
      final restarted = CatalogService(source: source, cache: cache);
      expect(await restarted.ensureLoaded(), isTrue);
      expect(restarted.usingCachedCopy, isFalse);
      expect(
        await restarted.instructionsFor(restarted.items.first),
        isNotEmpty,
      );
    },
  );

  test('limits the persisted detail cache to 100 exercises', () async {
    final source = FakeCatalog()..count = 101;
    final cache = MemoryCache();
    final service = CatalogService(source: source, cache: cache);
    await service.ensureLoaded();
    for (final item in service.items) {
      await service.instructionsFor(item);
    }
    final raw = cache.data.entries
        .singleWhere((entry) => entry.key.endsWith(':details'))
        .value;
    expect((jsonDecode(raw) as Map).length, 100);
  });
}
