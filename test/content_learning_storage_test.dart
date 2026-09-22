import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';

class _Store implements PreferenceStringStore {
  _Store(this.prefs);
  final SharedPreferences prefs;
  bool reject = false;
  Completer<void>? release;
  Completer<void>? entered;
  @override
  bool containsKey(String key) => prefs.containsKey(key);
  @override
  String? getString(String key) => prefs.getString(key);
  @override
  Future<void> reload() => prefs.reload();
  @override
  Future<bool> remove(String key) => prefs.remove(key);
  @override
  Future<bool> setString(String key, String value) async {
    entered?.complete();
    if (release case final wait?) {
      await wait.future;
    }
    if (reject) {
      return false;
    }
    return prefs.setString(key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Store store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
    store = _Store(await SharedPreferences.getInstance());
  });
  test('rejected durable write keeps confirmed state and retries', () async {
    await Storage.mutateContentLearning((_) => 'before', preferences: store);
    store.reject = true;
    await expectLater(
      Storage.mutateContentLearning((_) => 'after', preferences: store),
      throwsA(isA<PreferenceWriteException>()),
    );
    expect(Storage.contentLearningRawJson, 'before');
    store.reject = false;
    await Storage.mutateContentLearning((before) {
      expect(before, 'before');
      return 'after';
    }, preferences: store);
    expect(Storage.contentLearningRawJson, 'after');
  });
  test(
    'read never exposes unconfirmed native write, reset drains and erases it',
    () async {
      await Storage.mutateContentLearning((_) => 'before', preferences: store);
      store.release = Completer<void>();
      store.entered = Completer<void>();
      final pending = Storage.mutateContentLearning(
        (_) => 'after',
        preferences: store,
      );
      await store.entered!.future;
      expect(Storage.contentLearningRawJson, 'before');
      final reset = Storage.resetAllStrict();
      await expectLater(
        Storage.mutateContentLearning((_) => 'late'),
        throwsA(isA<StaleLocalDataLifetimeException>()),
      );
      store.release!.complete();
      await pending;
      await reset;
      expect(Storage.contentLearningRawJson, isEmpty);
      expect(store.containsKey(Storage.contentLearningPreferenceKey), isFalse);
    },
  );
  test('restore guard rechecks before persisted mutation', () async {
    final lease = LocalDataLifetime.capture();
    LocalDataLifetime.invalidate();
    await expectLater(
      Storage.mutateContentLearning(
        (_) => 'stale',
        assertCurrentWrite: lease.assertCurrent,
      ),
      throwsA(isA<StaleLocalDataLifetimeException>()),
    );
    expect(Storage.contentLearningRawJson, isEmpty);
  });
}
