import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/models/anamnese_model.dart';
import 'package:valex_app/models/student_model.dart';
import 'package:valex_app/models/workout_model.dart';
import 'package:valex_app/services/anamnese_pdf_service.dart';
import 'package:valex_app/views/students/workout_session_runner_view.dart';
import 'package:valex_app/widgets/bioimpedance_dashboard_card.dart';
import 'package:valex_app/widgets/interactive_body_pain_selector.dart';
import 'package:valex_app/widgets/posture_photo_gallery_viewer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testStudent = Student(
    id: 'st_portal_test',
    name: 'Carlos Oliveira',
    date: '01/09/2026',
    teacher: 'Profa. Valesca',
    phone: '11988887777',
    cpf: '123.456.789-00',
  );

  final testBio = BioimpedanceData(
    muscleMassKg: 34.5,
    fatMassKg: 14.2,
    bodyFatPercent: 17.8,
    basalMetabolicRateKcal: 1750,
    visceralFatLevel: 5,
    totalBodyWaterLiters: 48.0,
    boneMassKg: 3.2,
    deviceModel: 'InBody 270',
    assessmentDate: DateTime(2026, 9, 1),
  );

  final baselineBio = BioimpedanceData(
    muscleMassKg: 33.0,
    fatMassKg: 16.5,
    bodyFatPercent: 20.1,
    assessmentDate: DateTime(2026, 7, 1),
  );

  final List<PosturePhoto> testPhotos = [
    PosturePhoto(
      id: 'photo_front',
      angle: PostureAngle.front,
      url: 'https://example.com/front.jpg',
    ),
    PosturePhoto(
      id: 'photo_back',
      angle: PostureAngle.back,
      url: 'https://example.com/back.jpg',
    ),
  ];

  final testWorkoutDay = WorkoutDay(
    dow: 'Treino A',
    muscle: 'Peitoral & Tríceps',
    exercises: [
      WorkoutExercise(
        title: 'Supino Reto com Barra',
        loadKg: '60',
        cue: 'Escápulas travadas e pés firmes',
        sets: ['12', '10', '8'],
      ),
      WorkoutExercise(
        title: 'Crucifixo Inclinado',
        loadKg: '16',
        cue: 'Alongar peitoral no final da excêntrica',
        sets: ['12', '12', '10'],
      ),
    ],
  );

  group('Suíte Avançada de UX/UI & Módulos 360°', () {
    testWidgets(
      '1. InteractiveBodyPainSelector seleciona articulações e aciona callback',
      (WidgetTester tester) async {
        List<String> currentSelected = ['Ombro Direito'];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return InteractiveBodyPainSelector(
                    selectedJoints: currentSelected,
                    onChanged: (updated) {
                      setState(() => currentSelected = updated);
                    },
                  );
                },
              ),
            ),
          ),
        );

        expect(
          find.text('MAPA ANATÔMICO DE DORES ARTICULARES'),
          findsOneWidget,
        );
        expect(find.text('Ombro D'), findsOneWidget);
        expect(find.text('Lombar'), findsOneWidget);

        // Clica em Lombar
        await tester.tap(find.text('Lombar'));
        await tester.pumpAndSettle();

        expect(currentSelected.contains('Coluna Lombar'), isTrue);
      },
    );

    testWidgets(
      '2. BioimpedanceDashboardCard renderiza métricas e banner de evolução delta',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BioimpedanceDashboardCard(
                bio: testBio,
                previousBio: baselineBio,
              ),
            ),
          ),
        );

        expect(
          find.text('COMPOSIÇÃO CORPORAL & BIOIMPEDÂNCIA'),
          findsOneWidget,
        );
        expect(find.text('17.8%'), findsOneWidget); // % BF
        expect(find.text('34.5 kg'), findsOneWidget); // Massa Magra
        expect(find.text('14.2 kg'), findsOneWidget); // Massa Gorda
        expect(
          find.textContaining('Evolução vs. Avaliação Anterior'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '3. PosturePhotoGalleryViewer exibe abas de ângulos e modo comparativo',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PosturePhotoGalleryViewer(
                photos: testPhotos,
                baselinePhotos: testPhotos,
              ),
            ),
          ),
        );

        expect(find.text('AVALIAÇÃO POSTURAL & FOTOS 360°'), findsOneWidget);
        expect(find.textContaining('Frente'), findsWidgets);
        expect(find.textContaining('Costas'), findsWidgets);
        expect(find.textContaining('Lateral Direita'), findsWidgets);

        // Alterna para modo Antes vs Depois
        await tester.tap(find.text('Antes vs. Depois'));
        await tester.pumpAndSettle();

        expect(find.text('ANTES (1ª Avaliação)'), findsOneWidget);
        expect(find.text('DEPOIS (Atual)'), findsOneWidget);
      },
    );

    testWidgets(
      '4. WorkoutSessionRunnerView executa treino, marca séries e aciona cronômetro de descanso',
      (WidgetTester tester) async {
        bool finished = false;

        await tester.pumpWidget(
          MaterialApp(
            home: WorkoutSessionRunnerView(
              workoutDay: testWorkoutDay,
              studentName: testStudent.name,
              onFinish: () {
                finished = true;
              },
            ),
          ),
        );

        expect(find.text('Treino A • Peitoral & Tríceps'), findsOneWidget);
        expect(find.text('Supino Reto com Barra'), findsOneWidget);
        expect(find.text('Série 1: 12 reps'), findsWidgets);

        // Marca a Série 1 como feita
        await tester.tap(find.text('Série 1: 12 reps').first);
        await tester.pump();

        // Cronômetro de descanso aparece
        expect(find.text('INTERVALO DE DESCANSO'), findsOneWidget);

        // Clica em pular descanso
        await tester.tap(find.byTooltip('Pular descanso'));
        await tester.pumpAndSettle();

        expect(find.text('INTERVALO DE DESCANSO'), findsNothing);

        // Clica em Concluir Treino
        await tester.tap(find.text('Concluir Treino'));
        await tester.pumpAndSettle();

        expect(find.text('TREINO CONCLUÍDO!'), findsOneWidget);

        // Salva & Finaliza Sessão
        await tester.tap(find.widgetWithText(ChoiceChip, '7'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Salvar & Finalizar Sessão'));
        await tester.pumpAndSettle();

        expect(finished, isTrue);
      },
    );

    test(
      '5. AnamnesePdfService gera documento PDF com dados clínicos e bioimpedância',
      () async {
        final anamnese = AnamneseModel(
          id: 'an_test_pdf',
          studentId: testStudent.id,
          name: testStudent.name,
          age: 28,
          gender: 'Masculino',
          weightKg: 78.5,
          heightCm: 178.0,
          mainGoal: 'Hipertrofia & Força',
          bioimpedance: testBio,
          jointPains: const ['Coluna Lombar', 'Ombro Direito'],
          targetMuscles: const ['Peitoral', 'Dorsal'],
        );

        final pdfBytes = await AnamnesePdfService.generateAnamneseReportPdf(
          anamnese: anamnese,
          student: testStudent,
        );

        expect(pdfBytes.isNotEmpty, isTrue);
        expect(pdfBytes.length, greaterThan(1000));
      },
    );
  });
}
