import 'package:valex_app/config/supabase_config.dart';
import 'package:valex_app/models/sales_model.dart';
import 'package:valex_app/models/student_model.dart';
import 'package:valex_app/utils/formatters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SalesDataException implements Exception {
  final String message;
  final Object? cause;

  const SalesDataException(this.message, [this.cause]);

  @override
  String toString() => message;
}

class SalesRepository {
  final SupabaseClient? _clientOverride;
  SupabaseClient get _client => _clientOverride ?? SupabaseConfig.client;

  List<LeadItem> _leads = [];
  bool _loaded = false;

  SalesRepository({SupabaseClient? client}) : _clientOverride = client;

  Future<List<LeadItem>> fetchLeads() async {
    try {
      final client = _client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw const SalesDataException(
          'Entre na sua conta para acessar os leads do CRM.',
        );
      }

      final response = await client
          .from('leads')
          .select()
          .eq('trainer_id', userId)
          .order('score', ascending: false);

      _leads = (response as List)
          .map((json) => LeadItem.fromJson(json))
          .toList();
      _loaded = true;
      return List.unmodifiable(_leads);
    } on SalesDataException {
      rethrow;
    } catch (error) {
      throw SalesDataException(
        'Não foi possível carregar os leads do CRM.',
        error,
      );
    }
  }

  /// Salva ou atualiza um lead com cálculo de score
  Future<bool> saveLead(LeadItem lead) async {
    await _ensureLoaded();
    try {
      {
        final client = _client;
        final userId = _requireUserId();
        final data = lead.toJson();
        data['trainer_id'] = userId;
        await client.from('leads').upsert(data);
      }

      final updated = List<LeadItem>.from(_leads);
      final idx = updated.indexWhere((item) => item.id == lead.id);
      if (idx >= 0) {
        updated[idx] = lead;
      } else {
        updated.insert(0, lead);
      }

      _leads = updated;
      return true;
    } on SalesDataException {
      rethrow;
    } catch (error) {
      throw SalesDataException('Não foi possível salvar o lead.', error);
    }
  }

  /// Agenda ou atualiza o lembrete de retorno (follow-up) do lead
  Future<bool> scheduleFollowUp(
    String leadId,
    DateTime scheduledDate,
    String? note,
  ) async {
    await _ensureLoaded();
    final idx = _leads.indexWhere((l) => l.id == leadId);
    if (idx >= 0) {
      final lead = _leads[idx];
      final newNote = note != null && note.isNotEmpty
          ? LeadNote(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content:
                  '⏰ Retorno agendado para ${scheduledDate.day}/${scheduledDate.month} às ${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}: $note',
              timestamp: DateTime.now().toIso8601String(),
            )
          : null;

      final updatedNotes = newNote != null
          ? (List<LeadNote>.from(lead.notes)..add(newNote))
          : lead.notes;

      final updated = lead.copyWith(
        scheduledFollowUpDate: scheduledDate.toIso8601String(),
        scheduledFollowUpNote: note,
        notes: updatedNotes,
        updatedAt: DateTime.now().toIso8601String(),
      );
      return await saveLead(updated);
    }
    return false;
  }

  /// Remove o lembrete de retorno de um lead
  Future<bool> clearScheduledFollowUp(String leadId) async {
    await _ensureLoaded();
    final idx = _leads.indexWhere((l) => l.id == leadId);
    if (idx >= 0) {
      final lead = _leads[idx];
      final updated = lead.copyWith(
        clearScheduledFollowUp: true,
        updatedAt: DateTime.now().toIso8601String(),
      );
      return await saveLead(updated);
    }
    return false;
  }

  /// Atualiza o estágio do funil do lead
  Future<bool> updateLeadStatus(
    String leadId,
    LeadStatus newStatus, {
    String? lossReason,
  }) async {
    await _ensureLoaded();
    final idx = _leads.indexWhere((l) => l.id == leadId);
    if (idx >= 0) {
      final lead = _leads[idx];
      final updated = lead.copyWith(
        status: newStatus,
        lossReason: lossReason,
        updatedAt: DateTime.now().toIso8601String(),
      );
      return await saveLead(updated);
    }
    return false;
  }

  /// Adiciona uma anotação rápida ao lead
  Future<bool> addLeadNote(String leadId, String noteContent) async {
    await _ensureLoaded();
    final idx = _leads.indexWhere((l) => l.id == leadId);
    if (idx >= 0) {
      final lead = _leads[idx];
      final newNote = LeadNote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: noteContent,
        timestamp: DateTime.now().toIso8601String(),
      );
      final updatedNotes = List<LeadNote>.from(lead.notes)..add(newNote);
      final updated = lead.copyWith(
        notes: updatedNotes,
        lastContactAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );
      return await saveLead(updated);
    }
    return false;
  }

  /// Remove um lead do CRM
  Future<bool> deleteLead(String leadId) async {
    await _ensureLoaded();
    if (!_leads.any((lead) => lead.id == leadId)) return false;

    try {
      {
        final client = _client;
        final userId = _requireUserId();
        await client
            .from('leads')
            .delete()
            .eq('id', leadId)
            .eq('trainer_id', userId);
      }

      final updated = List<LeadItem>.from(_leads)
        ..removeWhere((lead) => lead.id == leadId);

      _leads = updated;
      return true;
    } on SalesDataException {
      rethrow;
    } catch (error) {
      throw SalesDataException('Não foi possível excluir o lead.', error);
    }
  }

  /// Cria o aluno antes de marcar o lead como convertido.
  Future<Student?> convertLeadToStudent({
    required LeadItem lead,
    String? planId,
    String? planName,
    double? price,
    String? gymName,
  }) async {
    await _ensureLoaded();
    final newStudentId = Formatters.generateUuidV4();
    final nowStr = DateTime.now().toIso8601String();

    // 1. Cria aluno
    final newStudent = Student(
      id: newStudentId,
      name: lead.name,
      date: nowStr.split('T')[0],
      cpf: '',
      phone: lead.phone,
      email: lead.email,
      address: '',
      niche: lead.objective.isNotEmpty ? lead.objective : 'Consultoria Online',
      prontuarioText:
          'Convertido do CRM VALEX em $nowStr (Score: ${lead.score} pts). Instagram: ${lead.instagram}. Origem: ${lead.originChannel}. Objetivo: ${lead.objective}',
      gymName: gymName ?? 'VALEX Consultoria',
      status: StudentStatus.active,
    );

    {
      try {
        _requireUserId();
        final response = await _client.rpc(
          'convert_lead_to_student',
          params: {'p_lead_id': lead.id, 'p_student': newStudent.toJson()},
        );
        if (response is! Map) {
          throw const FormatException('Resposta de conversão inválida.');
        }
        final persistedStudent = Student.fromJson(
          Map<String, dynamic>.from(response),
        );
        final wonLead = lead.copyWith(
          status: LeadStatus.won,
          clearScheduledFollowUp: true,
          updatedAt: nowStr,
        );
        final leadIndex = _leads.indexWhere((item) => item.id == lead.id);
        if (leadIndex >= 0) _leads[leadIndex] = wonLead;
        return persistedStudent;
      } catch (error) {
        throw SalesDataException(
          'Não foi possível converter o lead. Nenhum aluno foi criado.',
          error,
        );
      }
    }
  }

  /// Calcula métricas comerciais consolidadas
  Future<SalesMetricsData> fetchMetrics() async {
    final leads = await fetchLeads();
    return SalesMetricsData.calculate(leads);
  }

  Future<void> _ensureLoaded() async {
    if (!_loaded) await fetchLeads();
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const SalesDataException(
        'Entre na sua conta para alterar os leads do CRM.',
      );
    }
    return userId;
  }

  Future<void> clearLocalCache() async {
    _leads = [];
    _loaded = false;
  }
}
