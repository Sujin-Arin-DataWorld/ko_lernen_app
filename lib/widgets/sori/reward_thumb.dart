import 'package:flutter/material.dart';

import 'decoration_layer.dart' show kAvailableDecorations;
import 'tokens.dart';

/// Compact quest-reward preview shared by Quests and Sori Stage Today.
class SoriRewardThumb extends StatelessWidget {
  const SoriRewardThumb({
    super.key,
    required this.slug,
    this.earned = true,
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
      size: size * 0.65,
      color: earned ? SoriColors.success : s.textDim,
    );
    return Opacity(
      opacity: earned ? 1 : 0.4,
      child: SizedBox.square(
        dimension: size,
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
