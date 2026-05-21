import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../hanok_tokens.dart';

/// **MadangBackground** — 한옥 마당 분위기 home 배경.
///
/// Stack의 가장 아래에 깔아 콘텐츠 위에 subtle 한옥 분위기 부여.
///
/// 3 layer:
/// 1. **하늘 (top 35%)** — dark teal/cream 그라데이션 (모드별)
/// 2. **한옥 처마 silhouette (middle 12%)** — 멀리 보이는 지붕 라인
/// 3. **마당 (bottom 53%)** — 한지 크림/dark earthy 그라데이션
///
/// 추가 detail:
/// - dark mode: 우측 상단 보름달
/// - light mode: 우측 상단 은은한 해
/// - bottom corner: 작은 호랑이 silhouette (optional)
///
/// 사용:
/// ```dart
/// Stack(children: [
///   const MadangBackground(),         // 배경
///   SafeArea(child: ...content...),   // 콘텐츠
/// ])
/// ```
class MadangBackground extends StatelessWidget {
  /// 호랑이 silhouette 보여줄지. 기본 true.
  final bool showTigerSilhouette;

  const MadangBackground({super.key, this.showTigerSilhouette = true});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Positioned.fill(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _MadangPainter(
            isLight: isLight,
            showTigerSilhouette: showTigerSilhouette,
          ),
        ),
      ),
    );
  }
}

class _MadangPainter extends CustomPainter {
  final bool isLight;
  final bool showTigerSilhouette;

  _MadangPainter({required this.isLight, required this.showTigerSilhouette});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final skyH = h * 0.35;
    final roofY = skyH;
    final groundY = skyH + h * 0.12;

    // ── 1. 하늘 그라데이션 ──────────────────────────────────────────
    final skyTop = isLight ? HanokColors.madangSkyLight : HanokColors.madangSkyDark;
    final skyBottom = isLight
        ? HanokColors.hanjiCream.withValues(alpha: 0.6)
        : HanokColors.madangSkyDark.withValues(alpha: 0.85);

    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [skyTop, skyBottom],
      ).createShader(Rect.fromLTWH(0, 0, w, skyH));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, skyH), skyPaint);

    // ── 2. 달 (dark) / 해 (light) — 우측 상단 ────────────────────────
    final celestialColor = isLight
        ? HanokColors.hwang.withValues(alpha: 0.25)        // 은은한 해
        : HanokColors.hanjiCream.withValues(alpha: 0.30);  // 보름달
    canvas.drawCircle(
      Offset(w * 0.82, h * 0.10),
      h * 0.045,
      Paint()..color = celestialColor,
    );

    // ── 3. 한옥 silhouette (멀리 보이는 처마 + 기와) ────────────────
    final roofColor = isLight
        ? HanokColors.giwaShadow.withValues(alpha: 0.18)
        : HanokColors.giwaShadow.withValues(alpha: 0.45);
    final roofPaint = Paint()..color = roofColor;

    // 한옥 1동 — 곡선 처마
    final hanok = Path()
      ..moveTo(w * 0.10, roofY)
      ..lineTo(w * 0.10, roofY - h * 0.03)
      ..quadraticBezierTo(w * 0.25, roofY - h * 0.085, w * 0.50, roofY - h * 0.095)
      ..quadraticBezierTo(w * 0.75, roofY - h * 0.085, w * 0.90, roofY - h * 0.03)
      ..lineTo(w * 0.90, roofY)
      ..close();
    canvas.drawPath(hanok, roofPaint);

    // 처마 끝 살짝 올라간 곡선 (양옆)
    final eaveCurve = Paint()
      ..color = roofColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.10, roofY - h * 0.02), radius: h * 0.025),
      math.pi * 0.5, math.pi * 0.3, false, eaveCurve,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.90, roofY - h * 0.02), radius: h * 0.025),
      math.pi * 0.2, math.pi * 0.3, false, eaveCurve,
    );

    // ── 4. 마당 (ground) ───────────────────────────────────────────
    final groundTop = isLight
        ? HanokColors.madangGround
        : HanokColors.madangGroundDark;
    final groundBottom = isLight
        ? HanokColors.hanjiCreamDark
        : HanokColors.madangGroundDark.withValues(alpha: 0.95);

    final groundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [groundTop, groundBottom],
      ).createShader(Rect.fromLTWH(0, groundY, w, h - groundY));
    canvas.drawRect(Rect.fromLTWH(0, groundY, w, h - groundY), groundPaint);

    // ── 5. 작은 호랑이 silhouette (bottom right, optional) ──────────
    if (showTigerSilhouette) {
      _drawTinyTiger(canvas, w, h);
    }
  }

  void _drawTinyTiger(Canvas canvas, double w, double h) {
    // 우측 하단 코너에 작은 호랑이 (옆모습) 실루엣
    final tigerColor = isLight
        ? HanokColors.heuk.withValues(alpha: 0.10)
        : HanokColors.heuk.withValues(alpha: 0.30);
    final paint = Paint()..color = tigerColor;

    // 호랑이 옆모습 silhouette (very minimal)
    final cx = w * 0.85;
    final cy = h * 0.82;
    final s = h * 0.04;       // scale

    // Body (타원)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: s * 4, height: s * 1.8),
      paint,
    );
    // Head (원, 살짝 앞에)
    canvas.drawCircle(Offset(cx + s * 1.5, cy - s * 0.5), s * 1.2, paint);
    // Tail (꼬리, 호 모양)
    final tail = Path()
      ..moveTo(cx - s * 2, cy)
      ..quadraticBezierTo(cx - s * 3, cy - s * 1.5, cx - s * 2.8, cy - s * 2);
    canvas.drawPath(
      tail,
      Paint()
        ..color = tigerColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.4
        ..strokeCap = StrokeCap.round,
    );
    // Ears (작은 삼각형 2개)
    canvas.drawCircle(Offset(cx + s * 0.9, cy - s * 1.4), s * 0.3, paint);
    canvas.drawCircle(Offset(cx + s * 1.9, cy - s * 1.4), s * 0.3, paint);
    // Legs (작은 4 stub)
    for (var i = 0; i < 4; i++) {
      canvas.drawRect(
        Rect.fromLTWH(cx - s * 1.8 + s * 1.1 * i, cy + s * 0.6, s * 0.3, s * 0.8),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MadangPainter old) =>
      old.isLight != isLight || old.showTigerSilhouette != showTigerSilhouette;
}
