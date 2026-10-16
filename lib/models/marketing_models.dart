import 'package:flutter/material.dart';

/// Plataforma de Mídia Paga ou Origem
enum MarketingPlatform {
  meta, // Instagram / Facebook Ads
  tiktok, // TikTok Ads
  google, // Google Ads / YouTube
  influencer, // Parceria com Influenciador
  organic, // Post Orgânico / Bio
}

extension MarketingPlatformExtension on MarketingPlatform {
  String get value {
    switch (this) {
      case MarketingPlatform.meta:
        return 'meta';
      case MarketingPlatform.tiktok:
        return 'tiktok';
      case MarketingPlatform.google:
        return 'google';
      case MarketingPlatform.influencer:
        return 'influencer';
      case MarketingPlatform.organic:
        return 'organic';
    }
  }

  String get label {
    switch (this) {
      case MarketingPlatform.meta:
        return 'Meta Ads (Insta/FB)';
      case MarketingPlatform.tiktok:
        return 'TikTok Ads';
      case MarketingPlatform.google:
        return 'Google / YouTube';
      case MarketingPlatform.influencer:
        return 'Influencer / Parceiro';
      case MarketingPlatform.organic:
        return 'Orgânico / Bio';
    }
  }

  static MarketingPlatform fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'meta':
      case 'instagram':
      case 'facebook':
        return MarketingPlatform.meta;
      case 'tiktok':
        return MarketingPlatform.tiktok;
      case 'google':
      case 'youtube':
        return MarketingPlatform.google;
      case 'influencer':
      case 'parceria':
        return MarketingPlatform.influencer;
      default:
        return MarketingPlatform.organic;
    }
  }
}

/// Objetivo da Campanha
enum CampaignObjective {
  leads, // Geração de Leads / WhatsApp
  traffic, // Tráfego para Landing Page / Bio
  conversions, // Conversão Direta / Checkout
  engagement, // Visualização de Vídeo / Engajamento
}

extension CampaignObjectiveExtension on CampaignObjective {
  String get value {
    switch (this) {
      case CampaignObjective.leads:
        return 'leads';
      case CampaignObjective.traffic:
        return 'traffic';
      case CampaignObjective.conversions:
        return 'conversions';
      case CampaignObjective.engagement:
        return 'engagement';
    }
  }

  String get label {
    switch (this) {
      case CampaignObjective.leads:
        return 'Leads / WhatsApp';
      case CampaignObjective.traffic:
        return 'Tráfego para Página';
      case CampaignObjective.conversions:
        return 'Conversão / Checkout';
      case CampaignObjective.engagement:
        return 'Engajamento & Vídeo';
    }
  }

  static CampaignObjective fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'leads':
      case 'lead':
        return CampaignObjective.leads;
      case 'traffic':
      case 'trafego':
        return CampaignObjective.traffic;
      case 'conversions':
      case 'conversao':
        return CampaignObjective.conversions;
      case 'engagement':
      case 'engajamento':
        return CampaignObjective.engagement;
      default:
        return CampaignObjective.leads;
    }
  }
}

/// Status da Campanha
enum CampaignStatus {
  active, // Ativa
  paused, // Pausada
  draft, // Rascunho / Planejada
  completed, // Encerrada
}

extension CampaignStatusExtension on CampaignStatus {
  String get value {
    switch (this) {
      case CampaignStatus.active:
        return 'active';
      case CampaignStatus.paused:
        return 'paused';
      case CampaignStatus.draft:
        return 'draft';
      case CampaignStatus.completed:
        return 'completed';
    }
  }

  String get label {
    switch (this) {
      case CampaignStatus.active:
        return 'Ativa 🟢';
      case CampaignStatus.paused:
        return 'Pausada ⏸️';
      case CampaignStatus.draft:
        return 'Rascunho 📝';
      case CampaignStatus.completed:
        return 'Encerrada 🏁';
    }
  }

  static CampaignStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'active':
      case 'ativa':
        return CampaignStatus.active;
      case 'paused':
      case 'pausada':
        return CampaignStatus.paused;
      case 'draft':
      case 'rascunho':
        return CampaignStatus.draft;
      case 'completed':
      case 'encerrada':
        return CampaignStatus.completed;
      default:
        return CampaignStatus.draft;
    }
  }
}

