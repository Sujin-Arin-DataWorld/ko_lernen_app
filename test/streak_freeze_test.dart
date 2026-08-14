// Streak-freeze unit tests for [Storage.touchStreak].
//
// Verifies the streak-protection mechanic added in Phase 3:
// freezes accrue at every 7-day milestone (capped) and auto-shield
// exactly one missed day to keep the streak alive.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/storage_service.dart';

DateTime _d(int y, int m, int day) => DateTime(y, m, day);

Future<void> _resetStorage(Map<String, Object> seed) async {
  Storage.resetForTesting();
  SharedPreferences.setMockInitialValues(seed);
  await Storage.init();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('touchStreak — base behavior', () {
    test('first touch ever → streak=1, freezes=0', () async {
      await _resetStorage({});
      await Storage.touchStreak(now: _d(2026, 1, 1));
      expect(Storage.streakDays, 1);
      expect(Storage.streakFreezes, 0);
      expect(Storage.lastOpenDate, '2026-01-01');
    });

    test('same-day re-touch → no change', () async {
      await _resetStorage({
        'kl_last_open_date': '2026-01-01',
        'kl_streak_days': 3,
      });
      await Storage.touchStreak(now: _d(2026, 1, 1));
      expect(Storage.streakDays, 3);
    });

    test('next-day touch → streak +1', () async {
      await _resetStorage({
        'kl_last_open_date': '2026-01-01',
        'kl_streak_days': 3,
      });
      await Storage.touchStreak(now: _d(2026, 1, 2));
      expect(Storage.streakDays, 4);
    });

    test('skip 1 day with no freeze → reset to 1', () async {
      await _resetStorage({
        'kl_last_open_date': '2026-01-01',
        'kl_streak_days': 5,
        'kl_streak_freezes': 0,
      });
      await Storage.touchStreak(now: _d(2026, 1, 3)); // 1 missed day
      expect(Storage.streakDays, 1);
      expect(Storage.streakFreezes, 0);
    });

    test('skip 2+ days → reset to 1 even with freezes', () async {
      await _resetStorage({
        'kl_last_open_date': '2026-01-01',
        'kl_streak_days': 5,
        'kl_streak_freezes': 2,
      });
      await Storage.touchStreak(now: _d(2026, 1, 5)); // 3 missed days
      expect(Storage.streakDays, 1);
      // Freezes preserved — only consumed on the exact 1-day skip path.
      expect(Storage.streakFreezes, 2);
    });
  });

  group('touchStreak — freeze mechanic', () {
    test('reaching day 7 grants one freeze', () async {
      await _resetStorage({
        'kl_last_open_date': '2026-01-01',
        'kl_streak_days': 6,
        'kl_streak_freezes': 0,
      });
      await Storage.touchStreak(now: _d(2026, 1, 2));
      expect(Storage.streakDays, 7);
      expect(Storage.streakFreezes, 1);
    });

    test('reaching day 14 grants a second freeze', () async {
      await _resetStorage({
        'kl_last_open_date': '2026-01-13',
        'kl_streak_days': 13,
        'kl_streak_freezes': 1,
      });
      await Storage.touchStreak(now: _d(2026, 1, 14));
      expect(Storage.streakDays, 14);
      expect(Storage.streakFreezes, 2);
    });

    test('freeze cap respected at day 21', () async {
      await _resetStorage({
        'kl_last_open_date': '2026-01-20',
        'kl_streak_days': 20,
        'kl_streak_freezes': 2,
      });
      await Storage.touchStreak(now: _d(2026, 1, 21));
      expect(Storage.streakDays, 21);
      expect(Storage.streakFreezes, 2);
    });

    test('skip 1 day with a freeze → consumes 1, streak continues', () async {
      await _resetStorage({
        'kl_last_open_date': '2026-01-01',
        'kl_streak_days': 5,
        'kl_streak_freezes': 1,
      });
      await Storage.touchStreak(now: _d(2026, 1, 3)); // 1 missed day
      expect(Storage.streakDays, 6);
      expect(Storage.streakFreezes, 0);
      expect(Storage.streakFreezeLastUsed, '2026-01-03');
    });

    test(
      'skip 1 day on day-6 with freeze → reaches 7, refill keeps tokens',
      () async {
        // Streak=6 → use freeze to reach 7 → refill grants +1 back.
        await _resetStorage({
          'kl_last_open_date': '2026-01-06',
          'kl_streak_days': 6,
          'kl_streak_freezes': 1,
        });
        await Storage.touchStreak(now: _d(2026, 1, 8)); // 1 missed day
        expect(Storage.streakDays, 7);
        // Used -1, milestone +1 → net 1.
        expect(Storage.streakFreezes, 1);
        expect(Storage.streakFreezeLastUsed, '2026-01-08');
      },
    );
  });
}
