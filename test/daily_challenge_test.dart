// Tages-Challenge: täglicher Selbst-Streak (Storage) + deterministische
// Tagesauswahl (DailyChallengeScreen.pickDaily/dailySeed). Selbst-Wettbewerb,
// keine Rangliste.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/screens/daily_challenge_screen.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

ClozeItem _it(String a, {String level = 'a1'}) => ClozeItem(
  level: level,
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

  // 레벨 캡 — A2 사용자가 B2 문항('양극화' 등)을 데일리에서 만나지 않게.
  group('capToLevel — user level cap', () {
    final mixed = [
      for (var i = 0; i < 12; i++) _it('a1_$i'),
      for (var i = 0; i < 12; i++) _it('a2_$i', level: 'a2'),
      for (var i = 0; i < 12; i++) _it('b2_$i', level: 'b2'),
    ];

    test('caps pool at user level', () {
      final pool = DailyChallengeScreen.capToLevel(mixed, 'a2', 10);
      expect(pool, hasLength(24));
      expect(pool.every((i) => i.level == 'a1' || i.level == 'a2'), isTrue);
    });

    test('no level set → full pool (onboarding not done)', () {
      expect(DailyChallengeScreen.capToLevel(mixed, null, 10), hasLength(36));
    });

    test('capped pool smaller than round → falls back to full pool', () {
      final tiny = [_it('a1_0'), _it('b2_0', level: 'b2')];
      expect(DailyChallengeScreen.capToLevel(tiny, 'a1', 10), hasLength(2));
    });

    test('same seed stays deterministic after capping', () {
      final pool = DailyChallengeScreen.capToLevel(mixed, 'a2', 10);
      final a = DailyChallengeScreen.pickDaily(pool, 77, 10);
      final b = DailyChallengeScreen.pickDaily(pool, 77, 10);
      expect(a.map((e) => e.answer), b.map((e) => e.answer));
      expect(a.every((i) => i.level != 'b2'), isTrue);
    });
  });
}
