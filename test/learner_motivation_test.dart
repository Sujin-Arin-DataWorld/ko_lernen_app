import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/data/learner_motivation.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations_en.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  group('LearnerMotivation', () {
    test('7개 값 + id 유일 + name 일치', () {
      expect(LearnerMotivation.values.length, 7);
      final ids = LearnerMotivation.values.map((m) => m.id).toSet();
      expect(ids.length, 7);
      for (final m in LearnerMotivation.values) {
        expect(m.id, m.name);
      }
    });

    test('아이콘·강조색 전부 지정(switch 예외 없음)', () {
      for (final m in LearnerMotivation.values) {
        expect(m.icon, isA<IconData>());
        expect(m.accent, isA<Color>());
      }
    });

    test('fromId 매핑', () {
      expect(learnerMotivationFromId('kpop'), LearnerMotivation.kpop);
      expect(learnerMotivationFromId('curious'), LearnerMotivation.curious);
      expect(learnerMotivationFromId(''), isNull);
      expect(learnerMotivationFromId(null), isNull);
      expect(learnerMotivationFromId('bogus'), isNull);
    });

    test('V2 offers four purposes and normalizes all legacy values', () {
      expect(v2LearnerMotivationChoices, const [
        LearnerMotivation.travel,
        LearnerMotivation.culture,
        LearnerMotivation.career,
        LearnerMotivation.kdrama,
      ]);
      expect(LearnerMotivation.loved.v2Canonical, LearnerMotivation.culture);
      expect(LearnerMotivation.curious.v2Canonical, LearnerMotivation.culture);
      expect(LearnerMotivation.kpop.v2Canonical, LearnerMotivation.kdrama);
      expect(
        v2LearnerMotivationChoices.map((choice) => choice.v2Label(AppL10nEn())),
        const [
          'Everyday life & travel',
          'People & culture',
          'Study & work',
          'K-content',
        ],
      );
    });
  });

  group('Storage motivation', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await Storage.init();
    });

    test('기본값 = 미설정', () {
      expect(Storage.motivation, '');
      expect(Storage.motivationAsked, isFalse);
    });

    test('설정 라운드트립', () async {
      await Storage.setMotivation('kpop');
      await Storage.setMotivationAsked();
      expect(Storage.motivation, 'kpop');
      expect(Storage.motivationAsked, isTrue);
      expect(
        learnerMotivationFromId(Storage.motivation),
        LearnerMotivation.kpop,
      );
    });
  });

  group('homeTigerBubble (동기 소비 — 우선순위)', () {
    final t = AppL10nEn();

    test('첫 사용자(streak0 xp0) → start (동기 무관)', () {
      expect(
        homeTigerBubble(
          t,
          streak: 0,
          xp: 0,
          motivation: LearnerMotivation.kpop,
        ),
        t.homeTigerBubbleStart,
      );
    });

    test('streak 3+ → streak 축하 (동기보다 우선)', () {
      expect(
        homeTigerBubble(
          t,
          streak: 5,
          xp: 200,
          motivation: LearnerMotivation.kpop,
        ),
        t.homeTigerBubbleStreak,
      );
    });

    test('동기 설정 + 중간 구간 → 이유별 라인 소비', () {
      expect(
        homeTigerBubble(
          t,
          streak: 1,
          xp: 40,
          motivation: LearnerMotivation.kpop,
        ),
        t.motivationLineKpop,
      );
      expect(
        homeTigerBubble(
          t,
          streak: 1,
          xp: 40,
          motivation: LearnerMotivation.kdrama,
        ),
        t.motivationLineKdrama,
      );
    });

    test('동기 없음 → 기존 resume (회귀 0)', () {
      expect(
        homeTigerBubble(t, streak: 1, xp: 40, motivation: null),
        t.homeTigerBubbleResume,
      );
    });
  });
}
