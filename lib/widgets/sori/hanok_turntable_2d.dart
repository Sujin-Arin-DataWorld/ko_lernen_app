import 'package:flutter/material.dart';

import '../../data/ildu_turntable_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
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
  final double minZoom;
  final double maxZoom;
  final double zoomStep;

  const HanokTurntable2D({
    super.key,
    required this.frames,
    required this.direction,
    required this.onDirectionChanged,
    required this.semanticsLabel,
    this.dragPixelsPerStep = 28,
    this.cacheWidth = 512,
    this.minZoom = .75,
    this.maxZoom = 2.5,
    this.zoomStep = .25,
  }) : assert(frames.length == 8),
       assert(direction >= 0 && direction < 8),
       assert(dragPixelsPerStep > 0),
       assert(minZoom > 0),
       assert(maxZoom >= 1),
       assert(minZoom < maxZoom),
       assert(zoomStep > 0);

  @override
  State<HanokTurntable2D> createState() => _HanokTurntable2DState();
}

class _HanokTurntable2DState extends State<HanokTurntable2D> {
  double _dragAccumulator = 0;
  double _zoom = 1;
  double _gestureStartZoom = 1;

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

  double _clampZoom(double value) =>
      value.clamp(widget.minZoom, widget.maxZoom).toDouble();

  void _setZoom(double value) {
    final next = _clampZoom(value);
    if (next == _zoom) {
      return;
    }
    setState(() {
      _zoom = next;
    });
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _dragAccumulator = 0;
    _gestureStartZoom = _zoom;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final isZoomGesture =
        details.pointerCount > 1 || (details.scale - 1).abs() > .001;
    if (isZoomGesture) {
      _dragAccumulator = 0;
      _setZoom(_gestureStartZoom * details.scale);
      return;
    }
    _dragAccumulator += details.focalPointDelta.dx;
    final steps = (_dragAccumulator / widget.dragPixelsPerStep).truncate();
    if (steps == 0) {
      return;
    }
    _dragAccumulator -= steps * widget.dragPixelsPerStep;
    // Dragging left advances clockwise; dragging right walks back.
    _turnBy(-steps);
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _dragAccumulator = 0;
    _gestureStartZoom = _zoom;
  }

  @override
  Widget build(BuildContext context) {
    final frame = widget.frames[widget.direction];
    final t = AppL10n.of(context);
    final zoomPercent = (_zoom * 100).round();
    final duration = SoriMotion.respect(
      context,
      const Duration(milliseconds: 110),
    );
    return Semantics(
      key: const ValueKey('hanok-turntable-semantics'),
      container: true,
      image: true,
      label: widget.semanticsLabel,
      value: '${widget.direction + 1} / ${widget.frames.length}, $zoomPercent%',
      increasedValue:
          '${_wrap(widget.direction + 1) + 1} / ${widget.frames.length}',
      decreasedValue:
          '${_wrap(widget.direction - 1) + 1} / ${widget.frames.length}',
      onIncrease: () => _turnBy(1),
      onDecrease: () => _turnBy(-1),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: GestureDetector(
                key: const ValueKey('hanok-turntable-drag-area'),
                behavior: HitTestBehavior.opaque,
                onScaleStart: _handleScaleStart,
                onScaleUpdate: _handleScaleUpdate,
                onScaleEnd: _handleScaleEnd,
                child: Transform.scale(
                  key: const ValueKey('hanok-turntable-image-transform'),
                  scale: _zoom,
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    duration: duration,
                    switchInCurve: SoriMotion.gentle,
                    switchOutCurve: SoriMotion.gentle,
                    child: HanokTurntableFrameImage(
                      key: ValueKey(
                        'hanok-turntable-frame-${widget.direction}',
                      ),
                      frame: frame,
                      cacheWidth: widget.cacheWidth,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: Spacing.xs,
            top: Spacing.xs,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: SoriColors.darkBg.withValues(alpha: .78),
                borderRadius: SoriRadius.brPill,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const ValueKey('hanok-turntable-zoom-out'),
                    tooltip: t.personalRoomMakeSmaller,
                    onPressed: _zoom <= widget.minZoom
                        ? null
                        : () => _setZoom(_zoom - widget.zoomStep),
                    icon: const Icon(Icons.remove_rounded),
                    color: const Color(0xFFFFF8E8),
                    disabledColor: const Color(0x66FFF8E8),
                    iconSize: 18,
                    style: IconButton.styleFrom(
                      minimumSize: const Size.square(44),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('hanok-turntable-zoom-reset'),
                    onPressed: _zoom == 1 ? null : () => _setZoom(1),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 44),
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.xs,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: const Color(0xFFFFF8E8),
                      disabledForegroundColor: const Color(0xFFFFF8E8),
                    ),
                    child: Text('$zoomPercent%'),
                  ),
                  IconButton(
                    key: const ValueKey('hanok-turntable-zoom-in'),
                    tooltip: t.personalRoomMakeLarger,
                    onPressed: _zoom >= widget.maxZoom
                        ? null
                        : () => _setZoom(_zoom + widget.zoomStep),
                    icon: const Icon(Icons.add_rounded),
                    color: const Color(0xFFFFF8E8),
                    disabledColor: const Color(0x66FFF8E8),
                    iconSize: 18,
                    style: IconButton.styleFrom(
                      minimumSize: const Size.square(44),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
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
