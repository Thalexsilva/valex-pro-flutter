import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/sales_model.dart';
import '../../repositories/marketing_repository.dart';
import '../../repositories/sales_repository.dart';
import '../../services/student_context_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/carbon_card.dart';
import '../marketing/utm_generator_sheet.dart';
import 'lead_convert_dialog.dart';
import 'lead_detail_bottom_sheet.dart';
import 'lead_form_dialog.dart';
import 'lead_profile_sheet.dart';
import 'objection_battlecards_sheet.dart';
import 'schedule_follow_up_dialog.dart';

class SalesView extends StatefulWidget {
  final SalesRepository? repository;

  const SalesView({super.key, this.repository});

  @override
  State<SalesView> createState() => _SalesViewState();
}

class _SalesViewState extends State<SalesView> {
  late final SalesRepository _repository;

  List<LeadItem> _leads = [];
  SalesMetricsData _metrics = SalesMetricsData();
  bool _isLoading = true;
  String? _loadError;

  String _searchQuery = '';
  String _selectedPriorityFilter = 'all'; // 'all' | 'hot' | 'warm' | 'cold'
  LeadStatus? _selectedStageFilter; // null = all
  bool _filterOnlyDueToday =
      false; // Filter leads that have follow-up due today / overdue

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SalesRepository();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final leads = await _repository.fetchLeads();
      final metrics = SalesMetricsData.calculate(leads);
      if (mounted) {
        setState(() {
          _leads = leads;
          _metrics = metrics;
          _loadError = null;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadError = error is SalesDataException
              ? error.message
              : 'Não foi possível carregar o CRM. Verifique sua conexão e tente novamente.';
          _isLoading = false;
        });
      }
    }
  }

  void _showSalesError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error is SalesDataException
              ? error.message
              : 'Não foi possível concluir esta ação. Tente novamente.',
        ),
        backgroundColor: AppColors.crimson,
      ),
    );
  }

  List<LeadItem> get _filteredLeads {
    return _leads.where((lead) {
      // Filtro de Retorno Agendado para Hoje / Atrasado
      if (_filterOnlyDueToday) {
        if (!lead.isFollowUpDueTodayOrOverdue) {
          return false;
        }
      }

      // Busca textual
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = lead.name.toLowerCase().contains(q);
        final matchPhone = lead.phone.toLowerCase().contains(q);
        final matchInsta = lead.instagram.toLowerCase().contains(q);
        final matchObj = lead.objective.toLowerCase().contains(q);
        final matchPlan = lead.targetPlanName.toLowerCase().contains(q);
        final matchFollowUp = (lead.scheduledFollowUpNote ?? '')
            .toLowerCase()
            .contains(q);
        if (!matchName &&
            !matchPhone &&
            !matchInsta &&
            !matchObj &&
            !matchPlan &&
            !matchFollowUp) {
          return false;
        }
      }

      // Prioridade / Temperatura
      if (_selectedPriorityFilter != 'all') {
        if (lead.priority.value != _selectedPriorityFilter) {
          return false;
        }
      }

      // Estágio no funil
      if (_selectedStageFilter != null) {
        if (lead.status != _selectedStageFilter) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _openLeadForm({LeadItem? lead}) {
    showDialog(
      context: context,
      builder: (ctx) => LeadFormDialog(
        lead: lead,
        onSave: (savedLead, initialNote) async {
          if (initialNote != null && initialNote.isNotEmpty) {
            final note = LeadNote(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content: initialNote,
              timestamp: DateTime.now().toIso8601String(),
            );
            savedLead = savedLead.copyWith(notes: [note]);
          }
          try {
            await _repository.saveLead(savedLead);
            await _loadData();
          } catch (error) {
            _showSalesError(error);
            return;
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  lead != null
                      ? 'Lead atualizado com sucesso!'
                      : 'Novo lead cadastrado no CRM!',
                ),
                backgroundColor: AppColors.green,
              ),
            );
          }
        },
      ),
    );
  }

  void _openLeadProfile(LeadItem lead) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.94,
        minChildSize: 0.5,
        maxChildSize: 1.0,
        builder: (_, scrollController) => LeadProfileSheet(
          lead: lead,
          repository: _repository,
          onLeadUpdated: () => _loadData(),
          onConvert: () {
            Navigator.pop(ctx);
            _openConvertDialog(lead);
          },
        ),
      ),
    );
  }

  void _openLeadDetail(LeadItem lead) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LeadDetailBottomSheet(
        lead: lead,
        onUpdate: (updated) async {
          try {
            await _repository.saveLead(updated);
            await _loadData();
          } catch (error) {
            _showSalesError(error);
          }
        },
        onStatusChange: (newStatus) async {
          try {
            await _repository.updateLeadStatus(lead.id, newStatus);
            await _loadData();
          } catch (error) {
            _showSalesError(error);
          }
        },
        onConvert: () {
          Navigator.pop(ctx);
          _openConvertDialog(lead);
        },
        onAddNote: (noteContent) async {
          try {
            await _repository.addLeadNote(lead.id, noteContent);
            await _loadData();
          } catch (error) {
            _showSalesError(error);
          }
        },
        onEdit: () {
          Navigator.pop(ctx);
          _openLeadForm(lead: lead);
        },
        onDelete: () async {
          Navigator.pop(ctx);
          _confirmDeleteLead(lead);
        },
      ),
    );
  }

  void _openBattlecards(LeadItem lead) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: ObjectionBattlecardsSheet(lead: lead),
      ),
    );
  }

  void _openScheduleFollowUp(LeadItem lead) {
    showDialog(
      context: context,
      builder: (ctx) => ScheduleFollowUpDialog(
        lead: lead,
        onSave: (scheduledDate, note) async {
          try {
            if (scheduledDate != null) {
              final saved = await _repository.scheduleFollowUp(
                lead.id,
                scheduledDate,
                note,
              );
              if (!saved) throw StateError('Lead não encontrado.');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Retorno agendado com sucesso para ${lead.name}!',
                    ),
                    backgroundColor: AppColors.green,
                  ),
                );
              }
            } else {
              final cleared = await _repository.clearScheduledFollowUp(lead.id);
              if (!cleared) throw StateError('Lead não encontrado.');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lembrete de retorno removido.'),
                    backgroundColor: AppColors.carbon3,
                  ),
                );
              }
            }
            await _loadData();
          } catch (error) {
            _showSalesError(error);
          }
        },
      ),
    );
  }

  void _openConvertDialog(LeadItem lead) {
    showDialog(
      context: context,
      builder: (ctx) => LeadConvertDialog(
        lead: lead,
        onConvert: ({required LeadItem lead, required String gymName}) async {
          try {
            final student = await _repository.convertLeadToStudent(
              lead: lead,
              gymName: gymName,
            );
            if (student == null) {
              throw StateError('Não foi possível concluir a conversão.');
            }
            StudentContextService().addOrUpdateStudent(student);
            await _loadData();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${student.name} foi convertido em aluno com sucesso!',
                ),
                backgroundColor: AppColors.green,
                duration: const Duration(seconds: 4),
              ),
            );
          } catch (error) {
            _showSalesError(error);
          }
        },
      ),
    );
  }

  void _showWhatsAppMenu(BuildContext context, LeadItem lead) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.carbon2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.green,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'MENSAGENS WHATSAPP — ${lead.name.toUpperCase()}',
                      style: AppTheme.headlineMd(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Scheduled Return Message (if exists)
                if (lead.hasScheduledFollowUp) ...[
                  _ScriptTile(
                    title: '⏰ Retorno Agendado (Conforme Combinado)',
                    subtitle:
                        lead.scheduledFollowUpNote ??
                        'Dar continuidade ao planejamento',
                    icon: Icons.alarm_on_rounded,
                    color: AppColors.goldLight,
                    onTap: () {
                      Navigator.pop(ctx);
                      final encoded =
                          Formatters.buildWhatsAppScheduledReturnMessage(
                            leadName: lead.name,
                            note: lead.scheduledFollowUpNote,
                          );
                      _copyOrOpenWhatsApp(lead.phone, encoded);
                    },
                  ),
                ],

                _ScriptTile(
                  title: '1. Proposta / Pitch Comercial',
                  subtitle:
                      'Apresentação do plano, valor e convite de fechamento',
                  icon: Icons.send_rounded,
                  color: AppColors.blueLight,
                  onTap: () {
                    Navigator.pop(ctx);
                    final encoded = Formatters.buildWhatsAppPitchMessage(
                      leadName: lead.name,
                      planName: lead.targetPlanName.isNotEmpty
                          ? lead.targetPlanName
                          : 'Consultoria Personalizada',
                      value: lead.estimatedValue,
                    );
                    _copyOrOpenWhatsApp(lead.phone, encoded);
                  },
                ),
                _ScriptTile(
                  title: '2. Follow-up 24 Horas',
                  subtitle: 'Tirar dúvidas e manter engajamento ativo',
                  icon: Icons.hourglass_top_rounded,
                  color: AppColors.emerald,
                  onTap: () {
                    Navigator.pop(ctx);
                    final encoded = Formatters.buildWhatsAppFollowUpMessage(
                      leadName: lead.name,
                      followUpStage: 1,
                    );
                    _copyOrOpenWhatsApp(lead.phone, encoded);
                  },
                ),
                _ScriptTile(
                  title: '3. Follow-up 48h (Gatilho de Urgência)',
                  subtitle: 'Aviso de fechamento de grade e vagas limitadas',
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.crimson,
                  onTap: () {
                    Navigator.pop(ctx);
                    final encoded = Formatters.buildWhatsAppFollowUpMessage(
                      leadName: lead.name,
                      followUpStage: 2,
                    );
                    _copyOrOpenWhatsApp(lead.phone, encoded);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _copyOrOpenWhatsApp(String phone, String encodedText) {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final url = 'https://wa.me/55$cleanPhone?text=$encodedText';
    final decodedText = Uri.decodeComponent(encodedText);

    // Copia o texto legível primeiro
    Clipboard.setData(ClipboardData(text: decodedText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '✅ Mensagem copiada! Toque em WHATSAPP para copiar o link.',
        ),
        backgroundColor: AppColors.blue,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'WHATSAPP',
          textColor: Colors.white,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: url));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Link WhatsApp copiado! Cole no navegador.'),
                backgroundColor: AppColors.green,
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAddNoteDialog(LeadItem lead) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.carbon2,
        title: Text(
          'Adicionar Nota: ${lead.name}',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextFormField(
          controller: noteController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Conteúdo da interação...',
            hintText:
                'Ex: Respondeu proposta no WhatsApp, pediu desconto no PIX...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'CANCELAR',
              style: TextStyle(color: AppColors.steelDim),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
            onPressed: () async {
              final text = noteController.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx);
                await _repository.addLeadNote(lead.id, text);
                if (mounted) {
                  _loadData();
                }
              }
            },
            child: const Text(
              'SALVAR NOTA',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteLead(LeadItem lead) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.carbon2,
        title: const Text(
          'Excluir Lead',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Deseja realmente remover ${lead.name} do CRM?',
          style: const TextStyle(color: AppColors.steel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final deleted = await _repository.deleteLead(lead.id);
        if (!deleted) throw StateError('Lead não encontrado.');
        await _loadData();
      } catch (error) {
        _showSalesError(error);
      }
    }
  }

  void _openUtmGenerator() async {
    final campaigns = await MarketingRepository().getCampaigns();
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => UtmGeneratorSheet(availableCampaigns: campaigns),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.carbon,
      // Sem leads o estado vazio já oferece "Cadastrar primeiro lead"; o botão
      // flutuante cobria essa ação no celular.
      floatingActionButton: _isLoading || _loadError != null || _leads.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.blue,
              icon: const Icon(
                Icons.person_add_alt_1_rounded,
                color: Colors.white,
              ),
              label: const Text(
                'NOVO LEAD',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              onPressed: () => _openLeadForm(),
            ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.blueLight),
            )
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      color: AppColors.crimson,
                      size: 36,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.steel),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('TENTAR NOVAMENTE'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // ── Top Bar Header ──────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    Text(
                                      'Vendas & CRM',
                                      style: AppTheme.headlineMd(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.crimson.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.crimson.withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons
                                                .local_fire_department_outlined,
                                            size: 14,
                                            color: AppColors.crimson,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${_metrics.hotLeadsCount} QUENTES',
                                            style: const TextStyle(
                                              color: AppColors.crimson,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_metrics.scheduledFollowUpsTodayCount >
                                        0) ...[
                                      const SizedBox(width: 6),
                                      FilterChip(
                                        label: Text(
                                          '${_metrics.scheduledFollowUpsTodayCount} retornos hoje',
                                        ),
                                        avatar: const Icon(
                                          Icons.schedule_rounded,
                                          size: 16,
                                        ),
                                        selected: _filterOnlyDueToday,
                                        onSelected: (selected) => setState(
                                          () => _filterOnlyDueToday = selected,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Gestão de prospecção, agendamento de retornos e conversão de alunos',
                                  style: AppTheme.bodyMd(
                                    color: AppColors.steelDim,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _openUtmGenerator,
                            icon: const Icon(
                              Icons.link,
                              size: 16,
                              color: AppColors.emerald,
                            ),
                            label: const Text(
                              'LINKS UTM',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.emerald,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.emerald),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Full Scorecard KPI Metrics ──────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double itemWidth = isDesktop
                              ? (constraints.maxWidth - 36) / 4
                              : (constraints.maxWidth - 12) / 2;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: itemWidth,
                                child: _ScoreMetricCard(
                                  title: 'TOTAL DE LEADS',
                                  value: _metrics.totalLeads.toString(),
                                  subtitle:
                                      '${_metrics.activeLeads} em negociação ativa',
                                  icon: Icons.groups_outlined,
                                  accentColor: AppColors.blueLight,
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: _ScoreMetricCard(
                                  title: 'VGV EM NEGOCIAÇÃO',
                                  value: Formatters.formatBRL(
                                    _metrics.totalEstimatedPipelineValue,
                                  ),
                                  subtitle: 'Potencial de novos contratos',
                                  icon: Icons.monetization_on_outlined,
                                  accentColor: AppColors.goldLight,
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: _ScoreMetricCard(
                                  title: 'TAXA DE CONVERSÃO',
                                  value:
                                      '${_metrics.conversionRate.toStringAsFixed(1)}%',
                                  subtitle:
                                      '${_metrics.wonLeads} convertidos em alunos',
                                  icon: Icons.trending_up_rounded,
                                  accentColor: AppColors.green,
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: _ScoreMetricCard(
                                  title: 'RETORNOS AGENDADOS',
                                  value:
                                      '${_metrics.scheduledFollowUpsTodayCount} hoje',
                                  subtitle:
                                      '${_metrics.hotLeadsCount} leads quentes no funil',
                                  icon: Icons.alarm_on_rounded,
                                  accentColor: AppColors.goldLight,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  // ── Search & Filter Controls ────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search Box and Priority Chips
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Buscar por nome, WhatsApp, retorno, objetivo...',
                                    hintStyle: const TextStyle(
                                      color: AppColors.steelDim,
                                      fontSize: 13,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: AppColors.steelDim,
                                      size: 20,
                                    ),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.clear,
                                              size: 16,
                                              color: AppColors.steelDim,
                                            ),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() => _searchQuery = '');
                                            },
                                          )
                                        : null,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 0,
                                      horizontal: 16,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.carbon2,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppColors.radiusBtn,
                                      ),
                                      borderSide: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.05,
                                        ),
                                      ),
                                    ),
                                  ),
                                  onChanged: (val) =>
                                      setState(() => _searchQuery = val.trim()),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Priority Filter Chips
                              SizedBox(
                                width: MediaQuery.sizeOf(context).width < 600
                                    ? 170
                                    : 360,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _FilterChip(
                                        label: 'Todos',
                                        isSelected:
                                            _selectedPriorityFilter == 'all' &&
                                            !_filterOnlyDueToday,
                                        onTap: () => setState(() {
                                          _selectedPriorityFilter = 'all';
                                          _filterOnlyDueToday = false;
                                        }),
                                      ),
                                      const SizedBox(width: 4),
                                      _FilterChip(
                                        label: '⏰ Retornos Hoje',
                                        isSelected: _filterOnlyDueToday,
                                        onTap: () => setState(
                                          () => _filterOnlyDueToday =
                                              !_filterOnlyDueToday,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      _FilterChip(
                                        label: 'Quente 🔥',
                                        isSelected:
                                            _selectedPriorityFilter == 'hot',
                                        onTap: () => setState(
                                          () => _selectedPriorityFilter = 'hot',
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      _FilterChip(
                                        label: 'Morno ⚡',
                                        isSelected:
                                            _selectedPriorityFilter == 'warm',
                                        onTap: () => setState(
                                          () =>
                                              _selectedPriorityFilter = 'warm',
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      _FilterChip(
                                        label: 'Frio ❄️',
                                        isSelected:
                                            _selectedPriorityFilter == 'cold',
                                        onTap: () => setState(
                                          () =>
                                              _selectedPriorityFilter = 'cold',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Stage Pills Stepper
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _StagePill(
                                  label: 'Todos',
                                  count: _leads.length,
                                  isSelected: _selectedStageFilter == null,
                                  onTap: () => setState(
                                    () => _selectedStageFilter = null,
                                  ),
                                ),
                                ...LeadStatus.values.map((stage) {
                                  final count = _leads
                                      .where((l) => l.status == stage)
                                      .length;
                                  return _StagePill(
                                    label: stage.label,
                                    count: count,
                                    isSelected: _selectedStageFilter == stage,
                                    color: Formatters.getLeadStatusColor(
                                      stage.value,
                                    ),
                                    onTap: () => setState(
                                      () => _selectedStageFilter = stage,
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Rich Informative Lead Cards List ────────────────────────
                  if (_filteredLeads.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.blue.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.blue.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: Icon(
                                  _leads.isEmpty
                                      ? Icons.person_search_outlined
                                      : Icons.filter_list_off_outlined,
                                  color: AppColors.steelDim,
                                  size: 52,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _leads.isEmpty
                                    ? 'Nenhum Lead no CRM ainda'
                                    : 'Nenhum lead neste filtro',
                                style: AppTheme.bodyMd(color: Colors.white)
                                    .copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _leads.isEmpty
                                    ? 'Adicione o primeiro prospect e comece a gerenciar sua prospecção com score e cadência automática.'
                                    : 'Tente remover os filtros ativos para ver todos os leads.',
                                style: AppTheme.bodyMd(
                                  color: AppColors.steelDim,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              if (_leads.isEmpty)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.blue,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppColors.radiusBtn,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.person_add_alt_1_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  onPressed: () => _openLeadForm(),
                                  label: const Text(
                                    'CADASTRAR PRIMEIRO LEAD',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else
                                TextButton.icon(
                                  onPressed: () => setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                    _selectedPriorityFilter = 'all';
                                    _selectedStageFilter = null;
                                    _filterOnlyDueToday = false;
                                  }),
                                  icon: const Icon(
                                    Icons.filter_list_off_outlined,
                                    color: AppColors.blueLight,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'LIMPAR FILTROS',
                                    style: TextStyle(
                                      color: AppColors.blueLight,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final lead = _filteredLeads[index];
                          return _RichLeadCard(
                            lead: lead,
                            onTap: () => _openLeadProfile(lead),
                            onDetailsTap: () => _openLeadDetail(lead),
                            onWhatsAppMenu: () =>
                                _showWhatsAppMenu(context, lead),
                            onBattlecards: () => _openBattlecards(lead),
                            onScheduleFollowUp: () =>
                                _openScheduleFollowUp(lead),
                            onConvert: () => _openConvertDialog(lead),
                            onAddNote: () => _showAddNoteDialog(lead),
                            onStatusChange: (newStatus) async {
                              await _repository.updateLeadStatus(
                                lead.id,
                                newStatus,
                              );
                              _loadData();
                            },
                            onEdit: () => _openLeadForm(lead: lead),
                            onDelete: () => _confirmDeleteLead(lead),
                          );
                        }, childCount: _filteredLeads.length),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

// ── Rich Full-Featured Lead Card ──────────────────────────────────────────────

class _RichLeadCard extends StatelessWidget {
  final LeadItem lead;
  final VoidCallback onTap;
  final VoidCallback onDetailsTap;
  final VoidCallback onWhatsAppMenu;
  final VoidCallback onBattlecards;
  final VoidCallback onScheduleFollowUp;
  final VoidCallback onConvert;
  final VoidCallback onAddNote;
  final Function(LeadStatus) onStatusChange;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RichLeadCard({
    required this.lead,
    required this.onTap,
    required this.onDetailsTap,
    required this.onWhatsAppMenu,
    required this.onBattlecards,
    required this.onScheduleFollowUp,
    required this.onConvert,
    required this.onAddNote,
    required this.onStatusChange,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = Formatters.getLeadPriorityColor(lead.priority.value);
    final statusColor = Formatters.getLeadStatusColor(lead.status.value);
    final isFollowUpDue = lead.isFollowUpDueTodayOrOverdue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CarbonCard(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Top Header Row: Score, Name, Priority, Status Badge ─────────
            Row(
              children: [
                // Score Gauge Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: priorityColor.withValues(alpha: 0.15),
                    border: Border.all(color: priorityColor, width: 2),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${lead.score}',
                          style: TextStyle(
                            color: priorityColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            height: 1.0,
                          ),
                        ),
                        const Text(
                          'PTS',
                          style: TextStyle(
                            color: AppColors.steelDim,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Priority Chip
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lead.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Priority Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: priorityColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              lead.priority.label,
                              style: TextStyle(
                                color: priorityColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Origem: ${_formatOrigin(lead.originChannel)}',
                            style: const TextStyle(
                              color: AppColors.steelDim,
                              fontSize: 11,
                            ),
                          ),
                          if (lead.utmCampaign != null &&
                              lead.utmCampaign!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '• ${lead.utmCampaign}',
                              style: const TextStyle(
                                color: AppColors.emerald,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    lead.status.label,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // ── Indicador de Cadência de Follow-up (se ativo) ─────────────────
            if (lead.followUpStep > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.route_outlined,
                    size: 12,
                    color: AppColors.goldLight,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    lead.followUpStepLabel,
                    style: const TextStyle(
                      color: AppColors.goldLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: lead.followUpStep / 7,
                      backgroundColor: AppColors.carbon1,
                      color: AppColors.gold,
                      minHeight: 3,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],

            // ── Lembrete de Retorno Agendado (Destaque se houver) ─────────────
            if (lead.hasScheduledFollowUp) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onScheduleFollowUp,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isFollowUpDue
                        ? AppColors.crimson.withValues(alpha: 0.2)
                        : AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isFollowUpDue
                          ? AppColors.crimson
                          : AppColors.gold.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.alarm_on_rounded,
                        size: 16,
                        color: isFollowUpDue
                            ? AppColors.crimson
                            : AppColors.goldLight,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '⏰ RETORNO: ${Formatters.formatFollowUpDate(lead.scheduledFollowUpDate!)}'
                          '${lead.scheduledFollowUpNote != null && lead.scheduledFollowUpNote!.isNotEmpty ? " — ${lead.scheduledFollowUpNote}" : ""}',
                          style: TextStyle(
                            color: isFollowUpDue
                                ? Colors.white
                                : AppColors.goldLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.edit_calendar_outlined,
                        size: 14,
                        color: AppColors.steelDim,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ── 2. Middle Section: Objective, Plan, Value, Phone ──────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.carbon1,
                borderRadius: BorderRadius.circular(AppColors.radiusSm),
                border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Objective
                  if (lead.objective.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.fitness_center_rounded,
                          size: 14,
                          color: AppColors.blueLight,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            lead.objective,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Plan & Value
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.star_border_rounded,
                            size: 14,
                            color: AppColors.goldLight,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            lead.targetPlanName.isNotEmpty
                                ? lead.targetPlanName
                                : 'Proposta Padrão',
                            style: const TextStyle(
                              color: AppColors.steel,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        Formatters.formatBRL(lead.estimatedValue),
                        style: const TextStyle(
                          color: AppColors.goldLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  // Phone & Instagram
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 13,
                        color: AppColors.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        lead.phone,
                        style: const TextStyle(
                          color: AppColors.steel,
                          fontSize: 12,
                        ),
                      ),
                      if (lead.instagram.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.alternate_email,
                          size: 13,
                          color: AppColors.goldLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lead.instagram,
                          style: const TextStyle(
                            color: AppColors.steel,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── 3. Latest Note Snippet (if exists) ────────────────────────────
            if (lead.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.carbon1.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.sticky_note_2_outlined,
                      size: 13,
                      color: AppColors.steelDim,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Última nota: ${lead.notes.last.content}',
                        style: const TextStyle(
                          color: AppColors.steelDim,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(color: AppColors.carbon3, height: 20),

            // ── 4. Full Action Buttons Bar ────────────────────────────────────
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // WhatsApp Scripts Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green.withValues(alpha: 0.2),
                    foregroundColor: AppColors.green,
                    side: const BorderSide(color: AppColors.green, width: 0.8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                  icon: const Icon(Icons.chat_rounded, size: 14),
                  label: const Text(
                    'WHATSAPP SCRIPTS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  onPressed: onWhatsAppMenu,
                ),

                // Schedule Follow-Up Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowUpDue
                        ? AppColors.crimson.withValues(alpha: 0.25)
                        : AppColors.gold.withValues(alpha: 0.2),
                    foregroundColor: isFollowUpDue
                        ? AppColors.crimson
                        : AppColors.goldLight,
                    side: BorderSide(
                      color: isFollowUpDue ? AppColors.crimson : AppColors.gold,
                      width: 0.8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                  icon: Icon(
                    isFollowUpDue
                        ? Icons.alarm_on_rounded
                        : Icons.calendar_today_rounded,
                    size: 14,
                  ),
                  label: Text(
                    lead.hasScheduledFollowUp ? 'REAGENDAR' : 'AGENDAR RETORNO',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: onScheduleFollowUp,
                ),

                // Battlecards Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.crimson.withValues(alpha: 0.2),
                    foregroundColor: AppColors.crimson,
                    side: const BorderSide(
                      color: AppColors.crimson,
                      width: 0.8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                  icon: const Icon(Icons.shield_outlined, size: 14),
                  label: const Text(
                    'BATTLECARDS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  onPressed: onBattlecards,
                ),

                // Convert Button (if not already won)
                if (lead.status != LeadStatus.won)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue.withValues(alpha: 0.25),
                      foregroundColor: AppColors.blueLight,
                      side: const BorderSide(
                        color: AppColors.blueLight,
                        width: 0.8,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                    icon: const Icon(Icons.school_rounded, size: 14),
                    label: const Text(
                      'CONVERTER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: onConvert,
                  ),

                // Ver Perfil Completo (abre o LeadProfileSheet)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blueLight,
                    side: BorderSide(
                      color: AppColors.blueLight.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                  ),
                  icon: const Icon(Icons.person_search_outlined, size: 14),
                  label: const Text('PERFIL', style: TextStyle(fontSize: 11)),
                  onPressed: onTap,
                ),

                // Quick Note Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.steel,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                  ),
                  icon: const Icon(Icons.note_add_outlined, size: 14),
                  label: const Text('NOTA', style: TextStyle(fontSize: 11)),
                  onPressed: onAddNote,
                ),

                // Status Change Dropdown
                PopupMenuButton<LeadStatus>(
                  color: AppColors.carbon2,
                  icon: const Icon(
                    Icons.swap_horiz_rounded,
                    color: AppColors.steelDim,
                    size: 18,
                  ),
                  tooltip: 'Mudar Estágio',
                  onSelected: onStatusChange,
                  itemBuilder: (ctx) {
                    return LeadStatus.values.map((st) {
                      return PopupMenuItem(
                        value: st,
                        child: Text(
                          st.label,
                          style: TextStyle(
                            color: Formatters.getLeadStatusColor(st.value),
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList();
                  },
                ),

                // Edit Button
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: AppColors.steelDim,
                  ),
                  tooltip: 'Editar Lead',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onEdit,
                ),

                // Ver Detalhes (bottom sheet simples)
                IconButton(
                  icon: const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.steelDim,
                  ),
                  tooltip: 'Ver Detalhes',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onDetailsTap,
                ),

                const SizedBox(width: 4),

                // Delete Button
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: AppColors.crimson,
                  ),
                  tooltip: 'Excluir Lead',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatOrigin(String raw) {
    switch (raw) {
      case 'meta_ads':
        return 'Meta Ads';
      case 'instagram_direct':
        return 'Instagram Direct';
      case 'indicacao':
        return 'Indicação de Aluno';
      case 'whatsapp':
        return 'WhatsApp';
      case 'google':
        return 'Google Search';
      default:
        return raw;
    }
  }
}

// ── Scorecard Metric Widget ───────────────────────────────────────────────────

class _ScoreMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const _ScoreMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return CarbonCard(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(AppColors.radiusCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.labelCaps(color: AppColors.steelDim),
                ),
              ),
              Icon(icon, color: accentColor, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: AppTheme.kpiXl(color: accentColor),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.steel, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.blue.withValues(alpha: 0.25)
              : AppColors.carbon2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.blueLight
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.blueLight : AppColors.steel,
          ),
        ),
      ),
    );
  }
}

class _StagePill extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _StagePill({
    required this.label,
    required this.count,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.blueLight;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.2)
                : AppColors.carbon2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : AppColors.steelDim,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.3)
                      : AppColors.carbon1,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? activeColor : AppColors.steelDim,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScriptTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ScriptTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.carbon1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.steelDim, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.copy_rounded,
          color: AppColors.steelDim,
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }
}
