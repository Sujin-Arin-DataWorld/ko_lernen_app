import 'package:flutter/material.dart';

/// **SoriGlyph** — 앱의 시맨틱 아이콘 상수(한 곳에서 교체).
///
/// 이모지-아이콘(🔥🏆📚🎯⭐🔒 = "플레이스홀더 그대로 출시" 신호)을 대체한다.
/// 통일된 rounded Material 아이콘을 시맨틱 이름으로 노출 → 화면들은 이 상수만
/// 참조. 추후 커스텀 라인 아이콘 세트로 교체 시 이 파일만 수정하면 된다.
class SoriGlyph {
  SoriGlyph._();

  /// 연속 학습(스트릭) — 불꽃.
  static const IconData streak = Icons.local_fire_department_rounded;

  /// 최고기록·성취 — 인장/도장(seal) 느낌의 리본 배지.
  static const IconData record = Icons.workspace_premium_rounded;

  /// XP — 번개.
  static const IconData xp = Icons.bolt_rounded;

  /// 정확도 — 과녁.
  static const IconData accuracy = Icons.center_focus_strong_rounded;

  /// 학습한 카드/단어 수.
  static const IconData cards = Icons.style_rounded;

  /// 승률/트로피 대체 — 리본 배지.
  static const IconData wins = Icons.workspace_premium_rounded;

  /// 잠김.
  static const IconData locked = Icons.lock_rounded;

  /// 즐겨찾기 별.
  static const IconData star = Icons.star_rounded;

  /// 뜻풀이/사전.
  static const IconData definition = Icons.menu_book_rounded;
}
