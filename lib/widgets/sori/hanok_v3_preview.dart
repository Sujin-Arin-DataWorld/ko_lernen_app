import 'package:flutter/material.dart';

import 'tokens.dart';
import 'updating_scene.dart';

const String kIlDuV3PreviewAsset =
    'assets/illustrations/hanok/ildu_v3_preview.png';

class HanokV3Preview extends StatelessWidget {
  const HanokV3Preview({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    return SoriUpdatingScene(
      asset: kIlDuV3PreviewAsset,
      message: message,
      alignment: Alignment.center,
      assetFit: BoxFit.contain,
      backdropColor: surfaces.surfaceAlt,
    );
  }
}
