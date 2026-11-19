import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The short pearlescent anticipation, driven by the existing reveal clock.
/// Geometry is relative to chest width; no timers, randomness or asset edits.
class RewardChestPreludePainter extends CustomPainter {
  const RewardChestPreludePainter({
    required this.second,
    required this.origin,
    required this.floor,
    required this.chestWidth,
    required this.lift,
  });

  final double second;
  final Offset origin;
  final Offset floor;
  final double chestWidth;
  final double lift;

  static const _silver = Color(0xFFBACBD9);
  static const _lavender = Color(0xFFBCA9D1);
  static const _teal = Color(0xFF94C9BF);
  static const _gold = Color(0xFFE4BD77);
  static const _starts = <Offset>[
    Offset(-0.54, -0.16),
    Offset(0.56, -0.11),
    Offset(-0.44, -0.43),
    Offset(0.42, -0.49),
    Offset(-0.18, -0.60),
    Offset(0.08, -0.68),
    Offset(-0.55, 0.12),
    Offset(0.51, 0.11),
  ];
  static const _colors = [_silver, _lavender, _teal, _silver];
  static const _lobes = <(Offset, Offset, double, Color)>[
    (Offset(-0.22, -0.18), Offset(0.48, 0.55), -0.28, _lavender),
    (Offset(0.24, -0.12), Offset(0.43, 0.49), 0.35, _teal),
    (Offset(-0.04, -0.34), Offset(0.44, 0.39), -0.10, _silver),
  ];

  double _phase(double start, double end, [Curve curve = Curves.linear]) =>
      curve.transform(((second - start) / (end - start)).clamp(0.0, 1.0));

  double get opacity =>
      _phase(0, 0.20, Curves.easeOutCubic) *
      (1 - _phase(1.02, 1.42, Curves.easeInOutCubic));

  double get warmth => _phase(0.74, 1.18, Curves.easeInOutCubic);

  double get shadowOpacity =>
      opacity * 0.10 * (1 - 0.65 * lift.clamp(0.0, 1.0));

  int get moteCount => _starts.length;

  /// Chest-relative position. Inward and outward segments overlap without a
  /// reset at opening, so the same light points hand off to the gold release.
  Offset motePosition(int index) {
    final start = _starts[index];
    final p = _phase(
      0.15 + index * 0.035,
      1.00 + index * 0.009,
      Curves.easeInOutCubic,
    );
    final bend = Offset(
      start.dx * 0.76 + (index.isEven ? 0.10 : -0.09),
      start.dy - 0.13,
    );
    final target = Offset((index % 3 - 1) * 0.025, -0.025);
    final u = 1 - p;
    final inward = start * (u * u) + bend * (2 * u * p) + target * (p * p);
    final release = _phase(
      1.04 + index * 0.008,
      1.36 + index * 0.006,
      Curves.easeOutCubic,
    );
    return (inward + Offset(start.dx * 0.46, -0.28) * release) * chestWidth;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0 || chestWidth <= 0) {
      return;
    }
    _groundLight(canvas);
    _pearlLight(canvas);
    _lightPoints(canvas);
  }

  void _ellipse(
    Canvas canvas, {
    required Offset center,
    required Offset radii,
    required List<Color> colors,
    List<double>? stops,
    double rotation = 0,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.scale(radii.dx, radii.dy);
    canvas.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = RadialGradient(
          colors: colors,
          stops: stops,
        ).createShader(const Rect.fromLTRB(-1, -1, 1, 1)),
    );
    canvas.restore();
  }

  Color _alpha(Color color, double value) =>
      color.withAlpha((value.clamp(0.0, 1.0) * 255).round());

  void _groundLight(Canvas canvas) {
    final rise = lift.clamp(0.0, 1.0);
    final tint = Color.lerp(_silver, _teal, 0.34)!;
    _ellipse(
      canvas,
      center: floor,
      radii: Offset(0.57 + rise * 0.05, 0.075 + rise * 0.01) * chestWidth,
      colors: [
        _alpha(tint, 0.20 * opacity),
        _alpha(tint, 0.10 * opacity),
        _alpha(tint, 0),
      ],
      stops: const [0, 0.46, 1],
    );
    _ellipse(
      canvas,
      center: floor.translate(0, chestWidth * 0.01),
      radii: Offset(0.39 + rise * 0.05, 0.030 + rise * 0.014) * chestWidth,
      colors: [
        _alpha(const Color(0xFF657C80), shadowOpacity),
        _alpha(const Color(0xFF657C80), 0),
      ],
    );
  }

  void _pearlLight(Canvas canvas) {
    final gather = _phase(0.46, 1.05, Curves.easeInOutCubic);
    // One breath follows the lift, not a separate looping animation.
    final breath = math.sin(_phase(0, 0.98) * math.pi);
    for (var i = 0; i < _lobes.length; i++) {
      final lobe = _lobes[i];
      final drift = Offset(
        math.sin(second * math.pi + i * 1.7) * 0.016,
        -breath * 0.016,
      );
      final center =
          origin + (lobe.$1 * (1 - gather * 0.22) + drift) * chestWidth;
      final color = Color.lerp(lobe.$4, _gold, warmth * 0.45)!;
      final alpha = opacity * (0.86 + breath * 0.14);
      // Offset translucent rims overlap into an irregular pearl halo. No
      // stroked circle, straight seam, full-screen tint, fog texture or ribbon.
      _ellipse(
        canvas,
        center: center,
        radii: lobe.$2 * chestWidth * (1 + breath * 0.045 - gather * 0.10),
        rotation: lobe.$3 + breath * 0.035,
        colors: [
          _alpha(color, 0),
          _alpha(color, 0.10 * alpha),
          _alpha(color, 0.30 * alpha),
          _alpha(color, 0),
        ],
        stops: const [0, 0.38, 0.65, 1],
      );
    }
  }

  void _lightPoints(Canvas canvas) {
    for (var i = 0; i < moteCount; i++) {
      final appear = _phase(0.15 + i * 0.035, 0.29 + i * 0.035, Curves.easeOut);
      final alpha = opacity * appear * (0.73 + i % 3 * 0.09);
      if (alpha <= 0) {
        continue;
      }
      final position = origin + motePosition(i);
      final color = Color.lerp(_colors[i % _colors.length], _gold, warmth)!;
      final radius = chestWidth * (0.017 + i % 3 * 0.003);
      canvas.drawCircle(
        position,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [_alpha(color, 0.38 * alpha), _alpha(color, 0)],
          ).createShader(Rect.fromCircle(center: position, radius: radius)),
      );
      // Tiny light core, not a pearl, ball, star icon or reflective sphere.
      canvas.drawCircle(
        position,
        chestWidth * (0.0030 + i % 2 * 0.0008),
        Paint()..color = _alpha(color, alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant RewardChestPreludePainter oldDelegate) =>
      oldDelegate.second != second ||
      oldDelegate.origin != origin ||
      oldDelegate.floor != floor ||
      oldDelegate.chestWidth != chestWidth ||
      oldDelegate.lift != lift;
}
