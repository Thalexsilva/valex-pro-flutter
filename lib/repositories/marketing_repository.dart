import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import '../models/marketing_models.dart';

class MarketingRepository {
  MarketingRepository({String Function()? accountId, this.campaignWriter})
    : _accountId = accountId ?? _defaultAccountId;

  static const String _campaignsKey = 'valex_marketing_campaigns_v1';
  static const String _creativesKey = 'valex_marketing_creatives_v1';
  final String Function() _accountId;
  final Future<bool> Function(String key, String value)? campaignWriter;

  List<MarketingCampaign> _cachedCampaigns = [];
  List<AdCreativeItem> _cachedCreatives = [];
  String? _loadedAccountId;

  static String _defaultAccountId() {
    try {
      return SupabaseConfig.client.auth.currentUser?.id ?? 'signed-out';
    } catch (_) {
      return 'signed-out';
    }
  }

  String get _currentAccountId {
    final account = _accountId().trim();
    return account.isEmpty ? 'signed-out' : account;
  }

  String _scopedKey(String base, [String? account]) {
    final scope = account ?? _currentAccountId;
    return '${base}_$scope';
  }

  void _ensureAccountScope() {
    final account = _currentAccountId;
    if (_loadedAccountId == account) return;
    _cachedCampaigns = [];
    _cachedCreatives = [];
    _loadedAccountId = account;
  }

  /// Carrega todas as campanhas da persistência local
  Future<List<MarketingCampaign>> getCampaigns() async {
    _ensureAccountScope();
    if (_cachedCampaigns.isNotEmpty) return List.unmodifiable(_cachedCampaigns);

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_scopedKey(_campaignsKey));
      if (raw != null && raw.isNotEmpty) {
        final List decoded = jsonDecode(raw);
        _cachedCampaigns = decoded
            .map((e) => MarketingCampaign.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _cachedCampaigns = <MarketingCampaign>[];
      }
    } catch (_) {
      throw StateError('Não foi possível ler as campanhas neste aparelho.');
    }

