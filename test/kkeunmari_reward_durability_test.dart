import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'support/reward_preferences_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final original = SharedPreferencesStorePlatform.instance;
  late RewardPreferencesPlatform platform;
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    platform = RewardPreferencesPlatform();
    platform.values['kl_kkeunmari_wins'] = 7;
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
  });
  tearDown(() {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = original;
  });

  for (final committed in [false, true]) {
    test(
      'unknown win and XP reconcile together committed=$committed',
      () async {
        final attempt = XpAwardAttempt(20, kkeunmariWin: true);
        platform
          ..rejectKey = Storage.listeningRewardLedgerPreferenceKey
          ..throwReply = true
          ..commitBeforeFailure = committed
          ..failReloadAfterWrite = true;
        await expectLater(
          attempt.save(),
          throwsA(isA<PreferenceOutcomeUnknownException>()),
        );
        expect(Storage.xp, 0);
        expect(Storage.kkeunmariWins, 7);
        platform
          ..unavailable = false
          ..rejectKey = null;
        await Future.wait([attempt.save(), attempt.save()]);
        expect(Storage.xp, 20);
        expect(Storage.kkeunmariWins, 8);
        await Storage.addXp(3);
        await Storage.markDailyChallengeDone();
        await Storage.claimListeningCompletionReward(
          scenarioId: 'win-preserve',
          earnedXp: 4,
        );
        final ledger =
            jsonDecode(
                  platform.values[Storage.listeningRewardLedgerPreferenceKey]
                      as String,
                )
                as Map;
        expect(ledger['kkeunmariWins'], 8);
        expect(ledger['listeningClaims'], contains('win-preserve'));
        expect(ledger, contains('dailyChallenge'));
        Storage.resetForTesting();
        await (await SharedPreferences.getInstance()).reload();
        await Storage.init();
        expect(Storage.kkeunmariWins, 8);
        expect(Storage.xp, 27);
      },
    );
  }

  test(
    'concurrent distinct wins and compatibility increment retain every win',
    () async {
      await Future.wait([
        for (var i = 0; i < 5; i++)
          XpAwardAttempt(20, kkeunmariWin: true).save(),
        Storage.incKkeunmariWins(),
      ]);
      expect(Storage.kkeunmariWins, 13);
      expect(Storage.xp, 100);
    },
  );

  for (final malformed in [-1, '8', null]) {
    test(
      'invalid stored win count $malformed is preserved and blocks mutation',
      () async {
        await Storage.addXp(1);
        final key = Storage.listeningRewardLedgerPreferenceKey;
        final ledger = jsonDecode(platform.values[key] as String) as Map;
        ledger['kkeunmariWins'] = malformed;
        final raw = jsonEncode(ledger);
        platform.values[key] = raw;
        Storage.resetForTesting();
        await (await SharedPreferences.getInstance()).reload();
        await Storage.init();
        await expectLater(
          XpAwardAttempt(20, kkeunmariWin: true).save(),
          throwsA(isA<PreferenceWriteException>()),
        );
        expect(platform.values[key], raw);
      },
    );
  }
}
