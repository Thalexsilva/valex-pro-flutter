enum ClinicalRiskLevel {
  low,
  moderate,
  high;

  String get label {
    switch (this) {
      case ClinicalRiskLevel.low:
        return 'Baixo Risco (Liberado)';
      case ClinicalRiskLevel.moderate:
        return 'Risco Moderado (Atenção Biomecânica)';
      case ClinicalRiskLevel.high:
        return 'Alto Risco (Exige Liberação Médica)';
    }
  }

  String get badgeEmoji {
    switch (this) {
      case ClinicalRiskLevel.low:
        return '🟢';
      case ClinicalRiskLevel.moderate:
        return '🟡';
      case ClinicalRiskLevel.high:
        return '🔴';
    }
  }
}

enum PostureAngle {
  front,
  back,
  sideRight,
  sideLeft;

  String get label {
    switch (this) {
      case PostureAngle.front:
        return 'Frente (Anterior)';
      case PostureAngle.back:
        return 'Costas (Posterior)';
      case PostureAngle.sideRight:
        return 'Lateral Direita';
      case PostureAngle.sideLeft:
        return 'Lateral Esquerda';
    }
  }

  String get guideTip {
    switch (this) {
      case PostureAngle.front:
        return 'Braços levemente afastados do tronco, pés na largura dos ombros e olhar fixo no horizonte.';
      case PostureAngle.back:
        return 'Cabelos presos (se compridos), postura natural sem forçar escápulas.';
      case PostureAngle.sideRight:
      case PostureAngle.sideLeft:
        return 'Perfil reto, braço sem cobrir a linha do quadril e da coluna.';
    }
  }
}

class PosturePhoto {
  final String id;
  final PostureAngle angle;
  final String url;
  final String? localPath;
  final String? fileName;
  final int fileSizeBytes;
  final DateTime capturedAt;
  final String? notes;

  PosturePhoto({
    required this.id,
    required this.angle,
    required this.url,
    this.localPath,
    this.fileName,
    this.fileSizeBytes = 0,
    DateTime? capturedAt,
    this.notes,
  }) : capturedAt = capturedAt ?? DateTime.now();

  factory PosturePhoto.fromJson(Map<String, dynamic> json) {
    return PosturePhoto(
      id:
          json['id'] as String? ??
          'photo_${DateTime.now().millisecondsSinceEpoch}',
      angle: PostureAngle.values.firstWhere(
        (a) => a.name == json['angle'],
        orElse: () => PostureAngle.front,
      ),
      url: json['url'] as String? ?? '',
      localPath: json['localPath'] as String? ?? json['local_path'] as String?,
      fileName: json['fileName'] as String? ?? json['file_name'] as String?,
      fileSizeBytes:
          (json['fileSizeBytes'] as num?)?.toInt() ??
          (json['file_size_bytes'] as num?)?.toInt() ??
          0,
      capturedAt: json['capturedAt'] != null
          ? DateTime.tryParse(json['capturedAt'] as String) ?? DateTime.now()
          : (json['captured_at'] != null
                ? DateTime.tryParse(json['captured_at'] as String) ??
                      DateTime.now()
                : DateTime.now()),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'angle': angle.name,
      'url': url,
      'local_path': localPath,
      'file_name': fileName,
      'file_size_bytes': fileSizeBytes,
      'captured_at': capturedAt.toIso8601String(),
      'notes': notes,
    };
  }

  PosturePhoto copyWith({
    String? id,
    PostureAngle? angle,
    String? url,
    String? localPath,
    String? fileName,
    int? fileSizeBytes,
    DateTime? capturedAt,
    String? notes,
  }) {
    return PosturePhoto(
      id: id ?? this.id,
      angle: angle ?? this.angle,
      url: url ?? this.url,
      localPath: localPath ?? this.localPath,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      capturedAt: capturedAt ?? this.capturedAt,
      notes: notes ?? this.notes,
    );
  }
}

