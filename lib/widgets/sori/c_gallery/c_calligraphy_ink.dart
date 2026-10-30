import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

/// Visual-only values from the independent, approved brush motion study.
/// Recognition continues to use TraceCanvasSnapshot's unmodified local points.
abstract final class CCalligraphyMotion {
  static const fingerPressure = .75;
  static const bleed = .28;
  static const bleedMs = 350.0;
  static const dryMs = 650.0;
  static const sampleDistance = .88;
  static const tailLength = 8.0;
  static const stiffness = 310.0;
  static const damping = 29.0;
  static const springStep = 1 / 120;
  static const maxStep = .04;
  static const enterMs = 70.0;
  static const liftMs = 260.0;
  static const releaseFadeStartMs = 95.0;
  static const maxBend = 6.9;
  static const loadCompression = .28;
  static const loadSplay = 1.42;

  static double smooth(double value) {
    final t = value.clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  static double width(double speed, double length, double pressure) =>
      (9.3 *
              (1.08 - speed.clamp(0.0, 1.0) * .32) *
              (.18 + .82 * smooth(length / 9)) *
              (.4 + .8 * pressure.clamp(0.0, 1.0)))
          .clamp(1.25, 13.2);

  static bool isPen(PointerDeviceKind kind) =>
      kind == PointerDeviceKind.stylus ||
      kind == PointerDeviceKind.invertedStylus;

  static double pressure(PointerEvent event) {
    if (!isPen(event.kind) || event.pressureMax <= event.pressureMin) {
      return fingerPressure;
    }
    return ((event.pressure - event.pressureMin) /
            (event.pressureMax - event.pressureMin))
        .clamp(0.0, 1.0);
  }
}

@immutable
final class CInkPoint {
  const CInkPoint(this.position, this.timeStamp, this.pressure);

  factory CInkPoint.fromEvent(PointerEvent event) => CInkPoint(
    event.localPosition,
    event.timeStamp,
    CCalligraphyMotion.pressure(event),
  );

  final Offset position;
  final Duration timeStamp;
  final double pressure;
}

/// Pressure/time is a rendering sidecar; this never owns assessment or storage.
final class CInkStroke {
  CInkStroke(CInkPoint first, {required this.stylus}) : _points = [first];

  final bool stylus;
  final List<CInkPoint> _points;
  late final points = UnmodifiableListView<CInkPoint>(_points);
  bool complete = false;

  void add(CInkPoint point) => _points.add(point);
  void finish() => complete = true;
}

final class CInkStamp {
  CInkStamp({
    required this.position,
    required this.angle,
    required this.width,
    required this.distance,
    required this.bornMs,
  });

  final Offset position;
  final double angle;
  double width;
  final double distance;
  final double bornMs;
  Path? _core;

  double _noise(int channel) {
    final n =
        math.sin(
          (position.dx * 4).round() * 12.9898 +
              (position.dy * 4).round() * 78.233 +
              channel * 41.39,
        ) *
        43758.5453123;
    return n - n.floor();
  }

  void taper(double factor) {
    width *= factor;
    _core = null;
  }

