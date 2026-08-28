import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/storage_service.dart';

String _dateIso(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(Storage.unlockLearningWrites);

  test(
    'srsReview writes a judged id to today\'s dedicated ledger key',
    () async {
      await Storage.init();

      await Storage.srsReview('단어1', gotIt: true);

      final today = Storage.todayIso();
      final prefs = await SharedPreferences.getInstance();
      expect(Storage.studyLogIdsFor(today), ['단어1']);
      expect(prefs.getStringList('kl_study_log_v1_$today'), ['단어1']);
    },
  );

  test('repeated judgments leave one id in today\'s ledger', () async {
    await Storage.init();

    await Storage.srsReview('단어1', gotIt: true);
    await Storage.srsReview('단어1', gotIt: false);

    expect(Storage.studyLogIdsFor(Storage.todayIso()), ['단어1']);
  });

  test(
    'recordToStudyLog false leaves an automatic failure out of the ledger',
    () async {
      await Storage.init();

      await Storage.srsReview('자동오답단어', gotIt: false, recordToStudyLog: false);

      expect(Storage.studyLogIdsFor(Storage.todayIso()), isEmpty);
    },
  );

  test('studyLogDates returns only dates with ledger entries', () async {
    await Storage.init();
    expect(Storage.studyLogDates(), isEmpty);

    await Storage.srsReview('단어1', gotIt: true);

    expect(Storage.studyLogDates(), [Storage.todayIso()]);
  });

  test(
    'init preserves old ledger entries until post-migration pruning runs',
    () async {
      final now = DateTime.now();
      final old = _dateIso(now.subtract(const Duration(days: 61)));
      final boundary = _dateIso(now.subtract(const Duration(days: 60)));
      final recent = _dateIso(now.subtract(const Duration(days: 1)));
      SharedPreferences.setMockInitialValues({
        'kl_study_log_v1_$old': ['old'],
        'kl_study_log_v1_$boundary': ['boundary'],
        'kl_study_log_v1_$recent': ['recent'],
      });

      await Storage.init();

      expect(Storage.studyLogDates(), [old, boundary, recent]);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('kl_study_log_v1_$old'), ['old']);
    },
  );

  test('pruneStudyLog honors keepDays using calendar dates', () async {
    await Storage.init();
    final now = DateTime.now();
    final old = _dateIso(now.subtract(const Duration(days: 3)));
    final boundary = _dateIso(now.subtract(const Duration(days: 2)));
    final recent = _dateIso(now.subtract(const Duration(days: 1)));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('kl_study_log_v1_$old', ['old']);
    await prefs.setStringList('kl_study_log_v1_$boundary', ['boundary']);
    await prefs.setStringList('kl_study_log_v1_$recent', ['recent']);

    await Storage.pruneStudyLog(keepDays: 2);

    expect(Storage.studyLogDates(), [boundary, recent]);
  });

  test('today\'s ledger caps distinct judged ids at 500', () async {
    await Storage.init();

    for (var index = 0; index < 501; index++) {
      await Storage.srsReview('단어$index', gotIt: true);
    }

    final ids = Storage.studyLogIdsFor(Storage.todayIso());
    expect(ids, hasLength(500));
    expect(ids, contains('단어0'));
    expect(ids, isNot(contains('단어500')));
  });

  test('a global learning-write lock also prevents ledger writes', () async {
    await Storage.init();
    Storage.lockLearningWrites('test lock');

    await Storage.srsReview('잠긴단어', gotIt: true);

    expect(Storage.studyLogIdsFor(Storage.todayIso()), isEmpty);
  });

  test(
    'a quarantined SRS write does not create a daily ledger entry',
    () async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({'kl_srs_v1': '{broken'});
      await Storage.init();

      await Storage.srsReview('격리단어', gotIt: true);

      expect(Storage.srsIsQuarantined, isTrue);
      expect(Storage.studyLogIdsFor(Storage.todayIso()), isEmpty);
    },
  );

  test('a rejected SRS setter leaves no daily ledger entry', () async {
    await Storage.init();
    Storage.setSrsPersistenceStoreForTesting(_RejectingStringStore());

    await expectLater(
      Storage.srsReview('저장실패', gotIt: true),
      throwsA(isA<PreferenceWriteException>()),
    );

    expect(Storage.studyLogIdsFor(Storage.todayIso()), isEmpty);
  });

  test(
    'a rejected daily ledger setter is observable after SRS persists',
    () async {
      await Storage.init();
      Storage.setStudyLogStoreForTesting(_RejectingStringListStore());

      await expectLater(
        Storage.srsReview('원장실패', gotIt: true),
        throwsA(isA<PreferenceWriteException>()),
      );

      expect(Storage.srsRawJson, contains('원장실패'));
      expect(Storage.studyLogIdsFor(Storage.todayIso()), isEmpty);
    },
  );

  test(
    'studyLogDates hides malformed dates but preserves their recovery key',
    () async {
      await Storage.init();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('kl_study_log_v1_not-a-date', ['recover-me']);

      expect(Storage.studyLogDates(), isEmpty);
      expect(prefs.getStringList('kl_study_log_v1_not-a-date'), ['recover-me']);
    },
  );

  test('startup pruning is migration-gated and best effort in main', () {
    final source = File('lib/main.dart').readAsStringSync();
    final migration = source.indexOf(
      'migration = await DataMigrationService.run()',
    );
    final prune = source.indexOf('await Storage.pruneStudyLog()');
    final gate = source.lastIndexOf(
      'if (migration?.writesAllowed == true)',
      prune,
    );

    expect(migration, greaterThanOrEqualTo(0));
    expect(prune, greaterThan(migration));
    expect(gate, greaterThan(migration));
    final guardedPrune = source.substring(
      gate,
      source.indexOf('final streakBefore', gate),
    );
    expect(guardedPrune, contains('try {'));
    expect(guardedPrune, contains('catch (error)'));
  });
}

class _RejectingStringStore implements PreferenceStringStore {
  @override
  bool containsKey(String key) => false;

  @override
  String? getString(String key) => null;

  @override
  Future<void> reload() async {}

  @override
  Future<bool> remove(String key) async => false;

  @override
  Future<bool> setString(String key, String value) async => false;
}

class _RejectingStringListStore implements PreferenceStringListStore {
  @override
  bool containsKey(String key) => false;

  @override
  List<String>? getStringList(String key) => null;

  @override
  Future<void> reload() async {}

  @override
  Future<bool> remove(String key) async => false;

  @override
  Future<bool> setStringList(String key, List<String> value) async => false;
}
