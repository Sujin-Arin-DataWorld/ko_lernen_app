import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../services/haptic_service.dart';
import '../services/storage_service.dart';
import 'sori/tokens.dart';
import 'sori/video_lease.dart';

/// Decorative motion shares the route, lifecycle and viewport policy with video.
/// The gate must surround the state owning a ticker, rather than sit inside it.
class PracticeViewportGate extends StatefulWidget {
  const PracticeViewportGate({
    super.key,
    required this.child,
    this.requireFullVisibility = false,
  });
  final Widget child;

  /// Character video must fit inside the scroll viewport, including its head
  /// and club. Large enclosing cards only need to intersect that viewport.
  final bool requireFullVisibility;
  @override
  State<PracticeViewportGate> createState() => _PracticeViewportGateState();
}

class _PracticeViewportGateState extends State<PracticeViewportGate> {
  final _box = GlobalKey();
  late final VideoLeaseEligibilityBinding _eligibility;
  ScrollPosition? _scroll;
  Animation<double>? _routeAnimation, _secondaryAnimation;
  bool _visible = true, _queued = false;

  @override
  void initState() {
    super.initState();
    _eligibility = VideoLeaseEligibilityBinding(onChanged: _policyChanged);
    HapticService.preferencesChanged.addListener(_policyChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _eligibility.attach(context);
    // A modal sheet initially lays its child out below the screen. Its route
    // moves that same layout into view, so scroll/layout notifications alone
    // would leave decorative tickers disabled after the entrance completes.
    final route = ModalRoute.of(context);
    final animation = route?.animation;
    if (_routeAnimation != animation) {
      _routeAnimation?.removeListener(_schedule);
      _routeAnimation = animation;
      _routeAnimation?.addListener(_schedule);
    }
    final secondary = route?.secondaryAnimation;
    if (_secondaryAnimation != secondary) {
      _secondaryAnimation?.removeListener(_schedule);
      _secondaryAnimation = secondary;
      _secondaryAnimation?.addListener(_schedule);
    }
    final position = Scrollable.maybeOf(context)?.position;
    if (_scroll != position) {
      _scroll?.removeListener(_schedule);
      _scroll = position;
      _scroll?.addListener(_schedule);
    }
    _schedule();
  }

  @override
  void didUpdateWidget(PracticeViewportGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedule();
  }

  void _schedule() {
    if (!mounted || _queued) return;
    _queued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queued = false;
      if (!mounted) return;
      final box = _box.currentContext?.findRenderObject();
      var inView = false;
      if (box is RenderBox && box.hasSize && box.attached) {
        final rect = box.localToGlobal(Offset.zero) & box.size;
        final screen = Offset.zero & MediaQuery.sizeOf(context);
        final scrollBox = Scrollable.maybeOf(
          context,
        )?.context.findRenderObject();
        final viewport = scrollBox is RenderBox && scrollBox.hasSize
            ? screen.intersect(
                scrollBox.localToGlobal(Offset.zero) & scrollBox.size,
              )
            : screen;
        inView = widget.requireFullVisibility
            ? viewport.inflate(.5).contains(rect.topLeft) &&
                  viewport.inflate(.5).contains(rect.bottomRight)
            : rect.overlaps(viewport);
      }
      final visible =
          inView &&
          _eligibility.isVisible(context) &&
          !Storage.reducedMotion &&
          !MediaQuery.disableAnimationsOf(context);
      if (_visible != visible) setState(() => _visible = visible);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _policyChanged() {
    if (!mounted) return;
    if (!_eligibility.isVisible(context) ||
        Storage.reducedMotion ||
        MediaQuery.disableAnimationsOf(context)) {
      setState(() => _visible = false);
    }
    _schedule();
  }

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      disableAnimations:
          Storage.reducedMotion || MediaQuery.disableAnimationsOf(context),
    ),
    child: TickerMode(
      enabled:
          _visible &&
          !Storage.reducedMotion &&
          !MediaQuery.disableAnimationsOf(context) &&
          _eligibility.isVisible(context),
      child: KeyedSubtree(key: _box, child: widget.child),
    ),
  );

  @override
  void dispose() {
    _scroll?.removeListener(_schedule);
    _routeAnimation?.removeListener(_schedule);
    _secondaryAnimation?.removeListener(_schedule);
    HapticService.preferencesChanged.removeListener(_policyChanged);
    _eligibility.disposeBinding();
    super.dispose();
  }
}

/// Passive pointer observation keeps the existing buttons and scrolling in
/// charge. A scroll cancels the tilt; no new gesture recognizer claims input.
class PracticeMotionSurface extends StatelessWidget {
  const PracticeMotionSurface({
    super.key,
    required this.child,
    this.enter = false,
    this.interactive = false,
    this.pressDepth = 2,
    this.baseColor,
    this.radius = SoriRadius.md,
  });
  final Widget child;
  final bool enter, interactive;
  final double pressDepth;

