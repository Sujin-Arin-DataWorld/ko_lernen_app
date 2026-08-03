import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/bookshelf_service.dart';
import 'package:ko_lernen_app/services/course_mastery_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/services/account/bookshelf_generation_manifest.dart';
import 'package:ko_lernen_app/services/account/bookshelf_sync_outbox.dart';
import 'package:ko_lernen_app/services/account/cloud_backup_deletion.dart';
import 'package:ko_lernen_app/services/account/cloud_read_result.dart';
import 'package:ko_lernen_app/services/account/cloud_restore_result.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/models/book_page.dart';

typedef _IntReader = int Function();

class _CounterCase {
  const _CounterCase({
    required this.name,
    required this.preferenceKey,
    required this.cloudPayload,
    required this.read,
  });

  final String name;
  final String preferenceKey;
  final Map<String, dynamic> cloudPayload;
  final _IntReader read;
}

Future<void> _initializeStorage([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  Storage.resetForTesting();
  await Storage.init();
}

String _courseSnapshotJson({
  String evidenceId = 'cloud-evidence',
  bool isCorrect = true,
  String currentCourseUnitId = 'a1_01_greetings_hangul',
}) => jsonEncode(
  CourseMasterySnapshot(
    placementLevel: 'a1',
    currentCourseUnitId: currentCourseUnitId,
    evidence: [
      MasteryEvidence(
        id: evidenceId,
        conceptId: 'concept_greeting_politeness',
        contentKind: CurriculumContentKind.scenario,
        contentId: 'airport_arrival',
        courseUnitId: 'a1_01_greetings_hangul',
        isCorrect: isCorrect,
        occurredAt: DateTime.utc(2026, 8, 3, 9),
        courseEligible: true,
      ),
    ],
  ).toJson(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => _initializeStorage());

  test(
    'typed restore applies first-link components when the root backup is absent',
    () async {
      final sessions = CloudWriteSessionController();
      final session = sessions.acquire('durable');
      final events = <String>[];

      final result = await CloudSync.restoreWithSessionResult(
        sessions: sessions,
        uid: 'durable',
        readAccount: () async =>
            const CloudReadResult<Map<String, dynamic>>.absent(),
        applyAccount: (data, beforeWrite) async {
          fail('an absent root backup must not apply account data');
        },
        restoreBookshelf: (expectedSession) async {
          expect(expectedSession, session);
          events.add('bookshelf');
          return const CloudRestoreComponentResult(
            status: CloudWriteResult.completed,
            hasRemoteData: true,
          );
        },
        restorePacks: (expectedSession) async {
          expect(expectedSession, session);
          events.add('packs');
          return const CloudRestoreComponentResult(
            status: CloudWriteResult.completed,
            hasRemoteData: true,
          );
        },
      );

      expect(result, CloudRestoreResult.completed);
      expect(events, <String>['bookshelf', 'packs']);
    },
  );

  test(
    'typed restore reports empty only after every authoritative source is empty',
    () async {
      final sessions = CloudWriteSessionController()..acquire('durable');

      final result = await CloudSync.restoreWithSessionResult(
        sessions: sessions,
        uid: 'durable',
        readAccount: () async =>
            const CloudReadResult<Map<String, dynamic>>.absent(),
        applyAccount: (data, beforeWrite) async {
          fail('an absent root backup must not apply account data');
        },
        restoreBookshelf: (_) async => const CloudRestoreComponentResult(
          status: CloudWriteResult.completed,
          hasRemoteData: false,
        ),
        restorePacks: (_) async => const CloudRestoreComponentResult(
          status: CloudWriteResult.completed,
          hasRemoteData: false,
        ),
      );

      expect(result, CloudRestoreResult.empty);
    },
  );

  test(
    'typed restore reports empty for an operational-only user root',
    () async {
      final sessions = CloudWriteSessionController()..acquire('durable');
      var appliedRoot = false;

      final result = await CloudSync.restoreWithSessionResult(
        sessions: sessions,
        uid: 'durable',
        readAccount: () async =>
            const CloudReadResult<Map<String, dynamic>>.present(
              <String, dynamic>{
                'gyeIds': <String>['gye-a'],
                'blockedUids': <String>['blocked'],
                'fcmTokens': <String>['operational-token'],
                'displayName': 'retained profile',
              },
            ),
        applyAccount: (data, beforeWrite) async {
          beforeWrite();
          appliedRoot = true;
        },
        restoreBookshelf: (_) async => const CloudRestoreComponentResult(
          status: CloudWriteResult.completed,
          hasRemoteData: false,
        ),
        restorePacks: (_) async => const CloudRestoreComponentResult(
          status: CloudWriteResult.completed,
          hasRemoteData: false,
        ),
      );

      expect(appliedRoot, isTrue);
      expect(result, CloudRestoreResult.empty);
    },
  );

  test(
    'typed restore propagates a blocked component instead of reporting empty',
    () async {
      final sessions = CloudWriteSessionController()..acquire('durable');
      var restoredPacks = false;

      final result = await CloudSync.restoreWithSessionResult(
        sessions: sessions,
        uid: 'durable',
        readAccount: () async =>
            const CloudReadResult<Map<String, dynamic>>.absent(),
        applyAccount: (data, beforeWrite) async {
          fail('an absent root backup must not apply account data');
        },
        restoreBookshelf: (_) async => const CloudRestoreComponentResult(
          status: CloudWriteResult.blocked,
          hasRemoteData: false,
        ),
        restorePacks: (_) async {
          restoredPacks = true;
          return const CloudRestoreComponentResult(
            status: CloudWriteResult.completed,
            hasRemoteData: false,
          );
        },
      );

      expect(result, CloudRestoreResult.blocked);
      expect(restoredPacks, isFalse);
    },
  );

  test(
    'typed restore reports stale instead of empty after an A-to-B switch',
    () async {
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final loaded = Completer<CloudReadResult<Map<String, dynamic>>>();
      var restoredComponents = 0;

      final result = CloudSync.restoreWithSessionResult(
        sessions: sessions,
        uid: 'uid-a',
        readAccount: () => loaded.future,
        applyAccount: (data, beforeWrite) async {},
        restoreBookshelf: (_) async {
          restoredComponents += 1;
          return const CloudRestoreComponentResult(
            status: CloudWriteResult.completed,
            hasRemoteData: false,
          );
        },
        restorePacks: (_) async {
          restoredComponents += 1;
          return const CloudRestoreComponentResult(
            status: CloudWriteResult.completed,
            hasRemoteData: false,
          );
        },
      );
      await Future<void>.delayed(Duration.zero);
      sessions.acquire('uid-b');
      loaded.complete(const CloudReadResult<Map<String, dynamic>>.absent());

      expect(await result, CloudRestoreResult.stale);
      expect(restoredComponents, 0);
    },
  );

  test(
    'typed restore fails closed when a restore component throws unexpectedly',
    () async {
      final sessions = CloudWriteSessionController()..acquire('durable');
      var restoredPacks = false;

      final result = await CloudSync.restoreWithSessionResult(
        sessions: sessions,
        uid: 'durable',
        readAccount: () async =>
            const CloudReadResult<Map<String, dynamic>>.absent(),
        applyAccount: (data, beforeWrite) async {
          fail('an absent root backup must not apply account data');
        },
        restoreBookshelf: (_) async =>
            throw const FormatException('malformed bookshelf component'),
        restorePacks: (_) async {
          restoredPacks = true;
          return const CloudRestoreComponentResult(
            status: CloudWriteResult.completed,
            hasRemoteData: false,
          );
        },
      );

      expect(result, CloudRestoreResult.blocked);
      expect(restoredPacks, isFalse);
    },
  );

  test(
    'typed restore reports stale when a component error finishes after an account switch',
    () async {
      final sessions = CloudWriteSessionController()..acquire('uid-a');
      final component = Completer<CloudRestoreComponentResult>();
      var restoredPacks = false;

      final result = CloudSync.restoreWithSessionResult(
        sessions: sessions,
        uid: 'uid-a',
        readAccount: () async =>
            const CloudReadResult<Map<String, dynamic>>.absent(),
        applyAccount: (data, beforeWrite) async {
          fail('an absent root backup must not apply account data');
        },
        restoreBookshelf: (_) => component.future,
        restorePacks: (_) async {
          restoredPacks = true;
          return const CloudRestoreComponentResult(
            status: CloudWriteResult.completed,
            hasRemoteData: false,
          );
        },
      );
      await Future<void>.delayed(Duration.zero);
      sessions.acquire('uid-b');
      component.completeError(const FormatException('malformed component'));

      expect(await result, CloudRestoreResult.stale);
      expect(restoredPacks, isFalse);
    },
  );

  test(
    'public restore fails closed when its admitted operation throws',
    () async {
      final sessions = CloudWriteSessionController()..acquire('durable');
      AuthService.overrideCloudBackupDeletionCoordinatorForTesting(
        CloudBackupDeletionCoordinator(
          sessions: sessions,
          currentUid: () => 'durable',
          journalStore: const _ClearCloudBackupDeletionJournalStore(),
          gateway: const _UnusedCloudBackupDeletionGateway(),
        ),
      );
      CloudSync.overrideOperationsForTesting(
        restoreWithResult: () async =>
            throw const FormatException('unexpected restore failure'),
      );
      addTearDown(() {
        CloudSync.resetOperationsForTesting();
        AuthService.resetCloudBackupDeletionForTesting();
      });

      expect(await CloudSync.restoreWithResult(), CloudRestoreResult.blocked);
    },
  );

  test(
    'backup payload enumerates every locally stored restore field',
    () async {
      await _initializeStorage({
        'kl_vok_correct': 11,
        'kl_vok_wrong': 12,
        'kl_vok_skipped': 13,
        'kl_vok_last_idx': 14,
        'kl_vok_seen_ids': <String>['v1'],
        'kl_chosung_correct': 21,
        'kl_chosung_wrong': 22,
        'kl_wordle_wins': 31,
        'kl_wordle_losses': 32,
        'kl_wordle_streak': 33,
        'kl_wordle_best_streak': 34,
        'kl_gram_last_idx': 41,
        'kl_gram_seen': <String>['g1'],
        'kl_last_open_date': '2026-07-28',
        'kl_streak_days': 51,
        'kl_best_streak': 52,
        'kl_xp': 61,
        'kl_user_level': 'b1',
        'kl_stamps_earned': <String>['stamp1'],
        'kl_quests_completed_v1': '{"quest1":"2026-07-01T00:00:00.000Z"}',
        'kl_srs_v1': '{"srs":1}',
        'kl_custom_packs_v1': '{"pack1":{"name":"Pack 1"}}',
        'kl_bookshelf_v1': '{"page1":{"note":"Page 1"}}',
        Storage.courseMasterySnapshotPreferenceKey: _courseSnapshotJson(),
        Storage.browseLevelPreferenceKey: 'b2',
      });

      final payload = await CloudSync.buildBackupPayload();
      expect(payload, {
        'vok': {
          'correct': 11,
          'wrong': 12,
          'skipped': 13,
          'last_idx': 14,
          'seen_ids': ['v1'],
        },
        'chosung': {'correct': 21, 'wrong': 22},
        'wordle': {'wins': 31, 'losses': 32, 'streak': 33, 'best_streak': 34},
        'grammar': {
          'last_idx': 41,
          'seen': ['g1'],
        },
        'app': {
          'last_open': '2026-07-28',
          'streak_days': 51,
          'best_streak': 52,
        },
        'progress': {
          'xp': 61,
          'level': 'b1',
          'earned_stamps': ['stamp1'],
          'quest_completions': {'quest1': '2026-07-01T00:00:00.000Z'},
        },
        'srs_json': '{"srs":1}',
        'custom_packs_json': '{"pack1":{"name":"Pack 1"}}',
        'course_mastery_json': _courseSnapshotJson(),
      });
      expect(
        jsonDecode(payload['course_mastery_json'] as String)['version'],
        2,
      );
      expect(payload, isNot(contains('browse_level')));
    },
  );

  test('backup omits non-canonical course snapshots', () async {
    final malformedCheckpoint =
        jsonDecode(_courseSnapshotJson()) as Map<String, dynamic>;
    malformedCheckpoint['scenarioCheckpoints'] = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'bad-checkpoint',
        'scenarioId': 'airport_arrival',
        'courseUnitId': 'a1_01_greetings_hangul',
        'score': 'bad',
        'occurredAt': '2026-08-03T09:00:00.000Z',
        'courseEligible': true,
      },
    ];
    for (final raw in <String>[
      'not-json',
      '{"version":3}',
      '{"version":1}',
      jsonEncode(malformedCheckpoint),
    ]) {
      await _initializeStorage({
        Storage.courseMasterySnapshotPreferenceKey: raw,
      });

      expect(
        await CloudSync.buildBackupPayload(),
        isNot(contains('course_mastery_json')),
      );
    }
  });

  test(
    'backup migrates retained v1 course state before emitting canonical v2',
    () async {
      final legacy = jsonEncode({
        ...jsonDecode(_courseSnapshotJson()) as Map<String, dynamic>,
        'version': 1,
      });
      await _initializeStorage({
        Storage.legacyCourseMasteryPreferenceKey: legacy,
        Storage.browseLevelPreferenceKey: 'b2',
        'kl_user_level': 'a2',
      });

      final payload = await CloudSync.buildBackupPayload();

      expect(Storage.courseMasterySnapshotRawJson, contains('"version":2'));
      expect(Storage.legacyCourseMasteryRawJson, legacy);
      expect(Storage.browseLevelCode, 'b2');
      expect(Storage.userLevelCode, 'a2');
      expect(payload['course_mastery_json'], isA<String>());
      expect(
        jsonDecode(payload['course_mastery_json'] as String)['version'],
        2,
      );
    },
  );

  test(
    'backup migrates dedicated scalar course state without using browse or user level',
    () async {
      await _initializeStorage({
        Storage.placementLevelPreferenceKey: 'a1',
        Storage.courseUnitPreferenceKey: 'a1_01_greetings_hangul',
        Storage.browseLevelPreferenceKey: 'b2',
        'kl_user_level': 'a2',
      });

      final payload = await CloudSync.buildBackupPayload();

      final canonical =
          jsonDecode(Storage.courseMasterySnapshotRawJson)
              as Map<String, dynamic>;
      expect(canonical['version'], 2);
      expect(canonical['placementLevel'], 'a1');
      expect(canonical['currentCourseUnitId'], 'a1_01_greetings_hangul');
      expect(Storage.browseLevelCode, 'b2');
      expect(Storage.userLevelCode, 'a2');
      expect(
        payload['course_mastery_json'],
        Storage.courseMasterySnapshotRawJson,
      );
    },
  );

  test(
    'backup omits invalid local course inputs without overwriting course or browse state',
    () async {
      const malformedLegacy = '{not-json';
      await _initializeStorage({
        Storage.legacyCourseMasteryPreferenceKey: malformedLegacy,
        Storage.placementLevelPreferenceKey: 'a1',
        Storage.courseUnitPreferenceKey: 'a1_01_greetings_hangul',
        Storage.browseLevelPreferenceKey: 'b2',
        'kl_user_level': 'a2',
      });

      final malformedPayload = await CloudSync.buildBackupPayload();

      expect(malformedPayload, isNot(contains('course_mastery_json')));
      expect(Storage.courseMasterySnapshotRawJson, isEmpty);
      expect(Storage.legacyCourseMasteryRawJson, malformedLegacy);
      expect(Storage.dedicatedCoursePlacementLevelCode, 'a1');
      expect(Storage.courseUnitId, 'a1_01_greetings_hangul');
      expect(Storage.browseLevelCode, 'b2');
      expect(Storage.userLevelCode, 'a2');

      final invalidV2 = _courseSnapshotJson(
        currentCourseUnitId: 'unknown-course-unit',
      );
      await _initializeStorage({
        Storage.courseMasterySnapshotPreferenceKey: invalidV2,
        Storage.browseLevelPreferenceKey: 'b2',
      });

      final invalidPayload = await CloudSync.buildBackupPayload();

      expect(invalidPayload, isNot(contains('course_mastery_json')));
      expect(Storage.courseMasterySnapshotRawJson, invalidV2);
      expect(Storage.browseLevelCode, 'b2');
    },
  );

  final cumulativeCounters = <_CounterCase>[
    _CounterCase(
      name: 'vocabulary correct',
      preferenceKey: 'kl_vok_correct',
      cloudPayload: const {
        'vok': {'correct': 12},
      },
      read: () => Storage.vokCorrect,
    ),
    _CounterCase(
      name: 'vocabulary wrong',
      preferenceKey: 'kl_vok_wrong',
      cloudPayload: const {
        'vok': {'wrong': 12},
      },
      read: () => Storage.vokWrong,
    ),
    _CounterCase(
      name: 'vocabulary skipped',
      preferenceKey: 'kl_vok_skipped',
      cloudPayload: const {
        'vok': {'skipped': 12},
      },
      read: () => Storage.vokSkipped,
    ),
    _CounterCase(
      name: 'Chosung correct',
      preferenceKey: 'kl_chosung_correct',
      cloudPayload: const {
        'chosung': {'correct': 12},
      },
      read: () => Storage.chosungCorrect,
    ),
    _CounterCase(
      name: 'Chosung wrong',
      preferenceKey: 'kl_chosung_wrong',
      cloudPayload: const {
        'chosung': {'wrong': 12},
      },
      read: () => Storage.chosungWrong,
    ),
    _CounterCase(
      name: 'Wordle wins',
      preferenceKey: 'kl_wordle_wins',
      cloudPayload: const {
        'wordle': {'wins': 12},
      },
      read: () => Storage.wordleWins,
    ),
    _CounterCase(
      name: 'Wordle losses',
      preferenceKey: 'kl_wordle_losses',
      cloudPayload: const {
        'wordle': {'losses': 12},
      },
      read: () => Storage.wordleLosses,
    ),
    _CounterCase(
      name: 'Wordle best streak',
      preferenceKey: 'kl_wordle_best_streak',
      cloudPayload: const {
        'wordle': {'best_streak': 12},
      },
      read: () => Storage.wordleBestStreak,
    ),
    _CounterCase(
      name: 'app best streak',
      preferenceKey: 'kl_best_streak',
      cloudPayload: const {
        'app': {'best_streak': 12},
      },
      read: () => Storage.bestStreak,
    ),
    _CounterCase(
      name: 'XP',
      preferenceKey: 'kl_xp',
      cloudPayload: const {
        'progress': {'xp': 12},
      },
      read: () => Storage.xp,
    ),
  ];

  for (final counter in cumulativeCounters) {
    test(
      '${counter.name} max-merges larger and smaller cloud totals',
      () async {
        await _initializeStorage({counter.preferenceKey: 9});
        await CloudSync.applyRestorePayload(counter.cloudPayload);
        expect(counter.read(), 12);

        await _initializeStorage({counter.preferenceKey: 15});
        await CloudSync.applyRestorePayload(counter.cloudPayload);
        expect(counter.read(), 15);
      },
    );
  }

  test('fresh-device restore round-trips every backup-emitted field', () async {
    await _initializeStorage({
      'kl_vok_correct': 1,
      'kl_vok_wrong': 2,
      'kl_vok_skipped': 3,
      'kl_vok_last_idx': 4,
      'kl_vok_seen_ids': <String>['v1', 'v2'],
      'kl_chosung_correct': 5,
      'kl_chosung_wrong': 6,
      'kl_wordle_wins': 7,
      'kl_wordle_losses': 8,
      'kl_wordle_streak': 2,
      'kl_wordle_best_streak': 9,
      'kl_gram_last_idx': 10,
      'kl_gram_seen': <String>['g1'],
      'kl_last_open_date': '2026-07-28',
      'kl_streak_days': 11,
      'kl_best_streak': 12,
      'kl_xp': 130,
      'kl_user_level': 'a2',
      'kl_stamps_earned': <String>['stamp1'],
      'kl_quests_completed_v1': '{"quest1":"2026-07-01T00:00:00.000Z"}',
      'kl_srs_v1': '{"srs":1}',
      'kl_custom_packs_v1': '{"pack1":{"name":"Pack 1"}}',
      'kl_bookshelf_v1': '{"page1":{"note":"Page 1"}}',
      Storage.courseMasterySnapshotPreferenceKey: _courseSnapshotJson(),
    });
    final backup = await CloudSync.buildBackupPayload();

    await _initializeStorage();
    await CloudSync.applyRestorePayload(backup);

    expect(Storage.vokCorrect, 1);
    expect(Storage.vokWrong, 2);
    expect(Storage.vokSkipped, 3);
    expect(Storage.vokLastIdx, 4);
    expect(Storage.vokSeenIds, ['v1', 'v2']);
    expect(Storage.chosungCorrect, 5);
    expect(Storage.chosungWrong, 6);
    expect(Storage.wordleWins, 7);
    expect(Storage.wordleLosses, 8);
    expect(Storage.wordleStreak, 2);
    expect(Storage.wordleBestStreak, 9);
    expect(Storage.grammarLastIdx, 10);
    expect(Storage.grammarSeen, ['g1']);
    expect(Storage.lastOpenDate, '2026-07-28');
    expect(Storage.streakDays, 11);
    expect(Storage.bestStreak, 12);
    expect(Storage.xp, 130);
    expect(Storage.userLevelCode, 'a2');
    expect(Storage.earnedStamps, ['stamp1']);
    expect(Storage.questCompletions, {'quest1': '2026-07-01T00:00:00.000Z'});
    expect(Storage.srsRawJson, '{"srs":1}');
    expect(Storage.customPacksRawJson, '{"pack1":{"name":"Pack 1"}}');
    expect(Storage.bookshelfRawJson, isEmpty);
    Storage.resetCourseMasteryForTesting();
    final restored = await CourseMasteryService(
      await CurriculumCatalog.load(),
    ).refresh();
    expect(restored.placementLevel, 'a1');
    expect(restored.currentCourseUnitId, 'a1_01_greetings_hangul');
    expect(restored.evidence.single.id, 'cloud-evidence');
  });

  test(
    'course restore additively preserves local and remote evidence',
    () async {
      await Storage.setCourseMasterySnapshotRawJson(
        _courseSnapshotJson(evidenceId: 'local-evidence'),
      );

      await CloudSync.applyRestorePayload({
        'course_mastery_json': _courseSnapshotJson(
          evidenceId: 'remote-evidence',
        ),
      });

      Storage.resetCourseMasteryForTesting();
      final restored = await CourseMasteryService(
        await CurriculumCatalog.load(),
      ).refresh();
      expect(
        restored.evidence.map((item) => item.id),
        containsAll(<String>['local-evidence', 'remote-evidence']),
      );
    },
  );

  test(
    'invalid remote course JSON never clobbers local canonical bytes',
    () async {
      final local = _courseSnapshotJson(evidenceId: 'local-evidence');
      final future = jsonEncode({
        ...jsonDecode(_courseSnapshotJson()) as Map<String, dynamic>,
        'version': 3,
      });
      final unknownUnit = _courseSnapshotJson(
        currentCourseUnitId: 'unknown-course-unit',
      );
      final conflicting = _courseSnapshotJson(
        evidenceId: 'local-evidence',
        isCorrect: false,
      );

      for (final remote in <String>[
        'not-json',
        future,
        unknownUnit,
        conflicting,
      ]) {
        await Storage.setCourseMasterySnapshotRawJson(local);
        final before = Storage.courseMasterySnapshotRawJson;

        await expectLater(
          CloudSync.applyRestorePayload({'course_mastery_json': remote}),
          throwsA(isA<FormatException>()),
        );
        expect(Storage.courseMasterySnapshotRawJson, before);
      }
    },
  );

  test(
    'invalid remote course JSON leaves an empty canonical store untouched',
    () async {
      final duplicateIdentity =
          jsonDecode(_courseSnapshotJson()) as Map<String, dynamic>;
      duplicateIdentity['evidence'] = <Map<String, dynamic>>[
        ...((duplicateIdentity['evidence'] as List<dynamic>)
            .cast<Map<String, dynamic>>()),
        <String, dynamic>{
          ...((duplicateIdentity['evidence'] as List<dynamic>).single
              as Map<String, dynamic>),
          'isCorrect': false,
        },
      ];

      for (final remote in <String>[
        _courseSnapshotJson(currentCourseUnitId: 'unknown-course-unit'),
        jsonEncode(duplicateIdentity),
      ]) {
        await _initializeStorage();
        expect(Storage.courseMasterySnapshotRawJson, isEmpty);

        await expectLater(
          CloudSync.applyRestorePayload({'course_mastery_json': remote}),
          throwsA(isA<FormatException>()),
        );
        expect(Storage.courseMasterySnapshotRawJson, isEmpty);
      }
    },
  );

  test(
    'dedicated local course placement is preserved without canonical synthesis',
    () async {
      await _initializeStorage({Storage.placementLevelPreferenceKey: 'a2'});

      await expectLater(
        CloudSync.applyRestorePayload({
          'course_mastery_json': _courseSnapshotJson(),
        }),
        throwsA(isA<FormatException>()),
      );

      expect(Storage.courseMasterySnapshotRawJson, isEmpty);
      expect(Storage.placementLevelCode, 'a2');
    },
  );

  test(
    'retained v1 course history participates in normal cloud merge',
    () async {
      final legacy =
          jsonDecode(_courseSnapshotJson(evidenceId: 'legacy-evidence'))
              as Map<String, dynamic>;
      legacy['version'] = 1;
      (legacy['evidence'] as List<dynamic>).single.remove('id');
      final legacyRaw = jsonEncode(legacy);
      await _initializeStorage({
        Storage.legacyCourseMasteryPreferenceKey: legacyRaw,
        'kl_user_level': 'b2',
      });

      await CloudSync.applyRestorePayload({
        'course_mastery_json': _courseSnapshotJson(
          evidenceId: 'remote-evidence',
        ),
      });

      Storage.resetCourseMasteryForTesting();
      final restored = await CourseMasteryService(
        await CurriculumCatalog.load(),
      ).refresh();
      expect(restored.placementLevel, 'a1');
      expect(restored.evidence, hasLength(2));
      expect(
        restored.evidence.map((item) => item.id),
        contains('remote-evidence'),
      );
      expect(Storage.legacyCourseMasteryRawJson, legacyRaw);
      expect(Storage.userLevelCode, 'b2');
    },
  );

  test(
    'root backup round-trips custom packs but not canonical bookshelf data',
    () async {
      final pack = await CustomPackService.createEmpty(name: 'Cloud pack');
      final page = BookPage(
        id: BookshelfService.generateId(),
        localThumbnailPath: null,
        extractedText: '한국어',
        note: 'Cloud note',
        words: const [],
        grammar: const [],
        sentences: const [],
        capturedAtIso: '2026-07-29T08:30:00.000Z',
        customPackId: pack.id,
      );
      await BookshelfService.save(page);
      final backup = await CloudSync.buildBackupPayload();

      await _initializeStorage();
      await CloudSync.applyRestorePayload(backup);

      expect(CustomPackService.getById(pack.id)?.name, 'Cloud pack');
      expect(backup, isNot(contains('bookshelf_json')));
      expect(BookshelfService.getById(page.id), isNull);
    },
  );

  test('legacy root bookshelf remains readable during migration', () async {
    await CloudSync.applyRestorePayload({
      'bookshelf_json': '{"page1":{"note":"Legacy page"}}',
    });

    expect(BookshelfService.getById('page1')?.note, 'Legacy page');
    const store = SharedPreferencesBookshelfSyncOutboxStore();
    expect(
      await store.read(),
      isNull,
      reason: 'an arbitrary legacy restore must not approve parent migration',
    );
  });

  test(
    'validated reconciled legacy restore durably approves first generation',
    () async {
      final sessions = CloudWriteSessionController();
      sessions.acquire('uid-a');
      final session = sessions.transition(CloudWriteMode.reconciling);

      await CloudSync.applyReconciledRestorePayload(
        {'bookshelf_json': '{"page1":{"note":"Validated legacy page"}}'},
        uid: 'uid-a',
        session: session,
        sessions: sessions,
      );

      const store = SharedPreferencesBookshelfSyncOutboxStore();
      final pending = await store.read();
      expect(pending?.allowParentOnlyLegacy, isTrue);

      final repository = _LegacyBookshelfRepository()
        ..legacyParent = {
          'page1': {'note': 'Validated legacy page'},
        };
      await BookshelfGenerationSync.stageAndActivate(
        repository: repository,
        uid: 'uid-a',
        generationId: 'generation-first',
        operationId: pending!.operationId,
        entries: const {},
        allowParentOnlyLegacy: pending.allowParentOnlyLegacy,
        beforeWrite: () {},
      );

      final snapshot = await BookshelfGenerationSync.read(repository, 'uid-a');
      expect(snapshot.entries, {
        'page1': {'note': 'Validated legacy page'},
      });
    },
  );

  test('ready session cannot approve parent-only legacy migration', () async {
    final sessions = CloudWriteSessionController();
    final session = sessions.acquire('uid-a');

    await expectLater(
      CloudSync.applyReconciledRestorePayload(
        {'bookshelf_json': '{"page1":{"note":"Legacy page"}}'},
        uid: 'uid-a',
        session: session,
        sessions: sessions,
      ),
      throwsStateError,
    );

    const store = SharedPreferencesBookshelfSyncOutboxStore();
    expect(await store.read(), isNull);
    expect(Storage.bookshelfRawJson, isEmpty);
  });

  test(
    'invalid reconciled legacy restore remains unapproved and fail-closed',
    () async {
      final sessions = CloudWriteSessionController();
      sessions.acquire('uid-a');
      final session = sessions.transition(CloudWriteMode.reconciling);

      await CloudSync.applyReconciledRestorePayload(
        {'bookshelf_json': 'not-json'},
        uid: 'uid-a',
        session: session,
        sessions: sessions,
      );

      const store = SharedPreferencesBookshelfSyncOutboxStore();
      expect(await store.read(), isNull);
      final repository = _LegacyBookshelfRepository()
        ..legacyParent = {
          'page1': {'note': 'Untrusted parent'},
        };
      await expectLater(
        BookshelfGenerationSync.stageAndActivate(
          repository: repository,
          uid: 'uid-a',
          generationId: 'generation-first',
          entries: const {},
          beforeWrite: () {},
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'level restore normalizes supported levels and rejects garbage',
    () async {
      await CloudSync.applyRestorePayload({
        'progress': {'level': ' A2 '},
      });
      expect(Storage.userLevelCode, 'a2');

      await _initializeStorage();
      await CloudSync.applyRestorePayload({
        'progress': {'level': 'legendary'},
      });
      expect(Storage.userLevelCode, isNull);
    },
  );

  test(
    'quest restore accepts strict UTC timestamps and rejects overflow',
    () async {
      await CloudSync.applyRestorePayload({
        'progress': {
          'quest_completions': {
            'valid': '2026-02-28T23:59:58.123Z',
            'overflow-day': '2026-02-31T00:00:00.000Z',
            'overflow-time': '2026-02-28T25:00:00.000Z',
            'offset': '2026-02-28T23:59:58.123+01:00',
          },
        },
      });

      expect(Storage.questCompletions, {'valid': '2026-02-28T23:59:58.123Z'});
    },
  );

  test(
    'vocabulary cursor restores only into an uninitialized local domain',
    () async {
      await CloudSync.applyRestorePayload({
        'vok': {
          'last_idx': 8,
          'seen_ids': ['cloud'],
        },
      });
      expect(Storage.vokLastIdx, 8);

      await _initializeStorage({
        'kl_vok_correct': 1,
        'kl_vok_last_idx': 3,
        'kl_vok_seen_ids': <String>['local'],
      });
      await CloudSync.applyRestorePayload({
        'vok': {
          'last_idx': 8,
          'seen_ids': ['cloud'],
        },
      });
      expect(Storage.vokLastIdx, 3);
      expect(Storage.vokSeenIds, ['local', 'cloud']);
    },
  );

  test(
    'grammar cursor restores only into an uninitialized local domain',
    () async {
      await CloudSync.applyRestorePayload({
        'grammar': {
          'last_idx': 8,
          'seen': ['cloud'],
        },
      });
      expect(Storage.grammarLastIdx, 8);

      await _initializeStorage({
        'kl_gram_last_idx': 3,
        'kl_gram_seen': <String>['local'],
      });
      await CloudSync.applyRestorePayload({
        'grammar': {
          'last_idx': 8,
          'seen': ['cloud'],
        },
      });
      expect(Storage.grammarLastIdx, 3);
      expect(Storage.grammarSeen, ['local', 'cloud']);
    },
  );

  test(
    'Wordle current streak restores only for an uninitialized domain',
    () async {
      await CloudSync.applyRestorePayload({
        'wordle': {'wins': 7, 'losses': 2, 'streak': 4, 'best_streak': 5},
      });
      expect(Storage.wordleStreak, 4);

      await _initializeStorage({
        'kl_wordle_wins': 3,
        'kl_wordle_losses': 1,
        'kl_wordle_streak': 1,
        'kl_wordle_best_streak': 3,
      });
      await CloudSync.applyRestorePayload({
        'wordle': {'wins': 7, 'losses': 2, 'streak': 4, 'best_streak': 5},
      });
      expect(Storage.wordleWins, 7);
      expect(Storage.wordleLosses, 2);
      expect(Storage.wordleBestStreak, 5);
      expect(Storage.wordleStreak, 1);
    },
  );

  test(
    'restored Wordle current streak raises an omitted or lower best streak',
    () async {
      await CloudSync.applyRestorePayload({
        'wordle': {'streak': 4, 'best_streak': 2},
      });

      expect(Storage.wordleStreak, 4);
      expect(Storage.wordleBestStreak, 4);
    },
  );

  test('app current streak follows the newer valid last-open date', () async {
    await _initializeStorage({
      'kl_last_open_date': '2026-07-20',
      'kl_streak_days': 8,
    });
    await CloudSync.applyRestorePayload({
      'app': {'last_open': '2026-07-28', 'streak_days': 3},
    });
    expect(Storage.lastOpenDate, '2026-07-28');
    expect(Storage.streakDays, 3);

    await CloudSync.applyRestorePayload({
      'app': {'last_open': '2026-07-21', 'streak_days': 99},
    });
    expect(Storage.lastOpenDate, '2026-07-28');
    expect(Storage.streakDays, 3);
  });

  test(
    'same-date app current streak deterministically keeps the larger value',
    () async {
      await _initializeStorage({
        'kl_last_open_date': '2026-07-28',
        'kl_streak_days': 8,
      });
      await CloudSync.applyRestorePayload({
        'app': {'last_open': '2026-07-28', 'streak_days': 11},
      });
      expect(Storage.lastOpenDate, '2026-07-28');
      expect(Storage.streakDays, 11);

      await CloudSync.applyRestorePayload({
        'app': {'last_open': '2026-07-28', 'streak_days': 4},
      });
      expect(Storage.streakDays, 11);
    },
  );

  test(
    'restored app current streak raises an omitted or lower best streak',
    () async {
      await _initializeStorage({
        'kl_last_open_date': '2026-07-20',
        'kl_streak_days': 2,
        'kl_best_streak': 3,
      });
      await CloudSync.applyRestorePayload({
        'app': {'last_open': '2026-07-28', 'streak_days': 8},
      });

      expect(Storage.streakDays, 8);
      expect(Storage.bestStreak, 8);
    },
  );

  test(
    'malformed remote app date never clobbers current streak state',
    () async {
      await _initializeStorage({
        'kl_last_open_date': '2026-07-28',
        'kl_streak_days': 8,
        'kl_best_streak': 10,
      });
      await CloudSync.applyRestorePayload({
        'app': {
          'last_open': 'not-a-date',
          'streak_days': 99,
          'best_streak': 12,
        },
      });
      expect(Storage.lastOpenDate, '2026-07-28');
      expect(Storage.streakDays, 8);
      expect(Storage.bestStreak, 12);
    },
  );

  test('nonempty structured and collection data is never clobbered', () async {
    await _initializeStorage({
      'kl_vok_seen_ids': <String>['local-v'],
      'kl_gram_seen': <String>['local-g'],
      'kl_stamps_earned': <String>['local-stamp'],
      'kl_quests_completed_v1': '{"local-quest":"2026-07-01T00:00:00.000Z"}',
      'kl_srs_v1': '{"local":1}',
      'kl_custom_packs_v1': '{"local-pack":{}}',
      'kl_bookshelf_v1': '{"local-page":{}}',
    });
    await CloudSync.applyRestorePayload({
      'vok': {
        'seen_ids': ['cloud-v'],
      },
      'grammar': {
        'seen': ['cloud-g'],
      },
      'progress': {
        'earned_stamps': ['cloud-stamp'],
        'quest_completions': {'cloud-quest': '2026-07-02T00:00:00.000Z'},
      },
      'srs_json': '',
      'custom_packs_json': null,
      'bookshelf_json': '',
    });

    expect(Storage.vokSeenIds, ['local-v', 'cloud-v']);
    expect(Storage.grammarSeen, ['local-g', 'cloud-g']);
    expect(Storage.earnedStamps, ['local-stamp', 'cloud-stamp']);
    expect(
      Storage.questCompletions.keys,
      containsAll(['local-quest', 'cloud-quest']),
    );
    expect(Storage.srsRawJson, '{"local":1}');
    expect(Storage.customPacksRawJson, '{"local-pack":{}}');
    expect(Storage.bookshelfRawJson, '{"local-page":{}}');
  });

  test(
    'invalid structured JSON and wrong top-level shapes are not restored',
    () async {
      await CloudSync.applyRestorePayload({
        'srs_json': '[]',
        'custom_packs_json': '[]',
        'bookshelf_json': 'not-json',
      });

      expect(Storage.srsRawJson, isEmpty);
      expect(Storage.customPacksRawJson, isEmpty);
      expect(Storage.bookshelfRawJson, isEmpty);
    },
  );

  test(
    'older and malformed backup values are ignored without type crashes',
    () async {
      await _initializeStorage({
        'kl_vok_correct': 4,
        'kl_vok_seen_ids': <String>['local-v'],
        'kl_chosung_wrong': 5,
        'kl_wordle_wins': 6,
        'kl_gram_seen': <String>['local-g'],
        'kl_last_open_date': '2026-07-28',
        'kl_streak_days': 7,
        'kl_xp': 8,
        'kl_user_level': 'a2',
        'kl_stamps_earned': <String>['local-stamp'],
        'kl_quests_completed_v1': '{"local-quest":"2026-07-01T00:00:00.000Z"}',
        'kl_srs_v1': '{"local":1}',
      });

      await expectLater(
        CloudSync.applyRestorePayload({
          'vok': {
            'correct': 'four',
            'wrong': -1,
            'seen_ids': [1, null, 'cloud-v'],
          },
          'chosung': {
            'wrong': {'bad': 'type'},
          },
          'wordle': 'legacy',
          'grammar': {
            'last_idx': 1.5,
            'seen': [false, 'cloud-g'],
          },
          'app': {'last_open': 20260729, 'streak_days': 'many'},
          'progress': {
            'xp': 'lots',
            'level': 3,
            'earned_stamps': [3, 'cloud-stamp'],
            'quest_completions': {
              'cloud-quest': 123,
              7: '2026-07-02T00:00:00.000Z',
            },
          },
          'srs_json': 42,
          'custom_packs_json': <String>[],
          'bookshelf_json': <String, Object>{},
        }),
        completes,
      );

      expect(Storage.vokCorrect, 4);
      expect(Storage.vokWrong, 0);
      expect(Storage.vokSeenIds, ['local-v', 'cloud-v']);
      expect(Storage.chosungWrong, 5);
      expect(Storage.wordleWins, 6);
      expect(Storage.grammarLastIdx, 0);
      expect(Storage.grammarSeen, ['local-g', 'cloud-g']);
      expect(Storage.lastOpenDate, '2026-07-28');
      expect(Storage.streakDays, 7);
      expect(Storage.xp, 8);
      expect(Storage.userLevelCode, 'a2');
      expect(Storage.earnedStamps, ['local-stamp', 'cloud-stamp']);
      expect(Storage.questCompletions.keys, ['local-quest']);
      expect(Storage.srsRawJson, '{"local":1}');
    },
  );
}

class _ClearCloudBackupDeletionJournalStore
    implements CloudBackupDeletionJournalStore {
  const _ClearCloudBackupDeletionJournalStore();

  @override
  Future<bool> clearIfCurrent(CloudBackupDeletionJournal expected) async =>
      false;

  @override
  Future<CloudBackupDeletionJournal?> read() async => null;

  @override
  Future<void> write(CloudBackupDeletionJournal journal) async {
    throw UnsupportedError('not used by a restore admission');
  }
}

class _UnusedCloudBackupDeletionGateway implements CloudBackupDeletionGateway {
  const _UnusedCloudBackupDeletionGateway();

  @override
  Future<CloudBackupDeletionRemoteState> deleteCloudBackup(
    String requestKey, {
    required String expectedUid,
  }) async {
    throw UnsupportedError('not used by a restore admission');
  }
}

class _LegacyBookshelfRepository implements BookshelfGenerationRepository {
  BookshelfGenerationManifest? active;
  final generations = <String, Map<String, Map<String, dynamic>>>{};
  Map<String, Map<String, dynamic>> legacyParent = {};

  @override
  Future<bool> activateManifest({
    required String uid,
    required BookshelfGenerationManifest manifest,
    required int expectedRevision,
  }) async {
    if ((active?.revision ?? 0) != expectedRevision) return false;
    active = manifest;
    return true;
  }

  @override
  Future<BookshelfGenerationManifest?> readActiveManifest(String uid) async =>
      active;

  @override
  Future<Map<String, dynamic>?> readGenerationRecord({
    required String uid,
    required String generationId,
    required String recordId,
  }) async => generations[generationId]?[recordId];

  @override
  Future<Map<String, Map<String, dynamic>>> readLegacyEntries(
    String uid,
  ) async => {};

  @override
  Future<Map<String, Map<String, dynamic>>> readLegacyParent(
    String uid,
  ) async => legacyParent;

  @override
  Future<void> writeGenerationRecord({
    required String uid,
    required String generationId,
    required String recordId,
    required Map<String, dynamic> data,
  }) async {
    generations.putIfAbsent(generationId, () => {})[recordId] = data;
  }
}
