import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../../models/anamnese_model.dart';
import '../../models/student_model.dart';
import '../../repositories/anamnese_repository.dart';
import '../../services/anamnese_attachment_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/interactive_body_pain_selector.dart';
import '../../widgets/private_document_image.dart';

class AnamneseFormWizardView extends StatefulWidget {
  final Student? student;
  final String? leadId;
  final VoidCallback? onCompleted;
  final AnamneseModel? initialAnamnese;

  const AnamneseFormWizardView({
    super.key,
    this.student,
    this.leadId,
    this.onCompleted,
    this.initialAnamnese,
  });

  @override
  State<AnamneseFormWizardView> createState() => _AnamneseFormWizardViewState();
}

class _AnamneseFormWizardViewState extends State<AnamneseFormWizardView> {
  int _currentStep = 0;
  String _anamneseId = 'an_${DateTime.now().microsecondsSinceEpoch}';
  AnamneseModel? _original;
  final int _totalSteps =
      7; // Expandido para 7 passos com Bioimpedância dedicada
  bool _isLoading = false;
  bool _isSavingDraft = false;
  bool _draftReady = false;
  bool _allowExit = false;
  final ScrollController _stepScrollController = ScrollController();
  final AnamneseRepository _repository = AnamneseRepository();
  final AnamneseAttachmentService _attachments = AnamneseAttachmentService();
  bool _isExtractingOcr = false;
  final Set<String> _sessionUploadedReferences = {};

  String _getMotivationalMessage() {
    switch (_currentStep) {
      case 0:
        return 'Vamos começar! É rápido.';
      case 1:
        return 'Ótimo. Conhecer suas metas é o primeiro passo!';
      case 2:
        return 'A segurança sempre em primeiro lugar.';
      case 3:
        return 'Organizando o seu tempo para o máximo de resultados.';
      case 4:
        return 'Foco total no seu objetivo!';
      case 5:
        return 'Bioimpedância e exames';
      case 6:
        return 'Último passo! Estamos na reta final!';
      default:
        return '';
    }
  }

  // Step 1: Identificação
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cpfController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _addressController;
  String _gender = 'Masculino';

  // Step 2: Antropometria & Metas
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _bodyFatController;
  late final TextEditingController _targetWeightController;
  late final TextEditingController _gymController;
  late final TextEditingController _specificGoalsController;
  String _mainGoal = 'Hipertrofia';

  // Step 3: PAR-Q+ & Saúde
  final Map<String, bool> _parqAnswers = {
    'parq_cardiac_problem': false,
    'parq_chest_pain_activity': false,
    'parq_chest_pain_rest': false,
    'parq_dizziness_consciousness': false,
    'parq_bone_joint_problem': false,
    'parq_blood_pressure_meds': false,
    'parq_other_reason': false,
  };
  final Map<String, String> _parqDetails = {};
  final List<String> _selectedJointPains = [];
  late final TextEditingController _movementPainController;
  late final TextEditingController _medicalHistoryController;
  late final TextEditingController _surgeriesController;
  late final TextEditingController _medicationsController;
  late final TextEditingController _supplementsController;

  // Step 4: Rotina
  int _trainingDaysPerWeek = 4;
  String _sessionDuration = '45 a 60 minutos';
  String _preferredShift = 'Manhã';
  String _experienceLevel = 'Intermediário';
  bool _hasTrainedWithCoach = false;
  late final TextEditingController _otherSportsController;

  // Step 5: Foco Muscular & Hábitos
  final List<String> _selectedMuscles = [];
  late final TextEditingController _favoriteExercisesController;
  late final TextEditingController _dislikedExercisesController;
  double _sleepHours = 7.0;
  double _waterIntake = 2.5;
  int _stressLevel = 3;
  late final TextEditingController _dietController;

  // Step 6: Bioimpedância & Exames Médicos (DEDICADO)
  String? _bioimpedanceFileUrl;
  String? _bioimpedanceFileName;
  int _bioimpedanceFileSize = 0;
  late final TextEditingController _bioMuscleMassController;
  late final TextEditingController _bioFatMassController;
  late final TextEditingController _bioBfController;
  late final TextEditingController _bioBmrController;
  late final TextEditingController _bioVisceralFatController;
  late final TextEditingController _bioWaterController;
  String _bioDeviceModel = 'InBody / Balança de Precisão';
  final List<MedicalDocument> _documents = [];