class MedicalDocument {
  final String id;
  final String title;
  final String fileUrl;
  final String? localPath;
  final String fileType; // 'pdf', 'image', 'exam', 'bioimpedance', 'blood_test'
  final int sizeBytes;
  final DateTime uploadedAt;

  MedicalDocument({
    required this.id,
    required this.title,
    required this.fileUrl,
    this.localPath,
    required this.fileType,
    this.sizeBytes = 0,
    DateTime? uploadedAt,
  }) : uploadedAt = uploadedAt ?? DateTime.now();

  factory MedicalDocument.fromJson(Map<String, dynamic> json) {
    return MedicalDocument(
      id:
          json['id'] as String? ??
          'doc_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Documento',
      fileUrl: json['fileUrl'] as String? ?? json['file_url'] as String? ?? '',
      localPath: json['localPath'] as String? ?? json['local_path'] as String?,
      fileType:
          json['fileType'] as String? ?? json['file_type'] as String? ?? 'pdf',
      sizeBytes:
          (json['sizeBytes'] as num?)?.toInt() ??
          (json['size_bytes'] as num?)?.toInt() ??
          0,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'] as String) ?? DateTime.now()
          : (json['uploaded_at'] != null
                ? DateTime.tryParse(json['uploaded_at'] as String) ??
                      DateTime.now()
                : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'file_url': fileUrl,
      'local_path': localPath,
      'file_type': fileType,
      'size_bytes': sizeBytes,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}

class BioimpedanceData {
  final String? fileUrl;
  final String? fileName;
  final String? localPath;
  final int fileSizeBytes;
  final double? muscleMassKg;
  final double? fatMassKg;
  final double? bodyFatPercent;
  final double? basalMetabolicRateKcal;
  final int? visceralFatLevel;
  final double? totalBodyWaterLiters;
  final double? boneMassKg;
  final String? deviceModel; // ex: InBody, Tanita, Omron
  final DateTime? assessmentDate;

  BioimpedanceData({
    this.fileUrl,
    this.fileName,
    this.localPath,
    this.fileSizeBytes = 0,
    this.muscleMassKg,
    this.fatMassKg,
    this.bodyFatPercent,
    this.basalMetabolicRateKcal,
    this.visceralFatLevel,
    this.totalBodyWaterLiters,
    this.boneMassKg,
    this.deviceModel,
    this.assessmentDate,
  });

  bool get hasFile => fileUrl != null && fileUrl!.isNotEmpty;
  bool get hasMetrics =>
      muscleMassKg != null ||
      fatMassKg != null ||
      bodyFatPercent != null ||
      basalMetabolicRateKcal != null ||
      visceralFatLevel != null;

  factory BioimpedanceData.fromJson(Map<String, dynamic> json) {
    return BioimpedanceData(
      fileUrl: json['fileUrl'] as String? ?? json['file_url'] as String?,
      fileName: json['fileName'] as String? ?? json['file_name'] as String?,
      localPath: json['localPath'] as String? ?? json['local_path'] as String?,
      fileSizeBytes:
          (json['fileSizeBytes'] as num?)?.toInt() ??
          (json['file_size_bytes'] as num?)?.toInt() ??
          0,
      muscleMassKg:
          (json['muscleMassKg'] as num?)?.toDouble() ??
          (json['muscle_mass_kg'] as num?)?.toDouble(),
      fatMassKg:
          (json['fatMassKg'] as num?)?.toDouble() ??
          (json['fat_mass_kg'] as num?)?.toDouble(),
      bodyFatPercent:
          (json['bodyFatPercent'] as num?)?.toDouble() ??
          (json['body_fat_percent'] as num?)?.toDouble(),
      basalMetabolicRateKcal:
          (json['basalMetabolicRateKcal'] as num?)?.toDouble() ??
          (json['basal_metabolic_rate_kcal'] as num?)?.toDouble(),
      visceralFatLevel:
          (json['visceralFatLevel'] as num?)?.toInt() ??
          (json['visceral_fat_level'] as num?)?.toInt(),
      totalBodyWaterLiters:
          (json['totalBodyWaterLiters'] as num?)?.toDouble() ??
          (json['total_body_water_liters'] as num?)?.toDouble(),
      boneMassKg:
          (json['boneMassKg'] as num?)?.toDouble() ??
          (json['bone_mass_kg'] as num?)?.toDouble(),
      deviceModel:
          json['deviceModel'] as String? ?? json['device_model'] as String?,
      assessmentDate: json['assessmentDate'] != null
          ? DateTime.tryParse(json['assessmentDate'] as String)
          : (json['assessment_date'] != null
                ? DateTime.tryParse(json['assessment_date'] as String)
                : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'file_url': fileUrl,
      'file_name': fileName,
      'local_path': localPath,
      'file_size_bytes': fileSizeBytes,
      'muscle_mass_kg': muscleMassKg,
      'fat_mass_kg': fatMassKg,
      'body_fat_percent': bodyFatPercent,
      'basal_metabolic_rate_kcal': basalMetabolicRateKcal,
      'visceral_fat_level': visceralFatLevel,
      'total_body_water_liters': totalBodyWaterLiters,
      'bone_mass_kg': boneMassKg,
      'device_model': deviceModel,
      'assessment_date': assessmentDate?.toIso8601String(),
    };
  }

  BioimpedanceData copyWith({
    String? fileUrl,
    String? fileName,
    String? localPath,
    int? fileSizeBytes,
    double? muscleMassKg,
    double? fatMassKg,
    double? bodyFatPercent,
    double? basalMetabolicRateKcal,
    int? visceralFatLevel,
    double? totalBodyWaterLiters,
    double? boneMassKg,
    String? deviceModel,
    DateTime? assessmentDate,
  }) {
    return BioimpedanceData(
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      localPath: localPath ?? this.localPath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      muscleMassKg: muscleMassKg ?? this.muscleMassKg,
      fatMassKg: fatMassKg ?? this.fatMassKg,
      bodyFatPercent: bodyFatPercent ?? this.bodyFatPercent,
      basalMetabolicRateKcal:
          basalMetabolicRateKcal ?? this.basalMetabolicRateKcal,
      visceralFatLevel: visceralFatLevel ?? this.visceralFatLevel,
      totalBodyWaterLiters: totalBodyWaterLiters ?? this.totalBodyWaterLiters,
      boneMassKg: boneMassKg ?? this.boneMassKg,
      deviceModel: deviceModel ?? this.deviceModel,
      assessmentDate: assessmentDate ?? this.assessmentDate,
    );
  }
}

class AnamneseModel {
  final String id;
  final String studentId;
  final String? leadId;
  final String name;
  final String gender;
  final String birthDate;
  final int age;
  final String phone;
  final String email;
  final String cpf;
  final String address;

  // Antropometria & Metas
  final double weightKg;
  final double heightCm;
  final double? bodyFatPercent;
  final double? targetWeightKg;
  final String mainGoal;
  final String specificGoals;
  final String gymName;

  // Bioimpedância & Composição Corporal Dedicada
  final BioimpedanceData? bioimpedance;

  // Rotina & Treino
  final int trainingDaysPerWeek;
  final String sessionDuration;
  final String preferredShift;
  final String experienceLevel;
  final bool hasTrainedWithCoach;
  final String otherSports;

  // Biomecânica & Grupos Musculares
  final List<String> targetMuscles;
  final String bodyPerception;
  final String favoriteExercises;
  final String dislikedExercises;

  // Histórico Clínico & PAR-Q+
  final Map<String, bool> parqAnswers;
  final Map<String, String> parqDetails;
  final List<String> jointPains;
  final String movementPainDetails;
  final String medicalHistory;
  final String surgeries;
  final String medications;
  final String supplements;

  // Hábitos de Vida
  final double sleepHours;
  final double waterIntakeLiters;
  final int stressLevel; // 1 a 5
  final String dietHabit;
  final String alcoholHabit;
  final String smokingHabit;

  // Mídias & Documentos
  final List<PosturePhoto> posturePhotos;
  final List<MedicalDocument> documents;

  // Metadados & Auditoria
  final bool isDraft;
  final bool consentAccepted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String instructorNotes;

  AnamneseModel({
    required this.id,
    required this.studentId,
    this.leadId,
    required this.name,
    this.gender = 'Não informado',
    this.birthDate = '',
    this.age = 0,
    this.phone = '',
    this.email = '',
    this.cpf = '',
    this.address = '',
    this.weightKg = 0.0,
    this.heightCm = 0.0,
    this.bodyFatPercent,
    this.targetWeightKg,
    this.mainGoal = 'Hipertrofia',
    this.specificGoals = '',
    this.gymName = '',
    this.bioimpedance,
    this.trainingDaysPerWeek = 4,
    this.sessionDuration = '45 a 60 minutos',
    this.preferredShift = 'Manhã',
    this.experienceLevel = 'Intermediário',
    this.hasTrainedWithCoach = false,
    this.otherSports = '',
    this.targetMuscles = const [],
    this.bodyPerception = '',
    this.favoriteExercises = '',
    this.dislikedExercises = '',
    this.parqAnswers = const {},
    this.parqDetails = const {},
    this.jointPains = const [],
    this.movementPainDetails = '',
    this.medicalHistory = '',
    this.surgeries = '',
    this.medications = '',
    this.supplements = '',
    this.sleepHours = 7.0,
    this.waterIntakeLiters = 2.5,
    this.stressLevel = 3,
    this.dietHabit = '',
    this.alcoholHabit = 'Não',
    this.smokingHabit = 'Não',
    this.posturePhotos = const [],
    this.documents = const [],
    this.isDraft = false,
    this.consentAccepted = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.instructorNotes = '',
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Cálculo automático de Índice de Massa Corporal (IMC)
  double get bmi {
    if (heightCm <= 0 || weightKg <= 0) return 0.0;
    final heightM = heightCm / 100.0;
    return double.parse((weightKg / (heightM * heightM)).toStringAsFixed(1));
  }

  /// Classificação do IMC conforme padrão da OMS
  String get bmiClassification {
    final value = bmi;
    if (value <= 0) return 'Não calculado';
    if (value < 18.5) return 'Abaixo do peso';
    if (value < 25.0) return 'Peso normal';
    if (value < 30.0) return 'Sobrepeso';
    if (value < 35.0) return 'Obesidade Grau I';
    if (value < 40.0) return 'Obesidade Grau II';
    return 'Obesidade Grau III (Mórbida)';
  }

  /// Estratificação de Risco Clínico baseada no PAR-Q+ e Dores Articulares
  ClinicalRiskLevel get clinicalRisk {
    // 1. Verifica perguntas cardiovasculares críticas do PAR-Q+
    final cardiacRiskKeys = [
      'parq_cardiac_problem',
      'parq_chest_pain_activity',
      'parq_chest_pain_rest',
      'parq_dizziness_consciousness',
      'parq_blood_pressure_meds',
    ];

    for (final key in cardiacRiskKeys) {
      if (parqAnswers[key] == true) {
        return ClinicalRiskLevel.high;
      }
    }

    // 2. Verifica dores articulares ativas ou limitações ortopédicas
    if (jointPains.isNotEmpty ||
        movementPainDetails.trim().isNotEmpty ||
        parqAnswers['parq_bone_joint_problem'] == true ||
        parqAnswers['parq_other_reason'] == true) {
      return ClinicalRiskLevel.moderate;
    }

    return ClinicalRiskLevel.low;
  }

  /// Converte as respostas em texto estruturado de prontuário clínico para o perfil do aluno
  String toProntuarioSummary() {
    final buffer = StringBuffer();
    buffer.writeln('📋 AVALIAÇÃO DE ANAMNESE 360° — VALEX');
    buffer.writeln(
      '• Data de Preenchimento: ${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}',
    );
    buffer.writeln(
      '• Estratificação de Risco: ${clinicalRisk.badgeEmoji} ${clinicalRisk.label}',
    );
    buffer.writeln(
      '• Biometria: $weightKg kg | $heightCm cm | IMC: $bmi ($bmiClassification)',
    );

    // Bioimpedância & Composição
    final bf = bioimpedance?.bodyFatPercent ?? bodyFatPercent;
    if (bf != null && bf > 0) {
      buffer.writeln(
        '• Gordura Corporal: ${bf.toStringAsFixed(1)}% | Peso Alvo: ${targetWeightKg ?? "-"} kg',
      );
    }
    if (bioimpedance != null && bioimpedance!.hasMetrics) {
      if (bioimpedance!.muscleMassKg != null) {
        buffer.writeln(
          '• Massa Muscular Esquelética: ${bioimpedance!.muscleMassKg} kg',
        );
      }
      if (bioimpedance!.basalMetabolicRateKcal != null) {
        buffer.writeln(
          '• Taxa Metabólica Basal (TMB): ${bioimpedance!.basalMetabolicRateKcal!.toStringAsFixed(0)} kcal',
        );
      }
      if (bioimpedance!.visceralFatLevel != null) {
        buffer.writeln(
          '• Gordura Visceral: Nível ${bioimpedance!.visceralFatLevel}',
        );
      }
    }
    if (bioimpedance != null && bioimpedance!.hasFile) {
      buffer.writeln(
        '📎 Laudo de Bioimpedância Anexado: ${bioimpedance!.fileName ?? "Arquivo disponível no cofre"}',
      );
    }

    buffer.writeln('• Objetivo Principal: $mainGoal');
    if (specificGoals.trim().isNotEmpty) {
      buffer.writeln('• Metas Específicas: $specificGoals');
    }
    buffer.writeln(
      '• Rotina: $trainingDaysPerWeek dias/sem | $sessionDuration | Academia: ${gymName.isNotEmpty ? gymName : "Não informada"}',
    );
    buffer.writeln(
      '• Experiência: $experienceLevel (Acompanhamento anterior: ${hasTrainedWithCoach ? "Sim" : "Não"})',
    );

    if (targetMuscles.isNotEmpty) {
      buffer.writeln('• Foco Muscular: ${targetMuscles.join(", ")}');
    }

    // Alertas de Saúde & Dores
    if (jointPains.isNotEmpty) {
      buffer.writeln('⚠️ DORES / RESTRIÇÕES: ${jointPains.join(", ")}');
    }
    if (movementPainDetails.trim().isNotEmpty) {
      buffer.writeln(
        '⚠️ Exercícios/Movimentos com Desconforto: $movementPainDetails',
      );
    }
    if (medicalHistory.trim().isNotEmpty) {
      buffer.writeln('• Histórico de Doenças/Patologias: $medicalHistory');
    }
    if (surgeries.trim().isNotEmpty) {
      buffer.writeln('• Cirurgias: $surgeries');
    }
    if (medications.trim().isNotEmpty) {
      buffer.writeln('• Medicamentos em uso: $medications');
    }
    if (supplements.trim().isNotEmpty) {
      buffer.writeln('• Suplementos: $supplements');
    }

    // Hábitos
    buffer.writeln(
      '• Hábitos: Sono ${sleepHours}h/noite | Água ${waterIntakeLiters}L/dia | Estresse nível $stressLevel/5',
    );
    if (dietHabit.trim().isNotEmpty) {
      buffer.writeln('• Alimentação: $dietHabit');
    }

    // Preferências
    if (favoriteExercises.trim().isNotEmpty) {
      buffer.writeln('• Exercícios Favoritos: $favoriteExercises');
    }
    if (dislikedExercises.trim().isNotEmpty) {
      buffer.writeln('• Exercícios Rejeitados/Evitar: $dislikedExercises');
    }

    if (posturePhotos.isNotEmpty) {
      buffer.writeln(
        '📷 Fotos Posturais Anexadas: ${posturePhotos.length} fotos disponíveis no cofre.',
      );
    }
    if (documents.isNotEmpty) {
      buffer.writeln(
        '📄 Documentos/Exames Anexados: ${documents.length} arquivos.',
      );
    }

    return buffer.toString();
  }

  /// Gera notas automáticas de prescrição para o instrutor
  String toInstructorNotes() {
    final notes = <String>[];
    if (clinicalRisk == ClinicalRiskLevel.high) {
      notes.add(
        'ALERTA: Aluno com resposta positiva no PAR-Q+. Exigir liberação médica.',
      );
    }
    if (jointPains.isNotEmpty) {
      notes.add(
        'CUIDADO BIOMECÂNICO: Aluno relata dores em: ${jointPains.join(", ")}. Adequar amplitude e evitar compressão articular excessiva.',
      );
    }
    if (dislikedExercises.trim().isNotEmpty) {
      notes.add('PREFERÊNCIA: Evitar $dislikedExercises.');
    }
    if (targetMuscles.isNotEmpty) {
      notes.add(
        'PRIORIDADE: Volume semanal aumentado para: ${targetMuscles.join(", ")}.',
      );
    }
    if (bioimpedance != null && bioimpedance!.bodyFatPercent != null) {
      notes.add(
        'BIOIMPEDÂNCIA: BF ${bioimpedance!.bodyFatPercent}% | Massa Magra ${bioimpedance!.muscleMassKg ?? "-"}kg.',
      );
    }
    return notes.join('\n');
  }

  factory AnamneseModel.fromJson(Map<String, dynamic> json) {
    return AnamneseModel(
      id:
          json['id'] as String? ??
          'an_${DateTime.now().millisecondsSinceEpoch}',
      studentId:
          json['studentId'] as String? ?? json['student_id'] as String? ?? '',
      leadId: json['leadId'] as String? ?? json['lead_id'] as String?,
      name: json['name'] as String? ?? '',
      gender: json['gender'] as String? ?? 'Não informado',
      birthDate:
          json['birthDate'] as String? ?? json['birth_date'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      cpf: json['cpf'] as String? ?? '',
      address: json['address'] as String? ?? '',
      weightKg:
          (json['weightKg'] as num?)?.toDouble() ??
          (json['weight_kg'] as num?)?.toDouble() ??
          0.0,
      heightCm:
          (json['heightCm'] as num?)?.toDouble() ??
          (json['height_cm'] as num?)?.toDouble() ??
          0.0,
      bodyFatPercent:
          (json['bodyFatPercent'] as num?)?.toDouble() ??
          (json['body_fat_percent'] as num?)?.toDouble(),
      targetWeightKg:
          (json['targetWeightKg'] as num?)?.toDouble() ??
          (json['target_weight_kg'] as num?)?.toDouble(),
      mainGoal:
          json['mainGoal'] as String? ??
          json['main_goal'] as String? ??
          'Hipertrofia',
      specificGoals:
          json['specificGoals'] as String? ??
          json['specific_goals'] as String? ??
          '',
      gymName: json['gymName'] as String? ?? json['gym_name'] as String? ?? '',
      bioimpedance: json['bioimpedance'] != null
          ? BioimpedanceData.fromJson(
              json['bioimpedance'] as Map<String, dynamic>,
            )
          : null,
      trainingDaysPerWeek:
          (json['trainingDaysPerWeek'] as num?)?.toInt() ??
          (json['training_days_per_week'] as num?)?.toInt() ??
          4,
      sessionDuration:
          json['sessionDuration'] as String? ??
          json['session_duration'] as String? ??
          '45 a 60 minutos',
      preferredShift:
          json['preferredShift'] as String? ??
          json['preferred_shift'] as String? ??
          'Manhã',
      experienceLevel:
          json['experienceLevel'] as String? ??
          json['experience_level'] as String? ??
          'Intermediário',
      hasTrainedWithCoach:
          json['hasTrainedWithCoach'] as bool? ??
          json['has_trained_with_coach'] as bool? ??
          false,
      otherSports:
          json['otherSports'] as String? ??
          json['other_sports'] as String? ??
          '',
      targetMuscles:
          (json['targetMuscles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (json['target_muscles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      bodyPerception:
          json['bodyPerception'] as String? ??
          json['body_perception'] as String? ??
          '',
      favoriteExercises:
          json['favoriteExercises'] as String? ??
          json['favorite_exercises'] as String? ??
          '',
      dislikedExercises:
          json['dislikedExercises'] as String? ??
          json['disliked_exercises'] as String? ??
          '',
      parqAnswers:
          (json['parqAnswers'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v == true),
          ) ??
          (json['parq_answers'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v == true),
          ) ??
          const {},
      parqDetails:
          (json['parqDetails'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          (json['parq_details'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          const {},
      jointPains:
          (json['jointPains'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (json['joint_pains'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      movementPainDetails:
          json['movementPainDetails'] as String? ??
          json['movement_pain_details'] as String? ??
          '',
      medicalHistory:
          json['medicalHistory'] as String? ??
          json['medical_history'] as String? ??
          '',
      surgeries: json['surgeries'] as String? ?? '',
      medications: json['medications'] as String? ?? '',
      supplements: json['supplements'] as String? ?? '',
      sleepHours:
          (json['sleepHours'] as num?)?.toDouble() ??
          (json['sleep_hours'] as num?)?.toDouble() ??
          7.0,
      waterIntakeLiters:
          (json['waterIntakeLiters'] as num?)?.toDouble() ??
          (json['water_intake_liters'] as num?)?.toDouble() ??
          2.5,
      stressLevel:
          (json['stressLevel'] as num?)?.toInt() ??
          (json['stress_level'] as num?)?.toInt() ??
          3,
      dietHabit:
          json['dietHabit'] as String? ?? json['diet_habit'] as String? ?? '',
      alcoholHabit:
          json['alcoholHabit'] as String? ??
          json['alcohol_habit'] as String? ??
          'Não',
      smokingHabit:
          json['smokingHabit'] as String? ??
          json['smoking_habit'] as String? ??
          'Não',
      posturePhotos:
          (json['posturePhotos'] as List<dynamic>?)
              ?.map((e) => PosturePhoto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['posture_photos'] as List<dynamic>?)
              ?.map((e) => PosturePhoto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      documents:
          (json['documents'] as List<dynamic>?)
              ?.map((e) => MedicalDocument.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isDraft: json['isDraft'] as bool? ?? json['is_draft'] as bool? ?? false,
      consentAccepted:
          json['consentAccepted'] as bool? ??
          json['consent_accepted'] as bool? ??
          true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : (json['created_at'] != null
                ? DateTime.tryParse(json['created_at'] as String) ??
                      DateTime.now()
                : DateTime.now()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : (json['updated_at'] != null
                ? DateTime.tryParse(json['updated_at'] as String) ??
                      DateTime.now()
                : DateTime.now()),
      instructorNotes:
          json['instructorNotes'] as String? ??
          json['instructor_notes'] as String? ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'lead_id': leadId,
      'name': name,
      'gender': gender,
      'birth_date': birthDate,
      'age': age,
      'phone': phone,
      'email': email,
      'cpf': cpf,
      'address': address,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'bmi': bmi,
      'body_fat_percent': bodyFatPercent,
      'target_weight_kg': targetWeightKg,
      'main_goal': mainGoal,
      'specific_goals': specificGoals,
      'gym_name': gymName,
      'bioimpedance': bioimpedance?.toJson(),
      'training_days_per_week': trainingDaysPerWeek,
      'session_duration': sessionDuration,
      'preferred_shift': preferredShift,
      'experience_level': experienceLevel,
      'has_trained_with_coach': hasTrainedWithCoach,
      'other_sports': otherSports,
      'target_muscles': targetMuscles,
      'body_perception': bodyPerception,
      'favorite_exercises': favoriteExercises,
      'disliked_exercises': dislikedExercises,
      'parq_answers': parqAnswers,
      'parq_details': parqDetails,
      'joint_pains': jointPains,
      'movement_pain_details': movementPainDetails,
      'medical_history': medicalHistory,
      'surgeries': surgeries,
      'medications': medications,
      'supplements': supplements,
      'sleep_hours': sleepHours,
      'water_intake_liters': waterIntakeLiters,
      'stress_level': stressLevel,
      'diet_habit': dietHabit,
      'alcohol_habit': alcoholHabit,
      'smoking_habit': smokingHabit,
      'risk_level': clinicalRisk.name,
      'posture_photos': posturePhotos.map((p) => p.toJson()).toList(),
      'documents': documents.map((d) => d.toJson()).toList(),
      'is_draft': isDraft,
      'consent_accepted': consentAccepted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'instructor_notes': instructorNotes.isNotEmpty
          ? instructorNotes
          : toInstructorNotes(),
      'prontuario_text': toProntuarioSummary(),
    };
  }

  AnamneseModel copyWith({
    String? id,
    String? studentId,
    String? leadId,
    String? name,
    String? gender,
    String? birthDate,
    int? age,
    String? phone,
    String? email,
    String? cpf,
    String? address,
    double? weightKg,
    double? heightCm,
    double? bodyFatPercent,
    double? targetWeightKg,
    String? mainGoal,
    String? specificGoals,
    String? gymName,
    BioimpedanceData? bioimpedance,
    int? trainingDaysPerWeek,
    String? sessionDuration,
    String? preferredShift,
    String? experienceLevel,
    bool? hasTrainedWithCoach,
    String? otherSports,
    List<String>? targetMuscles,
    String? bodyPerception,
    String? favoriteExercises,
    String? dislikedExercises,
    Map<String, bool>? parqAnswers,
    Map<String, String>? parqDetails,
    List<String>? jointPains,
    String? movementPainDetails,
    String? medicalHistory,
    String? surgeries,
    String? medications,
    String? supplements,
    double? sleepHours,
    double? waterIntakeLiters,
    int? stressLevel,
    String? dietHabit,
    String? alcoholHabit,
    String? smokingHabit,
    List<PosturePhoto>? posturePhotos,
    List<MedicalDocument>? documents,
    bool? isDraft,
    bool? consentAccepted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? instructorNotes,
  }) {
    return AnamneseModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      leadId: leadId ?? this.leadId,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      age: age ?? this.age,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      cpf: cpf ?? this.cpf,
      address: address ?? this.address,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      bodyFatPercent: bodyFatPercent ?? this.bodyFatPercent,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      mainGoal: mainGoal ?? this.mainGoal,
      specificGoals: specificGoals ?? this.specificGoals,
      gymName: gymName ?? this.gymName,
      bioimpedance: bioimpedance ?? this.bioimpedance,
      trainingDaysPerWeek: trainingDaysPerWeek ?? this.trainingDaysPerWeek,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      preferredShift: preferredShift ?? this.preferredShift,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      hasTrainedWithCoach: hasTrainedWithCoach ?? this.hasTrainedWithCoach,
      otherSports: otherSports ?? this.otherSports,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      bodyPerception: bodyPerception ?? this.bodyPerception,
      favoriteExercises: favoriteExercises ?? this.favoriteExercises,
      dislikedExercises: dislikedExercises ?? this.dislikedExercises,
      parqAnswers: parqAnswers ?? this.parqAnswers,
      parqDetails: parqDetails ?? this.parqDetails,
      jointPains: jointPains ?? this.jointPains,
      movementPainDetails: movementPainDetails ?? this.movementPainDetails,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      surgeries: surgeries ?? this.surgeries,
      medications: medications ?? this.medications,
      supplements: supplements ?? this.supplements,
      sleepHours: sleepHours ?? this.sleepHours,
      waterIntakeLiters: waterIntakeLiters ?? this.waterIntakeLiters,
      stressLevel: stressLevel ?? this.stressLevel,
      dietHabit: dietHabit ?? this.dietHabit,
      alcoholHabit: alcoholHabit ?? this.alcoholHabit,
      smokingHabit: smokingHabit ?? this.smokingHabit,
      posturePhotos: posturePhotos ?? this.posturePhotos,
      documents: documents ?? this.documents,
      isDraft: isDraft ?? this.isDraft,
      consentAccepted: consentAccepted ?? this.consentAccepted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      instructorNotes: instructorNotes ?? this.instructorNotes,
    );
  }
}
