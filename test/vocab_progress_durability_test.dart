import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/pack_completion_owner.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/learning_data_export_service.dart';

import 'support/reward_preferences_platform.dart';

class _DelayedReadPlatform extends RewardPreferencesPlatform {
  final reads = <({Completer<void> entered, Completer<void> release})>[];

  ({Completer<void> entered, Completer<void> release}) holdNextRead() {
    final read = (entered: Completer<void>(), release: Completer<void>());
    reads.add(read);
    return read;
  }

  @override
  Future<Map<String, Object>> getAll() async {
    final read = reads.isEmpty ? null : reads.removeAt(0);
    final snapshot = await super.getAll();
    if (read != null) {
      read.entered.complete();
      await read.release.future;
    }
    return snapshot;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalPlatform = SharedPreferencesStorePlatform.instance;
  late _DelayedReadPlatform platform;

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    platform = _DelayedReadPlatform();
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
  });

  tearDown(() {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    SharedPreferencesStorePlatform.instance = originalPlatform;
  });

  test('a rejected vocabulary counter is not published as confirmed', () async {
    platform.rejectKey = 'kl_vok_correct';

    await expectLater(
      Storage.setVokCorrect(1),
      throwsA(isA<PreferenceWriteException>()),
    );
    expect(Storage.vokCorrect, 0);
    expect(platform.values['kl_vok_correct'], isNull);
  });

  test('a pending vocabulary counter keeps the confirmed reader', () async {
    platform.values['kl_vok_correct'] = 3;
    await (await SharedPreferences.getInstance()).reload();
    final entered = Completer<void>();
    final release = Completer<void>();
    platform
      ..rejectKey = 'kl_vok_correct'
      ..writeEntered = entered
      ..releaseWrite = release
      ..commitBeforeFailure = true
      ..successfulReply = true;

    final saving = Storage.setVokCorrect(4);
    await entered.future;
    expect(Storage.vokCorrect, 3);
    release.complete();
    await saving;
    expect(Storage.vokCorrect, 4);
  });

  test('a rejected wrong-count increment is not published', () async {
    platform.rejectKey = 'kl_wrong_count_v1';

    await expectLater(
      Storage.incrementWrongCount('하다'),
      throwsA(isA<PreferenceWriteException>()),
    );
    expect(Storage.wrongCountOf('하다'), 0);
    expect(platform.values['kl_wrong_count_v1'], isNull);
  });

  test('reset drains an accepted delayed seen-id write', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    platform
      ..rejectKey = 'kl_vok_seen_ids'
      ..writeEntered = entered
      ..releaseWrite = release
      ..commitBeforeFailure = true
      ..successfulReply = true;

    final saving = Storage.addVokSeen('하다');
    await entered.future;
    final reset = Storage.resetAllStrict();
    release.complete();
    await saving;
    await reset;
    expect(platform.values.keys.where((key) => key.startsWith('kl_')), isEmpty);
    expect(Storage.vokSeenIds, isEmpty);
  });

  for (final committed in <bool>[false, true]) {
    test(
      'retained counter increment resolves an unknown outcome once; committed=$committed',
      () async {
        platform.values['kl_vok_correct'] = 3;
        await (await SharedPreferences.getInstance()).reload();
        final attempt = VocabProgressAttempt(correctDelta: 1);
        platform
          ..rejectKey = 'kl_vok_correct'
          ..throwReply = true
          ..commitBeforeFailure = committed
          ..failReloadAfterWrite = true;

        await expectLater(
          attempt.save(),
          throwsA(isA<PreferenceOutcomeUnknownException>()),
        );
        expect(Storage.vokCorrect, 3);
        await expectLater(
          attempt.save(),
          throwsA(isA<PreferenceOutcomeUnknownException>()),
        );
        expect(platform.writes['kl_vok_correct'], 1);

        platform
          ..unavailable = false
          ..rejectKey = null;
        expect(await attempt.save(), isTrue);
        expect(await attempt.save(), isTrue);
        expect(Storage.vokCorrect, 4);
        expect(platform.values['kl_vok_correct'], 4);
        expect(platform.writes['kl_vok_correct'], committed ? 1 : 2);
      },
    );
  }

  test(
    'concurrent retained increments and seen unions do not overwrite',
    () async {
      await Future.wait(<Future<bool>>[
        for (var i = 0; i < 50; i++)
          VocabProgressAttempt(correctDelta: 1, seenId: 'word-$i').save(),
      ]);

      expect(Storage.vokCorrect, 50);
      expect(Storage.vokSeenIds, <String>[
        for (var i = 0; i < 50; i++) 'word-$i',
      ]);
    },
  );

  test(
    'cloud max and union are derived when their queued mutation runs',
    () async {
      platform.values['kl_vok_correct'] = 5;
      platform.values['kl_vok_seen_ids'] = <String>['local'];
      await (await SharedPreferences.getInstance()).reload();
      final entered = Completer<void>();
      final release = Completer<void>();
      platform
        ..rejectKey = 'kl_vok_correct'
        ..writeEntered = entered
        ..releaseWrite = release
        ..commitBeforeFailure = true
        ..successfulReply = true;

      final local = VocabProgressAttempt(
        correctDelta: 1,
        seenId: 'learned-while-restoring',
      ).save();
      await entered.future;
      final restoring = CloudSync.applyRestorePayload(<String, dynamic>{
        'vok': <String, dynamic>{
          'correct': 4,
          'seen_ids': <String>['cloud'],
        },
      });
      release.complete();
      await local;
      await restoring;

      expect(Storage.vokCorrect, 6);
      expect(Storage.vokSeenIds, <String>[
        'local',
        'learned-while-restoring',
        'cloud',
      ]);
    },
  );

  for (final field in ['integer', 'seen', 'wrong-count']) {
    for (final writeFirst in [false, true]) {
      test(
        'writer enters during delayed retirement read: $field writeFirst=$writeFirst',
        () async {
          final key = switch (field) {
            'integer' => 'kl_vok_correct',
            'seen' => 'kl_vok_seen_ids',
            _ => 'kl_wrong_count_v1',
          };
          final initial = switch (field) {
            'integer' => 5,
            'seen' => <String>['local'],
            _ => '{"word":2}',
          };
          platform.values[key] = initial;
          final prefs = await SharedPreferences.getInstance();
          await prefs.reload();
          final read = platform.holdNextRead();
          final retiring = PackCompletionStorage.retire();
          final entered = Completer<void>();
          final release = Completer<void>();
          Future<bool>? saving;
          VocabProgressAttempt attempt(String id) => switch (field) {
            'integer' => VocabProgressAttempt(correctDelta: 1),
            'seen' => VocabProgressAttempt(seenId: id),
            _ => VocabProgressAttempt(wrongCountId: 'word'),
          };
          try {
            await read.entered.future;
            platform
              ..rejectKey = key
              ..writeEntered = entered
              ..releaseWrite = release
              ..commitBeforeFailure = true
              ..successfulReply = true;
            saving = attempt('learned').save();
            await entered.future;
            if (writeFirst) {
              release.complete();
              await saving;
            }
            read.release.complete();
            await retiring;
            expect(
              prefs.get(key),
              initial,
              reason: 'Held native snapshot really displaced the cache.',
            );
            if (!writeFirst) {
              release.complete();
              await saving;
            }
            if (field == 'wrong-count') {
              expect(Storage.wrongCountRawJson, '{"word":3}');
            }
            platform
              ..rejectKey = null
              ..releaseWrite = null;
            await attempt('next').save();
            switch (field) {
              case 'integer':
                expect(platform.values[key], 7);
                expect(Storage.vokCorrect, 7);
              case 'seen':
                expect(platform.values[key], ['local', 'learned', 'next']);
                expect(Storage.vokSeenIds, ['local', 'learned', 'next']);
              case 'wrong-count':
                expect(platform.values[key], '{"word":4}');
                expect(Storage.wrongCountOf('word'), 4);
            }
          } finally {
            if (!read.release.isCompleted) {
              read.release.complete();
            }
            if (!release.isCompleted) {
              release.complete();
            }
            await retiring;
            await saving;
          }
        },
      );
    }

    test(
      'retirement reload preserves confirmed $field and queued successor',
      () async {
        final key = switch (field) {
          'integer' => 'kl_vok_correct',
          'seen' => 'kl_vok_seen_ids',
          _ => 'kl_wrong_count_v1',
        };
        final initial = switch (field) {
          'integer' => 5,
          'seen' => <String>['local'],
          _ => '{"word":2}',
        };
        platform.values[key] = initial;
        final prefs = await SharedPreferences.getInstance();
        await prefs.reload();
        final entered = Completer<void>();
        final release = Completer<void>();
        platform
          ..rejectKey = key
          ..writeEntered = entered
          ..releaseWrite = release
          ..commitBeforeFailure = true
          ..successfulReply = true;
        VocabProgressAttempt attempt(String id) => switch (field) {
          'integer' => VocabProgressAttempt(correctDelta: 1),
          'seen' => VocabProgressAttempt(seenId: id),
          _ => VocabProgressAttempt(wrongCountId: 'word'),
        };
        final first = attempt('learned').save();
        try {
          await entered.future;
          await PackCompletionStorage.retire();
          expect(
            prefs.get(key),
            initial,
            reason: 'Native reload displaced the optimistic setter.',
          );
          final next = attempt('cloud').save();
          release.complete();
          await first;
          platform
            ..rejectKey = null
            ..releaseWrite = null;
          await next;
          switch (field) {
            case 'integer':
              expect(Storage.vokCorrect, 7);
              expect(platform.values[key], 7);
            case 'seen':
              expect(Storage.vokSeenIds, ['local', 'learned', 'cloud']);
              expect(platform.values[key], ['local', 'learned', 'cloud']);
            case 'wrong-count':
              expect(Storage.wrongCountOf('word'), 4);
              expect(Storage.wrongCountRawJson, '{"word":4}');
              expect(platform.values[key], '{"word":4}');
          }
          // Explicit external replacement retires the retained confirmed value.
          platform.values[key] = initial;
          await prefs.reload();
          Storage.resetCachesAfterExternalWrite();
          switch (field) {
            case 'integer':
              expect(Storage.vokCorrect, 5);
            case 'seen':
              expect(Storage.vokSeenIds, ['local']);
            case 'wrong-count':
              expect(Storage.wrongCountOf('word'), 2);
          }
          platform.values.remove(key);
          await prefs.reload();
          Storage.resetCachesAfterExternalWrite();
          switch (field) {
            case 'integer':
              expect(Storage.vokCorrect, 0);
            case 'seen':
              expect(Storage.vokSeenIds, isEmpty);
            case 'wrong-count':
              expect(Storage.wrongCountRawJson, isEmpty);
          }
        } finally {
          if (!release.isCompleted) {
            release.complete();
          }
          await first;
        }
      },
    );
  }

  test(
    'a successor field entering an unresolved read keeps its confirmed union',
    () async {
      platform.values.addAll({
        'kl_vok_correct': 5,
        'kl_vok_seen_ids': <String>['local'],
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final firstEntered = Completer<void>();
      final firstRelease = Completer<void>();
      final nextEntered = Completer<void>();
      final nextRelease = Completer<void>();
      platform
        ..rejectKey = 'kl_vok_correct'
        ..writeEntered = firstEntered
        ..releaseWrite = firstRelease
        ..commitBeforeFailure = true
        ..successfulReply = true;
      final first = VocabProgressAttempt(correctDelta: 1).save();
      final read = platform.holdNextRead();
      Future<void>? reloading;
      Future<bool>? next;
      try {
        await firstEntered.future;
        reloading = Storage.reloadForPackCompletion(prefs);
        await read.entered.future;
        firstRelease.complete();
        await first;
        platform
          ..rejectKey = 'kl_vok_seen_ids'
          ..writeEntered = nextEntered
          ..releaseWrite = nextRelease;
        next = VocabProgressAttempt(seenId: 'learned').save();
        await nextEntered.future;
        read.release.complete();
        await reloading;
        nextRelease.complete();
        await next;
        platform
          ..rejectKey = null
          ..releaseWrite = null;
        await VocabProgressAttempt(correctDelta: 1, seenId: 'next').save();
        expect(Storage.vokCorrect, 7);
        expect(platform.values['kl_vok_correct'], 7);
        expect(Storage.vokSeenIds, ['local', 'learned', 'next']);
        expect(platform.values['kl_vok_seen_ids'], [
          'local',
          'learned',
          'next',
        ]);
      } finally {
        if (!firstRelease.isCompleted) {
          firstRelease.complete();
        }
        if (!nextRelease.isCompleted) {
          nextRelease.complete();
        }
        if (!read.release.isCompleted) {
          read.release.complete();
        }
        await first;
        await next;
        await reloading;
      }
    },
  );

  test(
    'a second overlapping native read remains owned after the first settles',
    () async {
      platform.values['kl_vok_correct'] = 5;
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final firstRead = platform.holdNextRead();
      final first = Storage.reloadForPackCompletion(prefs);
      await firstRead.entered.future;
      final secondRead = platform.holdNextRead();
      final second = Storage.reloadForPackCompletion(prefs);
      try {
        await secondRead.entered.future;
        firstRead.release.complete();
        await first;
        await VocabProgressAttempt(correctDelta: 1).save();
        secondRead.release.complete();
        await second;
        expect(prefs.getInt('kl_vok_correct'), 5);
        expect(Storage.vokCorrect, 6);
        await VocabProgressAttempt(correctDelta: 1).save();
        expect(platform.values['kl_vok_correct'], 7);
      } finally {
        if (!firstRead.release.isCompleted) {
          firstRead.release.complete();
        }
        if (!secondRead.release.isCompleted) {
          secondRead.release.complete();
        }
        await first;
        await second;
      }
    },
  );

  test(
    'caller timeout and logical invalidation do not retire the actual cache read',
    () async {
      platform.values['kl_vok_correct'] = 5;
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final read = platform.holdNextRead();
      final reloading = Storage.reloadForPackCompletion(prefs);
      try {
        await read.entered.future;
        await expectLater(
          reloading.timeout(Duration.zero),
          throwsA(isA<TimeoutException>()),
        );
        Storage.resetCachesAfterExternalWrite();
        await VocabProgressAttempt(correctDelta: 1).save();
        read.release.complete();
        await reloading;
        expect(prefs.getInt('kl_vok_correct'), 5);
        expect(Storage.vokCorrect, 6);
        await VocabProgressAttempt(correctDelta: 1).save();
        expect(platform.values['kl_vok_correct'], 7);
        platform.values.remove('kl_vok_correct');
        await prefs.reload();
        Storage.resetCachesAfterExternalWrite();
        expect(Storage.vokCorrect, 0);
      } finally {
        if (!read.release.isCompleted) {
          read.release.complete();
        }
        await reloading;
      }
    },
  );

  for (final reply in ['false', 'unknown-applied', 'unknown-unapplied']) {
    test(
      'writer entering delayed read preserves absent before-state for $reply',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final read = platform.holdNextRead();
        final reloading = Storage.reloadForPackCompletion(prefs);
        final entered = Completer<void>();
        final release = Completer<void>();
        Future<Object?>? saving;
        final attempt = VocabProgressAttempt(correctDelta: 1);
        try {
          await read.entered.future;
          platform
            ..rejectKey = 'kl_vok_correct'
            ..writeEntered = entered
            ..releaseWrite = release
            ..throwReply = reply.startsWith('unknown')
            ..failReloadAfterWrite = reply.startsWith('unknown')
            ..commitBeforeFailure = reply == 'unknown-applied';
          saving = attempt.save().then<Object?>(
            (value) => value,
            onError: (Object error) => error,
          );
          await entered.future;
          read.release.complete();
          await reloading;
          release.complete();
          expect(
            await saving,
            reply == 'false'
                ? isA<PreferenceWriteException>()
                : isA<PreferenceOutcomeUnknownException>(),
          );
          expect(Storage.vokCorrect, 0);
          expect(
            platform.values.containsKey('kl_vok_correct'),
            reply == 'unknown-applied',
          );
          platform
            ..rejectKey = null
            ..releaseWrite = null
            ..unavailable = false;
          expect(await attempt.save(), isTrue);
          expect(Storage.vokCorrect, 1);
          expect(platform.values['kl_vok_correct'], 1);
          expect(
            platform.writes['kl_vok_correct'],
            reply == 'unknown-applied' ? 1 : 2,
          );
        } finally {
          if (!read.release.isCompleted) {
            read.release.complete();
          }
          if (!release.isCompleted) {
            release.complete();
          }
          await reloading;
          await saving;
        }
      },
    );
  }

  test(
    'an old cache read cannot pin a write on a replacement cache instance',
    () async {
      final oldPrefs = await SharedPreferences.getInstance();
      final oldPlatform = platform;
      final read = oldPlatform.holdNextRead();
      final reloading = Storage.reloadForPackCompletion(oldPrefs);
      try {
        await read.entered.future;
        Storage.resetForTesting();
        SharedPreferences.setMockInitialValues(const <String, Object>{});
        platform = _DelayedReadPlatform()..values['kl_vok_correct'] = 5;
        SharedPreferencesStorePlatform.instance = platform;
        await Storage.init();
        final newPrefs = await SharedPreferences.getInstance();
        expect(identical(oldPrefs, newPrefs), isFalse);
        await VocabProgressAttempt(correctDelta: 1).save();
        read.release.complete();
        await reloading;
        expect(Storage.vokCorrect, 6);
        // No Task47 read touched this cache, so this confirmed value is not pinned.
        platform.values['kl_vok_correct'] = 2;
        await newPrefs.reload();
        expect(Storage.vokCorrect, 2);
      } finally {
        if (!read.release.isCompleted) {
          read.release.complete();
        }
        await reloading;
      }
    },
  );

  test(
    'a failed native read releases its interval without pinning later writes',
    () async {
      final prefs = await SharedPreferences.getInstance();
      platform.unavailable = true;
      await expectLater(
        Storage.reloadForPackCompletion(prefs),
        throwsStateError,
      );
      platform.unavailable = false;
      await VocabProgressAttempt(correctDelta: 1).save();
      platform.values['kl_vok_correct'] = 2;
      await prefs.reload();
      expect(Storage.vokCorrect, 2);
    },
  );

  for (final reply in [
    'false',
    'unknown-applied',
    'unknown-unapplied',
    'retired',
  ]) {
    test('displaced pending value stays unconfirmed for $reply', () async {
      platform.values['kl_vok_correct'] = 5;
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final entered = Completer<void>();
      final release = Completer<void>();
      platform
        ..rejectKey = 'kl_vok_correct'
        ..writeEntered = entered
        ..releaseWrite = release
        ..throwReply = reply.startsWith('unknown')
        ..failReloadAfterWrite = reply.startsWith('unknown')
        ..successfulReply = reply == 'retired'
        ..commitBeforeFailure =
            reply == 'unknown-applied' || reply == 'retired';
      final attempt = VocabProgressAttempt(correctDelta: 1);
      final outcome = attempt.save().then<Object?>(
        (value) => value,
        onError: (Object error) => error,
      );
      try {
        await entered.future;
        // Owner validation uses the same shared-cache preservation boundary.
        await PackCompletionOwner.confirm();
        expect(Storage.vokCorrect, 5);
        if (reply == 'retired') {
          Storage.resetCachesAfterExternalWrite();
        }
        release.complete();
        final result = await outcome;
        expect(
          result,
          reply == 'retired'
              ? isA<StaleLocalDataLifetimeException>()
              : reply == 'false'
              ? isA<PreferenceWriteException>()
              : isA<PreferenceOutcomeUnknownException>(),
        );
        if (reply != 'retired') {
          expect(Storage.vokCorrect, 5);
        }
        platform
          ..rejectKey = null
          ..releaseWrite = null
          ..unavailable = false;
        if (reply == 'retired') {
          platform.values['kl_vok_correct'] = 2;
          await prefs.reload();
          expect(
            Storage.vokCorrect,
            2,
            reason: 'An old completion cannot repin a retired baseline.',
          );
        } else {
          expect(await attempt.save(), isTrue);
          expect(Storage.vokCorrect, 6);
          expect(platform.values['kl_vok_correct'], 6);
          expect(
            platform.writes['kl_vok_correct'],
            reply == 'unknown-applied' ? 1 : 2,
          );
        }
      } finally {
        if (!release.isCompleted) {
          release.complete();
        }
        await outcome;
      }
    });
  }

  test('cloud write fence is checked again at queued execution', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    platform
      ..rejectKey = 'kl_vok_correct'
      ..writeEntered = entered
      ..releaseWrite = release
      ..commitBeforeFailure = true
      ..successfulReply = true;
    final local = VocabProgressAttempt(correctDelta: 1).save();
    await entered.future;
    var writable = true;
    final restoring = CloudSync.applyRestorePayload(
      <String, dynamic>{
        'vok': <String, dynamic>{'wrong': 7},
      },
      beforeWrite: () {
        if (!writable) throw StateError('account changed');
      },
    );
    writable = false;
    release.complete();
    await local;
    await expectLater(restoring, throwsStateError);
    expect(Storage.vokWrong, 0);
    expect(platform.values['kl_vok_wrong'], isNull);
  });

  test(
    'cloud restore propagates an unknown native vocabulary outcome',
    () async {
      platform
        ..rejectKey = 'kl_vok_correct'
        ..throwReply = true
        ..commitBeforeFailure = true
        ..failReloadAfterWrite = true;

      await expectLater(
        CloudSync.applyRestorePayload(<String, dynamic>{
          'vok': <String, dynamic>{'correct': 7},
        }),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );
      expect(Storage.vokCorrect, 0);

      platform
        ..unavailable = false
        ..rejectKey = null;
      await CloudSync.applyRestorePayload(<String, dynamic>{
        'vok': <String, dynamic>{'correct': 7},
      });
      expect(Storage.vokCorrect, 7);
      expect(platform.writes['kl_vok_correct'], 1);
    },
  );

  test('cursor-only restore does not replace initialized vocabulary', () async {
    await VocabProgressAttempt(correctDelta: 1, seenId: 'local').save();
    await Storage.setVokLastIdx(3);

    await CloudSync.applyRestorePayload(<String, dynamic>{
      'vok': <String, dynamic>{'last_idx': 17},
    });

    expect(Storage.vokLastIdx, 3);
  });

  test('cursor-only restore initializes empty vocabulary', () async {
    await CloudSync.applyRestorePayload(<String, dynamic>{
      'vok': <String, dynamic>{'last_idx': 17},
    });

    expect(Storage.vokLastIdx, 17);
  });

  test(
    'resetForTesting drains old vocabulary writes before a new boundary',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      platform
        ..rejectKey = 'kl_vok_seen_ids'
        ..writeEntered = entered
        ..releaseWrite = release
        ..commitBeforeFailure = true
        ..successfulReply = true;
      final oldWrite = VocabProgressAttempt(seenId: 'old').save();
      await entered.future;

      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues(<String, Object>{
        'kl_vok_seen_ids': <String>['new'],
      });
      release.complete();
      await expectLater(
        oldWrite,
        throwsA(isA<StaleLocalDataLifetimeException>()),
      );
      await Storage.init();
      expect(Storage.vokSeenIds, <String>['new']);
    },
  );

  for (final failureKey in <String>['kl_vok_seen_ids', 'kl_wrong_count_v1']) {
    for (final committed in <bool>[false, true]) {
      test(
        'multi-leg retry preserves confirmed fields when $failureKey is unknown; committed=$committed',
        () async {
          final attempt = VocabProgressAttempt(
            correctDelta: 1,
            seenId: '하다',
            wrongCountId: '하다',
          );
          platform
            ..rejectKey = failureKey
            ..throwReply = true
            ..commitBeforeFailure = committed
            ..failReloadAfterWrite = true;

          await expectLater(
            attempt.save(),
            throwsA(isA<PreferenceOutcomeUnknownException>()),
          );
          expect(Storage.vokCorrect, 1);
          expect(
            Storage.vokSeenIds,
            failureKey == 'kl_wrong_count_v1' ? <String>['하다'] : isEmpty,
          );
          expect(Storage.wrongCountOf('하다'), 0);

          platform
            ..unavailable = false
            ..rejectKey = null;
          expect(await attempt.save(), isTrue);
          expect(await attempt.save(), isTrue);
          expect(Storage.vokCorrect, 1);
          expect(Storage.vokSeenIds, <String>['하다']);
          expect(Storage.wrongCountOf('하다'), 1);
          expect(platform.writes['kl_vok_correct'], 1);
          expect(platform.writes[failureKey], committed ? 1 : 2);
          if (failureKey == 'kl_vok_seen_ids') {
            expect(platform.writes['kl_wrong_count_v1'], 1);
          } else {
            expect(platform.writes['kl_vok_seen_ids'], 1);
          }
        },
      );
    }
  }

  test(
    'later rejected list leg keeps confirmed export and retries once',
    () async {
      platform.values.addAll(<String, Object>{
        'kl_vok_correct': 3,
        'kl_vok_seen_ids': <String>['old'],
        'kl_wrong_count_v1': '{"하다":1}',
      });
      await (await SharedPreferences.getInstance()).reload();
      final entered = Completer<void>();
      final release = Completer<void>();
      final attempt = VocabProgressAttempt(
        correctDelta: 1,
        seenId: 'new',
        wrongCountId: '하다',
      );
      platform
        ..rejectKey = 'kl_vok_seen_ids'
        ..writeEntered = entered
        ..releaseWrite = release;

      final saving = attempt.save();
      await entered.future;
      final pendingExport = LearningDataExportService.buildPackage().data;
      final pendingVocabulary =
          (pendingExport['progress'] as Map)['vocabulary'] as Map;
      expect(pendingVocabulary['correct'], 4);
      expect(pendingVocabulary['seenIds'], <String>['old']);
      expect((pendingExport['review'] as Map)['wrongCounts'], <String, int>{
        '하다': 1,
      });
      release.complete();
      await expectLater(saving, throwsA(isA<PreferenceWriteException>()));

      platform
        ..rejectKey = null
        ..releaseWrite = null;
      expect(await attempt.save(), isTrue);
      final confirmedExport = LearningDataExportService.buildPackage().data;
      final confirmedVocabulary =
          (confirmedExport['progress'] as Map)['vocabulary'] as Map;
      expect(confirmedVocabulary['correct'], 4);
      expect(confirmedVocabulary['seenIds'], <String>['old', 'new']);
      expect((confirmedExport['review'] as Map)['wrongCounts'], <String, int>{
        '하다': 2,
      });
      expect(platform.writes['kl_vok_correct'], 1);
      expect(platform.writes['kl_vok_seen_ids'], 2);
      expect(platform.writes['kl_wrong_count_v1'], 1);
    },
  );

  test(
    'third native value keeps an unknown string outcome fail closed',
    () async {
      platform.values['kl_wrong_count_v1'] = '{"하다":1}';
      await (await SharedPreferences.getInstance()).reload();
      final attempt = VocabProgressAttempt(wrongCountId: '하다');
      platform
        ..rejectKey = 'kl_wrong_count_v1'
        ..throwReply = true
        ..commitBeforeFailure = false
        ..failReloadAfterWrite = true;

      await expectLater(
        attempt.save(),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );
      expect(Storage.wrongCountOf('하다'), 1);
      platform
        ..unavailable = false
        ..values['kl_wrong_count_v1'] = '{"하다":99}';
      await expectLater(
        attempt.save(),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );
      expect(Storage.wrongCountOf('하다'), 1);
      expect(
        (LearningDataExportService.buildPackage().data['review']
            as Map)['wrongCounts'],
        <String, int>{'하다': 1},
      );
      expect(platform.writes['kl_wrong_count_v1'], 1);
    },
  );

  test(
    'session reset drains vocabulary writes and preserves wrong history',
    () async {
      await VocabProgressAttempt(
        correctDelta: 2,
        wrongDelta: 1,
        skippedDelta: 1,
        cursor: 4,
        seenId: 'before',
        wrongCountId: 'before',
      ).save();
      final entered = Completer<void>();
      final release = Completer<void>();
      platform
        ..rejectKey = 'kl_vok_correct'
        ..writeEntered = entered
        ..releaseWrite = release
        ..successfulReply = true
        ..commitBeforeFailure = true;
      final learning = VocabProgressAttempt(
        correctDelta: 1,
        seenId: 'late',
      ).save();
      await entered.future;

      final reset = Storage.resetSession();
      release.complete();
      expect(await learning, isTrue);
      await reset;

      expect(Storage.vokCorrect, 0);
      expect(Storage.vokWrong, 0);
      expect(Storage.vokSkipped, 0);
      expect(Storage.vokLastIdx, 0);
      expect(Storage.vokSeenIds, isEmpty);
      expect(Storage.wrongCountOf('before'), 1);
      expect(platform.values['kl_wrong_count_v1'], '{"before":1}');
    },
  );

  test(
    'learning lock rejects progress before native or cache mutation',
    () async {
      Storage.lockLearningWrites('future schema');
      final attempt = VocabProgressAttempt(
        correctDelta: 1,
        seenId: 'blocked',
        wrongCountId: 'blocked',
      );

      expect(await attempt.save(), isFalse);
      expect(Storage.vokCorrect, 0);
      expect(Storage.vokSeenIds, isEmpty);
      expect(Storage.wrongCountOf('blocked'), 0);
      expect(platform.writes['kl_vok_correct'], isNull);
      expect(platform.writes['kl_vok_seen_ids'], isNull);
      expect(platform.writes['kl_wrong_count_v1'], isNull);
    },
  );

  test('learning lock also rejects every public vocabulary setter', () async {
    Storage.lockLearningWrites('future schema');

    for (final setter in <({String key, Future<void> Function() run})>[
      (key: 'kl_vok_correct', run: () => Storage.setVokCorrect(4)),
      (key: 'kl_vok_wrong', run: () => Storage.setVokWrong(3)),
      (key: 'kl_vok_skipped', run: () => Storage.setVokSkipped(2)),
      (key: 'kl_vok_last_idx', run: () => Storage.setVokLastIdx(1)),
    ]) {
      await expectLater(setter.run(), throwsA(isA<PreferenceWriteException>()));
      expect(platform.writes[setter.key], isNull);
    }

    expect(Storage.vokCorrect, 0);
    expect(Storage.vokWrong, 0);
    expect(Storage.vokSkipped, 0);
    expect(Storage.vokLastIdx, 0);
  });

  for (final strict in <bool>[false, true]) {
    test(
      'session reset owns the learning-reset boundary against ${strict ? 'resetAllStrict' : 'resetAll'}',
      () async {
        platform.values.addAll(<String, Object>{
          'kl_vok_correct': 4,
          'kl_vok_seen_ids': <String>['old'],
        });
        await (await SharedPreferences.getInstance()).reload();
        final entered = Completer<void>();
        final release = Completer<void>();
        platform
          ..rejectKey = 'kl_vok_correct'
          ..writeEntered = entered
          ..releaseWrite = release
          ..commitBeforeFailure = true
          ..successfulReply = true;

        final sessionReset = Storage.resetSession();
        await entered.future;
        Object? concurrentResetError;
        try {
          if (strict) {
            await Storage.resetAllStrict();
          } else {
            await Storage.resetAll();
          }
        } on Object catch (error) {
          concurrentResetError = error;
        }
        release.complete();
        await sessionReset;

        expect(concurrentResetError, isA<StateError>());
        await Storage.resetAllStrict();
        expect(
          platform.values.keys.where((key) => key.startsWith('kl_')),
          isEmpty,
        );
      },
    );
  }

  test(
    'resetForTesting drains an active session reset before a new preference boundary',
    () async {
      platform.values['kl_vok_correct'] = 5;
      await (await SharedPreferences.getInstance()).reload();
      final oldPlatform = platform;
      final entered = Completer<void>();
      final release = Completer<void>();
      oldPlatform
        ..rejectKey = 'kl_vok_correct'
        ..writeEntered = entered
        ..releaseWrite = release
        ..commitBeforeFailure = true
        ..successfulReply = true;

      final sessionReset = Storage.resetSession();
      await entered.future;
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      platform = _DelayedReadPlatform()..values['kl_vok_correct'] = 9;
      SharedPreferencesStorePlatform.instance = platform;
      var initialized = false;
      final initializing = Storage.init().then((_) => initialized = true);
      await Future<void>.delayed(Duration.zero);
      final completedBeforeRelease = initialized;

      release.complete();
      await expectLater(
        sessionReset,
        throwsA(isA<StaleLocalDataLifetimeException>()),
      );
      await initializing;

      expect(completedBeforeRelease, isFalse);
      expect(Storage.vokCorrect, 9);
      expect(platform.values['kl_vok_correct'], 9);
      expect(oldPlatform.values['kl_vok_correct'], 0);
    },
  );

  for (final key in <String>['kl_vok_correct', 'kl_vok_seen_ids']) {
    for (final committed in <bool>[false, true]) {
      test(
        'account transition quarantines stale $key outcome; committed=$committed',
        () async {
          final sessions = CloudWriteSessionController();
          final accountA = sessions.acquire('uid-a');
          var accountAGuardChecks = 0;
          void assertAccountA() {
            accountAGuardChecks++;
            sessions.assertCurrent(accountA);
          }

          platform
            ..rejectKey = key
            ..throwReply = true
            ..commitBeforeFailure = committed
            ..failReloadAfterWrite = true;
          await expectLater(
            CloudSync.applyRestorePayload(<String, dynamic>{
              'vok': <String, dynamic>{
                if (key == 'kl_vok_correct') 'correct': 9,
                if (key == 'kl_vok_seen_ids') 'seen_ids': <String>['account-a'],
              },
            }, beforeWrite: assertAccountA),
            throwsA(isA<PreferenceOutcomeUnknownException>()),
          );
          final checksBeforeTransition = accountAGuardChecks;

          expect(Storage.vokCorrect, 0);
          expect(Storage.vokSeenIds, isEmpty);
          final pendingExport = LearningDataExportService.buildPackage().data;
          final pendingVocabulary =
              (pendingExport['progress'] as Map)['vocabulary'] as Map;
          expect(pendingVocabulary['correct'], 0);
          expect(pendingVocabulary['seenIds'], isEmpty);

          final accountB = sessions.acquire('uid-b');
          platform
            ..unavailable = false
            ..rejectKey = null;
          await CloudSync.applyRestorePayload(<String, dynamic>{
            'vok': <String, dynamic>{
              if (key == 'kl_vok_correct') 'correct': 3,
              if (key == 'kl_vok_seen_ids') 'seen_ids': <String>['account-b'],
            },
          }, beforeWrite: () => sessions.assertCurrent(accountB));

          expect(accountAGuardChecks, greaterThan(checksBeforeTransition));
          if (key == 'kl_vok_correct') {
            expect(Storage.vokCorrect, 3);
            expect(platform.values[key], 3);
          } else {
            expect(Storage.vokSeenIds, <String>['account-b']);
            expect(platform.values[key], <String>['account-b']);
          }
          final restoredExport = LearningDataExportService.buildPackage().data;
          final restoredVocabulary =
              (restoredExport['progress'] as Map)['vocabulary'] as Map;
          expect(
            restoredVocabulary['correct'],
            key == 'kl_vok_correct' ? 3 : 0,
          );
          expect(
            restoredVocabulary['seenIds'],
            key == 'kl_vok_seen_ids' ? <String>['account-b'] : isEmpty,
          );
        },
      );
    }
  }

  test(
    'stale committed account value is not rolled back for a no-op restore',
    () async {
      final sessions = CloudWriteSessionController();
      final accountA = sessions.acquire('uid-a');
      platform
        ..rejectKey = 'kl_vok_correct'
        ..throwReply = true
        ..commitBeforeFailure = true
        ..failReloadAfterWrite = true;

      await expectLater(
        CloudSync.applyRestorePayload(<String, dynamic>{
          'vok': <String, dynamic>{'correct': 9},
        }, beforeWrite: () => sessions.assertCurrent(accountA)),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );

      final accountB = sessions.acquire('uid-b');
      platform
        ..unavailable = false
        ..rejectKey = null;
      await expectLater(
        CloudSync.applyRestorePayload(<String, dynamic>{
          'vok': <String, dynamic>{'correct': 0},
        }, beforeWrite: () => sessions.assertCurrent(accountB)),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );

      expect(Storage.vokCorrect, 0);
      expect(platform.values['kl_vok_correct'], 9);
      expect(platform.writes['kl_vok_correct'], 1);
    },
  );

  for (final key in <String>['kl_vok_correct', 'kl_vok_seen_ids']) {
    test('quarantined $key rejects an unrelated third native value', () async {
      final sessions = CloudWriteSessionController();
      final accountA = sessions.acquire('uid-a');
      platform
        ..rejectKey = key
        ..throwReply = true
        ..commitBeforeFailure = true
        ..failReloadAfterWrite = true;
      await expectLater(
        CloudSync.applyRestorePayload(<String, dynamic>{
          'vok': <String, dynamic>{
            if (key == 'kl_vok_correct') 'correct': 9,
            if (key == 'kl_vok_seen_ids') 'seen_ids': <String>['account-a'],
          },
        }, beforeWrite: () => sessions.assertCurrent(accountA)),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );

      final accountB = sessions.acquire('uid-b');
      platform
        ..unavailable = false
        ..rejectKey = null
        ..values[key] = key == 'kl_vok_correct' ? 77 : <String>['external'];
      await expectLater(
        CloudSync.applyRestorePayload(<String, dynamic>{
          'vok': <String, dynamic>{
            if (key == 'kl_vok_correct') 'correct': 3,
            if (key == 'kl_vok_seen_ids') 'seen_ids': <String>['account-b'],
          },
        }, beforeWrite: () => sessions.assertCurrent(accountB)),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );

      expect(Storage.vokCorrect, 0);
      expect(Storage.vokSeenIds, isEmpty);
      expect(
        platform.values[key],
        key == 'kl_vok_correct' ? 77 : <String>['external'],
      );
      expect(platform.writes[key], 1);
      final export = LearningDataExportService.buildPackage().data;
      final vocabulary = (export['progress'] as Map)['vocabulary'] as Map;
      expect(vocabulary['correct'], 0);
      expect(vocabulary['seenIds'], isEmpty);
    });
  }

  for (final key in <String>[
    'kl_vok_correct',
    'kl_vok_seen_ids',
    'kl_wrong_count_v1',
  ]) {
    for (final outcome
        in <({String label, bool committed, bool throws, bool succeeds})>[
          (label: 'success', committed: true, throws: false, succeeds: true),
          (
            label: 'false committed',
            committed: true,
            throws: false,
            succeeds: false,
          ),
          (
            label: 'false uncommitted',
            committed: false,
            throws: false,
            succeeds: false,
          ),
          (
            label: 'throw committed',
            committed: true,
            throws: true,
            succeeds: false,
          ),
          (
            label: 'throw uncommitted',
            committed: false,
            throws: true,
            succeeds: false,
          ),
        ]) {
      test('delayed ${outcome.label} quarantines stale-origin $key', () async {
        final sessions = CloudWriteSessionController();
        final accountA = sessions.acquire('uid-a');
        var accountAGuardChecks = 0;
        void assertAccountA() {
          accountAGuardChecks++;
          sessions.assertCurrent(accountA);
        }

        final entered = Completer<void>();
        final release = Completer<void>();
        platform
          ..rejectKey = key
          ..throwReply = outcome.throws
          ..commitBeforeFailure = outcome.committed
          ..successfulReply = outcome.succeeds
          ..writeEntered = entered
          ..releaseWrite = release;
        final restoringA = CloudSync.applyRestorePayload(<String, dynamic>{
          if (key == 'kl_vok_correct') 'vok': <String, dynamic>{'correct': 9},
          if (key == 'kl_vok_seen_ids')
            'vok': <String, dynamic>{
              'seen_ids': <String>['account-a'],
            },
          if (key == 'kl_wrong_count_v1') 'wrong_count_json': '{"account-a":9}',
        }, beforeWrite: assertAccountA);
        await entered.future;
        final checksBeforeTransition = accountAGuardChecks;
        final accountB = sessions.acquire('uid-b');
        release.complete();

        await expectLater(restoringA, throwsStateError);
        expect(accountAGuardChecks, greaterThan(checksBeforeTransition));
        expect(Storage.vokCorrect, 0);
        expect(Storage.vokSeenIds, isEmpty);
        expect(Storage.wrongCountRawJson, isEmpty);
        final pendingExport = LearningDataExportService.buildPackage().data;
        final pendingVocabulary =
            (pendingExport['progress'] as Map)['vocabulary'] as Map;
        expect(pendingVocabulary['correct'], 0);
        expect(pendingVocabulary['seenIds'], isEmpty);
        expect((pendingExport['review'] as Map)['wrongCounts'], isEmpty);

        platform
          ..rejectKey = null
          ..throwReply = false
          ..successfulReply = false
          ..releaseWrite = null;
        await CloudSync.applyRestorePayload(<String, dynamic>{
          if (key == 'kl_vok_correct') 'vok': <String, dynamic>{'correct': 3},
          if (key == 'kl_vok_seen_ids')
            'vok': <String, dynamic>{
              'seen_ids': <String>['account-b'],
            },
          if (key == 'kl_wrong_count_v1') 'wrong_count_json': '{"account-b":3}',
        }, beforeWrite: () => sessions.assertCurrent(accountB));

        expect(Storage.vokCorrect, key == 'kl_vok_correct' ? 3 : 0);
        expect(
          Storage.vokSeenIds,
          key == 'kl_vok_seen_ids' ? <String>['account-b'] : isEmpty,
        );
        expect(
          Storage.wrongCountRawJson,
          key == 'kl_wrong_count_v1' ? '{"account-b":3}' : isEmpty,
        );
        expect(platform.values[key], switch (key) {
          'kl_vok_correct' => 3,
          'kl_vok_seen_ids' => <String>['account-b'],
          _ => '{"account-b":3}',
        });
        final restoredExport = LearningDataExportService.buildPackage().data;
        expect(
          (restoredExport['review'] as Map)['wrongCounts'],
          key == 'kl_wrong_count_v1' ? <String, int>{'account-b': 3} : isEmpty,
        );
      });
    }
  }
}
