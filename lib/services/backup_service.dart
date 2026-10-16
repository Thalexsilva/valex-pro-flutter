import 'dart:convert';
import '../config/supabase_config.dart';
import '../models/finance_models.dart';
import '../models/sales_model.dart';
import '../models/student_model.dart';
import '../models/workout_model.dart';
import '../repositories/finance_repository.dart';
import '../repositories/anamnese_repository.dart';
import '../repositories/marketing_repository.dart';
import '../repositories/preset_repository.dart';
import '../repositories/sales_repository.dart';
import '../repositories/student_repository.dart';
import '../repositories/workout_repository.dart';
import 'student_context_service.dart';

class BackupDiagnostics {
  final int schemaVersion;
  final int totalStudents;
  final int totalWorkouts;
  final int totalPresets;
  final int totalLeads;
  final int totalInvoices;
  final bool isSupabaseConfigured;
  final bool hasAuthenticatedUser;
  final String? userEmail;
  final String appVersion;
  final String cacheIntegrity;

  BackupDiagnostics({
    required this.schemaVersion,
    required this.totalStudents,
    required this.totalWorkouts,
    required this.totalPresets,
    required this.totalLeads,
    required this.totalInvoices,
    required this.isSupabaseConfigured,
    required this.hasAuthenticatedUser,
    this.userEmail,
    this.appVersion = '1.0.0+1',
    this.cacheIntegrity = 'Não verificada',
  });
}

class BackupService {
  final StudentContextService _studentContext;
  final StudentRepository _studentRepository = StudentRepository();
  final WorkoutRepository _workoutRepository = WorkoutRepository();
  final PresetRepository _presetRepository = PresetRepository();
  final SalesRepository _salesRepository;
  BackupService({
    SalesRepository? salesRepository,
    StudentContextService? studentContext,
  }) : _salesRepository = salesRepository ?? SalesRepository(),
       _studentContext = studentContext ?? StudentContextService();
  final FinanceRepository _financeRepository = FinanceRepository();
  final AnamneseRepository _anamneseRepository = AnamneseRepository();
  final MarketingRepository _marketingRepository = MarketingRepository();

