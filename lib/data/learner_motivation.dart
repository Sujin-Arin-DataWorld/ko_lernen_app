import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// 학습자가 한국어를 배우는 **이유**(서양 학습자 어필의 핵심 레버).
///
/// 첫 홈 진입 시 [showMotivationSheet]로 1회 캡처 → 홈 tiger bubble·프로필에서
/// 그 이유에 맞춘 격려로 개인화한다(Duolingo "왜 배우는가" 플레이북).
enum LearnerMotivation { kpop, kdrama, travel, culture, loved, career, curious }

extension LearnerMotivationX on LearnerMotivation {
  /// storage id (= enum name). 'kpop' 등.
  String get id => name;

  IconData get icon => switch (this) {
    LearnerMotivation.kpop => Icons.music_note_rounded,
    LearnerMotivation.kdrama => Icons.movie_outlined,
    LearnerMotivation.travel => Icons.flight_takeoff_rounded,
    LearnerMotivation.culture => Icons.auto_stories_outlined,
    LearnerMotivation.loved => Icons.favorite_outline_rounded,
    LearnerMotivation.career => Icons.work_outline_rounded,
    LearnerMotivation.curious => Icons.lightbulb_outline_rounded,
  };

  /// 강조색 — 이유별 단청 팔레트 배분(무경쟁·따뜻).
  Color get accent => switch (this) {
    LearnerMotivation.kpop => const Color(0xFFA0524A), // 석간주 적
    LearnerMotivation.kdrama => const Color(0xFF5A7BA0), // 청금석
    LearnerMotivation.travel => const Color(0xFF1F7A6B), // 녹청
    LearnerMotivation.culture => const Color(0xFFC99A2E), // 황
    LearnerMotivation.loved => const Color(0xFFA0524A), // 석간주 적
    LearnerMotivation.career => const Color(0xFF1F7A6B), // 녹청
    LearnerMotivation.curious => const Color(0xFFFF8C42), // 호랑이 주황
  };

  /// 선택지 라벨 (l10n).
  String label(AppL10n t) => switch (this) {
    LearnerMotivation.kpop => t.motivationKpop,
    LearnerMotivation.kdrama => t.motivationKdrama,
    LearnerMotivation.travel => t.motivationTravel,
    LearnerMotivation.culture => t.motivationCulture,
    LearnerMotivation.loved => t.motivationLoved,
    LearnerMotivation.career => t.motivationCareer,
    LearnerMotivation.curious => t.motivationCurious,
  };

  /// 이유별 맞춤 호랑이 격려 라인 (l10n).
  String tigerLine(AppL10n t) => switch (this) {
    LearnerMotivation.kpop => t.motivationLineKpop,
    LearnerMotivation.kdrama => t.motivationLineKdrama,
    LearnerMotivation.travel => t.motivationLineTravel,
    LearnerMotivation.culture => t.motivationLineCulture,
    LearnerMotivation.loved => t.motivationLineLoved,
    LearnerMotivation.career => t.motivationLineCareer,
    LearnerMotivation.curious => t.motivationLineCurious,
  };
}

/// storage id → enum (미지정/미인식 → null).
LearnerMotivation? learnerMotivationFromId(String? id) {
  if (id == null || id.isEmpty) {
    return null;
  }
  for (final m in LearnerMotivation.values) {
    if (m.name == id) {
      return m;
    }
  }
  return null;
}

/// 홈 tiger 말풍선 선택(순수 함수, 테스트 대상).
///
/// 우선순위: 첫 사용자(격려) → 스트릭 3+ (스트릭 축하) → **학습 이유**(동기 강화,
/// 습관 형성 구간에 "왜 배우는가"로 되돌림) → 일반 resume. motivation이 null이면
/// 기존 동작과 동일(회귀 0).
String homeTigerBubble(
  AppL10n t, {
  required int streak,
  required int xp,
  LearnerMotivation? motivation,
}) {
  if (streak == 0 && xp == 0) {
    return t.homeTigerBubbleStart;
  }
  if (streak >= 3) {
    return t.homeTigerBubbleStreak;
  }
  if (motivation != null) {
    return motivation.tigerLine(t);
  }
  return t.homeTigerBubbleResume;
}
