import 'dart:convert';

/// Status do Lead no Pipeline / Funil Comercial
enum LeadStatus {
  newLead, // 'new'
  anamneseSent, // 'anamnese_sent'
  proposalSent, // 'proposal_sent'
  negotiating, // 'negotiating'
  won, // 'won' - Convertido em Aluno
  lost, // 'lost' - Arquivado / Perdido
}

extension LeadStatusExtension on LeadStatus {
  String get value {
    switch (this) {
      case LeadStatus.newLead:
        return 'new';
      case LeadStatus.anamneseSent:
        return 'anamnese_sent';
      case LeadStatus.proposalSent:
        return 'proposal_sent';
      case LeadStatus.negotiating:
        return 'negotiating';
      case LeadStatus.won:
        return 'won';
      case LeadStatus.lost:
        return 'lost';
    }
  }

  String get label {
    switch (this) {
      case LeadStatus.newLead:
        return 'Novo Lead';
      case LeadStatus.anamneseSent:
        return 'Anamnese';
      case LeadStatus.proposalSent:
        return 'Proposta';
      case LeadStatus.negotiating:
        return 'Negociação';
      case LeadStatus.won:
        return 'Convertido (Aluno)';
      case LeadStatus.lost:
        return 'Perdido';
    }
  }

  static LeadStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'new':
      case 'new_lead':
      case 'novo':
        return LeadStatus.newLead;
      case 'anamnese_sent':
      case 'anamnese':
        return LeadStatus.anamneseSent;
      case 'proposal_sent':
      case 'proposta':
        return LeadStatus.proposalSent;
      case 'negotiating':
      case 'negociacao':
        return LeadStatus.negotiating;
      case 'won':
      case 'ganho':
      case 'convertido':
        return LeadStatus.won;
      case 'lost':
      case 'perdido':
        return LeadStatus.lost;
      default:
        return LeadStatus.newLead;
    }
  }
}

/// Nível de Prioridade / Temperatura do Lead
enum LeadPriority {
  hot, // 'hot' - Alta prontidão (Score >= 75)
  warm, // 'warm' - Interessado (Score 45-74)
  cold, // 'cold' - Frio (Score < 45)
}

extension LeadPriorityExtension on LeadPriority {
  String get value {
    switch (this) {
      case LeadPriority.hot:
        return 'hot';
      case LeadPriority.warm:
        return 'warm';
      case LeadPriority.cold:
        return 'cold';
    }
  }

  String get label {
    switch (this) {
      case LeadPriority.hot:
        return 'Diamante 🔥';
      case LeadPriority.warm:
        return 'Ouro ⚡';
      case LeadPriority.cold:
        return 'Prata ❄️';
    }
  }

  static LeadPriority fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'hot':
      case 'quente':
      case 'diamante':
        return LeadPriority.hot;
      case 'warm':
      case 'morno':
      case 'ouro':
        return LeadPriority.warm;
      case 'cold':
      case 'frio':
      case 'prata':
        return LeadPriority.cold;
      default:
        return LeadPriority.warm;
    }
  }
}

/// Nota / Histórico de Interação com o Lead
class LeadNote {
  final String id;
  final String content;
  final String timestamp;
  final String author;

  LeadNote({
    required this.id,
    required this.content,
    required this.timestamp,
    this.author = 'Treinador',
  });

  factory LeadNote.fromJson(Map<String, dynamic> json) {
    return LeadNote(
      id:
          json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      content: json['content'] as String? ?? '',
      timestamp:
          json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      author: json['author'] as String? ?? 'Treinador',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'timestamp': timestamp,
      'author': author,
    };
  }
}

/// Battlecard de Objeção Tática para Vendas
class BattlecardItem {
  final String id;
  final String title;
  final String category;
  final String rootCause;
  final String whatsappScript;
  final String audioScript;
  final String keyBenefit;

  const BattlecardItem({
    required this.id,
    required this.title,
    required this.category,
    required this.rootCause,
    required this.whatsappScript,
    required this.audioScript,
    required this.keyBenefit,
  });

