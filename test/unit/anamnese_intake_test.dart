import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/models/anamnese_model.dart';

void main() {
  group('Anamnese & Intake 360° — Testes Unitários de Domínio', () {
    test('1. Cálculo de IMC e Classificação da OMS', () {
      final modelNormal = AnamneseModel(
        id: 'an_001',
        studentId: 'st_001',
        name: 'Lucas Ferreira',
        weightKg: 75.0,
        heightCm: 178.0,
      );

      // IMC = 75 / (1.78 * 1.78) = 23.66 -> 23.7
      expect(modelNormal.bmi, equals(23.7));
      expect(modelNormal.bmiClassification, equals('Peso normal'));

      final modelOverweight = AnamneseModel(
        id: 'an_002',
        studentId: 'st_002',
        name: 'Mariana Costa',
        weightKg: 85.0,
        heightCm: 165.0,
      );

      // IMC = 85 / (1.65 * 1.65) = 31.22 -> 31.2
      expect(modelOverweight.bmi, equals(31.2));
      expect(modelOverweight.bmiClassification, equals('Obesidade Grau I'));
    });

    test('2. Estratificação de Risco Clínico PAR-Q+ (Low, Moderate, High)', () {
      // Caso 1: Aluno 100% saudável
      final healthyModel = AnamneseModel(
        id: 'an_healthy',
        studentId: 'st_healthy',
        name: 'Atleta Saudável',
        parqAnswers: {
          'parq_cardiac_problem': false,
          'parq_chest_pain_activity': false,
        },
      );
      expect(healthyModel.clinicalRisk, equals(ClinicalRiskLevel.low));
      expect(healthyModel.clinicalRisk.badgeEmoji, equals('🟢'));

      // Caso 2: Aluno com dores no joelho/ombro (Risco Moderado)
      final moderateModel = AnamneseModel(
        id: 'an_moderate',
        studentId: 'st_moderate',
        name: 'Aluno com Dor',
        jointPains: ['Joelho', 'Ombro'],
        movementPainDetails: 'Dor ao agachar profundo',
      );
      expect(moderateModel.clinicalRisk, equals(ClinicalRiskLevel.moderate));
      expect(moderateModel.clinicalRisk.badgeEmoji, equals('🟡'));

      // Caso 3: Aluno com histórico cardíaco no PAR-Q+ (Alto Risco)
      final highRiskModel = AnamneseModel(
        id: 'an_high',
        studentId: 'st_high',
        name: 'Aluno Cardiopata',
        parqAnswers: {
          'parq_cardiac_problem': true,
          'parq_blood_pressure_meds': true,
        },
      );
      expect(highRiskModel.clinicalRisk, equals(ClinicalRiskLevel.high));
      expect(highRiskModel.clinicalRisk.badgeEmoji, equals('🔴'));
    });

    test('3. Bioimpedância Dedicada, Composição Corporal e Serialização', () {
      final bioData = BioimpedanceData(
        fileUrl: 'https://storage.valex.com.br/bio/laudo_inbody.pdf',
        fileName: 'Laudo_InBody_270_Carlos.pdf',
        fileSizeBytes: 2048500,
        muscleMassKg: 38.5,
        fatMassKg: 12.2,
        bodyFatPercent: 14.2,
        basalMetabolicRateKcal: 1850.0,
        visceralFatLevel: 4,
        totalBodyWaterLiters: 48.0,
        boneMassKg: 3.4,
        deviceModel: 'InBody 270',
      );

      expect(bioData.hasFile, isTrue);
      expect(bioData.hasMetrics, isTrue);

      final model = AnamneseModel(
        id: 'an_bio_001',
        studentId: 'st_bio_001',
        name: 'Carlos Bio',
        weightKg: 80.0,
        heightCm: 180.0,
        bioimpedance: bioData,
      );

      final json = model.toJson();
      final reconstructed = AnamneseModel.fromJson(json);

      expect(reconstructed.bioimpedance, isNotNull);
      expect(reconstructed.bioimpedance!.muscleMassKg, equals(38.5));
      expect(reconstructed.bioimpedance!.bodyFatPercent, equals(14.2));
      expect(
        reconstructed.bioimpedance!.basalMetabolicRateKcal,
        equals(1850.0),
      );
      expect(
        reconstructed.bioimpedance!.fileName,
        equals('Laudo_InBody_270_Carlos.pdf'),
      );

      final prontuario = reconstructed.toProntuarioSummary();
      expect(prontuario, contains('Massa Muscular Esquelética: 38.5 kg'));
      expect(prontuario, contains('Taxa Metabólica Basal (TMB): 1850 kcal'));
      expect(
        prontuario,
        contains('Laudo de Bioimpedância Anexado: Laudo_InBody_270_Carlos.pdf'),
      );
    });

    test('4. Serialização e Desserialização JSON Completa com 30+ Campos', () {
      final original = AnamneseModel(
        id: 'an_full_001',
        studentId: 'st_full_001',
        leadId: 'lead_999',
        name: 'Roberto Alencar',
        gender: 'Masculino',
        birthDate: '1990-05-12',
        age: 36,
        phone: '(11) 99888-7766',
        email: 'roberto@alencar.com',
        cpf: '111.222.333-44',
        address: 'São Paulo - SP',
        weightKg: 82.0,
        heightCm: 180.0,
        bodyFatPercent: 14.5,
        targetWeightKg: 85.0,
        mainGoal: 'Hipertrofia',
        specificGoals: 'Ganho de 3kg de massa magra',
        gymName: 'Smart Fit Paulista',
        trainingDaysPerWeek: 5,
        sessionDuration: '60 a 75 minutos',
        preferredShift: 'Noite',
        experienceLevel: 'Avançado',
        hasTrainedWithCoach: true,
        otherSports: 'Natação aos domingos',
        targetMuscles: ['Dorsal', 'Bíceps', 'Ombros'],
        bodyPerception: 'Boa resposta para membros superiores',
        favoriteExercises: 'Barra fixa, Supino inclinado',
        dislikedExercises: 'Agachamento hack',
        parqAnswers: {'parq_cardiac_problem': false},
        jointPains: ['Lombar'],
        movementPainDetails: 'Desconforto na hiperextensão',
        medicalHistory: 'Sem histórico de cirurgias',
        surgeries: 'Nenhuma',
        medications: 'Nenhum',
        supplements: 'Creatina, Whey Protein',
        sleepHours: 8.0,
        waterIntakeLiters: 3.5,
        stressLevel: 2,
        dietHabit: 'Hipercalórica orientada por nutricionista',
        alcoholHabit: 'Socialmente',
        smokingHabit: 'Não',
        posturePhotos: [
          PosturePhoto(
            id: 'photo_front',
            angle: PostureAngle.front,
            url: 'https://storage.valex.com/photos/front.jpg',
            fileName: 'frente.jpg',
          ),
          PosturePhoto(
            id: 'photo_back',
            angle: PostureAngle.back,
            url: 'https://storage.valex.com/photos/back.jpg',
            fileName: 'costas.jpg',
          ),
        ],
        documents: [
          MedicalDocument(
            id: 'doc_bio_01',
            title: 'Bioimpedância InBody 270',
            fileUrl: 'https://storage.valex.com/docs/bio.pdf',
            fileType: 'pdf',
            sizeBytes: 1048576,
          ),
        ],
        isDraft: false,
        consentAccepted: true,
      );

      final json = original.toJson();
      final reconstructed = AnamneseModel.fromJson(json);

      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.studentId, equals(original.studentId));
      expect(reconstructed.name, equals('Roberto Alencar'));
      expect(reconstructed.weightKg, equals(82.0));
      expect(reconstructed.heightCm, equals(180.0));
      expect(reconstructed.bmi, equals(25.3));
      expect(reconstructed.targetMuscles.length, equals(3));
      expect(reconstructed.posturePhotos.length, equals(2));
      expect(
        reconstructed.posturePhotos.first.angle,
        equals(PostureAngle.front),
      );
      expect(reconstructed.documents.length, equals(1));
      expect(
        reconstructed.documents.first.title,
        equals('Bioimpedância InBody 270'),
      );
    });

    test(
      '5. Geração Automática de Prontuário Estruturado e Notas do Instrutor',
      () {
        final model = AnamneseModel(
          id: 'an_prontuario',
          studentId: 'st_prontuario',
          name: 'Camila Mendes',
          weightKg: 62.0,
          heightCm: 168.0,
          mainGoal: 'Definição e Glúteos',
          gymName: 'Bio Ritmo',
          trainingDaysPerWeek: 5,
          targetMuscles: ['Glúteos', 'Posterior de Coxa'],
          jointPains: ['Joelho Esquerdo'],
          dislikedExercises: 'Agachamento sumô',
          supplements: 'Whey, Creatina',
        );

        final prontuario = model.toProntuarioSummary();
        expect(prontuario, contains('AVALIAÇÃO DE ANAMNESE 360° — VALEX'));
        expect(prontuario, contains('62.0 kg | 168.0 cm'));
        expect(prontuario, contains('Definição e Glúteos'));
        expect(prontuario, contains('DORES / RESTRIÇÕES: Joelho Esquerdo'));
        expect(
          prontuario,
          contains('Foco Muscular: Glúteos, Posterior de Coxa'),
        );

        final notes = model.toInstructorNotes();
        expect(
          notes,
          contains(
            'CUIDADO BIOMECÂNICO: Aluno relata dores em: Joelho Esquerdo',
          ),
        );
        expect(notes, contains('PREFERÊNCIA: Evitar Agachamento sumô'));
        expect(
          notes,
          contains(
            'PRIORIDADE: Volume semanal aumentado para: Glúteos, Posterior de Coxa',
          ),
        );
      },
    );
  });
}
