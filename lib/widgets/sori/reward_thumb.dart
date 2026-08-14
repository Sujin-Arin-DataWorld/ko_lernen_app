import 'package:flutter/material.dart';

import 'placed_decoration.dart' show kAvailableDecorations;
import 'tokens.dart';

/// 장식 PNG 썸네일 — 퀘스트·Today·Hanok 숏컷 공용 (widgets → screens import 금지).
class RewardThumb extends StatelessWidget {
  const RewardThumb({
    super.key,
    required this.slug,
    this.size = 34,
    this.earned = true,
  });

  final String slug;
  final double size;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final giftIcon = Icon(
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
                errorBuilder: (_, __, ___) => giftIcon,
              )
            : giftIcon,
      ),
    );
  }
}

/// Hanok 숏컷·Today 퀘스트 행에서 쓰는 대표 장식.
const String kRewardThumbShowcaseSlug = 'decoration_chaekgado';
