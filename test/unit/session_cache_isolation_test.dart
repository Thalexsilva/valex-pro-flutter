import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valex_app/models/student_model.dart';
import 'package:valex_app/repositories/marketing_repository.dart';
import 'package:valex_app/models/marketing_models.dart';
import 'package:valex_app/services/student_context_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'student context keeps each authenticated account in its own cache',
    () async {
      final accountA = StudentContextService.forTesting(
        accountId: () => 'account-a',
      );
      await accountA.init();
      accountA.addOrUpdateStudent(
        Student(id: 'student-a', name: 'Aluno da conta A'),
      );
      await accountA.persistToDisk();

      final accountB = StudentContextService.forTesting(
        accountId: () => 'account-b',
      );
      await accountB.init();
      expect(accountB.allStudents, isEmpty);
      accountB.addOrUpdateStudent(
        Student(id: 'student-b', name: 'Aluno da conta B'),
      );
      await accountB.persistToDisk();

      final reloadedA = StudentContextService.forTesting(
        accountId: () => 'account-a',
      );
      await reloadedA.init();
      expect(reloadedA.allStudents.map((student) => student.id), ['student-a']);

      await reloadedA.clearCurrentAccountCache();
      final reloadedB = StudentContextService.forTesting(
        accountId: () => 'account-b',
      );
      await reloadedB.init();
      expect(reloadedB.allStudents.map((student) => student.id), ['student-b']);
    },
  );

  test(
    'marketing cache changes namespace when the signed-in account changes',
    () async {
      var account = 'account-a';
      final repository = MarketingRepository(accountId: () => account);
      expect(await repository.getCampaigns(), isEmpty);
      await repository.saveCampaign(
        MarketingCampaign(
          id: 'private-a',
          utmCampaign: 'private_a',
          name: 'Campanha privada da conta A',
          createdAt: '2026-09-20',
          updatedAt: '2026-09-20',
        ),
      );

      account = 'account-b';
      final campaignsB = await repository.getCampaigns();
      expect(campaignsB, isEmpty);

      account = 'account-a';
      final reloadedA = await repository.getCampaigns();
      expect(reloadedA.first.name, 'Campanha privada da conta A');
    },
  );
}
