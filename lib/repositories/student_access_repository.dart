import '../config/supabase_config.dart';

class StudentAccessEvent {
  final String studentId;
  final DateTime occurredAt;
  final String? ipAddress;
  final String? city;
  final String? region;
  final String? country;
  final String? platform;
  final String? timeZone;

  const StudentAccessEvent({
    required this.studentId,
    required this.occurredAt,
    this.ipAddress,
    this.city,
    this.region,
    this.country,
    this.platform,
    this.timeZone,
  });

  factory StudentAccessEvent.fromJson(Map<String, dynamic> json) =>
      StudentAccessEvent(
        studentId: json['student_id'] as String,
        occurredAt: DateTime.parse(json['occurred_at'] as String).toLocal(),
        ipAddress: json['ip_address'] as String?,
        city: json['city'] as String?,
        region: json['region'] as String?,
        country: json['country'] as String?,
        platform: json['platform'] as String?,
        timeZone: json['time_zone'] as String?,
      );
}

class StudentAccessRepository {
  Future<(int, int)> summary({int days = 30}) async {
    final row = await SupabaseConfig.client
        .rpc('student_login_summary', params: {'p_days': days})
        .single();
    return (
      (row['total_logins'] as num).toInt(),
      (row['students_with_access'] as num).toInt(),
    );
  }

  Future<List<StudentAccessEvent>> recent({int days = 30}) async {
    final trainerId = SupabaseConfig.client.auth.currentUser?.id;
    if (trainerId == null) throw StateError('Sessão ausente');
    final since = DateTime.now()
        .toUtc()
        .subtract(Duration(days: days))
        .toIso8601String();
    final rows = await SupabaseConfig.client
        .from('student_login_events')
        .select(
          'student_id, occurred_at, ip_address, city, region, country, platform, time_zone',
        )
        .eq('trainer_id', trainerId)
        .gte('occurred_at', since)
        .order('occurred_at', ascending: false)
        .limit(500);
    return (rows as List)
        .map(
          (row) => StudentAccessEvent.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }
}
