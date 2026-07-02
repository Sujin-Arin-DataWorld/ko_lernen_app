import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/data/milestone.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  group('newlyReachedMilestones (순수)', () {
    test('임계값 이상 + 미축하만 반환(값 오름차순)', () {
      final r = newlyReachedMilestones(
        streak: 7,
        level: 1,
        vocab: 0,
        celebrated: {},
      );
      expect(r.map((m) => m.id).toList(), ['streak_3', 'streak_7']);
    });

    test('이미 축하한 것 제외', () {
      final r = newlyReachedMilestones(
        streak: 7,
        level: 1,
        vocab: 0,
        celebrated: {'streak_3'},
      );
      expect(r.map((m) => m.id).toList(), ['streak_7']);
    });

    test('전부 미달성 → 빈 리스트', () {
      expect(
        newlyReachedMilestones(streak: 2, level: 4, vocab: 9, celebrated: {}),
        isEmpty,
      );
    });

    test('복합 — level 5 + vocab 100', () {
      final r = newlyReachedMilestones(
        streak: 0,
        level: 5,
        vocab: 100,
        celebrated: {},
      );
      expect(r.map((m) => m.id).toSet(), {'level_5', 'vocab_10', 'vocab_100'});
    });

    test('임계값 사이 값 — vocab 50 → vocab_10만(100 미달)', () {
      final r = newlyReachedMilestones(
        streak: 0,
        level: 0,
        vocab: 50,
        celebrated: {},
      );
      expect(r.map((m) => m.id).toList(), ['vocab_10']);
    });
  });

  group('Storage celebratedMilestones', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
    });

    test('mark + dedup + 영속', () async {
      expect(Storage.celebratedMilestones, isEmpty);
      await Storage.markMilestonesCelebrated(['streak_3', 'streak_7']);
      expect(Storage.celebratedMilestones.toSet(), {'streak_3', 'streak_7'});
      // 중복 id는 재추가 안 함.
      await Storage.markMilestonesCelebrated(['streak_3', 'level_5']);
      expect(Storage.celebratedMilestones.toSet(), {
        'streak_3',
        'streak_7',
        'level_5',
      });
    });
  });
}
