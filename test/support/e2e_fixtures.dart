import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valex_app/controllers/user_profile_controller.dart';
import 'package:valex_app/models/sales_model.dart';
import 'package:valex_app/services/student_context_service.dart';

import 'fake_supabase_backend.dart';

const trainerId = 'trainer-1';
const anaId = '11111111-1111-4111-8111-111111111111';
const joaoId = '22222222-2222-4222-8222-222222222222';
const archivedId = '33333333-3333-4333-8333-333333333333';
const longName =
    'João Pedro Albuquerque de Oliveira Santos Cavalcanti Figueiredo Filho';

Map<String, dynamic> studentRow(
  String id,
  String name, {
  String status = 'active',
  String email = '',
  bool needsReassessment = false,
  String? studentUserId,
}) => {
  'id': id,
  'trainer_id': trainerId,
  'name': name,
  'date': '2026-09-01',
  'teacher': 'Profa. Teste',
  'status': status,
  'cpf': '123.456.789-00',
  'phone': '(41) 99999-0000',
  'email': email,
  'academia': 'Academia Centro',
  'mes': 'Outubro/2026',
  'needs_reassessment': needsReassessment,
  'anamnese_pending': false,
  'student_user_id': studentUserId,
  'created_at': '2026-09-01T10:00:00Z',
};

Map<String, dynamic> exerciseJson(
  String title, {
  String load = '40',
  List<String>? sets,
  int? rest,
}) => {
  'title': title,
  'cue': 'Controle a fase excêntrica',
  'loadKg': load,
  'sets':
      sets ??
      [
        '[work]Série de trabalho: 10-12 reps',
        '[work]Série de trabalho: 10-12 reps',
        '[work]Série de trabalho: 8-10 reps',
      ],
  'restSeconds': ?rest,
};

Map<String, dynamic> sheetRow(String studentId, String studentName) => {
  'id': 'sheet-$studentId',
  'student_id': studentId,
  'trainer_id': trainerId,
  'student_name': studentName,
  'gym_name': 'Academia Centro',
  'month': 'Outubro/2026',
  'instructor_notes': 'Evitar impacto no joelho esquerdo.',
  'days': [
    {
      'dow': 'Treino A',
      'muscle': 'Peitoral e Tríceps',
      'exercises': [
        exerciseJson('Supino Reto com Barra', rest: 60),
        exerciseJson('Crucifixo Inclinado com Halteres', load: '14'),
        exerciseJson('Tríceps Corda na Polia', load: ''),
      ],
    },
    {
      'dow': 'Treino B',
      'muscle': 'Costas e Bíceps',
      'exercises': [
        exerciseJson('Puxada Frontal', load: '45'),
        exerciseJson('Remada Baixa', load: '40'),
      ],
    },
  ],
  'cardio_options': ['Esteira 20 min'],
  'general_notes': ['Hidrate-se'],
  'created_at': '2026-09-02T10:00:00Z',
};

Map<String, dynamic> anamneseRow(String studentId, {String? createdAt}) => {
  'id': 'an-$studentId',
  'student_id': studentId,
  'trainer_id': trainerId,
  'name': 'Ana Beatriz Souza',
  'weight_kg': 64.5,
  'height_cm': 168,
  'main_goal': 'Hipertrofia',
  'is_draft': false,
  'created_at': createdAt ?? '2026-09-03T10:00:00Z',
};

