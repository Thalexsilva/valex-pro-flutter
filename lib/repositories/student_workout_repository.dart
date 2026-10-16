import '../config/supabase_config.dart';
import '../models/student_model.dart';

class StudentWorkoutEntry {
  final String studentId;
  final String kind;
  final String workoutDay;
  final String feedback;
  final DateTime createdAt;
  final int durationSeconds;
  final int? rpe;

  StudentWorkoutEntry.fromJson(Map<String, dynamic> json)
    : studentId = json['student_id']?.toString() ?? '',
      kind = json['kind'] as String? ?? 'comment',
      workoutDay = json['workout_day'] as String? ?? '',
      feedback = json['feedback'] as String? ?? '',
      createdAt =
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      durationSeconds = (json['duration_seconds'] as num?)?.toInt() ?? 0,
      rpe = (json['rpe'] as num?)?.toInt();
}

class StudentWorkoutRepository {
  Future<void> sendComment(Student student, String body) async {
    final text = body.trim();
    if (text.isEmpty || text.length > 2000) {
      throw const FormatException(
        'Escreva um comentário de até 2.000 caracteres.',
      );
    }
    await SupabaseConfig.client.from('student_workout_sessions').insert({
      'student_id': student.id,
      'trainer_id': student.trainerId,
      'kind': 'comment',
      'feedback': text,
    });
  }

  Future<void> saveSession({
    required Student student,
    required String workoutDay,
    required Map<int, Set<int>> completedSets,
    required int durationSeconds,
    required int rpe,
    required String feedback,
  }) async {
    final text = feedback.trim();
    if (text.length > 2000) {
      throw const FormatException(
        'O comentário deve ter até 2.000 caracteres.',
      );
    }
    await SupabaseConfig.client.from('student_workout_sessions').insert({
      'student_id': student.id,
      'trainer_id': student.trainerId,
      'kind': 'session',
      'workout_day': workoutDay,
      'completed_sets': completedSets.map(
        (exercise, sets) => MapEntry('$exercise', sets.toList()..sort()),
      ),
      'duration_seconds': durationSeconds,
      'rpe': rpe,
      'feedback': text,
    });
  }

  Future<List<StudentWorkoutEntry>> fetchEntries(String studentId) async {
    final rows = await SupabaseConfig.client
        .from('student_workout_sessions')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false)
        .limit(50);
    return (rows as List)
        .map(
          (row) => StudentWorkoutEntry.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  /// Treinos e mensagens mais recentes de todos os alunos do instrutor.
  Future<List<StudentWorkoutEntry>> fetchRecentForTrainer({
    int limit = 8,
  }) async {
    if (!SupabaseConfig.hasAuthenticatedUser) return [];
    final trainerId = SupabaseConfig.client.auth.currentUser!.id;
    final rows = await SupabaseConfig.client
        .from('student_workout_sessions')
        .select()
        .eq('trainer_id', trainerId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map(
          (row) => StudentWorkoutEntry.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }
}
