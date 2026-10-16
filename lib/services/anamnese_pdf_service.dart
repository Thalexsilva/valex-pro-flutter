import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/anamnese_model.dart';
import '../models/student_model.dart';

/// AnamnesePdfService — Gera laudos clínicos e relatórios da Anamnese 360° em PDF
class AnamnesePdfService {
  static Future<Uint8List> generateAnamneseReportPdf({
    required AnamneseModel anamnese,
    required Student student,
    String trainerName = 'Profa. Valesca',
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // 1. Cabeçalho Institucional
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey900,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'VALEX PRO | RELATÓRIO CLÍNICO & ANAMNESE 360°',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Prescrição Individualizada & Periodização Científica',
                        style: const pw.TextStyle(
                          color: PdfColors.grey400,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Treinador(a): $trainerName',
                        style: pw.TextStyle(
                          color: PdfColors.amber,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Data: ${anamnese.createdAt.day.toString().padLeft(2, '0')}/${anamnese.createdAt.month.toString().padLeft(2, '0')}/${anamnese.createdAt.year}',
                        style: const pw.TextStyle(
                          color: PdfColors.grey300,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // 2. Dados do Aluno & Biometria
            _buildSectionTitle('1. IDENTIFICAÇÃO & BIOMETRIA'),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoLine('Nome:', anamnese.name),
                      _buildInfoLine(
                        'Idade / Sexo:',
                        '${anamnese.age} anos | ${anamnese.gender}',
                      ),
                      _buildInfoLine(
                        'Telefone:',
                        anamnese.phone.isNotEmpty
                            ? anamnese.phone
                            : student.phone,
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoLine(
                        'Peso / Altura:',
                        '${anamnese.weightKg} kg | ${anamnese.heightCm} cm',
                      ),
                      _buildInfoLine(
                        'IMC:',
                        '${anamnese.bmi} (${anamnese.bmiClassification})',
                      ),
                      _buildInfoLine('Objetivo Principal:', anamnese.mainGoal),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // 3. Composição Corporal & Bioimpedância
            if (anamnese.bioimpedance != null &&
                anamnese.bioimpedance!.hasMetrics) ...[
              _buildSectionTitle('2. COMPOSIÇÃO CORPORAL (BIOIMPEDÂNCIA)'),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Table(
                  children: [
                    pw.TableRow(
                      children: [
                        _buildTableItem(
                          'Gordura Corporal (% BF)',
                          '${anamnese.bioimpedance!.bodyFatPercent?.toStringAsFixed(1) ?? "-"} %',
                        ),
                        _buildTableItem(
                          'Massa Muscular',
                          '${anamnese.bioimpedance!.muscleMassKg?.toStringAsFixed(1) ?? "-"} kg',
                        ),
                        _buildTableItem(
                          'Massa Gorda',
                          '${anamnese.bioimpedance!.fatMassKg?.toStringAsFixed(1) ?? "-"} kg',
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _buildTableItem(
                          'Taxa Metabólica Basal',
                          '${anamnese.bioimpedance!.basalMetabolicRateKcal?.toStringAsFixed(0) ?? "-"} kcal/dia',
                        ),
                        _buildTableItem(
                          'Gordura Visceral',
                          'Nível ${anamnese.bioimpedance!.visceralFatLevel ?? "-"}',
                        ),
                        _buildTableItem(
                          'Água Corporal',
                          '${anamnese.bioimpedance!.totalBodyWaterLiters?.toStringAsFixed(1) ?? "-"} L',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
            ],

            // 4. Biomecânica & Estratificação de Risco
            _buildSectionTitle('3. ESTRATIFICAÇÃO CLÍNICA & BIOMECÂNICA'),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        'Risco Clínico PAR-Q+: ',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: pw.BoxDecoration(
                          color: anamnese.clinicalRisk == ClinicalRiskLevel.high
                              ? PdfColors.red100
                              : PdfColors.green100,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          anamnese.clinicalRisk.label.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color:
                                anamnese.clinicalRisk == ClinicalRiskLevel.high
                                ? PdfColors.red900
                                : PdfColors.green900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  _buildInfoLine(
                    'Dores / Restrições Articulares:',
                    anamnese.jointPains.isNotEmpty
                        ? anamnese.jointPains.join(', ')
                        : 'Nenhuma dor relatada',
                  ),
                  if (anamnese.movementPainDetails.isNotEmpty)
                    _buildInfoLine(
                      'Detalhes dos Movimentos com Dor:',
                      anamnese.movementPainDetails,
                    ),
                  if (anamnese.medicalHistory.isNotEmpty)
                    _buildInfoLine(
                      'Histórico Médico / Lesões:',
                      anamnese.medicalHistory,
                    ),
                  if (anamnese.medications.isNotEmpty)
                    _buildInfoLine(
                      'Medicamentos em Uso:',
                      anamnese.medications,
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // 5. Rotina & Hábitos
            _buildSectionTitle('4. ROTINA, HÁBITOS & PREFERÊNCIAS'),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoLine(
                        'Frequência de Treino:',
                        '${anamnese.trainingDaysPerWeek} dias/semana (${anamnese.sessionDuration})',
                      ),
                      _buildInfoLine(
                        'Nível de Experiência:',
                        anamnese.experienceLevel,
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  _buildInfoLine(
                    'Sono & Hidratação:',
                    '${anamnese.sleepHours}h/noite | ${anamnese.waterIntakeLiters}L água/dia | Estresse ${anamnese.stressLevel}/5',
                  ),
                  if (anamnese.targetMuscles.isNotEmpty)
                    _buildInfoLine(
                      'Foco / Grupamentos Prioritários:',
                      anamnese.targetMuscles.join(', '),
                    ),
                  if (anamnese.favoriteExercises.isNotEmpty)
                    _buildInfoLine(
                      'Exercícios Favoritos:',
                      anamnese.favoriteExercises,
                    ),
                  if (anamnese.dislikedExercises.isNotEmpty)
                    _buildInfoLine(
                      'Exercícios a Evitar:',
                      anamnese.dislikedExercises,
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // 6. Parecer Técnico da Treinadora
            _buildSectionTitle('5. PARECER & DIRETRIZES DE PRESCRIÇÃO'),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Text(
                anamnese.instructorNotes.isNotEmpty
                    ? anamnese.instructorNotes
                    : anamnese.toInstructorNotes(),
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey800,
                ),
              ),
            ),
            pw.SizedBox(height: 30),

            // Assinatura
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Container(
                      width: 180,
                      height: 1,
                      color: PdfColors.grey600,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      anamnese.name,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Assinatura do Aluno',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(
                      width: 180,
                      height: 1,
                      color: PdfColors.grey600,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      trainerName,
                      style: const pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Personal Trainer & Consultoria',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
    );
  }

  static pw.Widget _buildInfoLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label ',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey900,
              ),
            ),
            pw.TextSpan(
              text: value,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTableItem(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900,
            ),
          ),
        ],
      ),
    );
  }

  static Future<bool> printOrSharePdf({
    required AnamneseModel anamnese,
    required Student student,
  }) async {
    final pdfBytes = await generateAnamneseReportPdf(
      anamnese: anamnese,
      student: student,
    );
    return Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Anamnese_360_${student.name.replaceAll(' ', '_')}.pdf',
    );
  }
}
