import 'dart:convert';
import '../models/exercise_library_item.dart';
import 'catalog_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_model.dart';
import '../models/workout_model.dart';
import '../config/supabase_config.dart';
import '../repositories/student_repository.dart';
import '../repositories/workout_repository.dart';
import '../repositories/preset_repository.dart';

export '../models/exercise_library_item.dart';

class StudentContextService extends ChangeNotifier {
  static final StudentContextService _instance =
      StudentContextService._internal();
  factory StudentContextService() => _instance;
  StudentContextService._internal()
    : _studentRepository = StudentRepository(),
      _workoutRepository = WorkoutRepository(),
      _presetRepository = PresetRepository(),
      _accountId = _defaultAccountId,
      _allowOfflineWrites = false,
      _initialStudents = const [],
      _isTestInstance = false;

  @visibleForTesting
  StudentContextService.forTesting({
    StudentRepository? studentRepository,
    WorkoutRepository? workoutRepository,
    PresetRepository? presetRepository,
    String Function()? accountId,
    bool allowOfflineWrites = false,
    List<Student> initialStudents = const [],
  }) : _studentRepository = studentRepository ?? StudentRepository(),
       _workoutRepository = workoutRepository ?? WorkoutRepository(),
       _presetRepository = presetRepository ?? PresetRepository(),
       _accountId = accountId ?? (() => 'test'),
       // ignore: prefer_initializing_formals
       _allowOfflineWrites = allowOfflineWrites,
       // ignore: prefer_initializing_formals
       _initialStudents = initialStudents,
       _isTestInstance = true {
    _resetInMemoryState(currentAccountId);
  }

  final StudentRepository _studentRepository;
  final WorkoutRepository _workoutRepository;
  final PresetRepository _presetRepository;
  final String Function() _accountId;
  final bool _allowOfflineWrites;
  final bool _isTestInstance;
  final List<Student> _initialStudents;
  bool get _canWrite =>
      _isTestInstance ||
      (SupabaseConfig.hasAuthenticatedUser &&
          _loadedAccountId == currentAccountId);

  void clearSessionMemory() {
    _resetInMemoryState('signed-out');
    _initialized = false;
    _loadedAccountId = null;
    _initFuture = null;
    _initAccount = null;
  }

  bool _initialized = false;
  String? _loadedAccountId;
  String? _activeStudentId;
  Future<void>? _initFuture;
  String? _initAccount;
  bool _isRefreshing = false;
  String? _remoteError;

  final Map<String, Student> _studentsMap = {};

  final Map<String, WorkoutSheet> _studentSheets = {};
  final Map<String, List<WorkoutSheet>> _versionHistory = {};
  final List<WorkoutSheet> _customPresets = [];
  final Map<String, SheetLoadState> _sheetStates = {};
  final Map<String, int> _sheetRevisions = {};

  bool get isInitialized => _initialized;
  String? get activeStudentId => _activeStudentId;

  /// Verdadeiro enquanto a lista de alunos é sincronizada com o servidor.
  bool get isRefreshing => _isRefreshing;

  /// Mensagem da última falha ao sincronizar alunos; nula após sucesso.
  String? get remoteError => _remoteError;

  /// Estado da ficha remota do aluno. Fichas sem consulta remota ficam prontas.
  SheetLoadState sheetState(String studentId) =>
      _sheetStates[studentId] ?? SheetLoadState.ready;

  /// Muda apenas quando a ficha é substituída pelo servidor, para que o
  /// editor não descarte o que está sendo digitado a cada autosave.
  int sheetRevision(String studentId) => _sheetRevisions[studentId] ?? 0;

  Student? get activeStudent {
    if (_activeStudentId == null) return null;
    return _studentsMap[_activeStudentId];
  }

  List<Student> get allStudents => _studentsMap.values.toList();
  List<WorkoutSheet> get customPresets => _customPresets;
  WorkoutSheet? cachedSheetForStudent(String studentId) =>
      _studentSheets[studentId]?.deepCopy();
  bool get isUsingRemoteData => SupabaseConfig.hasAuthenticatedUser;
  bool get _shouldUseRemote =>
      (_isTestInstance && !_allowOfflineWrites) ||
      (SupabaseConfig.isConfigured && SupabaseConfig.hasAuthenticatedUser);

  static String _defaultAccountId() {
    try {
      return SupabaseConfig.client.auth.currentUser?.id ?? 'signed-out';
    } catch (_) {
      return 'signed-out';
    }
  }

  String get currentAccountId {
    final account = _accountId().trim();
    return account.isEmpty ? 'signed-out' : account;
  }

