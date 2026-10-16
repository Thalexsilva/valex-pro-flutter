import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/marketing_models.dart';
import '../../repositories/marketing_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'campaign_form_dialog.dart';
import 'creative_detail_sheet.dart';
import 'funnel_simulator_sheet.dart';
import 'social_proof_card_dialog.dart';
import 'teleprompter_dialog.dart';
import 'utm_generator_sheet.dart';

class MarketingView extends StatefulWidget {
  const MarketingView({super.key, this.repository});

  final MarketingRepository? repository;

  @override
  State<MarketingView> createState() => _MarketingViewState();
}

class _MarketingViewState extends State<MarketingView>
    with SingleTickerProviderStateMixin {
  late final MarketingRepository _repository =
      widget.repository ?? MarketingRepository();

  late TabController _tabController;
  List<MarketingCampaign> _campaigns = [];
  List<AdCreativeItem> _creatives = [];
  MarketingMetricsSummary _metrics = MarketingMetricsSummary();
  bool _isLoading = true;
  bool _loadFailed = false;
  String _selectedStageFilter = 'ALL';
  Set<int> _weeklyDone = {};
  bool _savingChecklist = false;

  static const _weeklyTasks = <(String, String)>[
    ('Seg', 'Grave 1 vídeo de 30s no Teleprompter (Tema: Treino sem dor)'),
    ('Qua', 'Poste um Stories de Pizza vs Treino com seu link de WhatsApp'),
    ('Sex', 'Mande a mensagem de indicação (Boca a Boca) para 2 alunos fiéis'),
    ('Dom', 'Abra o VALEX, veja quantos contatos chamaram e prepare as fichas'),
  ];

  Future<void> _toggleWeeklyTask(int index) async {
    if (_savingChecklist) return;
    _savingChecklist = true;
    final previous = {..._weeklyDone};
    final next = {..._weeklyDone};
    if (!next.remove(index)) next.add(index);
    setState(() => _weeklyDone = next);
    bool saved;
    try {
      saved = await _repository.saveWeeklyChecklist(DateTime.now(), next);
    } catch (_) {
      saved = false;
    }
    _savingChecklist = false;
    if (!saved && mounted) {
      setState(() => _weeklyDone = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível guardar o checklist. Tente novamente.',
          ),
        ),
      );
    }
  }

  Future<void> _saveCampaign(
    MarketingCampaign campaign, {
    String? successMessage,
  }) async {
    try {
      await _repository.saveCampaign(campaign);
      await _loadData();
      if (mounted && successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppColors.emerald,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Não foi possível salvar a campanha neste aparelho.',
          ),
          backgroundColor: AppColors.crimson,
          action: SnackBarAction(
            label: 'TENTAR NOVAMENTE',
            textColor: Colors.white,
            onPressed: () =>
                _saveCampaign(campaign, successMessage: successMessage),
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final campaigns = await _repository.getCampaigns();
      final creatives = await _repository.getCreatives();
      final metrics = await _repository.getMetricsSummary();
      final weeklyDone = await _repository.getWeeklyChecklist(DateTime.now());

      if (mounted) {
        setState(() {
          _campaigns = campaigns;
          _creatives = creatives;
          _metrics = metrics;
          _weeklyDone = weeklyDone;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadFailed = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openNewCampaignDialog() async {
    final result = await showDialog<MarketingCampaign>(
      context: context,
      builder: (ctx) => const CampaignFormDialog(),
    );

    if (result != null) {
      await _saveCampaign(
        result,
        successMessage: 'Campanha "${result.name}" criada com sucesso!',
      );
    }
  }

  Future<void> _openEditCampaignDialog(MarketingCampaign campaign) async {
    final result = await showDialog<MarketingCampaign>(
      context: context,
      builder: (ctx) => CampaignFormDialog(campaign: campaign),
    );

    if (result != null) {
      await _saveCampaign(result);
    }
  }

  Future<void> _toggleCampaignStatus(MarketingCampaign campaign) async {
    try {
      await _repository.toggleCampaignStatus(campaign.id);
      await _loadData();
    } catch (_) {
      _showCampaignMutationError();
    }
  }

  void _showCampaignMutationError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Não foi possível atualizar a campanha. Tente novamente.',
        ),
        backgroundColor: AppColors.crimson,
      ),
    );
  }

  Future<void> _deleteCampaign(MarketingCampaign campaign) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.carbon,
        title: const Text('Excluir Campanha?'),
        content: Text('Tem certeza que deseja excluir "${campaign.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repository.deleteCampaign(campaign.id);
        await _loadData();
      } catch (_) {
        _showCampaignMutationError();
      }
    }
  }

  void _openUtmSheet({MarketingCampaign? campaign}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UtmGeneratorSheet(
        availableCampaigns: _campaigns,
        initialCampaignTag: campaign?.utmCampaign,
      ),
    );
  }

  void _openFunnelSimulator() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const FunnelSimulatorSheet(),
    );
  }

  void _openSocialProofGenerator() {
    showDialog(
      context: context,
      builder: (ctx) => const SocialProofCardDialog(),
    );
  }

  void _openTeleprompter(AdCreativeItem creative) {
    showDialog(
      context: context,
      builder: (ctx) => TeleprompterDialog(creative: creative),
    );
  }

  void _openCreativeSheet(AdCreativeItem creative) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreativeDetailSheet(creative: creative),
    );
  }

  void _showHowItWorksDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.carbon2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.blueLight),
        ),
        title: Row(
          children: const [
            Icon(Icons.lightbulb, color: AppColors.gold, size: 24),
            SizedBox(width: 8),
            Text(
              'Como Conseguir Alunos?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Você não precisa entender de marketing ou tecnologia. O VALEX faz o trabalho pesado para você em 3 passos simples:',
                style: TextStyle(
                  color: AppColors.steel,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 16),
              const _ExplainingStep(
                number: '1',
                title: 'Escolha um Roteiro Pronto',
                desc:
                    'Vá na aba "O Que Falar no Vídeo". Escolha um tema (ex: Treino sem dor) e toque em "Gravar c/ Teleprompter". O texto sobe na tela do seu celular para você só ler naturally sem gaguejar!',
                color: AppColors.crimson,
              ),
              const SizedBox(height: 12),
              const _ExplainingStep(
                number: '2',
                title: 'Pegue o Link do WhatsApp',
                desc:
                    'Toque em "Link do Meu WhatsApp". Coloque esse link no seu Instagram (nos Stories ou na Bio). Quando o aluno clica, ele já te manda uma mensagem pronta dizendo que quer treinar!',
                color: AppColors.emerald,
              ),
              const SizedBox(height: 12),
              const _ExplainingStep(
                number: '3',
                title: 'Responda e Feche a Matrícula',
                desc:
                    'Se o aluno perguntar valores ou disser que "vai pensar", vá na aba "Mensagens & Imagens" e copie a resposta que quebra a objeção com 1 toque!',
                color: AppColors.gold,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'ENTENDI, VAMOS LÁ!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showGoalPlannerDialog() {
    int targetStudents = 5;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final dailyBudget = ((targetStudents * 120) / 30).round();
          final monthlyBudget = dailyBudget * 30;
          final expectedLeads = targetStudents * 8;
          final estimatedRevenue = targetStudents * 350;

          return AlertDialog(
            backgroundColor: AppColors.carbon2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.purpleAccent),
            ),
            title: Row(
              children: const [
                Icon(Icons.flag_rounded, color: Colors.purpleAccent, size: 24),
                SizedBox(width: 8),
                Text(
                  'Planejador de Metas do Mês',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quantos alunos novos você quer matricular este mês?',
                    style: TextStyle(color: AppColors.steel, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [3, 5, 10, 15].map((qty) {
                      final isSelected = targetStudents == qty;
                      return GestureDetector(
                        onTap: () => setDialogState(() => targetStudents = qty),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.purpleAccent
                                : AppColors.carbon3,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+$qty',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.steel,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.carbon1,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.purpleAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📋 Seu Plano Recomendado para +$targetStudents Alunos:',
                          style: const TextStyle(
                            color: Colors.purpleAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Investimento Diário: R\$ $dailyBudget,00 / dia (R\$ $monthlyBudget no mês)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '• Mensagens no WhatsApp: ~ $expectedLeads pessoas te chamando',
                          style: const TextStyle(
                            color: AppColors.steel,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '• Vídeos no Prompter: Gravar ${targetStudents <= 5 ? '4' : '8'} vídeos no mês (~1 ou 2 por semana)',
                          style: const TextStyle(
                            color: AppColors.steel,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '• Faturamento Extra: +R\$ ${estimatedRevenue.toStringAsFixed(0)} / mês (plano R\$ 350)',
                          style: const TextStyle(
                            color: AppColors.emerald,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppColors.steel),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Meta de +$targetStudents alunos definida com sucesso!',
                      ),
                      backgroundColor: Colors.purpleAccent,
                    ),
                  );
                },
                child: const Text(
                  'DEFINIR META 🚀',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _launchOneClickPreset(
    String title,
    FunnelStage stage,
    double dailyBudget,
    String utmTag,
  ) async {
    final nowStr = DateTime.now().toIso8601String();
    final presetCampaign = MarketingCampaign(
      id: 'camp_${DateTime.now().millisecondsSinceEpoch}',
      name: title,
      platform: MarketingPlatform.meta,
      funnelStage: stage,
      objective: CampaignObjective.leads,
      status: CampaignStatus.active,
      dailyBudget: dailyBudget,
      totalSpent: 0.0,
      leadsGenerated: 0,
      wonStudents: 0,
      revenueGenerated: 0.0,
      utmCampaign: utmTag,
      createdAt: nowStr,
      updatedAt: nowStr,
    );

    await _saveCampaign(
      presetCampaign,
      successMessage: 'Campanha 1-Clique ativada: "$title"!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.carbon,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.blueLight),
            )
          : _loadFailed
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Não foi possível carregar as divulgações.'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.blueLight,
              backgroundColor: AppColors.carbon2,
              child: CustomScrollView(
                slivers: [
                  // ── Top Bar Header (Linguagem Amigável para Leigos) ──────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Atrair novos alunos',
                                style: AppTheme.headlineMd(),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Divulgue seus treinos, grave vídeos sem travar e receba alunos no WhatsApp',
                                style: AppTheme.bodySm(
                                  color: AppColors.steelDim,
                                ),
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              TextButton.icon(
                                onPressed: _showHowItWorksDialog,
                                icon: const Icon(
                                  Icons.lightbulb_outline,
                                  color: AppColors.gold,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Como funciona',
                                  style: TextStyle(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _openNewCampaignDialog,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text(
                                  'Nova divulgação',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.blue,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Quick Launch Deck (4 Super-Poderes em Português Claro) ───
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _QuickActionCard(
                              icon: Icons.link_rounded,
                              label: 'Link do Meu WhatsApp',
                              sub: 'Poste na Bio ou Stories p/ te chamarem',
                              accentColor: AppColors.emerald,
                              onTap: _openUtmSheet,
                            ),
                            const SizedBox(width: 10),
                            _QuickActionCard(
                              icon: Icons.video_camera_front_rounded,
                              label: 'Gravar Lendo na Tela',
                              sub: 'O texto sobe na tela do celular',
                              accentColor: AppColors.crimson,
                              onTap: () {
                                if (_creatives.isNotEmpty) {
                                  _openTeleprompter(_creatives.first);
                                }
                              },
                            ),
                            const SizedBox(width: 10),
                            _QuickActionCard(
                              icon: Icons.auto_awesome,
                              label: 'Criar Imagem p/ Stories',
                              sub: 'Antes/Depois e comparações prontas',
                              accentColor: AppColors.gold,
                              onTap: _openSocialProofGenerator,
                            ),
                            const SizedBox(width: 10),
                            _QuickActionCard(
                              icon: Icons.calculate_rounded,
                              label: 'Simular Meu Lucro',
                              sub: 'Calcule quanto você vai faturar',
                              accentColor: AppColors.blueLight,
                              onTap: _openFunnelSimulator,
                            ),
                            const SizedBox(width: 10),
                            _QuickActionCard(
                              icon: Icons.flag_rounded,
                              label: 'Minha Meta do Mês',
                              sub: 'Calcule quanto precisa p/ +5 alunos',
                              accentColor: Colors.purpleAccent,
                              onTap: _showGoalPlannerDialog,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Scorecard de Métricas Globais ───────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: _buildGlobalKpiCard(),
                    ),
                  ),

                  // ── Checklist Semanal Prático ────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: _buildWeeklyChecklistCard(),
                    ),
                  ),

                  // ── Tab Bar (4 Abas em Linguagem Amigável) ──────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.carbon2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.carbon3),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          // Os rótulos completos não cabem em 4 abas no celular.
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          indicator: BoxDecoration(
                            color: AppColors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: AppColors.steel,
                          labelStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          tabs: const [
                            Tab(
                              icon: Icon(Icons.campaign, size: 18),
                              text: 'Minhas Divulgações',
                            ),
                            Tab(
                              icon: Icon(Icons.video_library, size: 18),
                              text: 'O Que Falar nos Vídeos',
                            ),
                            Tab(
                              icon: Icon(Icons.chat_bubble_outline, size: 18),
                              text: 'Mensagens & Imagens',
                            ),
                            Tab(
                              icon: Icon(Icons.analytics, size: 18),
                              text: 'De Onde Vieram os Alunos',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Conteúdo das Abas ───────────────────────────────────────
                  SliverFillRemaining(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCampaignsTab(),
                        _buildCreativeVaultTab(),
                        _buildAssetsVaultTab(),
                        _buildAttributionTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Checklist Semanal Prático ──────────────────────────────────────────────

  Widget _buildWeeklyChecklistCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.checklist_rtl_rounded,
                color: AppColors.blueLight,
                size: 22,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SEU PLANO PRÁTICO DESTA SEMANA',
                  style: TextStyle(
                    fontFamily: 'BebasNeue',
                    fontSize: 14,
                    letterSpacing: 1.0,
                    color: AppColors.blueLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Faça estas 4 pequenas ações para receber mensagens de pessoas '
            'querendo treinar. ${_weeklyDone.length} de '
            '${_weeklyTasks.length} feitas nesta semana.',
            style: const TextStyle(fontSize: 11, color: AppColors.steel),
          ),
          const SizedBox(height: 10),
          for (final (index, (day, task)) in _weeklyTasks.indexed)
            _ChecklistTile(
              day: day,
              task: task,
              isDone: _weeklyDone.contains(index),
              onTap: () => _toggleWeeklyTask(index),
            ),
        ],
      ),
    );
  }

  // ── Scorecard Global ───────────────────────────────────────────────────────

  Widget _buildGlobalKpiCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF161B24), Color(0xFF101319)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'DINHEIRO QUE ENTROU DE NOVOS ALUNOS',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.8,
                      color: AppColors.steelDim,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.formatBRL(_metrics.totalRevenueGenerated),
                    style: const TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: 28,
                      color: AppColors.emerald,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: AppColors.gold,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'LUCRO: ${_metrics.globalRoas.toStringAsFixed(1).replaceAll('.', ',')}x o investido',
                        style: const TextStyle(
                          fontFamily: 'BebasNeue',
                          fontSize: 15,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.carbon3),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ScoreItem(
                  label: 'INVESTIDO',
                  subLabel: 'no Instagram/TikTok',
                  value: Formatters.formatBRL(_metrics.totalSpent),
                  color: AppColors.steel,
                ),
                const SizedBox(width: 12),
                _ScoreItem(
                  label: 'TE CHAMARAM',
                  subLabel: 'no WhatsApp',
                  value: '${_metrics.totalLeadsGenerated}',
                  color: AppColors.blueLight,
                ),
                const SizedBox(width: 12),
                _ScoreItem(
                  label: 'VIRARAM ALUNOS',
                  subLabel: 'matrículas',
                  value: '${_metrics.totalConversions}',
                  color: AppColors.emerald,
                ),
                const SizedBox(width: 12),
                _ScoreItem(
                  label: 'CUSTO P/ CONTATO',
                  subLabel: 'por mensagem',
                  value: Formatters.formatBRL(_metrics.averageCpl),
                  color: AppColors.steelDim,
                ),
                const SizedBox(width: 12),
                _ScoreItem(
                  label: 'CUSTO P/ ALUNO',
                  subLabel: 'para fechar',
                  value: Formatters.formatBRL(_metrics.averageCac),
                  color: AppColors.steelDim,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── ABA 1: MINHAS DIVULGAÇÕES & MODELOS 1-CLIQUE ───────────────────────────
  Widget _buildCampaignsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Modelos de 1-Clique Prontos
        const Text(
          'MODELOS PRONTOS (LIGAR COM 1 TOQUE):',
          style: TextStyle(
            fontFamily: 'BebasNeue',
            fontSize: 13,
            letterSpacing: 1.0,
            color: AppColors.blueLight,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Toque em um modelo para começar a divulgar imediatamente:',
          style: TextStyle(fontSize: 11, color: AppColors.steelDim),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _PresetLauncherCard(
                title: '🌅 Lotar Horários da Manhã',
                badge: 'Vídeo Reels · R\$ 20/dia',
                desc: 'Para pessoas que querem treinar antes de ir trabalhar.',
                accentColor: AppColors.blueLight,
                onTap: () => _launchOneClickPreset(
                  'Lotar Horários Manhã (Reels)',
                  FunnelStage.tofu,
                  20.0,
                  'manha_reels_2026',
                ),
              ),
              const SizedBox(width: 10),
              _PresetLauncherCard(
                title: '🩹 Alunos com Dores / Lesões',
                badge: 'Carrossel · R\$ 15/dia',
                desc:
                    'Para quem tem dor na lombar ou joelho e quer treinar com segurança.',
                accentColor: AppColors.emerald,
                onTap: () => _launchOneClickPreset(
                  'Consultoria Sem Dor (Carrossel)',
                  FunnelStage.mofu,
                  15.0,
                  'sem_dor_carrossel_2026',
                ),
              ),
              const SizedBox(width: 10),
              _PresetLauncherCard(
                title: '⏳ Fechar Últimas Vagas',
                badge: 'Últimas Vagas · R\$ 10/dia',
                desc:
                    'Avisa que você só tem mais 2 vagas para iniciar esta semana.',
                accentColor: AppColors.crimson,
                onTap: () => _launchOneClickPreset(
                  'Últimas Vagas Semestral (Remarketing)',
                  FunnelStage.bofu,
                  10.0,
                  'vagas_fechamento_2026',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Lista de Campanhas Criadas
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              'SUAS DIVULGAÇÕES ATIVAS (${_campaigns.length})',
              style: const TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 14,
                letterSpacing: 1.0,
                color: Colors.white,
              ),
            ),
            TextButton.icon(
              onPressed: _openUtmSheet,
              icon: const Icon(Icons.link, size: 16, color: AppColors.emerald),
              label: const Text(
                'PEGAR LINK DO WHATSAPP',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.emerald,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_campaigns.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.carbon2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Nenhuma campanha cadastrada. Toque em um lançador acima ou em Criar Campanha.',
                style: TextStyle(color: AppColors.steel),
              ),
            ),
          )
        else
          ..._campaigns.map((c) => _buildCampaignCard(c)),
      ],
    );
  }

  Widget _buildCampaignCard(MarketingCampaign campaign) {
    final isActive = campaign.status == CampaignStatus.active;
    final cpl = campaign.cpl;
    final roas = campaign.roas;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.carbon2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.blue.withValues(alpha: 0.3)
              : AppColors.carbon3,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: campaign.stage.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: campaign.stage.color.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    campaign.stage.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: campaign.stage.color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    campaign.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Switch(
                  value: isActive,
                  activeThumbColor: AppColors.emerald,
                  onChanged: (val) => _toggleCampaignStatus(campaign),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.steel),
                  color: AppColors.carbon2,
                  onSelected: (val) {
                    if (val == 'edit') _openEditCampaignDialog(campaign);
                    if (val == 'delete') _deleteCampaign(campaign);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Editar Campanha'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Excluir',
                        style: TextStyle(color: AppColors.crimson),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.sell_outlined,
                  size: 14,
                  color: AppColors.steelDim,
                ),
                const SizedBox(width: 4),
                Text(
                  'Código: ${campaign.utmCampaign}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppColors.blueLight,
                  ),
                ),
                const Spacer(),
                Text(
                  'Orçamento: R\$ ${campaign.dailyBudget.toStringAsFixed(0)} / dia',
                  style: const TextStyle(fontSize: 11, color: AppColors.steel),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: AppColors.carbon3),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MiniStat(
                  label: 'INVESTIDO',
                  value: Formatters.formatBRL(campaign.totalSpent),
                ),
                _MiniStat(
                  label: 'NO WHATSAPP',
                  value: '${campaign.leadsGenerated}',
                  color: AppColors.blueLight,
                ),
                _MiniStat(
                  label: 'VIRARAM ALUNOS',
                  value: '${campaign.conversions}',
                  color: AppColors.emerald,
                ),
                _MiniStat(
                  label: 'P/ CONTATO',
                  value: Formatters.formatBRL(cpl),
                ),
                _MiniStat(
                  label: 'LUCRO',
                  value: '${roas.toStringAsFixed(1)}x',
                  color: AppColors.gold,
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _openUtmSheet(campaign: campaign),
                icon: const Icon(Icons.link_rounded, size: 18),
                label: const Text('GERAR LINK DESTA CAMPANHA'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.emerald,
                  side: const BorderSide(color: AppColors.emerald),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ABA 2: ROTEIROS & ESTÚDIO TELEPROMPTER ──────────────────────────────────
  Widget _buildCreativeVaultTab() {
    final filtered = _selectedStageFilter == 'ALL'
        ? _creatives
        : _creatives
              .where((c) => c.stage.name.toUpperCase() == _selectedStageFilter)
              .toList();

    return Column(
      children: [
        // Dica amigável
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: const [
              Icon(
                Icons.video_camera_front,
                color: AppColors.blueLight,
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '💡 Dica: Toque no botão vermelho "GRAVAR LENDO NA TELA". O texto sobe devagar na tela do seu celular para você ler naturalmente olhando para a câmera. Não precisa decorar nada!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Filter Pills
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'TODOS OS TEMAS',
                  isSelected: _selectedStageFilter == 'ALL',
                  onSelected: () =>
                      setState(() => _selectedStageFilter = 'ALL'),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: '1. CHAMAR ATENÇÃO',
                  isSelected: _selectedStageFilter == 'TOFU',
                  onSelected: () =>
                      setState(() => _selectedStageFilter = 'TOFU'),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: '2. EXPLICAR MÉTODO',
                  isSelected: _selectedStageFilter == 'MOFU',
                  onSelected: () =>
                      setState(() => _selectedStageFilter = 'MOFU'),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: '3. FECHAR MATRÍCULAS',
                  isSelected: _selectedStageFilter == 'BOFU',
                  onSelected: () =>
                      setState(() => _selectedStageFilter = 'BOFU'),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final item = filtered[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.carbon2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.carbon3),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: item.stage.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.stage == FunnelStage.tofu
                                ? 'Para Atrair Novos'
                                : (item.stage == FunnelStage.mofu
                                      ? 'Para Explicar Treino'
                                      : 'Para Fechar Vaga'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: item.stage.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.carbon3,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '🔥 Alta Atenção',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.carbon1,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.crimson.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🎯 O QUE FALAR NO COMEÇO (PRIMEIROS 3 SEGUNDOS):',
                            style: TextStyle(
                              fontFamily: 'BebasNeue',
                              fontSize: 11,
                              color: AppColors.crimson,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '"${item.hookText}"',
                            style: const TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openTeleprompter(item),
                            icon: const Icon(
                              Icons.play_circle_fill,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'GRAVAR LENDO NA TELA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.crimson,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _openCreativeSheet(item),
                          icon: const Icon(
                            Icons.visibility,
                            size: 16,
                            color: AppColors.blueLight,
                          ),
                          label: const Text(
                            'VER ROTEIRO',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.blueLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── ABA 3: IMAGENS & MENSAGENS PRONTAS ──────────────────────────────────────
  Widget _buildAssetsVaultTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Cartão de Destaque para Stories
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1D2430), Color(0xFF101319)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: AppColors.gold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CRIADOR DE IMAGENS P/ STORIES',
                    style: AppTheme.headlineSm(color: AppColors.gold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Crie imagens de evolução dos seus alunos (Antes/Depois com selo VALEX), comparativo de preço de pizza vs consultoria ou certificado de garantia para postar no Instagram.',
                style: TextStyle(fontSize: 12, color: AppColors.steel),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openSocialProofGenerator,
                  icon: const Icon(Icons.brush, size: 18),
                  label: const Text(
                    'ABRIR CRIADOR DE IMAGENS',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'O QUE RESPONDER NO WHATSAPP (COPIE E COLE COM 1 TOQUE):',
          style: TextStyle(
            fontFamily: 'BebasNeue',
            fontSize: 13,
            letterSpacing: 1.0,
            color: AppColors.steel,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Toque no botão para copiar a resposta pronta para o WhatsApp do aluno:',
          style: TextStyle(fontSize: 11, color: AppColors.steelDim),
        ),
        const SizedBox(height: 8),

        _ScriptCopyCard(
          title: '💬 Quando perguntarem: "Oi, quanto custa seu treino?"',
          script:
              'Fala [Nome]! Que top seu interesse em evoluir os treinos. Antes de falar de valores, me conta rápido: qual seu objetivo principal hoje (emagrecer, ganhar massa ou tratar alguma dor)? Assim vejo se meu método é o ideal pra você! 🚀',
        ),
        _ScriptCopyCard(
          title: '💬 Quando disserem: "Achei caro" ou "Vou pensar"',
          script:
              'Totalmente compreensível [Nome]. Mas pensa comigo: quanto custa continuar treinando sem periodização científica e sem ver mudança no espelho pelos próximos 6 meses? Na minha consultoria você tem garantia de 15 dias para testar sem risco.',
        ),
        _ScriptCopyCard(
          title: '💬 Quando o cliente sumir (Após 3 dias sem resposta)',
          script:
              'Oi [Nome]! Separei uma das últimas 2 vagas com avaliação biomecânica inclusa para quem iniciar esta semana. Quer que eu segure sua vaga ou posso passar pro próximo da fila? 💪',
        ),
        _ScriptCopyCard(
          title: '🤝 Pedir indicação para aluno que elogiou o treino',
          script:
              'Fala [Nome]! Fiquei muito feliz com a sua evolução hoje no treino! Olha, estou abrindo apenas 2 vagas novas para este mês e queria priorizar amigos seus. Se você me indicar 1 amigo que feche consultoria, você ganha 30 dias de bônus ou uma avaliação completa pra ele. Quem você conhece que precisa treinar sério com a gente?',
        ),
      ],
    );
  }

  // ── ABA 4: DE ONDE VIERAM OS ALUNOS ────────────────────────────────────────
  Widget _buildAttributionTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Simulador Shortcut
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calculate, color: AppColors.blueLight, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Simular: Se Eu Investir Mais, Quanto Eu Ganho?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Arraste os controles e veja quantos alunos novos você terá.',
                      style: TextStyle(fontSize: 11, color: AppColors.steelDim),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _openFunnelSimulator,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                ),
                child: const Text(
                  'SIMULAR',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'RESULTADOS POR CANAL (ONDE VOCÊ GANHOU DINHEIRO):',
          style: TextStyle(
            fontFamily: 'BebasNeue',
            fontSize: 13,
            letterSpacing: 1.0,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Veja qual rede social traz mais pessoas para o seu WhatsApp:',
          style: TextStyle(fontSize: 11, color: AppColors.steelDim),
        ),
        const SizedBox(height: 8),

        _ChannelPerfCard(
          channel: '📸 Instagram (Reels e Anúncios Pagos)',
          spend: 'R\$ 1.200',
          leads: 95,
          students: 12,
          roas: '4.8x de volta',
          color: AppColors.blueLight,
        ),
        _ChannelPerfCard(
          channel: '🎵 TikTok Ads',
          spend: 'R\$ 450',
          leads: 48,
          students: 5,
          roas: '3.6x de volta',
          color: AppColors.crimson,
        ),
        _ChannelPerfCard(
          channel: '🤝 Amigos que os Alunos Indicaram (Boca a Boca)',
          spend: 'R\$ 0 (Grátis)',
          leads: 22,
          students: 8,
          roas: 'Lucro Puro',
          color: AppColors.emerald,
        ),
        _ChannelPerfCard(
          channel: '🌐 Link da Bio do Instagram (Sem Anúncios)',
          spend: 'R\$ 0 (Grátis)',
          leads: 35,
          students: 4,
          roas: 'Lucro Puro',
          color: AppColors.gold,
        ),
      ],
    );
  }
}

// ── WIDGETS AUXILIARES COM ALTA ERGONOMIA ────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color accentColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.sub,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.carbon2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: const TextStyle(fontSize: 10, color: AppColors.steelDim),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetLauncherCard extends StatelessWidget {
  final String title;
  final String badge;
  final String desc;
  final Color accentColor;
  final VoidCallback onTap;

  const _PresetLauncherCard({
    required this.title,
    required this.badge,
    required this.desc,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.carbon2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(fontSize: 10, color: AppColors.steelDim),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(vertical: 6),
              ),
              child: const Text(
                'ATIVAR 1-CLIQUE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreItem extends StatelessWidget {
  final String label;
  final String subLabel;
  final String value;
  final Color color;

  const _ScoreItem({
    required this.label,
    this.subLabel = '',
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: AppColors.steelDim,
          ),
        ),
        if (subLabel.isNotEmpty)
          Text(
            subLabel,
            style: const TextStyle(fontSize: 8, color: AppColors.steelDim),
          ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontFamily: 'BebasNeue', fontSize: 16, color: color),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: AppColors.steelDim),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontFamily: 'BebasNeue', fontSize: 14, color: color),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue : AppColors.carbon2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.blue : AppColors.carbon3,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.steel,
          ),
        ),
      ),
    );
  }
}

class _ScriptCopyCard extends StatelessWidget {
  final String title;
  final String script;

  const _ScriptCopyCard({required this.title, required this.script});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.carbon2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.carbon3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.blueLight,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16, color: AppColors.steel),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: script));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Script copiado com sucesso!'),
                      backgroundColor: AppColors.emerald,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          Text(
            script,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.paper,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelPerfCard extends StatelessWidget {
  final String channel;
  final String spend;
  final int leads;
  final int students;
  final String roas;
  final Color color;

  const _ChannelPerfCard({
    required this.channel,
    required this.spend,
    required this.leads,
    required this.students,
    required this.roas,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.carbon2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.carbon3),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Gasto: $spend · $leads Leads · $students Alunos',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.steelDim,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.carbon3,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'ROAS $roas',
              style: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 13,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplainingStep extends StatelessWidget {
  final String number;
  final String title;
  final String desc;
  final Color color;

  const _ExplainingStep({
    required this.number,
    required this.title,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Text(
            number,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.steel,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  final String day;
  final String task;
  final bool isDone;
  final VoidCallback onTap;

  const _ChecklistTile({
    required this.day,
    required this.task,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: isDone,
      button: true,
      label: '$day: $task',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: _content(),
        ),
      ),
    );
  }

  Widget _content() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.emerald.withValues(alpha: 0.2)
                  : AppColors.carbon3,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              day,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDone ? AppColors.emerald : AppColors.steel,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 14,
            color: isDone ? AppColors.emerald : AppColors.steelDim,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              task,
              style: TextStyle(
                fontSize: 11,
                color: isDone ? Colors.white : AppColors.steel,
                decoration: isDone ? TextDecoration.none : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
