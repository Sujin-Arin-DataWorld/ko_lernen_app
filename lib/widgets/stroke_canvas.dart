import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../data/hangul_strokes.dart';
import 'sori/tokens.dart';

/// Animierte Strichreihenfolge eines Hangul-Buchstabens.
///
/// Spielt die Striche nacheinander ab, wie ein "Schreiben"-Effekt.
/// Tipp: Tap aufs Widget → vom Anfang neu starten.
class StrokeCanvas extends StatefulWidget {
  final String letter;
  final List<Stroke> strokes;
  final double size;
  final Color color;
  final bool showNumbers;
  final Duration perStroke;
  final VoidCallback? onCompleted;
  final String? semanticsLabel;
  final String? semanticsHint;

  /// 지금 그려야 할 획을 강조한다. null 이면 강조 없음(기존 동작).
  ///
  /// 애니메이션 재생과 무관하게 **항상 완성된 상태**로 덧그린다 — 학습자가
  /// "다음은 이 획" 을 한눈에 보게 하는 것이 목적이다.
  final int? highlightIndex;

  const StrokeCanvas({
    super.key,
    required this.letter,
    required this.strokes,
    this.size = 220,
    this.color = SoriColors.primary,
    this.showNumbers = true,
    this.perStroke = const Duration(milliseconds: 700),
    this.onCompleted,
    this.semanticsLabel,
    this.semanticsHint,
    this.highlightIndex,
  });

  @override
  State<StrokeCanvas> createState() => _StrokeCanvasState();
}

