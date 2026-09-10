import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

import 'support/reward_preferences_platform.dart';

class _SrsPreferencesPlatform extends RewardPreferencesPlatform {
  String? rejectedDeck;

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    if (key == 'flutter.kl_srs_v1' && value == rejectedDeck) {
      return Future.value(false);
    }
    return super.setValue(valueType, key, value);
  }
}

const _scenario = Scenario(
  id: 'srs-retry',
  level: LearnerLevel.a1,
  emoji: '',
  register: Register.polite,
  title: LocalizedText(ko: '', de: '', en: ''),
  intro: LocalizedText(ko: '', de: '', en: ''),
  vocab: [VocabRef(korean: '사과')],
  grammarIds: [],
  dialog: [],
  quests: [
    QuestSpec(
      type: QuestType.luecken,
      data: {
        'sentence': '___ 입니다.',
        'options': ['사과', '바나나'],
        'correctIndex': 0,
      },
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalPlatform = SharedPreferencesStorePlatform.instance;
  late _SrsPreferencesPlatform platform;

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    platform = _SrsPreferencesPlatform();
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
  });

  tearDown(() {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = originalPlatform;
  });

  test(
    'rejected failed-quest SRS cannot be treated as saved completion',
    () async {
      platform.rejectKey = 'kl_srs_v1';
      await expectLater(
        recordScenarioFailedQuestSrs(
          scenario: _scenario,
          failedQuestIndices: [0],
        ),
        throwsA(isA<PreferenceWriteException>()),
      );
      expect(Storage.srsCard('사과'), isNull);
    },
  );

  test(
    'same judgment retries once while a new judgment remains real evidence',
    () async {
      final attempt = SrsReviewAttempt(id: '사과', gotIt: false);
      expect(await Future.wait([attempt.save(), attempt.save()]), [true, true]);
      expect(Storage.srsCard('사과')!.reviewCount, 1);
      expect(await Storage.srsReview('사과', gotIt: true), isTrue);
      expect(Storage.srsCard('사과')!.reviewCount, 2);
      expect(await attempt.save(), isTrue);
      expect(Storage.srsCard('사과')!.reviewCount, 2);
    },
  );

  for (final committed in [false, true]) {
    test('unknown SRS outcome resolves once; committed=$committed', () async {
      await Storage.srsReview('보존', gotIt: true);
      final beforeRaw = Storage.srsRawJson;
      final attempt = SrsReviewAttempt(
        id: '사과',
        gotIt: false,
        recordToStudyLog: false,
      );
      platform
        ..rejectKey = 'kl_srs_v1'
        ..throwReply = true
        ..commitBeforeFailure = committed
        ..failReloadAfterWrite = true;
      expect(await attempt.save(), isFalse);
      expect(Storage.srsCard('사과'), isNull);
      expect(Storage.srsRawJson, beforeRaw);
      expect(await attempt.save(), isFalse);
      expect(platform.writes['kl_srs_v1'], 2);
      platform
        ..unavailable = false
        ..rejectKey = null;
      expect(await attempt.save(), isTrue);
      expect(Storage.srsCard('사과')!.reviewCount, 1);
      expect(Storage.srsCard('보존')!.reviewCount, 1);
      expect(platform.writes['kl_srs_v1'], committed ? 2 : 3);
      expect(await attempt.save(), isTrue);
      expect(Storage.srsCard('사과')!.reviewCount, 1);
    });
  }

  test(
    'another judgment resolves the pending one before changing the deck',
    () async {
      final first = SrsReviewAttempt(
        id: '사과',
        gotIt: false,
        recordToStudyLog: false,
      );
      platform
        ..rejectKey = 'kl_srs_v1'
        ..throwReply = true
        ..commitBeforeFailure = true
        ..failReloadAfterWrite = true;
      expect(await first.save(), isFalse);
      platform
        ..unavailable = false
        ..rejectKey = null;
      expect(await Storage.srsReview('바나나', gotIt: true), isTrue);
      expect(await first.save(), isTrue);
      expect(Storage.srsCard('사과')!.reviewCount, 1);
      expect(Storage.srsCard('바나나')!.reviewCount, 1);
    },
  );

  test(
    'retry repairs only the rejected daily log after confirmed SRS',
    () async {
      final attempt = SrsReviewAttempt(id: '사과', gotIt: true);
      final today = Storage.todayIso();
      platform.rejectKey = 'kl_study_log_v1_$today';
      expect(await attempt.save(), isFalse);
      expect(Storage.srsCard('사과')!.reviewCount, 1);
      platform.rejectKey = null;
      expect(await attempt.save(), isTrue);
      expect(Storage.srsCard('사과')!.reviewCount, 1);
      expect(Storage.studyLogIdsFor(today), contains('사과'));
      expect(platform.writes['kl_srs_v1'], 1);
    },
  );

  for (final strict in [false, true]) {
    test(
      'reset drains delayed SRS and invalidates its retry; strict=$strict',
      () async {
        final entered = Completer<void>();
        final release = Completer<void>();
        final attempt = SrsReviewAttempt(id: '사과', gotIt: true);
        platform
          ..rejectKey = 'kl_srs_v1'
          ..writeEntered = entered
          ..releaseWrite = release
          ..commitBeforeFailure = true
          ..successfulReply = true;
        final saving = attempt.save();
        await entered.future;
        final reset = strict ? Storage.resetAllStrict() : Storage.resetAll();
        expect(await Storage.srsReview('late', gotIt: true), isFalse);
        release.complete();
        expect(await saving, isTrue);
        await reset;
        expect(
          platform.values.keys.where((key) => key.startsWith('kl_')),
          isEmpty,
        );
        expect(await attempt.save(), isFalse);
        platform.rejectKey = null;
        expect(await Storage.srsReview('fresh', gotIt: true), isTrue);
        expect(Storage.srsCard('사과'), isNull);
      },
    );
  }

  test(
    'explicit deck replacement invalidates an earlier saved attempt',
    () async {
      final attempt = SrsReviewAttempt(id: '사과', gotIt: true);
      expect(await attempt.save(), isTrue);
      await Storage.setSrsRawJsonStrict('{}');
      expect(await attempt.save(), isFalse);
      expect(Storage.srsCard('사과'), isNull);
    },
  );

  for (final committed in [false, true]) {
    test(
      'unknown daily log cannot complete an attempt; committed=$committed',
      () async {
        final attempt = SrsReviewAttempt(id: '사과', gotIt: true);
        final key = 'kl_study_log_v1_${Storage.todayIso()}';
        platform
          ..rejectKey = key
          ..throwReply = true
          ..commitBeforeFailure = committed
          ..failReloadAfterWrite = true;
        expect(await attempt.save(), isFalse);
        expect(await attempt.save(), isFalse);
        platform
          ..unavailable = false
          ..rejectKey = null;
        expect(await attempt.save(), isTrue);
        expect(Storage.srsCard('사과')!.reviewCount, 1);
        expect(platform.values[key], contains('사과'));
        expect(platform.writes[key], committed ? 1 : 2);
      },
    );
  }

  for (final kind in ['strict', 'legacy', 'quarantine']) {
    test('deck replacement follows a delayed old SRS write; $kind', () async {
      await Storage.setSrsRawJson(
        '{"old":{"e":2.5,"i":1,"n":"2099-01-01","r":3}}',
      );
      final entered = Completer<void>();
      final release = Completer<void>();
      platform
        ..rejectKey = 'kl_srs_v1'
        ..writeEntered = entered
        ..releaseWrite = release
        ..commitBeforeFailure = true
        ..successfulReply = true;
      final saving = Storage.srsReview('pending', gotIt: true);
      await entered.future;
      platform.rejectKey = null;
      final replacement = kind == 'quarantine'
          ? '{}'
          : '{"restored":{"e":2.5,"i":1,"n":"2099-01-01","r":7}}';
      final restoring = switch (kind) {
        'strict' => Storage.setSrsRawJsonStrict(replacement),
        'legacy' => Storage.setSrsRawJson(replacement),
        _ => Storage.resetQuarantinedSrs(),
      };
      await Future<void>.delayed(Duration.zero);
      release.complete();
      expect(await saving, isFalse);
      await restoring;
      expect(platform.values['kl_srs_v1'], replacement);
      expect(Storage.srsRawJson, replacement);
    });
  }

  test(
    'unknown restore is refreshed before a new judgment derives its deck',
    () async {
      final old = SrsReviewAttempt(id: 'old', gotIt: true);
      expect(await old.save(), isTrue);
      platform
        ..rejectKey = 'kl_srs_v1'
        ..throwReply = true
        ..commitBeforeFailure = true
        ..failReloadAfterWrite = true;
      await expectLater(
        Storage.setSrsRawJsonStrict(
          '{"restored":{"e":2.5,"i":1,"n":"2099-01-01","r":7}}',
        ),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );
      expect(await old.save(), isFalse);
      platform
        ..unavailable = false
        ..rejectKey = null;
      expect(await Storage.srsReview('new', gotIt: true), isTrue);
      expect(Storage.srsCard('restored')!.reviewCount, 7);
      expect(Storage.srsCard('old'), isNull);
      expect(Storage.srsCard('new')!.reviewCount, 1);
    },
  );

  test(
    'rejected restore cannot resurrect its retired review from cache',
    () async {
      const replacement = '{"restored":{"e":2.5,"i":1,"n":"2099-01-01","r":7}}';
      final entered = Completer<void>();
      final release = Completer<void>();
      platform
        ..rejectKey = 'kl_srs_v1'
        ..writeEntered = entered
        ..releaseWrite = release
        ..commitBeforeFailure = true
        ..successfulReply = true;
      final saving = Storage.srsReview('retired', gotIt: true);
      await entered.future;
      platform
        ..rejectKey = null
        ..rejectedDeck = replacement;
      final rejected = expectLater(
        Storage.setSrsRawJsonStrict(replacement),
        throwsA(isA<PreferenceWriteException>()),
      );
      release.complete();
      expect(await saving, isFalse);
      await rejected;
      expect(Storage.srsCard('retired'), isNull);
      expect(await Storage.srsReview('fresh', gotIt: true), isTrue);
      expect(Storage.srsRawJson, isNot(contains('retired')));
    },
  );
}
