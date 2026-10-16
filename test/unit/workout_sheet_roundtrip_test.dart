import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/models/workout_model.dart';

void main() {
  group(
    'Suíte de Testes de Round-Trip Completo de WorkoutSheet (toJson / fromJson)',
    () {
      test(
        'Validação estrita de Round-Trip sem perda de campos ou mutação de tipos',
        () {
          final exercise = Exercise(
            title: 'Leg Press 45',
            cue: 'Pés na largura dos ombros, empurre pelos calcanhares',
            video: 'https://example.com/video.mp4',
            image: 'https://example.com/image.png',
            loadKg: '160',
            sets: ['15', '12', '10', '8'],
          );

          final day = WorkoutDay(
            dow: 'Treino B',
            muscle: 'Quadríceps e Panturrilha',
            icon: 'leg',
            cardio: true,
            exercises: [exercise],
          );

          final originalSheet = WorkoutSheet(
            studentId: 'st_uuid_9999',
            studentName: 'Carlos Eduardo',
            gymName: 'gymName Elite V3',
            month: 'Setembro 2026',
            instructorNotes: 'Foco em hipertrofia de membros inferiores',
            currentVersionName: 'v2 - Ajustada',
            days: [day],
            cardioOptions: ['Esteira: 25 min HIIT', 'Escada: 15 min'],
            generalNotes: [
              'Controlar respiração',
              'Descanso de 60s entre séries',
            ],
          );

          // Serialização para JSON
          final jsonMap = originalSheet.toJson();

          // Desserialização de volta para o modelo
          final deserializedSheet = WorkoutSheet.fromJson(jsonMap);

          // Asserção campo a campo
          expect(deserializedSheet.studentId, equals(originalSheet.studentId));
          expect(
            deserializedSheet.studentName,
            equals(originalSheet.studentName),
          );
          expect(deserializedSheet.gymName, equals(originalSheet.gymName));
          expect(deserializedSheet.month, equals(originalSheet.month));
          expect(
            deserializedSheet.instructorNotes,
            equals(originalSheet.instructorNotes),
          );
          expect(
            deserializedSheet.currentVersionName,
            equals(originalSheet.currentVersionName),
          );
          expect(
            deserializedSheet.cardioOptions,
            equals(originalSheet.cardioOptions),
          );
          expect(
            deserializedSheet.generalNotes,
            equals(originalSheet.generalNotes),
          );

          expect(deserializedSheet.days.length, equals(1));
          final d = deserializedSheet.days.first;
          expect(d.dow, equals('Treino B'));
          expect(d.muscle, equals('Quadríceps e Panturrilha'));
          expect(d.icon, equals('leg'));
          expect(d.cardio, isTrue);

          expect(d.exercises.length, equals(1));
          final ex = d.exercises.first;
          expect(ex.title, equals('Leg Press 45'));
          expect(
            ex.cue,
            equals('Pés na largura dos ombros, empurre pelos calcanhares'),
          );
          expect(ex.video, equals('https://example.com/video.mp4'));
          expect(ex.image, equals('https://example.com/image.png'));
          expect(ex.loadKg, equals('160'));
          expect(ex.sets, equals(['15', '12', '10', '8']));

          // Teste de deepCopy baseado em round-trip
          final deepClonedSheet = originalSheet.deepCopy();
          expect(deepClonedSheet.studentId, equals(originalSheet.studentId));
          expect(identical(deepClonedSheet, originalSheet), isFalse);
          expect(
            identical(deepClonedSheet.days.first, originalSheet.days.first),
            isFalse,
          );
          expect(
            identical(
              deepClonedSheet.days.first.exercises.first,
              originalSheet.days.first.exercises.first,
            ),
            isFalse,
          );
        },
      );
    },
  );
}
