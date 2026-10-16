import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../repositories/anamnese_repository.dart';
import '../../models/anamnese_model.dart';
import '../../models/student_model.dart';
import '../../services/anamnese_pdf_service.dart';
import '../../services/student_context_service.dart';
import '../../theme/app_colors.dart';
import '../editor/editor_view.dart';
import 'anamnese_form_wizard_view.dart';

class AnamneseDetailSheet extends StatelessWidget {
  final AnamneseModel anamnese;
  final Student student;
  final VoidCallback? onUpdated;

  Future<void> _openDocument(BuildContext context, String reference) async {
    try {
      final uri = await AnamneseRepository().documentUri(reference);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('Unable to open document');
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nao foi possivel abrir o arquivo. Verifique a conexao e tente novamente.',
          ),
        ),
      );
    }
  }

  const AnamneseDetailSheet({
    super.key,
    required this.anamnese,
    required this.student,
    this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final risk = anamnese.clinicalRisk;
    final bio = anamnese.bioimpedance;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.carbon,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Anamnese & Bioimpedância 360° • ${anamnese.name}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Preenchido em ${anamnese.createdAt.day.toString().padLeft(2, '0')}/${anamnese.createdAt.month.toString().padLeft(2, '0')}/${anamnese.createdAt.year}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: AppColors.gold,
                      ),
                      tooltip: 'Exportar Laudo em PDF',
                      onPressed: () => AnamnesePdfService.printOrSharePdf(
                        anamnese: anamnese,
                        student: student,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Editar Anamnese',
                      onPressed: () async {
                        Navigator.pop(context);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnamneseFormWizardView(
                              student: student,
                              initialAnamnese: anamnese,
                              onCompleted: onUpdated,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10),

              // Body Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Card de Estratificação de Risco Clínico
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: risk == ClinicalRiskLevel.high
                            ? const Color(0xFF331414)
                            : (risk == ClinicalRiskLevel.moderate
                                  ? const Color(0xFF33250E)
                                  : const Color(0xFF0F291E)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: risk == ClinicalRiskLevel.high
                              ? AppColors.crimson
                              : (risk == ClinicalRiskLevel.moderate
                                    ? AppColors.amber
                                    : AppColors.emerald),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            risk.badgeEmoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  risk.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  risk == ClinicalRiskLevel.high
                                      ? 'Atenção: Resposta afirmativa em pergunta cardiovascular do PAR-Q+. Exigir atestado médico antes da liberação da ficha.'
                                      : (risk == ClinicalRiskLevel.moderate
                                            ? 'Atenção às articulações e histórico de dor relatado durante a periodização.'
                                            : 'Aluno apto para treinos de alta intensidade e sobrecarga progressiva.'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // PAINEL DE BIOIMPEDÂNCIA & COMPOSIÇÃO CORPORAL DEDICADO
                    _buildDetailCard(
                      title: 'Bioimpedância & Composição Corporal',
                      icon: Icons.analytics_outlined,
                      children: [
                        if (bio != null && bio.hasFile) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.carbon,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.emerald.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.picture_as_pdf,
                                  color: AppColors.emerald,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bio.fileName ??
                                            'Laudo_Bioimpedancia.pdf',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        bio.fileSizeBytes > 0
                                            ? '${(bio.fileSizeBytes / 1024).toStringAsFixed(0)} KB • Laudo Anexado'
                                            : 'Laudo Anexado pelo Aluno',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.emerald,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  icon: const Icon(Icons.download, size: 16),
                                  label: const Text(
                                    'Abrir Laudo',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  onPressed: () =>
                                      _openDocument(context, bio.fileUrl!),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              'Nenhum arquivo de laudo de bioimpedância anexado.',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        if (bio != null && bio.hasMetrics) ...[
                          if (bio.muscleMassKg != null)
                            _buildRow(
                              'Massa Muscular',
                              '${bio.muscleMassKg} kg',
                            ),
                          if (bio.fatMassKg != null)
                            _buildRow('Massa Gorda', '${bio.fatMassKg} kg'),
                          if (bio.bodyFatPercent != null)
                            _buildRow(
                              '% Gordura (BF)',
                              '${bio.bodyFatPercent}%',
                            ),
                          if (bio.basalMetabolicRateKcal != null)
                            _buildRow(
                              'Taxa Metabólica (TMB)',
                              '${bio.basalMetabolicRateKcal!.toStringAsFixed(0)} kcal',
                            ),
                          if (bio.visceralFatLevel != null)
                            _buildRow(
                              'Gordura Visceral',
                              'Nível ${bio.visceralFatLevel}',
                            ),
                          if (bio.totalBodyWaterLiters != null)
                            _buildRow(
                              'Água Corporal',
                              '${bio.totalBodyWaterLiters} L',
                            ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Antropometria & Metas
                    _buildDetailCard(
                      title: 'Antropometria & Metas',
                      icon: Icons.monitor_weight_outlined,
                      children: [
                        _buildRow('Peso Atual', '${anamnese.weightKg} kg'),
                        _buildRow('Altura', '${anamnese.heightCm} cm'),
                        _buildRow(
                          'IMC',
                          '${anamnese.bmi} kg/m² (${anamnese.bmiClassification})',
                        ),
                        if (anamnese.bodyFatPercent != null)
                          _buildRow(
                            'Gordura Corporal',
                            '${anamnese.bodyFatPercent}%',
                          ),
                        _buildRow('Objetivo Principal', anamnese.mainGoal),
                        if (anamnese.specificGoals.isNotEmpty)
                          _buildRow(
                            'Metas Específicas',
                            anamnese.specificGoals,
                          ),
                        _buildRow(
                          'Academia',
                          anamnese.gymName.isNotEmpty
                              ? anamnese.gymName
                              : 'Não informada',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Rotina & Treino
                    _buildDetailCard(
                      title: 'Rotina & Disponibilidade',
                      icon: Icons.calendar_today_outlined,
                      children: [
                        _buildRow(
                          'Frequência Semanal',
                          '${anamnese.trainingDaysPerWeek} dias por semana',
                        ),
                        _buildRow(
                          'Duração por Sessão',
                          anamnese.sessionDuration,
                        ),
                        _buildRow(
                          'Turno Preferencial',
                          anamnese.preferredShift,
                        ),
                        _buildRow(
                          'Nível de Experiência',
                          anamnese.experienceLevel,
                        ),
                        _buildRow(
                          'Acompanhamento Anterior',
                          anamnese.hasTrainedWithCoach ? 'Sim' : 'Não',
                        ),
                        if (anamnese.otherSports.isNotEmpty)
                          _buildRow(
                            'Outros Esportes / Cardio',
                            anamnese.otherSports,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Foco Muscular & Restrições
                    _buildDetailCard(
                      title: 'Biomecânica & Preferências',
                      icon: Icons.fitness_center_outlined,
                      children: [
                        if (anamnese.targetMuscles.isNotEmpty)
                          _buildRow(
                            'Foco Muscular',
                            anamnese.targetMuscles.join(', '),
                          ),
                        if (anamnese.jointPains.isNotEmpty)
                          _buildRow(
                            'Dores / Lesões',
                            anamnese.jointPains.join(', '),
                          ),
                        if (anamnese.movementPainDetails.isNotEmpty)
                          _buildRow(
                            'Desconforto em Exercício',
                            anamnese.movementPainDetails,
                          ),
                        if (anamnese.favoriteExercises.isNotEmpty)
                          _buildRow(
                            'Exercícios Favoritos',
                            anamnese.favoriteExercises,
                          ),
                        if (anamnese.dislikedExercises.isNotEmpty)
                          _buildRow(
                            'Exercícios Rejeitados',
                            anamnese.dislikedExercises,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Outros Exames Anexados
                    if (anamnese.documents.isNotEmpty) ...[
                      _buildDetailCard(
                        title:
                            'Outros Exames & Laudos (${anamnese.documents.length})',
                        icon: Icons.folder_shared_outlined,
                        children: anamnese.documents.map((doc) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.picture_as_pdf,
                              color: AppColors.crimson,
                            ),
                            title: Text(
                              doc.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              '${(doc.sizeBytes / 1024).toStringAsFixed(0)} KB • PDF Anexo',
                            ),
                            trailing: const Icon(
                              Icons.download,
                              color: AppColors.vibrantBlue,
                            ),
                            onTap: () => _openDocument(context, doc.fileUrl),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Galeria de Fotos Posturais
                    _buildDetailCard(
                      title:
                          'Fotos de Avaliação Postural (${anamnese.posturePhotos.length})',
                      icon: Icons.camera_alt_outlined,
                      children: [
                        if (anamnese.posturePhotos.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Nenhuma foto postural anexada ainda.',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: anamnese.posturePhotos.map((p) {
                              return Container(
                                width: 140,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.carbon,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.image,
                                      size: 48,
                                      color: AppColors.vibrantBlue,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      p.angle.label,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (p.fileName != null)
                                      Text(
                                        p.fileName!,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Botão de Transferir para o Editor de Treinos
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.vibrantBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.fitness_center),
                      label: const Text(
                        'Prescrever Treino com Base na Anamnese & Bioimpedância',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        StudentContextService().setActiveStudent(student.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditorView(studentId: student.id),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.carbon2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.vibrantBlue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
