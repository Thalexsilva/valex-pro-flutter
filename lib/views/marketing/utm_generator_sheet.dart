import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/marketing_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/carbon_card.dart';

class UtmGeneratorSheet extends StatefulWidget {
  final List<MarketingCampaign> availableCampaigns;
  final String? initialCampaignTag;

  const UtmGeneratorSheet({
    super.key,
    required this.availableCampaigns,
    this.initialCampaignTag,
  });

  @override
  State<UtmGeneratorSheet> createState() => _UtmGeneratorSheetState();
}

class _UtmGeneratorSheetState extends State<UtmGeneratorSheet> {
  bool _isWhatsApp = true;
  final TextEditingController _phoneController = TextEditingController(
    text: '5511987654321',
  );
  final TextEditingController _baseUrlController = TextEditingController(
    text: 'https://valex.app/anamnese',
  );
  final TextEditingController _customSourceController = TextEditingController();
  final TextEditingController _customCampaignController =
      TextEditingController();
  final TextEditingController _contentController = TextEditingController(
    text: 'video_hook_v1',
  );
  final TextEditingController _greetingController = TextEditingController(
    text: 'Olá! Vi seu anúncio e gostaria de agendar uma avaliação de treino.',
  );

  String _selectedSource = 'meta';
  String _selectedMedium = 'reels';
  String _selectedCampaignTag = 'hipertrofia_tofu_2026';

