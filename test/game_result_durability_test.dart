import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/widgets/sori/game_reward.dart';
import 'support/reward_preferences_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final original = SharedPreferencesStorePlatform.instance;
  late RewardPreferencesPlatform platform;
  final sounds = <String>[];
  setUp(() async {
    sounds.clear();
    SoundService.playImpl = sounds.add;
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    platform = RewardPreferencesPlatform();
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
  });
  tearDown(() {
    SoundService.resetForTesting();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = original;
  });

  test('native rejection cannot announce a new personal best', () async {
    platform.rejectKey = 'kl_game_best';
    await expectLater(
      Storage.recordGameBest('cloze', 80),
      throwsA(isA<PreferenceWriteException>()),
    );
    expect(Storage.gameBest('cloze'), 0);
  });

  test(
    'daily completion does not depend on separate legacy marker writes',
    () async {
      platform.rejectKey = 'kl_daily_last';
      await Storage.markDailyChallengeDone();
      await (await SharedPreferences.getInstance()).reload();
      Storage.resetCachesAfterExternalWrite();
      expect(Storage.dailyChallengeDoneToday(), isTrue);
      expect(Storage.dailyChallengeStreak, 1);
    },
  );

  test(
    'uncommitted unknown best overtaken by another score is not a new record',
    () async {
      final attempt = GameBestAttempt('cloze', 80);
      platform
        ..rejectKey = 'kl_game_best'
        ..throwReply = true
        ..failReloadAfterWrite = true;
      await expectLater(
        attempt.save(),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );
      platform
        ..unavailable = false
        ..rejectKey = null;
      await Storage.recordGameBest('cloze', 90);
      expect(await attempt.save(), isFalse);
      expect(Storage.gameBest('cloze'), 90);
    },
  );

  for (final key in [
    Storage.listeningRewardLedgerPreferenceKey,
    'kl_game_best',
  ]) {
    for (final committed in [false, true]) {
      test('game retry after unknown $key committed=$committed', () async {
        final attempt = GameResultAttempt(gameId: 'cloze', xp: 10, score: 80);
        platform
          ..rejectKey = key
          ..throwReply = true
          ..commitBeforeFailure = committed
          ..failReloadAfterWrite = true;
        await expectLater(
          attempt.save(),
          throwsA(isA<PreferenceOutcomeUnknownException>()),
        );
        expect(Storage.gameBest('cloze'), 0);
        await expectLater(
          attempt.save(),
          throwsA(isA<PreferenceOutcomeUnknownException>()),
        );
        expect(platform.writes[key], 1);
        platform
          ..unavailable = false
          ..rejectKey = null;
        final outcomes = await Future.wait([attempt.save(), attempt.save()]);
        expect(
          outcomes.every(
            (o) => o.xpGained == 10 && o.isNewBest && o.best == 80,
          ),
          isTrue,
        );
        expect(Storage.xp, 10);
        expect(Storage.xpToday, 10);
        await attempt.save();
        expect(Storage.xp, 10);
        expect(sounds.where((sound) => sound == 'sfx/complete.wav').length, 1);
      });
    }
  }

  test('failed best retry never pays XP twice', () async {
    final attempt = GameResultAttempt(gameId: 'quiz', xp: 10, score: 80);
    platform.rejectKey = 'kl_game_best';
    await expectLater(attempt.save(), throwsA(isA<PreferenceWriteException>()));
    expect(Storage.xp, 10);
    expect(Storage.gameBest('quiz'), 0);
    platform.rejectKey = null;
    expect((await attempt.save()).isNewBest, isTrue);
    expect(Storage.xp, 10);
  });

  for (final committed in [false, true]) {
    test(
      'daily bonus and completion recover together committed=$committed',
      () async {
        final attempt = GameResultAttempt(
          gameId: 'daily',
          xp: 5,
          score: 100,
          dailyCompletionBonus: 20,
        );
        platform
          ..rejectKey = Storage.listeningRewardLedgerPreferenceKey
          ..throwReply = true
          ..commitBeforeFailure = committed
          ..failReloadAfterWrite = true;
        await expectLater(
          attempt.save(),
          throwsA(isA<PreferenceOutcomeUnknownException>()),
        );
        expect(Storage.dailyChallengeDoneToday(), isFalse);
        expect(Storage.xp, 0);
        platform
          ..unavailable = false
          ..rejectKey = null;
        expect((await attempt.save()).xpGained, 25);
        expect(Storage.xp, 25);
        expect(Storage.xpToday, 25);
        expect(Storage.dailyChallengeDoneToday(), isTrue);
        expect(Storage.dailyChallengeStreak, 1);
        final practice = GameResultAttempt(
          gameId: 'daily',
          xp: 5,
          score: 100,
          dailyCompletionBonus: 20,
        );
        expect((await practice.save()).xpGained, 5);
        expect(Storage.xp, 30);
      },
    );
  }

  test(
    'concurrent daily completions award one bonus and preserve legacy streak',
    () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final date = yesterday.toIso8601String().substring(0, 10);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('kl_daily_last', date);
      await prefs.setInt('kl_daily_streak', 4);
      final outcomes = await Future.wait(
        List.generate(
          5,
          (_) => GameResultAttempt(
            gameId: 'daily',
            xp: 5,
            dailyCompletionBonus: 20,
          ).save(),
        ),
      );
      expect(outcomes.where((o) => o.xpGained == 25).length, 1);
      expect(Storage.xp, 45);
      expect(Storage.dailyChallengeStreak, 5);
      expect(
        jsonDecode(
          platform.values[Storage.listeningRewardLedgerPreferenceKey] as String,
        )['dailyChallenge'],
        {'date': Storage.todayIso(), 'streak': 5},
      );
    },
  );

  test(
    'definite best rejection followed by a better score does not claim a record',
    () async {
      final attempt = GameBestAttempt('cloze', 80);
      platform.rejectKey = 'kl_game_best';
      await expectLater(
        attempt.save(),
        throwsA(isA<PreferenceWriteException>()),
      );
      platform.rejectKey = null;
      await Storage.recordGameBest('cloze', 90);
      expect(await attempt.save(), isFalse);
    },
  );

  test('daily streak uses calendar yesterday across spring DST', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kl_daily_last', '2026-03-29');
    await prefs.setInt('kl_daily_streak', 4);
    await XpAwardAttempt(
      5,
      earnedAt: DateTime(2026, 3, 30, 12),
      dailyCompletionBonus: 20,
    ).save();
    expect(Storage.dailyChallengeStreak, 5);
    expect(Storage.xp, 25);
  });

  for (final action in ['cancel', 'reset']) {
    test('$action during XP prevents later personal-best writes', () async {
      final attempt = GameResultAttempt(gameId: 'cloze', xp: 10, score: 80);
      final release = Completer<void>();
      final entered = Completer<void>();
      platform
        ..rejectKey = Storage.listeningRewardLedgerPreferenceKey
        ..releaseWrite = release
        ..writeEntered = entered
        ..successfulReply = true
        ..commitBeforeFailure = true;
      final pending = attempt.save();
      final failure = expectLater(
        pending,
        throwsA(isA<StaleLocalDataLifetimeException>()),
      );
      await entered.future;
      Future<void>? reset;
      if (action == 'cancel') {
        attempt.cancel();
      } else {
        reset = Storage.resetAllStrict();
      }
      release.complete();
      await failure;
      if (reset != null) {
        await reset;
        expect(Storage.xp, 0);
      }
      expect(platform.writes['kl_game_best'] ?? 0, 0);
    });
  }

  test(
    'legacy date without a valid streak cannot poison the XP ledger',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'kl_daily_last',
        DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String()
            .substring(0, 10),
      );
      await prefs.setInt('kl_daily_streak', -1);
      await GameResultAttempt(
        gameId: 'daily',
        xp: 5,
        dailyCompletionBonus: 20,
      ).save();
      await prefs.reload();
      Storage.resetCachesAfterExternalWrite();
      expect(Storage.dailyChallengeStreak, 2);
      expect(Storage.xp, 25);
    },
  );
}
