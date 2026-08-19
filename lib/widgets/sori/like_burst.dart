import 'package:flutter/material.dart';

import 'tokens.dart';

/// One seokganju heart burst. Transform + opacity only (no layout shift).
class SoriLikeBurst extends StatelessWidget {
  const SoriLikeBurst({super.key, required this.visible, this.alignment});

  final bool visible;
  final Alignment? alignment;

  @override
  Widget build(BuildContext context) {
    final reduce = SoriMotion.reduceMotion(context);
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: reduce ? Duration.zero : SoriMotion.fast,
        child: AnimatedScale(
          scale: visible ? 1 : 0.6,
          duration: reduce ? Duration.zero : SoriMotion.fast,
          alignment: alignment ?? Alignment.center,
          child: Icon(
            Icons.favorite_rounded,
            size: 88,
            color: SoriColors.like.withValues(alpha: 0.92),
          ),
        ),
      ),
    );
  }
}
