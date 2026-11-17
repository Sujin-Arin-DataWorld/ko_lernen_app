import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import 'practice_motion.dart';
import 'sori/tokens.dart';

/// Highlights the existing card border once when the club makes contact.
/// Decoration alone repaints; the character, cells and input keep their bounds.
class PracticeImpactFrame extends StatelessWidget {
  const PracticeImpactFrame({super.key, required this.child, this.pulse = 0});
  final Widget child;
  final int pulse;

  @override
  Widget build(BuildContext context) => PracticeViewportGate(
    child: _ImpactFrame(pulse: pulse, child: child),
  );
}

abstract final class PracticeImpactTiming {
  static const rise = Duration(milliseconds: 100);
  static const hold = Duration(milliseconds: 150);
  static const fade = Duration(milliseconds: 900);
  static const total = Duration(milliseconds: 1150);
}

class _ImpactFrame extends StatefulWidget {
  const _ImpactFrame({required this.child, required this.pulse});
  final Widget child;
  final int pulse;
  @override
  State<_ImpactFrame> createState() => _ImpactFrameState();
}

class _ImpactFrameState extends State<_ImpactFrame>
    with SingleTickerProviderStateMixin {
  late final _clock = AnimationController(
    vsync: this,
    duration: PracticeImpactTiming.total,
    value: 1,
  );

  bool get _enabled =>
      TickerMode.valuesOf(context).enabled &&
      !Storage.reducedMotion &&
      !MediaQuery.disableAnimationsOf(context);

  void _stop() {
    _clock.stop();
    _clock.value = 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_enabled) _stop();
  }

  @override
  void didUpdateWidget(_ImpactFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse != oldWidget.pulse) {
      if (widget.pulse > 0 && _enabled) {
        _clock.forward(from: 0);
      } else {
        _stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _ImpactPainter(clock: _clock, enabled: _enabled),
    child: RepaintBoundary(child: widget.child),
  );

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }
}

class _ImpactPainter extends CustomPainter {
  _ImpactPainter({required this.clock, required this.enabled})
    : super(repaint: clock);
  final Animation<double> clock;
  final bool enabled;
  static const _blue = Color(0xFF137DE0);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.shortestSide <= 3) return;
    var strength = 0.0;
    if (enabled && clock.value < 1) {
      final elapsed = clock.value * PracticeImpactTiming.total.inMilliseconds;
      final fadeStart =
          PracticeImpactTiming.rise.inMilliseconds +
          PracticeImpactTiming.hold.inMilliseconds;
      strength = elapsed < PracticeImpactTiming.rise.inMilliseconds
          ? Curves.easeOutCubic.transform(
              (elapsed / PracticeImpactTiming.rise.inMilliseconds).clamp(0, 1),
            )
          : Curves.easeInOut.transform(
              (1 -
                      (elapsed - fadeStart) /
                          PracticeImpactTiming.fade.inMilliseconds)
                  .clamp(0, 1),
            );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(1.5),
        const Radius.circular(SoriRadius.md),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 + 2 * strength
        ..color = Color.lerp(
          SoriColors.info.withValues(alpha: .32),
          _blue,
          strength,
        )!,
    );
  }

  @override
  bool shouldRepaint(_ImpactPainter oldDelegate) =>
      clock != oldDelegate.clock || enabled != oldDelegate.enabled;
}