  // Step 7: Fotos & Finalização
  final List<PosturePhoto> _posturePhotos = [];
  bool _consentAccepted = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadInitialOrDraftData();
  }

  void _initControllers() {
    final s = widget.student;
    _nameController = TextEditingController(text: s?.name ?? '');
    _emailController = TextEditingController(text: s?.email ?? '');
    _phoneController = TextEditingController(text: s?.phone ?? '');
    _cpfController = TextEditingController(text: s?.cpf ?? '');
    _birthDateController = TextEditingController();
    _addressController = TextEditingController(text: s?.address ?? '');

    _weightController = TextEditingController();
    _heightController = TextEditingController();
    _bodyFatController = TextEditingController();
    _targetWeightController = TextEditingController();
    _gymController = TextEditingController(text: s?.gymName ?? '');
    _specificGoalsController = TextEditingController();

    _movementPainController = TextEditingController();
    _medicalHistoryController = TextEditingController();
    _surgeriesController = TextEditingController();
    _medicationsController = TextEditingController();
    _supplementsController = TextEditingController();

    _otherSportsController = TextEditingController();
    _favoriteExercisesController = TextEditingController();
    _dislikedExercisesController = TextEditingController();
    _dietController = TextEditingController();

    // Bioimpedance Controllers
    _bioMuscleMassController = TextEditingController();
    _bioFatMassController = TextEditingController();
    _bioBfController = TextEditingController();
    _bioBmrController = TextEditingController();
    _bioVisceralFatController = TextEditingController();
    _bioWaterController = TextEditingController();
  }

  Future<void> _loadInitialOrDraftData() async {
    final id =
        widget.student?.id ??
        widget.initialAnamnese?.studentId ??
        widget.leadId ??
        'temp_draft';
    final local = await _repository.getLocalDraft(id);
    final initial = widget.initialAnamnese;
    final draft = initial == null
        ? local
        : (local?.id == initial.id ? local : initial);
    if (draft != null && mounted) {
      setState(() {
        _anamneseId = draft.id;
        _original = draft;
        _nameController.text = draft.name;
        _emailController.text = draft.email;
        _phoneController.text = draft.phone;
        _cpfController.text = draft.cpf;
        _birthDateController.text = draft.birthDate;
        _addressController.text = draft.address;
        _bodyFatController.text = draft.bodyFatPercent?.toString() ?? '';
        _targetWeightController.text = draft.targetWeightKg?.toString() ?? '';
        _parqDetails.addAll(draft.parqDetails);
        _movementPainController.text = draft.movementPainDetails;
        _medicalHistoryController.text = draft.medicalHistory;
        _surgeriesController.text = draft.surgeries;
        _medicationsController.text = draft.medications;
        _supplementsController.text = draft.supplements;
        _experienceLevel = draft.experienceLevel;
        _preferredShift = draft.preferredShift;
        _stressLevel = draft.stressLevel;
        _hasTrainedWithCoach = draft.hasTrainedWithCoach;
        _otherSportsController.text = draft.otherSports;
        _sleepHours = draft.sleepHours.clamp(4, 10).toDouble();
        _waterIntake = draft.waterIntakeLiters.clamp(1, 6).toDouble();
        _dietController.text = draft.dietHabit;
        _documents.addAll(draft.documents);
        _posturePhotos.addAll(draft.posturePhotos);
        _gender = draft.gender;
        _weightController.text = draft.weightKg > 0
            ? draft.weightKg.toString()
            : '';
        _heightController.text = draft.heightCm > 0
            ? draft.heightCm.toString()
            : '';
        _mainGoal = draft.mainGoal;
        _specificGoalsController.text = draft.specificGoals;
        _gymController.text = draft.gymName;
        _parqAnswers.addAll(draft.parqAnswers);
        _selectedJointPains.addAll(draft.jointPains);
        _trainingDaysPerWeek = draft.trainingDaysPerWeek;
        _sessionDuration = draft.sessionDuration;
        _selectedMuscles.addAll(draft.targetMuscles);
        _favoriteExercisesController.text = draft.favoriteExercises;
        _dislikedExercisesController.text = draft.dislikedExercises;

        // Bioimpedance draft
        if (draft.bioimpedance != null) {
          final bio = draft.bioimpedance!;
          _bioimpedanceFileUrl = bio.fileUrl;
          _bioimpedanceFileName = bio.fileName;
          _bioimpedanceFileSize = bio.fileSizeBytes;
          _bioMuscleMassController.text = bio.muscleMassKg?.toString() ?? '';
          _bioFatMassController.text = bio.fatMassKg?.toString() ?? '';
          _bioBfController.text = bio.bodyFatPercent?.toString() ?? '';
          _bioBmrController.text = bio.basalMetabolicRateKcal?.toString() ?? '';
          _bioVisceralFatController.text =
              bio.visceralFatLevel?.toString() ?? '';
          _bioWaterController.text = bio.totalBodyWaterLiters?.toString() ?? '';
          _bioDeviceModel = bio.deviceModel ?? 'InBody / Balança de Precisão';
        }
      });
    }
    if (mounted) setState(() => _draftReady = true);
  }

  @override
  void dispose() {
    _stepScrollController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cpfController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _bodyFatController.dispose();
    _targetWeightController.dispose();
    _gymController.dispose();
    _specificGoalsController.dispose();
    _movementPainController.dispose();
    _medicalHistoryController.dispose();
    _surgeriesController.dispose();
    _medicationsController.dispose();
    _supplementsController.dispose();
    _otherSportsController.dispose();
    _favoriteExercisesController.dispose();
    _dislikedExercisesController.dispose();
    _dietController.dispose();
    _bioMuscleMassController.dispose();
    _bioFatMassController.dispose();
    _bioBfController.dispose();
    _bioBmrController.dispose();
    _bioVisceralFatController.dispose();
    _bioWaterController.dispose();
    super.dispose();
  }

  double _getCalculatedBmi() {
    final w =
        double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0.0;
    final h =
        double.tryParse(_heightController.text.replaceAll(',', '.')) ?? 0.0;
    if (w <= 0 || h <= 0) return 0.0;
    final hM = h / 100.0;
    return double.parse((w / (hM * hM)).toStringAsFixed(1));
  }

  BioimpedanceData? _buildBioimpedanceData() {
    final mm = double.tryParse(
      _bioMuscleMassController.text.replaceAll(',', '.'),
    );
    final fm = double.tryParse(_bioFatMassController.text.replaceAll(',', '.'));
    final bf = double.tryParse(_bioBfController.text.replaceAll(',', '.'));
    final bmr = double.tryParse(_bioBmrController.text.replaceAll(',', '.'));
    final vf = int.tryParse(_bioVisceralFatController.text);
    final tbw = double.tryParse(_bioWaterController.text.replaceAll(',', '.'));

    if ((_bioimpedanceFileUrl?.isEmpty ?? true) &&
        mm == null &&
        fm == null &&
        bf == null &&
        bmr == null &&
        vf == null &&
        tbw == null) {
      return null;
    }

    return BioimpedanceData(
      fileUrl: _bioimpedanceFileUrl,
      fileName: _bioimpedanceFileName,
      fileSizeBytes: _bioimpedanceFileSize,
      muscleMassKg: mm,
      fatMassKg: fm,
      bodyFatPercent: bf,
      basalMetabolicRateKcal: bmr,
      visceralFatLevel: vf,
      totalBodyWaterLiters: tbw,
      deviceModel: _bioDeviceModel,
      assessmentDate: _original?.bioimpedance?.assessmentDate ?? DateTime.now(),
    );
  }

  AnamneseModel _buildCurrentModel({bool isDraft = false}) {
    final w =
        double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0.0;
    final h =
        double.tryParse(_heightController.text.replaceAll(',', '.')) ?? 0.0;
    final bf = double.tryParse(_bodyFatController.text.replaceAll(',', '.'));
    final tw = double.tryParse(
      _targetWeightController.text.replaceAll(',', '.'),
    );

    return AnamneseModel(
      id: _anamneseId,
      studentId:
          widget.student?.id ??
          _original?.studentId ??
          widget.leadId ??
          'temp_draft',
      leadId: widget.leadId ?? _original?.leadId,
      age: _original?.age ?? 0,
      bodyPerception: _original?.bodyPerception ?? '',
      alcoholHabit: _original?.alcoholHabit ?? 'Não',
      smokingHabit: _original?.smokingHabit ?? 'Não',
      instructorNotes: _original?.instructorNotes ?? '',
      createdAt: _original?.createdAt,
      updatedAt: DateTime.now(),
      name: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : 'Aluno Sem Nome',
      gender: _gender,
      birthDate: _birthDateController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      cpf: _cpfController.text.trim(),
      address: _addressController.text.trim(),
      weightKg: w,
      heightCm: h,
      bodyFatPercent: bf,
      targetWeightKg: tw,
      mainGoal: _mainGoal,
      specificGoals: _specificGoalsController.text.trim(),
      gymName: _gymController.text.trim(),
      bioimpedance: _buildBioimpedanceData(),
      trainingDaysPerWeek: _trainingDaysPerWeek,
      sessionDuration: _sessionDuration,
      preferredShift: _preferredShift,
      experienceLevel: _experienceLevel,
      hasTrainedWithCoach: _hasTrainedWithCoach,
      otherSports: _otherSportsController.text.trim(),
      targetMuscles: List.from(_selectedMuscles),
      parqAnswers: Map.from(_parqAnswers),
      parqDetails: Map.from(_parqDetails),
      jointPains: List.from(_selectedJointPains),
      movementPainDetails: _movementPainController.text.trim(),
      medicalHistory: _medicalHistoryController.text.trim(),
      surgeries: _surgeriesController.text.trim(),
      medications: _medicationsController.text.trim(),
      supplements: _supplementsController.text.trim(),
      sleepHours: _sleepHours,
      waterIntakeLiters: _waterIntake,
      stressLevel: _stressLevel,
      dietHabit: _dietController.text.trim(),
      favoriteExercises: _favoriteExercisesController.text.trim(),
      dislikedExercises: _dislikedExercisesController.text.trim(),
      posturePhotos: List.from(_posturePhotos),
      documents: List.from(_documents),
      isDraft: isDraft,
      consentAccepted: _consentAccepted,
    );
  }

  Future<bool> _saveDraft({
    bool showSuccess = true,
    bool showError = true,
  }) async {
    if (_isSavingDraft || !_draftReady) return false;
    setState(() => _isSavingDraft = true);
    final model = _buildCurrentModel(isDraft: true);
    final saved = await _repository.saveLocalDraft(model);
    if (mounted) {
      setState(() => _isSavingDraft = false);
      if ((saved && showSuccess) || (!saved && showError)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              saved
                  ? 'Rascunho salvo neste dispositivo.'
                  : 'Não foi possível salvar o rascunho neste dispositivo. Tente novamente.',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
    return saved;
  }

  void _leave() {
    if (!mounted) return;
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _requestExit() async {
    if (_isSavingDraft || _isLoading || !_draftReady) return;
    if (await _saveDraft(showSuccess: false, showError: false)) {
      _leave();
      return;
    }
    if (!mounted) return;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rascunho não salvo'),
        content: const Text(
          'Não foi possível salvar suas respostas neste dispositivo. '
          'Você pode continuar no formulário e tentar novamente ou sair sem salvar as alterações recentes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Continuar e tentar novamente'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sair sem salvar'),
          ),
        ],
      ),
    );
    if (discard == true) _leave();
  }

  Future<void> _changeStep(int delta) async {
    if (_isSavingDraft || !_draftReady) return;
    if (!await _saveDraft(showSuccess: false)) return;
    if (mounted) _moveToStep(_currentStep + delta);
  }

  void _moveToStep(int step) {
    setState(() => _currentStep = step);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_stepScrollController.hasClients) _stepScrollController.jumpTo(0);
      SemanticsService.sendAnnouncement(
        View.of(context),
        'Passo ${_currentStep + 1} de $_totalSteps: ${_getStepTitle(_currentStep)}',
        Directionality.of(context),
      );
    });
  }

  Future<void> _submitAnamnese() async {
    if (_isLoading || _isExtractingOcr) return;
    if (!_consentAccepted) return;
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Por favor, informe ao menos o nome do aluno.'),
        ),
      );
      _moveToStep(0);
      return;
    }

    setState(() => _isLoading = true);
    final model = _buildCurrentModel(isDraft: false);
    final success = await _repository.saveAnamnese(model);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.emerald,
            content: Text(
              '✅ Anamnese & Bioimpedância 360° concluídas com sucesso!',
            ),
          ),
        );
        widget.onCompleted?.call();
        setState(() => _allowExit = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context, model);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.crimson,
            content: Text('❌ Falha ao salvar a anamnese. Tente novamente.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowExit,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestExit();
      },
      child: Scaffold(
        backgroundColor: AppColors.carbon,
        appBar: AppBar(
          backgroundColor: AppColors.carbon2,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Anamnese & Intake 360°',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  'Passo ${_currentStep + 1} de $_totalSteps • ${_getStepTitle(_currentStep)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: _isSavingDraft
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              tooltip: 'Salvar Rascunho',
              onPressed: _isSavingDraft || !_draftReady
                  ? null
                  : () => _saveDraft(),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.vibrantBlue,
              ),
            ),
          ),
        ),
        body: _isLoading || !_draftReady
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _stepScrollController,
                        padding: const EdgeInsets.all(20.0),
                        child: _buildCurrentStepContent(),
                      ),
                    ),
                    _buildBottomNavigation(),
                  ],
                ),
              ),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Identificação & Contato';
      case 1:
        return 'Antropometria & Metas';
      case 2:
        return 'Histórico Clínico & PAR-Q+';
      case 3:
        return 'Rotina & Treino';
      case 4:
        return 'Músculos & Hábitos';
      case 5:
        return 'Bioimpedância & Exames';
      case 6:
        return 'Fotos Posturais & Termos';
      default:
        return '';
    }
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Identification();
      case 1:
        return _buildStep2Biometrics();
      case 2:
        return _buildStep3ClinicalParq();
      case 3:
        return _buildStep4Routine();
      case 4:
        return _buildStep5Preferences();
      case 5:
        return _buildStep6Bioimpedance();
      case 6:
        return _buildStep7PhotosAndFinish();
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: IDENTIFICAÇÃO
  Widget _buildStep1Identification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.person_outline,
          title: 'Dados Cadastrais',
          subtitle: 'Informações de contato e identificação oficial do aluno.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nome Completo *',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp / Telefone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _cpfController,
                decoration: const InputDecoration(
                  labelText: 'CPF',
                  prefixIcon: Icon(Icons.credit_card_outlined),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'E-mail Principal',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Sexo / Gênero',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: ['Masculino', 'Feminino', 'Outro'].map((g) {
            final isSelected = _gender == g;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(g),
                  selected: isSelected,
                  selectedColor: AppColors.vibrantBlue.withValues(alpha: 0.3),
                  onSelected: (val) {
                    if (val) setState(() => _gender = g);
                  },
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Endereço / Cidade',
            prefixIcon: Icon(Icons.home_outlined),
          ),
        ),
      ],
    );
  }

  // STEP 2: ANTROPOMETRIA & METAS
  Widget _buildStep2Biometrics() {
    final bmi = _getCalculatedBmi();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.monitor_weight_outlined,
          title: 'Antropometria & Objetivos',
          subtitle:
              'Medidas corporais e meta principal para cálculo de periodização.',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Peso Atual (kg) *',
                  suffixText: 'kg',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _heightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Altura (cm) *',
                  suffixText: 'cm',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Card de IMC Dinâmico
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161E2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.vibrantBlue.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.vibrantBlue,
                child: Icon(Icons.health_and_safety, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IMC Calculado: $bmi kg/m²',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Classificação OMS: ${_buildCurrentModel().bmiClassification}',
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _bodyFatController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '% Gordura Estimado',
                  suffixText: '%',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _targetWeightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Peso Meta (kg)',
                  suffixText: 'kg',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Objetivo Primário',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
                'Hipertrofia',
                'Emagrecimento',
                'Definição',
                'Saúde & Qualidade',
                'Força / Performance',
                'Reabilitação / Postura',
                'TAF / Concurso',
              ].map((goal) {
                final isSelected = _mainGoal == goal;
                return ChoiceChip(
                  label: Text(goal),
                  selected: isSelected,
                  selectedColor: AppColors.vibrantBlue.withValues(alpha: 0.3),
                  onSelected: (val) {
                    if (val) setState(() => _mainGoal = goal);
                  },
                );
              }).toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _specificGoalsController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Metas Específicas / Expectativas do Aluno',
            hintText:
                'Ex: Aumentar 3cm de braço, diminuir gordura abdominal...',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _gymController,
          decoration: const InputDecoration(
            labelText: 'Academia onde treina atualmente',
            prefixIcon: Icon(Icons.fitness_center),
          ),
        ),
      ],
    );
  }

  // STEP 3: CLÍNICO & PAR-Q+
  Widget _buildStep3ClinicalParq() {
    final parqQuestions = [
      {
        'key': 'parq_cardiac_problem',
        'q':
            '1. Algum médico já disse que você possui problema cardíaco e que só deve fazer exercício sob supervisão?',
      },
      {
        'key': 'parq_chest_pain_activity',
        'q': '2. Você sente dor no peito quando pratica atividade física?',
      },
      {
        'key': 'parq_chest_pain_rest',
        'q': '3. No último mês, você sentiu dor no peito mesmo em repouso?',
      },
      {
        'key': 'parq_dizziness_consciousness',
        'q':
            '4. Você já perdeu o equilíbrio por tontura ou perdeu a consciência?',
      },
      {
        'key': 'parq_bone_joint_problem',
        'q':
            '5. Você possui problema ósseo ou articular que pode piorar com o exercício?',
      },
      {
        'key': 'parq_blood_pressure_meds',
        'q':
            '6. Seu médico prescreve medicamentos para pressão alta ou coração?',
      },
      {
        'key': 'parq_other_reason',
        'q':
            '7. Tem conhecimento de outro motivo pelo qual não deveria treinar?',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.medical_services_outlined,
          title: 'Questionário de Prontidão (PAR-Q+)',
          subtitle:
              'Padrão clínico internacional para segurança na prescrição do treinamento.',
        ),
        const SizedBox(height: 16),

        ...parqQuestions.map((item) {
          final key = item['key']!;
          final qText = item['q']!;
          final isYes = _parqAnswers[key] == true;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: isYes ? const Color(0xFF2E1A1A) : AppColors.carbon2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isYes
                    ? AppColors.crimson.withValues(alpha: 0.6)
                    : Colors.white10,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    qText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ChoiceChip(
                        label: const Text('Não'),
                        selected: !isYes,
                        selectedColor: AppColors.emerald.withValues(alpha: 0.3),
                        onSelected: (val) {
                          if (val) setState(() => _parqAnswers[key] = false);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Sim'),
                        selected: isYes,
                        selectedColor: AppColors.crimson.withValues(alpha: 0.4),
                        onSelected: (val) {
                          if (val) setState(() => _parqAnswers[key] = true);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 16),
        InteractiveBodyPainSelector(
          selectedJoints: _selectedJointPains,
          onChanged: (updated) => setState(() {
            _selectedJointPains.clear();
            _selectedJointPains.addAll(updated);
          }),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _movementPainController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Exercícios ou movimentos que causam dor',
            hintText: 'Ex: Dor no ombro direito ao fazer supino reto...',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _medicalHistoryController,
          decoration: const InputDecoration(
            labelText: 'Histórico de Patologias / Lesões Anteriores',
            hintText: 'Ex: Hérnia de disco L4-L5, cirurgia de LCA em 2022...',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _medicationsController,
          decoration: const InputDecoration(
            labelText: 'Medicamentos Contínuos / Suplementação em Uso',
          ),
        ),
      ],
    );
  }

  // STEP 4: ROTINA & TREINO
  Widget _buildStep4Routine() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.calendar_today_outlined,
          title: 'Rotina & Disponibilidade',
          subtitle: 'Ajuste de volume, frequência semanal e tempo por sessão.',
        ),
        const SizedBox(height: 16),
        Text(
          'Disponibilidade Real: $_trainingDaysPerWeek dias por semana',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        Slider(
          value: _trainingDaysPerWeek.toDouble(),
          min: 1,
          max: 7,
          divisions: 6,
          label: '$_trainingDaysPerWeek dias',
          activeColor: AppColors.vibrantBlue,
          onChanged: (val) =>
              setState(() => _trainingDaysPerWeek = val.round()),
        ),
        const SizedBox(height: 16),
        const Text(
          'Duração Ideal por Sessão',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              [
                '30 a 45 minutos',
                '45 a 60 minutos',
                '60 a 75 minutos',
                '90+ minutos',
              ].map((d) {
                final isSelected = _sessionDuration == d;
                return ChoiceChip(
                  label: Text(d),
                  selected: isSelected,
                  selectedColor: AppColors.vibrantBlue.withValues(alpha: 0.3),
                  onSelected: (val) {
                    if (val) setState(() => _sessionDuration = d);
                  },
                );
              }).toList(),
        ),
        const SizedBox(height: 16),
        const Text(
          'Nível de Experiência na Musculação',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              [
                'Iniciante (<6 meses)',
                'Intermediário (6m - 2 anos)',
                'Avançado (>2 anos)',
              ].map((lvl) {
                final isSelected = _experienceLevel == lvl;
                return ChoiceChip(
                  label: Text(lvl),
                  selected: isSelected,
                  selectedColor: AppColors.vibrantBlue.withValues(alpha: 0.3),
                  onSelected: (val) {
                    if (val) setState(() => _experienceLevel = lvl);
                  },
                );
              }).toList(),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Já treinou com personal ou consultoria antes?'),
          value: _hasTrainedWithCoach,
          activeThumbColor: AppColors.vibrantBlue,
          onChanged: (val) => setState(() => _hasTrainedWithCoach = val),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _otherSportsController,
          decoration: const InputDecoration(
            labelText: 'Outras Atividades Físicas / Cardio',
            hintText: 'Ex: Corrida 2x/sem, Pilates, Futebol aos sábados...',
          ),
        ),
      ],
    );
  }

  // STEP 5: PREFERÊNCIAS & HÁBITOS
  Widget _buildStep5Preferences() {
    final muscles = [
      'Peitoral',
      'Costas',
      'Ombros',
      'Bíceps',
      'Tríceps',
      'Quadríceps',
      'Posterior de Coxa',
      'Glúteos',
      'Panturrilhas',
      'Abdômen / Core',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.tune_outlined,
          title: 'Foco Muscular & Hábitos',
          subtitle:
              'Priorização de grupos musculares e hábitos de recuperação.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Grupos Musculares Prioritários (Foco da Periodização)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: muscles.map((m) {
            final isSelected = _selectedMuscles.contains(m);
            return FilterChip(
              label: Text(m),
              selected: isSelected,
              selectedColor: AppColors.vibrantBlue.withValues(alpha: 0.3),
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedMuscles.add(m);
                  } else {
                    _selectedMuscles.remove(m);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _favoriteExercisesController,
          decoration: const InputDecoration(
            labelText: 'Exercícios que mais gosta',
            hintText:
                'Ex: Supino reto, Elevação lateral, Agachamento búlgaro...',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _dislikedExercisesController,
          decoration: const InputDecoration(
            labelText: 'Exercícios que NÃO gosta ou quer evitar',
            hintText: 'Ex: Burpee, Passada, Levantamento terra...',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Média de Sono: ${_sleepHours.toStringAsFixed(1)} horas/noite',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Slider(
          value: _sleepHours,
          min: 4,
          max: 10,
          divisions: 12,
          activeColor: AppColors.vibrantBlue,
          onChanged: (val) => setState(() => _sleepHours = val),
        ),
        const SizedBox(height: 8),
        Text(
          'Ingestão de Água: ${_waterIntake.toStringAsFixed(1)} Litros/dia',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Slider(
          value: _waterIntake,
          min: 1.0,
          max: 6.0,
          divisions: 10,
          activeColor: AppColors.vibrantBlue,
          onChanged: (val) => setState(() => _waterIntake = val),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _dietController,
          decoration: const InputDecoration(
            labelText: 'Alimentação & Dieta',
            hintText: 'Ex: Acompanhado por nutricionista, déficit calórico...',
          ),
        ),
      ],
    );
  }

  Future<void> _handleBioimpedanceUpload() async {
    await _uploadAttachment(bioimpedance: true);
  }

  Future<void> _uploadAttachment({
    bool bioimpedance = false,
    PostureAngle? angle,
  }) async {
    if (_isExtractingOcr || _isLoading) return;
    final previousReference = angle != null
        ? _posturePhotos
              .cast<PosturePhoto?>()
              .firstWhere((photo) => photo?.angle == angle, orElse: () => null)
              ?.url
        : bioimpedance
        ? _bioimpedanceFileUrl
        : null;
    setState(() => _isExtractingOcr = true);
    try {
      final attachment = await _attachments.selectAndUpload(
        widget.student?.id ?? '',
        angle: angle,
      );
      if (!mounted || attachment == null) return;
      _sessionUploadedReferences.add(attachment.reference);
      setState(() {
        if (angle != null) {
          _posturePhotos.removeWhere((p) => p.angle == angle);
          _posturePhotos.add(
            PosturePhoto(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              angle: angle,
              url: attachment.reference,
              fileName: attachment.name,
              fileSizeBytes: attachment.bytes.length,
            ),
          );
        } else if (bioimpedance) {
          _bioimpedanceFileUrl = attachment.reference;
          _bioimpedanceFileName = attachment.name;
          _bioimpedanceFileSize = attachment.bytes.length;
        } else {
          _documents.add(
            MedicalDocument(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              title: attachment.name,
              fileUrl: attachment.reference,
              fileType: attachment.name.split('.').last.toLowerCase(),
              sizeBytes: attachment.bytes.length,
            ),
          );
        }
      });
      final draftSaved = await _saveDraft();
      if (draftSaved &&
          previousReference != null &&
          previousReference != attachment.reference &&
          _sessionUploadedReferences.remove(previousReference)) {
        final deleted = await _repository.deleteDocumentReference(
          studentId: widget.student?.id ?? _original?.studentId ?? '',
          reference: previousReference,
        );
        if (!deleted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'O novo arquivo foi salvo, mas o envio anterior não pôde ser limpo.',
              ),
            ),
          );
        }
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is FormatException
                ? error.message
                : 'Falha no envio do arquivo.',
          ),
          action: SnackBarAction(
            label: 'Tentar novamente',
            onPressed: () =>
                _uploadAttachment(bioimpedance: bioimpedance, angle: angle),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExtractingOcr = false);
    }
  }

  Future<void> _removeAttachmentReference({
    required String reference,
    required String label,
    required VoidCallback unlink,
  }) async {
    if (_isExtractingOcr || _isLoading) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Retirar $label?'),
        content: const Text(
          'O anexo será retirado desta avaliação. A alteração será efetivada ao finalizar o formulário.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Retirar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isExtractingOcr = true;
      unlink();
    });
    try {
      final draftSaved = await _saveDraft();
      if (draftSaved && _sessionUploadedReferences.remove(reference)) {
        final deleted = await _repository.deleteDocumentReference(
          studentId: widget.student?.id ?? _original?.studentId ?? '',
          reference: reference,
        );
        if (!deleted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'O anexo foi retirado, mas o arquivo enviado não pôde ser limpo.',
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isExtractingOcr = false);
    }
  }

  // STEP 6: BIOIMPEDÂNCIA & EXAMES MÉDICOS (DEDICADO)
  Widget _buildStep6Bioimpedance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.analytics_outlined,
          title: 'Bioimpedância & Exames',
          subtitle:
              'Envio do laudo de bioimpedância (PDF/Foto) e composição corporal.',
        ),
        const SizedBox(height: 16),

        if (_isExtractingOcr)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.vibrantBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.vibrantBlue.withValues(alpha: 0.3),
              ),
            ),
            child: const Column(
              children: [
                CircularProgressIndicator(color: AppColors.vibrantBlue),
                SizedBox(height: 12),
                Text(
                  'Enviando arquivo...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.vibrantBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else
          // Área de Upload de Arquivo de Bioimpedância
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.carbon2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _bioimpedanceFileUrl != null
                    ? AppColors.emerald
                    : AppColors.vibrantBlue.withValues(alpha: 0.4),
                width: _bioimpedanceFileUrl != null ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _bioimpedanceFileUrl != null
                      ? Icons.check_circle
                      : Icons.upload_file_outlined,
                  size: 44,
                  color: _bioimpedanceFileUrl != null
                      ? AppColors.emerald
                      : AppColors.vibrantBlue,
                ),
                const SizedBox(height: 12),
                Text(
                  _bioimpedanceFileUrl != null
                      ? 'Laudo de Bioimpedância Anexado!'
                      : 'Fazer Upload do Laudo de Bioimpedância',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _bioimpedanceFileName ??
                      'Formatos suportados: PDF, JPG, PNG (InBody, Tanita, Omron, etc.)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _bioimpedanceFileUrl != null
                            ? AppColors.carbon
                            : AppColors.vibrantBlue,
                      ),
                      icon: Icon(
                        _bioimpedanceFileUrl != null
                            ? Icons.refresh
                            : Icons.cloud_upload,
                      ),
                      label: Text(
                        _bioimpedanceFileUrl != null
                            ? 'Substituir Laudo'
                            : 'Selecionar arquivo',
                      ),
                      onPressed: _handleBioimpedanceUpload,
                    ),
                    if (_bioimpedanceFileUrl != null) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.crimson,
                        ),
                        tooltip: 'Remover laudo',
                        onPressed: () => _removeAttachmentReference(
                          reference: _bioimpedanceFileUrl!,
                          label: 'o laudo de bioimpedância',
                          unlink: () {
                            _bioimpedanceFileUrl = null;
                            _bioimpedanceFileName = null;
                            _bioimpedanceFileSize = 0;
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),
        const Text(
          'Métricas de Composição Corporal (Opcional se enviou o arquivo)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _bioMuscleMassController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Massa Muscular (kg)',
                  suffixText: 'kg',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _bioFatMassController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Massa Gorda (kg)',
                  suffixText: 'kg',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _bioBfController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: '% Gordura (BF)',
                  suffixText: '%',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _bioBmrController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Taxa Metabólica (TMB)',
                  suffixText: 'kcal',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _bioVisceralFatController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Gordura Visceral (Nível)',
                  hintText: '1 a 20',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _bioWaterController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Água Corporal (L)',
                  suffixText: 'L',
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        const Divider(color: Colors.white10),
        const SizedBox(height: 8),

        // Seção para Exames Complementares (Sangue / Atestados)
        Row(
          children: [
            const Icon(
              Icons.folder_shared_outlined,
              size: 20,
              color: AppColors.vibrantBlue,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Outros Exames & Laudos Médicos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Anexar Exame'),
              onPressed: _isExtractingOcr ? null : () => _uploadAttachment(),
            ),
          ],
        ),
        if (_documents.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Nenhum outro exame anexado (opcional).',
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
            ),
          )
        else
          ..._documents.map(
            (doc) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(
                  Icons.picture_as_pdf,
                  color: AppColors.crimson,
                ),
                title: Text(
                  doc.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${(doc.sizeBytes / 1024).toStringAsFixed(0)} KB • PDF',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Retirar exame',
                  onPressed: () => _removeAttachmentReference(
                    reference: doc.fileUrl,
                    label: 'este exame',
                    unlink: () => _documents.remove(doc),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // STEP 7: FOTOS POSTURAIS & FINALIZAÇÃO
  Widget _buildStep7PhotosAndFinish() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.camera_alt_outlined,
          title: 'Fotos de Avaliação Postural',
          subtitle:
              'Captura padronizada em 4 ângulos para análise de simetria e postura.',
        ),
        const SizedBox(height: 16),

        // Guia Visual de Orientação de Fotos
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF131D2E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.vibrantBlue.withValues(alpha: 0.3),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.vibrantBlue, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '💡 Dica para as fotos: Use roupas de treino justas, mantenha a câmera na altura do umbigo a 2-3 metros de distância e com boa iluminação.',
                  style: TextStyle(fontSize: 12, color: AppColors.onSurface),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Grid de 4 Cards de Fotos Posturais
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: PostureAngle.values.map((angle) {
            final photo = _posturePhotos.cast<PosturePhoto?>().firstWhere(
              (p) => p?.angle == angle,
              orElse: () => null,
            );

            return InkWell(
              onTap: _isExtractingOcr
                  ? null
                  : () => _uploadAttachment(angle: angle),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.carbon2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: photo != null ? AppColors.emerald : Colors.white12,
                    width: photo != null ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      photo != null
                          ? Icons.check_circle
                          : Icons.add_a_photo_outlined,
                      size: 32,
                      color: photo != null
                          ? AppColors.emerald
                          : AppColors.vibrantBlue,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      angle.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      photo != null ? 'Foto anexada' : 'Toque para enviar',
                      style: TextStyle(
                        fontSize: 10,
                        color: photo != null
                            ? AppColors.emerald
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                    if (photo != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            tooltip: 'Visualizar foto',
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 18,
                            ),
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (ctx) => Dialog(
                                child: SizedBox(
                                  width: 600,
                                  height: 500,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: PrivateDocumentImage(
                                          reference: photo.url,
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: IconButton(
                                          tooltip: 'Fechar',
                                          icon: const Icon(Icons.close),
                                          onPressed: () => Navigator.pop(ctx),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Retirar foto do formulario',
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: _isExtractingOcr
                                ? null
                                : () => _removeAttachmentReference(
                                    reference: photo.url,
                                    label:
                                        'a foto ${angle.label.toLowerCase()}',
                                    unlink: () => _posturePhotos.removeWhere(
                                      (item) => item.angle == angle,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Card de Consentimento LGPD
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _consentAccepted,
                activeColor: AppColors.vibrantBlue,
                onChanged: (val) =>
                    setState(() => _consentAccepted = val ?? false),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Declaro que as informações, laudos de bioimpedância e histórico médico acima são verdadeiros e autorizo o uso dos dados e imagens exclusivamente para elaboração da minha planilha de treino pelo treinador, conforme a Lei Geral de Proteção de Dados (LGPD).',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.vibrantBlue.withValues(alpha: 0.15),
          child: Icon(icon, color: AppColors.vibrantBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    final isLastStep = _currentStep == _totalSteps - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.carbon2,
        border: const Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              _getMotivationalMessage(),
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 8,
            children: [
              if (_currentStep > 0)
                OutlinedButton(
                  onPressed: _isSavingDraft ? null : () => _changeStep(-1),
                  child: const Text('Voltar'),
                ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLastStep
                      ? AppColors.emerald
                      : AppColors.vibrantBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
                icon: Icon(isLastStep ? Icons.check : Icons.arrow_forward),
                label: Text(isLastStep ? 'Finalizar' : 'Próximo Passo'),
                onPressed:
                    _isLoading ||
                        _isSavingDraft ||
                        _isExtractingOcr ||
                        (isLastStep && !_consentAccepted)
                    ? null
                    : isLastStep
                    ? _submitAnamnese
                    : () => _changeStep(1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
