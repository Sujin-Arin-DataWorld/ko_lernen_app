import 'package:flutter/material.dart';

import '../../models/sori_stage_progression.dart';
import 'tokens.dart';

/// §C-3c P1-③: 잠금 판정 통일 — 카드(카탈로그)와 시트가 같은 판정을 쓴다.
/// progress 가 locked 를 이미 선언했으면 그것을 존중하고, 아니면 unlock gate.
bool isActivityLocked(
  ActivityCatalogEntry entry,
  SoriActivityProgress? progress,
) {
  if (progress?.state == SoriActivityState.locked) return true;
  return !entry.unlock.isUnlocked;
}

/// 활동 카드 일러스트 경로 — 규약: `assets/illustrations/activities/{id}.webp`.
/// 파일을 넣기만 하면 뜬다 (errorBuilder 폴백 계약).
String activityIllustrationAsset(String activityId) =>
    'assets/illustrations/activities/$activityId.webp';

// ─── §C-1-10: 레이어 역전 수리 ──────────────────────────────
// soriActivityColor / soriActivityIcon 을 widget 층(여기)으로 이동.
// screen 층 sori_stage_common.dart 에서는 re-export 한다.

/// Activity 카탈로그 컬러 — [SoriActivityColorRole] → concrete [Color].
Color soriActivityColor(SoriActivityColorRole role) => switch (role) {
  SoriActivityColorRole.listening => SoriActivityColors.listening,
  SoriActivityColorRole.speaking => SoriActivityColors.speaking,
  SoriActivityColorRole.review => SoriActivityColors.review,
  SoriActivityColorRole.completion => SoriActivityColors.completion,
  SoriActivityColorRole.reward => SoriActivityColors.reward,
  SoriActivityColorRole.collaboration => SoriActivityColors.collaboration,
  SoriActivityColorRole.hanok => SoriActivityColors.hanokStage,
};

/// Activity 카탈로그 아이콘 — iconName 문자열 → [IconData].
IconData soriActivityIcon(String name) => switch (name) {
  'headphones' => Icons.headphones_rounded,
  'mic' => Icons.mic_rounded,
  'brush' => Icons.brush_rounded,
  'cards' => Icons.style_rounded,
  'repeat' => Icons.replay_rounded,
  'target' => Icons.track_changes_rounded,
  'grammar' => Icons.account_tree_outlined,
  'dialogue' || 'chat' => Icons.forum_outlined,
  'camera' => Icons.document_scanner_outlined,
  'bookshelf' => Icons.auto_stories_outlined,
  'search' => Icons.search_rounded,
  'hub' => Icons.hub_rounded,
  'sun' => Icons.wb_sunny_outlined,
  'chosung' => Icons.text_fields_rounded,
  'grid' => Icons.grid_view_rounded,
  'cloze' => Icons.space_bar_rounded,
  'bolt' => Icons.bolt_rounded,
  'arcade' => Icons.sports_esports_outlined,
  'chain' => Icons.link_rounded,
  'keyboard' => Icons.keyboard_alt_outlined,
  'matching' => Icons.compare_arrows_rounded,
  'quiz' => Icons.quiz_outlined,
  'hangul' => Icons.translate_rounded,
  _ => Icons.route_rounded,
};

/// 일러스트 미존재 시 폴백 — 활동 컬러 배경 위에 아이콘을 그린 원형 위젯.
///
/// [SoriIllustratedCard.fallback] 슬롯에 들어가므로 AspectRatio 바깥에서
/// Center 배치된다.
class ActivityIconFallback extends StatelessWidget {
  const ActivityIconFallback({
    super.key,
    required this.iconName,
    required this.colorRole,
  });

  final String iconName;
  final SoriActivityColorRole colorRole;

  @override
  Widget build(BuildContext context) {
    final color = soriActivityColor(colorRole);
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Icon(soriActivityIcon(iconName), size: 28, color: color),
    );
  }
}
