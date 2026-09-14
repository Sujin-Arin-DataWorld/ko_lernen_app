import 'package:flutter/material.dart';

import 'tokens.dart';
import 'updating_scene.dart';

const String kIlDuV3PreviewAsset =
    'assets/illustrations/hanok/ildu_v3_preview.png';

class HanokV3Preview extends StatelessWidget {
  const HanokV3Preview({
    super.key,
    required this.message,
    this.fit = BoxFit.contain,
    this.showOverlay = true,
  });

  final String message;
  final BoxFit fit;

  /// Root and summary compositions place the status in readable text outside art.
  final bool showOverlay;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    if (!showOverlay) {
      return Image.asset(
        kIlDuV3PreviewAsset,
        fit: fit,
        semanticLabel: message,
        errorBuilder: (_, _, _) => Center(child: Text(message)),
      );
    }
    return SoriUpdatingScene(
      asset: kIlDuV3PreviewAsset,
      message: message,
      alignment: Alignment.center,
      assetFit: fit,
      backdropColor: surfaces.surfaceAlt,
    );
  }
}
