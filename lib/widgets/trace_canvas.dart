import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'sori/tokens.dart';
import 'sori/c_gallery/c_calligraphy_canvas.dart';
import 'sori/c_gallery/c_calligraphy_ink.dart';

typedef TraceStrokeEndCallback =
    void Function(TraceCanvasSnapshot snapshot, Size canvasSize);

@immutable
final class TraceCanvasSnapshot {
  TraceCanvasSnapshot({required List<List<Offset>> strokes})
    : strokes = List<List<Offset>>.unmodifiable(
        strokes.map(List<Offset>.unmodifiable),
      );

  final List<List<Offset>> strokes;
}

final class TraceCanvasController extends ChangeNotifier {
  final List<List<Offset>> _strokes = [];
  final List<CInkStroke?> _inkStrokes = [];
  CInkStroke? _currentInk;
  List<Offset>? _currentStroke;
  List<Offset>? _errorGhost;
  List<Offset>? _nextStrokeHint;
  var _revision = 0;

  TraceCanvasSnapshot get snapshot => TraceCanvasSnapshot(strokes: _strokes);

  void rejectLastStroke() {
    if (_strokes.isEmpty) {
      return;
    }
    _errorGhost = List<Offset>.unmodifiable(_strokes.removeLast());
    _inkStrokes.removeLast();
    _currentInk = null;
    _currentStroke = null;
    _changed();
  }

  void clearErrorGhost() {
    if (_errorGhost == null) {
      return;
    }
    _errorGhost = null;
    _changed();
  }

  void showNextStrokeHint(List<Offset> points) {
    _nextStrokeHint = List<Offset>.unmodifiable(points);
    _changed();
  }

  void clearHint() {
    if (_nextStrokeHint == null) {
      return;
    }
    _nextStrokeHint = null;
    _changed();
  }

  void reset() {
    if (_strokes.isEmpty &&
        _currentStroke == null &&
        _errorGhost == null &&
        _nextStrokeHint == null) {
      return;
    }
    _strokes.clear();
    _inkStrokes.clear();
    _currentInk = null;
    _currentStroke = null;
    _errorGhost = null;
    _nextStrokeHint = null;
    _changed();
  }

  void _beginStroke(Offset point, {CInkPoint? inkPoint, bool stylus = false}) {
    _errorGhost = null;
    _currentStroke = <Offset>[point];
    _strokes.add(_currentStroke!);
    _currentInk = inkPoint == null
        ? null
        : CInkStroke(inkPoint, stylus: stylus);
    _inkStrokes.add(_currentInk);
    _changed();
  }

  void _moveStroke(Offset point, {CInkPoint? inkPoint}) {
    final current = _currentStroke;
    if (current == null) {
      return;
    }
    current.add(point);
    if (inkPoint != null) {
      _currentInk?.add(inkPoint);
    }
    _changed();
  }

  bool _endStroke() {
    final current = _currentStroke;
    if (current == null) {
      return false;
    }
    _currentStroke = null;
    _currentInk?.finish();
    _currentInk = null;
    if (current.length < 2) {
      _strokes.removeLast();
      _inkStrokes.removeLast();
      _changed();
      return false;
    }
    _changed();
    return true;
  }

  void _cancelStroke({bool notify = true}) {
    if (_currentStroke == null) {
      return;
    }
    _strokes.removeLast();
    _inkStrokes.removeLast();
    _currentInk = null;
    _currentStroke = null;
    if (notify) {
      _changed();
    } else {
      _revision++;
    }
  }

  void _changed() {
    _revision++;
    notifyListeners();
  }
}

class TraceCanvas extends StatefulWidget {
  const TraceCanvas({
    super.key,
    required this.controller,
    required this.ghost,
    required this.color,
    required this.errorColor,
    required this.enabled,
    required this.onStrokeEnd,
    required this.semanticLabel,
    this.paintKey,
    this.calligraphy = false,
    this.canonicalCoordinates = false,
    this.parkedBrush,
    this.brushScale = 1,
    this.brushAngle = .42,
  });

  final TraceCanvasController controller;
  final String ghost;
  final Color color;
  final Color errorColor;
  final bool enabled;
  final TraceStrokeEndCallback onStrokeEnd;
  final String semanticLabel;
  final Key? paintKey;

  /// C writing uses the pressure/time sidecar, without changing snapshots.
  final bool calligraphy;

  /// A resize must not change historical paths or the assessment reference.
  /// Atelier stores centered, uniform 220-unit paths at pointer capture time.
  final bool canonicalCoordinates;
  final Offset? parkedBrush;
  final double brushScale;
  final double brushAngle;

  @override
  State<TraceCanvas> createState() => _TraceCanvasState();
}

class _TraceCanvasState extends State<TraceCanvas> {
  int? _activePointer;
  Size? _paperSize;

