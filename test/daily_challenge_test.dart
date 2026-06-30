// Tages-Challenge: täglicher Selbst-Streak (Storage) + deterministische
// Tagesauswahl (DailyChallengeScreen.pickDaily/dailySeed). Selbst-Wettbewerb,
// keine Rangliste.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/screens/daily_challenge_screen.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

ClozeItem _it(String a) => ClozeItem(
  level: 'a1',
  sentenceKo: '＿＿＿ $a',
  answer: a,
  fullKo: a,
  de: a,
  en: a,
  distractors: const ['x', 'y', 'z'],
);

Future<void> _reset() async {
  Storage.resetForTesting();
  SharedPreferences.setMockInitialValues({});
  await Storage.init();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final d0 = DateTime(2026, 7, 1);

  group('markDailyChallengeDone — streak', () {
    test('first ever → streak 1, done today', () async {
      await _reset();
      await Storage.markDailyChallengeDone(now: d0);
      expect(Storage.dailyChallengeStreak, 1);
      expect(Storage.dailyChallengeDoneToday(now: d0), isTrue);
    });

    test('same day again → no-op (no double increment)', () async {
      await _reset();
      await Storage.markDailyChallengeDone(now: d0);
      await Storage.markDailyChallengeDone(now: d0);
      expect(Storage.dailyChallengeStreak, 1);
    });

    test('consecutive days → +1', () async {
      await _reset();
      await Storage.markDailyChallengeDone(now: d0);
      await Storage.markDailyChallengeDone(
        now: d0.add(const Duration(days: 1)),
      );
      await Storage.markDailyChallengeDone(
        now: d0.add(const Duration(days: 2)),
      );
      expect(Storage.dailyChallengeStreak, 3);
    });

    test('gap of 2 days → reset to 1', () async {
      await _reset();
      await Storage.markDailyChallengeDone(now: d0);
      await Storage.markDailyChallengeDone(
        now: d0.add(const Duration(days: 3)),
      );
      expect(Storage.dailyChallengeStreak, 1);
    });

    test('doneToday is false on a fresh day', () async {
      await _reset();
      await Storage.markDailyChallengeDone(now: d0);
      expect(
        Storage.dailyChallengeDoneToday(now: d0.add(const Duration(days: 1))),
        isFalse,
      );
    });
  });

  group('pickDaily — deterministic', () {
    final pool = List.generate(50, (i) => _it('w$i'));

    test('same seed → identical set', () {
      final a = DailyChallengeScreen.pickDaily(pool, 123, 10);
      final b = DailyChallengeScreen.pickDaily(pool, 123, 10);
      expect(a.map((e) => e.answer), b.map((e) => e.answer));
      expect(a, hasLength(10));
    });

    test('different seed → (very likely) different set', () {
      final a = DailyChallengeScreen.pickDaily(pool, 1, 10);
      final b = DailyChallengeScreen.pickDaily(pool, 2, 10);
      expect(
        a.map((e) => e.answer).toList() == b.map((e) => e.answer).toList(),
        isFalse,
      );
    });

    test('count larger than pool → returns whole pool', () {
      final small = [_it('a'), _it('b')];
      expect(DailyChallengeScreen.pickDaily(small, 5, 10), hasLength(2));
    });

    test('dailySeed advances by 1 each day', () {
      final s0 = DailyChallengeScreen.dailySeed(DateTime.utc(2026, 7, 1));
      final s1 = DailyChallengeScreen.dailySeed(DateTime.utc(2026, 7, 2));
      expect(s1 - s0, 1);
    });
  });
}