  String _cacheKey(String base, [String? account]) {
    final scope = account ?? currentAccountId;
    return '${base}_$scope';
  }

  void _resetInMemoryState(String account) {
    _studentsMap.clear();
    _studentsMap.addEntries(
      _initialStudents.map((student) => MapEntry(student.id, student)),
    );
    _studentSheets.clear();
    _versionHistory.clear();
    _customPresets.clear();
    _sheetStates.clear();
    _sheetRevisions.clear();
    _isRefreshing = false;
    _remoteError = null;
    _activeStudentId = _initialStudents.firstOrNull?.id;
  }

  /// Carrega o cache do aparelho imediatamente e sincroniza com o servidor
  /// em seguida. Chamadas concorrentes reutilizam a mesma carga.
  Future<void> init() {
    final account = currentAccountId;
    if (_initialized && _loadedAccountId == account) return Future.value();
    final pending = _initFuture;
    if (pending != null && _initAccount == account) return pending;
    _initAccount = account;
    late final Future<void> future;
    future = _initInternal(account).whenComplete(() {
      if (identical(_initFuture, future)) _initFuture = null;
    });
    _initFuture = future;
    return future;
  }

  Future<void> _initInternal(String account) async {
    _resetInMemoryState(account);
    _loadedAccountId = account;
    if (!_canWrite) {
      _initialized = true;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (_loadedAccountId != account) return;
    _loadCache(prefs, account);
    _initialized = true;
    notifyListeners();

    if (_shouldUseRemote) {
      await _syncRemote(account);
      if (_loadedAccountId != account) return;
    }
    await persistToDisk();
    notifyListeners();
  }

  void _loadCache(SharedPreferences prefs, String account) {
    _activeStudentId =
        prefs.getString(_cacheKey('valex_active_student_id', account)) ??
        _initialStudents.firstOrNull?.id;

    final studentsRaw = prefs.getString(_cacheKey('valex_students', account));
    if (studentsRaw != null && studentsRaw.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(studentsRaw);
        final cachedStudents = decoded
            .map(
              (item) =>
                  Student.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
        if (cachedStudents.isNotEmpty) {
          _studentsMap
            ..clear()
            ..addEntries(
              cachedStudents.map((student) => MapEntry(student.id, student)),
            );
        }
      } catch (e) {
        debugPrint('Erro ao carregar alunos do disco: $e');
      }
    }

    final sheetsRaw = prefs.getString(
      _cacheKey('valex_student_sheets', account),
    );
    if (sheetsRaw != null && sheetsRaw.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(sheetsRaw);
        decoded.forEach((key, value) {
          _studentSheets[key] = WorkoutSheet.fromJson(
            Map<String, dynamic>.from(value),
          );
        });
      } catch (e) {
        debugPrint('Erro ao carregar sheets do disco: $e');
      }
    }

    final historyRaw = prefs.getString(
      _cacheKey('valex_version_history', account),
    );
    if (historyRaw != null && historyRaw.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(historyRaw);
        decoded.forEach((key, value) {
          _versionHistory[key] = (value as List)
              .map(
                (item) =>
                    WorkoutSheet.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList();
        });
      } catch (e) {
        debugPrint('Erro ao carregar historico do disco: $e');
      }
    }

    final presetsRaw = prefs.getString(
      _cacheKey('valex_custom_presets', account),
    );
    if (presetsRaw != null && presetsRaw.isNotEmpty) {
      try {
        final List decoded = jsonDecode(presetsRaw);
        _customPresets
          ..clear()
          ..addAll(
            decoded.map(
              (item) => WorkoutSheet.fromJson(Map<String, dynamic>.from(item)),
            ),
          );
      } catch (e) {
        debugPrint('Erro ao carregar presets do disco: $e');
      }
    }
  }

  /// Busca alunos e presets em paralelo e, em seguida, a ficha do aluno ativo.
  Future<bool> _syncRemote(String account) async {
    _isRefreshing = true;
    notifyListeners();
    var studentsOk = true;
    try {
      final results = await Future.wait<Object>([
        _studentRepository.fetchStudentsOrThrow(),
        _presetRepository.fetchPresets(),
      ]);
      if (_loadedAccountId != account) return false;
      final remoteStudents = results[0] as List<Student>;
      final remotePresets = results[1] as List<WorkoutSheet>;
      _studentsMap
        ..clear()
        ..addEntries(
          remoteStudents.map((student) => MapEntry(student.id, student)),
        );
      if (!_studentsMap.containsKey(_activeStudentId)) {
        _activeStudentId = remoteStudents.firstOrNull?.id;
      }
      if (remotePresets.isNotEmpty) {
        _customPresets
          ..clear()
          ..addAll(remotePresets);
      }
      _remoteError = null;
    } catch (e) {
      studentsOk = false;
      if (_loadedAccountId != account) return false;
      _remoteError =
          'Não foi possível atualizar a lista de alunos. Mostrando os dados '
          'salvos neste aparelho.';
      debugPrint('Falha ao sincronizar alunos: $e');
    } finally {
      if (_loadedAccountId == account) _isRefreshing = false;
    }
    notifyListeners();

    final active = _activeStudentId;
    if (active != null) await _loadRemoteSheet(active);
    return studentsOk;
  }

