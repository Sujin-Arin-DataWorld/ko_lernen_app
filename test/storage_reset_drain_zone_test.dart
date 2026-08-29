import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('reset drain zone isolation', () {
    setUp(() {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues(const <String, Object>{
        'kl_consent_accepted': true,
      });
    });

    testWidgets(
      'an idle reset reinitializes mock preferences in a later widget zone',
      (_) async {
        await Storage.init();

        expect(Storage.consentAccepted, isTrue);
      },
    );
  });

  group('completed active drain zone isolation', () {
    setUp(() async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      await Storage.init();
      final store = _DelayedStringStore();
      Storage.setSrsPersistenceStoreForTesting(store);
      final oldReview = Storage.srsReview('old-generation', gotIt: true);
      await store.setStarted.future;

      Storage.resetForTesting();
      store.releaseSet.complete();
      expect(await oldReview, isFalse);
      SharedPreferences.setMockInitialValues(const <String, Object>{
        'kl_consent_accepted': true,
      });
    });

    testWidgets(
      'a completed active drain reinitializes preferences in the next widget zone',
      (_) async {
        await Storage.init();

        expect(Storage.consentAccepted, isTrue);
      },
    );
  });
}

class _DelayedStringStore implements PreferenceStringStore {
  final Completer<void> setStarted = Completer<void>();
  final Completer<void> releaseSet = Completer<void>();
  String? value;

  @override
  bool containsKey(String key) => value != null;

  @override
  String? getString(String key) => value;

  @override
  Future<void> reload() async {}

  @override
  Future<bool> remove(String key) async {
    value = null;
    return true;
  }

  @override
  Future<bool> setString(String key, String nextValue) async {
    setStarted.complete();
    await releaseSet.future;
    value = nextValue;
    return true;
  }
}
