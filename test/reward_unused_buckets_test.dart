import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/decoration_reward_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DecorationRewardService.unusedRewardBuckets (pure)', () {
    final now = DateTime(2026, 8, 18);

    String iso(int daysAgo) =>
        now.subtract(Duration(days: daysAgo)).toIso8601String();

    test('buckets a single owned-unplaced item by days since earned', () {
      final buckets = DecorationRewardService.unusedRewardBuckets(
        owned: ['decoration_soban'],
        placed: const {},
        earnedAt: {'decoration_soban': iso(5)},
        now: now,
      );

      expect(buckets, {'3-6'});
    });

    test('excludes items that are already placed somewhere', () {
      final buckets = DecorationRewardService.unusedRewardBuckets(
        owned: ['decoration_soban'],
        placed: {'decoration_soban'},
        earnedAt: {'decoration_soban': iso(10)},
        now: now,
      );

      expect(buckets, isEmpty);
    });

    test('excludes items with no recorded earned-at timestamp', () {
      final buckets = DecorationRewardService.unusedRewardBuckets(
        owned: ['decoration_soban'],
        placed: const {},
        earnedAt: const {},
        now: now,
      );

      expect(buckets, isEmpty);
    });

    test('covers every bucket boundary', () {
      final earnedAt = {
        'a': iso(0),
        'b': iso(2),
        'c': iso(3),
        'd': iso(6),
        'e': iso(7),
        'f': iso(13),
        'g': iso(14),
        'h': iso(29),
        'i': iso(30),
        'j': iso(365),
      };
      final buckets = DecorationRewardService.unusedRewardBuckets(
        owned: earnedAt.keys,
        placed: const {},
        earnedAt: earnedAt,
        now: now,
      );

      expect(buckets, {'0-2', '3-6', '7-13', '14-29', '30plus'});
    });

    test('ignores a future/clock-skewed earned-at timestamp', () {
      final buckets = DecorationRewardService.unusedRewardBuckets(
        owned: ['decoration_soban'],
        placed: const {},
        earnedAt: {'decoration_soban': now.add(const Duration(days: 1)).toIso8601String()},
        now: now,
      );

      expect(buckets, isEmpty);
    });
  });

  group('Storage decor earned-at + reward_unused dedup', () {
    setUp(() async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
    });

    test('records earned-at once and never overwrites it', () async {
      await Storage.recordDecorEarnedAt('decoration_soban', '2026-08-01T00:00:00.000');
      await Storage.recordDecorEarnedAt('decoration_soban', '2026-08-15T00:00:00.000');

      expect(Storage.decorEarnedAt['decoration_soban'], '2026-08-01T00:00:00.000');
    });

    test('reward_unused logged-date flag persists and reads back', () async {
      expect(Storage.rewardUnusedLoggedDate, isEmpty);

      await Storage.setRewardUnusedLoggedDate('2026-08-18');

      expect(Storage.rewardUnusedLoggedDate, '2026-08-18');
    });
  });
}
