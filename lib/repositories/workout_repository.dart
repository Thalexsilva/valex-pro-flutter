import 'package:valex_app/config/supabase_config.dart';
import 'package:valex_app/models/workout_model.dart';

enum ActiveWorkoutLoadStatus { loaded, empty, error }

class ActiveWorkoutLoadResult {
  final ActiveWorkoutLoadStatus status;
  final WorkoutSheet? sheet;

  const ActiveWorkoutLoadResult(this.status, [this.sheet]);
}

class WorkoutRepository {
  /// Carrega a ficha de treino ativa de um aluno no Supabase
  Future<WorkoutSheet?> fetchActiveSheet(String studentId) async {
    return (await fetchActiveSheetResult(studentId)).sheet;
  }

  /// Diferencia uma ficha ausente de uma falha ao consultar a ficha.
  Future<ActiveWorkoutLoadResult> fetchActiveSheetResult(
    String studentId,
  ) async {
    try {
      final client = SupabaseConfig.client;
      final response = await client
          .from('workout_sheets')
          .select()
          .eq('student_id', studentId)
          .maybeSingle();

      if (response == null) {
        return const ActiveWorkoutLoadResult(ActiveWorkoutLoadStatus.empty);
      }
      final map = Map<String, dynamic>.from(response as Map);
      final sheet = WorkoutSheet(
        studentId: map['student_id'] as String? ?? studentId,
        studentName: map['student_name'] as String? ?? '',
        gymName: map['gym_name'] as String? ?? map['academia'] as String? ?? '',
        month: map['month'] as String? ?? map['mes'] as String? ?? '',
        instructorNotes: map['instructor_notes'] as String? ?? '',
        days:
            (map['days'] as List?)
                ?.map((d) => WorkoutDay.fromJson(Map<String, dynamic>.from(d)))
                .toList() ??
            [],
        cardioOptions:
            (map['cardio_options'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        generalNotes:
            ((map['general_notes'] ?? map['observacoes']) as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
      return ActiveWorkoutLoadResult(ActiveWorkoutLoadStatus.loaded, sheet);
    } catch (_) {
      return const ActiveWorkoutLoadResult(ActiveWorkoutLoadStatus.error);
    }
  }

  /// Salva ou atualiza a ficha de treino ativa no Supabase
  Future<bool> saveActiveSheet(WorkoutSheet sheet) async {
    try {
      final client = SupabaseConfig.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return false;

      final data = {
        'student_id': sheet.studentId,
        'student_name': sheet.studentName,
        'gym_name': sheet.gymName,
        'month': sheet.month,
        'instructor_notes': sheet.instructorNotes,
        'days': sheet.days.map((d) => d.toJson()).toList(),
        'cardio_options': sheet.cardioOptions,
        'general_notes': sheet.generalNotes,
        'trainer_id': userId,
      };

      await client
          .from('workout_sheets')
          .upsert(data, onConflict: 'student_id,trainer_id');
      return true;
    } catch (e, st) {
      // ignore: avoid_print
      print('DEBUG saveActiveSheet Error: $e \n $st');
      return false;
    }
  }

  /// Cria um snapshot de versão da ficha de treino
  Future<bool> saveVersionSnapshot(
    String studentId,
    WorkoutSheet sheet,
    String versionName,
  ) async {
    try {
      final client = SupabaseConfig.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return false;

      // Busca ou garante que a workout_sheet existe no backend
      final activeSheet = await client
          .from('workout_sheets')
          .select('id')
          .eq('student_id', studentId)
          .eq('trainer_id', userId)
          .maybeSingle();

      String sheetId;
      if (activeSheet != null) {
        sheetId = activeSheet['id'] as String;
      } else {
        final saved = await saveActiveSheet(sheet);
        if (!saved) return false;
        final newSheet = await client
            .from('workout_sheets')
            .select('id')
            .eq('student_id', studentId)
            .eq('trainer_id', userId)
            .single();
        sheetId = newSheet['id'] as String;
      }

      final payload = {
        'student_id': studentId,
        'workout_sheet_id': sheetId,
        'trainer_id': userId,
        'version_name': versionName,
        'sheet_data': sheet.toJson(),
      };

      await client.from('sheet_versions').insert(payload);
      return true;
    } catch (e, st) {
      // ignore: avoid_print
      print('DEBUG saveVersionSnapshot Error: $e \n $st');
      return false;
    }
  }

  /// Carrega o histórico de versões de um aluno
  Future<List<WorkoutSheet>> fetchVersionHistory(String studentId) async {
    try {
      final client = SupabaseConfig.client;
      final response = await client
          .from('sheet_versions')
          .select()
          .eq('student_id', studentId)
          .order('created_at', ascending: false);

      return (response as List).map((row) {
        final data = Map<String, dynamic>.from(row['sheet_data'] as Map);
        data['currentVersionName'] = row['version_name'];
        return WorkoutSheet.fromJson(data);
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