/// A trainer account with students, prescriptions, finance and CRM records.
void seedTrainerWorkspace(FakeSupabaseBackend backend) {
  backend.seed('students', [
    studentRow(anaId, 'Ana Beatriz Souza', email: 'ana@example.com'),
    studentRow(joaoId, longName, needsReassessment: true),
    studentRow(archivedId, 'Zé Arquivado', status: 'archived'),
  ]);
  backend.seed('workout_sheets', [sheetRow(anaId, 'Ana Beatriz Souza')]);
  backend.seed('student_anamneses', [anamneseRow(anaId)]);
  backend.seed('student_workout_sessions', [
    {
      'id': 'session-1',
      'student_id': anaId,
      'trainer_id': trainerId,
      'kind': 'session',
      'workout_day': 'Treino A',
      'completed_sets': {
        '0': [0, 1, 2],
      },
      'duration_seconds': 2700,
      'rpe': 8,
      'feedback': 'Senti o ombro no supino.',
      'created_at': '2026-10-07T18:00:00Z',
    },
    {
      'id': 'comment-1',
      'student_id': anaId,
      'trainer_id': trainerId,
      'kind': 'comment',
      'feedback': 'Posso trocar o treino B por corrida amanhã?',
      'duration_seconds': 0,
      'created_at': '2026-10-08T08:00:00Z',
    },
  ]);
  backend.seed('student_financial_summary', [
    {
      'student_id': anaId,
      'plan_name': 'Consultoria Mensal',
      'subscription_status': 'active',
      'next_due_date': '2026-10-10',
      'total_open': 180,
      'total_overdue': 0,
      'last_payment_date': '2026-09-10',
      'badge': 'paid',
    },
  ]);
  backend.seed('plans', [
    {
      'id': 'plan-1',
      'trainer_id': trainerId,
      'name': 'Consultoria Mensal',
      'type': 'subscription',
      'price': 180,
      'interval': 'Mensal',
      'active': true,
      'status': 'active',
      'created_at': '2026-08-01T00:00:00Z',
    },
  ]);
  backend.seed('subscriptions', [
    {
      'id': 'sub-1',
      'trainer_id': trainerId,
      'student_id': anaId,
      'plan_id': 'plan-1',
      'status': 'active',
      'contracted_value': 180,
      'discount': 0,
      'readjustment': 0,
      'cycle': 'Mensal',
      'start_date': '2026-08-10',
      'auto_renew': true,
      'created_at': '2026-08-10T00:00:00Z',
      'updated_at': '2026-08-10T00:00:00Z',
    },
  ]);
  backend.seed('invoices', [
    {
      'id': 'inv-1',
      'trainer_id': trainerId,
      'student_id': anaId,
      'subscription_id': 'sub-1',
      'plan_id': 'plan-1',
      'type': 'subscription',
      'original_amount': 180,
      'discount': 0,
      'fine': 0,
      'interest': 0,
      'final_amount': 180,
      'due_date': '2026-09-10',
      'status': 'paid',
      'created_at': '2026-09-01T00:00:00Z',
      'updated_at': '2026-09-10T00:00:00Z',
    },
    {
      'id': 'inv-2',
      'trainer_id': trainerId,
      'student_id': anaId,
      'subscription_id': 'sub-1',
      'plan_id': 'plan-1',
      'type': 'subscription',
      'original_amount': 180,
      'discount': 0,
      'fine': 0,
      'interest': 0,
      'final_amount': 180,
      'due_date': '2026-10-10',
      'status': 'pending',
      'created_at': '2026-10-01T00:00:00Z',
      'updated_at': '2026-10-01T00:00:00Z',
    },
  ]);
  backend.seed('payments', [
    {
      'id': 'pay-1',
      'trainer_id': trainerId,
      'invoice_id': 'inv-1',
      'student_id': anaId,
      'amount': 180,
      'payment_date': '2026-09-10',
      'payment_method': 'pix',
      'status': 'confirmed',
      'notes': '',
      'created_at': '2026-09-10T00:00:00Z',
    },
  ]);
  backend.seed('cash_flow', [
    {
      'id': 'cash-1',
      'trainer_id': trainerId,
      'type': 'income',
      'amount': 180,
      'date': '2026-09-10',
      'category': 'Mensalidade',
      'description': 'Pagamento Ana',
      'invoice_id': 'inv-1',
      'created_at': '2026-09-10T00:00:00Z',
    },
  ]);
  backend.seed('leads', [
    {
      ...LeadItem(
        id: 'lead-1',
        name: 'Carla Mendes',
        phone: '41988887777',
        createdAt: '2026-10-01',
        updatedAt: '2026-10-01',
      ).toJson(),
      'trainer_id': trainerId,
    },
  ]);
  backend.seed('custom_presets', [
    {
      'id': 'preset-1',
      'trainer_id': trainerId,
      'preset_title': 'Hipertrofia Iniciante',
      'sheet_data': {
        'studentId': 'preset_custom',
        'studentName': 'Hipertrofia Iniciante',
        'days': [
          {
            'dow': 'Treino A',
            'muscle': 'Corpo inteiro',
            'exercises': [exerciseJson('Agachamento Livre')],
          },
        ],
      },
      'created_at': '2026-09-15T00:00:00Z',
    },
  ]);
}

/// Resets singletons and local storage so every test starts from a clean device.
Future<void> resetAppSingletons() async {
  SharedPreferences.setMockInitialValues({});
  StudentContextService().clearSessionMemory();
  UserProfileController().clear();
}

/// Routes every framework error (layout overflow included) into a list so a
/// single run reports every broken screen instead of stopping at the first.
/// Each error is described immediately, while its widget is still mounted.
Future<List<String>> collectFlutterErrors(Future<void> Function() body) async {
  final errors = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) => errors.add(describeError(details));
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  return errors;
}

String describeError(FlutterErrorDetails error) {
  String full;
  try {
    full = error.toString();
  } catch (_) {
    full = error.exceptionAsString();
  }
  final source =
      RegExp(r'\w+:file:///\S+/lib/(\S+)').firstMatch(full)?.group(1) ??
      error.stack
          ?.toString()
          .split('\n')
          .firstWhere(
            (line) => line.contains('package:valex_app/'),
            orElse: () => '',
          )
          .replaceAll(RegExp(r'^#\d+\s+'), '')
          .trim();
  return '- ${error.exceptionAsString().split('\n').first}'
      '${source == null || source.isEmpty ? '' : ' @ $source'}';
}

String describeErrors(List<String> errors) => errors.toSet().join('\n');

/// Widget tests render text with a square-glyph font that is about twice as
/// wide as Poppins. Loading the shipped fonts keeps overflow checks realistic.
Future<void> loadAppFonts() async {
  final fonts = <String, List<String>>{
    'Poppins': [
      'assets/fonts/Poppins-Regular.ttf',
      'assets/fonts/Poppins-Bold.ttf',
    ],
    'BebasNeue': ['assets/fonts/BebasNeue-Regular.ttf'],
  };
  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key);
    for (final asset in entry.value) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
}

Future<void> settleFrames(WidgetTester tester, {int frames = 6}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