  static List<BattlecardItem> get defaultBattlecards => [
    const BattlecardItem(
      id: 'obj_preco',
      title: 'Achei caro / Sem dinheiro agora',
      category: 'Preço & Valor',
      rootCause: 'Falta de percepção do custo da estagnação vs investimento.',
      keyBenefit: 'Menos de R\$ 4,90/dia (parcelamento em até 12x).',
      whatsappScript:
          'Te entendo perfeitamente, [Nome]. Mas deixa eu te fazer uma pergunta sincera: quanto você já gastou nos últimos meses com mensalidade de academia, suplementos e lanches no fim de semana sem ver o resultado que você queria no espelho?\n\nA minha consultoria custa menos de R\$ 4,90 por dia. O que sai mais caro: investir 1 cafezinho por dia para transformar seu corpo com periodização científica, ou continuar pagando academia todo mês sem mudar nada?\n\nConsigo parcelar seu plano em até 12x no cartão. Vamos garantir sua vaga hoje?',
      audioScript:
          'Roteiro de Áudio (25 segundos):\n1. Empatia: "Fala [Nome]! Olha, entendo perfeitamente que a gente precisa priorizar onde coloca o dinheiro."\n2. Reenquadramento: "Mas pensa o seguinte: meu foco não é te passar uma fichinha de gaveta, é te economizar 1 ano de esforço jogado fora na academia ou de dores no ombro."\n3. Fechamento: "Eu consigo dividir seu protocolo em até 12x no cartão. Vamos confirmar sua matrícula agora para eu já liberar seu questionário?"',
    ),
    const BattlecardItem(
      id: 'obj_sozinho',
      title: 'Já treino sozinho / Pego na internet',
      category: 'Autonomia',
      rootCause:
          'Ilusão de autossuficiência e excesso de informação desconectada.',
      keyBenefit:
          'Periodização individualizada no sistema VALEX sem risco de lesão.',
      whatsappScript:
          'A internet está cheia de exercícios excelentes, [Nome], mas o exercício certo na ordem errada ou com volume inadequado para o seu biotipo é a receita perfeita para estagnar ou lesionar ombro/lombar.\n\nO meu trabalho é analisar suas limitações e periodizar suas cargas e volume semana a semana no sistema VALEX para você ter o dobro de resultado na metade do tempo.',
      audioScript:
          'Roteiro de Áudio (20 segundos):\n1. Empatia: "Com certeza, [Nome], hoje tem muito conteúdo bom no Instagram e YouTube."\n2. Reenquadramento: "Só que a diferença é que o influenciador não sabe se você tem encurtamento, desvio ou quanto tempo você realmente tem para treinar."\n3. Fechamento: "Com o meu protocolo, você tem treino sob medida no app e meu acompanhamento semanal. Topa fazer o teste este mês?"',
    ),
    const BattlecardItem(
      id: 'obj_tempo',
      title: 'Não tenho tempo para treinar',
      category: 'Rotina & Frequência',
      rootCause: 'Crença de que precisa passar 2 horas na academia todo dia.',
      keyBenefit:
          'Treinos de 35 a 45 minutos com máxima densidade de estímulo.',
      whatsappScript:
          'Essa é a melhor parte, [Nome]: eu monto o seu protocolo exatamente para o tempo que você tem disponível!\n\nSe você só tiver 40 minutos 3 vezes por semana, eu ajusto a intensidade e os métodos avançados para você ter mais resultado do que quem passa 2 horas enrolando na academia. Menos tempo, mais intensidade e resultado real.',
      audioScript:
          'Roteiro de Áudio (20 segundos):\n1. Empatia: "Entendo total a correria do seu dia a dia, [Nome]."\n2. Reenquadramento: "Mas você não precisa morar na academia. Com 40 minutinhos bem calculados, você estimula o músculo certo e não perde tempo."\n3. Fechamento: "Deixa eu montar sua periodização para a sua rotina real? Tenho certeza de que você vai se surpreender."',
    ),
    const BattlecardItem(
      id: 'obj_online',
      title: 'Será que consultoria online funciona?',
      category: 'Confiança & Método',
      rootCause: 'Medo de abandono pós-venda e falta de suporte.',
      keyBenefit:
          'Suporte semanal no WhatsApp + Correção de postura por vídeo.',
      whatsappScript:
          'Funciona muito porque você não fica solto, [Nome]!\n\nNo sistema VALEX, você recebe cada exercício com vídeo em alta resolução demonstrando a postura exata. Além disso, você pode me filmar executando qualquer movimento para eu corrigir sua biomecânica direto no WhatsApp, além de ter ajustes periódicos de treino.',
      audioScript:
          'Roteiro de Áudio (25 segundos):\n1. Empatia: "É super normal ter essa dúvida se você nunca fez consultoria online antes."\n2. Reenquadramento: "A verdade é que meu acompanhamento é muito mais próximo do que o do instrutor da academia que atende 50 pessoas ao mesmo tempo."\n3. Fechamento: "Você me manda o vídeo do seu treino, eu analiso e corrijo. Seus resultados são garantidos."',
    ),
    const BattlecardItem(
      id: 'obj_depois',
      title: 'Vou pensar e te respondo depois',
      category: 'Indecisão & Urgência',
      rootCause: 'Falta de prioridade imediata e medo de assumir compromisso.',
      keyBenefit: 'Garantia de bônus de anamnese e reserva de vaga na grade.',
      whatsappScript:
          'Sem problemas, [Nome]! Fica à vontade para avaliar.\n\nSó me avisa se ficou alguma dúvida sobre a entrega ou os treinos. Como eu atendo com limite de alunos para conseguir acompanhar de perto e corrigir vídeos, só consigo segurar o bônus da avaliação postural até hoje às 20h. Posso reservar a sua vaga?',
      audioScript:
          'Roteiro de Áudio (20 segundos):\n1. Empatia: "Claro, [Nome], pensa com calma sim!"\n2. Reenquadramento: "Só te aviso porque estou fechando a grade de acompanhamento desta semana para poder focar nos novos treinos."\n3. Fechamento: "Se quiser que eu segure a sua vaga e o bônus da anamnese, me dá um toque que eu já travo aqui para você!"',
    ),
    const BattlecardItem(
      id: 'obj_sumiu',
      title: 'Já fiz consultoria antes e o personal sumiu',
      category: 'Trauma & Frustração Anterior',
      rootCause: 'Experiência negativa com profissionais desorganizados.',
      keyBenefit: 'Check-in semanal ativo + Garantia incondicional de 15 dias.',
      whatsappScript:
          'Eu sei exatamente como é isso, [Nome], e infelizmente muitos instrutores pegam o dinheiro e somem.\n\nNo meu método com o ecossistema VALEX, o seu treino é 100% digital com vídeos, e nós temos um check-in obrigatório toda semana no WhatsApp para avaliar sua evolução e ajustar as cargas. Se nos primeiros 15 dias você achar que não teve atenção, eu devolvo 100% do seu valor.',
      audioScript:
          'Roteiro de Áudio (25 segundos):\n1. Empatia: "Poxa, [Nome], sinto muito que você tenha passado por isso. Isso queima o mercado de personal."\n2. Reenquadramento: "Aqui no VALEX é o oposto: se você não me mandar seu feedback semanal, eu mesmo te cobro no WhatsApp para ver como foi o treino."\n3. Fechamento: "Te dou 15 dias de garantia incondicional. Vamos começar hoje sem nenhum risco para você?"',
    ),
  ];
}

