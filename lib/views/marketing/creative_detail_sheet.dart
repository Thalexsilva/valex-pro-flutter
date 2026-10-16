import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/marketing_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/carbon_card.dart';

class CreativeDetailSheet extends StatelessWidget {
  final AdCreativeItem creative;

  const CreativeDetailSheet({super.key, required this.creative});

  void _copyFullScript(BuildContext context) {
    final fullText =
        '''
🎯 ROTEIRO DE ANÚNCIO VALEX — ${creative.title.toUpperCase()}
Formato: ${creative.format.label} | Etapa: ${creative.funnelStage.label}
Público Alvo / ICP: ${creative.targetIcp}

🔥 GANCHO (HOOK DE 3 SEGUNDOS):
"${creative.hookText}"

📖 CORPO DO ROTEIRO:
${creative.bodyScript}

🚀 CHAMADA PARA AÇÃO (CTA):
"${creative.ctaText}"

🎙️ GUIA DE ÁUDIO / ENTONAÇÃO:
${creative.audioGuide}
''';

    Clipboard.setData(ClipboardData(text: fullText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.emerald, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Roteiro completo copiado para a área de transferência!',
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.carbon3,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color stageColor;
    switch (creative.funnelStage) {
      case FunnelStage.tofu:
        stageColor = AppColors.blueLight;
        break;
      case FunnelStage.mofu:
        stageColor = AppColors.amber;
        break;
      case FunnelStage.bofu:
        stageColor = AppColors.crimson;
        break;
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.carbon,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.carbon3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: stageColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.video_library_rounded,
                  color: stageColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(creative.title, style: AppTheme.headlineSm()),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: stageColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            creative.funnelStage.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: stageColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.carbon3,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            creative.format.label,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.steel,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'CTR Est: ${creative.estimatedCtr}%',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.emerald,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.steel),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.carbon3),
          const SizedBox(height: 12),

          // Conteúdo com Scroll
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                // ICP / Perfil Alvo
                CarbonCard(
                  padding: const EdgeInsets.all(12),
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_pin_rounded,
                        color: AppColors.gold,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PERFIL DE CLIENTE IDEAL (ICP)',
                              style: AppTheme.labelCaps(
                                color: AppColors.goldLight,
                              ),
                            ),
                            Text(
                              creative.targetIcp,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 1. O Gancho (Hook 3s)
                CarbonCard(
                  padding: const EdgeInsets.all(14),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.flash_on,
                            color: AppColors.crimson,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '1. O GANCHO (PRIMEIROS 3 SEGUNDOS)',
                            style: AppTheme.labelCaps(color: AppColors.crimson),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        creative.hookText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Corpo do Roteiro
                CarbonCard(
                  padding: const EdgeInsets.all(14),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.article_outlined,
                            color: AppColors.blueLight,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '2. CORPO DO ROTEIRO (QUEBRA DE CRENÇA & MÉTODO)',
                            style: AppTheme.labelCaps(
                              color: AppColors.blueLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        creative.bodyScript,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.steel,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3. CTA
                CarbonCard(
                  padding: const EdgeInsets.all(14),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.touch_app,
                            color: AppColors.emerald,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '3. CHAMADA PARA AÇÃO (CTA FINAL)',
                            style: AppTheme.labelCaps(color: AppColors.emerald),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        creative.ctaText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Guia de Áudio
                CarbonCard(
                  padding: const EdgeInsets.all(14),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.mic,
                            color: AppColors.gold,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'GUIA DE GRAVAÇÃO & ENTONAÇÃO',
                            style: AppTheme.labelCaps(
                              color: AppColors.goldLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        creative.audioGuide,
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.steelDim,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Botão Copiar Tudo
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _copyFullScript(context),
              icon: const Icon(Icons.copy_all_rounded, size: 20),
              label: const Text(
                'COPIAR ROTEIRO COMPLETO',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