/// Etapa do Funil de Mídia
enum FunnelStage {
  tofu, // Topo de Funil (Atração & Consciência)
  mofu, // Meio de Funil (Consideração & Anamnese)
  bofu, // Fundo de Funil (Conversão & Fechamento)
}

extension FunnelStageExtension on FunnelStage {
  String get value {
    switch (this) {
      case FunnelStage.tofu:
        return 'tofu';
      case FunnelStage.mofu:
        return 'mofu';
      case FunnelStage.bofu:
        return 'bofu';
    }
  }

  String get label {
    switch (this) {
      case FunnelStage.tofu:
        return 'TOFU (Atração)';
      case FunnelStage.mofu:
        return 'MOFU (Anamnese)';
      case FunnelStage.bofu:
        return 'BOFU (Fechamento)';
    }
  }

  Color get color {
    switch (this) {
      case FunnelStage.tofu:
        return const Color(0xFF60A5FA); // blueLight
      case FunnelStage.mofu:
        return const Color(0xFFF59E0B); // amber
      case FunnelStage.bofu:
        return const Color(0xFFE63946); // crimson
    }
  }

  static FunnelStage fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'tofu':
      case 'topo':
        return FunnelStage.tofu;
      case 'mofu':
      case 'meio':
        return FunnelStage.mofu;
      case 'bofu':
      case 'fundo':
        return FunnelStage.bofu;
      default:
        return FunnelStage.tofu;
    }
  }
}

/// Formato do Criativo de Anúncio
enum CreativeFormat {
  videoReels, // Vídeo Vertical (Reels / TikTok)
  carousel, // Carrossel de 3 a 5 lâminas
  singleImage, // Imagem Única de Alto Impacto
  socialProofCard, // Cartão Antes/Depois VALEX
  roiCalculator, // Comparativo Visual de Investimento
}

extension CreativeFormatExtension on CreativeFormat {
  String get value {
    switch (this) {
      case CreativeFormat.videoReels:
        return 'video_reels';
      case CreativeFormat.carousel:
        return 'carousel';
      case CreativeFormat.singleImage:
        return 'single_image';
      case CreativeFormat.socialProofCard:
        return 'social_proof';
      case CreativeFormat.roiCalculator:
        return 'roi_calculator';
    }
  }

  String get label {
    switch (this) {
      case CreativeFormat.videoReels:
        return 'Vídeo Reels / TikTok';
      case CreativeFormat.carousel:
        return 'Carrossel Educativo';
      case CreativeFormat.singleImage:
        return 'Imagem Única';
      case CreativeFormat.socialProofCard:
        return 'Antes/Depois VALEX';
      case CreativeFormat.roiCalculator:
        return 'Calculadora de ROI';
    }
  }

  static CreativeFormat fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'video_reels':
      case 'video':
      case 'reels':
        return CreativeFormat.videoReels;
      case 'carousel':
      case 'carrossel':
        return CreativeFormat.carousel;
      case 'single_image':
      case 'imagem':
        return CreativeFormat.singleImage;
      case 'social_proof':
      case 'prova_social':
        return CreativeFormat.socialProofCard;
      case 'roi_calculator':
      case 'roi':
        return CreativeFormat.roiCalculator;
      default:
        return CreativeFormat.videoReels;
    }
  }
}

/// Entidade de Campanha de Mídia Paga
class MarketingCampaign {
  final String id;
  final String name;
  final MarketingPlatform platform;
  final CampaignObjective objective;
  final FunnelStage funnelStage;
  final CampaignStatus status;
  final double dailyBudget;
  final double totalSpent;
  final int leadsGenerated;
  final int wonStudents;
  final double revenueGenerated;
  final String targetAudience;
  final String utmCampaign;
  final String createdAt;
  final String updatedAt;

  MarketingCampaign({
    required this.id,
    required this.name,
    this.platform = MarketingPlatform.meta,
    this.objective = CampaignObjective.leads,
    this.funnelStage = FunnelStage.tofu,
    this.status = CampaignStatus.active,
    this.dailyBudget = 20.0,
    this.totalSpent = 0.0,
    this.leadsGenerated = 0,
    this.wonStudents = 0,
    this.revenueGenerated = 0.0,
    this.targetAudience = 'Homens e Mulheres 25-45 | Interesses em Fitness',
    required this.utmCampaign,
    required this.createdAt,
    required this.updatedAt,
  });