  /// A fixed lower plate for a tactile action. Only the upper face moves.
  final Color? baseColor;
  final double radius;
  @override
  Widget build(BuildContext context) => PracticeViewportGate(
    child: _PaperMotion(
      enter: enter,
      interactive: interactive,
      pressDepth: pressDepth,
      baseColor: baseColor,
      radius: radius,
      child: child,
    ),
  );
}

class _PaperMotion extends StatefulWidget {
  const _PaperMotion({
    required this.child,
    required this.enter,
    required this.interactive,
    required this.pressDepth,
    required this.baseColor,
    required this.radius,
  });
  final Widget child;
  final bool enter, interactive;
  final double pressDepth;
  final Color? baseColor;
  final double radius;
  @override
  State<_PaperMotion> createState() => _PaperMotionState();
}

class _PaperMotionState extends State<_PaperMotion>
    with TickerProviderStateMixin {
  late final _press = AnimationController(
    vsync: this,
    duration: SoriMotion.fast,
  );
  late final _arrival = AnimationController(
    vsync: this,
    duration: SoriMotion.slow,
    value: widget.enter ? 0 : 1,
  );
  Offset _origin = Offset.zero, _tilt = Offset.zero;
  int? _pointer;
  int _pressSerial = 0;
  bool _entered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!TickerMode.valuesOf(context).enabled) {
      _pressSerial++;
      _press.stop();
      _press.value = 0;
      _arrival.value = 1;
      _pointer = null;
      _entered = true;
    } else if (!_entered) {
      _entered = true;
      _arrival.forward();
    }
  }

  void _down(PointerDownEvent event) {
    if (!widget.interactive ||
        !TickerMode.valuesOf(context).enabled ||
        _pointer != null) {
      return;
    }
    final box = context.findRenderObject() as RenderBox;
    _pressSerial++;
    _pointer = event.pointer;
    _origin = event.position;
    _tilt = Offset(
      (event.localPosition.dx / box.size.width * 2 - 1).clamp(-1, 1),
      (event.localPosition.dy / box.size.height * 2 - 1).clamp(-1, 1),
    );
    _press.forward();
  }

  void _release(int pointer, {bool cancel = false}) {
    if (_pointer != pointer) return;
    _pointer = null;
    final serial = _pressSerial;
    void settle() {
      if (!mounted ||
          serial != _pressSerial ||
          _pointer != null ||
          !TickerMode.valuesOf(context).enabled) {
        return;
      }
      _press
          .animateWith(
            SpringSimulation(SoriMotion.deckSpring, _press.value, 0, 0),
          )
          .whenCompleteOrCancel(() {
            if (mounted &&
                serial == _pressSerial &&
                _pointer == null &&
                !_press.isAnimating) {
              _press.value = 0;
            }
          });
    }

    // A quick tap still shows the 150 ms press. Scrolling cancels immediately.
    if (cancel || _press.value >= .75) {
      settle();
    } else {
      _press.forward().whenCompleteOrCancel(settle);
    }
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: _down,
    onPointerUp: (e) => _release(e.pointer),
    onPointerCancel: (e) => _release(e.pointer, cancel: true),
    onPointerMove: (e) {
      if ((e.position - _origin).distance > 8) {
        _release(e.pointer, cancel: true);
      }
    },
    child: AnimatedBuilder(
      animation: Listenable.merge([_press, _arrival]),
      child: RepaintBoundary(child: widget.child),
      builder: (context, child) {
        final active = TickerMode.valuesOf(context).enabled;
        final press = active ? _press.value : 0.0;
        final entry = active
            ? 1 - SoriMotion.emphasis.transform(_arrival.value)
            : 0.0;
        final matrix = Matrix4.identity();
        if (press != 0 || entry != 0) {
          matrix.setEntry(3, 2, .0015);
          matrix.translateByDouble(
            0,
            8 * entry + widget.pressDepth * press,
            0,
            1,
          );
          matrix.rotateX(-_tilt.dy * .04 * press - .035 * entry);
          matrix.rotateY(_tilt.dx * .04 * press);
          matrix.scaleByDouble(1 - .008 * press, 1 - .008 * press, 1, 1);
        }
        final face = Transform(
          key: const ValueKey('practice-paper-transform'),
          alignment: Alignment.center,
          transform: matrix,
          child: Opacity(opacity: 1 - .2 * entry, child: child),
        );
        final base = widget.baseColor;
        if (base == null) {
          return face;
        }
        return DecoratedBox(
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: [
              BoxShadow(color: base, offset: Offset(0, widget.pressDepth + 2)),
              BoxShadow(
                color: base.withValues(alpha: .14 * (1 - press)),
                offset: const Offset(0, Spacing.sm),
                blurRadius: Spacing.md,
              ),
            ],
          ),
          child: Stack(
            children: [
              face,
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.radius),
                      border: Border.all(
                        color: SoriColors.info.withValues(
                          alpha: .12 + .5 * press,
                        ),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0, .08, 1],
                        colors: [
                          Colors.white.withValues(alpha: .18 + .06 * press),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  @override
  void dispose() {
    _press.dispose();
    _arrival.dispose();
    super.dispose();
  }
}

/// Paint-only emphasis: grid hit boxes and tile placement coordinates stay put.
class PracticeHintEmphasis extends StatefulWidget {
  const PracticeHintEmphasis({
    super.key,
    required this.child,
    required this.pulse,
  });
  final Widget child;
  final int pulse;
  @override
  State<PracticeHintEmphasis> createState() => _PracticeHintEmphasisState();
}

class _PracticeHintEmphasisState extends State<PracticeHintEmphasis>
    with SingleTickerProviderStateMixin {
  late final _highlight = AnimationController(
    vsync: this,
    duration: SoriMotion.slow,
  );
  int _lastPulse = 0;
  bool get _canAnimate =>
      TickerMode.valuesOf(context).enabled &&
      !Storage.reducedMotion &&
      !MediaQuery.disableAnimationsOf(context);

  void _consumePulse() {
    if (!_canAnimate) {
      _lastPulse = widget.pulse;
      _highlight.stop();
      _highlight.value = 0;
    } else if (widget.pulse != _lastPulse) {
      _lastPulse = widget.pulse;
      if (widget.pulse > 0) {
        _highlight.reverse(from: 1);
      } else {
        _highlight.stop();
        _highlight.value = 0;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _consumePulse();
  }

  @override
  void didUpdateWidget(PracticeHintEmphasis oldWidget) {
    super.didUpdateWidget(oldWidget);
    _consumePulse();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _highlight,
    child: widget.child,
    builder: (context, child) => DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SoriRadius.sm),
        border: Border.all(
          color: SoriColors.info.withValues(alpha: _highlight.value * .7),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: SoriColors.info.withValues(alpha: _highlight.value * .2),
            blurRadius: 14,
          ),
        ],
      ),
      child: child,
    ),
  );

  @override
  void dispose() {
    _highlight.dispose();
    super.dispose();
  }
}

class PracticeImpactRipple extends StatelessWidget {
  const PracticeImpactRipple({super.key, required this.pulse});
  final int pulse;
  @override
  Widget build(BuildContext context) {
    if (!TickerMode.valuesOf(context).enabled ||
        Storage.reducedMotion ||
        MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox.shrink();
    }
    return ExcludeSemantics(
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(pulse),
          tween: Tween(begin: 0, end: 1),
          duration: pulse > 0 && TickerMode.valuesOf(context).enabled
              ? SoriMotion.slow
              : Duration.zero,
          builder: (context, value, _) =>
              CustomPaint(painter: _RipplePainter(pulse > 0 ? value : 1)),
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .838, size.height * .921);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = SoriColors.info.withValues(alpha: (1 - progress) * .8);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: 12 + 50 * progress,
        height: 6 + 22 * progress,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// A decorative copy travels to the answer. The real answer changes immediately.
class PracticeTokenFlight extends StatefulWidget {
  const PracticeTokenFlight({
    super.key,
    required this.from,
    required this.to,
    required this.text,
    required this.style,
    required this.onFinished,
    required this.visible,
  });
  final Rect from, to;
  final String text;
  final TextStyle style;
  final VoidCallback onFinished;
  final bool Function() visible;
  @override
  State<PracticeTokenFlight> createState() => _PracticeTokenFlightState();
}

class _PracticeTokenFlightState extends State<PracticeTokenFlight>
    with SingleTickerProviderStateMixin {
  late final _motion =
      AnimationController(vsync: this, duration: SoriMotion.medium)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) widget.onFinished();
        })
        ..forward();
  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: ExcludeSemantics(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _motion,
          builder: (context, _) {
            if (!widget.visible()) return const SizedBox.shrink();
            final t = SoriMotion.emphasis.transform(_motion.value);
            final center = Offset.lerp(
              widget.from.center,
              widget.to.center,
              t,
            )!;
            return Stack(
              children: [
                Positioned(
                  left: center.dx - widget.from.width / 2,
                  top:
                      center.dy -
                      widget.from.height / 2 -
                      math.sin(t * math.pi) * 12,
                  width: widget.from.width,
                  height: widget.from.height,
                  child: Opacity(
                    opacity: (1 - t).clamp(0, 1),
                    child: Transform.rotate(
                      angle: .04 * math.sin(t * math.pi),
                      child: Material(
                        color: SoriSurfaces.of(context).surface,
                        borderRadius: BorderRadius.circular(SoriRadius.sm),
                        elevation: 3,
                        child: Center(
                          child: Text(widget.text, style: widget.style),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }
}