  final List<String> _sources = [
    'meta',
    'tiktok',
    'google',
    'instagram_bio',
    'influencer',
  ];
  final List<String> _mediums = [
    'reels',
    'stories',
    'feed',
    'cpc',
    'bio',
    'direct',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.availableCampaigns.isNotEmpty) {
      final requestedTag = widget.initialCampaignTag;
      _selectedCampaignTag =
          requestedTag != null &&
              widget.availableCampaigns.any(
                (c) => c.utmCampaign == requestedTag,
              )
          ? requestedTag
          : widget.availableCampaigns.first.utmCampaign;
    }
    for (final controller in _controllers) {
      controller.addListener(_refreshPreview);
    }
  }

  List<TextEditingController> get _controllers => [
    _phoneController,
    _baseUrlController,
    _customSourceController,
    _customCampaignController,
    _contentController,
    _greetingController,
  ];

  void _refreshPreview() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _baseUrlController.dispose();
    _customSourceController.dispose();
    _customCampaignController.dispose();
    _contentController.dispose();
    _greetingController.dispose();
    super.dispose();
  }

  String _getFinalSource() {
    return _selectedSource == 'custom'
        ? _customSourceController.text.trim()
        : _selectedSource;
  }

  String _getFinalCampaign() {
    return _selectedCampaignTag == 'custom'
        ? _customCampaignController.text.trim()
        : _selectedCampaignTag;
  }

  String _generateGeneratedUrl() {
    final tracker = _buildTracker();

    if (_isWhatsApp) {
      return tracker.buildWhatsAppUrl(
        _phoneController.text.trim(),
        defaultGreeting: _greetingController.text.trim(),
      );
    } else {
      return tracker.buildLandingPageUrl(_baseUrlController.text.trim());
    }
  }

  UtmTrackerData _buildTracker() {
    final source = _getFinalSource();
    final campaign = _getFinalCampaign();
    final content = _contentController.text.trim();
    return UtmTrackerData(
      source: source.isNotEmpty ? source : 'meta',
      medium: _selectedMedium.isNotEmpty ? _selectedMedium : 'reels',
      campaign: campaign.isNotEmpty ? campaign : 'geral',
      content: content.isNotEmpty ? content : null,
    );
  }

  void _copyToClipboard() {
    final url = _generateGeneratedUrl();
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.emerald, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Link rastreado copiado para a área de transferência!',
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
    final generatedUrl = _generateGeneratedUrl();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.carbon,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: AppColors.blueLight,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Criar Link do Meu WhatsApp',
                      style: AppTheme.headlineSm(),
                    ),
                    Text(
                      'Coloque este link no Instagram para o aluno te chamar com 1 clique',
                      style: AppTheme.bodySm(color: AppColors.steelDim),
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

          // Alternador WhatsApp vs Landing Page
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isWhatsApp = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _isWhatsApp
                          ? AppColors.emerald.withValues(alpha: 0.2)
                          : AppColors.carbon2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isWhatsApp
                            ? AppColors.emerald
                            : AppColors.carbon3,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat,
                          color: _isWhatsApp
                              ? AppColors.emerald
                              : AppColors.steel,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'WhatsApp Direto',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isWhatsApp ? Colors.white : AppColors.steel,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isWhatsApp = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_isWhatsApp
                          ? AppColors.blue.withValues(alpha: 0.2)
                          : AppColors.carbon2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: !_isWhatsApp
                            ? AppColors.blue
                            : AppColors.carbon3,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.language,
                          color: !_isWhatsApp
                              ? AppColors.blueLight
                              : AppColors.steel,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Página Web / Anamnese',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: !_isWhatsApp
                                ? Colors.white
                                : AppColors.steel,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Atalhos de 1-Toque para Canais Comuns
          const Text(
            'Onde você vai postar esse link? (Toque para preencher):',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.steel,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _PresetChip(
                  label: '📸 Nos Stories de Hoje',
                  onTap: () {
                    setState(() {
                      _selectedSource = 'instagram';
                      _selectedMedium = 'stories';
                      _contentController.text = 'stories_hoje';
                    });
                  },
                ),
                const SizedBox(width: 6),
                _PresetChip(
                  label: '🎥 No Reels sobre Dor/Ombro',
                  onTap: () {
                    setState(() {
                      _selectedSource = 'meta';
                      _selectedMedium = 'reels';
                      _contentController.text = 'reels_dor_ombro';
                    });
                  },
                ),
                const SizedBox(width: 6),
                _PresetChip(
                  label: '🔗 No Link da Minha Bio',
                  onTap: () {
                    setState(() {
                      _selectedSource = 'instagram_bio';
                      _selectedMedium = 'bio';
                      _contentController.text = 'bio_perfil';
                    });
                  },
                ),
                const SizedBox(width: 6),
                _PresetChip(
                  label: '🎵 No Meu TikTok',
                  onTap: () {
                    setState(() {
                      _selectedSource = 'tiktok';
                      _selectedMedium = 'reels';
                      _contentController.text = 'tiktok_40min';
                    });
                  },
                ),
                const SizedBox(width: 6),
                _PresetChip(
                  label: '🥗 Parceria Nutricionista',
                  onTap: () {
                    setState(() {
                      _selectedSource = 'influencer';
                      _selectedMedium = 'direct';
                      _contentController.text = 'parceria_nutri';
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Configurações Específicas
          if (_isWhatsApp) ...[
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: AppTheme.inputText(),
                    decoration: const InputDecoration(
                      labelText: 'Seu WhatsApp (com DDD)',
                      hintText: '5511999999999',
                      prefixIcon: Icon(Icons.phone, color: AppColors.emerald),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _greetingController,
              maxLines: 2,
              style: AppTheme.inputText(),
              decoration: const InputDecoration(
                labelText: 'Mensagem inicial que o aluno vai te mandar',
                hintText:
                    'Olá! Vi seu anúncio e gostaria de agendar uma avaliação...',
                prefixIcon: Icon(Icons.message, color: AppColors.steel),
              ),
            ),
            const SizedBox(height: 10),
            // Live Preview do Balão de WhatsApp
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF075E54).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF25D366).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 14,
                        color: Color(0xFF25D366),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Como a mensagem vai chegar no seu WhatsApp:',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF25D366),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '"${_greetingController.text.trim()}\n\n${_buildTracker().attributionTag}"',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '(Essa etiqueta [Ref: ...] permite ao VALEX saber exatamente de onde esse aluno veio!)',
                    style: TextStyle(fontSize: 9, color: AppColors.steelDim),
                  ),
                ],
              ),
            ),
          ] else ...[
            TextFormField(
              controller: _baseUrlController,
              keyboardType: TextInputType.url,
              style: AppTheme.inputText(),
              decoration: const InputDecoration(
                labelText: 'URL da Sua Página ou Anamnese',
                hintText: 'https://valex.app/anamnese',
                prefixIcon: Icon(Icons.public, color: AppColors.blueLight),
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Seleção de Fonte (Source) e Meio (Medium)
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedSource,
                  dropdownColor: AppColors.carbon2,
                  style: AppTheme.inputText(),
                  decoration: const InputDecoration(labelText: 'Rede Social'),
                  items: _sources
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSource = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedMedium,
                  dropdownColor: AppColors.carbon2,
                  style: AppTheme.inputText(),
                  decoration: const InputDecoration(
                    labelText: 'Formato do Post',
                  ),
                  items: _mediums
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedMedium = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Campanha & Conteúdo do Criativo
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCampaignTag,
                  dropdownColor: AppColors.carbon2,
                  style: AppTheme.inputText(),
                  decoration: const InputDecoration(
                    labelText: 'Divulgação Vinculada',
                  ),
                  items: widget.availableCampaigns.map((c) {
                    return DropdownMenuItem(
                      value: c.utmCampaign,
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCampaignTag = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _contentController,
                  style: AppTheme.inputText(),
                  decoration: const InputDecoration(
                    labelText: 'Identificador do Vídeo',
                    hintText: 'ex: video_hook_1',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Prévia do Link Gerado
          CarbonCard(
            padding: const EdgeInsets.all(14),
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'SEU LINK PRONTO PARA POSTAR',
                      style: AppTheme.labelCaps(color: AppColors.emerald),
                    ),
                    const Spacer(),
                    const Text(
                      'TAG EMBUTIDA',
                      style: TextStyle(fontSize: 10, color: AppColors.steelDim),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  generatedUrl,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: AppColors.blueLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Botão de Copiar
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _copyToClipboard,
              icon: const Icon(Icons.copy_rounded, size: 20),
              label: Text(
                _isWhatsApp
                    ? 'COPIAR LINK DO MEU WHATSAPP'
                    : 'COPIAR LINK DA PÁGINA',
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

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.carbon2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.blueLight,
          ),
        ),
      ),
    );
  }
}
