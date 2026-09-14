import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/srs_commit_journal.dart';
import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/learning_data_export_service.dart';
import 'support/reward_preferences_platform.dart';

class RecoveryPreferences extends RewardPreferencesPlatform {
  bool rejectRemoval = false;
  bool commitRemoval = false;
  bool loseRemovalRead = false;
  final mutations = <String>[];

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    mutations.add(key.substring('flutter.'.length));
    return super.setValue(valueType, key, value);
  }

  @override
  Future<bool> remove(String key) async {
    mutations.add('remove:$key');
    if (key == 'flutter.${SrsCommitJournal.key}' && rejectRemoval) {
      if (commitRemoval) {
        values.remove(SrsCommitJournal.key);
      }
      if (loseRemovalRead) {
        unavailable = true;
      }
      return false;
    }
    return super.remove(key);
  }
}

SrsCommitJournal journal({bool history = true}) => SrsCommitJournal(
  date: '2026-09-01',
  recordHistory: history,
  beforeDeck: null,
  afterDeck: jsonEncode({
    'original': {'e': 2.55, 'i': 1, 'n': '2026-09-02', 'r': 1},
  }),
  beforeHistory: history ? ['earlier'] : null,
  afterHistory: history ? ['earlier', 'original'] : null,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RecoveryPreferences native;
  setUp(() {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    native = RecoveryPreferences();
    SharedPreferencesStorePlatform.instance = native;
  });

  group('partial deck structural repair before judgment', () {
    final damaged = jsonEncode({
      'kept': {'e': 2.5, 'i': 3, 'n': '2026-01-01', 'r': 2},
      'broken': 'original damaged evidence',
    });
    final normalized = jsonEncode({
      'kept': {'e': 2.5, 'i': 3, 'n': '2026-01-01', 'r': 2},
    });
    final evidenceKey =
        '${Storage.srsQuarantinePreferenceKey}_${sha256.convert(utf8.encode(damaged))}';

    setUp(() async {
      native.values['kl_srs_v1'] = damaged;
      await Storage.init();
    });

    void expectUnadmitted() {
      expect(native.values.containsKey(SrsCommitJournal.key), isFalse);
      expect(
        native.values.keys.where((key) => key.startsWith('kl_study_log_v1_')),
        isEmpty,
      );
    }

    test(
      'keeps prior quarantine and exact new evidence; repair is idempotent',
      () async {
        native.values[Storage.srsQuarantinePreferenceKey] = 'previous damage';
        final attempt = SrsReviewAttempt(id: 'answer', gotIt: true);
        expect(await attempt.save(), isTrue);
        expect(
          native.values[Storage.srsQuarantinePreferenceKey],
          'previous damage',
        );
        expect(native.values[evidenceKey], damaged);
        expect(Storage.srsCard('kept')!.reviewCount, 2);
        expect(Storage.srsCard('answer')!.reviewCount, 1);
        expect(native.mutations.take(3), [
          evidenceKey,
          'kl_srs_v1',
          SrsCommitJournal.key,
        ]);
        final mutations = List<String>.of(native.mutations);
        expect(await attempt.save(), isTrue);
        expect(await Storage.retrySrsRecovery(), isTrue);
        expect(native.mutations, mutations);
      },
    );

    for (final collision in ['different retained bytes', 42]) {
      test(
        'different evidence at deterministic key is never overwritten: $collision',
        () async {
          native.values[evidenceKey] = collision;
          expect(await Storage.srsReview('answer', gotIt: true), isFalse);
          expect(await Storage.retrySrsRecovery(), isFalse);
          expect(native.values[evidenceKey], collision);
          expect(native.values['kl_srs_v1'], damaged);
          expect(native.mutations, isEmpty);
          expectUnadmitted();
        },
      );
    }

    test(
      'matching retained copy is reused without another preservation write',
      () async {
        native.values[evidenceKey] = damaged;
        expect(await Storage.srsReview('answer', gotIt: true), isTrue);
        expect(native.writes[evidenceKey], isNull);
      },
    );

    test(
      'rejected preservation stops before normalization and remains retryable',
      () async {
        native.rejectKey = evidenceKey;
        final attempt = SrsReviewAttempt(id: 'answer', gotIt: true);
        expect(await attempt.save(), isFalse);
        expect(native.values['kl_srs_v1'], damaged);
        expect(native.values[evidenceKey], isNull);
        expect(native.writes['kl_srs_v1'], isNull);
        expectUnadmitted();
        native.rejectKey = null;
        expect(await attempt.save(), isTrue);
        expect(Storage.srsCard('answer')!.reviewCount, 1);
      },
    );

    for (final phase in ['preservation', 'normalization']) {
      for (final committed in [false, true]) {
        test(
          'unknown $phase committed=$committed reconciles before admission',
          () async {
            native
              ..rejectKey = phase == 'preservation' ? evidenceKey : 'kl_srs_v1'
              ..commitBeforeFailure = committed
              ..throwReply = true
              ..failReloadAfterWrite = true;
            final attempt = SrsReviewAttempt(id: 'answer', gotIt: true);
            expect(await attempt.save(), isFalse);
            expect(Storage.srsRecoveryPending, isTrue);
            expect(Storage.srsRawJson, damaged);
            expectUnadmitted();
            final mutations = List<String>.of(native.mutations);
            expect(await attempt.save(), isFalse);
            expect(native.mutations, mutations);
            native
              ..unavailable = false
              ..rejectKey = null;
            expect(await Storage.retrySrsRecovery(), isTrue);
            expect(native.values['kl_srs_v1'], normalized);
            expect(native.values[evidenceKey], damaged);
            expectUnadmitted();
            expect(await attempt.save(), isTrue);
            expect(Storage.srsCard('kept')!.reviewCount, 2);
            expect(Storage.srsCard('answer')!.reviewCount, 1);
            expect(
              native.writes['kl_srs_v1'],
              phase == 'normalization' && !committed ? 3 : 2,
            );
          },
        );
      }
    }

    for (final history in [List.generate(500, (i) => 'id$i'), 42]) {
      test(
        'invalid or full history preflights before structural effects: ${history is int}',
        () async {
          native.values['kl_study_log_v1_${Storage.todayIso()}'] = history;
          expect(await Storage.srsReview('answer', gotIt: true), isFalse);
          expect(native.values['kl_srs_v1'], damaged);
          expect(native.mutations, isEmpty);
          expect(native.values[evidenceKey], isNull);
        },
      );
    }

    test(
      'unknown normalization never overwrites a third native deck',
      () async {
        native
          ..rejectKey = 'kl_srs_v1'
          ..failReloadAfterWrite = true;
        expect(await Storage.srsReview('answer', gotIt: true), isFalse);
        native
          ..unavailable = false
          ..rejectKey = null;
        native.values['kl_srs_v1'] = '{}';
        final writes = native.writes['kl_srs_v1'];
        expect(await Storage.retrySrsRecovery(), isFalse);
        expect(Storage.srsRecoveryStatus.value, SrsRecoveryStatus.blocked);
        expect(native.values['kl_srs_v1'], '{}');
        expect(native.writes['kl_srs_v1'], writes);
        expectUnadmitted();
      },
    );

    testWidgets(
      'late normalization retains lane through timeout and reset retires caller',
      (tester) async {
        final entered = Completer<void>();
        final release = Completer<void>();
        native
          ..rejectKey = 'kl_srs_v1'
          ..writeEntered = entered
          ..releaseWrite = release
          ..commitBeforeFailure = true
          ..successfulReply = true;
        final attempt = SrsReviewAttempt(id: 'answer', gotIt: true);
        final saving = attempt.save();
        await tester.runAsync(() => entered.future);
        final retry = Storage.retrySrsRecovery();
        await tester.pump(const Duration(seconds: 6));
        expect(await retry, isFalse);
        expect(native.writes['kl_srs_v1'], 1);
        expect(Storage.srsRecoveryPending, isTrue);
        expectUnadmitted();
        final reset = Storage.resetAllStrict();
        expect(attempt.isCurrent, isFalse);
        release.complete();
        await tester.runAsync(() async {
          await saving;
          await reset;
        });
        expect(await saving, isFalse);
        expect(
          native.values.keys.where((key) => key.startsWith('kl_')),
          isEmpty,
        );
        expect(await attempt.save(), isFalse);
      },
    );
  });

  for (final cut in ['journal', 'deck', 'history', 'removed']) {
    test(
      'cold init recovers persisted $cut cut exactly once on original date',
      () async {
        final record = journal();
        native.values[record.historyKey] = record.beforeHistory!;
        if (cut != 'removed') {
          native.values[SrsCommitJournal.key] = record.encode();
        }
        if (cut != 'journal') {
          native.values['kl_srs_v1'] = record.afterDeck;
        }
        if (cut == 'history' || cut == 'removed') {
          native.values[record.historyKey] = record.afterHistory!;
        }
        await Storage.init();
        if (cut != 'removed') {
          expect(Storage.srsRecoveryPending, isTrue);
          expect(Storage.srsCard('original'), isNull);
          expect(Storage.studyLogIdsFor(record.date), ['earlier']);
        }
        expect(await Storage.retrySrsRecovery(), isTrue);
        expect(Storage.srsCard('original')!.reviewCount, 1);
        expect(Storage.studyLogIdsFor(record.date), record.afterHistory);
        expect(Storage.studyLogIdsFor(Storage.todayIso()), isEmpty);
        expect(native.values.containsKey(SrsCommitJournal.key), isFalse);
        final writes = List<String>.of(native.mutations);
        expect(await Storage.retrySrsRecovery(), isTrue);
        expect(native.mutations, writes);
      },
    );
  }

  for (final key in [SrsCommitJournal.key, 'kl_srs_v1', 'history']) {
    for (final throws in [false, true]) {
      test(
        'committed $key with ${throws ? 'throw' : 'false'} acknowledgement reconciles',
        () async {
          await Storage.init();
          native.rejectKey = key == 'history'
              ? 'kl_study_log_v1_${Storage.todayIso()}'
              : key;
          native.commitBeforeFailure = true;
          native.throwReply = throws;
          expect(await Storage.srsReview('answer', gotIt: true), isTrue);
          expect(Storage.srsCard('answer')!.reviewCount, 1);
          expect(Storage.studyLogIdsFor(Storage.todayIso()), ['answer']);
          expect(native.values.containsKey(SrsCommitJournal.key), isFalse);
        },
      );
    }
  }

  test(
    'native success reply without persisted effect is never completion',
    () async {
      await Storage.init();
      native.rejectKey = 'kl_study_log_v1_${Storage.todayIso()}';
      native.successfulReply = true;
      final attempt = SrsReviewAttempt(id: 'answer', gotIt: true);
      expect(await attempt.save(), isFalse);
      expect(Storage.srsRecoveryPending, isTrue);
      expect(Storage.srsCard('answer'), isNull);
      expect(native.values['kl_srs_v1'], contains('answer'));
      native.rejectKey = null;
      expect(await attempt.save(), isTrue);
      expect(await attempt.save(), isTrue);
      expect(Storage.srsCard('answer')!.reviewCount, 1);
    },
  );

  test(
    'unknown primary outcome fences writes and captures until native recovery',
    () async {
      await Storage.init();
      native.rejectKey = 'kl_srs_v1';
      native.commitBeforeFailure = true;
      native.failReloadAfterWrite = true;
      final attempt = SrsReviewAttempt(id: 'answer', gotIt: true);
      expect(await attempt.save(), isFalse);
      Storage.unlockLearningWrites();
      Storage.resetCachesAfterExternalWrite();
      expect(Storage.srsRecoveryPending, isTrue);
      expect(await Storage.srsReview('other', gotIt: true), isFalse);
      expect(
        CloudSync.buildBackupPayload(),
        throwsA(isA<SrsRecoveryPendingException>()),
      );
      expect(
        () => LearningDataExportService.buildPackage(),
        throwsA(isA<SrsRecoveryPendingException>()),
      );
      native.unavailable = false;
      native.rejectKey = null;
      expect(await Storage.retrySrsRecovery(), isTrue);
      expect(
        await attempt.save(),
        isFalse,
        reason: 'external replacement retires UI attempts',
      );
      expect(Storage.srsCard('answer')!.reviewCount, 1);
    },
  );

  test(
    'unknown unpersisted intent safely reopens only after fresh before proof',
    () async {
      await Storage.init();
      native.rejectKey = SrsCommitJournal.key;
      native.failReloadAfterWrite = true;
      final attempt = SrsReviewAttempt(id: 'answer', gotIt: true);
      expect(await attempt.save(), isFalse);
      expect(Storage.srsRecoveryPending, isTrue);
      native.unavailable = false;
      native.rejectKey = null;
      expect(await attempt.save(), isFalse);
      expect(Storage.srsRecoveryPending, isFalse);
      expect(await attempt.save(), isTrue);
      expect(Storage.srsCard('answer')!.reviewCount, 1);
    },
  );

  test('third history value arriving during deck write is preserved', () async {
    await Storage.init();
    final entered = Completer<void>();
    final release = Completer<void>();
    native.rejectKey = 'kl_srs_v1';
    native.writeEntered = entered;
    native.releaseWrite = release;
    native.commitBeforeFailure = true;
    final save = Storage.srsReview('answer', gotIt: true);
    await entered.future;
    final historyKey = 'kl_study_log_v1_${Storage.todayIso()}';
    native.values[historyKey] = ['external'];
    release.complete();
    expect(await save, isFalse);
    expect(native.values[historyKey], ['external']);
    expect(native.values.containsKey(SrsCommitJournal.key), isTrue);
  });

  test('malformed native deck is preserved before admission', () async {
    native.values['kl_srs_v1'] = '{"damaged":{"r":"wrong"}}';
    await Storage.init();
    expect(await Storage.srsReview('answer', gotIt: true), isFalse);
    expect(native.values['kl_srs_v1'], '{"damaged":{"r":"wrong"}}');
    expect(native.values.containsKey(SrsCommitJournal.key), isFalse);
  });

  for (final malformed in [
    'future',
    'invalid',
    'wrong-type',
    'third-deck',
    'third-history',
  ]) {
    test(
      '$malformed preserves evidence and blocks all affected replacements',
      () async {
        final record = journal();
        native.values[SrsCommitJournal.key] = switch (malformed) {
          'future' => record.encode().replaceFirst(
            '"version":1',
            '"version":2',
          ),
          'invalid' => '{',
          'wrong-type' => 42,
          _ => record.encode(),
        };
        native.values[record.historyKey] = malformed == 'third-history'
            ? ['external']
            : record.beforeHistory!;
        if (malformed == 'third-deck') {
          native.values['kl_srs_v1'] = '{}';
        }
        final before = jsonEncode(native.values);
        await Storage.init();
        expect(await Storage.retrySrsRecovery(), isFalse);
        expect(Storage.srsRecoveryStatus.value, SrsRecoveryStatus.blocked);
        await expectLater(
          Storage.setSrsRawJsonStrict('{}'),
          throwsA(isA<SrsRecoveryPendingException>()),
        );
        await expectLater(
          Storage.appendStudyLogEntryForRestore(record.date, 'remote'),
          throwsA(isA<SrsRecoveryPendingException>()),
        );
        await expectLater(
          Storage.restoreStudyLogDateForRestore(record.date, ['remote']),
          throwsA(isA<SrsRecoveryPendingException>()),
        );
        await Storage.pruneStudyLog(keepDays: 0);
        expect(jsonEncode(native.values), before);
      },
    );
  }

  test('history false recovers only deck and ignores a damaged date', () async {
    final record = journal(history: false);
    native.values.addAll({
      SrsCommitJournal.key: record.encode(),
      record.historyKey: 42,
    });
    await Storage.init();
    expect(await Storage.retrySrsRecovery(), isTrue);
    expect(Storage.srsCard('original')!.reviewCount, 1);
    expect(native.values[record.historyKey], 42);
  });

  test(
    'full history rejects before journal; existing ID at capacity is admitted',
    () async {
      final ids = List.generate(500, (i) => 'id$i');
      native.values['kl_study_log_v1_${Storage.todayIso()}'] = ids;
      await Storage.init();
      expect(await Storage.srsReview('overflow', gotIt: true), isFalse);
      expect(native.mutations, isEmpty);
      expect(await Storage.srsReview('id499', gotIt: true), isTrue);
      expect(Storage.studyLogIdsFor(Storage.todayIso()), ids);
    },
  );

  for (final malformed in [
    42,
    ['same', 'same'],
    [''],
  ]) {
    test('malformed history $malformed rejects before admission', () async {
      native.values['kl_study_log_v1_${Storage.todayIso()}'] = malformed;
      await Storage.init();
      expect(await Storage.srsReview('answer', gotIt: true), isFalse);
      expect(native.mutations, isEmpty);
    });
  }

  test(
    'unknown journal removal confirms effects without replaying on retry',
    () async {
      await Storage.init();
      native.rejectRemoval = true;
      native.commitRemoval = true;
      native.loseRemovalRead = true;
      final attempt = SrsReviewAttempt(id: 'answer', gotIt: true);
      expect(await attempt.save(), isFalse);
      expect(Storage.srsRecoveryPending, isTrue);
      native.unavailable = false;
      expect(await attempt.save(), isTrue);
      expect(Storage.srsCard('answer')!.reviewCount, 1);
      expect(native.writes['kl_srs_v1'], 1);
    },
  );

  test(
    'reset removes replay authority before data and does not resurrect',
    () async {
      final record = journal();
      native.values.addAll({
        SrsCommitJournal.key: record.encode(),
        'kl_srs_v1': record.afterDeck,
        record.historyKey: record.beforeHistory!,
      });
      await Storage.init();
      await Storage.resetAllStrict();
      expect(native.mutations.first, 'remove:flutter.${SrsCommitJournal.key}');
      expect(Storage.srsRecoveryPending, isFalse);
      expect(await Storage.retrySrsRecovery(), isTrue);
      expect(Storage.srsRawJson, isEmpty);
    },
  );

  test('rejected reset journal retirement touches no data', () async {
    final record = journal();
    native.values.addAll({
      SrsCommitJournal.key: record.encode(),
      'kl_srs_v1': record.afterDeck,
    });
    native.rejectRemoval = true;
    await Storage.init();
    await expectLater(
      Storage.resetAllStrict(),
      throwsA(isA<SrsRecoveryPendingException>()),
    );
    expect(native.values['kl_srs_v1'], record.afterDeck);
    expect(Storage.srsRecoveryPending, isTrue);
  });

  for (final precedence in [
    'kl_migration_journal_v1',
    Storage.accountDeletionCheckpointPreferenceKey,
  ]) {
    test('$precedence has precedence over SRS replay', () async {
      final record = journal();
      native.values.addAll({
        SrsCommitJournal.key: record.encode(),
        precedence: 'pending',
        record.historyKey: record.beforeHistory!,
      });
      await Storage.init();
      expect(await Storage.retrySrsRecovery(), isFalse);
      expect(Storage.srsRecoveryStatus.value, SrsRecoveryStatus.blocked);
      expect(native.mutations, isEmpty);
      native.values.remove(precedence);
      expect(await Storage.retrySrsRecovery(), isTrue);
    });
  }
}
