import 'dart:math' as math;

import 'package:flutter/material.dart';

// NOTE: tokens.dart absichtlich nicht importiert — die Stempel-Farben sind
// als const Color() hier inline gehalten, damit der Stempel ohne Theme-Lookup
// in jedem Kontext (CustomPainter, Hero-Animation, off-screen render) ohne
// MediaQuery funktioniert. Die Farbwerte spiegeln die Dancheong-Palette aus
// HANGUL_SORI_STYLE_GUIDE.md wider.

/// 단청 도장 — 팩 클리어 시 한지 위에 찍히는 도장.
///
/// Phase 2 (stately-rising-jongga): 정적 SVG-fallback (PNG 자산이 오기 전).
/// Jin이 `assets/illustrations/stamps/stamp_*.png` 작업 끝나면 [asset]
/// 파라미터로 PNG 사용. 그 전까지는 CustomPainter로 단청 lotus 모티프 그림.
///
/// 사용:
/// ```dart
/// DancheongStamp(
///   motif: DancheongMotif.lotus,       // 토픽군별 다른 모티프
///   size: 96,
///   animate: true,                     // 결과 화면에서 찍히는 애니메이션
/// )
/// ```
enum DancheongMotif {
  lotus,         // 인사·자기소개·가족 (a1_greetings/family/self_intro)
  chrysanthemum, // 시간·숫자 (a1_time/numbers)
  plum,          // 감정·형용사 (a1/a2 feelings·descriptions)
  bamboo,        // 학교·직장 (a2/b1 work/education)
  cloud,         // 날씨·자연 (a2 weather, a2 health_misc)
  octagon,       // 음식·쇼핑 (a1/a2 food/shopping)
  mountain,      // 교통·여행 (a1/a2 transport)
  swastika,      // 신체·건강 (a1 body / a2 health)
}

/// Pack-ID → Motif Mapping. Konsistent über alle Phasen.
DancheongMotif motifForPackId(String packId) {
  final base = _baseOf(packId);
  return switch (base) {
    'a1_greetings' || 'a1_self_intro' || 'a1_family' => DancheongMotif.lotus,
    'a1_time' || 'a1_numbers' => DancheongMotif.chrysanthemum,
    'a1_descriptions' ||
    'a2_descriptions' ||
    'a2_feelings' ||
    'b1_emotions_relations' =>
      DancheongMotif.plum,
    'a2_work' || 'a2_education' || 'b1_work' || 'b2_work' || 'b2_education' =>
      DancheongMotif.bamboo,
    'a2_weather' || 'a2_health_misc' || 'b1_health_education' =>
      DancheongMotif.cloud,
    'a1_food' || 'a2_food' || 'a2_shopping' => DancheongMotif.octagon,
    'a1_transport' || 'a2_transport' => DancheongMotif.mountain,
    'a1_body' || 'a1_colors' || 'a1_position' => DancheongMotif.swastika,
    _ => DancheongMotif.lotus, // fallback
  };
}

String _baseOf(String packId) {
  final parts = packId.split('_');
  if (parts.isNotEmpty && int.tryParse(parts.last) != null) {
    return parts.sublist(0, parts.length - 1).join('_');
  }
  return packId;
}

class DancheongStamp extends StatefulWidget {
  final DancheongMotif motif;
  final double size;

  /// `true`면 찍히는 애니메이션 (scale 1.4 → 0.95 → 1.0, ~700ms).
  /// `false`면 즉시 1.0 정적.
  final bool animate;

  /// `true`면 stamped 효과 (찍힌 후 약간 ink-smudge feel — opacity 살짝 ↓).
  final bool stamped;

  const DancheongStamp({
    super.key,
    this.motif = DancheongMotif.lotus,
    this.size = 96,
    this.animate = false,
    this.stamped = false,
  });

  @override
  State<DancheongStamp> createState() => _DancheongStampState();
}

class _DancheongStampState extends State<DancheongStamp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    // overshoot → settle
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.4, end: 0.95)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
    ]).animate(_ctrl);
    _opacity = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5));

    if (widget.animate) {
      _ctrl.forward();
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Motif → `stamps/stamp_*.png` 파일 slug.
  static String _assetSlug(DancheongMotif m) => switch (m) {
        DancheongMotif.lotus => 'stamp_lotus',
        DancheongMotif.chrysanthemum => 'stamp_chrysanthemum',
        DancheongMotif.plum => 'stamp_plum',
        DancheongMotif.bamboo => 'stamp_bamboo',
        DancheongMotif.cloud => 'stamp_cloud',
        DancheongMotif.octagon => 'stamp_geometric_octagon',
        DancheongMotif.mountain => 'stamp_mountain',
        DancheongMotif.swastika => 'stamp_swastika',
      };

  @override
  Widget build(BuildContext context) {
    // PNG 자산 우선; 없으면(로드 실패) 기존 절차적 CustomPainter로 fallback.
    final painter = CustomPaint(
      size: Size(widget.size, widget.size),
      painter: _StampPainter(
        motif: widget.motif,
        intensity: widget.stamped ? 0.85 : 1.0,
      ),
    );
    Widget stamp = Image.asset(
      'assets/illustrations/stamps/${_assetSlug(widget.motif)}.png',
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => painter,
    );
    // stamped 도장은 약간 무광 (ink absorbed effect).
    if (widget.stamped) {
      stamp = Opacity(opacity: 0.92, child: stamp);
    }

    if (!widget.animate) return stamp;
    return AnimatedBuilder(
      animation: _ctrl,
      child: stamp,
      builder: (ctx, child) {
        return Opacity(
          opacity: _opacity.value.clamp(0.0, 1.0),
          child: Transform.scale(scale: _scale.value, child: child),
        );
      },
    );
  }
}