  @override
  void didUpdateWidget(covariant TraceCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _cancelActiveStroke(oldWidget.controller);
    } else if ((oldWidget.enabled && !widget.enabled) ||
        oldWidget.calligraphy != widget.calligraphy) {
      _cancelActiveStroke(widget.controller);
    }
  }

  @override
  void dispose() {
    _cancelActiveStroke(widget.controller, notify: false);
    super.dispose();
  }

  void _cancelActiveStroke(
    TraceCanvasController controller, {
    bool notify = true,
  }) {
    if (_activePointer == null) {
      return;
    }
    _activePointer = null;
    controller._cancelStroke(notify: notify);
  }

  void _startStroke(PointerDownEvent event) {
    if (!widget.enabled || _activePointer != null) {
      return;
    }
    _activePointer = event.pointer;
    widget.controller._beginStroke(
      _point(event.localPosition),
      inkPoint: _inkPoint(event),
      stylus: CCalligraphyMotion.isPen(event.kind),
    );
  }

  void _updateStroke(PointerMoveEvent event) {
    if (_activePointer != event.pointer) {
      return;
    }
    widget.controller._moveStroke(
      _point(event.localPosition),
      inkPoint: _inkPoint(event),
    );
  }

  void _endStroke(PointerUpEvent event) {
    if (_activePointer != event.pointer) {
      return;
    }
    _activePointer = null;
    if (!widget.controller._endStroke()) {
      return;
    }
    final box = context.findRenderObject();
    final size = box is RenderBox && box.hasSize ? box.size : Size.zero;
    widget.onStrokeEnd(
      widget.controller.snapshot,
      widget.canonicalCoordinates ? const Size.square(220) : size,
    );
  }

  Offset _point(Offset local) {
    if (!widget.canonicalCoordinates) {
      return local;
    }
    final size = (context.findRenderObject()! as RenderBox).size;
    final side = size.shortestSide;
    return (local - Offset((size.width - side) / 2, (size.height - side) / 2)) *
        (220 / side);
  }

  CInkPoint? _inkPoint(PointerEvent event) => !widget.calligraphy
      ? null
      : CInkPoint(
          _point(event.localPosition),
          event.timeStamp,
          CCalligraphyMotion.pressure(event),
        );

  void _cancelStroke(PointerCancelEvent event) {
    if (_activePointer != event.pointer) {
      return;
    }
    _cancelActiveStroke(widget.controller);
  }

  @override
  Widget build(BuildContext context) {
    final drawing = LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (_paperSize != null && _paperSize != size) {
          // Geometry changes retire only the in-flight pointer. Accepted ink is
          // already stored in the stable 220-unit reference coordinate system.
          _cancelActiveStroke(widget.controller, notify: false);
        }
        _paperSize = size;
        return RawGestureDetector(
          key: const Key('trace-canvas'),
          behavior: HitTestBehavior.opaque,
          gestures: <Type, GestureRecognizerFactory>{
            EagerGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                  EagerGestureRecognizer.new,
                  (_) {},
                ),
          },
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _startStroke,
            onPointerMove: _updateStroke,
            onPointerUp: _endStroke,
            onPointerCancel: _cancelStroke,
            child: AnimatedBuilder(
              animation: widget.controller,
              builder: (context, _) => Stack(
                clipBehavior: widget.calligraphy ? Clip.none : Clip.hardEdge,
                fit: StackFit.expand,
                children: [
                  if (widget.calligraphy)
                    CCalligraphyCanvas(
                      strokes: widget.controller._inkStrokes
                          .whereType<CInkStroke>()
                          .toList(),
                      revision: widget.controller._revision,
                      canonicalCoordinates: widget.canonicalCoordinates,
                      parkedBrush: widget.parkedBrush,
                      brushOverflow: widget.canonicalCoordinates,
                      brushScale: widget.brushScale,
                      brushAngle: widget.brushAngle,
                      paintKey:
                          widget.paintKey ??
                          ValueKey('trace-canvas-ghost-${widget.ghost}'),
                    )
                  else
                    CustomPaint(
                      key:
                          widget.paintKey ??
                          ValueKey('trace-canvas-ghost-${widget.ghost}'),
                      painter: _TraceStrokePainter(
                        strokes: widget.controller._strokes,
                        color: widget.color,
                        revision: widget.controller._revision,
                      ),
                    ),
                  if (widget.controller._nextStrokeHint case final hint?)
                    IgnorePointer(
                      child: CustomPaint(
                        key: const Key('trace-canvas-next-stroke-hint'),
                        painter: _TraceStrokePainter(
                          strokes: [hint],
                          color: widget.color.withValues(alpha: 0.38),
                          revision: widget.controller._revision,
                          referenceCoordinates: true,
                          uniformReference: widget.canonicalCoordinates,
                          strokeWidth: 7,
                        ),
                      ),
                    ),
                  if (widget.controller._errorGhost case final errorGhost?)
                    IgnorePointer(
                      child: CustomPaint(
                        key: const Key('trace-canvas-error-ghost'),
                        painter: _TraceStrokePainter(
                          strokes: [errorGhost],
                          color: widget.errorColor,
                          revision: widget.controller._revision,
                          strokeWidth: 7,
                          referenceCoordinates: widget.canonicalCoordinates,
                          uniformReference: widget.canonicalCoordinates,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return Semantics(
      container: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      child: widget.calligraphy
          ? drawing
          : ClipRRect(
              borderRadius: BorderRadius.circular(SoriRadius.md),
              child: drawing,
            ),
    );
  }
}

final class _TraceStrokePainter extends CustomPainter {
  const _TraceStrokePainter({
    required this.strokes,
    required this.color,
    required this.revision,
    this.referenceCoordinates = false,
    this.strokeWidth,
    this.uniformReference = false,
  });

  final List<List<Offset>> strokes;
  final Color color;
  final int revision;
  final bool referenceCoordinates;
  final double? strokeWidth;
  final bool uniformReference;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(SoriRadius.md),
      ),
    );
    if (referenceCoordinates) {
      if (uniformReference) {
        final side = size.shortestSide;
        canvas.translate((size.width - side) / 2, (size.height - side) / 2);
        canvas.scale(side / 220);
      } else {
        canvas.scale(size.width / 220, size.height / 220);
      }
    }
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth ?? size.height / 220 * 11
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length < 2) {
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TraceStrokePainter oldDelegate) =>
      !identical(strokes, oldDelegate.strokes) ||
      revision != oldDelegate.revision ||
      color != oldDelegate.color ||
      referenceCoordinates != oldDelegate.referenceCoordinates ||
      strokeWidth != oldDelegate.strokeWidth;
}
