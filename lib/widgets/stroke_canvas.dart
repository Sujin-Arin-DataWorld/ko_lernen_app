import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/hangul_strokes.dart';
import '../theme.dart';

/// Animierte Strichreihenfolge eines Hangul-Buchstabens.
///
/// Spielt die Striche nacheinander ab, wie ein "Schreiben"-Effekt.
/// Tipp: Tap aufs Widget → vom Anfang neu starten.
class StrokeCanvas extends StatefulWidget {
  final String letter;
  final List<Stroke> strokes;
  final double size;
  final Color color;
  final Color guideColor;
  final bool showNumbers;
  final Duration perStroke;

  const StrokeCanvas({
    super.key,
    required this.letter,
    required this.strokes,
    this.size = 220,
    this.color = AppColors.hangul,
    this.guideColor = const Color(0x33845EF7),
    this.showNumbers = true,
    this.perStroke = const Duration(milliseconds: 700),
  });

  @override
  State<StrokeCanvas> createState() => _StrokeCanvasState();
}

class _StrokeCanvasState extends State<StrokeCanvas> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _initCtrl();
  }

  void _initCtrl() {
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.perStroke * widget.strokes.length,
    );
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant StrokeCanvas old) {
    super.didUpdateWidget(old);
    if (old.letter != widget.letter || old.strokes.length != widget.strokes.length) {
      _ctrl.dispose();
      _initCtrl();
    }
  }

  void _restart() {
    HapticFeedback.selectionClick();
    _ctrl.reset();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _restart,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _Painter(
              strokes: widget.strokes,
              progress: _ctrl.value,
              color: widget.color,
              guideColor: widget.guideColor,
              showNumbers: widget.showNumbers,
              letter: widget.letter,
              source: strokeCanvas,
            ),
          );
        },
      ),
    );
  }
}

class _Painter extends CustomPainter {
  final List<Stroke> strokes;
  final double progress;       // 0..1 für alle Striche zusammen
  final Color color;
  final Color guideColor;
  final bool showNumbers;
  final String letter;
  final Size source;            // 220×220 reference

  _Painter({
    required this.strokes,
    required this.progress,
    required this.color,
    required this.guideColor,
    required this.showNumbers,
    required this.letter,
    required this.source,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width  / source.width;
    final scaleY = size.height / source.height;
    final scale  = math.min(scaleX, scaleY);

    Offset s(Offset o) => Offset(o.dx * scale, o.dy * scale);

    // Hintergrund-Geist (zeigt Endform schwach)
    final ghostP = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..strokeWidth = 12 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final st in strokes) {
      _drawStroke(canvas, st, ghostP, s, 1.0);
    }

    // Aktuelle Striche
    final n = strokes.length;
    final perStroke = 1.0 / n;
    for (var i = 0; i < n; i++) {
      final localStart = i * perStroke;
      final localEnd   = (i + 1) * perStroke;
      double prog = (progress - localStart) / (localEnd - localStart);
      prog = prog.clamp(0.0, 1.0);
      if (prog == 0) break;

      final paint = Paint()
        ..color = color
        ..strokeWidth = 11 * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      _drawStroke(canvas, strokes[i], paint, s, prog);

      if (showNumbers && prog > 0.05) {
        _drawNumber(canvas, strokes[i], i + 1, s, scale);
      }
    }
  }

  void _drawStroke(Canvas canvas, Stroke st, Paint paint, Offset Function(Offset) s, double prog) {
    if (st is LineStroke) {
      final pts = st.points.map(s).toList();
      final path = _partialPath(pts, prog);
      canvas.drawPath(path, paint);
    } else if (st is CircleStroke) {
      final c = s(st.center);
      final r = st.radius * (paint.strokeWidth / 11);
      final sweep = 2 * math.pi * prog;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, sweep, false, paint);
    }
  }

  Path _partialPath(List<Offset> pts, double prog) {
    // Polyline-Länge berechnen, dann prog × totalLength entlang zeichnen
    final lens = <double>[];
    double total = 0;
    for (var i = 0; i < pts.length - 1; i++) {
      final l = (pts[i + 1] - pts[i]).distance;
      lens.add(l);
      total += l;
    }
    final target = total * prog;

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    double acc = 0;
    for (var i = 0; i < lens.length; i++) {
      final l = lens[i];
      if (acc + l <= target) {
        path.lineTo(pts[i + 1].dx, pts[i + 1].dy);
        acc += l;
      } else {
        final remain = target - acc;
        final ratio  = remain / l;
        final p = Offset.lerp(pts[i], pts[i + 1], ratio)!;
        path.lineTo(p.dx, p.dy);
        break;
      }
    }
    return path;
  }

  void _drawNumber(Canvas canvas, Stroke st, int n, Offset Function(Offset) s, double scale) {
    Offset pos;
    if (st is LineStroke) {
      pos = s(st.points.first);
    } else if (st is CircleStroke) {
      pos = s(Offset(st.center.dx, st.center.dy - st.radius));
    } else {
      return;
    }
    final tp = TextPainter(
      text: TextSpan(
        text: '$n',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11 * scale,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final r = 11 * scale;
    canvas.drawCircle(pos, r, Paint()..color = AppColors.hangul);
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _Painter old) =>
      old.progress != progress || old.letter != letter || old.color != color;
}