  /// Consulta a ficha e o histórico do aluno, registrando carga e falha.
  Future<void> _loadRemoteSheet(String studentId) async {
    final account = _loadedAccountId;
    _sheetStates[studentId] = SheetLoadState.loading;
    notifyListeners();
    final results = await Future.wait<Object>([
      _workoutRepository.fetchActiveSheetResult(studentId),
      _workoutRepository.fetchVersionHistory(studentId),
    ]);
    if (_loadedAccountId != account) return;
    final sheetResult = results[0] as ActiveWorkoutLoadResult;
    final versions = results[1] as List<WorkoutSheet>;
    switch (sheetResult.status) {
      case ActiveWorkoutLoadStatus.loaded:
        _studentSheets[studentId] = sheetResult.sheet!;
        _sheetRevisions[studentId] = sheetRevision(studentId) + 1;
        _sheetStates[studentId] = SheetLoadState.ready;
      case ActiveWorkoutLoadStatus.empty:
        _sheetStates[studentId] = SheetLoadState.ready;
      case ActiveWorkoutLoadStatus.error:
        _sheetStates[studentId] = SheetLoadState.failed;
    }
    if (versions.isNotEmpty) _versionHistory[studentId] = versions;
    await persistToDisk();
    notifyListeners();
  }

  /// Nova tentativa de carregar a ficha remota de um aluno.
  Future<void> retrySheet(String studentId) async {
    if (_shouldUseRemote) await _loadRemoteSheet(studentId);
  }

  /// Sincroniza a lista de alunos. Retorna falso quando o servidor falha;
  /// nesse caso os dados do aparelho continuam visíveis e [remoteError]
  /// explica o problema.
  Future<bool> refreshFromRemote() async {
    if (!_shouldUseRemote) return true;
    final account = currentAccountId;
    if (_loadedAccountId != account || !_initialized) {
      await init();
      return _remoteError == null;
    }
    final ok = await _syncRemote(account);
    await persistToDisk();
    notifyListeners();
    return ok;
  }

  void addStudent(Student student) {
    _studentsMap[student.id] = student;
    persistToDisk();
    notifyListeners();
  }

  void addOrUpdateStudent(Student student) {
    _studentsMap[student.id] = student;
    persistToDisk();
    notifyListeners();
  }

  Future<bool> saveStudent(Student student) async {
    if (!_canWrite) return false;
    final previous = _studentsMap[student.id];
    final previousActive = _activeStudentId;
    _studentsMap[student.id] = student;
    _activeStudentId ??= student.id;
    await persistToDisk();
    notifyListeners();

    final remoteSaved = _shouldUseRemote
        ? await _studentRepository.saveStudent(student)
        : false;
    final saved = remoteSaved || (_allowOfflineWrites && !_shouldUseRemote);
    if (!saved) {
      // Sem confirmação do servidor a lista volta ao estado anterior.
      if (previous == null) {
        _studentsMap.remove(student.id);
      } else {
        _studentsMap[student.id] = previous;
      }
      _activeStudentId = previousActive;
      await persistToDisk();
      notifyListeners();
    }
    return saved;
  }

  Future<bool> updateStudentStatus(
    String studentId,
    StudentStatus status,
  ) async {
    final student = _studentsMap[studentId];
    if (student == null) return false;

    _studentsMap[studentId] = student.copyWith(status: status);
    await persistToDisk();
    notifyListeners();

    final remoteSaved = _shouldUseRemote
        ? await _studentRepository.updateStudentStatus(
            studentId,
            status == StudentStatus.archived ? 'archived' : 'active',
          )
        : false;
    final saved = remoteSaved || (_allowOfflineWrites && !_shouldUseRemote);
    if (!saved) {
      _studentsMap[studentId] = student;
      await persistToDisk();
      notifyListeners();
    }
    return saved;
  }