/// Entidade de Lead Comercial no CRM do VALEX
class LeadItem {
  final String id;
  final String name;
  final String phone;
  final String instagram;
  final String email;
  final String objective;
  final String
  originChannel; // 'meta_ads', 'instagram_direct', 'indicacao', 'whatsapp', 'google'
  final String? targetPlanId;
  final String targetPlanName;
  final double estimatedValue;
  final int score; // 0 a 100
  final LeadStatus status;
  final LeadPriority priority;
  final String? lossReason;
  final List<LeadNote> notes;
  final String? utmSource;
  final String? utmMedium;
  final String? utmCampaign;
  final String? utmContent;
  final String? scheduledFollowUpDate; // ISO String: "2026-08-28T14:00:00"
  final String? scheduledFollowUpNote; // "Pediu para ligar dia do salário"
  final int
  followUpStep; // Cadência de 7 Passos (0 = não iniciado, 1-7 = passo atual)
  final String createdAt;
  final String updatedAt;
  final String? lastContactAt;

  LeadItem({
    required this.id,
    required this.name,
    this.phone = '',
    this.instagram = '',
    this.email = '',
    this.objective = '',
    this.originChannel = 'meta_ads',
    this.targetPlanId,
    this.targetPlanName = '',
    this.estimatedValue = 0.0,
    int? score,
    this.status = LeadStatus.newLead,
    LeadPriority? priority,
    this.lossReason,
    this.notes = const [],
    this.utmSource,
    this.utmMedium,
    this.utmCampaign,
    this.utmContent,
    this.scheduledFollowUpDate,
    this.scheduledFollowUpNote,
    this.followUpStep = 0,
    required this.createdAt,
    required this.updatedAt,
    this.lastContactAt,
  }) : score =
           score ??
           _calculateScore(originChannel, estimatedValue, objective, status),
       priority =
           priority ??
           _inferPriority(
             score ??
                 _calculateScore(
                   originChannel,
                   estimatedValue,
                   objective,
                   status,
                 ),
           );

