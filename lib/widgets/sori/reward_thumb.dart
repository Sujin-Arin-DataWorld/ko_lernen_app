import 'package:flutter/material.dart';

import 'decoration_layer.dart' show kAvailableDecorations;
import 'tokens.dart';

/// 퀘스트 보상 장식의 썸네일 — `assets/illustrations/decorations/{slug}.png`.
///
/// 원래 `quests_screen` 안의 private 위젯이었다. Today 의 퀘스트 행이 같은
/// 그림을 써야 해서 위젯 층으로 올렸다 (widgets → screens import 금지).
///
/// 자산이 없는 슬러그는 **로드를 시도하지 않는다** — 웹에서 404 가 뜬다.
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
    final Widget giftIcon = Icon(
      Icons.card_giftcard_rounded,
      size: size * 0.65,
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