class _StrokeCanvasState extends State<StrokeCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _reduceMotion = false;
  bool _motionInitialized = false;
  bool _completionNotificationScheduled = false;

  @override
  void initState() {
    super.initState();
    _initCtrl();
  }

  void _initCtrl() {
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.perStroke * widget.strokes.length,
    )..addStatusListener(_handleStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = SoriMotion.reduceMotion(context);
    if (_motionInitialized && reduceMotion == _reduceMotion) {
      return;
    }
    _reduceMotion = reduceMotion;
    _motionInitialized = true;
    if (_reduceMotion) {
      _ctrl.value = 1;
    } else {
      _ctrl.forward(from: 0);
    }
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _notifyCompleted();
    }
  }

  void _notifyCompleted() {
    if (widget.onCompleted == null) {
      return;
    }
    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      widget.onCompleted?.call();
      return;
    }
    // Reduced motion can complete the controller from didChangeDependencies.
    // Notify after this build frame so a parent may safely unlock its action.
    if (_completionNotificationScheduled) {
      return;
    }
    _completionNotificationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _completionNotificationScheduled = false;
      if (mounted) {
        widget.onCompleted?.call();
      }
    });
  }

  void _completeWithoutMotion({bool notifyIfAlreadyComplete = false}) {
    final wasComplete = _ctrl.value == 1;
    _ctrl.value = 1;
    if (wasComplete && notifyIfAlreadyComplete) {
      _notifyCompleted();
    }
  }

  @override
  void didUpdateWidget(covariant StrokeCanvas old) {
    super.didUpdateWidget(old);
    if (old.letter != widget.letter ||
        old.strokes.length != widget.strokes.length) {
      // Controller wiederverwenden (nur Dauer anpassen), statt einen neuen zu
      // erzeugen — SingleTickerProviderStateMixin erlaubt nur einen Ticker.
      _ctrl.duration = widget.perStroke * widget.strokes.length;
      if (_reduceMotion) {
        _completeWithoutMotion(notifyIfAlreadyComplete: true);
      } else {
        _ctrl
          ..reset()
          ..forward();
      }
    }
  }

  void _restart() {
    HapticFeedback.selectionClick();
    if (_reduceMotion) {
      _completeWithoutMotion(notifyIfAlreadyComplete: true);
    } else {
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticsLabel ?? widget.letter,
      hint: widget.semanticsHint,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
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
                showNumbers: widget.showNumbers,
                letter: widget.letter,
                source: strokeCanvas,
                highlightIndex: widget.highlightIndex,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  final List<Stroke> strokes;
  final double progress; // 0..1 für alle Striche zusammen
  final Color color;
  final bool showNumbers;
  final String letter;
  final Size source; // 220×220 reference
  final int? highlightIndex;

  _Painter({
    required this.strokes,
    required this.progress,
    required this.color,
    required this.showNumbers,
    required this.letter,
    required this.source,
    this.highlightIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / source.width;
    final scaleY = size.height / source.height;
    final scale = math.min(scaleX, scaleY);

    Offset s(Offset o) => Offset(o.dx * scale, o.dy * scale);

    // Hintergrund-Geist (zeigt Endform schwach)
    final ghostP = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..strokeWidth = 12 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final st in strokes) {
      _drawStroke(canvas, st, ghostP, s, 1.0, scale);
    }

    // Aktuelle Striche
    final n = strokes.length;
    final perStroke = 1.0 / n;
    for (var i = 0; i < n; i++) {
      final localStart = i * perStroke;
      final localEnd = (i + 1) * perStroke;
      double prog = (progress - localStart) / (localEnd - localStart);
      prog = prog.clamp(0.0, 1.0);
      if (prog == 0) break;

      final paint = Paint()
        ..color = color
        ..strokeWidth = 11 * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      _drawStroke(canvas, strokes[i], paint, s, prog, scale);

      if (showNumbers && prog > 0.05) {
        _drawNumber(canvas, strokes[i], i + 1, s, scale);
      }
    }

    // 지금 그려야 할 획을 애니메이션 위에 덧그린다.
    final hi = highlightIndex;
    if (hi != null && hi >= 0 && hi < n) {
      // 지금 그릴 획은 **색**으로 구분한다. 예전에는 같은 색에 2px 만 굵어서
      // 구분이 안 됐고, 고스트(12)+본선(11)+하이라이트(13) 삼중 페인트가
      // 오히려 획을 뭉툭해 보이게 만들었다 (Jin: "시범이랑 내가 그리는
      // 글자체가 너무 달라서 이상해보여").
      final halo = Paint()
        ..color = SoriColors.accent.withValues(alpha: 0.22)
        ..strokeWidth = 20 * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      _drawStroke(canvas, strokes[hi], halo, s, 1.0, scale);
      final highlight = Paint()
        ..color = SoriColors.accent
        ..strokeWidth = 11 * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      _drawStroke(canvas, strokes[hi], highlight, s, 1.0, scale);
      if (showNumbers) {
        _drawNumber(canvas, strokes[hi], hi + 1, s, scale);
      }
    }
  }

  void _drawStroke(
    Canvas canvas,
    Stroke st,
    Paint paint,
    Offset Function(Offset) s,
    double prog,
    double scale,
  ) {
    if (st is LineStroke) {
      final pts = st.points.map(s).toList();
      final path = _partialPath(pts, prog);
      canvas.drawPath(path, paint);
    } else if (st is CircleStroke) {
      final c = s(st.center);
      // 반지름은 캔버스 배율만 따른다. 예전에는 `paint.strokeWidth / 11` 로
      // 배율을 역산했는데, 고스트(12·scale)와 하이라이트(13·scale) 는 그 식이
      // 각각 9%·18% 큰 값을 내서 ㅇ·ㅎ 에 동심원 세 개가 겹쳐 보였다.
      final r = st.radius * scale;
      final sweep = 2 * math.pi * prog;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        sweep,
        false,
        paint,
      );
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
        final ratio = remain / l;
        final p = Offset.lerp(pts[i], pts[i + 1], ratio)!;
        path.lineTo(p.dx, p.dy);
        break;
      }
    }
    return path;
  }

  void _drawNumber(
    Canvas canvas,
    Stroke st,
    int n,
    Offset Function(Offset) s,
    double scale,
  ) {
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
          fontSize: 13 * scale,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final r = 13 * scale;
    canvas.drawCircle(pos, r, Paint()..color = color);
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _Painter old) =>
      old.progress != progress ||
      old.letter != letter ||
      old.color != color ||
      old.highlightIndex != highlightIndex;
}
