import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/bookshelf_service.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => _initializeStorage());

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
      });

      expect(CloudSync.buildBackupPayload(), {
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
        'bookshelf_json': '{"page1":{"note":"Page 1"}}',
      });
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
    });
    final backup = CloudSync.buildBackupPayload();

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
    expect(Storage.bookshelfRawJson, '{"page1":{"note":"Page 1"}}');
  });

  test(
    'production custom-pack and bookshelf services round-trip through backup',
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
      final backup = CloudSync.buildBackupPayload();

      await _initializeStorage();
      await CloudSync.applyRestorePayload(backup);

      expect(CustomPackService.getById(pack.id)?.name, 'Cloud pack');
      expect(BookshelfService.getById(page.id)?.note, 'Cloud note');
      expect(BookshelfService.getById(page.id)?.customPackId, pack.id);
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
