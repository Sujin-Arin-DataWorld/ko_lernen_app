import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/models/practice_history.dart';
import 'package:ko_lernen_app/services/practice_history_store.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/account/account_reconciliation.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';

class _Store implements PreferenceStringStore {
  _Store(this.prefs);
  final SharedPreferences prefs;
  bool reject = false;
  Completer<void>? entered;
  Completer<void>? release;
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
    if (release != null) {
      await release!.future;
    }
    return reject ? false : prefs.setString(key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final time = DateTime.utc(2026, 10, 3);
  PracticeAttempt attempt(String id, {bool assisted = false}) =>
      PracticeAttempt(
        id: id,
        at: time,
        variant: 'transfer',
        completed: true,
        hints: assisted ? {'expression': 1} : const {},
        expressionId: 'accept',
      );
  const source = PracticeSource(
    kind: PracticeKind.smalltalk,
    id: 'invite_friend',
    level: 'a1',
    revision: 1,
  );
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
  });
  test('A to B to A never revives an old practice session', () async {
    cloudWriteSessionController.acquire('a');
    final old = PracticeHistoryStore.session();
    cloudWriteSessionController.acquire('b');
    cloudWriteSessionController.acquire('a');
    await expectLater(
      PracticeHistoryStore.recordAttempt(
        source,
        attempt('old-account'),
        session: old,
      ),
      throwsA(isA<StaleLocalDataLifetimeException>()),
    );
    expect(PracticeHistoryStore.load().items, isEmpty);
    cloudWriteSessionController.clear();
  });
  test('corrupt practice backup is rejected before XP restore', () async {
    await expectLater(
      CloudSync.applyRestorePayload({
        'progress': {'xp': 900},
        'hanok_practice_json': 'broken',
      }),
      throwsFormatException,
    );
    expect(Storage.xp, 0);
  });
  test(
    'viewed and assisted cannot erase independent completion; retry is idempotent',
    () async {
      final lease = PracticeHistoryStore.session();
      await PracticeHistoryStore.recordAttempt(
        source,
        attempt('solo'),
        session: lease,
      );
      await PracticeHistoryStore.recordAttempt(
        source,
        attempt('hint', assisted: true),
        session: lease,
      );
      await PracticeHistoryStore.recordViewed(
        source,
        at: time.add(const Duration(days: 1)),
        session: lease,
      );
      final raw = Storage.hanokPracticeRawJson;
      await PracticeHistoryStore.recordAttempt(
        source,
        attempt('hint', assisted: true),
        session: lease,
      );
      expect(Storage.hanokPracticeRawJson, raw);
      final item = PracticeHistoryStore.load().items.single;
      expect(item.independent!.id, 'solo');
      expect(item.assisted!.id, 'hint');
      expect(item.viewedAt, time.add(const Duration(days: 1)));
    },
  );
  test(
    'merge is commutative, idempotent and keeps both kinds of evidence',
    () async {
      await PracticeHistoryStore.recordAttempt(source, attempt('solo'));
      final local = Storage.hanokPracticeRawJson;
      await Storage.resetAllStrict();
      await PracticeHistoryStore.recordAttempt(
        source,
        attempt('hint', assisted: true),
      );
      final remote = Storage.hanokPracticeRawJson;
      final merged = PracticeHistory.mergeJson(local, remote);
      expect(merged, PracticeHistory.mergeJson(remote, local));
      expect(merged, PracticeHistory.mergeJson(merged, local));
      expect(
        PracticeHistory.decode(merged).items.single.independent!.id,
        'solo',
      );
    },
  );
  test(
    'rejects corrupt and future records without replacing confirmed history',
    () async {
      await PracticeHistoryStore.recordAttempt(source, attempt('solo'));
      final before = Storage.hanokPracticeRawJson;
      await expectLater(
        PracticeHistoryStore.mergeCloudJson('{"version":2,"items":{}}'),
        throwsFormatException,
      );
      await expectLater(
        PracticeHistoryStore.mergeCloudJson('{broken'),
        throwsFormatException,
      );
      expect(Storage.hanokPracticeRawJson, before);
    },
  );
  test(
    'failed write is not exposed and retry preserves the same attempt',
    () async {
      final store = _Store(await SharedPreferences.getInstance())
        ..reject = true;
      final value = attempt('stable');
      await expectLater(
        PracticeHistoryStore.recordAttempt(source, value, preferences: store),
        throwsA(isA<PreferenceWriteException>()),
      );
      expect(PracticeHistoryStore.load().items, isEmpty);
      store.reject = false;
      await PracticeHistoryStore.recordAttempt(
        source,
        value,
        preferences: store,
      );
      expect(
        PracticeHistoryStore.load().items.single.independent!.id,
        'stable',
      );
    },
  );
  test(
    'expired session and queued reset cannot repopulate another lifetime',
    () async {
      final old = PracticeHistoryStore.session();
      LocalDataLifetime.invalidate();
      await expectLater(
        PracticeHistoryStore.recordAttempt(
          source,
          attempt('late'),
          session: old,
        ),
        throwsA(isA<StaleLocalDataLifetimeException>()),
      );
      final store = _Store(await SharedPreferences.getInstance())
        ..entered = Completer<void>()
        ..release = Completer<void>();
      final write = PracticeHistoryStore.recordAttempt(
        source,
        attempt('pending'),
        preferences: store,
      );
      await store.entered!.future;
      expect(PracticeHistoryStore.load().items, isEmpty);
      final reset = Storage.resetAllStrict();
      store.release!.complete();
      await write;
      await reset;
      expect(PracticeHistoryStore.load().items, isEmpty);
    },
  );
  test(
    'backup, old backup and account reconciliation preserve separate evidence',
    () async {
      await PracticeHistoryStore.recordAttempt(source, attempt('solo'));
      final backup = await CloudSync.buildBackupPayload();
      expect(backup['hanok_practice_json'], Storage.hanokPracticeRawJson);
      await Storage.resetAllStrict();
      await CloudSync.applyRestorePayload({});
      await PracticeHistoryStore.recordAttempt(
        source,
        attempt('hint', assisted: true),
      );
      final local = AccountReconciliationSnapshot.decodeCloudDocument({
        'hanok_practice_json': Storage.hanokPracticeRawJson,
      }).value!;
      final remote = AccountReconciliationSnapshot.decodeCloudDocument(
        backup,
      ).value!;
      final merged = AccountReconciliationMerger.merge(
        local: local,
        remote: remote,
        catalog: {},
      );
      expect(merged.conflicts, isEmpty);
      await CloudSync.applyRestorePayload(merged.merged!.toCloudDocument());
      expect(PracticeHistoryStore.load().items.single.independent!.id, 'solo');
      expect(PracticeHistoryStore.load().items.single.assisted!.id, 'hint');
      expect(
        AccountReconciliationSnapshot.decodeCloudDocument({
          'hanok_practice_json': 'broken',
        }).isPresent,
        isFalse,
      );
    },
  );
}
