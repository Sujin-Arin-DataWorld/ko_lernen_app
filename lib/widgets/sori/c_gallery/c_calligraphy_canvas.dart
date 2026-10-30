import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../tokens.dart';
import 'c_calligraphy_ink.dart';

abstract final class CCalligraphyAssets {
  static const brush = 'assets/illustrations/concept_c/calligraphy_brush.png';
  static Future<ui.Image>? _brush;
  static ui.Image? readyBrush;

  /// One application-owned decode; the original PNG is not edited or resaved.
  static Future<ui.Image> loadBrush() => _brush ??= () async {
    final bytes = await rootBundle.load(brush);
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    try {
      return readyBrush = (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }();
}

/// Native ink and image mesh, independent of assessment. The listener remains
/// in TraceCanvas; this visual layer never intercepts or adjusts pointer input.
class CCalligraphyCanvas extends StatefulWidget {
  const CCalligraphyCanvas({
    super.key,
    required this.strokes,
    required this.revision,
    this.paintKey,
    this.canonicalCoordinates = false,
    this.parkedBrush,
    this.brushOverflow = false,
    this.brushScale = 1,
    this.brushAngle = .42,
  }) : assert(brushScale > 0);

  final List<CInkStroke> strokes;
  final int revision;
  final Key? paintKey;
  final bool canonicalCoordinates;
  final Offset? parkedBrush;
  final bool brushOverflow;

  /// Scales only the decorative brush around its contact point. Ink and input
  /// remain in the canonical assessment coordinates.
  final double brushScale;
  final double brushAngle;

  @override
  State<CCalligraphyCanvas> createState() => _CCalligraphyCanvasState();
}

class _CCalligraphyCanvasState extends State<CCalligraphyCanvas>
    with SingleTickerProviderStateMixin {
  final _frames = ValueNotifier(0.0);
  final _shapes = <CInkShape>[];
  late final Ticker _ticker = createTicker(_tick);
  ui.Image? _image;
  CCalligraphyBrush? _brush;
  CInkStroke? _brushStroke;
  Size _size = Size.zero;
  double _now = 0;
  double _clockBase = 0;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _image = CCalligraphyAssets.readyBrush;
    unawaited(
      CCalligraphyAssets.loadBrush()
          .then((image) {
            if (mounted) {
              setState(() => _image = image);
            }
          })
          .catchError((Object error, StackTrace stack) {
            FlutterError.reportError(
              FlutterErrorDetails(
                exception: error,
                stack: stack,
                library: 'C calligraphy brush',
              ),
            );
          }),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = SoriMotion.reduceMotion(context);
    if (_reduced) {
      _ticker.stop();
    }
  }

  void _tick(Duration elapsed) {
    _now = _clockBase + elapsed.inMicroseconds / 1000;
    for (final shape in _shapes) {
      shape.hold(_now);
    }
    _brush?.update(_now);
    _frames.value = _now;
    if (!_needsFrames) {
      _ticker.stop();
    }
  }

  bool get _needsFrames =>
      !_reduced &&
      (_shapes.any((shape) => shape.wet(_now)) ||
          (_brush?.moving(_now) ?? false));

  void _sync(Size size) {
    if (size.isEmpty) {
      return;
    }
    if (_size != size) {
      for (final shape in _shapes) {
        shape.dispose();
      }
      _shapes.clear();
      _brush = null;
      _brushStroke = null;
      _size = size;
    }
    final remaining = widget.strokes.toSet();
    // The 288dp writing desk has less outer room on compact phones. Regrip
    // earlier there, retaining the same full-size tool and canonical input.
    final leanBoundary = widget.brushScale > 1
        ? (112 + (MediaQuery.sizeOf(context).width - 320) * .6).clamp(
            105.0,
            160.0,
          )
        : double.infinity;
    _shapes.removeWhere((shape) {
      if (remaining.contains(shape.stroke)) {
        return false;
      }
      shape.dispose();
      return true;
    });
    if (_brushStroke != null && !remaining.contains(_brushStroke)) {
      _brush = null;
      _brushStroke = null;
    }
    for (final stroke in widget.strokes) {
      var shape = _shapes.where((s) => identical(s.stroke, stroke)).firstOrNull;
      shape ??= () {
        final added = CInkShape(
          stroke,
          widget.canonicalCoordinates ? const Size.square(220) : size,
        );
        _shapes.add(added);
        return added;
      }();
      final changed = shape.sampledPointCount != stroke.points.length;
      shape.sync(_now);
      // Only an actual live pointer creates a moving brush. Historical ink
      // survives rebuilds without pretending it is a newly drawn gesture.
      if (!stroke.complete) {
        if (!identical(_brushStroke, stroke)) {
          _brushStroke = stroke;
          _brush = CCalligraphyBrush(
            shape.contact,
            _now,
            shape.pressure,
            restAngle: widget.brushAngle,
            leftLeanBoundary: leanBoundary,
            animateRegrip: !_reduced,
          );
        }
        if (changed) {
          _brush!.move(
            shape.contact,
            _now,
            shape.speed,
            shape.direction,
            shape.pressure,
          );
        }
      } else if (identical(_brushStroke, stroke)) {
        _brush?.lift(_now);
      }
    }
    if (widget.parkedBrush != null &&
        (_brush == null || _brushStroke?.complete == true)) {
      _brush = CCalligraphyBrush(
        widget.parkedBrush!,
        _now,
        .38,
        restAngle: widget.brushAngle,
        leftLeanBoundary: leanBoundary,
        animateRegrip: !_reduced,
      );
      _brushStroke = null;
    }
    if (_needsFrames && !_ticker.isActive) {
      _clockBase = _now;
      _ticker.start();
    } else if (!_needsFrames && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: LayoutBuilder(
      builder: (context, constraints) {
        _sync(constraints.biggest);
        return Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: CustomPaint(
                key: widget.paintKey,
                painter: _CInkPainter(
                  _shapes,
                  _frames,
                  widget.revision,
                  _reduced,
                  widget.canonicalCoordinates,
                ),
              ),
            ),
            if (_brush != null && _image != null)
              RepaintBoundary(
                child: CustomPaint(
                  key: const Key('c-calligraphy-moving-brush'),
                  painter: _CBrushPainter(
                    _brush!,
                    _image!,
                    _frames,
                    widget.revision,
                    widget.canonicalCoordinates,
                    widget.brushOverflow,
                    widget.brushScale,
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );

  @override
  void dispose() {
    _ticker.dispose();
    _frames.dispose();
    for (final shape in _shapes) {
      shape.dispose();
    }
    super.dispose();
  }
}

final class _CInkPainter extends CustomPainter {
  _CInkPainter(
    this.shapes,
    this.frames,
    this.revision,
    this.reduced,
    this.uniform,
  ) : super(repaint: frames);

  final List<CInkShape> shapes;
  final ValueNotifier<double> frames;
  final int revision;
  final bool reduced;
  final bool uniform;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Ink stays on the paper; the visual brush never changes the hit area.
    canvas.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
    );
    if (uniform) {
      final side = size.shortestSide;
      canvas.translate((size.width - side) / 2, (size.height - side) / 2);
      canvas.scale(side / 220);
    } else {
      canvas.scale(size.width / 220, size.height / 220);
    }
    for (final shape in shapes) {
      shape.paint(canvas, frames.value, staticInk: reduced);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CInkPainter oldDelegate) =>
      revision != oldDelegate.revision || reduced != oldDelegate.reduced;
}

final class _CBrushPainter extends CustomPainter {
  _CBrushPainter(
    this.brush,
    this.image,
    this.frames,
    this.revision,
    this.uniform,
    this.overflow,
    this.visualScale,
  ) : super(repaint: frames);

  final CCalligraphyBrush brush;
  final ui.Image image;
  final ValueNotifier<double> frames;
  final int revision;
  final bool uniform, overflow;
  final double visualScale;
  static final _identity = Float64List.fromList([
    1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
  ]);

  @override
  void paint(Canvas canvas, Size size) {
    final now = frames.value;
    final opacity = brush.opacity(now);
    if (opacity < .005) {
      return;
    }
    const sourceX = 448.0;
    const sourceWidth = 128.0;
    const neck = 1144.0;
    const hairLength = 1495.0 - neck;
    const scale = 87 / (1495 - 18);
    const width = sourceWidth * scale;
    final lift = brush.liftAmount(now);
    final root = brush.root;
    canvas.save();
    if (uniform) {
      final side = size.shortestSide;
      canvas.translate((size.width - side) / 2, (size.height - side) / 2);
      canvas.scale(side / 220);
    } else {
      canvas.scale(size.width / 220, size.height / 220);
    }
    const paper = Rect.fromLTWH(0, 0, 220, 220);
    // Fade the decorative handle at the paper edge so it cannot cover controls.
    // Neither the raw path nor the contact point is relocated to make it fit.
    if (!overflow) {
      canvas.clipRect(paper);
      canvas.saveLayer(paper, Paint());
    }
    canvas.save();
    canvas.translate(brush.contact.dx, brush.contact.dy - lift * 4.1);
    canvas.rotate(brush.angle + lift * .025);
    canvas.scale(visualScale);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..filterQuality = FilterQuality.medium;
    canvas.drawImageRect(
      image,
      const Rect.fromLTWH(sourceX, 18, sourceWidth, neck - 18),
      Rect.fromLTWH(
        root.dx - width / 2,
        root.dy - (neck - 18) * scale,
        width,
        (neck - 18) * scale,
      ),
      paint,
    );
    final positions = <Offset>[];
    final texture = <Offset>[];
    final indices = <int>[];
    const rows = 22;
    for (var i = 0; i <= rows; i++) {
      final t = i / rows;
      final (point, derivative) = brush.curve(t);
      final length = derivative.distance;
      final normal = length == 0
          ? const Offset(1, 0)
          : Offset(derivative.dy / length, -derivative.dx / length);
      final splay =
          1 +
          brush.load *
              CCalligraphyMotion.loadSplay *
              CCalligraphyMotion.smooth((t - .1) / .58);
      positions.addAll([
        point - normal * width * splay / 2,
        point + normal * width * splay / 2,
      ]);
      texture.addAll([
        Offset(sourceX, neck + hairLength * t),
        Offset(sourceX + sourceWidth, neck + hairLength * t),
      ]);
      if (i < rows) {
        final j = i * 2;
        indices.addAll([j, j + 1, j + 2, j + 1, j + 3, j + 2]);
      }
    }
    final vertices = ui.Vertices(
      ui.VertexMode.triangles,
      positions,
      textureCoordinates: texture,
      indices: indices,
    );
    paint.shader = ui.ImageShader(
      image,
      TileMode.clamp,
      TileMode.clamp,
      _identity,
      filterQuality: FilterQuality.medium,
    );
    canvas.drawVertices(vertices, BlendMode.modulate, paint);
    vertices.dispose();
    canvas.restore();
    if (!overflow) {
      canvas.drawRect(
        paper,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = ui.Gradient.linear(
            Offset.zero,
            const Offset(0, 220),
            const [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            const [0, .055, .96, 1],
          ),
      );
      canvas.drawRect(
        paper,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = ui.Gradient.linear(
            Offset.zero,
            const Offset(220, 0),
            const [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            const [0, .04, .96, 1],
          ),
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CBrushPainter oldDelegate) =>
      revision != oldDelegate.revision ||
      !identical(brush, oldDelegate.brush) ||
      visualScale != oldDelegate.visualScale ||
      image != oldDelegate.image;
}
