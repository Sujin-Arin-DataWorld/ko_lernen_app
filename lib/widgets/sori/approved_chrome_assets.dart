import 'package:flutter/material.dart';

/// Byte-identical user originals. Provenance: APPROVED_CHROME_20261030.json.
abstract final class ApprovedChromeAssets {
  static const cloud = 'assets/icons/chrome/cloud.png';
  static const settings = 'assets/icons/chrome/settings-gear.png';
  static const coinAngled = 'assets/icons/chrome/yeopjeon-angled.png';
  static const coinFront = 'assets/icons/chrome/yeopjeon-front.png';
  static const today = 'assets/icons/navigation/today.png';
  static const learn = 'assets/icons/navigation/learn.png';
  static const games = 'assets/icons/navigation/games.png';
  static const hanok = 'assets/icons/navigation/hanok.png';
  static const gye = 'assets/icons/navigation/gye.png';
}

/// Keeps the complete transparent original, with bounded decode memory.
class ApprovedChromeImage extends StatelessWidget {
  const ApprovedChromeImage({
    super.key,
    required this.asset,
    required this.size,
  });

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    width: size,
    height: size,
    cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    excludeFromSemantics: true,
  );
}