  /// Marca a reavaliação 360° no servidor; o estado local só muda após a
  /// confirmação, para não indicar ao instrutor um pedido que não foi salvo.
  Future<bool> requestReassessment(String studentId) async {
    final student = _studentsMap[studentId];
    if (student == null) return false;
    final saved = _shouldUseRemote
        ? await _studentRepository.requestReassessment(studentId)
        : _allowOfflineWrites;
    if (!saved) return false;
    _studentsMap[studentId] = student.copyWith(
      needsReassessment: true,
      anamnesePending: true,
      reassessmentRequestedAt: DateTime.now().toIso8601String(),
    );
    await persistToDisk();
    notifyListeners();
    return true;
  }

  Future<void> replaceStudents(List<Student> students) async {
    _studentsMap
      ..clear()
      ..addEntries(students.map((student) => MapEntry(student.id, student)));
    if (_studentsMap.isNotEmpty &&
        !_studentsMap.containsKey(_activeStudentId)) {
      _activeStudentId = students.first.id;
    }
    await persistToDisk();
    notifyListeners();
  }

  Future<void> persistToDisk() async {
    if (!_canWrite) return;
    final prefs = await SharedPreferences.getInstance();
    final account = currentAccountId;
    if (_activeStudentId != null) {
      await prefs.setString(
        _cacheKey('valex_active_student_id', account),
        _activeStudentId!,
      );
    } else {
      await prefs.remove(_cacheKey('valex_active_student_id', account));
    }

    await prefs.setString(
      _cacheKey('valex_students', account),
      jsonEncode(
        _studentsMap.values.map((student) => student.toJson()).toList(),
      ),
    );

    final Map<String, dynamic> sheetsEncodable = {};
    _studentSheets.forEach(
      (key, value) => sheetsEncodable[key] = value.toJson(),
    );
    await prefs.setString(
      _cacheKey('valex_student_sheets', account),
      jsonEncode(sheetsEncodable),
    );

    final Map<String, dynamic> historyEncodable = {};
    _versionHistory.forEach(
      (key, value) =>
          historyEncodable[key] = value.map((v) => v.toJson()).toList(),
    );
    await prefs.setString(
      _cacheKey('valex_version_history', account),
      jsonEncode(historyEncodable),
    );

    final List presetsEncodable = _customPresets
        .map((p) => p.toJson())
        .toList();
    await prefs.setString(
      _cacheKey('valex_custom_presets', account),
      jsonEncode(presetsEncodable),
    );
  }

  Future<void> clearCurrentAccountCache() async {
    final prefs = await SharedPreferences.getInstance();
    final account = currentAccountId;
    for (final base in const [
      'valex_active_student_id',
      'valex_students',
      'valex_student_sheets',
      'valex_version_history',
      'valex_custom_presets',
    ]) {
      await prefs.remove(_cacheKey(base, account));
    }
    _resetInMemoryState(account);
    _initialized = false;
    _loadedAccountId = null;
    notifyListeners();
  }

  Future<void> setActiveStudent(String studentId) async {
    if (!_studentsMap.containsKey(studentId)) return;
    _activeStudentId = studentId;
    await persistToDisk();
    notifyListeners();
    // Busca a ficha atualizada; o editor aguarda esta carga antes de editar.
    if (_shouldUseRemote) await _loadRemoteSheet(studentId);
  }

  WorkoutSheet getActiveSheet() {
    final student = activeStudent;
    if (student == null) {
      return WorkoutSheet(
        studentId: '',
        studentName: '',
        gymName: '',
        month: '',
        teacher: '',
        cardioOptions: [],
        generalNotes: [],
      );
    }
    return _studentSheets.putIfAbsent(
      student.id,
      () => WorkoutSheet(
        studentId: student.id,
        studentName: student.name,
        gymName: student.gymName,
        month: student.month,
        teacher: '',
        cardioOptions: [],
        generalNotes: [],
      ),
    );
  }

  /// FLUXO 1: Salvar Ficha Ativa (Persiste no Supabase + Cache SharedPreferences se sucesso)
  Future<bool> saveActiveSheet(WorkoutSheet sheet) async {
    if (!_canWrite || sheet.studentId.isEmpty) return false;
    final sid = sheet.studentId.isNotEmpty
        ? sheet.studentId
        : (_activeStudentId ?? '');

    _studentSheets[sid] = sheet.deepCopy();
    await persistToDisk();
    notifyListeners();

    final success = _shouldUseRemote
        ? await _workoutRepository.saveActiveSheet(sheet)
        : false;

    if (success) {
      _studentSheets[sid] = sheet.deepCopy();
    }
    return success || (_allowOfflineWrites && !_shouldUseRemote);
  }

