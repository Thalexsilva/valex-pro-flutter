import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:valex_app/models/exercise_library_item.dart';
import 'package:valex_app/models/training_methods.dart';
import 'package:valex_app/services/catalog_service.dart';

/// Reference fixtures are only loaded by tests, never shipped in the application.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  List<Map<String, dynamic>> read(String name) =>
      (jsonDecode(File('tool/exercise_catalog/$name.json').readAsStringSync())
              as List)
          .cast<Map<String, dynamic>>();
  CatalogService.instance = CatalogService.seeded(
    read('exercises').map(ExerciseLibraryItem.fromJson).toList(),
    read('training-methods').map(TrainingMethod.fromJson).toList(),
  );
  await testMain();
}
