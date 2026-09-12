import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/vocab_pack_finish_coordinator.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';

import 'support/reward_preferences_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalPlatform = SharedPreferencesStorePlatform.instance;
  late RewardPreferencesPlatform platform;

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    platform = RewardPreferencesPlatform()
      ..values['kl_xp'] = 100
      ..values['kl_xp_today_date'] = Storage.todayIso()
      ..values['kl_xp_today_raw'] = 5;
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
  });

  tearDown(() {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = originalPlatform;
  });

  test(
    'ordinary XP and daily XP survive a rejected old-format daily write',
    () async {
      platform.rejectKey = 'kl_xp_today_raw';
      await Storage.addXp(10);
      await (await SharedPreferences.getInstance()).reload();
      Storage.resetCachesAfterExternalWrite();
      expect(Storage.xp, 110);
      expect(
        Storage.xpToday,
        15,
        reason: 'A successful XP award must include its daily total.',
      );
    },
  );

  test(
    'rejected canonical award publishes neither total nor daily XP',
    () async {
      final attempt = XpAwardAttempt(10);
      platform.rejectKey = Storage.listeningRewardLedgerPreferenceKey;
      await expectLater(
        attempt.save(),
        throwsA(isA<PreferenceWriteException>()),
      );
      expect(Storage.xp, 100);
      expect(Storage.xpToday, 5);
      platform.rejectKey = null;
      await attempt.save();
      expect(Storage.xp, 110);
      expect(Storage.xpToday, 15);
      await attempt.save();
      expect(Storage.xp, 110);
    },
  );

  for (final committed in [false, true]) {
    test('unknown ordinary award recovers once; committed=$committed', () async {
      final attempt = XpAwardAttempt(10);
      platform
        ..rejectKey = Storage.listeningRewardLedgerPreferenceKey
        ..throwReply = true
        ..commitBeforeFailure = committed
        ..failReloadAfterWrite = true;
      await expectLater(
        attempt.save(),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );
      expect(Storage.xp, 100);
      expect(Storage.xpToday, 5);
      await expectLater(
        attempt.save(),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );
      expect(platform.writes[Storage.listeningRewardLedgerPreferenceKey], 1);
      platform
        ..unavailable = false
        ..rejectKey = null;
      // Another real award resolves the unknown one before deriving its delta.
      await Storage.addXp(7);
      await attempt.save();
      expect(Storage.xp, 117);
      expect(Storage.xpToday, 22);
      expect(
        platform.writes[Storage.listeningRewardLedgerPreferenceKey],
        committed ? 2 : 3,
      );
    });
  }

  test(
    'a pending native write keeps the confirmed total and daily snapshot',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      platform
        ..rejectKey = Storage.listeningRewardLedgerPreferenceKey
        ..writeEntered = entered
        ..releaseWrite = release
        ..commitBeforeFailure = true
        ..successfulReply = true;
      final saving = Storage.addXp(10);
      await entered.future;
      expect(Storage.xp, 100);
      expect(Storage.xpToday, 5);
      release.complete();
      await saving;
      expect(Storage.xp, 110);
      expect(Storage.xpToday, 15);
    },
  );

  test(
    'concurrent awards accumulate without a growing per-award record',
    () async {
      await Future.wait(List.generate(100, (_) => Storage.addXp(1)));
      expect(Storage.xp, 200);
      expect(Storage.xpToday, 105);
      final ledger =
          jsonDecode(
                platform.values[Storage.listeningRewardLedgerPreferenceKey]!
                    as String,
              )
              as Map<String, dynamic>;
      expect(ledger['ordinaryDay'], {'date': Storage.todayIso(), 'xp': 105});
      expect(
        ledger.keys,
        unorderedEquals([
          'version',
          'totalXp',
          'listeningClaims',
          'scenarioClaims',
          'ordinaryDay',
        ]),
      );
      expect(ledger['listeningClaims'], isEmpty);
      expect(ledger['scenarioClaims'], isEmpty);
    },
  );

  test(
    'first award today migrates an older legacy day without carrying its XP',
    () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final date =
          '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      platform.values['kl_xp_today_date'] = date;
      platform.values['kl_xp_today_raw'] = 40;
      await (await SharedPreferences.getInstance()).reload();
      await Storage.addXp(10);
      expect(Storage.xp, 110);
      expect(Storage.xpToday, 10);
    },
  );

  test('older delayed award cannot replace the newer daily snapshot', () async {
    final yesterday = XpAwardAttempt(
      3,
      earnedAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    await Storage.addXp(10);
    await yesterday.save();
    expect(Storage.xp, 113);
    expect(Storage.xpToday, 15);
  });

  test(
    'zero does not write and negative correction survives failed mirror',
    () async {
      await Storage.addXp(0);
      expect(platform.writes, isEmpty);
      platform.rejectKey = 'kl_xp';
      await Storage.addXp(-10);
      expect(Storage.xp, 90);
      expect(Storage.xpToday, -5);
      await (await SharedPreferences.getInstance()).reload();
      Storage.resetCachesAfterExternalWrite();
      expect(Storage.xp, 90);
      expect(Storage.xpToday, -5);
      await expectLater(Storage.addXp(-91), throwsArgumentError);
    },
  );

  test(
    'old claims and legacy daily XP migrate without double counting',
    () async {
      await Storage.claimListeningCompletionReward(
        scenarioId: 'listen',
        earnedXp: 40,
      );
      await Storage.claimScenarioCompletionReward(
        attemptId: 'scene-attempt',
        scenarioId: 'scene',
        earnedXp: 24,
      );
      await Storage.addXp(10);
      expect(Storage.xp, 174);
      expect(Storage.xpToday, 79);
      await Storage.setXp(150);
      expect(Storage.xp, 150);
      expect(Storage.xpToday, 79);
      expect(Storage.completedScenarios, contains('listen'));
    },
  );

  test('malformed ordinary snapshot is preserved and fails closed', () async {
    final raw = jsonEncode({
      'version': 1,
      'totalXp': 100,
      'listeningClaims': {},
      'ordinaryDay': null,
    });
    platform.values[Storage.listeningRewardLedgerPreferenceKey] = raw;
    await (await SharedPreferences.getInstance()).reload();
    await expectLater(
      Storage.addXp(10),
      throwsA(isA<PreferenceWriteException>()),
    );
    expect(platform.values[Storage.listeningRewardLedgerPreferenceKey], raw);
    expect(platform.writes, isEmpty);
  });

  for (final strict in [false, true]) {
    test(
      'reset drains the ordinary award and rejects old retry; strict=$strict',
      () async {
        final entered = Completer<void>();
        final release = Completer<void>();
        final attempt = XpAwardAttempt(10);
        platform
          ..rejectKey = Storage.listeningRewardLedgerPreferenceKey
          ..writeEntered = entered
          ..releaseWrite = release
          ..commitBeforeFailure = true
          ..successfulReply = true;
        final saving = attempt.save();
        await entered.future;
        final reset = strict ? Storage.resetAllStrict() : Storage.resetAll();
        await expectLater(
          Storage.addXp(2),
          throwsA(isA<StaleLocalDataLifetimeException>()),
        );
        release.complete();
        await saving;
        await reset;
        await expectLater(
          attempt.save(),
          throwsA(isA<StaleLocalDataLifetimeException>()),
        );
        expect(
          platform.values.keys.where((key) => key.startsWith('kl_')),
          isEmpty,
        );
        expect(Storage.xp, 0);
        expect(Storage.xpToday, 0);
      },
    );
  }

  for (final committed in [false, true]) {
    test(
      'production vocab adapter retries the same award; committed=$committed',
      () async {
        const pack = VocabPack(id: 'a1_pack', level: 'A1', words: []);
        final request = VocabPackFinishRequest(
          pack: pack,
          siblingPacks: [pack],
          bossAccuracy: 1,
          bossCorrect: 1,
          bossTotal: 1,
          quizCorrect: 2,
          quizTotal: 2,
          completionStampMotif: 'test_stamp',
        );
        final operations = DefaultVocabPackFinishOperations();
        platform
          ..rejectKey = Storage.listeningRewardLedgerPreferenceKey
          ..throwReply = true
          ..commitBeforeFailure = committed
          ..failReloadAfterWrite = true;
        await expectLater(
          operations.awardXp(request),
          throwsA(isA<PreferenceOutcomeUnknownException>()),
        );
        platform
          ..unavailable = false
          ..rejectKey = null;
        await operations.awardXp(request);
        await operations.awardXp(request);
        expect(Storage.xp, 110);
        expect(Storage.xpToday, 15);
        await DefaultVocabPackFinishOperations().awardXp(request);
        expect(
          Storage.xp,
          120,
          reason:
              'A different session can genuinely earn the same amount again.',
        );
      },
    );
  }
}
