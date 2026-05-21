import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A small gat-wearing magpie that periodically crosses the top of the screen.
///
/// The flight path is procedural, but the character itself uses the separated
/// wing-up / wing-down mascot PNGs so it matches the rest of the app art.
class FlyingMagpie extends StatefulWidget {
  /// Flight band top position (0 = top of screen, 1 = bottom).
  final double bandTop;

  /// Upward arc height as a fraction of screen height.
  final double archHeight;

  /// Magpie size in logical pixels.
  final double size;

  /// Full flight + off-screen rest cycle.
  final Duration cycle;

  const FlyingMagpie({
    super.key,
    this.bandTop = 0.16,
    this.archHeight = 0.07,
    this.size = 56,
    this.cycle = const Duration(seconds: 22),
  });

  @override
  State<FlyingMagpie> createState() => _FlyingMagpieState();
}

class _FlyingMagpieState extends State<FlyingMagpie>
    with SingleTickerProviderStateMixin {
  static const _wingUp = 'assets/illustrations/mascot/magpie_wingup.png';
  static const _wingDown = 'assets/illustrations/mascot/magpie_wingdown.png';
  static const double _flightFrac = 0.40;

  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.cycle)..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return AnimatedBuilder(
            animation: _c,
            builder: (_, __) => _flightFrame(size),
          );
        },
      ),
    );
  }

  Widget _flightFrame(Size size) {
    final t = _c.value;
    if (size.isEmpty || t > _flightFrac) return const SizedBox.expand();

    final ft = t / _flightFrac;
    final margin = widget.size * 1.6;
    final x = -margin + (size.width + margin * 2) * ft;
    final arc = math.sin(ft * math.pi);
    final y =
        widget.bandTop * size.height - arc * widget.archHeight * size.height;

    final flap = math.sin(t * 64 * 2 * math.pi);
    final bob = flap * widget.size * 0.035;
    final bank = -math.cos(ft * math.pi) * 0.17;
    final fade = (ft < 0.10)
        ? ft / 0.10
        : (ft > 0.90 ? (1.0 - ft) / 0.10 : 1.0);
    final asset = flap >= 0 ? _wingUp : _wingDown;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: x - widget.size / 2,
          top: y + bob - widget.size / 2,
          width: widget.size,
          height: widget.size,
          child: Opacity(
            opacity: fade.clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: bank,
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
