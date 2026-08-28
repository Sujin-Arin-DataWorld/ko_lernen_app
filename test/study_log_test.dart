import 'dart:async';
import 'dart:convert';

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

    var lastResult = true;
    for (var index = 0; index < 501; index++) {
      lastResult = await Storage.srsReview('단어$index', gotIt: true);
    }

    expect(lastResult, isFalse);
    final ids = Storage.studyLogIdsFor(Storage.todayIso());
    expect(ids, hasLength(500));
    expect(ids, contains('단어0'));
    expect(ids, isNot(contains('단어500')));
    expect(Storage.srsRawJson, contains('단어500'));
  });

  test('a global learning-write lock also prevents ledger writes', () async {
    await Storage.init();
    Storage.lockLearningWrites('test lock');

    final locked = await Storage.srsReview('잠긴단어', gotIt: true);

    expect(locked, isFalse);
    expect(Storage.studyLogIdsFor(Storage.todayIso()), isEmpty);

    Storage.unlockLearningWrites();
    final unlocked = await Storage.srsReview('잠금해제단어', gotIt: true);

    expect(unlocked, isTrue);
    expect(Storage.srsRawJson, isNot(contains('잠긴단어')));
    expect(Storage.srsRawJson, contains('잠금해제단어'));
    expect(Storage.studyLogIdsFor(Storage.todayIso()), ['잠금해제단어']);
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

    final persisted = await Storage.srsReview('저장실패', gotIt: true);

    expect(persisted, isFalse);
    expect(Storage.srsRawJson, isNot(contains('저장실패')));
    expect(Storage.studyLogIdsFor(Storage.todayIso()), isEmpty);
  });

  test(
    'a rejected SRS review cannot leak into a later successful review',
    () async {
      await Storage.init();
      Storage.setSrsPersistenceStoreForTesting(_RejectingStringStore());

      expect(await Storage.srsReview('거절A', gotIt: true), isFalse);

      Storage.setSrsPersistenceStoreForTesting(null);
      expect(await Storage.srsReview('성공B', gotIt: true), isTrue);

      expect(Storage.srsRawJson, isNot(contains('거절A')));
      expect(Storage.srsRawJson, contains('성공B'));
      expect(Storage.studyLogIdsFor(Storage.todayIso()), ['성공B']);
    },
  );

  test(
    'an overlapping rejected review settles before the next same-id judgment',
    () async {
      await Storage.init();
      final store = _DelayedRejectThenPersistStringStore();
      Storage.setSrsPersistenceStoreForTesting(store);

      final first = Storage.srsReview('동시단어', gotIt: true);
      await store.firstSetStarted.future;
      final second = Storage.srsReview('동시단어', gotIt: true);
      await Future<void>.delayed(Duration.zero);

      expect(store.setCalls, 1);
      store.releaseFirstSet.complete();

      expect(await first, isFalse);
      expect(await second, isTrue);
      final durable = jsonDecode(store.value!) as Map<String, dynamic>;
      expect((durable['동시단어'] as Map<String, dynamic>)['r'], 1);
      expect(Storage.srsCard('동시단어')?.reviewCount, 1);
      expect(Storage.studyLogIdsFor(Storage.todayIso()), ['동시단어']);
    },
  );

  test(
    'a lock acquired after SRS persistence returns an incomplete ledger result',
    () async {
      await Storage.init();
      Storage.setSrsPersistenceStoreForTesting(_LockingStringStore());

      final result = await Storage.srsReview('중간잠금', gotIt: true);

      expect(result, isFalse);
      expect(Storage.srsCard('중간잠금')?.reviewCount, 1);
      expect(Storage.studyLogIdsFor(Storage.todayIso()), isEmpty);
    },
  );

  test(
    'a rejected daily ledger setter is observable after SRS persists',
    () async {
      await Storage.init();
      Storage.setStudyLogStoreForTesting(_RejectingStringListStore());

      final incomplete = await Storage.srsReview('원장실패', gotIt: true);

      expect(incomplete, isFalse);
      expect(Storage.srsRawJson, contains('원장실패'));
      expect(Storage.studyLogIdsFor(Storage.todayIso()), isEmpty);

      Storage.setStudyLogStoreForTesting(null);
      final repaired = await Storage.srsReview('원장실패', gotIt: true);

      expect(repaired, isTrue);
      expect(Storage.studyLogIdsFor(Storage.todayIso()), ['원장실패']);
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

  test(
    'a canonical ledger key with a wrong value type stays recoverable and fail-soft',
    () async {
      final today = Storage.todayIso();
      final key = 'kl_study_log_v1_$today';
      SharedPreferences.setMockInitialValues({key: 'wrong-type'});
      await Storage.init();

      expect(Storage.studyLogIdsFor(today), isEmpty);
      expect(Storage.studyLogDates(), isEmpty);
      await Storage.pruneStudyLog();

      final result = await Storage.srsReview('손상원장단어', gotIt: true);
      final prefs = await SharedPreferences.getInstance();
      expect(result, isFalse);
      expect(Storage.srsRawJson, contains('손상원장단어'));
      expect(prefs.getString(key), 'wrong-type');
      expect(Storage.studyLogDates(), isEmpty);
    },
  );

  test(
    'the first same-id review after an indeterminate ledger recovery succeeds',
    () async {
      await Storage.init();
      final store = _IndeterminateThenRecoveringStringListStore();
      Storage.setStudyLogStoreForTesting(store);

      expect(await Storage.srsReview('복구원장단어', gotIt: true), isFalse);
      store.value = null;

      expect(await Storage.srsReview('복구원장단어', gotIt: true), isTrue);
      expect(store.value, ['복구원장단어']);
    },
  );

  test(
    'resetForTesting isolates a stale SRS completion from the new queue generation',
    () async {
      await Storage.init();
      final oldStore = _DelayedRejectThenPersistStringStore();
      Storage.setSrsPersistenceStoreForTesting(oldStore);
      final oldReview = Storage.srsReview('이전세대', gotIt: true);
      await oldStore.firstSetStarted.future;

      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({});
      final newInit = Storage.init();
      var newInitCompleted = false;
      newInit.then((_) => newInitCompleted = true);
      await Future<void>.delayed(Duration.zero);
      expect(newInitCompleted, isFalse);
      oldStore.releaseFirstSet.complete();
      expect(await oldReview, isFalse);
      await newInit;
      final newStore = _DelayedPersistStringStore();
      Storage.setSrsPersistenceStoreForTesting(newStore);
      final firstNewReview = Storage.srsReview('새세대B', gotIt: true);
      await newStore.firstSetStarted.future;

      final secondNewReview = Storage.srsReview('새세대C', gotIt: true);
      await Future<void>.delayed(Duration.zero);
      expect(newStore.setCalls, 1);

      newStore.releaseFirstSet.complete();
      expect(await firstNewReview, isTrue);
      expect(await secondNewReview, isTrue);
      expect(Storage.srsReviewedIds, {'새세대B', '새세대C'});
    },
  );

  test(
    'resetForTesting removes a successful stale primary write without overwriting a new review',
    () async {
      await Storage.init();
      final oldStore = _DelayedSuccessIntoCurrentPreferencesStore();
      Storage.setSrsPersistenceStoreForTesting(oldStore);
      final oldReview = Storage.srsReview('이전성공A', gotIt: true);
      await oldStore.firstSetStarted.future;

      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({});
      final newInit = Storage.init();
      await Future<void>.delayed(Duration.zero);
      oldStore.releaseFirstSet.complete();
      expect(await oldReview, isFalse);
      await newInit;

      final newReview = await Storage.srsReview('새성공B', gotIt: true);
      expect(newReview, isTrue);

      expect(Storage.srsRawJson, isNot(contains('이전성공A')));
      expect(Storage.srsRawJson, contains('새성공B'));
      expect(Storage.studyLogIdsFor(Storage.todayIso()), ['새성공B']);
    },
  );
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

class _DelayedRejectThenPersistStringStore implements PreferenceStringStore {
  final Completer<void> firstSetStarted = Completer<void>();
  final Completer<void> releaseFirstSet = Completer<void>();
  String? value;
  var setCalls = 0;

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
    setCalls++;
    if (setCalls == 1) {
      firstSetStarted.complete();
      await releaseFirstSet.future;
      return false;
    }
    value = nextValue;
    return true;
  }
}

class _DelayedSuccessIntoCurrentPreferencesStore
    implements PreferenceStringStore {
  final Completer<void> firstSetStarted = Completer<void>();
  final Completer<void> releaseFirstSet = Completer<void>();
  SharedPreferences? _currentPreferences;

  @override
  bool containsKey(String key) =>
      _currentPreferences?.containsKey(key) ?? false;

  @override
  String? getString(String key) => _currentPreferences?.getString(key);

  @override
  Future<void> reload() async {}

  @override
  Future<bool> remove(String key) async {
    final prefs = _currentPreferences ?? await SharedPreferences.getInstance();
    _currentPreferences = prefs;
    return prefs.remove(key);
  }

  @override
  Future<bool> setString(String key, String value) async {
    firstSetStarted.complete();
    await releaseFirstSet.future;
    final prefs = await SharedPreferences.getInstance();
    _currentPreferences = prefs;
    return prefs.setString(key, value);
  }
}

class _LockingStringStore implements PreferenceStringStore {
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
    value = nextValue;
    Storage.lockLearningWrites('test between SRS and ledger');
    return true;
  }
}

class _IndeterminateThenRecoveringStringListStore
    implements PreferenceStringListStore {
  List<String>? value;
  var setCalls = 0;

  @override
  bool containsKey(String key) => value != null;

  @override
  List<String>? getStringList(String key) => value;

  @override
  Future<void> reload() async {}

  @override
  Future<bool> remove(String key) async {
    value = null;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> nextValue) async {
    setCalls++;
    if (setCalls == 1) {
      value = ['indeterminate'];
      return false;
    }
    value = List<String>.from(nextValue);
    return true;
  }
}

class _DelayedPersistStringStore implements PreferenceStringStore {
  final Completer<void> firstSetStarted = Completer<void>();
  final Completer<void> releaseFirstSet = Completer<void>();
  String? value;
  var setCalls = 0;

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
    setCalls++;
    if (setCalls == 1) {
      firstSetStarted.complete();
      await releaseFirstSet.future;
    }
    value = nextValue;
    return true;
  }
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
