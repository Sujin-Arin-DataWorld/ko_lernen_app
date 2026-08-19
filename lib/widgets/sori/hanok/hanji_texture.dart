import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../hanok_tokens.dart';

/// **HanjiTexture** — 진짜 한지(닥 섬유) 텍스처 wrapper.
///
/// CustomPainter로 크림 워시 + 옅은 구름 톤 + **흩뿌려진 긴 곡선 닥 섬유**를 그린다
/// (실제 한지 결 재현 — 점/직선 아님). 카드/배경에 사용.
/// Performance: RepaintBoundary 내부 1회 페인트 후 cache.
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

  /// 섬유 강도(intensity). 0(없음) ~ 0.2 (또렷). 밀도·alpha를 함께 도출.
  /// 기본: [HanokSizing.hanjiNoiseAlpha] (카드=또렷). 전체 배경은 낮게 넘김(은은).
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
    final baseColor =
        color ?? (isLight ? HanokColors.hanjiCream : HanokColors.hanjiNight);
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
      painter: _HanjiPainter(
        baseColor: baseColor,
        noiseAlpha: alpha,
        seed: seed,
      ),
      child: child,
    );
  }
}

/// 위젯 트리 **밖**에서 같은 한지를 그린다 — 오프스크린 PNG 렌더처럼
/// [HanjiTexture] 를 얹을 수 없는 캔버스용 단일 진입점.
///
/// [HanjiTexture] 와 같은 페인터를 호출하므로 결·티끌·구름 얼룩이 화면과
/// 픽셀 규칙까지 같다. 캔버스 원점부터 [size] 만큼 채우니, 일부 영역만
/// 칠하려면 부르는 쪽에서 `save`/`clipRect`/`translate` 하고 부른다.
void paintHanjiInto(
  Canvas canvas,
  Size size, {
  required Color baseColor,
  double? noiseAlpha,
  int seed = 42,
}) {
  _HanjiPainter(
    baseColor: baseColor,
    noiseAlpha: noiseAlpha ?? HanokSizing.hanjiNoiseAlpha,
    seed: seed,
  ).paint(canvas, size);
}

/// 실제 한지("은은 크림" 룩)를 재현하는 페인터.
/// 크림 워시 + 따뜻한 구름 얼룩 + 먹 티끌(불순물 반점) + 가늘고 성긴 창백한 닥 섬유.
/// [noiseAlpha]가 강도(intensity) → 섬유 밀도(area/dens)·alpha·티끌 양을 함께 도출.
/// 결정적(seed) → shouldRepaint·테스트 재현.
class _HanjiPainter extends CustomPainter {
  final Color baseColor;
  final double noiseAlpha;
  final int seed;

  _HanjiPainter({
    required this.baseColor,
    required this.noiseAlpha,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // 1. 크림 베이스 워시
    canvas.drawRect(Offset.zero & size, Paint()..color = baseColor);

    final k = noiseAlpha.clamp(0.0, 0.3);
    if (k <= 0 || w <= 0 || h <= 0) {
      return;
    }
    final isLight = baseColor.computeLuminance() > 0.5;
    final rng = math.Random(seed);

    final area = w * h;

    // 2. 따뜻한 구름 얼룩 — 종이 톤 불균일(warm ivory)
    final warmCloud = isLight ? const Color(0xFFD4C496) : HanokColors.baek;
    final coolCloud = isLight ? const Color(0xFFFFFDF7) : HanokColors.hanjiInk;
    final cloudCount = (area / 9000).round().clamp(2, 40);
    const cloudA = 0.075;
    for (var i = 0; i < cloudCount; i++) {
      final cx = rng.nextDouble() * w, cy = rng.nextDouble() * h;
      final cr = 48 + rng.nextDouble() * 115;
      final warm = rng.nextDouble() < 0.55;
      final tone = warm ? warmCloud : coolCloud;
      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: cr);
      canvas.drawCircle(
        Offset(cx, cy),
        cr,
        Paint()
          ..shader = RadialGradient(
            colors: [
              tone.withValues(alpha: warm ? cloudA : cloudA + 0.01),
              tone.withValues(alpha: 0.0),
            ],
          ).createShader(rect),
      );
    }

    // 3. 먹 티끌 — 불순물 반점(작고 성기게, 강도에 비례)
    final speckColor = isLight ? const Color(0xFF65583E) : HanokColors.baek;
    final speckScale = (k * 5.5).clamp(0.3, 1.2);
    final speckCount = (area / 5500 * speckScale).round().clamp(0, 900);
    final speckPaint = Paint();
    for (var i = 0; i < speckCount; i++) {
      speckPaint.color = speckColor.withValues(
        alpha: 0.10 + rng.nextDouble() * 0.26,
      );
      canvas.drawCircle(
        Offset(rng.nextDouble() * w, rng.nextDouble() * h),
        0.4 + rng.nextDouble() * 1.05,
        speckPaint,
      );
    }

    // 4. 닥 섬유 — 가늘고 성긴 창백한 곡선(은은 크림). 밝은 섬유 절반.
    final darkFiber = isLight ? const Color(0xFFB2A57C) : HanokColors.baek;
    final lightFiber = isLight ? const Color(0xFFFFFCF5) : HanokColors.baek;
    final dens = (4600.0 - 20000.0 * k).clamp(1200.0, 3000.0);
    final fiberCount = (area / dens).round().clamp(0, 1400);
    final fiber = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < fiberCount; i++) {
      final x0 = rng.nextDouble() * w, y0 = rng.nextDouble() * h;
      final len = 14 + rng.nextDouble() * 95;
      final ang = rng.nextDouble() * math.pi * 2;
      final perp = ang + math.pi / 2;
      final bow = (rng.nextDouble() - 0.5) * len * 0.45;
      final x1 = x0 + math.cos(ang) * len;
      final y1 = y0 + math.sin(ang) * len;
      final mx = (x0 + x1) / 2 + math.cos(perp) * bow;
      final my = (y0 + y1) / 2 + math.sin(perp) * bow;
      final isLightFiber = rng.nextDouble() < 0.5;
      final a = (k * (0.4 + rng.nextDouble())).clamp(0.0, 0.5);
      fiber
        ..color = (isLightFiber ? lightFiber : darkFiber).withValues(
          alpha: isLightFiber ? (a * 1.35).clamp(0.0, 0.5) : a,
        )
        ..strokeWidth = 0.4 + rng.nextDouble() * 0.95;
      canvas.drawPath(
        Path()
          ..moveTo(x0, y0)
          ..quadraticBezierTo(mx, my, x1, y1),
        fiber,
      );
    }
  }

  @override
  bool shouldRepaint(_HanjiPainter old) =>
      old.baseColor != baseColor ||
      old.noiseAlpha != noiseAlpha ||
      old.seed != seed;
}
