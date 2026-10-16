class StudentTimelineItem {
  final String id;
  final String studentId;
  final String timestamp;
  final String title;
  final String description;
  final String? referenceType;
  final String? referenceId;

  StudentTimelineItem({
    required this.id,
    required this.studentId,
    required this.timestamp,
    required this.title,
    this.description = '',
    this.referenceType,
    this.referenceId,
  });

  factory StudentTimelineItem.fromJson(Map<String, dynamic> json) {
    return StudentTimelineItem(
      id: json['id'] as String,
      studentId:
          json['studentId'] as String? ?? json['student_id'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      title: json['title'] as String? ?? 'Evento',
      description: json['description'] as String? ?? '',
      referenceType:
          json['referenceType'] as String? ?? json['reference_type'] as String?,
      referenceId:
          json['referenceId'] as String? ?? json['reference_id'] as String?,
    );
  }
}