    return List.unmodifiable(_cachedCampaigns);
  }

  /// Salva ou atualiza uma campanha
  Future<void> saveCampaign(MarketingCampaign campaign) async {
    final campaigns = await getCampaigns();
    final updatedList = List<MarketingCampaign>.from(campaigns);

    final idx = updatedList.indexWhere((c) => c.id == campaign.id);
    if (idx >= 0) {
      updatedList[idx] = campaign.copyWith(
        updatedAt: DateTime.now().toIso8601String(),
      );
    } else {
      updatedList.insert(0, campaign);
    }

    if (!await _saveCampaignsToPrefs(updatedList)) {
      throw StateError('Não foi possível salvar a campanha neste aparelho.');
    }
    _cachedCampaigns = updatedList;
  }

  /// Exclui uma campanha
  Future<void> deleteCampaign(String campaignId) async {
    final campaigns = await getCampaigns();
    final updatedList = List<MarketingCampaign>.from(campaigns)
      ..removeWhere((c) => c.id == campaignId);
    if (!await _saveCampaignsToPrefs(updatedList)) {
      throw StateError('Não foi possível excluir a campanha neste aparelho.');
    }
    _cachedCampaigns = updatedList;
  }

  /// Alterna o status da campanha (Ativa / Pausada)
  Future<MarketingCampaign?> toggleCampaignStatus(String campaignId) async {
    final campaigns = await getCampaigns();
    final idx = campaigns.indexWhere((c) => c.id == campaignId);
    if (idx >= 0) {
      final current = campaigns[idx];
      final newStatus = current.status == CampaignStatus.active
          ? CampaignStatus.paused
          : CampaignStatus.active;
      final updated = current.copyWith(
        status: newStatus,
        updatedAt: DateTime.now().toIso8601String(),
      );
      await saveCampaign(updated);
      return updated;
    }
    return null;
  }

  /// Carrega a biblioteca de criativos e roteiros
  Future<List<AdCreativeItem>> getCreatives() async {
    _ensureAccountScope();
    if (_cachedCreatives.isNotEmpty) return List.unmodifiable(_cachedCreatives);

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_scopedKey(_creativesKey));
      if (raw != null && raw.isNotEmpty) {
        final List decoded = jsonDecode(raw);
        _cachedCreatives = decoded
            .map((e) => AdCreativeItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _cachedCreatives = List.from(AdCreativeItem.defaultCreatives);
        await _saveCreativesToPrefs(_cachedCreatives);
      }
    } catch (_) {
      throw StateError('Não foi possível ler os criativos neste aparelho.');
    }

    return List.unmodifiable(_cachedCreatives);
  }

  /// Salva ou atualiza um criativo
  Future<void> saveCreative(AdCreativeItem creative) async {
    final creatives = await getCreatives();
    final updated = List<AdCreativeItem>.from(creatives);
    final idx = updated.indexWhere((c) => c.id == creative.id);
    if (idx >= 0) {
      updated[idx] = creative;
    } else {
      updated.insert(0, creative);
    }
    _cachedCreatives = updated;
    await _saveCreativesToPrefs(updated);
  }

  /// Chave da semana corrente (segunda-feira), para o checklist semanal.
  static String weekKey(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final monday = day.subtract(Duration(days: day.weekday - DateTime.monday));
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-'
        '${monday.day.toString().padLeft(2, '0')}';
  }

  /// Ações do checklist semanal concluídas nesta semana.
  Future<Set<int>> getWeeklyChecklist(DateTime now) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(
        _scopedKey('valex_marketing_checklist_${weekKey(now)}'),
      );
      return {...?raw?.map(int.tryParse).whereType<int>()};
    } catch (_) {
      return {};
    }
  }

  Future<bool> saveWeeklyChecklist(DateTime now, Set<int> done) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setStringList(
        _scopedKey('valex_marketing_checklist_${weekKey(now)}'),
        (done.toList()..sort()).map((e) => '$e').toList(),
      );
    } catch (_) {
      return false;
    }
  }

  /// Obtém o resumo consolidado de métricas de marketing
  Future<MarketingMetricsSummary> getMetricsSummary() async {
    final campaigns = await getCampaigns();
    return MarketingMetricsSummary.calculate(campaigns);
  }

  /// Registra a atribuição de um lead recém-chegado a uma campanha
  Future<void> recordLeadAttribution(String utmCampaign) async {
    final campaigns = await getCampaigns();
    final idx = campaigns.indexWhere(
      (c) => c.utmCampaign.toLowerCase() == utmCampaign.toLowerCase(),
    );
    if (idx >= 0) {
      final camp = campaigns[idx];
      final updated = camp.copyWith(
        leadsGenerated: camp.leadsGenerated + 1,
        updatedAt: DateTime.now().toIso8601String(),
      );
      await saveCampaign(updated);
    }
  }

  /// Registra a conversão de um aluno ganho associado à campanha
  Future<void> recordWonStudentAttribution(
    String utmCampaign,
    double revenue,
  ) async {
    final campaigns = await getCampaigns();
    final idx = campaigns.indexWhere(
      (c) => c.utmCampaign.toLowerCase() == utmCampaign.toLowerCase(),
    );
    if (idx >= 0) {
      final camp = campaigns[idx];
      final updated = camp.copyWith(
        wonStudents: camp.wonStudents + 1,
        revenueGenerated: camp.revenueGenerated + revenue,
        updatedAt: DateTime.now().toIso8601String(),
      );
      await saveCampaign(updated);
    }
  }

  // ── Helpers de persistência interna ─────────────────────────────────────────

  Future<bool> _saveCampaignsToPrefs(List<MarketingCampaign> list) async {
    try {
      _ensureAccountScope();
      final jsonStr = jsonEncode(list.map((c) => c.toJson()).toList());
      final key = _scopedKey(_campaignsKey);
      if (campaignWriter != null) return await campaignWriter!(key, jsonStr);
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(key, jsonStr);
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveCreativesToPrefs(List<AdCreativeItem> list) async {
    try {
      _ensureAccountScope();
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(list.map((c) => c.toJson()).toList());
      await prefs.setString(_scopedKey(_creativesKey), jsonStr);
    } catch (_) {}
  }

  Future<void> clearCurrentAccountCache() async {
    _ensureAccountScope();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scopedKey(_campaignsKey));
    await prefs.remove(_scopedKey(_creativesKey));
    _cachedCampaigns = [];
    _cachedCreatives = [];
  }
}