  Path get _corePath => _core ??= () {
    final path = Path();
    for (var j = 0; j < 24; j++) {
      final a = j / 24 * math.pi * 2;
      final hair = 1 + (_noise(j) - .5) * .075;
      final p = Offset(
        math.cos(a) * width / 2 * .62 * hair,
        math.sin(a) * width / 2 * .95 * hair,
      );
      if (j == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }();

  void paint(Canvas canvas, double now, {required bool dry}) {
    final growth = dry
        ? 1.0
        : CCalligraphyMotion.smooth(
            (now - bornMs) / CCalligraphyMotion.bleedMs,
          );
    final drying = dry
        ? 1.0
        : CCalligraphyMotion.smooth((now - bornMs) / CCalligraphyMotion.dryMs);
    final r = width / 2;
    final spread =
        3.8 *
        CCalligraphyMotion.bleed *
        (.18 + .82 * growth) *
        math.min(1.0, math.sqrt(width / 6));
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle);
    final paint = Paint();
    for (final layer in const [(1.0, .024), (.67, .032), (.34, .045)]) {
      paint.color = const Color(0xff29382b).withValues(
        alpha: layer.$2 * CCalligraphyMotion.bleed * (.6 + .4 * growth),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: (r * .62 + spread * layer.$1) * 2,
          height: (r * .91 + spread * layer.$1 * (.88 + _noise(2) * .12)) * 2,
        ),
        paint,
      );
    }
    paint.style = PaintingStyle.stroke;
    for (var i = 0; i < 8; i++) {
      final a = i / 8 * math.pi * 2 + _noise(i + 4);
      final start = Offset(math.cos(a) * r * .61, math.sin(a) * r * .89);
      paint
        ..strokeWidth = .13 + _noise(i + 13) * .15
        ..color = const Color(0xff29382b).withValues(
          alpha: (.055 + _noise(i + 21) * .055) * CCalligraphyMotion.bleed,
        );
      canvas.drawLine(
        start,
        start + Offset(math.cos(a), math.sin(a)) * spread,
        paint,
      );
    }
    paint
      ..style = PaintingStyle.fill
      ..color = Color.fromRGBO(
        (20 + 15 * drying).round(),
        (27 + 13 * drying).round(),
        (23 + 10 * drying).round(),
        .86,
      );
    canvas.drawPath(_corePath, paint);
    if (drying < 1) {
      paint.color = const Color(
        0xffede3ce,
      ).withValues(alpha: .018 * (1 - drying));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -r * .22),
          width: r * .92,
          height: .24,
        ),
        paint,
      );
    }
    canvas.restore();
  }
}

/// Incremental ink geometry in the same 220-unit coordinates as the motion
/// study. Resampling only draws ink, and is never published back to input.
final class CInkShape {
  CInkShape(this.stroke, this.sourceSize);

  final CInkStroke stroke;
  final Size sourceSize;
  final List<CInkStamp> stamps = [];
  int _processed = 0;
  bool _holdAdded = false;
  double _lastInputMs = 0;
  bool _finished = false;
  double length = 0;
  double speed = 0;
  double direction = 0;
  Picture? _dryPicture;

  Offset _reference(Offset point) => Offset(
    point.dx * (220 / sourceSize.width),
    point.dy * (220 / sourceSize.height),
  );

  Offset get contact => _reference(stroke.points.last.position);
  double get pressure => stroke.points.last.pressure;
  int get sampledPointCount => _processed;
  double get lastBornMs => stamps.isEmpty ? 0 : stamps.last.bornMs;

  void sync(double now) {
    final points = stroke.points;
    if (_processed != points.length) {
      _lastInputMs = now;
      _holdAdded = false;
    }
    if (_processed == 0) {
      stamps.add(
        CInkStamp(
          position: _reference(points.first.position),
          angle: 0,
          width: CCalligraphyMotion.width(0, 0, points.first.pressure),
          distance: 0,
          bornMs: now,
        ),
      );
      _processed = 1;
    }
    for (; _processed < points.length; _processed++) {
      final previous = points[_processed - 1];
      final next = points[_processed];
      final start = _reference(previous.position);
      final end = _reference(next.position);
      final distance = (end - start).distance;
      final ms = (next.timeStamp - previous.timeStamp).inMicroseconds / 1000;
      speed = distance / math.max(2.0, ms);
      if (distance == 0) {
        continue;
      }
      direction = math.atan2(end.dy - start.dy, end.dx - start.dx);
      final count = (distance / CCalligraphyMotion.sampleDistance).ceil();
      for (var step = 1; step <= count; step++) {
        final t = step / count;
        final pressure =
            previous.pressure + (next.pressure - previous.pressure) * t;
        stamps.add(
          CInkStamp(
            position: Offset.lerp(start, end, t)!,
            angle: direction,
            width: CCalligraphyMotion.width(
              speed,
              length + distance * t,
              pressure,
            ),
            distance: length + distance * t,
            bornMs: now,
          ),
        );
      }
      length += distance;
    }
    if (stroke.complete && !_finished) {
      _finished = true;
      final closed =
          length > 20 &&
          (stamps.first.position - stamps.last.position).distance < 1;
      // Pen pressure already supplies its own tail. A closed circle stays closed.
      if (!stroke.stylus && !closed && length > 2) {
        final tail = math.min(CCalligraphyMotion.tailLength, length * .3);
        for (final stamp in stamps.reversed) {
          final remaining = length - stamp.distance;
          if (remaining >= tail) {
            break;
          }
          stamp.taper(.12 + .88 * CCalligraphyMotion.smooth(remaining / tail));
        }
      }
    }
  }