class _StampPainter extends CustomPainter {
  final DancheongMotif motif;
  final double intensity;
  _StampPainter({required this.motif, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(cx, cy);

    // Outer red ring — Dancheong red lifted
    final red = const Color(0xFFC44F40).withValues(alpha: intensity);
    final cream = const Color(0xFFFAF6EC);

    final ringPaint = Paint()..color = red;
    canvas.drawCircle(Offset(cx, cy), radius, ringPaint);

    // Inner cream circle (paper surface)
    final innerR = radius * 0.78;
    canvas.drawCircle(Offset(cx, cy), innerR, Paint()..color = cream);

    // Motif
    final motifPaint = Paint()..color = red.withValues(alpha: intensity * 0.95);
    final accentPaint = Paint()
      ..color = const Color(0xFFD4A22E).withValues(alpha: intensity); // 황 (gold)
    final tealPaint = Paint()
      ..color = const Color(0xFF1F7A6B).withValues(alpha: intensity); // 녹청

    switch (motif) {
      case DancheongMotif.lotus:
        _drawLotus(canvas, cx, cy, innerR, motifPaint, accentPaint);
        break;
      case DancheongMotif.chrysanthemum:
        _drawChrysanthemum(canvas, cx, cy, innerR, motifPaint, accentPaint);
        break;
      case DancheongMotif.plum:
        _drawPlum(canvas, cx, cy, innerR, motifPaint, accentPaint);
        break;
      case DancheongMotif.bamboo:
        _drawBamboo(canvas, cx, cy, innerR, tealPaint, motifPaint);
        break;
      case DancheongMotif.cloud:
        _drawCloud(canvas, cx, cy, innerR, motifPaint);
        break;
      case DancheongMotif.octagon:
        _drawOctagon(canvas, cx, cy, innerR, motifPaint, accentPaint);
        break;
      case DancheongMotif.mountain:
        _drawMountain(canvas, cx, cy, innerR, motifPaint, tealPaint);
        break;
      case DancheongMotif.swastika:
        _drawSwastika(canvas, cx, cy, innerR, motifPaint);
        break;
    }
  }

  // 8-petal lotus (radial)
  void _drawLotus(
    Canvas c, double cx, double cy, double r, Paint p, Paint accent,
  ) {
    const petals = 8;
    final petalLen = r * 0.55;
    final petalWidth = r * 0.18;
    for (int i = 0; i < petals; i++) {
      final angle = (i * 2 * math.pi / petals);
      c.save();
      c.translate(cx, cy);
      c.rotate(angle);
      final path = Path()
        ..moveTo(0, -r * 0.15)
        ..quadraticBezierTo(petalWidth, -r * 0.35, 0, -petalLen)
        ..quadraticBezierTo(-petalWidth, -r * 0.35, 0, -r * 0.15)
        ..close();
      c.drawPath(path, p);
      c.restore();
    }
    c.drawCircle(Offset(cx, cy), r * 0.16, accent);
  }

  void _drawChrysanthemum(
    Canvas c, double cx, double cy, double r, Paint p, Paint accent,
  ) {
    // double layer lotus, 12 petals each
    for (int layer = 0; layer < 2; layer++) {
      final petals = 12;
      final petalLen = layer == 0 ? r * 0.65 : r * 0.40;
      for (int i = 0; i < petals; i++) {
        final angle =
            (i * 2 * math.pi / petals) + (layer == 1 ? math.pi / petals : 0);
        c.save();
        c.translate(cx, cy);
        c.rotate(angle);
        final path = Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(r * 0.05, -r * 0.25, 0, -petalLen)
          ..quadraticBezierTo(-r * 0.05, -r * 0.25, 0, 0)
          ..close();
        c.drawPath(path, layer == 0 ? p : accent);
        c.restore();
      }
    }
    c.drawCircle(Offset(cx, cy), r * 0.12, p);
  }

  void _drawPlum(
    Canvas c, double cx, double cy, double r, Paint p, Paint accent,
  ) {
    // 5 round petals
    const petals = 5;
    final petalR = r * 0.28;
    final dist = r * 0.45;
    for (int i = 0; i < petals; i++) {
      final angle = (i * 2 * math.pi / petals) - math.pi / 2;
      final px = cx + math.cos(angle) * dist;
      final py = cy + math.sin(angle) * dist;
      c.drawCircle(Offset(px, py), petalR, p);
    }
    c.drawCircle(Offset(cx, cy), r * 0.18, accent);
  }

  void _drawBamboo(
    Canvas c, double cx, double cy, double r, Paint p, Paint dark,
  ) {
    // 3 vertical stalks
    final stalkW = r * 0.15;
    final stalkH = r * 1.4;
    final spacing = r * 0.4;
    for (int i = -1; i <= 1; i++) {
      final left = cx + i * spacing - stalkW / 2;
      final top = cy - stalkH / 2;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, stalkW, stalkH),
          const Radius.circular(4),
        ),
        p,
      );
      // segment lines
      for (int seg = 1; seg < 4; seg++) {
        final y = top + (stalkH / 4) * seg;
        c.drawLine(
          Offset(left, y),
          Offset(left + stalkW, y),
          Paint()
            ..color = dark.color
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  void _drawCloud(
    Canvas c, double cx, double cy, double r, Paint p,
  ) {
    // 3-bump cloud scroll
    final base = cy + r * 0.2;
    c.drawCircle(Offset(cx - r * 0.4, base), r * 0.3, p);
    c.drawCircle(Offset(cx, base - r * 0.1), r * 0.4, p);
    c.drawCircle(Offset(cx + r * 0.4, base), r * 0.3, p);
    // bottom curl
    final path = Path()
      ..moveTo(cx - r * 0.6, base + r * 0.1)
      ..quadraticBezierTo(cx, base + r * 0.4, cx + r * 0.6, base + r * 0.1);
    c.drawPath(
      path,
      Paint()
        ..color = p.color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawOctagon(
    Canvas c, double cx, double cy, double r, Paint p, Paint accent,
  ) {
    final sides = 8;
    final outer = r * 0.75;
    final inner = r * 0.5;
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * math.pi / sides) - math.pi / 8;
      final x = cx + math.cos(angle) * outer;
      final y = cy + math.sin(angle) * outer;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    c.drawPath(path, p);

    final innerPath = Path();
    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * math.pi / sides) - math.pi / 8;
      final x = cx + math.cos(angle) * inner;
      final y = cy + math.sin(angle) * inner;
      if (i == 0) {
        innerPath.moveTo(x, y);
      } else {
        innerPath.lineTo(x, y);
      }
    }
    innerPath.close();
    c.drawPath(innerPath, accent);
  }

  void _drawMountain(
    Canvas c, double cx, double cy, double r, Paint p, Paint accent,
  ) {
    // 3 triangular peaks (irworobongdo simplified)
    final base = cy + r * 0.5;
    // back peak
    final back = Path()
      ..moveTo(cx - r * 0.6, base)
      ..lineTo(cx, cy - r * 0.5)
      ..lineTo(cx + r * 0.6, base)
      ..close();
    c.drawPath(back, accent);
    // front peaks
    final left = Path()
      ..moveTo(cx - r * 0.7, base)
      ..lineTo(cx - r * 0.3, cy - r * 0.1)
      ..lineTo(cx + r * 0.1, base)
      ..close();
    c.drawPath(left, p);
    final right = Path()
      ..moveTo(cx - r * 0.1, base)
      ..lineTo(cx + r * 0.3, cy - r * 0.2)
      ..lineTo(cx + r * 0.7, base)
      ..close();
    c.drawPath(right, p);
  }

  void _drawSwastika(Canvas c, double cx, double cy, double r, Paint p) {
    // Korean traditional 卍 (manja) — geometric grid, NOT to be confused
    // with German nazi symbol (mirrored direction + 4 dots). For neutrality,
    // we draw a 4-petal pinwheel instead of full swastika.
    final arm = r * 0.55;
    final w = r * 0.2;
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      c.save();
      c.translate(cx, cy);
      c.rotate(angle);
      final path = Path()
        ..moveTo(0, -w / 2)
        ..lineTo(arm, -w / 2)
        ..lineTo(arm, -w * 1.5)
        ..lineTo(arm + w, 0)
        ..lineTo(arm, w * 1.5)
        ..lineTo(arm, w / 2)
        ..lineTo(0, w / 2)
        ..close();
      c.drawPath(path, p);
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_StampPainter old) =>
      old.motif != motif || old.intensity != intensity;
}

// Convenience helper for theme-aware accent if needed in future.
@visibleForTesting
Color dancheongRed() => const Color(0xFFC44F40);
