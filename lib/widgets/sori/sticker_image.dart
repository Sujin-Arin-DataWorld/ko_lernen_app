import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/sticker_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/sticker_localizations.dart';
import 'tokens.dart';

/// Shared, memory-bounded renderer for the 1254px sticker source images.
///
/// [semantic] defaults to the catalog's localized name. Pass an empty string
/// only when an accessible parent already owns the label (for example, the
/// picker's button semantics).
class StickerImage extends StatelessWidget {
  final StickerSpec spec;
  final double size;
  final String? semantic;
  final BoxFit fit;

  const StickerImage({
    super.key,
    required this.spec,
    required this.size,
    this.semantic,
    this.fit = BoxFit.contain,
  }) : assert(size > 0);

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final decodeDimension = math.min(
      768,
      math.max(1, (size * devicePixelRatio).ceil()),
    );
    final label = semantic ?? stickerName(AppL10n.of(context), spec);
    final image = SizedBox.square(
      dimension: size,
      child: Image.asset(
        spec.asset,
        fit: fit,
        filterQuality: FilterQuality.medium,
        cacheWidth: decodeDimension,
        cacheHeight: decodeDimension,
        excludeFromSemantics: true,
        errorBuilder: (_, __, ___) => Icon(
          Icons.emoji_emotions_outlined,
          color: SoriColors.primary,
          size: size * 0.48,
        ),
      ),
    );

    if (label.isEmpty) {
      return ExcludeSemantics(child: image);
    }
    return Semantics(
      image: true,
      label: label,
      excludeSemantics: true,
      child: image,
    );
  }
}
