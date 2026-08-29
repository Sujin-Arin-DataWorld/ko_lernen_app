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
  final double dragPixelsPerStep;
  final int cacheWidth;

  const HanokTurntable2D({
    super.key,
    required this.frames,
    required this.direction,
    required this.onDirectionChanged,
    required this.semanticsLabel,
    this.dragPixelsPerStep = 28,
    this.cacheWidth = 512,
  }) : assert(frames.length == 8),
       assert(direction >= 0 && direction < 8),
       assert(dragPixelsPerStep > 0);

  @override
  State<HanokTurntable2D> createState() => _HanokTurntable2DState();
}

class _HanokTurntable2DState extends State<HanokTurntable2D> {
  double _dragAccumulator = 0;

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

  void _handleDrag(DragUpdateDetails details) {
    _dragAccumulator += details.delta.dx;
    final steps = (_dragAccumulator / widget.dragPixelsPerStep).truncate();
    if (steps == 0) {
      return;
    }
    _dragAccumulator -= steps * widget.dragPixelsPerStep;
    // Dragging left advances clockwise; dragging right walks back.
    _turnBy(-steps);
  }

  @override
  Widget build(BuildContext context) {
    final frame = widget.frames[widget.direction];
    final duration = SoriMotion.respect(
      context,
      const Duration(milliseconds: 110),
    );
    return Semantics(
      key: const ValueKey('hanok-turntable-semantics'),
      container: true,
      image: true,
      label: widget.semanticsLabel,
      value: '${widget.direction + 1} / ${widget.frames.length}',
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
          onHorizontalDragStart: (_) => _dragAccumulator = 0,
          onHorizontalDragUpdate: _handleDrag,
          onHorizontalDragEnd: (_) => _dragAccumulator = 0,
          onHorizontalDragCancel: () => _dragAccumulator = 0,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: duration,
                switchInCurve: SoriMotion.gentle,
                switchOutCurve: SoriMotion.gentle,
                child: HanokTurntableFrameImage(
                  key: ValueKey('hanok-turntable-frame-${widget.direction}'),
                  frame: frame,
                  cacheWidth: widget.cacheWidth,
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
    final bounds = frame.contentBounds;
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