  /// Exporta o banco de dados completo em formato JSON padronizado v3
  Future<String> exportFullBackup() async {
    await _studentContext.init();
    final students = _studentContext.allStudents.isNotEmpty
        ? _studentContext.allStudents
        : await _studentRepository.fetchStudents();
    final presets = _studentContext.customPresets.isNotEmpty
        ? _studentContext.customPresets
        : await _presetRepository.fetchPresets();
    final leads = await _salesRepository.fetchLeads();
    final financeState = await _financeRepository.loadState();

    // Carrega fichas associadas aos alunos
    final workoutsMap = <String, dynamic>{};
    for (final s in students) {
      final sheet =
          _studentContext.cachedSheetForStudent(s.id) ??
          await _workoutRepository.fetchActiveSheet(s.id);
      if (sheet != null) {
        workoutsMap[s.id] = sheet.toJson();
      }
    }

    final backupData = {
      'valex_backup_version': 3,
      'schemaVersion': 3,
      'exported_at': DateTime.now().toIso8601String(),
      'platform': 'Valex Flutter Architecture v3',
      'data': {
        'students': students.map((s) => s.toJson()).toList(),
        'workouts': workoutsMap,
        'presets': presets.map((p) => p.toJson()).toList(),
        'leads': leads.map((l) => l.toJson()).toList(),
        'finance': financeState.toJson(),
      },
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(backupData);
  }

  /// Valida e importa um backup JSON completo
  Future<Map<String, dynamic>> importFullBackup(String jsonContent) async {
    try {
      if (jsonContent.trim().isEmpty) {
        return {'success': false, 'message': 'Arquivo de backup vazio.'};
      }

      final dynamic decoded = jsonDecode(jsonContent);
      if (decoded is! Map<String, dynamic>) {
        return {'success': false, 'message': 'Estrutura JSON inválida.'};
      }

      // Validação de Schema
      final version =
          decoded['valex_backup_version'] ?? decoded['schemaVersion'];
      if (version == null) {
        return {
          'success': false,
          'message': 'Arquivo incompatível: versão de schema ausente.',
        };
      }
      if (version != 3) {
        return {
          'success': false,
          'message': 'Versão de backup não suportada. Use o schema 3.',
        };
      }

      final data = decoded['data'] is Map<String, dynamic>
          ? decoded['data'] as Map<String, dynamic>
          : decoded;

      int restoredStudents = 0;
      int restoredWorkouts = 0;
      int restoredPresets = 0;
      int restoredLeads = 0;

      await _studentContext.init();

      // 1. Restaura Alunos
      if (data['students'] is List) {
        final studentsList = data['students'] as List;
        for (final item in studentsList) {
          if (item is Map<String, dynamic>) {
            final student = Student.fromJson(item);
            if (!await _studentContext.saveStudent(student)) {
              throw StateError(
                'Falha ao restaurar aluno. Restauração parcial.',
              );
            }
            restoredStudents++;
          }
        }
      }

      // 2. Restaura Fichas de Treino
      if (data['workouts'] is Map) {
        final workoutsMap = data['workouts'] as Map;
        for (final entry in workoutsMap.entries) {
          if (entry.value is Map<String, dynamic>) {
            final sheet = WorkoutSheet.fromJson(
              Map<String, dynamic>.from(entry.value as Map),
            );
            if (sheet.studentId != entry.key) {
              throw FormatException(
                'Identidade da ficha difere do aluno no backup.',
              );
            }
            if (!await _studentContext.saveActiveSheet(sheet)) {
              throw StateError(
                'Falha ao restaurar ficha. Restauração parcial.',
              );
            }
            restoredWorkouts++;
          }
        }
      }

      // 3. Restaura Presets
      if (data['presets'] is List) {
        final presetsList = data['presets'] as List;
        for (final item in presetsList) {
          if (item is Map<String, dynamic>) {
            final preset = WorkoutSheet.fromJson(item);
            final title =
                item['studentName']?.toString() ??
                item['preset_title']?.toString() ??
                'Preset';
            if (!await _studentContext.saveCustomPreset(preset, title)) {
              throw StateError(
                'Falha ao restaurar preset. Restauração parcial.',
              );
            }
            restoredPresets++;
          }
        }
      }

      // 4. Restaura Leads do CRM
      if (data['leads'] is List) {
        final leadsList = data['leads'] as List;
        for (final item in leadsList) {
          if (item is Map<String, dynamic>) {
            final lead = LeadItem.fromJson(item);
            if (!await _salesRepository.saveLead(lead)) {
              throw StateError('Falha ao restaurar lead. Restauração parcial.');
            }
            restoredLeads++;
          }
        }
      }

      // 5. Restaura Financeiro
      if (data['finance'] is Map<String, dynamic>) {
        final financeState = FinanceState.fromJson(
          data['finance'] as Map<String, dynamic>,
        );
        if (!await _financeRepository.saveState(financeState)) {
          throw StateError(
            'Falha ao restaurar financeiro. Restauração parcial.',
          );
        }
      }

      return {
        'success': true,
        'message': 'Backup restaurado com sucesso!',
        'details': {
          'students': restoredStudents,
          'workouts': restoredWorkouts,
          'presets': restoredPresets,
          'leads': restoredLeads,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Falha na restauração do backup: $e',
      };
    }
  }

  /// Limpeza destrutiva do banco local (Reset total)
  Future<bool> resetDatabase() async {
    try {
      await _studentContext.clearCurrentAccountCache();
      await _financeRepository.clearCurrentAccountCache();
      await _anamneseRepository.clearCurrentAccountCache();
      await _marketingRepository.clearCurrentAccountCache();
      await _salesRepository.clearLocalCache();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Coleta informações de diagnóstico em tempo real
  Future<BackupDiagnostics> getDiagnostics() async {
    await _studentContext.init();
    final students = _studentContext.allStudents.isNotEmpty
        ? _studentContext.allStudents
        : await _studentRepository.fetchStudents();
    final presets = _studentContext.customPresets.isNotEmpty
        ? _studentContext.customPresets
        : await _presetRepository.fetchPresets();
    final leads = await _salesRepository.fetchLeads();
    final financeState = await _financeRepository.loadState();

    String? email;
    bool hasAuth = false;
    try {
      hasAuth = SupabaseConfig.hasAuthenticatedUser;
      if (hasAuth) {
        email = SupabaseConfig.client.auth.currentUser?.email;
      }
    } catch (_) {}

    return BackupDiagnostics(
      schemaVersion: 3,
      totalStudents: students.length,
      totalWorkouts: students.length,
      totalPresets: presets.length,
      totalLeads: leads.length,
      totalInvoices: financeState.invoices.length,
      isSupabaseConfigured: SupabaseConfig.isConfigured,
      hasAuthenticatedUser: hasAuth,
      userEmail: email,
    );
  }
}
