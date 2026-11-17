import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'practice_motion.dart';
import 'sori/tokens.dart';

/// A quiet, faceted spell frame. Contact lights the rim once; neither the
/// layout nor the hit boxes move. It never triggers a learning action.
class PracticeMagicFrame extends StatelessWidget {
  const PracticeMagicFrame({super.key, required this.child, this.pulse = 0});
  final Widget child;
  final int pulse;

  @override
  Widget build(BuildContext context) => PracticeViewportGate(
    child: _MagicFrame(pulse: pulse, child: child),
  );
}

class _MagicFrame extends StatefulWidget {
  const _MagicFrame({required this.pulse, required this.child});
  final int pulse;
  final Widget child;
  @override
  State<_MagicFrame> createState() => _MagicFrameState();
}

class _MagicFrameState extends State<_MagicFrame>
    with SingleTickerProviderStateMixin {
  late final _light = AnimationController(
    vsync: this,
    duration: SoriMotion.verySlow,
    value: 1,
  );
  bool get _enabled =>
      TickerMode.valuesOf(context).enabled &&
      !Storage.reducedMotion &&
      !MediaQuery.disableAnimationsOf(context);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_enabled) {
      _light.stop();
      _light.value = 1;
    }
  }

  @override
  void didUpdateWidget(_MagicFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse != oldWidget.pulse) {
      if (widget.pulse > 0 && _enabled) {
        _light.forward(from: 0);
      } else {
        _light.stop();
        _light.value = 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _light,
    child: widget.child,
    builder: (context, child) => CustomPaint(
      foregroundPainter: _SpellFrame(_enabled ? _light.value : 1),
      child: child,
    ),
  );
  @override
  void dispose() {
    _light.dispose();
    super.dispose();
  }
}

class _SpellFrame extends CustomPainter {
  const _SpellFrame(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = SoriColors.info.withValues(alpha: .45);
    final rect = (Offset.zero & size).deflate(1);
    final r = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(SoriRadius.md),
    );
    canvas.drawRRect(r, edge);
    final diamond = Paint()..color = SoriColors.info.withValues(alpha: .65);
    for (final x in [Spacing.lg, size.width - Spacing.lg]) {
      final y = size.height - 1;
      canvas.drawPath(
        Path()
          ..moveTo(x, y - 3)
          ..lineTo(x + 3, y)
          ..lineTo(x, y + 3)
          ..lineTo(x - 3, y)
          ..close(),
        diamond,
      );
    }
    if (progress >= 1) {
      return;
    }
    final glow = math.sin(progress * math.pi);
    edge
      ..strokeWidth = 2.5
      ..color = SoriColors.info.withValues(alpha: glow * .8);
    canvas.drawRRect(r, edge);
    final center = Offset(size.width * progress, 1);
    canvas.drawCircle(center, 4, diamond);
    canvas.drawCircle(
      center,
      8,
      Paint()..color = SoriColors.info.withValues(alpha: glow * .15),
    );
  }

  @override
  bool shouldRepaint(_SpellFrame oldDelegate) =>
      progress != oldDelegate.progress;
}
