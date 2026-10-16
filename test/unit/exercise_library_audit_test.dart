import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/services/student_context_service.dart';

void main() {
  final library = StudentContextService.exerciseLibrary;
  final originals =
      (jsonDecode(
                File(
                  'tool/exercise_catalog/sources/exercises-en.json',
                ).readAsStringSync(),
              )
              as List)
          .cast<Map<String, dynamic>>();
  final translations =
      (jsonDecode(
                File(
                  'tool/exercise_catalog/sources/exercises-ptbr.json',
                ).readAsStringSync(),
              )
              as List)
          .cast<Map<String, dynamic>>();
  final legacy =
      (jsonDecode(
                File(
                  'tool/exercise_catalog/sources/legacy.json',
                ).readAsStringSync(),
              )
              as List)
          .cast<Map<String, dynamic>>();

  group('Biblioteca unificada e offline', () {
    test('preserva todos os IDs originais e unifica as traduções', () {
      final ids = library.map((e) => e.id).toSet();
      expect(library.length, 2029);
      expect(ids.length, library.length);
      expect(ids, containsAll(originals.map((e) => e['id'])));
      expect(ids, containsAll(translations.map((e) => e['id'])));
      final titles = library
          .map((e) => ExerciseLibraryItem.normalize(e.title))
          .toSet();
      expect(titles.length, library.length);
    });

    test('fotos correspondem aos caminhos da revisão original', () {
      const base =
          'https://raw.githubusercontent.com/yuhonas/free-exercise-db/'
          'a859101d633a01c4a1a920d6a8ce41dabba0705f/exercises/';
      for (final original in originals) {
        final item = library.firstWhere((e) => e.id == original['id']);
        final paths = (original['images'] as List).cast<String>();
        expect(
          item.images,
          paths
              .map(
                (path) =>
                    '$base${Uri.encodeComponent(item.id)}/${path.split('/').last}',
              )
              .toList(),
          reason: item.id,
        );
      }
      expect(library.where((item) => item.images.isNotEmpty).length, 873);
    });

    test('preserva títulos, dicas e ordem dos 152 exercícios existentes', () {
      for (var i = 0; i < legacy.length; i++) {
        final item = library[i];
        expect(item.title, legacy[i]['title']);
        expect(item.muscle, legacy[i]['muscle']);
        expect(item.cue, legacy[i]['cue']);
        expect(item.video, legacy[i]['video'] ?? '');
      }
    });

    test('prioriza português e mantém todas as instruções traduzidas', () {
      for (final translated in translations) {
        final item = library.firstWhere((e) => e.id == translated['id']);
        expect(item.language, 'pt-BR');
        expect(item.aliases, contains(translated['name']));
        if ((translated['instructions'] as List).isNotEmpty) {
          expect(item.instructions, translated['instructions']);
        }
      }
      expect(library.take(931).every((e) => e.language == 'pt-BR'), isTrue);
      expect(library.skip(931).every((e) => e.language == 'en'), isTrue);
      expect(
        library.firstWhere((e) => e.id == 'Kettlebell_Halo').title,
        'Halo com kettlebell',
      );
    });

    test('metadados permitem filtros e cardio tem classificação explícita', () {
      for (final item in library) {
        expect(item.title.trim(), isNotEmpty);
        expect(item.muscle.trim(), isNotEmpty);
        expect(item.cue.trim(), isNotEmpty);
        expect(item.equipment, isNotEmpty);
        expect(item.source, isNotEmpty);
        if (item.category == 'cardio') expect(item.muscle, 'Cardio');
      }
      expect(
        library.map((e) => e.category),
        containsAll(['strength', 'cardio', 'stretching', 'plyometrics']),
      );
    });

    test('busca aceita acentos, aliases em inglês e termos fora de ordem', () {
      final bench = library.firstWhere(
        (e) => e.id == 'Barbell_Bench_Press_-_Medium_Grip',
      );
      expect(bench.matchesSearch('barra supino'), isTrue);
      expect(bench.matchesSearch('bench press'), isTrue);
      expect(bench.matchesSearch('agachamento'), isFalse);
      final curl = library.firstWhere((e) => e.id == 'Dumbbell_Bicep_Curl');
      expect(curl.matchesSearch('biceps halteres'), isTrue);
    });

    test(
      'homônimos têm nomes diferentes e lacunas não ganham instruções fictícias',
      () {
        final jog = library.firstWhere((e) => e.id == 'Jogging_Treadmill');
        final run = library.firstWhere((e) => e.id == 'Running_Treadmill');
        expect(jog.title, isNot(run.title));
        final missing = library.firstWhere((e) => e.id == 'Iron_Cross');
        expect(missing.instructions, isEmpty);
        expect(missing.cue, contains('não fornecidas'));
      },
    );
  });
}
