import 'package:flutter/material.dart';

import 'pressable.dart';
import 'tokens.dart';

/// Figma 208:264: bounded contact and state feedback for Einleitung.
abstract final class IntroMotion {
  static const press = Duration(milliseconds: 100);
  static const release = Duration(milliseconds: 180);
  static const selection = Duration(milliseconds: 180);
  static const scene = Duration(milliseconds: 160);
  static const pressOffsetY = 1.5;
  static const sceneOffsetY = 4.0;
  static const settle = Curves.easeOutCubic;
}

/// The existing native input owner keeps keyboard, cancel and haptic behavior.
/// The complete face moves within unchanged layout and hit-test bounds.
class IntroPressable extends StatelessWidget {
  const IntroPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.pressScale = .995,
    this.surfaceDepth = 0,
    this.surfaceRadius = SoriRadius.lg,
    this.surfaceEdgeColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressScale;
  final double surfaceDepth;
  final double surfaceRadius;
  final Color? surfaceEdgeColor;

  @override
  Widget build(BuildContext context) => SoriPressable(
    onTap: onTap,
    pressScale: pressScale,
    pressOffsetY: IntroMotion.pressOffsetY,
    pressDuration: IntroMotion.press,
    releaseDuration: IntroMotion.release,
    pressCurve: IntroMotion.settle,
    releaseCurve: IntroMotion.settle,
    surfaceDepth: surfaceDepth,
    surfaceRadius: surfaceRadius,
    surfaceEdgeColor: surfaceEdgeColor,
    child: child,
  );
}

/// Paint-only feedback for the supplied gold check, never a new layout row.
class IntroSelectionMotion extends StatelessWidget {
  const IntroSelectionMotion({
    super.key,
    required this.selected,
    required this.child,
  });

  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: _IntroReveal(
        trigger: selected,
        visible: selected,
        duration: IntroMotion.selection,
        distance: IntroMotion.pressOffsetY,
        child: child,
      ),
    ),
  );
}

/// The selection border follows the same finite state transition as the check.
/// Decoration is painted around the unchanged child and never adds border padding.
class IntroSelectionSurface extends StatelessWidget {
  const IntroSelectionSurface({
    super.key,
    required this.selected,
    required this.idle,
    required this.active,
    required this.child,
  });

  final bool selected;
  final Decoration idle, active;
  final Widget child;

  @override
  Widget build(BuildContext context) => _IntroReveal(
    trigger: selected,
    visible: selected,
    duration: IntroMotion.selection,
    distance: 0,
    transitionBuilder: (_, value, child) => DecoratedBox(
      decoration: Decoration.lerp(idle, active, value)!,
      child: child,
    ),
    child: child,
  );
}

/// A single live scene: outgoing media is disposed immediately. Draft updates
/// keep the scene id, subtree identity, focus and scroll position unchanged.
class IntroSceneTransition extends StatelessWidget {
  const IntroSceneTransition({
    super.key,
    required this.sceneId,
    required this.child,
  });

  final Object sceneId;
  final Widget child;

  @override
  Widget build(BuildContext context) => _IntroReveal(
    trigger: sceneId,
    visible: true,
    restartOnChange: true,
    duration: IntroMotion.scene,
    distance: IntroMotion.sceneOffsetY,
    child: child,
  );
}

class _IntroReveal extends StatefulWidget {
  const _IntroReveal({
    required this.trigger,
    required this.visible,
    required this.duration,
    required this.distance,
    required this.child,
    this.restartOnChange = false,
    this.transitionBuilder,
  });

  final Object trigger;
  final bool visible;
  final Duration duration;
  final double distance;
  final bool restartOnChange;
  final Widget child;
  final Widget Function(BuildContext, double, Widget?)? transitionBuilder;

  @override
  State<_IntroReveal> createState() => _IntroRevealState();
}

class _IntroRevealState extends State<_IntroReveal>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  bool _motionEnabled = false;

  double get _target => widget.visible ? 1 : 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, value: _target);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motionEnabled =
        !SoriMotion.reduceMotion(context) &&
        TickerMode.valuesOf(context).enabled;
    if (!_motionEnabled) {
      _controller.stop();
      _controller.value = _target;
    }
  }

  @override
  void didUpdateWidget(covariant _IntroReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger == oldWidget.trigger) {
      return;
    }
    if (!_motionEnabled ||
        (WidgetsBinding.instance.lifecycleState != null &&
            WidgetsBinding.instance.lifecycleState !=
                AppLifecycleState.resumed)) {
      _controller.value = _target;
      return;
    }
    if (widget.restartOnChange) {
      _controller.value = 0;
    }
    _controller.animateTo(
      _target,
      duration: widget.duration,
      curve: IntroMotion.settle,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _controller.stop();
      _controller.value = _target;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) =>
        widget.transitionBuilder?.call(context, _controller.value, child) ??
        Opacity(
          opacity: _controller.value,
          alwaysIncludeSemantics: true,
          child: Transform.translate(
            offset: Offset(
              0,
              _motionEnabled ? (1 - _controller.value) * widget.distance : 0,
            ),
            child: child,
          ),
        ),
  );
}
