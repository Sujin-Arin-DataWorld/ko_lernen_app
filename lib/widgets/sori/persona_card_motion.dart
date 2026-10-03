import 'package:flutter/material.dart';

import 'motion.dart';
import 'tokens.dart';

/// Shared, finite feedback for persona browsing and dialogue cards.
/// The child owns activation and its existing press/haptic/semantic contract.
class SoriPersonaCardMotion extends StatefulWidget {
  const SoriPersonaCardMotion({
    super.key,
    required this.child,
    this.interactive = false,
    this.index = 0,
    this.depth = true,
    this.entrance = true,
    this.borderRadius = SoriRadius.brMd,
  });

  final Widget child;
  final bool interactive;
  final int index;
  final bool depth;
  final bool entrance;
  final BorderRadius borderRadius;

  @override
  State<SoriPersonaCardMotion> createState() => _SoriPersonaCardMotionState();
}

class _SoriPersonaCardMotionState extends State<SoriPersonaCardMotion> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;
  Offset? _touchOrigin;
  double _tiltX = 0;
  double _tiltY = 0;

  void _touch(PointerDownEvent event) {
    if (!widget.interactive) return;
    _touchOrigin = event.position;
    final box = context.findRenderObject() as RenderBox?;
    final size = box?.size;
    setState(() {
      _pressed = true;
      if (size == null || size.isEmpty) return;
      _tiltX = (.5 - (event.localPosition.dy / size.height).clamp(0, 1)) * .14;
      _tiltY = ((event.localPosition.dx / size.width).clamp(0, 1) - .5) * .18;
    });
  }

  void _release() {
    if (!_pressed) return;
    setState(() {
      _pressed = false;
      _touchOrigin = null;
      _tiltX = _tiltY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.interactive && (_hovered || _focused);
    final reduced = SoriMotion.reduceMotion(context);
    final surfaces = SoriSurfaces.of(context);
    final accent = surfaces.brightness == Brightness.light
        ? SoriColors.primaryDark
        : SoriColors.darkPrimary;
    final physicalDepth = _pressed ? 2.0 : 6.0;
    final edge = surfaces.brightness == Brightness.light
        ? surfaces.border
        : Color.alphaBlend(Colors.black.withValues(alpha: .4), surfaces.bg);
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, .0012)
      ..rotateX(reduced ? 0 : _tiltX)
      ..rotateY(reduced ? 0 : _tiltY)
      ..translateByDouble(
        0,
        reduced ? 0 : (_pressed ? 4 : (highlighted ? -3 : 0)),
        0,
        1,
      );
    final surface = Focus(
      canRequestFocus: false,
      includeSemantics: false,
      onFocusChange: (value) => setState(() => _focused = value),
      child: MouseRegion(
        onEnter: widget.interactive
            ? (_) => setState(() => _hovered = true)
            : null,
        onExit: (_) => setState(() => _hovered = false),
        child: Listener(
          onPointerDown: _touch,
          onPointerUp: (_) => _release(),
          onPointerCancel: (_) => _release(),
          onPointerMove: (event) {
            if (_touchOrigin != null &&
                (event.position - _touchOrigin!).distance > 14) {
              _release();
            }
          },
          child: AnimatedContainer(
            duration: SoriMotion.respect(
              context,
              _pressed ? const Duration(milliseconds: 80) : SoriMotion.medium,
            ),
            curve: Curves.easeOutCubic,
            transform: matrix,
            transformAlignment: Alignment.center,
            decoration: widget.depth
                ? BoxDecoration(
                    borderRadius: widget.borderRadius,
                    boxShadow: [
                      BoxShadow(color: edge, offset: Offset(0, physicalDepth)),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .14),
                        offset: Offset(0, physicalDepth + 6),
                        blurRadius: 18,
                      ),
                    ],
                  )
                : null,
            foregroundDecoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              border: Border.all(
                width: 2,
                color: highlighted || (reduced && _pressed)
                    ? accent
                    : Colors.transparent,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
    return RepaintBoundary(
      child: !widget.entrance || widget.index >= 6
          ? surface
          : SoriEntrance(
              delay: Duration(milliseconds: widget.index * 35),
              duration: SoriMotion.medium,
              slideY: 8,
              startScale: .99,
              child: surface,
            ),
    );
  }
}