  bool wet(double now) => now - lastBornMs < CCalligraphyMotion.dryMs;

  void hold(double now) {
    if (!stroke.complete && !_holdAdded && now - _lastInputMs > 150) {
      // One resting contact mark, visual only. No sample is appended to input.
      final width = stamps.last.width;
      stamps.add(
        CInkStamp(
          position: contact,
          angle: direction,
          width: math.min(13.2, width * 1.08),
          distance: length,
          bornMs: now,
        ),
      );
      _holdAdded = true;
    }
  }

  void paint(Canvas canvas, double now, {required bool staticInk}) {
    if (stroke.complete && (staticInk || !wet(now))) {
      if (_dryPicture == null) {
        final recorder = PictureRecorder();
        final cache = Canvas(recorder);
        for (final stamp in stamps) {
          stamp.paint(cache, now, dry: true);
        }
        _dryPicture = recorder.endRecording();
      }
      canvas.drawPicture(_dryPicture!);
    } else {
      for (final stamp in stamps) {
        stamp.paint(canvas, now, dry: staticInk);
      }
    }
  }

  void dispose() {
    _dryPicture?.dispose();
    _dryPicture = null;
  }
}

/// Flexible texture mesh with a rigid handle. Only the fibers spring; the
/// contact is always the input position, including turns and closed strokes.
final class CCalligraphyBrush {
  CCalligraphyBrush(
    this.contact,
    double now,
    double pressure, {
    this.restAngle = .42,
    this.leftLeanBoundary = double.infinity,
    this.animateRegrip = true,
  }) : enterMs = now,
       _lastMs = now,
       _lastMoveMs = now,
       angle = contact.dx > leftLeanBoundary ? -.72 : restAngle,
       _targetAngle = contact.dx > leftLeanBoundary ? -.72 : restAngle,
       _leanLeft = contact.dx > leftLeanBoundary,
       _targetLoad = (.1 + .85 * pressure).clamp(.1, .98);

  Offset contact;
  final double enterMs;
  final double restAngle;
  final double leftLeanBoundary;
  final bool animateRegrip;
  bool _leanLeft;
  double? _regripMs;
  double angle;
  double load = .04;
  Offset bend = Offset.zero;
  double _loadVelocity = 0;
  Offset _bendVelocity = Offset.zero;
  double _targetAngle;
  double _targetLoad;
  Offset _targetBend = Offset.zero;
  double _lastMs;
  double _lastMoveMs;
  double? liftedMs;

  void move(
    Offset point,
    double now,
    double speed,
    double direction,
    double pressure,
  ) {
    contact = point;
    final movement = math.cos(direction) * .08 + math.sin(direction) * .045;
    final leanLeft = _leanLeft
        ? contact.dx >= leftLeanBoundary - 18
        : contact.dx > leftLeanBoundary;
    final changedLean = leanLeft != _leanLeft;
    _leanLeft = leanLeft;
    // Regrip inward at the screen edge. Do not sweep a long handle through
    // the header by interpolating across a vertical pose. Input is untouched.
    _targetAngle = restAngle == .42
        ? restAngle + movement.clamp(-.1, .1)
        : (_leanLeft
                  ? -.72 + .06 * ((contact.dy - 40) / 140).clamp(0.0, 1.0)
                  : restAngle -
                        .08 * ((contact.dy - 40) / 140).clamp(0.0, 1.0)) +
              movement.clamp(-.02, .02);
    if (changedLean) {
      angle = _targetAngle;
      _regripMs = animateRegrip ? now : null;
    }
    final magnitude = math.min(
      CCalligraphyMotion.maxBend,
      (2 + speed * 10) * (.65 + .35 * pressure),
    );
    _targetBend = Offset(math.cos(direction), math.sin(direction)) * magnitude;
    _targetLoad = (.1 + .85 * pressure - math.min(speed, 1.0) * .15).clamp(
      .12,
      .98,
    );
    _lastMoveMs = now;
  }

