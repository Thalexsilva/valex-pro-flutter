import 'package:flutter/material.dart';
import '../../../models/workout_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import 'day_badge_text.dart';

/// Página 1 (capa) da ficha virtual — equivalente a `.cover-page` no modelo
/// legado (`js/pdf.js#renderCoverPage`).
class EditorCoverPage extends StatelessWidget {
  final WorkoutSheet sheet;

  const EditorCoverPage({super.key, required this.sheet});

  @override
  Widget build(BuildContext context) {
    // Medido no nível da página (largura sempre finita, vinda do
    // ConstrainedBox de `_centeredPageWidth`) em vez de dentro do Positioned
    // — ali right+top+bottom sem `left`/`width` dá largura infinita ao
    // BoxConstraints, o que quebra o LayoutBuilder/ShaderMask.
    return LayoutBuilder(
      builder: (context, pageConstraints) {
        final characterWidth = pageConstraints.maxWidth * 0.32;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.carbon,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                bottom: 0,
                top: 40,
                width: characterWidth,
                // Largura explícita (em vez de deixar o BoxFit.contain
                // dimensionar pela intrínseca da imagem): evita que a
                // personagem passe da borda da capa e seja cortada de forma
                // dura pelo Stack em telas mais estreitas.
                child: ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.white],
                    stops: [0.0, 0.18],
                  ).createShader(rect),
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    'assets/images/character.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(36.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset('assets/images/logo.png', height: 38),
                    const SizedBox(height: 18),
                    Text(
                      'PROGRAMA SEMANAL · ${sheet.days.length} TREINOS',
                      style: AppTheme.labelCaps(color: AppColors.blueLight),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'FICHA\nDE\nTREINO',
                      style: AppTheme.displayLg(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Container(width: 48, height: 3, color: AppColors.blue),
                    const SizedBox(height: 12),
                    Text(
                      'Biomechanics & Rehabilitation',
                      style: AppTheme.bodyMd(color: AppColors.steel),
                    ),
                    const SizedBox(height: 36),

                    // Student Details Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.carbon2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sheet.studentName,
                            style: AppTheme.headlineLg(color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              Text(
                                '🎯 ${sheet.gymName}',
                                style: AppTheme.bodyMd(
                                  color: AppColors.blueLight,
                                ),
                              ),
                              Text(
                                '📅 ${sheet.month}',
                                style: AppTheme.bodyMd(color: AppColors.steel),
                              ),
                              Text(
                                '👤 ${sheet.teacher}',
                                style: AppTheme.bodyMd(color: AppColors.steel),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Day badges
                    Wrap(
                      spacing: 8,
                      children: sheet.days.map((d) {
                        return Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            getDayBadgeText(d.dow),
                            style: const TextStyle(
                              fontFamily: 'BebasNeue',
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
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
}
