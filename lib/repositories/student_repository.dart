import 'package:valex_app/config/supabase_config.dart';
import 'package:valex_app/models/student_model.dart';
import 'package:valex_app/models/timeline_model.dart';

class StudentRepository {
  /// Links an email-confirmed account to its trainer-created student record.
  /// The RPC enforces identity matching on the server.
  Future<Student?> fetchStudentForCurrentAccount() async {
    if (!SupabaseConfig.hasAuthenticatedUser) return null;
    final client = SupabaseConfig.client;
    final studentId = await client.rpc('claim_student_account');
    if (studentId == null) return null;
    final row = await client
        .from('students')
        .select()
        .eq('id', studentId as String)
        .single();
    return Student.fromJson(row);
  }

  /// Carrega a lista de alunos do treinador autenticado no Supabase.
  /// Retorna lista vazia em qualquer falha; use [fetchStudentsOrThrow] quando
  /// for preciso distinguir "sem alunos" de "servidor indisponível".
  Future<List<Student>> fetchStudents() async {
    try {
      return await fetchStudentsOrThrow();
    } catch (_) {
      return [];
    }
  }

  Future<List<Student>> fetchStudentsOrThrow() async {
    final client = SupabaseConfig.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw StateError('Sessão ausente');

    final response = await client
        .from('students')
        .select()
        .eq('trainer_id', userId);

    return (response as List).map((json) => Student.fromJson(json)).toList();
  }

  /// Marca a reavaliação 360° no servidor e confirma a gravação.
  Future<bool> requestReassessment(String studentId) async {
    try {
      final client = SupabaseConfig.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return false;
      final rows = await client
          .from('students')
          .update({
            'needs_reassessment': true,
            'anamnese_pending': true,
            'reassessment_requested_at': DateTime.now()
                .toUtc()
                .toIso8601String(),
          })
          .eq('id', studentId)
          .eq('trainer_id', userId)
          .select('id')
          .timeout(const Duration(seconds: 20));
      return (rows as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Salva ou atualiza um aluno no Supabase
  Future<bool> saveStudent(Student student) async {
    try {
      final client = SupabaseConfig.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return false;

      final data = student.toJson();
      data['trainer_id'] = userId;
      data.removeWhere((_, value) => value == null);

      await client.from('students').upsert(data);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Arquiva ou reativa um aluno
  Future<bool> updateStudentStatus(String studentId, String status) async {
    try {
      final client = SupabaseConfig.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return false;
      await client
          .from('students')
          .update({'status': status})
          .eq('id', studentId)
          .eq('trainer_id', userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Carrega prontuário / dados de anamnese do aluno
  Future<Map<String, dynamic>?> fetchStudentRecord(String studentId) async {
    if (!SupabaseConfig.isConfigured || !SupabaseConfig.hasAuthenticatedUser) {
      return null;
    }
    try {
      final client = SupabaseConfig.client;
      final response = await client
          .from('student_records')
          .select()
          .eq('student_id', studentId)
          .maybeSingle();

      return response;
    } catch (_) {
      return null;
    }
  }

  /// Salva ou atualiza o prontuário de um aluno
  Future<bool> saveStudentRecord(
    String studentId,
    Map<String, dynamic> recordData,
  ) async {
    try {
      final client = SupabaseConfig.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return false;

      recordData['student_id'] = studentId;
      recordData['trainer_id'] = userId;

      await client
          .from('student_records')
          .upsert(recordData, onConflict: 'student_id,trainer_id');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Carrega o histórico (timeline) do aluno
  Future<List<StudentTimelineItem>> fetchTimeline(String studentId) async {
    if (!SupabaseConfig.isConfigured || !SupabaseConfig.hasAuthenticatedUser) {
      return [];
    }
    try {
      final client = SupabaseConfig.client;
      final response = await client
          .from('student_timeline')
          .select()
          .eq('student_id', studentId)
          .order('timestamp', ascending: false);

      return (response as List)
          .map((json) => StudentTimelineItem.fromJson(json))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Carrega o resumo financeiro do aluno
  Future<StudentFinancialSummary> fetchFinancialSummary(
    String studentId,
  ) async {
    if (!SupabaseConfig.isConfigured || !SupabaseConfig.hasAuthenticatedUser) {
      return StudentFinancialSummary();
    }
    try {
      final client = SupabaseConfig.client;
      final response = await client
          .from('student_financial_summary')
          .select()
          .eq('student_id', studentId)
          .maybeSingle();

      if (response == null) return StudentFinancialSummary();
      return _summaryFromRow(response);
    } catch (_) {
      return StudentFinancialSummary();
    }
  }

  /// Resumo financeiro de vários alunos em uma única consulta.
  /// Lança exceção em falha para a tela mostrar o erro em vez de zeros.
  Future<Map<String, StudentFinancialSummary>> fetchFinancialSummaries(
    List<String> studentIds,
  ) async {
    if (studentIds.isEmpty ||
        !SupabaseConfig.isConfigured ||
        !SupabaseConfig.hasAuthenticatedUser) {
      return {};
    }
    final response = await SupabaseConfig.client
        .from('student_financial_summary')
        .select()
        .inFilter('student_id', studentIds);
    return {
      for (final row in response as List)
        (row['student_id']).toString(): _summaryFromRow(
          Map<String, dynamic>.from(row as Map),
        ),
    };
  }

  StudentFinancialSummary _summaryFromRow(Map<String, dynamic> response) =>
      StudentFinancialSummary(
        planName: response['plan_name'] as String? ?? 'Sem plano ativo',
        subscriptionStatus:
            response['subscription_status'] as String? ?? 'Nenhum',
        nextDueDate: response['next_due_date'] as String? ?? '-',
        totalOpen: (response['total_open'] as num?)?.toDouble() ?? 0.0,
        totalOverdue: (response['total_overdue'] as num?)?.toDouble() ?? 0.0,
        lastPaymentDate: response['last_payment_date'] as String? ?? '-',
        badge: _parseBadge(response['badge'] as String?),
      );

  FinancialBadge _parseBadge(String? badgeStr) {
    if (badgeStr == 'overdue') return FinancialBadge.overdue;
    if (badgeStr == 'dueToday') return FinancialBadge.dueToday;
    if (badgeStr == 'paid') return FinancialBadge.paid;
    return FinancialBadge.noInvoice;
  }
}
