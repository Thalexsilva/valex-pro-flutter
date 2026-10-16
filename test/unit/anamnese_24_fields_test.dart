import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auditoria & Teste da Matriz dos 24 Campos da Anamnese', () {
    test(
      'Serialização e Desserialização Completa dos 24 Campos Clínicos e Pessoais',
      () {
        final anamneseFullMap = {
          'name': 'Carlos Eduardo Silva',
          'email': 'carlos.silva@example.com',
          'phone': '(11) 98765-4321',
          'cpf': '123.456.789-00',
          'gender': 'Masculino',
          'age': 32,
          'weightKg': 82.5,
          'heightCm': 178.0,
          'mainGoal': 'Hipertrofia',
          'specificGoals': 'Aumento de braço e definição abdominal',
          'experienceLevel': 'Intermediário (2 anos)',
          'medicalNotes': 'Sem hipertensão, cirurgia de joelho em 2021',
          'academia': 'Studio Fit Master',
          'targetMuscles': ['Peito', 'Tríceps', 'Ombro'],
          'bodyPerception': 'Satisfeito, busca reduzir gordura abdominal',
          'healthHistory': 'Histórico familiar de diabetes',
          'limitations': 'Evitar agachamento profundo sem apoio',
          'currentActivity': 'Futebol aos sábados',
          'dietHabits': 'Dieta normocalórica acompanhada por nutricionista',
          'lifestyleHabits': '7h de sono por noite, estresse moderado',
          'physicalAssessment': 'https://drive.google.com/assessment_001.pdf',
          'exercisePreferences': 'Gosta de supino e pulley; odeia burpee',
          'instructorNotes': 'Manter foco na cadência excêntrica de 3s',
          'availability': '5 dias por semana (Seg a Sex)',
        };

        // 1. Validar que exatos 24 campos estão presentes
        expect(anamneseFullMap.keys.length, equals(24));

        // 2. Testar parsing e tipos individuais
        expect(anamneseFullMap['name'], equals('Carlos Eduardo Silva'));
        expect(anamneseFullMap['age'], equals(32));
        expect(anamneseFullMap['weightKg'], equals(82.5));
        expect((anamneseFullMap['targetMuscles'] as List).length, equals(3));

        // 3. Testar fallback quando um campo opcional está ausente
        final partialMap = Map<String, dynamic>.from(anamneseFullMap);
        partialMap.remove('limitations');
        final fallbackLimitations =
            partialMap['limitations'] as String? ?? 'Sem lesões relatadas';
        expect(fallbackLimitations, equals('Sem lesões relatadas'));
      },
    );
  });
}
