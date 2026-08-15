import 'package:flutter/material.dart';

import 'placed_decoration.dart' show kAvailableDecorations;
import 'tokens.dart';

/// **SoriRewardThumb** — 퀘스트/보상이 언락하는 마당 장식의 썸네일
/// (§P3-3b, 2026-08-14 — `quests_screen.dart` 의 `_RewardThumb` 를 위젯 층으로
/// 승격, widgets → screens import 금지 규칙 §C-1-10 선례).
///
/// 미획득 → 딤. 자산이 없는 슬러그는 로드 시도 없이 선물 아이콘 (웹 404 방지).
class SoriRewardThumb extends StatelessWidget {
  const SoriRewardThumb({
    super.key,
    required this.slug,
    required this.earned,
    this.size = 34,
  });

  final String slug;
  final bool earned;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final giftIcon = Icon(
      Icons.card_giftcard_rounded,
      size: size * (22 / 34),
      color: earned ? SoriColors.success : s.textDim,
    );
    return Opacity(
      opacity: earned ? 1.0 : 0.4,
      child: SizedBox(
        width: size,
        height: size,
        child: kAvailableDecorations.contains(slug)
            ? Image.asset(
                'assets/illustrations/decorations/$slug.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => giftIcon,
              )
            : giftIcon,
      ),
    );
  }
}
