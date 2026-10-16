enum StudentStatus { active, archived }

enum FinancialBadge { overdue, dueToday, paid, noInvoice }

extension FinancialBadgeExtension on FinancialBadge {
  String get label {
    switch (this) {
      case FinancialBadge.overdue:
        return 'Atrasado';
      case FinancialBadge.dueToday:
        return 'Vence Hoje';
      case FinancialBadge.paid:
        return 'Pago';
      case FinancialBadge.noInvoice:
        return 'Sem Fatura';
    }
  }
}

class Student {
  final String id;
  final String? trainerId;
  final String name;
  final String date;
  final String teacher;
  final StudentStatus status;
  final String cpf;
  final String phone;
  final String email;
  final String address;
  final String niche;
  final String prontuarioText;
  final String evolucao;
  final String gymName;
  final String month;
  final String instructorNotes;
  final bool needsReassessment;
  final bool anamnesePending;
  final String? lastAnamneseDate;
  final String? reassessmentRequestedAt;

  Student({
    required this.id,
    this.trainerId,
    required this.name,
    this.date = '',
    this.teacher = '',
    this.status = StudentStatus.active,
    this.cpf = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.niche = '',
    this.prontuarioText = '',
    this.evolucao = '',
    this.gymName = '',
    this.month = '',
    this.instructorNotes = '',
    this.needsReassessment = false,
    this.anamnesePending = false,
    this.lastAnamneseDate,
    this.reassessmentRequestedAt,
  });

  bool get isArchived => status == StudentStatus.archived;

  Student copyWith({
    String? id,
    String? trainerId,
    String? name,
    String? date,
    String? teacher,
    StudentStatus? status,
    String? cpf,
    String? phone,
    String? email,
    String? address,
    String? niche,
    String? prontuarioText,
    String? evolucao,
    String? gymName,
    String? month,
    String? instructorNotes,
    bool? needsReassessment,
    bool? anamnesePending,
    String? lastAnamneseDate,
    String? reassessmentRequestedAt,
  }) {
    return Student(
      id: id ?? this.id,
      trainerId: trainerId ?? this.trainerId,
      name: name ?? this.name,
      date: date ?? this.date,
      teacher: teacher ?? this.teacher,
      status: status ?? this.status,
      cpf: cpf ?? this.cpf,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      niche: niche ?? this.niche,
      prontuarioText: prontuarioText ?? this.prontuarioText,
      evolucao: evolucao ?? this.evolucao,
      gymName: gymName ?? this.gymName,
      month: month ?? this.month,
      instructorNotes: instructorNotes ?? this.instructorNotes,
      needsReassessment: needsReassessment ?? this.needsReassessment,
      anamnesePending: anamnesePending ?? this.anamnesePending,
      lastAnamneseDate: lastAnamneseDate ?? this.lastAnamneseDate,
      reassessmentRequestedAt:
          reassessmentRequestedAt ?? this.reassessmentRequestedAt,
    );
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      trainerId: json['trainer_id'] as String?,
      name: json['name'] as String? ?? 'Aluno Desconhecido',
      date: json['date'] as String? ?? '',
      teacher: json['teacher'] as String? ?? '',
      status: (json['status'] == 'archived' || json['status'] == 'arquivado')
          ? StudentStatus.archived
          : StudentStatus.active,
      cpf: json['cpf'] as String? ?? json['extra']?['cpf'] ?? '',
      phone: json['phone'] as String? ?? json['extra']?['telEmergencia'] ?? '',
      email: json['email'] as String? ?? json['extra']?['email'] ?? '',
      address: json['address'] as String? ?? json['extra']?['endereco'] ?? '',
      niche: json['niche'] as String? ?? json['extra']?['nicho'] ?? '',
      prontuarioText:
          json['prontuarioText'] as String? ?? json['prontuario_text'] ?? '',
      evolucao: json['evolucao'] as String? ?? '',
      gymName: json['gym_name'] as String? ?? json['academia'] as String? ?? '',
      month: json['month'] as String? ?? json['mes'] as String? ?? '',
      instructorNotes:
          json['instructorNotes'] as String? ?? json['instructor_notes'] ?? '',
      needsReassessment:
          json['needsReassessment'] as bool? ??
          json['needs_reassessment'] as bool? ??
          false,
      anamnesePending:
          json['anamnesePending'] as bool? ??
          json['anamnese_pending'] as bool? ??
          false,
      lastAnamneseDate:
          json['lastAnamneseDate'] as String? ??
          json['last_anamnese_date'] as String?,
      reassessmentRequestedAt:
          json['reassessmentRequestedAt'] as String? ??
          json['reassessment_requested_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date.isEmpty ? null : date,
      'teacher': teacher,
      'status': status == StudentStatus.archived ? 'archived' : 'active',
      'cpf': cpf,
      'phone': phone,
      'email': email,
      'address': address,
      'niche': niche,
      'prontuario_text': prontuarioText,
      'evolucao': evolucao,
      'academia': gymName,
      'mes': month,
      'instructor_notes': instructorNotes,
      'needs_reassessment': needsReassessment,
      'anamnese_pending': anamnesePending,
      'last_anamnese_date': lastAnamneseDate,
      'reassessment_requested_at': reassessmentRequestedAt,
    };
  }
}

class StudentFinancialSummary {
  final String planName;
  final String subscriptionStatus;
  final String nextDueDate;
  final double totalOpen;
  final double totalOverdue;
  final String lastPaymentDate;
  final FinancialBadge badge;

  StudentFinancialSummary({
    this.planName = 'Sem plano ativo',
    this.subscriptionStatus = 'Nenhum',
    this.nextDueDate = '-',
    this.totalOpen = 0.0,
    this.totalOverdue = 0.0,
    this.lastPaymentDate = '-',
    this.badge = FinancialBadge.noInvoice,
  });
}