  /// Retorna se há retorno agendado
  bool get hasScheduledFollowUp =>
      scheduledFollowUpDate != null && scheduledFollowUpDate!.isNotEmpty;

  /// Verifica se o retorno agendado é para hoje ou já passou (atrasado)
  bool get isFollowUpDueTodayOrOverdue {
    if (!hasScheduledFollowUp) return false;
    try {
      final scheduled = DateTime.parse(scheduledFollowUpDate!);
      final now = DateTime.now();
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      return scheduled.isBefore(todayEnd);
    } catch (_) {
      return false;
    }
  }

  /// Verifica se o retorno é estritamente hoje
  bool get isFollowUpToday {
    if (!hasScheduledFollowUp) return false;
    try {
      final scheduled = DateTime.parse(scheduledFollowUpDate!);
      final now = DateTime.now();
      return scheduled.year == now.year &&
          scheduled.month == now.month &&
          scheduled.day == now.day;
    } catch (_) {
      return false;
    }
  }

  /// Legenda visual do passo atual na Cadência de 7 Passos
  String get followUpStepLabel {
    const labels = [
      '',
      'Passo 1/7 📩 Recepção',
      'Passo 2/7 📋 Anamnese',
      'Passo 3/7 💬 Proposta',
      'Passo 4/7 ⭐ Prova Social',
      'Passo 5/7 ⏳ Urgência Fraca',
      'Passo 6/7 🔥 Urgência Forte',
      'Passo 7/7 🎯 Fechamento Final',
    ];
    if (followUpStep < 1 || followUpStep > 7) return '';
    return labels[followUpStep];
  }

