import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/sales_model.dart';
import '../../repositories/sales_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'objection_battlecards_sheet.dart';
import 'schedule_follow_up_dialog.dart';

/// Perfil Completo do Lead — Modal de tela cheia com 5 seções e navbar inferior.
/// Aprovado na Sessão 17 do Conselho Diretor VALEX.
class LeadProfileSheet extends StatefulWidget {
  final LeadItem lead;
  final SalesRepository repository;
  final VoidCallback onLeadUpdated;
  final VoidCallback? onConvert;

  const LeadProfileSheet({
    super.key,
    required this.lead,
    required this.repository,
    required this.onLeadUpdated,
    this.onConvert,
  });

  @override
  State<LeadProfileSheet> createState() => _LeadProfileSheetState();
}

class _LeadProfileSheetState extends State<LeadProfileSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late LeadItem _lead;
  final TextEditingController _noteController = TextEditingController();
  bool _isSavingNote = false;

  static const _tabs = ['Perfil', 'Timeline', 'Scripts', 'Calculadora ROI'];

  @override
  void initState() {
    super.initState();
    _lead = widget.lead;
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSavingNote = true);
    await widget.repository.addLeadNote(_lead.id, text);
    _noteController.clear();
    final refreshed = await widget.repository.fetchLeads();
    final updated = refreshed.firstWhere(
      (l) => l.id == _lead.id,
      orElse: () => _lead,
    );
    setState(() {
      _lead = updated;
      _isSavingNote = false;
    });
    widget.onLeadUpdated();
  }

  Future<void> _advanceCadenceStep() async {
    if (_lead.followUpStep >= 7) return;
    final next = _lead.copyWith(followUpStep: _lead.followUpStep + 1);
    await widget.repository.saveLead(next);
    setState(() => _lead = next);
    widget.onLeadUpdated();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${next.followUpStepLabel} ativado!'),
          backgroundColor: AppColors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Retorna a label do passo N sem instanciar um LeadItem descartável.
  static String _nextStepLabel(int step) {
    const labels = {
      1: 'Passo 1/7 📲 Primeiro Contato',
      2: 'Passo 2/7 📋 Anamnese Enviada',
      3: 'Passo 3/7 💬 Proposta',
      4: 'Passo 4/7 ⏰ Follow-up 24h',
      5: 'Passo 5/7 🔥 Urgência 48h',
      6: 'Passo 6/7 🛡️ Objeção Tratada',
      7: 'Passo 7/7 🎉 Decisão Final',
    };
    return labels[step] ?? 'Passo $step/7';
  }

  Future<void> _scheduleFollowUp() async {
    showDialog(
      context: context,
      builder: (ctx) => ScheduleFollowUpDialog(
        lead: _lead,
        onSave: (scheduledDate, note) async {
          if (scheduledDate != null) {
            await widget.repository.scheduleFollowUp(
              _lead.id,
              scheduledDate,
              note,
            );
            final refreshed = await widget.repository.fetchLeads();
            final updated = refreshed.firstWhere(
              (l) => l.id == _lead.id,
              orElse: () => _lead,
            );
            if (mounted) {
              setState(() => _lead = updated);
              widget.onLeadUpdated();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '⏰ Retorno agendado com sucesso para ${_lead.name}!',
                  ),
                  backgroundColor: AppColors.green,
                ),
              );
            }
          } else {
            await widget.repository.clearScheduledFollowUp(_lead.id);
            final refreshed = await widget.repository.fetchLeads();
            final updated = refreshed.firstWhere(
              (l) => l.id == _lead.id,
              orElse: () => _lead,
            );
            if (mounted) {
              setState(() => _lead = updated);
              widget.onLeadUpdated();
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.carbon,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          _buildHeader(),

          // ── Tabs ────────────────────────────────────────────────────────────
          Container(
            color: AppColors.carbon2,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.gold,
              labelColor: AppColors.gold,
              unselectedLabelColor: AppColors.steel,
              labelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(),
                _buildTimelineTab(),
                _buildScriptsTab(),
                _buildRoiCalculatorTab(),
              ],
            ),
          ),

          // ── Sticky Bottom Actions ────────────────────────────────────────────
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final priority = _lead.priority;
    final ringColor = priority == LeadPriority.hot
        ? AppColors.crimson
        : priority == LeadPriority.warm
        ? AppColors.gold
        : AppColors.steel;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.carbon2, AppColors.carbon],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: const Border(bottom: BorderSide(color: AppColors.carbon3)),
      ),
      child: Row(
        children: [
          // Avatar com Ring de Score
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColor, width: 2.5),
                  color: AppColors.carbon3,
                ),
                child: Center(
                  child: Text(
                    _lead.name.isNotEmpty ? _lead.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ringColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_lead.score}',
                    style: const TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: 11,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Info Principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lead.name,
                  style: AppTheme.headlineMd(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  _lead.status.label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.blueLight,
                  ),
                ),
                if (_lead.followUpStepLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _lead.followUpStepLabel,
                    style: const TextStyle(fontSize: 11, color: AppColors.gold),
                  ),
                ],
              ],
            ),
          ),

          // Botão Fechar
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.steel),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ── ABA 1: PERFIL ──────────────────────────────────────────────────────────
  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Contato
        _Section(
          title: '📞 CONTATO RÁPIDO',
          child: Row(
            children: [
              if (_lead.phone.isNotEmpty)
                _ContactChip(
                  icon: Icons.chat,
                  label: 'WhatsApp',
                  color: AppColors.emerald,
                  onTap: () {
                    final url =
                        'https://wa.me/55${_lead.phone.replaceAll(RegExp(r'[^0-9]'), '')}';
                    Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link WhatsApp copiado!'),
                        backgroundColor: AppColors.emerald,
                      ),
                    );
                  },
                ),
              if (_lead.instagram.isNotEmpty) ...[
                const SizedBox(width: 8),
                _ContactChip(
                  icon: Icons.alternate_email,
                  label: _lead.instagram,
                  color: AppColors.crimson,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _lead.instagram));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Instagram copiado!'),
                        backgroundColor: AppColors.crimson,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Diagnóstico Comercial
        _Section(
          title: '🎯 DIAGNÓSTICO COMERCIAL',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                label: 'Objetivo Principal',
                value: _lead.objective.isNotEmpty
                    ? _lead.objective
                    : 'Não informado',
              ),
              _InfoRow(
                label: 'Plano de Interesse',
                value: _lead.targetPlanName.isNotEmpty
                    ? _lead.targetPlanName
                    : 'Não definido',
                valueColor: AppColors.gold,
              ),
              _InfoRow(
                label: 'Valor Estimado',
                value: _lead.estimatedValue > 0
                    ? 'R\$ ${_lead.estimatedValue.toStringAsFixed(0)}'
                    : '—',
                valueColor: AppColors.gold,
              ),
              _InfoRow(
                label: 'Canal de Origem',
                value: Formatters.translateChannel(_lead.originChannel),
              ),
              if (_lead.utmSource != null)
                _InfoRow(
                  label: 'UTM Source',
                  value: _lead.utmSource!,
                  valueColor: AppColors.blueLight,
                ),
              _InfoRow(
                label: 'Dias desde 1º contato',
                value: () {
                  try {
                    final created = DateTime.parse(_lead.createdAt);
                    final diff = DateTime.now().difference(created).inDays;
                    return '$diff dias atrás';
                  } catch (_) {
                    return '—';
                  }
                }(),
                valueColor: AppColors.amber,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Agendamento de Retorno
        if (_lead.hasScheduledFollowUp)
          _Section(
            title: '⏰ RETORNO AGENDADO',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.formatFollowUpDate(_lead.scheduledFollowUpDate!),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _lead.isFollowUpDueTodayOrOverdue
                        ? AppColors.crimson
                        : AppColors.gold,
                  ),
                ),
                if (_lead.scheduledFollowUpNote != null &&
                    _lead.scheduledFollowUpNote!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _lead.scheduledFollowUpNote!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.steel,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _scheduleFollowUp,
                  icon: const Icon(
                    Icons.edit_calendar,
                    size: 16,
                    color: AppColors.blueLight,
                  ),
                  label: const Text(
                    'Reagendar',
                    style: TextStyle(color: AppColors.blueLight),
                  ),
                ),
              ],
            ),
          )
        else
          _Section(
            title: '⏰ RETORNO AGENDADO',
            child: TextButton.icon(
              onPressed: _scheduleFollowUp,
              icon: const Icon(Icons.add_alarm, color: AppColors.gold),
              label: const Text(
                'Agendar Retorno',
                style: TextStyle(color: AppColors.gold),
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Cadência 7 Passos
        _Section(
          title: '⚡ CADÊNCIA DE 7 PASSOS',
          child: Column(
            children: [
              Row(
                children: List.generate(7, (i) {
                  final step = i + 1;
                  final done = step <= _lead.followUpStep;
                  final current = step == _lead.followUpStep + 1;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 6,
                      decoration: BoxDecoration(
                        color: done
                            ? AppColors.emerald
                            : current
                            ? AppColors.gold
                            : AppColors.carbon3,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              if (_lead.followUpStep < 7)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _advanceCadenceStep,
                    icon: const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppColors.gold,
                    ),
                    label: Text(
                      _lead.followUpStep == 0
                          ? 'INICIAR CADÊNCIA — PASSO 1'
                          : 'AVANÇAR PARA ${_nextStepLabel(_lead.followUpStep + 1)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.gold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.gold),
                    ),
                  ),
                )
              else
                const Text(
                  '🎯 Cadência concluída!',
                  style: TextStyle(
                    color: AppColors.emerald,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── ABA 2: TIMELINE ────────────────────────────────────────────────────────
  Widget _buildTimelineTab() {
    final notes = [..._lead.notes]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Column(
      children: [
        // Campo de nova nota
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  maxLength: 300,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Ex: Disse que prefere receber entre 14h-18h…',
                    hintStyle: const TextStyle(
                      color: AppColors.steelDim,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.carbon2,
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.carbon3),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.carbon3),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSavingNote ? null : _saveNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                child: _isSavingNote
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'SALVAR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),

        // Lista de notas
        Expanded(
          child: notes.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhuma nota ainda.\nComece registrando o primeiro contato!',
                    style: TextStyle(color: AppColors.steel),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: notes.length,
                  itemBuilder: (ctx, i) {
                    final note = notes[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
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
                            children: [
                              const Icon(
                                Icons.notes,
                                size: 14,
                                color: AppColors.blueLight,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                Formatters.formatFollowUpDate(note.timestamp),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.steelDim,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                note.author,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.steelDim,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            note.content,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              height: 1.4,
                            ),
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

  // ── ABA 3: SCRIPTS ─────────────────────────────────────────────────────────
  Widget _buildScriptsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'SCRIPTS PERSONALIZADOS (COPIE COM 1 TOQUE)',
          style: TextStyle(
            fontFamily: 'BebasNeue',
            fontSize: 13,
            letterSpacing: 1.0,
            color: AppColors.blueLight,
          ),
        ),
        const SizedBox(height: 12),
        _ScriptTile(
          title: '💬 Proposta / Pitch Comercial',
          script: Formatters.buildWhatsAppPitchMessage(
            leadName: _lead.name,
            planName: _lead.targetPlanName.isNotEmpty
                ? _lead.targetPlanName
                : 'Consultoria VALEX',
            value: _lead.estimatedValue > 0 ? _lead.estimatedValue : null,
          ),
        ),
        _ScriptTile(
          title: '⏰ Follow-up 24 Horas',
          script: Formatters.buildFollowUp24hMessage(leadName: _lead.name),
        ),
        _ScriptTile(
          title: '🔥 Follow-up 48h (Urgência)',
          script: Formatters.buildFollowUp48hMessage(leadName: _lead.name),
        ),
        if (_lead.hasScheduledFollowUp)
          _ScriptTile(
            title:
                '📅 Retorno Agendado (${Formatters.formatFollowUpDate(_lead.scheduledFollowUpDate!)})',
            script: Formatters.buildWhatsAppScheduledReturnMessage(
              leadName: _lead.name,
              trainerName: 'Valex Coach',
              note: _lead.scheduledFollowUpNote,
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          'BATTLECARDS DE OBJEÇÕES',
          style: TextStyle(
            fontFamily: 'BebasNeue',
            fontSize: 13,
            letterSpacing: 1.0,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => ObjectionBattlecardsSheet(lead: _lead),
            ),
            icon: const Icon(Icons.shield, size: 18),
            label: const Text(
              'ABRIR CENTRAL DE OBJEÇÕES',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  // ── ABA 4: CALCULADORA DE ROI ──────────────────────────────────────────────
  Widget _buildRoiCalculatorTab() {
    double monthlyGym = 120;
    int monthsStuck = 12;

    return StatefulBuilder(
      builder: (ctx, setInner) {
        final costOfInertia = monthlyGym * monthsStuck;
        final planValue = _lead.estimatedValue > 0
            ? _lead.estimatedValue * 3
            : 1350.0;
        final savings = costOfInertia - planValue;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'CALCULADORA DE CUSTO DE OPORTUNIDADE',
              style: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 13,
                letterSpacing: 1.0,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Mostre ao lead quanto custou ficar sem resultado.',
              style: TextStyle(fontSize: 12, color: AppColors.steelDim),
            ),
            const SizedBox(height: 20),

            _SliderField(
              label: 'Mensalidade da academia atual',
              value: monthlyGym,
              min: 50,
              max: 400,
              prefix: 'R\$ ',
              onChanged: (v) => setInner(() => monthlyGym = v),
            ),
            const SizedBox(height: 16),
            _SliderField(
              label: 'Meses tentando sem resultado',
              value: monthsStuck.toDouble(),
              min: 3,
              max: 36,
              suffix: ' meses',
              divisions: 33,
              onChanged: (v) => setInner(() => monthsStuck = v.round()),
            ),

            const SizedBox(height: 24),
            const Divider(color: AppColors.carbon3),
            const SizedBox(height: 16),

            // Resultado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.carbon2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  _ResultRow(
                    label: '💸 Gasto na academia sem resultado',
                    value: 'R\$ ${costOfInertia.toStringAsFixed(0)}',
                    color: AppColors.crimson,
                  ),
                  const SizedBox(height: 8),
                  _ResultRow(
                    label: '🚀 Consultoria VALEX (3 meses)',
                    value: 'R\$ ${planValue.toStringAsFixed(0)}',
                    color: AppColors.blueLight,
                  ),
                  const Divider(color: AppColors.carbon3, height: 16),
                  _ResultRow(
                    label: savings >= 0
                        ? '💰 Economia potencial'
                        : '⚠️ Diferença de investimento',
                    value: 'R\$ ${savings.abs().toStringAsFixed(0)}',
                    color: savings >= 0 ? AppColors.emerald : AppColors.amber,
                    bold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final script =
                      'Fala ${_lead.name}! 💪\n\n'
                      'Deixa eu te mostrar um cálculo rápido:\n\n'
                      '❌ Você já gastou R\$ ${costOfInertia.toStringAsFixed(0)} com academia nesses $monthsStuck meses sem chegar no resultado.\n\n'
                      '✅ Com a Consultoria VALEX (3 meses) por R\$ ${planValue.toStringAsFixed(0)}, você tem metodologia científica e acompanhamento semanal.\n\n'
                      '${savings >= 0 ? "💰 Isso representa uma economia de R\$ ${savings.toStringAsFixed(0)} em comparação com continuar assim!" : "A diferença é apenas R\$ ${savings.abs().toStringAsFixed(0)} para sair do zero resultado."}\n\n'
                      'Vamos garantir sua vaga? 🚀';
                  Clipboard.setData(ClipboardData(text: script));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Script de ROI copiado! Cole no WhatsApp.'),
                      backgroundColor: AppColors.emerald,
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text(
                  'COPIAR SCRIPT DO ROI',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Bottom Actions ──────────────────────────────────────────────────────────
  Widget _buildBottomActions() {
    if (_lead.status == LeadStatus.won || _lead.status == LeadStatus.lost) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.carbon2,
        border: Border(top: BorderSide(color: AppColors.carbon3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final updated = _lead.copyWith(
                  status: LeadStatus.lost,
                  updatedAt: DateTime.now().toIso8601String(),
                );
                await widget.repository.saveLead(updated);
                widget.onLeadUpdated();
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lead arquivado.'),
                      backgroundColor: AppColors.carbon3,
                    ),
                  );
                }
              },
              icon: const Icon(
                Icons.archive_outlined,
                size: 16,
                color: AppColors.steel,
              ),
              label: const Text(
                'ARQUIVAR',
                style: TextStyle(fontSize: 11, color: AppColors.steel),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.steel),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                if (widget.onConvert != null) {
                  Navigator.of(context).pop();
                  widget.onConvert!();
                }
              },
              icon: const Icon(
                Icons.emoji_events,
                size: 18,
                color: Colors.black,
              ),
              label: const Text(
                'CONVERTER EM ALUNO 🎉',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets Auxiliares ─────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.carbon2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.carbon3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'BebasNeue',
              fontSize: 12,
              letterSpacing: 1.0,
              color: AppColors.steelDim,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.steelDim),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: valueColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ContactChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScriptTile extends StatelessWidget {
  final String title;
  final String script;

  const _ScriptTile({required this.title, required this.script});

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
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: Uri.decodeComponent(script)),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Script copiado!'),
                      backgroundColor: AppColors.emerald,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            Uri.decodeComponent(script),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.steel),
          ),
        ],
      ),
    );
  }
}

class _SliderField extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String prefix;
  final String suffix;
  final int? divisions;
  final ValueChanged<double> onChanged;

  const _SliderField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.prefix = '',
    this.suffix = '',
    this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.steel),
            ),
            Text(
              '$prefix${value.toStringAsFixed(0)}$suffix',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions ?? (max - min).round(),
          activeColor: AppColors.gold,
          inactiveColor: AppColors.carbon3,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _ResultRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: bold ? 13 : 12,
              color: bold ? Colors.white : AppColors.steel,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'BebasNeue',
            fontSize: bold ? 20 : 16,
            color: color,
          ),
        ),
      ],
    );
  }
}
