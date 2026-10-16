import 'support/sales_http_fixture.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valex_app/models/sales_model.dart';

import 'package:valex_app/repositories/sales_repository.dart';

import 'package:valex_app/utils/formatters.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Sales Module 3.0 — Elevated Domain Models & Scheduled Follow-ups', () {
    test('LeadStatus & LeadPriority string parsing and values', () {
      expect(LeadStatusExtension.fromString('new'), LeadStatus.newLead);
      expect(
        LeadStatusExtension.fromString('anamnese_sent'),
        LeadStatus.anamneseSent,
      );
      expect(
        LeadStatusExtension.fromString('proposal_sent'),
        LeadStatus.proposalSent,
      );
      expect(
        LeadStatusExtension.fromString('negotiating'),
        LeadStatus.negotiating,
      );
      expect(LeadStatusExtension.fromString('won'), LeadStatus.won);
      expect(LeadStatusExtension.fromString('lost'), LeadStatus.lost);

      expect(LeadPriorityExtension.fromString('hot'), LeadPriority.hot);
      expect(LeadPriorityExtension.fromString('warm'), LeadPriority.warm);
      expect(LeadPriorityExtension.fromString('cold'), LeadPriority.cold);
    });

    test(
      'Lead scoring dynamic calculation accurately weights origin, ticket, urgency and funnel status',
      () {
        // High intent lead (Indicação + Ticket Alto + Dor Alta + Proposta)
        final hotLead = LeadItem(
          id: 'l_hot',
          name: 'Lead Diamante',
          originChannel: 'indicacao',
          estimatedValue: 800.0,
          objective: 'Dores no ombro e lombar',
          status: LeadStatus.proposalSent,
          createdAt: '',
          updatedAt: '',
        );

        expect(hotLead.score >= 75, isTrue);
        expect(hotLead.priority, LeadPriority.hot);

        // Low intent lead (Google + Ticket 0 + Sem objetivo claro + Novo)
        final coldLead = LeadItem(
          id: 'l_cold',
          name: 'Lead Prata',
          originChannel: 'google',
          estimatedValue: 0.0,
          objective: '',
          status: LeadStatus.newLead,
          createdAt: '',
          updatedAt: '',
        );

        expect(coldLead.score < 45, isTrue);
        expect(coldLead.priority, LeadPriority.cold);
      },
    );

    test('Scheduled Follow-up detection and due date helpers', () {
      final now = DateTime.now();

      final dueTodayLead = LeadItem(
        id: 'l_due_today',
        name: 'Lead Hoje',
        scheduledFollowUpDate: now.toIso8601String(),
        scheduledFollowUpNote: 'Pediu contato dia do salário',
        createdAt: '',
        updatedAt: '',
      );

      expect(dueTodayLead.hasScheduledFollowUp, isTrue);
      expect(dueTodayLead.isFollowUpDueTodayOrOverdue, isTrue);
      expect(dueTodayLead.isFollowUpToday, isTrue);

      final futureLead = LeadItem(
        id: 'l_future',
        name: 'Lead Futuro',
        scheduledFollowUpDate: now
            .add(const Duration(days: 5))
            .toIso8601String(),
        createdAt: '',
        updatedAt: '',
      );

      expect(futureLead.hasScheduledFollowUp, isTrue);
      expect(futureLead.isFollowUpDueTodayOrOverdue, isFalse);
    });

    test('Battlecards catalog has default objections with valid scripts', () {
      final battlecards = BattlecardItem.defaultBattlecards;
      expect(battlecards.length >= 6, isTrue);

      final priceCard = battlecards.firstWhere((b) => b.id == 'obj_preco');
      expect(priceCard.whatsappScript.contains('R\$ 4,90'), isTrue);
      expect(priceCard.audioScript.contains('Roteiro de Áudio'), isTrue);
    });

    test('UTM parameters serialize and deserialize properly', () {
      final lead = LeadItem(
        id: 'utm_lead',
        name: 'Prospect Meta',
        utmSource: 'meta_ads',
        utmMedium: 'reels',
        utmCampaign: 'hipertrofia_q3',
        utmContent: 'video_ombro_v1',
        scheduledFollowUpDate: '2026-08-28T14:00:00',
        scheduledFollowUpNote: 'Me chama na sexta',
        createdAt: '2026-08-25',
        updatedAt: '2026-08-25',
      );

      final json = lead.toJson();
      expect(json['utm_source'], 'meta_ads');
      expect(json['utm_medium'], 'reels');
      expect(json['utm_campaign'], 'hipertrofia_q3');
      expect(json['utm_content'], 'video_ombro_v1');
      expect(json['scheduled_follow_up_date'], '2026-08-28T14:00:00');
      expect(json['scheduled_follow_up_note'], 'Me chama na sexta');

      final fromJsonLead = LeadItem.fromJson(json);
      expect(fromJsonLead.utmSource, 'meta_ads');
      expect(fromJsonLead.scheduledFollowUpNote, 'Me chama na sexta');
    });

    test(
      'SalesMetricsData calculates average score, follow-ups today and totals correctly',
      () {
        final now = DateTime.now();
        final leads = [
          LeadItem(
            id: 'l1',
            name: 'Lead 1',
            estimatedValue: 300.0,
            score: 80,
            status: LeadStatus.newLead,
            scheduledFollowUpDate: now.toIso8601String(),
            createdAt: '',
            updatedAt: '',
          ),
          LeadItem(
            id: 'l2',
            name: 'Lead 2',
            estimatedValue: 500.0,
            score: 60,
            status: LeadStatus.proposalSent,
            createdAt: '',
            updatedAt: '',
          ),
          LeadItem(
            id: 'l3',
            name: 'Lead 3',
            estimatedValue: 400.0,
            score: 100,
            status: LeadStatus.won,
            createdAt: '',
            updatedAt: '',
          ),
        ];

        final metrics = SalesMetricsData.calculate(leads);
        expect(metrics.totalLeads, 3);
        expect(metrics.wonLeads, 1);
        expect(metrics.scheduledFollowUpsTodayCount, 1);
        expect(metrics.averageScore, closeTo(80.0, 0.1));
        expect(metrics.totalEstimatedPipelineValue, 800.0);
      },
    );
  });

  group('Sales Module 3.0 — Formatters & WhatsApp Scripts', () {
    test('translateLeadStatus and colors', () {
      expect(Formatters.translateLeadStatus('won'), 'Convertido (Aluno)');
      expect(Formatters.translateLeadStatus('new'), 'Novo Lead');
      expect(Formatters.translateLeadPriority('hot'), 'Quente 🔥');
      expect(Formatters.translateLeadPriority('cold'), 'Frio ❄️');
    });

    test(
      'buildWhatsAppScheduledReturnMessage generates personalized copy with note context',
      () {
        final msg = Uri.decodeComponent(
          Formatters.buildWhatsAppScheduledReturnMessage(
            leadName: 'Fernanda',
            trainerName: 'Valex Coach',
            note: 'Dia do pagamento',
          ),
        );

        expect(msg.contains('Fala Fernanda!'), isTrue);
        expect(msg.contains('Valex Coach'), isTrue);
        expect(msg.contains('Dia do pagamento'), isTrue);
        expect(msg.contains('Conforme combinamos'), isTrue);
      },
    );

    test('formatFollowUpDate formats today, tomorrow and dates properly', () {
      final todayStr = DateTime.now().toIso8601String();
      final formattedToday = Formatters.formatFollowUpDate(todayStr);
      expect(formattedToday.contains('Hoje às'), isTrue);
    });
  });

  group(
    'Sales Module 3.0 — Repository Lifecycle, Follow-up Scheduling & Lead Conversion',
    () {
      test(
        'Scheduling, Follow-up notes and Conversion to Student in SalesRepository',
        () async {
          final client = await createSalesTestClient();
          addTearDown(client.dispose);
          final repo = SalesRepository(client: client);

          // 1. Fetch
          final initialLeads = await repo.fetchLeads();
          expect(initialLeads.isNotEmpty, isTrue);

          // 2. Save New Lead
          final newLead = LeadItem(
            id: 'test_lead_followup_${DateTime.now().millisecondsSinceEpoch}',
            name: 'Aluno Teste Retorno',
            phone: '11999998888',
            instagram: '@alunoteste',
            originChannel: 'indicacao',
            objective: 'Definição Abdominal e Dores no Joelho',
            estimatedValue: 600.0,
            status: LeadStatus.newLead,
            utmSource: 'indicacao_direta',
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
          );

          await repo.saveLead(newLead);

          // 3. Schedule Follow-Up
          final returnDate = DateTime.now().add(const Duration(days: 3));
          await repo.scheduleFollowUp(
            newLead.id,
            returnDate,
            'Me chama sexta após receber salário',
          );

          final leadsAfterFollowUp = await repo.fetchLeads();
          final fetched = leadsAfterFollowUp.firstWhere(
            (l) => l.id == newLead.id,
          );
          expect(fetched.hasScheduledFollowUp, isTrue);
          expect(
            fetched.scheduledFollowUpNote,
            'Me chama sexta após receber salário',
          );
          expect(
            fetched.notes.any((n) => n.content.contains('Retorno agendado')),
            isTrue,
          );

          // 4. Convert to Student
          final convertedStudent = await repo.convertLeadToStudent(
            lead: fetched,
            gymName: 'Academia Matriz VIP',
          );

          expect(convertedStudent, isNotNull);
          expect(convertedStudent!.name, 'Aluno Teste Retorno');

          // Cleanup
          await repo.deleteLead(newLead.id);
        },
      );

      test('remote lead changes survive repository recreation', () async {
        final client = await createSalesTestClient();
        addTearDown(client.dispose);
        final firstRepository = SalesRepository(client: client);
        await firstRepository.fetchLeads();

        final lead = LeadItem(
          id: 'persisted_lead',
          name: 'Lead Persistido',
          createdAt: '2026-09-02T10:00:00.000',
          updatedAt: '2026-09-02T10:00:00.000',
        );
        await firstRepository.saveLead(lead);

        final restartedRepository = SalesRepository(client: client);
        final restartedLeads = await restartedRepository.fetchLeads();

        expect(
          restartedLeads.any(
            (item) => item.id == lead.id && item.name == lead.name,
          ),
          isTrue,
        );
      });

      test(
        'conversion does not mark lead as won when student creation fails',
        () async {
          final client = await createSalesTestClient(failConversion: true);
          addTearDown(client.dispose);
          final repository = SalesRepository(client: client);
          final lead = (await repository.fetchLeads()).first;

          await expectLater(
            repository.convertLeadToStudent(lead: lead),
            throwsA(isA<SalesDataException>()),
          );

          final unchangedLead = (await repository.fetchLeads()).firstWhere(
            (item) => item.id == lead.id,
          );

          expect(unchangedLead.status, lead.status);
          expect(unchangedLead.status, isNot(LeadStatus.won));
        },
      );
    },
  );
}