  /// FLUXO 2: Salvar Versão (Persiste no Supabase + Cache SharedPreferences se sucesso)
  Future<bool> saveVersionSnapshot(
    WorkoutSheet sheet,
    String versionName,
  ) async {
    final sid = sheet.studentId;
    final cleanVersionName = versionName.trim();
    if (cleanVersionName.isEmpty) return false;

    // Persistência Primária no Supabase
    final success = _shouldUseRemote
        ? await _workoutRepository.saveVersionSnapshot(
            sid,
            sheet,
            cleanVersionName,
          )
        : false;

    if (success || (_allowOfflineWrites && !_shouldUseRemote)) {
      if (!_versionHistory.containsKey(sid)) {
        _versionHistory[sid] = [];
      }
      final clone = sheet.deepCopy()..currentVersionName = cleanVersionName;

      _versionHistory[sid]!.insert(0, clone);
      await persistToDisk();
      notifyListeners();
    }
    return success || (_allowOfflineWrites && !_shouldUseRemote);
  }

  List<WorkoutSheet> getVersionHistory(String studentId) {
    return _versionHistory[studentId] ?? [];
  }

  /// FLUXO 3: Salvar Preset Customizado (Persiste no Supabase + Cache SharedPreferences se sucesso)
  Future<bool> saveCustomPreset(WorkoutSheet sheet, String presetTitle) async {
    final cleanTitle = presetTitle.trim();
    if (cleanTitle.isEmpty) return false;

    // Persistência Primária no Supabase
    final success = _shouldUseRemote
        ? await _presetRepository.savePreset(sheet, cleanTitle)
        : false;

    if (success || (_allowOfflineWrites && !_shouldUseRemote)) {
      final clone = sheet.deepCopy()
        ..studentId = 'preset_custom'
        ..studentName = cleanTitle;

      _customPresets.add(clone);
      await persistToDisk();
      notifyListeners();
    }
    return success || (_allowOfflineWrites && !_shouldUseRemote);
  }

  /// Exclui um preset customizado da memória e do disco
  Future<bool> deleteCustomPreset(String presetTitle) async {
    final cleanTitle = presetTitle.trim();
    if (cleanTitle.isEmpty) return false;

    // Sem exclusão remota o preset reaparecia no próximo carregamento.
    final remoteDeleted = _shouldUseRemote
        ? await _presetRepository.deletePreset(cleanTitle)
        : _allowOfflineWrites;
    if (!remoteDeleted) return false;

    _customPresets.removeWhere((p) => p.studentName == cleanTitle);
    await persistToDisk();
    notifyListeners();
    return true;
  }

  /// FLUXO 4: Salvar Anamnese / Prontuário (Persiste no Supabase + Cache SharedPreferences se sucesso)
  Future<bool> saveStudentRecord(
    String studentId,
    Map<String, dynamic> recordData,
  ) async {
    final success = _shouldUseRemote
        ? await _studentRepository.saveStudentRecord(studentId, recordData)
        : false;
    if (success || (_allowOfflineWrites && !_shouldUseRemote)) {
      if (_studentsMap.containsKey(studentId)) {
        if (recordData.containsKey('medical_notes')) {
          _studentsMap[studentId] = _studentsMap[studentId]!.copyWith(
            prontuarioText: recordData['medical_notes'].toString(),
          );
        }
      }
      await persistToDisk();
      notifyListeners();
    }
    return success || (_allowOfflineWrites && !_shouldUseRemote);
  }

  /// Solicita reavaliação 360° para o aluno
  void requestStudentReassessment(String studentId) {
    if (_studentsMap.containsKey(studentId)) {
      _studentsMap[studentId] = _studentsMap[studentId]!.copyWith(
        needsReassessment: true,
        anamnesePending: true,
        reassessmentRequestedAt: DateTime.now().toIso8601String(),
      );
      persistToDisk();
      notifyListeners();
    }
  }

  /// Conclui a Anamnese 360° do aluno
  void completeStudentAnamnese(String studentId) {
    if (_studentsMap.containsKey(studentId)) {
      _studentsMap[studentId] = _studentsMap[studentId]!.copyWith(
        needsReassessment: false,
        anamnesePending: false,
        lastAnamneseDate: DateTime.now().toIso8601String(),
      );
      persistToDisk();
      notifyListeners();
    }
  }

  // Catálogo offline em PT-BR; mantém os títulos e a ordem inicial do legado.
  static List<ExerciseLibraryItem> get exerciseLibrary =>
      CatalogService.instance.items;
}

enum SheetLoadState { loading, ready, failed }
