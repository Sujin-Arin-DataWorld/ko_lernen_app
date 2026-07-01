import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  group('xpTodayValue (순수 — 자정 리셋)', () {
    test('저장 날짜 == 오늘 → raw', () {
      expect(Storage.xpTodayValue('2026-07-01', 25, '2026-07-01'), 25);
    });
    test('저장 날짜 != 오늘 → 0 (리셋)', () {
      expect(Storage.xpTodayValue('2026-06-30', 25, '2026-07-01'), 0);
    });
    test('빈 날짜 → 0', () {
      expect(Storage.xpTodayValue('', 99, '2026-07-01'), 0);
    });
  });

  group('Storage 일일 목표', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
    });

    test('dailyGoalXp 파생 — 미설정 30, 분×3', () async {
      expect(Storage.dailyGoalXp, 30);
      await Storage.setDailyGoal(10);
      expect(Storage.dailyGoalXp, 30);
      await Storage.setDailyGoal(15);
      expect(Storage.dailyGoalXp, 45);
      await Storage.setDailyGoal(5);
      expect(Storage.dailyGoalXp, 15);
    });

    test('addXp가 xpToday를 함께 올린다(같은 날 누적)', () async {
      expect(Storage.xpToday, 0);
      await Storage.addXp(10);
      expect(Storage.xpToday, 10);
      await Storage.addXp(5);
      expect(Storage.xpToday, 15);
      // 누적 xp도 정상.
      expect(Storage.xp, 15);
    });
  });
}