  void lift(double now) => liftedMs ??= now;

  (double, double) _spring(
    double value,
    double velocity,
    double target,
    double seconds,
  ) {
    var remaining = seconds;
    while (remaining > 0) {
      final dt = math.min(remaining, CCalligraphyMotion.springStep);
      velocity +=
          (CCalligraphyMotion.stiffness * (target - value) -
              CCalligraphyMotion.damping * velocity) *
          dt;
      value += velocity * dt;
      remaining -= dt;
    }
    return (value, velocity);
  }

  void update(double now) {
    final seconds = ((now - _lastMs) / 1000).clamp(
      0.0,
      CCalligraphyMotion.maxStep,
    );
    _lastMs = now;
    final resting = liftedMs == null && now - _lastMoveMs > 110;
    final target = liftedMs == null
        ? (_targetLoad + (resting ? .06 : 0)).clamp(0.0, .98)
        : 0.0;
    final drag = liftedMs != null ? 0.0 : (resting ? .64 : 1.0);
    final springLoad = _spring(load, _loadVelocity, target, seconds);
    load = springLoad.$1;
    _loadVelocity = springLoad.$2;
    final x = _spring(
      bend.dx,
      _bendVelocity.dx,
      _targetBend.dx * drag,
      seconds,
    );
    final y = _spring(
      bend.dy,
      _bendVelocity.dy,
      _targetBend.dy * drag,
      seconds,
    );
    bend = Offset(x.$1, y.$1);
    _bendVelocity = Offset(x.$2, y.$2);
    angle += (_targetAngle - angle) * (1 - math.exp(-seconds * 1000 / 85));
    load = load.clamp(0.0, 1.0);
  }

  double liftAmount(double now) => liftedMs == null
      ? 0
      : CCalligraphyMotion.smooth(
          (now - liftedMs!) / CCalligraphyMotion.liftMs,
        );

  double opacity(double now) {
    final age = liftedMs == null ? 0.0 : now - liftedMs!;
    return (animateRegrip
            ? CCalligraphyMotion.smooth(
                (now - enterMs) / CCalligraphyMotion.enterMs,
              )
            : 1) *
        (_regripMs == null
            ? 1
            : CCalligraphyMotion.smooth((now - _regripMs!) / 100)) *
        (1 -
            CCalligraphyMotion.smooth(
              (age - CCalligraphyMotion.releaseFadeStartMs) /
                  (CCalligraphyMotion.liftMs -
                      CCalligraphyMotion.releaseFadeStartMs),
            ));
  }

  bool moving(double now) {
    if (liftedMs != null) {
      return now - liftedMs! < CCalligraphyMotion.liftMs;
    }
    if (now - _lastMoveMs < 150) {
      return true;
    }
    return _loadVelocity.abs() > .03 ||
        _bendVelocity.distance > .03 ||
        (load - (_targetLoad + .06).clamp(0.0, .98)).abs() > .001 ||
        (bend - _targetBend * .64).distance > .001 ||
        (angle - _targetAngle).abs() > .001;
  }

  Offset get localBend => Offset(
    math.cos(angle) * bend.dx + math.sin(angle) * bend.dy,
    -math.sin(angle) * bend.dx + math.cos(angle) * bend.dy,
  );

  Offset get root {
    final drag = localBend;
    const restHair = (1495 - 1144) * 87 / (1495 - 18);
    return Offset(
      drag.dx,
      -restHair * (1 - CCalligraphyMotion.loadCompression * load) +
          drag.dy * .17,
    );
  }

  (Offset, Offset) curve(double t) {
    final start = root;
    final drag = localBend;
    final c1 = start + Offset(0, -start.dy * .41);
    final c2 = Offset(
      drag.dx * (.2 + .5 * load),
      -3.3 * (1 - load) + drag.dy * .32 * load,
    );
    final u = 1 - t;
    return (
      start * (u * u * u) + c1 * (3 * u * u * t) + c2 * (3 * u * t * t),
      (c1 - start) * (3 * u * u) + (c2 - c1) * (6 * u * t) - c2 * (3 * t * t),
    );
  }
}
