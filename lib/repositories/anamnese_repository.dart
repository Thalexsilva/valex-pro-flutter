import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/anamnese_model.dart';
import '../models/student_model.dart';
import '../services/student_context_service.dart';
import 'student_repository.dart';

class AnamneseRepository {
  final String Function() _accountId;
  AnamneseRepository({String Function()? accountId})
    : _accountId =
          accountId ??
          (() => SupabaseConfig.hasAuthenticatedUser
              ? SupabaseConfig.client.auth.currentUser!.id
              : 'signed-out');

  String _scoped(String key) => '${_accountId()}:$key';
  static const String _draftStoragePrefix = 'valex_anamnese_draft_';
  static const String _documentStoragePrefix = 'storage://student-documents/';

  /// Salva rascunho em tempo real no armazenamento local do dispositivo
  Future<bool> saveLocalDraft(AnamneseModel anamnese) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key =
          '$_draftStoragePrefix${anamnese.studentId.isNotEmpty ? anamnese.studentId : anamnese.id}';
      return await prefs.setString(_scoped(key), jsonEncode(anamnese.toJson()));
    } catch (_) {
      return false;
    }
  }

  /// Recupera rascunho local de anamnese em andamento
  Future<AnamneseModel?> getLocalDraft(String studentIdOrDraftId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_draftStoragePrefix$studentIdOrDraftId';
      final jsonString = prefs.getString(_scoped(key));
      if (jsonString != null && jsonString.isNotEmpty) {
        final map = jsonDecode(jsonString) as Map<String, dynamic>;
        return AnamneseModel.fromJson(map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Remove rascunho local após envio bem-sucedido
  Future<void> clearLocalDraft(String studentIdOrDraftId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_draftStoragePrefix$studentIdOrDraftId';
      await prefs.remove(_scoped(key));
    } catch (_) {}
  }

  Future<void> clearCurrentAccountCache() async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '${_accountId()}:valex_anamnese_';
    for (final key in prefs.getKeys().where((key) => key.startsWith(prefix))) {
      await prefs.remove(key);
    }
  }

  /// Salva ou sincroniza a Anamnese completa no Supabase
  Future<bool> saveAnamnese(AnamneseModel anamnese) async {
    try {
      if (!await saveLocalDraft(anamnese)) return false;
      if (!SupabaseConfig.hasAuthenticatedUser) {
        final saved = await _cacheAnamneseLocally(anamnese);
        if (saved) {
          StudentContextService().completeStudentAnamnese(anamnese.studentId);
          await clearLocalDraft(anamnese.studentId);
        }
        return saved;
      }

      final client = SupabaseConfig.client;
      final userId = client.auth.currentUser?.id;

      final data = anamnese.toJson();
      final studentRow = anamnese.studentId.isEmpty
          ? null
          : await client
                .from('students')
                .select('trainer_id')
                .eq('id', anamnese.studentId)
                .maybeSingle();
      final trainerId = studentRow?['trainer_id'] as String? ?? userId;
      data['trainer_id'] = trainerId;

      // 2. Persiste na tabela student_anamneses do Supabase se autenticado
      if (userId != null) {
        AnamneseModel? previous;
        final previousRow = await client
            .from('student_anamneses')
            .select()
            .eq('id', anamnese.id)
            .eq('trainer_id', trainerId!)
            .maybeSingle();
        if (previousRow != null) {
          previous = AnamneseModel.fromJson(previousRow);
        }
        await client.from('student_anamneses').upsert(data);
        if (previous != null) {
          await _cleanupRemovedAttachments(previous, anamnese);
        }
      }

      // 3. Atualiza o cadastro do aluno com o novo prontuário e notas de instrução
      if (anamnese.studentId.isNotEmpty && trainerId == userId) {
        final studentRepo = StudentRepository();
        final currentStudents = await studentRepo.fetchStudents();
        final existingStudent = currentStudents.cast<Student?>().firstWhere(
          (s) => s?.id == anamnese.studentId,
          orElse: () => null,
        );

        if (existingStudent != null) {
          final updatedStudent = existingStudent.copyWith(
            cpf: anamnese.cpf.isNotEmpty ? anamnese.cpf : existingStudent.cpf,
            phone: anamnese.phone.isNotEmpty
                ? anamnese.phone
                : existingStudent.phone,
            email: anamnese.email.isNotEmpty
                ? anamnese.email
                : existingStudent.email,
            gymName: anamnese.gymName.isNotEmpty
                ? anamnese.gymName
                : existingStudent.gymName,
            niche: anamnese.mainGoal.isNotEmpty
                ? anamnese.mainGoal
                : existingStudent.niche,
            prontuarioText: anamnese.toProntuarioSummary(),
            instructorNotes: anamnese.toInstructorNotes(),
            needsReassessment: false,
            anamnesePending: false,
            lastAnamneseDate: DateTime.now().toIso8601String(),
          );
          if (!await studentRepo.saveStudent(updatedStudent)) return false;
        }
        StudentContextService().completeStudentAnamnese(anamnese.studentId);
      }

      await _cacheAnamneseLocally(anamnese);
      // 4. Limpa o rascunho temporário
      await clearLocalDraft(
        anamnese.studentId.isNotEmpty ? anamnese.studentId : anamnese.id,
      );

      return true;
    } catch (_) {
      // Keep the draft, but never report a failed remote write as completed.
      return false;
    }
  }

  /// Solicita nova reavaliação 360° para o aluno. Com sessão ativa só
  /// retorna verdadeiro depois que o servidor confirma a gravação.
  Future<bool> requestReassessment(String studentId, {String? reason}) async {
    if (!SupabaseConfig.hasAuthenticatedUser) {
      StudentContextService().requestStudentReassessment(studentId);
      return true;
    }
    final context = StudentContextService();
    if (context.allStudents.any((student) => student.id == studentId)) {
      return context.requestReassessment(studentId);
    }
    return StudentRepository().requestReassessment(studentId);
  }

  /// Verifica se o aluno precisa do Fluxo 360° (primeiro acesso ou reavaliação solicitada)
  Future<bool> checkNeeds360(String studentId) async {
    try {
      final studentRepo = StudentRepository();
      final currentStudents = await studentRepo.fetchStudents();
      var existingStudent = currentStudents.cast<Student?>().firstWhere(
        (s) => s?.id == studentId,
        orElse: () => null,
      );

      if (existingStudent == null) {
        final localStudents = StudentContextService().allStudents;
        existingStudent = localStudents.cast<Student?>().firstWhere(
          (s) => s?.id == studentId,
          orElse: () => null,
        );
      }

      if (existingStudent != null) {
        if (existingStudent.needsReassessment ||
            existingStudent.anamnesePending) {
          return true;
        }
      }

      final anamnese = await fetchByStudentId(studentId);
      return anamnese == null;
    } catch (_) {
      return false;
    }
  }

  /// Busca a anamnese mais recente de um aluno
  Future<AnamneseModel?> fetchByStudentId(String studentId) async {
    try {
      // Tenta buscar no Supabase
      final client = SupabaseConfig.client;
      final response = await client
          .from('student_anamneses')
          .select()
          .eq('student_id', studentId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return AnamneseModel.fromJson(response);
      }
    } catch (_) {}

    // Fallback: busca no cache local
    return _getCachedAnamnese(studentId);
  }

  /// Busca o histórico completo de anamneses do aluno para gráficos longitudinais
  Future<List<AnamneseModel>> fetchHistoryByStudentId(String studentId) async {
    try {
      final client = SupabaseConfig.client;
      final response = await client
          .from('student_anamneses')
          .select()
          .eq('student_id', studentId)
          .order(
            'created_at',
            ascending: true,
          ); // Ordem cronológica para gráficos

      final List<dynamic> data = response;
      return data.map((json) => AnamneseModel.fromJson(json)).toList();
    } catch (_) {}

    final local = await _getCachedAnamnese(studentId);
    return local != null ? [local] : [];
  }

  /// Histórico em ordem cronológica, distinguindo "sem avaliação" de falha
  /// de conexão. Em falha devolve a última avaliação salva no aparelho.
  Future<AnamneseLoadResult> fetchHistoryResult(String studentId) async {
    try {
      final response = await SupabaseConfig.client
          .from('student_anamneses')
          .select()
          .eq('student_id', studentId)
          .order('created_at', ascending: true);
      final history = (response as List)
          .map(
            (json) => AnamneseModel.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
      return AnamneseLoadResult(
        history.isEmpty ? AnamneseLoadStatus.empty : AnamneseLoadStatus.loaded,
        history,
      );
    } catch (_) {
      final cached = await _getCachedAnamnese(studentId);
      return AnamneseLoadResult(AnamneseLoadStatus.error, [?cached]);
    }
  }

  /// Upload de Foto Postural para o Supabase Storage Bucket `student-documents`
  Future<String?> uploadPosturePhoto({
    required String studentId,
    required String photoId,
    required PostureAngle angle,
    required List<int> imageBytes,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final client = SupabaseConfig.client;
      final extension = contentType == 'image/png' ? 'png' : 'jpg';
      final fileName = 'posture_${studentId}_${angle.name}_$photoId.$extension';
      final path = '$studentId/posture/$fileName';

      await client.storage
          .from('student-documents')
          .uploadBinary(
            path,
            Uint8List.fromList(imageBytes),
            fileOptions: FileOptions(contentType: contentType),
          );

      return '$_documentStoragePrefix$path';
    } catch (_) {
      return null;
    }
  }

  /// Upload de Laudo ou Documento PDF para o Supabase Storage
  Future<String?> uploadMedicalDocument({
    required String studentId,
    required String docId,
    required String fileName,
    required List<int> docBytes,
    String contentType = 'application/pdf',
  }) async {
    try {
      final client = SupabaseConfig.client;
      final path = '$studentId/documents/${docId}_$fileName';

      await client.storage
          .from('student-documents')
          .uploadBinary(
            path,
            Uint8List.fromList(docBytes),
            fileOptions: FileOptions(contentType: contentType),
          );

      return '$_documentStoragePrefix$path';
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteDocumentReference({
    required String studentId,
    required String reference,
  }) async {
    final path = _extractDocumentPath(reference);
    if (path == null) return true;
    if (!SupabaseConfig.hasAuthenticatedUser ||
        studentId.isEmpty ||
        !path.startsWith('$studentId/')) {
      return false;
    }
    try {
      await SupabaseConfig.client.storage.from('student-documents').remove([
        path,
      ]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _cleanupRemovedAttachments(
    AnamneseModel previous,
    AnamneseModel current,
  ) async {
    final currentReferences = _attachmentReferences(current);
    final removed = _attachmentReferences(
      previous,
    ).difference(currentReferences);
    for (final reference in removed) {
      await deleteDocumentReference(
        studentId: current.studentId,
        reference: reference,
      );
    }
  }

  Set<String> _attachmentReferences(AnamneseModel anamnese) => {
    for (final photo in anamnese.posturePhotos) photo.url,
    for (final document in anamnese.documents) document.fileUrl,
    if (anamnese.bioimpedance?.fileUrl case final String reference) reference,
  };

  /// Gerenciamento de Cache Local
  Future<bool> _cacheAnamneseLocally(AnamneseModel anamnese) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'valex_anamnese_${anamnese.studentId}';
      return await prefs.setString(_scoped(key), jsonEncode(anamnese.toJson()));
    } catch (_) {
      return false;
    }
  }

  Future<AnamneseModel?> _getCachedAnamnese(String studentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'valex_anamnese_$studentId';
      final raw = prefs.getString(_scoped(key));
      if (raw != null) {
        return AnamneseModel.fromJson(jsonDecode(raw));
      }
    } catch (_) {}
    return null;
  }

  Future<Uri> documentUri(String reference) async {
    final path = _extractDocumentPath(reference);
    if (path == null) {
      throw const FormatException('Arquivo indisponivel neste projeto.');
    }
    final signed = await SupabaseConfig.client.storage
        .from('student-documents')
        .createSignedUrl(path, 3600);
    return Uri.parse(signed);
  }

  String? _extractDocumentPath(String storedValue) {
    if (storedValue.startsWith(_documentStoragePrefix)) {
      return storedValue.substring(_documentStoragePrefix.length);
    }
    final uri = Uri.tryParse(storedValue);
    if (uri == null || uri.host != Uri.parse(SupabaseConfig.url).host) {
      return null;
    }
    for (final marker in [
      '/storage/v1/object/public/student-documents/',
      '/storage/v1/object/sign/student-documents/',
    ]) {
      if (uri.path.startsWith(marker)) {
        return Uri.decodeComponent(uri.path.substring(marker.length));
      }
    }
    return null;
  }
}

enum AnamneseLoadStatus { loaded, empty, error }

class AnamneseLoadResult {
  final AnamneseLoadStatus status;

  /// Avaliações em ordem cronológica; a última é a vigente.
  final List<AnamneseModel> history;

  const AnamneseLoadResult(this.status, this.history);

  AnamneseModel? get latest => history.isEmpty ? null : history.last;
}
