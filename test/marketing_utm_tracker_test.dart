import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/models/marketing_models.dart';
import 'package:valex_app/views/marketing/utm_generator_sheet.dart';

void main() {
  group('UtmTrackerData', () {
    const tracker = UtmTrackerData(
      source: 'meta',
      medium: 'reels',
      campaign: 'hipertrofia_tofu_2026',
      content: 'video_hook_v1',
      term: 'dor no ombro',
    );

    test('preserva campanha e criativo com underscores no WhatsApp', () {
      final url = tracker.buildWhatsAppUrl(
        '+55 (11) 98765-4321',
        defaultGreeting: 'Quero saber mais.',
      );
      final uri = Uri.parse(url);
      final message = uri.queryParameters['text'];

      expect(uri.host, 'wa.me');
      expect(uri.path, '/5511987654321');
      expect(message, isNotNull);
      expect(message, contains('[Ref: utm_source=meta'));
      expect(UtmTrackerData.parseFromWhatsAppMessage(message!), {
        'utm_source': 'meta',
        'utm_medium': 'reels',
        'utm_campaign': 'hipertrofia_tofu_2026',
        'utm_content': 'video_hook_v1',
        'utm_term': 'dor no ombro',
      });
    });

    test('mantém parâmetros e fragmento de uma página existente', () {
      final url = tracker.buildLandingPageUrl(
        'https://valex.app/anamnese?student=42#inicio',
      );
      final uri = Uri.parse(url);

      expect(uri.fragment, 'inicio');
      expect(uri.queryParameters['student'], '42');
      expect(uri.queryParameters['utm_campaign'], 'hipertrofia_tofu_2026');
      expect(uri.queryParameters['utm_content'], 'video_hook_v1');
    });

    test('continua lendo etiquetas legadas já publicadas', () {
      expect(
        UtmTrackerData.parseFromWhatsAppMessage(
          'Olá!\n\n[Ref: META_REELS_ESTAGNACAO_2026]',
        ),
        {
          'utm_source': 'meta',
          'utm_medium': 'reels',
          'utm_campaign': 'estagnacao_2026',
        },
      );
    });

    test('rejeita etiqueta estruturada sem campanha', () {
      expect(
        UtmTrackerData.parseFromWhatsAppMessage(
          '[Ref: utm_source=meta&utm_medium=reels]',
        ),
        isNull,
      );
    });
  });

  testWidgets('gerador abre na campanha solicitada e atualiza a prévia', (
    tester,
  ) async {
    final now = DateTime(2026, 9, 2).toIso8601String();
    final campaigns = [
      MarketingCampaign(
        id: '1',
        name: 'Campanha A',
        utmCampaign: 'campanha_a',
        createdAt: now,
        updatedAt: now,
      ),
      MarketingCampaign(
        id: '2',
        name: 'Campanha B',
        utmCampaign: 'campanha_b',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UtmGeneratorSheet(
            availableCampaigns: campaigns,
            initialCampaignTag: 'campanha_b',
          ),
        ),
      ),
    );

    expect(find.text('Campanha B'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SelectableText &&
            (widget.data?.contains('utm_campaign%3Dcampanha_b') ?? false),
      ),
      findsOneWidget,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Identificador do Vídeo'),
      'criativo_novo_v2',
    );
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SelectableText &&
            (widget.data?.contains('utm_content%3Dcriativo_novo_v2') ?? false),
      ),
      findsOneWidget,
    );
  });
}
