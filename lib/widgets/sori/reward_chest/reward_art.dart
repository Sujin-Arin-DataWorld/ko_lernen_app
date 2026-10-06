import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../c_gallery/c_materials.dart';
import 'reward_art_bounds.dart';

/// Fits the visible object, preserving original pixels and aspect ratio.
/// The approved HTML uses the same alpha >20 threshold for its object fit.
class RewardArt extends StatelessWidget {
  const RewardArt(this.asset, {super.key, this.fit = BoxFit.contain});
  final String asset;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => FutureBuilder<ui.Image>(
    future: CImageCache.load(asset),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text(AppL10n.of(context).catalogImageUnavailable));
      }
      if (!snapshot.hasData) {
        return const SizedBox.expand();
      }
      final image = snapshot.data!;
      final bounds = rewardArtBounds[asset];
      return CustomPaint(
        painter: _RewardArtPainter(
          image,
          bounds == null
              ? const Rect.fromLTWH(0, 0, 1, 1)
              : Rect.fromLTWH(bounds[0], bounds[1], bounds[2], bounds[3]),
          fit,
        ),
        size: Size.infinite,
      );
    },
  );
}

class _RewardArtPainter extends CustomPainter {
  const _RewardArtPainter(this.image, this.bounds, this.fit);
  final ui.Image image;
  final Rect bounds;
  final BoxFit fit;

  @override
  void paint(Canvas canvas, Size size) {
    final source = Rect.fromLTWH(
      bounds.left * image.width,
      bounds.top * image.height,
      bounds.width * image.width,
      bounds.height * image.height,
    );
    final fitted = applyBoxFit(fit, source.size, size);
    canvas.drawImageRect(
      image,
      source,
      Alignment.center.inscribe(fitted.destination, Offset.zero & size),
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(_RewardArtPainter old) =>
      old.image != image || old.bounds != bounds || old.fit != fit;
}
