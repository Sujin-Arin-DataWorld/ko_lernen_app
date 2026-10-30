import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/yeopjeon_wallet.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/account/reconciliation_errors.dart';
import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _date = '2026-10-30';
const _studyKey = 'kl_study_log_v1_$_date';

Future<void> _initialize([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  Storage.resetForTesting();
  await Storage.init();
}

({CloudWriteSessionController sessions, CloudWriteSession session}) _owner() {
  final sessions = CloudWriteSessionController()..acquire('local-test-account');
  return (
    sessions: sessions,
    session: sessions.transition(CloudWriteMode.reconciling),
  );
}

Future<void> _apply(
  Map<String, dynamic> data,
  ({CloudWriteSessionController sessions, CloudWriteSession session}) owner, {
  void Function()? assertCurrentLocalSource,
}) => CloudSync.applyReconciledRestorePayload(
  data,
  uid: 'local-test-account',
  session: owner.session,
  sessions: owner.sessions,
  assertCurrentLocalSource: assertCurrentLocalSource,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => _initialize());
  tearDown(() => Storage.setStudyLogStoreForTesting(null));

  test(
    'committed app pair converges after interruption following native date write',
    () async {
      await _initialize({
        'kl_last_open_date': '2026-10-29',
        'kl_streak_days': 12,
        'kl_best_streak': 12,
        'kl_xp': 7,
      });
      final owner = _owner();
      final committed = <String, dynamic>{
        'app': {'last_open': '2026-10-30', 'streak_days': 2, 'best_streak': 12},
      };
      var interrupted = false;
      await expectLater(
        _apply(
          committed,
          owner,
          assertCurrentLocalSource: () {
            if (Storage.lastOpenDate == '2026-10-30' &&
                Storage.streakDays == 12) {
              interrupted = true;
              throw StateError(
                'Injected interruption after native date write.',
              );
            }
          },
        ),
        throwsStateError,
      );
      expect(interrupted, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('kl_last_open_date'), '2026-10-30');
      expect(prefs.getInt('kl_streak_days'), 12);
      for (var attempt = 0; attempt < 2; attempt++) {
        await _apply(committed, owner);
        expect(Storage.lastOpenDate, '2026-10-30');
        expect(Storage.streakDays, 2);
        expect(prefs.getInt('kl_streak_days'), 2);
        expect(Storage.bestStreak, 12);
        expect(Storage.xp, 7);
      }
    },
  );

  test(
    'ordinary app restore retains the larger same-date current streak',
    () async {
      await _initialize({
        'kl_last_open_date': '2026-10-30',
        'kl_streak_days': 12,
        'kl_best_streak': 12,
      });
      await CloudSync.applyRestorePayload({
        'app': {'last_open': '2026-10-30', 'streak_days': 2, 'best_streak': 12},
      });
      expect(Storage.lastOpenDate, '2026-10-30');
      expect(Storage.streakDays, 12);
      expect(Storage.bestStreak, 12);
    },
  );

  for (final invalid in <Map<String, dynamic>>[
    {'last_open': '2026-02-30', 'streak_days': 2},
    {'last_open': '2026-10-3', 'streak_days': 2},
    {'last_open': '', 'streak_days': 2},
    {'last_open': '2026-10-30', 'streak_days': -1},
    {'last_open': '2026-10-30', 'streak_days': 2.0},
    {'last_open': '2026-10-30'},
    {'streak_days': 2},
  ]) {
    test(
      'invalid committed app pair fails before unrelated native writes: $invalid',
      () async {
        await _initialize({'kl_xp': 7, 'kl_best_streak': 12});
        await expectLater(
          _apply({
            'app': {...invalid, 'best_streak': 99},
            'vok': {'correct': 99},
            'progress': {'xp': 99},
          }, _owner()),
          throwsFormatException,
        );
        expect(Storage.xp, 7);
        expect(Storage.vokCorrect, 0);
        expect(Storage.bestStreak, 12);
        expect(Storage.lastOpenDate, '');
        expect(Storage.streakDays, 0);
      },
    );
  }

  test(
    'committed reset-empty app pair is a valid idempotent zero baseline',
    () async {
      final owner = _owner();
      for (var attempt = 0; attempt < 2; attempt++) {
        await _apply({
          'app': {'last_open': '', 'streak_days': 0},
        }, owner);
        expect(Storage.lastOpenDate, '');
        expect(Storage.streakDays, 0);
        expect(Storage.xp, 0);
      }
    },
  );

  for (final newUser in [false, true]) {
    test(
      'partial native app pair cannot cross source/new-user fence: newUser=$newUser',
      () async {
        await _initialize({
          'kl_last_open_date': '2026-10-29',
          'kl_streak_days': 12,
          'kl_best_streak': 12,
          'kl_xp': 7,
        });
        final owner = _owner();
        var fenceReached = false;
        await expectLater(
          _apply(
            {
              'app': {
                'last_open': '2026-10-30',
                'streak_days': 2,
                'best_streak': 12,
              },
              'progress': {'xp': 99},
            },
            owner,
            assertCurrentLocalSource: () {
              if (Storage.lastOpenDate != '2026-10-30') {
                return;
              }
              fenceReached = true;
              if (newUser) {
                owner.sessions.acquire('other-local-account');
              } else {
                throw const LocalReconciliationGenerationConflict();
              }
            },
          ),
          newUser
              ? throwsStateError
              : throwsA(isA<LocalReconciliationGenerationConflict>()),
        );
        expect(fenceReached, isTrue);
        expect(Storage.lastOpenDate, '2026-10-30');
        expect(Storage.streakDays, 12);
        expect(Storage.bestStreak, 12);
        expect(Storage.xp, 7);
      },
    );
  }

  test(
    'committed study union converges locally and repeated apply creates no credit',
    () async {
      final wallet = YeopjeonWallet.grandfather(
        sarangchaeStage: 0,
        b2Stage: 0,
      ).encode();
      await _initialize({
        _studyKey: <String>['device'],
        'kl_srs_v1': '{}',
        'kl_xp': 7,
        Storage.yeopjeonWalletPreferenceKey: wallet,
      });
      final owner = _owner();
      final committed = jsonEncode({
        _date: ['device', 'cloud'],
        '2026-10-29': ['older-proof'],
      });
      for (var attempt = 0; attempt < 2; attempt++) {
        await _apply({'study_log_json': committed}, owner);
        expect(Storage.studyLogIdsFor(_date), ['device', 'cloud']);
        expect(Storage.studyLogIdsFor('2026-10-29'), ['older-proof']);
        expect(Storage.xp, 7);
        expect(Storage.srsRawJson, '{}');
        final preferences = await SharedPreferences.getInstance();
        expect(
          preferences.getString(Storage.yeopjeonWalletPreferenceKey),
          wallet,
        );
      }
    },
  );

  test('committed grammar history extends a nonempty device plan', () async {
    const local =
        '{"a2":{"level":"a2","itemsPerDay":3,"servedIdsByDate":{"2026-10-29":["g1"]}}}';
    const committed =
        '{"a2":{"level":"a2","itemsPerDay":3,"servedIdsByDate":{"2026-10-29":["g1","g2"],"2026-10-30":["g3"]}}}';
    await _initialize({'kl_gram_plan_v1': local});
    final owner = _owner();
    await _apply({'gram_plan_json': committed}, owner);
    expect(jsonDecode(Storage.grammarPlanRawJson), jsonDecode(committed));
    await _apply({'gram_plan_json': committed}, owner);
    expect(jsonDecode(Storage.grammarPlanRawJson), jsonDecode(committed));
  });

  test(
    'ordinary restore still gives an existing local study date precedence',
    () async {
      await _initialize({
        _studyKey: <String>['device'],
      });
      await CloudSync.applyRestorePayload({
        'study_log_json': '{"2026-10-30":["device","cloud"]}',
      });
      expect(Storage.studyLogIdsFor(_date), ['device']);
    },
  );

  test(
    'ordinary restore still preserves a nonempty local grammar plan',
    () async {
      const local =
          '{"a2":{"level":"a2","itemsPerDay":3,"servedIdsByDate":{}}}';
      const remote =
          '{"a2":{"level":"a2","itemsPerDay":5,"servedIdsByDate":{"2026-10-30":["g1"]}}}';
      await _initialize({'kl_gram_plan_v1': local});
      await CloudSync.applyRestorePayload({'gram_plan_json': remote});
      expect(Storage.grammarPlanRawJson, local);
    },
  );

  test(
    'invalid committed study data fails before unrelated local progress changes',
    () async {
      await expectLater(
        _apply({
          'progress': {'xp': 50},
          'study_log_json': '{"2026-02-30":["proof"]}',
        }, _owner()),
        throwsFormatException,
      );
      expect(Storage.xp, 0);
      expect(Storage.studyLogDates(), isEmpty);
    },
  );

  test(
    'learner-goal application never creates a course starting point',
    () async {
      await _apply({
        'progress': {'level': 'b2'},
      }, _owner());
      expect(Storage.userLevelCode, 'b2');
      expect(Storage.dedicatedCoursePlacementLevelCode, isNull);
    },
  );

  for (final reacquireSameUid in [false, true]) {
    test(
      'session replacement during ledger preparation blocks the setter: sameUid=$reacquireSameUid',
      () async {
        final owner = _owner();
        final store = _PreparingLedger(() {
          owner.sessions.acquire(
            reacquireSameUid ? 'local-test-account' : 'other-local-account',
          );
        });
        Storage.setStudyLogStoreForTesting(store);
        await expectLater(
          _apply({'study_log_json': '{"2026-10-30":["cloud"]}'}, owner),
          throwsStateError,
        );
        expect(store.setCalls, 0);
        expect(store.values, isEmpty);
      },
    );
  }

  test(
    'reset lifetime invalidation during ledger preparation blocks the setter',
    () async {
      final owner = _owner();
      final store = _PreparingLedger(LocalDataLifetime.invalidate);
      Storage.setStudyLogStoreForTesting(store);
      await expectLater(
        _apply({'study_log_json': '{"2026-10-30":["cloud"]}'}, owner),
        throwsA(isA<StaleLocalDataLifetimeException>()),
      );
      expect(store.setCalls, 0);
      expect(store.values, isEmpty);
    },
  );
}

class _PreparingLedger implements PreferenceStringListStore {
  _PreparingLedger(this.onFirstReload);
  final void Function() onFirstReload;
  final Map<String, List<String>> values = {};
  var setCalls = 0;
  var _prepared = false;

  @override
  bool containsKey(String key) => values.containsKey(key);
  @override
  List<String>? getStringList(String key) => values[key];
  @override
  Future<void> reload() async {
    if (!_prepared) {
      _prepared = true;
      onFirstReload();
    }
  }

  @override
  Future<bool> remove(String key) async => values.remove(key) != null;
  @override
  Future<bool> setStringList(String key, List<String> value) async {
    setCalls++;
    values[key] = List<String>.from(value);
    return true;
  }
}
