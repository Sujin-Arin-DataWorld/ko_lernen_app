import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_store.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });
  test(
    'strict preference boundary survives reinitialization and resets',
    () async {
      final sessions = CloudWriteSessionController()..acquire('boundary-owner');
      await DancheongStore(sessions: sessions).saveCaption('de', 'Grüße');
      Storage.resetForTesting();
      await Storage.init();
      expect(
        DancheongStore(sessions: sessions).currentOwner().captions['de'],
        'Grüße',
      );
      await Storage.resetAllStrict();
      expect(Storage.dancheongStudioRawJson, isEmpty);
      expect(
        (await SharedPreferences.getInstance()).containsKey(
          Storage.dancheongStudioPreferenceKey,
        ),
        isFalse,
      );
    },
  );
  test(
    'strict setter refuses an invalidated operation before persistence',
    () async {
      await expectLater(
        Storage.setDancheongStudioRawJsonStrict(
          'blocked',
          assertCurrentWrite: () => throw StateError('stale'),
        ),
        throwsStateError,
      );
      expect(Storage.dancheongStudioRawJson, isEmpty);
    },
  );
}
