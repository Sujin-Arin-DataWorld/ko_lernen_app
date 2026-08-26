import 'package:flutter/material.dart';

import '../../models/sori_stage_progression.dart';

/// 보상 종류 → 아이콘 단일 매핑 (§C-3c P1-⑦).
///
/// "약속"(활동 상세 시트의 보상 계약)과 "이행"(리워드 리시트)이 같은 시각
/// 언어를 쓰도록 공용화했다 — 정본은 리시트가 쓰던 매핑이다. 여기 말고
/// 다른 곳에 보상 아이콘 switch 를 새로 만들지 말 것.
IconData soriRewardIcon(SoriRewardKind kind) => switch (kind) {
  SoriRewardKind.none => Icons.info_outline_rounded,
  SoriRewardKind.xp => Icons.bolt_rounded,
  SoriRewardKind.stamp => Icons.approval_rounded,
  SoriRewardKind.questProgress => Icons.checklist_rounded,
  SoriRewardKind.hanokProgress => Icons.roofing_rounded,
  SoriRewardKind.bojagi => Icons.redeem_rounded,
  SoriRewardKind.gyeLantern => Icons.lightbulb_rounded,
  SoriRewardKind.personalBest => Icons.emoji_events_rounded,
};
