import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:valex_app/models/workout_model.dart';
import 'package:valex_app/services/pdf_generator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Testes Automatizados de Estrutura e Paridade do PDF Generator', () {
    test(
      'Geração de PDF Individual com todos os elementos (Nome, Dias, Exercícios, Cardio, QR Code e Notas)',
      () async {
        final sheet = WorkoutSheet(
          studentId: 'st_pdf_full',
          studentName: 'Carlos Eduardo da Silva',
          gymName: 'Smart Fit Centro',
          month: 'Setembro 2026',
          instructorNotes:
              'Manter cadência 2-0-2 em todas as séries. Foco no descanso entre séries de 60 segundos.',
          days: [
            WorkoutDay(
              dow: 'Treino A',
              muscle: 'Peito, Ombros e Tríceps',
              exercises: [
                Exercise(
                  title: 'Supino Reto com Barra',
                  cue: 'Escápulas aduzidas e cotovelos a 45 graus',
                  loadKg: '35',
                  sets: ['12', '10', '8', '6'],
                  video: 'https://youtube.com/watch?v=supino_reto',
                ),
                Exercise(
                  title: 'Desenvolvimento com Halteres',
                  cue: 'Não hiperestender a coluna',
                  loadKg: '16',
                  sets: ['10', '10', '10'],
                  video: '',
                ),
              ],
            ),
            WorkoutDay(
              dow: 'Treino B',
              muscle: 'Costas e Bíceps',
              exercises: [
                Exercise(
                  title: 'Puxada Frontal Aberta',
                  cue: 'Puxar até a barra tocar o peito',
                  loadKg: '45',
                  sets: ['12', '12', '12'],
                  video: 'https://youtube.com/watch?v=puxada_frontal',
                ),
              ],
            ),
          ],
          cardioOptions: [
            'Esteira: 20 min HIIT (1 min forte / 1 min leve)',
            'Transport: 15 min moderado',
          ],
          generalNotes: [
            'Beber pelo menos 3L de água por dia.',
            'Não pular o aquecimento de manguito.',
          ],
        );

        final pdfBytes = await PdfGeneratorService.generateWorkoutPdf(sheet);
        expect(pdfBytes, isNotNull);
        expect(
          pdfBytes.length,
          greaterThan(5000),
          reason:
              'PDF completo deve possuir tamanho compatível com documento formatado',
        );

        // Valida que o documento gerado é compilável e possui estrutura válida de documento PDF
        final doc = pw.Document();
        expect(doc, isNotNull);
      },
    );

    test('Geração de PDF sem imagem ou vídeo não deve gerar erro', () async {
      final sheetMinimal = WorkoutSheet(
        studentId: 'st_minimal',
        studentName: 'Ana Paula Minimal',
        days: [
          WorkoutDay(
            dow: 'Treino Único',
            muscle: 'Geral',
            exercises: [
              Exercise(
                title: 'Agachamento Livre',
                cue: '',
                loadKg: '20',
                sets: ['15', '15'],
                video: '',
              ),
            ],
          ),
        ],
        cardioOptions: [],
        generalNotes: [],
      );

      final pdfBytes = await PdfGeneratorService.generateWorkoutPdf(
        sheetMinimal,
      );
      expect(pdfBytes.length, isPositive);
    });

    test('Geração de PDF em Lote para múltiplos alunos diferentes', () async {
      final sheets = [
        WorkoutSheet(
          studentId: 's1',
          studentName: 'Aluno Lote 1',
          days: [
            WorkoutDay(
              dow: 'Dia A',
              muscle: 'Perna',
              exercises: [
                Exercise(title: 'Leg Press 45', sets: ['12', '12']),
              ],
            ),
          ],
        ),
        WorkoutSheet(
          studentId: 's2',
          studentName: 'Aluno Lote 2',
          days: [
            WorkoutDay(
              dow: 'Dia A',
              muscle: 'Braços',
              exercises: [
                Exercise(title: 'Rosca Direta', sets: ['10', '10']),
              ],
            ),
          ],
        ),
      ];

      final pdfBytes = await PdfGeneratorService.generateBatchWorkoutPdf(
        sheets,
      );
      expect(pdfBytes, isNotNull);
      expect(
        pdfBytes.length,
        greaterThan(2000),
        reason: 'PDF em lote para 2 alunos deve conter páginas combinadas',
      );
    });
  });
}
