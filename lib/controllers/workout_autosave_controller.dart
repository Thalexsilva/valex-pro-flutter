import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/workout_model.dart';
import '../services/student_context_service.dart';

enum AutosaveStatus { idle, dirty, saving, saved, error }

class WorkoutAutosaveController extends ChangeNotifier {
  final StudentContextService contextService;
  final Duration debounceDuration;

  AutosaveStatus _status = AutosaveStatus.idle;
  AutosaveStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Timer? _debounceTimer;
  Timer? _resetTimer;
  WorkoutSheet? _pendingSheet;
  WorkoutSheet? get pendingSheet => _pendingSheet;
  bool _isSaving = false;
  bool get isSaving => _isSaving;
  bool get isDirty =>
      _status == AutosaveStatus.dirty || (_pendingSheet != null && !_isSaving);
  Completer<bool>? _activeSaveCompleter;

  WorkoutAutosaveController({
    required this.contextService,
    this.debounceDuration = const Duration(milliseconds: 500),
  });

  /// Digitação contínua em campos de texto (debounce 500ms)
  void markDirty(WorkoutSheet sheet) {
    _pendingSheet = sheet.deepCopy();
    _setStatus(AutosaveStatus.dirty);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      _triggerSave();
    });
  }

  /// Operações estruturais (adicionar/remover/duplicar dia/exercício, etc.)
  Future<bool> saveNow(WorkoutSheet sheet) async {
    _debounceTimer?.cancel();
    _pendingSheet = sheet.deepCopy();
    return await _triggerSave();
  }

  /// Dispara salvamento serializado sem concorrência
  Future<bool> _triggerSave() async {
    if (_isSaving) {
      _activeSaveCompleter ??= Completer<bool>();
      return _activeSaveCompleter!.future;
    }

    if (_pendingSheet == null) return true;

    _isSaving = true;
    _setStatus(AutosaveStatus.saving);

    final snapshotToSave = _pendingSheet!.deepCopy();
    _pendingSheet = null;

    try {
      final success = await contextService.saveActiveSheet(snapshotToSave);

      if (success) {
        _errorMessage = null;
        if (_pendingSheet != null) {
          _isSaving = false;
          final nextCompleter = _activeSaveCompleter;
          _activeSaveCompleter = null;
          final res = await _triggerSave();
          nextCompleter?.complete(res);
          return res;
        } else {
          _setStatus(AutosaveStatus.saved);
          _isSaving = false;
          final nextCompleter = _activeSaveCompleter;
          _activeSaveCompleter = null;
          nextCompleter?.complete(true);
          _resetTimer?.cancel();
          _resetTimer = Timer(const Duration(seconds: 2), () {
            if (_status == AutosaveStatus.saved) {
              _setStatus(AutosaveStatus.idle);
            }
          });
          return true;
        }
      } else {
        _errorMessage = 'Não foi possível salvar no servidor. Tente novamente.';
        _pendingSheet ??= snapshotToSave;
        _setStatus(AutosaveStatus.error);
        _isSaving = false;
        final nextCompleter = _activeSaveCompleter;
        _activeSaveCompleter = null;
        nextCompleter?.complete(false);
        return false;
      }
    } catch (e) {
      assert(() {
        debugPrint(
          '[WorkoutAutosaveController Error] Falha técnica ao sincronizar ficha',
        );
        return true;
      }());
      _errorMessage = 'Erro técnico de persistência. Tente novamente.';
      _pendingSheet ??= snapshotToSave;
      _setStatus(AutosaveStatus.error);
      _isSaving = false;
      final nextCompleter = _activeSaveCompleter;
      _activeSaveCompleter = null;
      nextCompleter?.complete(false);
      return false;
    } finally {
      _isSaving = false;
    }
  }

  /// Descarte explícito de alterações pendentes em memória
  void discardPending() {
    _debounceTimer?.cancel();
    _resetTimer?.cancel();
    _pendingSheet = null;
    _errorMessage = null;
    if (!_isSaving) {
      if (_activeSaveCompleter != null && !_activeSaveCompleter!.isCompleted) {
        _activeSaveCompleter!.complete(false);
        _activeSaveCompleter = null;
      }
      _setStatus(AutosaveStatus.idle);
    }
  }

  /// Tenta novamente o último snapshot acumulado
  Future<bool> retry() async {
    if (_pendingSheet != null) {
      return await saveNow(_pendingSheet!);
    }
    return true;
  }

  /// Garante a persistência de pendências antes de trocar de aluno ou descartar
  Future<bool> flush() async {
    _debounceTimer?.cancel();
    if (_pendingSheet != null || _isSaving) {
      return await _triggerSave();
    }
    return true;
  }

  bool _isDisposed = false;

  void _setStatus(AutosaveStatus newStatus) {
    if (_isDisposed) return;
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _debounceTimer?.cancel();
    _resetTimer?.cancel();
    super.dispose();
  }
}
