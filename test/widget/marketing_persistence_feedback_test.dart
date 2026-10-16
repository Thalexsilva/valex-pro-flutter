import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valex_app/models/marketing_models.dart';
import 'package:valex_app/repositories/marketing_repository.dart';
import 'package:valex_app/views/marketing/marketing_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'falha de escrita de campanha não altera cache nem confirma gravação',
    () async {
      final repository = MarketingRepository(
        accountId: () => 'teste',
        campaignWriter: (_, _) async => false,
      );
      final campaign = MarketingCampaign(
        id: 'camp-1',
        name: 'Teste',
        utmCampaign: 'teste',
        createdAt: '2026-10-09',
        updatedAt: '2026-10-09',
      );

      await expectLater(repository.saveCampaign(campaign), throwsStateError);
      expect(await repository.getCampaigns(), isEmpty);
      expect(
        await MarketingRepository(accountId: () => 'teste').getCampaigns(),
        isEmpty,
      );
    },
  );

  testWidgets('checklist reverte marcação quando persistência falha', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FailingChecklistRepository();
    await tester.pumpWidget(
      MaterialApp(home: MarketingView(repository: repository)),
    );
    await tester.pumpAndSettle();

    const initial = '0 de 4 feitas nesta semana.';
    final task = find.textContaining('Grave 1 vídeo de 30s');
    expect(find.textContaining(initial), findsOneWidget);
    await tester.ensureVisible(task);
    await tester.tap(task);
    await tester.pumpAndSettle();

    expect(repository.saveCalls, 1);
    expect(find.textContaining(initial), findsOneWidget);
    expect(
      find.textContaining('Não foi possível guardar o checklist'),
      findsOneWidget,
    );
  });

  testWidgets('falha de leitura oferece nova tentativa', (tester) async {
    final repository = _RetryLoadingRepository();
    await tester.pumpWidget(
      MaterialApp(home: MarketingView(repository: repository)),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Não foi possível carregar as divulgações.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(repository.loadCalls, 2);
    expect(find.text('Atrair novos alunos'), findsOneWidget);
  });
}

class _RetryLoadingRepository extends _FailingChecklistRepository {
  int loadCalls = 0;

  @override
  Future<List<MarketingCampaign>> getCampaigns() async {
    loadCalls++;
    if (loadCalls == 1) throw StateError('falha de leitura');
    return [];
  }
}

class _FailingChecklistRepository extends MarketingRepository {
  int saveCalls = 0;

  @override
  Future<List<MarketingCampaign>> getCampaigns() async => [];

  @override
  Future<List<AdCreativeItem>> getCreatives() async =>
      AdCreativeItem.defaultCreatives;

  @override
  Future<MarketingMetricsSummary> getMetricsSummary() async =>
      MarketingMetricsSummary();

  @override
  Future<Set<int>> getWeeklyChecklist(DateTime now) async => {};

  @override
  Future<bool> saveWeeklyChecklist(DateTime now, Set<int> done) async {
    saveCalls++;
    return false;
  }
}
