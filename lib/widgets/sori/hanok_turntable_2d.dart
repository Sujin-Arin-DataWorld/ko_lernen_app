import 'package:flutter/material.dart';

import '../../data/ildu_turntable_catalog.dart';
import 'tokens.dart';

/// Controlled, eight-direction 2.5D viewer for an authored Hanok turnaround.
///
/// It changes only between supplied PNGs. No image is mirrored, rotated, or
/// synthesized at runtime.
class HanokTurntable2D extends StatefulWidget {
  final List<IlDuTurntableFrame> frames;
  final int direction;
  final ValueChanged<int> onDirectionChanged;
  final String semanticsLabel;
  final String zoomInLabel;
  final String zoomOutLabel;
  final String resetZoomLabel;
  final double dragPixelsPerStep;

  const HanokTurntable2D({
    super.key,
    required this.frames,
    required this.direction,
    required this.onDirectionChanged,
    required this.semanticsLabel,
    required this.zoomInLabel,
    required this.zoomOutLabel,
    required this.resetZoomLabel,
    this.dragPixelsPerStep = 28,
  }) : assert(frames.length == 8),
       assert(direction >= 0 && direction < 8),
       assert(dragPixelsPerStep > 0);

  @override
  State<HanokTurntable2D> createState() => _HanokTurntable2DState();
}

class _HanokTurntable2DState extends State<HanokTurntable2D> {
  static const double _minScale = .75;
  static const double _maxScale = 2.5;
  static const double _zoomStep = .25;

  double _dragAccumulator = 0;
  double _scale = 1;
  double _gestureStartScale = 1;
  bool _gestureHasScaled = false;

  @override
  void didUpdateWidget(HanokTurntable2D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.frames, widget.frames)) {
      _scale = 1;
      return;
    }
    _scale = _scale.clamp(_minScale, _maxScale).toDouble();
  }

  int _wrap(int value) {
    final remainder = value % widget.frames.length;
    return remainder < 0 ? remainder + widget.frames.length : remainder;
  }

  void _turnBy(int steps) {
    final next = _wrap(widget.direction + steps);
    if (next != widget.direction) {
      widget.onDirectionChanged(next);
    }
  }

  void _handleHorizontalDelta(double delta) {
    _dragAccumulator += delta;
    final steps = (_dragAccumulator / widget.dragPixelsPerStep).truncate();
    if (steps == 0) {
      return;
    }
    _dragAccumulator -= steps * widget.dragPixelsPerStep;
    // Dragging left advances clockwise; dragging right walks back.
    _turnBy(-steps);
  }

  void _setScale(double value) {
    final next = value.clamp(_minScale, _maxScale).toDouble();
    if ((next - _scale).abs() < .001) {
      return;
    }
    setState(() => _scale = next);
  }

  void _zoomBy(double delta) => _setScale(_scale + delta);

  void _handleScaleStart(ScaleStartDetails details) {
    _dragAccumulator = 0;
    _gestureStartScale = _scale;
    _gestureHasScaled = false;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final scaleChanged = (details.scale - 1).abs() > .015;
    if (details.pointerCount > 1 || _gestureHasScaled || scaleChanged) {
      _gestureHasScaled = true;
      _setScale(_gestureStartScale * details.scale);
      return;
    }

    _handleHorizontalDelta(details.focalPointDelta.dx);
  }

  void _handleScaleEnd(ScaleEndDetails _) {
    _dragAccumulator = 0;
    _gestureHasScaled = false;
  }

  @override
  Widget build(BuildContext context) {
    final frame = widget.frames[widget.direction];
    return Semantics(
      key: const ValueKey('hanok-turntable-semantics'),
      container: true,
      explicitChildNodes: true,
      image: true,
      label: widget.semanticsLabel,
      value:
          '${widget.direction + 1} / ${widget.frames.length}, '
          '${(_scale * 100).round()}%',
      increasedValue:
          '${_wrap(widget.direction + 1) + 1} / ${widget.frames.length}',
      decreasedValue:
          '${_wrap(widget.direction - 1) + 1} / ${widget.frames.length}',
      onIncrease: () => _turnBy(1),
      onDecrease: () => _turnBy(-1),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: GestureDetector(
          key: const ValueKey('hanok-turntable-drag-area'),
          behavior: HitTestBehavior.opaque,
          onScaleStart: _handleScaleStart,
          onScaleUpdate: _handleScaleUpdate,
          onScaleEnd: _handleScaleEnd,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              Transform.scale(
                key: const ValueKey('hanok-turntable-zoom-layer'),
                scale: _scale,
                alignment: Alignment.bottomCenter,
                child: HanokTurntableFrameImage(
                  key: ValueKey('hanok-turntable-frame-${widget.direction}'),
                  frame: frame,
                  cacheWidth: frame.sourceSize.width.round(),
                ),
              ),
              Positioned(
                top: Spacing.xs,
                right: Spacing.xs,
                child: Material(
                  color: SoriColors.darkBg.withValues(alpha: .76),
                  borderRadius: SoriRadius.brSm,
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ZoomButton(
                        key: const ValueKey('hanok-turntable-zoom-out'),
                        icon: Icons.remove_rounded,
                        label: widget.zoomOutLabel,
                        onPressed: _scale > _minScale + .001
                            ? () => _zoomBy(-_zoomStep)
                            : null,
                      ),
                      _ZoomButton(
                        key: const ValueKey('hanok-turntable-zoom-reset'),
                        icon: Icons.center_focus_strong_rounded,
                        label: widget.resetZoomLabel,
                        onPressed: (_scale - 1).abs() > .001
                            ? () => _setScale(1)
                            : null,
                      ),
                      _ZoomButton(
                        key: const ValueKey('hanok-turntable-zoom-in'),
                        icon: Icons.add_rounded,
                        label: widget.zoomInLabel,
                        onPressed: _scale < _maxScale - .001
                            ? () => _zoomBy(_zoomStep)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: Spacing.xs,
                bottom: Spacing.xs,
                child: ExcludeSemantics(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: SoriColors.darkBg.withValues(alpha: .72),
                        borderRadius: SoriRadius.brPill,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.sm,
                          vertical: 2,
                        ),
                        child: Text(
                          '${widget.direction + 1}/8',
                          style: SoriTextTheme.of(context).caption.copyWith(
                            color: const Color(0xFFFFF8E8),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HanokTurntableFrameImage extends StatelessWidget {
  final IlDuTurntableFrame frame;
  final int cacheWidth;

  const HanokTurntableFrameImage({
    super.key,
    required this.frame,
    required this.cacheWidth,
  });

  @override
  Widget build(BuildContext context) {
    final bounds = frame.displayBounds;
    return RepaintBoundary(
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: bounds.width,
          height: bounds.height,
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: -bounds.left,
                  top: -bounds.top,
                  width: frame.sourceSize.width,
                  height: frame.sourceSize.height,
                  child: ExcludeSemantics(
                    child: Image.asset(
                      frame.assetPath,
                      fit: BoxFit.fill,
                      cacheWidth: cacheWidth,
                      filterQuality: FilterQuality.medium,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _ZoomButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 18,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      color: const Color(0xFFFFF8E8),
      disabledColor: const Color(0x66FFF8E8),
      visualDensity: VisualDensity.compact,
    );
  }
}