  FunnelStage get stage => funnelStage;
  int get conversions => wonStudents;

  /// Custo por Lead (CPL)
  double get cpl => leadsGenerated > 0 ? (totalSpent / leadsGenerated) : 0.0;

  /// Custo de Aquisição de Cliente (CAC)
  double get cac => wonStudents > 0 ? (totalSpent / wonStudents) : 0.0;

  /// Retorno sobre Investimento em Anúncios (ROAS)
  double get roas => totalSpent > 0 ? (revenueGenerated / totalSpent) : 0.0;

  /// Taxa de Conversão de Leads em Alunos
  double get conversionRate =>
      leadsGenerated > 0 ? (wonStudents / leadsGenerated) * 100 : 0.0;

  MarketingCampaign copyWith({
    String? id,
    String? name,
    MarketingPlatform? platform,
    CampaignObjective? objective,
    FunnelStage? funnelStage,
    CampaignStatus? status,
    double? dailyBudget,
    double? totalSpent,
    int? leadsGenerated,
    int? wonStudents,
    double? revenueGenerated,
    String? targetAudience,
    String? utmCampaign,
    String? createdAt,
    String? updatedAt,
  }) {
    return MarketingCampaign(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      objective: objective ?? this.objective,
      funnelStage: funnelStage ?? this.funnelStage,
      status: status ?? this.status,
      dailyBudget: dailyBudget ?? this.dailyBudget,
      totalSpent: totalSpent ?? this.totalSpent,
      leadsGenerated: leadsGenerated ?? this.leadsGenerated,
      wonStudents: wonStudents ?? this.wonStudents,
      revenueGenerated: revenueGenerated ?? this.revenueGenerated,
      targetAudience: targetAudience ?? this.targetAudience,
      utmCampaign: utmCampaign ?? this.utmCampaign,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MarketingCampaign.fromJson(Map<String, dynamic> json) {
    return MarketingCampaign(
      id:
          json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Campanha Sem Nome',
      platform: MarketingPlatformExtension.fromString(
        json['platform'] as String?,
      ),
      objective: CampaignObjectiveExtension.fromString(
        json['objective'] as String?,
      ),
      funnelStage: FunnelStageExtension.fromString(
        json['funnel_stage'] as String?,
      ),
      status: CampaignStatusExtension.fromString(json['status'] as String?),
      dailyBudget: (json['daily_budget'] as num?)?.toDouble() ?? 20.0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
      leadsGenerated: (json['leads_generated'] as num?)?.toInt() ?? 0,
      wonStudents: (json['won_students'] as num?)?.toInt() ?? 0,
      revenueGenerated: (json['revenue_generated'] as num?)?.toDouble() ?? 0.0,
      targetAudience: json['target_audience'] as String? ?? '',
      utmCampaign: json['utm_campaign'] as String? ?? 'campanha_valex',
      createdAt:
          json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt:
          json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'platform': platform.value,
      'objective': objective.value,
      'funnel_stage': funnelStage.value,
      'status': status.value,
      'daily_budget': dailyBudget,
      'total_spent': totalSpent,
      'leads_generated': leadsGenerated,
      'won_students': wonStudents,
      'revenue_generated': revenueGenerated,
      'target_audience': targetAudience,
      'utm_campaign': utmCampaign,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

/// Entidade do Cofre de Criativos & Roteiros de Anúncio
class AdCreativeItem {
  final String id;
  final String title;
  final CreativeFormat format;
  final FunnelStage funnelStage;
  final String
  targetIcp; // 'Estagnado', 'Dores Articulares', 'Urgência TAF/Noiva'
  final String hookText; // Os primeiros 3 segundos do vídeo / Título da imagem
  final String bodyScript; // Roteiro completo do corpo do anúncio
  final String ctaText; // Chamada para ação final
  final String audioGuide; // Guia de entonação para gravação
  final List<String> tags;
  final int usesCount;
  final double estimatedCtr;

  const AdCreativeItem({
    required this.id,
    required this.title,
    required this.format,
    required this.funnelStage,
    required this.targetIcp,
    required this.hookText,
    required this.bodyScript,
    required this.ctaText,
    required this.audioGuide,
    this.tags = const [],
    this.usesCount = 0,
    this.estimatedCtr = 2.8,
  });

  FunnelStage get stage => funnelStage;

  factory AdCreativeItem.fromJson(Map<String, dynamic> json) {
    List<String> parsedTags = [];
    if (json['tags'] != null) {
      if (json['tags'] is List) {
        parsedTags = (json['tags'] as List).map((e) => e.toString()).toList();
      }
    }

    return AdCreativeItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      format: CreativeFormatExtension.fromString(json['format'] as String?),
      funnelStage: FunnelStageExtension.fromString(
        json['funnel_stage'] as String?,
      ),
      targetIcp: json['target_icp'] as String? ?? 'Geral',
      hookText: json['hook_text'] as String? ?? '',
      bodyScript: json['body_script'] as String? ?? '',
      ctaText: json['cta_text'] as String? ?? '',
      audioGuide: json['audio_guide'] as String? ?? '',
      tags: parsedTags,
      usesCount: (json['uses_count'] as num?)?.toInt() ?? 0,
      estimatedCtr: (json['estimated_ctr'] as num?)?.toDouble() ?? 2.5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'format': format.value,
      'funnel_stage': funnelStage.value,
      'target_icp': targetIcp,
      'hook_text': hookText,
      'body_script': bodyScript,
      'cta_text': ctaText,
      'audio_guide': audioGuide,
      'tags': tags,
      'uses_count': usesCount,
      'estimated_ctr': estimatedCtr,
    };
  }

  /// Biblioteca padrão de criativos validados de alta conversão
  static List<AdCreativeItem> get defaultCreatives => [
    const AdCreativeItem(
      id: 'cr_hook_dor_ombro',
      title: 'Por que seu ombro queima no Supino (Biomecânica)',
      format: CreativeFormat.videoReels,
      funnelStage: FunnelStage.tofu,
      targetIcp: 'Dores Articulares & Biomecânica',
      hookText:
          'Se o seu ombro dói quando você faz supino reto, para agora e assiste isso antes de rasgar o manguito!',
      bodyScript:
          '90% das pessoas cometem o erro de empurrar a barra com as escápulas soltas e os cotovelos abertos em 90 graus.\n\nIsso esmaga o tendão supraespinhal. O jeito correto é: fechar as escápulas no banco, criar um arco lombar estável e trazer os cotovelos a 45 graus.\n\nNo sistema VALEX, nós montamos a periodização exata respeitando a sua mobilidade articular para você treinar pesado sem nenhuma dor.',
      ctaText:
          'Clica no botão aqui embaixo e me chama no WhatsApp para eu analisar a postura do seu exercício gratuitamente!',
      audioGuide:
          'Tom enérgico de alerta nos primeiros 3s, passando para tom didático e autoridade científica no corpo.',
      tags: ['Biomecânica', 'Supino', 'Dores', 'TOFU'],
      estimatedCtr: 3.4,
    ),
    const AdCreativeItem(
      id: 'cr_estagnado_3_sinais',
      title: '3 Sinais de que seu treino está te fazendo perder massa',
      format: CreativeFormat.videoReels,
      funnelStage: FunnelStage.tofu,
      targetIcp: 'O Estagnado Frustrado',
      hookText:
          'Você treina 5 vezes por semana, cansa, mas quando se olha no espelho não vê músculo aparecendo? Cuidado com esses 3 erros!',
      bodyScript:
          'Erro 1: Trocar de ficha todo mês sem progredir carga real.\nErro 2: Fazer volume lixo (15 séries até a falha sem controle de recuperação).\nErro 3: Não periodizar estímulo mecânico vs metabólico.\n\nO que transforma seu corpo é a progressão milimétrica de tensão calculada cientificamente.',
      ctaText:
          'Envie uma mensagem no botão do anúncio e receba o diagnóstico da sua periodização no meu WhatsApp.',
      audioGuide:
          'Tom questionador, direto ao ponto, provocando quebra de crença comum.',
      tags: ['Hipertrofia', 'Estagnação', 'Volume de Treino'],
      estimatedCtr: 3.1,
    ),
    const AdCreativeItem(
      id: 'cr_anamnese_gratuita',
      title: 'Teste de Anamnese & Diagnóstico Corporal (MOFU)',
      format: CreativeFormat.carousel,
      funnelStage: FunnelStage.mofu,
      targetIcp: 'Geral / Consideração',
      hookText:
          'Descubra em 2 minutos por que seu metabolismo travou e qual a divisão ideal para sua rotina.',
      bodyScript:
          'Lâmina 1: Qual seu tipo de rotina diária? (Sedentária, Moderada, Intensa)\nLâmina 2: Qual a sua principal queixa? (Gordura abdominal vs Falta de volume)\nLâmina 3: Como a periodização individualizada VALEX reorganiza seus estímulos semanais.\nLâmina 4: Receba um planejamento exclusivo no seu WhatsApp.',
      ctaText:
          'Arraste para o lado e toque em "Fazer Avaliação Gratuita" para receber seu relatório no WhatsApp.',
      audioGuide: 'Formato carrossel interativo visual de alta densidade.',
      tags: ['Anamnese', 'Diagnóstico', 'Carrossel', 'MOFU'],
      estimatedCtr: 2.9,
    ),
    const AdCreativeItem(
      id: 'cr_antes_depois_bofu',
      title: 'Evolução de 90 Dias com Protocolo VALEX (BOFU)',
      format: CreativeFormat.socialProofCard,
      funnelStage: FunnelStage.bofu,
      targetIcp: 'Conversão / Prova Social',
      hookText:
          '-8kg de gordura e +3cm de braço em 12 semanas sem dietas malucas nem 2 horas na academia.',
      bodyScript:
          'Este é o resultado do aluno [Nome], que trabalha 9 horas por dia e só tinha 40 minutos para treinar 4x por semana.\n\nNós ajustamos os métodos de densidade no sistema VALEX e ele atingiu o melhor físico da vida dele.\n\nHoje estou abrindo as últimas 3 vagas da minha consultoria para o próximo ciclo de acompanhamento.',
      ctaText:
          'Toque em "Enviar Mensagem" e garanta uma das 3 vagas restantes com suporte direto no WhatsApp.',
      audioGuide:
          'Tom de fechamento comercial, prova irrefutável e escassez legítima.',
      tags: ['Antes e Depois', 'Fechamento', 'Remarketing', 'BOFU'],
      estimatedCtr: 4.2,
    ),
    const AdCreativeItem(
      id: 'cr_calc_roi_comparativo',
      title: 'Calculadora: Academia sem Personal vs Consultoria VALEX',
      format: CreativeFormat.roiCalculator,
      funnelStage: FunnelStage.mofu,
      targetIcp: 'Preço & Custo da Inação',
      hookText:
          'Quanto custa 1 ano jogado fora na academia vs 90 dias com método científico?',
      bodyScript:
          '• Cenário A: 12 meses de academia (R\$ 1.400) + Suplementos aleatórios (R\$ 800) + Zero resultado = R\$ 2.200 no lixo.\n• Cenário B: Consultoria VALEX por menos de R\$ 4,90/dia (12x) = Ficha periodizada, correção de vídeo semanal e evolução garantida.\n\nO que sai mais caro no final das contas?',
      ctaText:
          'Clica aqui e fale direto comigo para simular seu plano em até 12x no cartão.',
      audioGuide: 'Lógica financeira irrefutável focada em valor percebido.',
      tags: ['ROI', 'Comparativo', 'Preço', 'Gatilho de Valor'],
      estimatedCtr: 3.5,
    ),
  ];
}

/// Construtor de Parâmetros UTM e Links Rastreados
class UtmTrackerData {
  final String source; // ex: meta, tiktok, google, bio
  final String medium; // ex: reels, stories, feed, cpc
  final String campaign; // ex: hipertrofia_tofu_2026
  final String? content; // ex: video_dor_ombro_v1
  final String? term; // Palavra-chave opcional

  const UtmTrackerData({
    required this.source,
    required this.medium,
    required this.campaign,
    this.content,
    this.term,
  });

  /// Gera a querystring UTM padrão
  String toQueryString() {
    return Uri(queryParameters: _queryParameters).query;
  }

  Map<String, String> get _queryParameters => {
    'utm_source': source,
    'utm_medium': medium,
    'utm_campaign': campaign,
    if (content != null && content!.isNotEmpty) 'utm_content': content!,
    if (term != null && term!.isNotEmpty) 'utm_term': term!,
  };

  /// Etiqueta legível e sem ambiguidade para atribuição via WhatsApp.
  String get attributionTag => '[Ref: ${toQueryString()}]';

  /// Constrói a URL completa para uma landing page
  String buildLandingPageUrl(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    return uri
        .replace(queryParameters: {...uri.queryParameters, ..._queryParameters})
        .toString();
  }

  /// Constrói o link direto do WhatsApp com mensagem parametrizada para captura de UTM
  String buildWhatsAppUrl(
    String rawPhone, {
    String defaultGreeting =
        'Olá! Vi seu anúncio e gostaria de saber mais sobre a consultoria de treinos VALEX.',
  }) {
    final cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final fullMessage = '$defaultGreeting\n\n$attributionTag';
    return 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(fullMessage)}';
  }

  /// Extrai UTMs de uma mensagem pré-preenchida do WhatsApp caso o lead tenha enviado a tag
  static Map<String, String>? parseFromWhatsAppMessage(String message) {
    final regex = RegExp(r'\[Ref:\s*([^\]]+)\]', caseSensitive: false);
    final match = regex.firstMatch(message);
    if (match == null || match.groupCount < 1) return null;

    final ref = match.group(1)!.trim();
    if (ref.contains('=')) {
      try {
        final params = Uri.splitQueryString(ref);
        final source = params['utm_source'];
        final campaign = params['utm_campaign'];
        if (source == null ||
            source.isEmpty ||
            campaign == null ||
            campaign.isEmpty) {
          return null;
        }
        return {
          'utm_source': source.toLowerCase(),
          'utm_medium': (params['utm_medium'] ?? 'direct').toLowerCase(),
          'utm_campaign': campaign.toLowerCase(),
          if (params['utm_content'] case final content? when content.isNotEmpty)
            'utm_content': content.toLowerCase(),
          if (params['utm_term'] case final term? when term.isNotEmpty)
            'utm_term': term.toLowerCase(),
        };
      } on FormatException {
        return null;
      }
    }

    // Compatibilidade com links já publicados no formato SOURCE_MEDIUM_CAMPAIGN.
    final parts = ref.split('_');
    return {
      'utm_source': parts.isNotEmpty ? parts[0].toLowerCase() : 'whatsapp',
      'utm_medium': parts.length > 1 ? parts[1].toLowerCase() : 'direct',
      'utm_campaign': parts.length > 2
          ? parts.sublist(2).join('_').toLowerCase()
          : 'geral',
    };
  }
}

/// Métricas Consolidadas de Performance de Marketing & Mídia
class MarketingMetricsSummary {
  final double totalSpend;
  final int totalLeads;
  final int totalWonStudents;
  final double totalRevenueGenerated;
  final int activeCampaignsCount;
  final double averageCpl;
  final double averageCac;
  final double overallRoas;
  final double conversionRate;

  MarketingMetricsSummary({
    this.totalSpend = 0.0,
    this.totalLeads = 0,
    this.totalWonStudents = 0,
    this.totalRevenueGenerated = 0.0,
    this.activeCampaignsCount = 0,
    this.averageCpl = 0.0,
    this.averageCac = 0.0,
    this.overallRoas = 0.0,
    this.conversionRate = 0.0,
  });

  double get globalRoas => overallRoas;
  double get totalSpent => totalSpend;
  int get totalLeadsGenerated => totalLeads;
  int get totalConversions => totalWonStudents;

  factory MarketingMetricsSummary.calculate(List<MarketingCampaign> campaigns) {
    if (campaigns.isEmpty) return MarketingMetricsSummary();

    double spend = 0.0;
    int leads = 0;
    int won = 0;
    double revenue = 0.0;
    int activeCount = 0;

    for (final c in campaigns) {
      spend += c.totalSpent;
      leads += c.leadsGenerated;
      won += c.wonStudents;
      revenue += c.revenueGenerated;
      if (c.status == CampaignStatus.active) {
        activeCount++;
      }
    }

    final double cpl = leads > 0 ? spend / leads : 0.0;
    final double cac = won > 0 ? spend / won : 0.0;
    final double roas = spend > 0 ? revenue / spend : 0.0;
    final double convRate = leads > 0 ? (won / leads) * 100 : 0.0;

    return MarketingMetricsSummary(
      totalSpend: spend,
      totalLeads: leads,
      totalWonStudents: won,
      totalRevenueGenerated: revenue,
      activeCampaignsCount: activeCount,
      averageCpl: cpl,
      averageCac: cac,
      overallRoas: roas,
      conversionRate: convRate,
    );
  }
}