  /// Busca instantânea em múltiplos campos do lead
  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    if (name.toLowerCase().contains(q)) return true;
    if (phone.contains(q)) return true;
    if (instagram.toLowerCase().contains(q)) return true;
    if (objective.toLowerCase().contains(q)) return true;
    if (targetPlanName.toLowerCase().contains(q)) return true;
    if (notes.any((n) => n.content.toLowerCase().contains(q))) return true;
    if ((utmSource ?? '').toLowerCase().contains(q)) return true;
    return false;
  }

  static int _calculateScore(
    String origin,
    double value,
    String objective,
    LeadStatus status,
  ) {
    int points = 0;

    // 1. Canal de Origem (até 25 pts)
    if (origin == 'indicacao') {
      points += 25;
    } else if (origin == 'whatsapp' || origin == 'instagram_direct') {
      points += 20;
    } else if (origin == 'meta_ads') {
      points += 15;
    } else {
      points += 10;
    }

    // 2. Ticket / Valor Estimado (até 30 pts)
    if (value >= 700) {
      points += 30;
    } else if (value >= 350) {
      points += 22;
    } else if (value > 0) {
      points += 15;
    } else {
      points += 10;
    }

    // 3. Dor e Clareza de Objetivo (até 25 pts)
    final obj = objective.toLowerCase();
    if (obj.contains('dor') ||
        obj.contains('lesao') ||
        obj.contains('reab') ||
        obj.contains('casamento') ||
        obj.contains('taf')) {
      points += 25; // Dor de alta urgência
    } else if (obj.contains('hipertrofia') ||
        obj.contains('emagrecimento') ||
        obj.contains('defin')) {
      points += 20;
    } else if (obj.isNotEmpty) {
      points += 15;
    } else {
      points += 5;
    }

    // 4. Estágio no Funil (até 20 pts)
    if (status == LeadStatus.proposalSent || status == LeadStatus.negotiating) {
      points += 20;
    } else if (status == LeadStatus.anamneseSent) {
      points += 15;
    } else if (status == LeadStatus.newLead) {
      points += 10;
    }

    return points.clamp(0, 100);
  }

  static LeadPriority _inferPriority(int calculatedScore) {
    if (calculatedScore >= 75) return LeadPriority.hot;
    if (calculatedScore >= 45) return LeadPriority.warm;
    return LeadPriority.cold;
  }

  LeadItem copyWith({
    String? id,
    String? name,
    String? phone,
    String? instagram,
    String? email,
    String? objective,
    String? originChannel,
    String? targetPlanId,
    String? targetPlanName,
    double? estimatedValue,
    int? score,
    LeadStatus? status,
    LeadPriority? priority,
    String? lossReason,
    List<LeadNote>? notes,
    String? utmSource,
    String? utmMedium,
    String? utmCampaign,
    String? utmContent,
    String? scheduledFollowUpDate,
    String? scheduledFollowUpNote,
    bool clearScheduledFollowUp = false,
    int? followUpStep,
    String? createdAt,
    String? updatedAt,
    String? lastContactAt,
  }) {
    final updatedScore =
        score ??
        (estimatedValue != null ||
                objective != null ||
                status != null ||
                originChannel != null
            ? _calculateScore(
                originChannel ?? this.originChannel,
                estimatedValue ?? this.estimatedValue,
                objective ?? this.objective,
                status ?? this.status,
              )
            : this.score);

    return LeadItem(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      instagram: instagram ?? this.instagram,
      email: email ?? this.email,
      objective: objective ?? this.objective,
      originChannel: originChannel ?? this.originChannel,
      targetPlanId: targetPlanId ?? this.targetPlanId,
      targetPlanName: targetPlanName ?? this.targetPlanName,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      score: updatedScore,
      status: status ?? this.status,
      priority: priority ?? _inferPriority(updatedScore),
      lossReason: lossReason ?? this.lossReason,
      notes: notes ?? this.notes,
      utmSource: utmSource ?? this.utmSource,
      utmMedium: utmMedium ?? this.utmMedium,
      utmCampaign: utmCampaign ?? this.utmCampaign,
      utmContent: utmContent ?? this.utmContent,
      scheduledFollowUpDate: clearScheduledFollowUp
          ? null
          : (scheduledFollowUpDate ?? this.scheduledFollowUpDate),
      scheduledFollowUpNote: clearScheduledFollowUp
          ? null
          : (scheduledFollowUpNote ?? this.scheduledFollowUpNote),
      followUpStep: followUpStep ?? this.followUpStep,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastContactAt: lastContactAt ?? this.lastContactAt,
    );
  }

  factory LeadItem.fromJson(Map<String, dynamic> json) {
    List<LeadNote> parsedNotes = [];
    if (json['notes'] != null) {
      if (json['notes'] is List) {
        parsedNotes = (json['notes'] as List)
            .map(
              (e) => e is Map<String, dynamic>
                  ? LeadNote.fromJson(e)
                  : LeadNote(id: '', content: e.toString(), timestamp: ''),
            )
            .toList();
      } else if (json['notes'] is String &&
          (json['notes'] as String).isNotEmpty) {
        try {
          final decoded = jsonDecode(json['notes'] as String);
          if (decoded is List) {
            parsedNotes = decoded
                .map((e) => LeadNote.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        } catch (_) {}
      }
    }

    final val = (json['estimated_value'] as num?)?.toDouble() ?? 0.0;
    final obj = json['objective'] as String? ?? '';
    final orig = json['origin_channel'] as String? ?? 'meta_ads';
    final st = LeadStatusExtension.fromString(json['status'] as String?);
    final rawScore = json['score'] as int?;
    final finalScore = rawScore ?? _calculateScore(orig, val, obj, st);

    return LeadItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Lead Sem Nome',
      phone: json['phone'] as String? ?? '',
      instagram: json['instagram'] as String? ?? '',
      email: json['email'] as String? ?? '',
      objective: obj,
      originChannel: orig,
      targetPlanId: json['target_plan_id'] as String?,
      targetPlanName: json['target_plan_name'] as String? ?? '',
      estimatedValue: val,
      score: finalScore,
      status: st,
      priority: json['priority'] != null
          ? LeadPriorityExtension.fromString(json['priority'] as String?)
          : _inferPriority(finalScore),
      lossReason: json['loss_reason'] as String?,
      notes: parsedNotes,
      utmSource: json['utm_source'] as String?,
      utmMedium: json['utm_medium'] as String?,
      utmCampaign: json['utm_campaign'] as String?,
      utmContent: json['utm_content'] as String?,
      scheduledFollowUpDate: json['scheduled_follow_up_date'] as String?,
      scheduledFollowUpNote: json['scheduled_follow_up_note'] as String?,
      followUpStep: (json['follow_up_step'] as num?)?.toInt() ?? 0,
      createdAt:
          json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt:
          json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      lastContactAt: json['last_contact_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'instagram': instagram,
      'email': email,
      'objective': objective,
      'origin_channel': originChannel,
      'target_plan_id': targetPlanId,
      'target_plan_name': targetPlanName,
      'estimated_value': estimatedValue,
      'score': score,
      'status': status.value,
      'priority': priority.value,
      'loss_reason': lossReason,
      'notes': notes.map((n) => n.toJson()).toList(),
      'utm_source': utmSource,
      'utm_medium': utmMedium,
      'utm_campaign': utmCampaign,
      'utm_content': utmContent,
      'scheduled_follow_up_date': scheduledFollowUpDate,
      'scheduled_follow_up_note': scheduledFollowUpNote,
      'follow_up_step': followUpStep,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'last_contact_at': lastContactAt,
    };
  }
}

/// Métricas e Indicadores Consolidados do Funil de Vendas
class SalesMetricsData {
  final int totalLeads;
  final int activeLeads;
  final int wonLeads;
  final int lostLeads;
  final double conversionRate;
  final double totalEstimatedPipelineValue;
  final double totalWonRevenue;
  final int hotLeadsCount;
  final int scheduledFollowUpsTodayCount;
  final double averageScore;

  SalesMetricsData({
    this.totalLeads = 0,
    this.activeLeads = 0,
    this.wonLeads = 0,
    this.lostLeads = 0,
    this.conversionRate = 0.0,
    this.totalEstimatedPipelineValue = 0.0,
    this.totalWonRevenue = 0.0,
    this.hotLeadsCount = 0,
    this.scheduledFollowUpsTodayCount = 0,
    this.averageScore = 0.0,
  });

  factory SalesMetricsData.calculate(List<LeadItem> leads) {
    if (leads.isEmpty) return SalesMetricsData();

    int total = leads.length;
    int won = 0;
    int lost = 0;
    int active = 0;
    int hot = 0;
    int scheduledToday = 0;
    int totalScore = 0;
    double pipelineValue = 0.0;
    double wonRevenue = 0.0;

    for (final l in leads) {
      totalScore += l.score;
      if (l.isFollowUpDueTodayOrOverdue &&
          l.status != LeadStatus.won &&
          l.status != LeadStatus.lost) {
        scheduledToday++;
      }
      if (l.status == LeadStatus.won) {
        won++;
        wonRevenue += l.estimatedValue;
      } else if (l.status == LeadStatus.lost) {
        lost++;
      } else {
        active++;
        pipelineValue += l.estimatedValue;
        if (l.priority == LeadPriority.hot || l.score >= 75) {
          hot++;
        }
      }
    }

    final double convRate = total > 0 ? (won / total) * 100 : 0.0;
    final double avgScore = total > 0 ? totalScore / total : 0.0;

    return SalesMetricsData(
      totalLeads: total,
      activeLeads: active,
      wonLeads: won,
      lostLeads: lost,
      conversionRate: convRate,
      totalEstimatedPipelineValue: pipelineValue,
      totalWonRevenue: wonRevenue,
      hotLeadsCount: hot,
      scheduledFollowUpsTodayCount: scheduledToday,
      averageScore: avgScore,
    );
  }
}
