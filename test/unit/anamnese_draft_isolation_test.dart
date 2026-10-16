import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valex_app/models/anamnese_model.dart';
import 'package:valex_app/repositories/anamnese_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'drafts remain isolated across accounts and preserve identity',
    () async {
      SharedPreferences.setMockInitialValues({});
      var account = 'trainer-a';
      final repo = AnamneseRepository(accountId: () => account);
      final model = AnamneseModel(
        id: 'assessment-1',
        studentId: 'student-1',
        name: 'Test',
        weightKg: 70,
        heightCm: 170,
      );
      expect(await repo.saveLocalDraft(model), isTrue);
      expect((await repo.getLocalDraft('student-1'))?.id, 'assessment-1');
      account = 'trainer-b';
      expect(await repo.getLocalDraft('student-1'), isNull);
      await repo.clearLocalDraft('student-1');
      account = 'trainer-a';
      expect((await repo.getLocalDraft('student-1'))?.id, 'assessment-1');
    },
  );
}
