import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../hanok_tokens.dart';

/// **HanjiTexture** — 한지 paper grain 텍스처 wrapper.
///
/// CustomPainter로 미세 noise + warm cream tint. 카드/banner 배경에 사용.
/// Performance: noise는 build 시 한 번 생성 후 cache (RepaintBoundary 권장).
///
/// 사용:
/// ```dart
/// HanjiTexture(
///   borderRadius: BorderRadius.circular(16),
///   child: Padding(
///     padding: EdgeInsets.all(16),
///     child: ...,
///   ),
/// )
/// ```
class HanjiTexture extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  /// 한지 base color override. 기본: [HanokColors.hanjiCream] (light) / [HanokColors.hanjiNight] (dark)
  final Color? color;
  /// noise 강도. 0(없음) ~ 0.15 (확연). 기본: [HanokSizing.hanjiNoiseAlpha]
  final double? noiseAlpha;
  /// 미세 random seed — 같은 seed면 같은 패턴 (테스트 재현성).
  final int seed;

  const HanjiTexture({
    super.key,
    required this.child,
    this.borderRadius,
    this.color,
    this.noiseAlpha,
    this.seed = 42,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final baseColor = color ?? (isLight ? HanokColors.hanjiCream : HanokColors.hanjiNight);
    final alpha = noiseAlpha ?? HanokSizing.hanjiNoiseAlpha;

    final clipper = borderRadius != null
        ? ClipRRect(
            borderRadius: borderRadius!,
            child: _build(baseColor, alpha),
          )
        : _build(baseColor, alpha);

    return RepaintBoundary(child: clipper);
  }

  Widget _build(Color baseColor, double alpha) {
    return CustomPaint(
      painter: _HanjiPainter(baseColor: baseColor, noiseAlpha: alpha, seed: seed),
      child: child,
    );
  }
}

class _HanjiPainter extends CustomPainter {
  final Color baseColor;
  final double noiseAlpha;
  final int seed;

  _HanjiPainter({required this.baseColor, required this.noiseAlpha, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    // Base wash
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = baseColor,
    );

    // Noise grain — 작은 점을 random sparse하게
    final rng = math.Random(seed);
    final inkColor = baseColor.computeLuminance() > 0.5
        ? HanokColors.hanjiInk
        : HanokColors.baek;

    final paint = Paint()..color = inkColor.withValues(alpha: noiseAlpha);

    // grain density: ~1 spot per 80 px² (subtle)
    final spotCount = ((size.width * size.height) / 80).round();

    for (var i = 0; i < spotCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 0.6 + 0.2;  // 0.2 ~ 0.8 px
      canvas.drawCircle(Offset(x, y), r, paint);
    }

    // 한지 fiber 결 — 미세한 가로 선 3-5개
    final fiberPaint = Paint()
      ..color = inkColor.withValues(alpha: noiseAlpha * 0.6)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final fiberCount = (size.height / 80).round().clamp(2, 6);
    for (var i = 0; i < fiberCount; i++) {
      final y = (i + 0.5) * size.height / fiberCount + (rng.nextDouble() - 0.5) * 6;
      final xStart = rng.nextDouble() * size.width * 0.3;
      final xEnd = size.width - rng.nextDouble() * size.width * 0.3;
      canvas.drawLine(Offset(xStart, y), Offset(xEnd, y), fiberPaint);
    }
  }

  @override
  bool shouldRepaint(_HanjiPainter old) =>
      old.baseColor != baseColor ||
      old.noiseAlpha != noiseAlpha ||
      old.seed != seed;
}
