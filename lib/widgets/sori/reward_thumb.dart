import 'package:flutter/material.dart';

import 'decoration_layer.dart' show kAvailableDecorations;
import 'tokens.dart';

/// Quest decoration thumbnail — shared by Quests list and Today closest-quests.
///
/// Missing PNG / unknown slug → gift icon. Unearned → dimmed.
class RewardThumb extends StatelessWidget {
  final String slug;
  final bool earned;
  final double size;

  const RewardThumb({
    super.key,
    required this.slug,
    required this.earned,
    this.size = 34,
  });

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
        // Skip load for unknown slugs (avoids web 404 spam).
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
