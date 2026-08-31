import 'dart:ui' as ui;

import 'package:flutter/material.dart';

enum SarangchaeBuildPhase {
  setout,
  foundation,
  posts,
  beams,
  rafters,
  roof,
  walls,
  finished,
}

@immutable
final class SarangchaeSegment {
  const SarangchaeSegment(this.start, this.end);

  final Offset start;
  final Offset end;
}

/// One normalized coordinate model for every Sarangchae pilot phase.
///
/// The six-bay main body and the attached numaru wing are generated once.
/// Painters may reveal more members, but they never calculate new positions.
@immutable
final class SarangchaeGeometry {
  const SarangchaeGeometry._({
    required this.mainFrontFeet,
    required this.mainRearFeet,
    required this.mainFrontHeads,
    required this.mainRearHeads,
    required this.wingFrontFeet,
    required this.wingRearFeet,
    required this.wingFrontHeads,
    required this.wingRearHeads,
    required this.posts,
    required this.beams,
    required this.rafters,
    required this.ridges,
    required this.eaves,
    required this.foundationPolygons,
    required this.roofPolygons,
    required this.wallPolygons,
    required this.groundContact,
  });

  factory SarangchaeGeometry.standard() {
    const mainFrontLeft = Offset(.13, .78);
    const mainFrontRight = Offset(.72, .78);
    const mainRearLeft = Offset(.19, .66);
    const mainRearRight = Offset(.75, .66);
    const mainRise = Offset(0, -.28);
    const wingFrontLeft = Offset(.70, .84);
    const wingFrontRight = Offset(.91, .80);
    const wingRearLeft = Offset(.74, .69);
    const wingRearRight = Offset(.91, .66);
    const wingRise = Offset(0, -.24);

    List<Offset> line(Offset a, Offset b, int bays) => [
      for (var i = 0; i <= bays; i++) Offset.lerp(a, b, i / bays)!,
    ];

    final mainFrontFeet = line(mainFrontLeft, mainFrontRight, 6);
    final mainRearFeet = line(mainRearLeft, mainRearRight, 6);
    final mainFrontHeads = [for (final p in mainFrontFeet) p + mainRise];
    final mainRearHeads = [for (final p in mainRearFeet) p + mainRise];
    final wingFrontFeet = line(wingFrontLeft, wingFrontRight, 2);
    final wingRearFeet = line(wingRearLeft, wingRearRight, 2);
    final wingFrontHeads = [for (final p in wingFrontFeet) p + wingRise];
    final wingRearHeads = [for (final p in wingRearFeet) p + wingRise];

    final posts = <SarangchaeSegment>[
      for (var i = 0; i < mainFrontFeet.length; i++) ...[
        SarangchaeSegment(mainFrontFeet[i], mainFrontHeads[i]),
        SarangchaeSegment(mainRearFeet[i], mainRearHeads[i]),
      ],
      for (var i = 0; i < wingFrontFeet.length; i++) ...[
        SarangchaeSegment(wingFrontFeet[i], wingFrontHeads[i]),
        SarangchaeSegment(wingRearFeet[i], wingRearHeads[i]),
      ],
    ];

    List<SarangchaeSegment> rail(List<Offset> points) => [
      for (var i = 0; i < points.length - 1; i++)
        SarangchaeSegment(points[i], points[i + 1]),
    ];

    final beams = <SarangchaeSegment>[
      ...rail(mainFrontHeads),
      ...rail(mainRearHeads),
      for (var i = 0; i < mainFrontHeads.length; i++)
        SarangchaeSegment(mainRearHeads[i], mainFrontHeads[i]),
      ...rail(wingFrontHeads),
      ...rail(wingRearHeads),
      for (var i = 0; i < wingFrontHeads.length; i++)
        SarangchaeSegment(wingRearHeads[i], wingFrontHeads[i]),
    ];

    const mainRidgeStart = Offset(.15, .31);
    const mainRidgeEnd = Offset(.74, .31);
    const wingRidgeStart = Offset(.72, .39);
    const wingRidgeEnd = Offset(.93, .35);
    final ridges = <SarangchaeSegment>[
      const SarangchaeSegment(mainRidgeStart, mainRidgeEnd),
      const SarangchaeSegment(wingRidgeStart, wingRidgeEnd),
    ];
    final eaves = <SarangchaeSegment>[
      SarangchaeSegment(mainFrontHeads.first, mainFrontHeads.last),
      SarangchaeSegment(mainRearHeads.first, mainRearHeads.last),
      SarangchaeSegment(wingFrontHeads.first, wingFrontHeads.last),
      SarangchaeSegment(wingRearHeads.first, wingRearHeads.last),
    ];

    final rafters = <SarangchaeSegment>[];
    for (var i = 0; i <= 24; i++) {
      final t = i / 24;
      final ridge = Offset.lerp(mainRidgeStart, mainRidgeEnd, t)!;
      rafters
        ..add(
          SarangchaeSegment(
            ridge,
            Offset.lerp(mainFrontHeads.first, mainFrontHeads.last, t)!,
          ),
        )
        ..add(
          SarangchaeSegment(
            ridge,
            Offset.lerp(mainRearHeads.first, mainRearHeads.last, t)!,
          ),
        );
    }
    for (var i = 0; i <= 10; i++) {
      final t = i / 10;
      final ridge = Offset.lerp(wingRidgeStart, wingRidgeEnd, t)!;
      rafters
        ..add(
          SarangchaeSegment(
            ridge,
            Offset.lerp(wingFrontHeads.first, wingFrontHeads.last, t)!,
          ),
        )
        ..add(
          SarangchaeSegment(
            ridge,
            Offset.lerp(wingRearHeads.first, wingRearHeads.last, t)!,
          ),
        );
    }

    return SarangchaeGeometry._(
      mainFrontFeet: List.unmodifiable(mainFrontFeet),
      mainRearFeet: List.unmodifiable(mainRearFeet),
      mainFrontHeads: List.unmodifiable(mainFrontHeads),
      mainRearHeads: List.unmodifiable(mainRearHeads),
      wingFrontFeet: List.unmodifiable(wingFrontFeet),
      wingRearFeet: List.unmodifiable(wingRearFeet),
      wingFrontHeads: List.unmodifiable(wingFrontHeads),
      wingRearHeads: List.unmodifiable(wingRearHeads),
      posts: List.unmodifiable(posts),
      beams: List.unmodifiable(beams),
      rafters: List.unmodifiable(rafters),
      ridges: List.unmodifiable(ridges),
      eaves: List.unmodifiable(eaves),
      foundationPolygons: const [
        [
          Offset(.09, .79),
          Offset(.72, .79),
          Offset(.78, .68),
          Offset(.16, .68),
        ],
        [
          Offset(.67, .85),
          Offset(.94, .80),
          Offset(.94, .66),
          Offset(.72, .70),
        ],
      ],
      roofPolygons: const [
        [Offset(.10, .47), Offset(.77, .47), mainRidgeEnd, mainRidgeStart],
        [Offset(.15, .41), Offset(.78, .41), mainRidgeEnd, mainRidgeStart],
        [Offset(.67, .60), Offset(.96, .54), wingRidgeEnd, wingRidgeStart],
        [Offset(.72, .50), Offset(.96, .47), wingRidgeEnd, wingRidgeStart],
      ],
      wallPolygons: const [
        [
          Offset(.17, .51),
          Offset(.72, .51),
          Offset(.72, .75),
          Offset(.13, .75),
        ],
        [
          Offset(.74, .55),
          Offset(.91, .52),
          Offset(.91, .76),
          Offset(.72, .79),
        ],
      ],
      groundContact: const Offset(.52, .85),
    );
  }

  final List<Offset> mainFrontFeet;
  final List<Offset> mainRearFeet;
  final List<Offset> mainFrontHeads;
  final List<Offset> mainRearHeads;
  final List<Offset> wingFrontFeet;
  final List<Offset> wingRearFeet;
  final List<Offset> wingFrontHeads;
  final List<Offset> wingRearHeads;
  final List<SarangchaeSegment> posts;
  final List<SarangchaeSegment> beams;
  final List<SarangchaeSegment> rafters;
  final List<SarangchaeSegment> ridges;
  final List<SarangchaeSegment> eaves;
  final List<List<Offset>> foundationPolygons;
  final List<List<Offset>> roofPolygons;
  final List<List<Offset>> wallPolygons;
  final Offset groundContact;

  int get frontPostCount => mainFrontFeet.length + wingFrontFeet.length;
  int get rearPostCount => mainRearFeet.length + wingRearFeet.length;
}

class SarangchaeConstructionPilot extends StatelessWidget {
  const SarangchaeConstructionPilot({
    required this.phase,
    this.finishedImage,
    this.geometry,
    super.key,
  });

  final SarangchaeBuildPhase phase;
  final ui.Image? finishedImage;
  final SarangchaeGeometry? geometry;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _SarangchaePilotPainter(
      phase: phase,
      geometry: geometry ?? SarangchaeGeometry.standard(),
      finishedImage: finishedImage,
    ),
    size: Size.infinite,
  );
}

final class _SarangchaePilotPainter extends CustomPainter {
  const _SarangchaePilotPainter({
    required this.phase,
    required this.geometry,
    required this.finishedImage,
  });

  final SarangchaeBuildPhase phase;
  final SarangchaeGeometry geometry;
  final ui.Image? finishedImage;

  Offset _p(Offset p, Size size) =>
      Offset(p.dx * size.width, p.dy * size.height);

  Path _polygon(List<Offset> points, Size size) =>
      Path()..addPolygon([for (final p in points) _p(p, size)], true);

  void _segments(
    Canvas canvas,
    Size size,
    Iterable<SarangchaeSegment> segments,
    Paint paint,
  ) {
    for (final segment in segments) {
      canvas.drawLine(_p(segment.start, size), _p(segment.end, size), paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final groundY = geometry.groundContact.dy * size.height;
    canvas.drawLine(
      Offset(size.width * .05, groundY),
      Offset(size.width * .96, groundY),
      Paint()
        ..color = const Color(0x33785B32)
        ..strokeWidth = 1,
    );

    if (phase == SarangchaeBuildPhase.finished && finishedImage != null) {
      final source = Rect.fromLTWH(
        0,
        0,
        finishedImage!.width.toDouble(),
        finishedImage!.height.toDouble(),
      );
      final ratio = source.width / source.height;
      final drawWidth = size.width * .93;
      final drawHeight = drawWidth / ratio;
      final destination = Rect.fromLTWH(
        size.width * .035,
        groundY - drawHeight,
        drawWidth,
        drawHeight,
      );
      canvas.drawImageRect(finishedImage!, source, destination, Paint());
      return;
    }

    final phaseIndex = phase.index;
    final footprintPaint = Paint()
      ..color = const Color(0xFF9A7440)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final polygon in geometry.foundationPolygons) {
      canvas.drawPath(_polygon(polygon, size), footprintPaint);
    }
    if (phaseIndex == SarangchaeBuildPhase.setout.index) return;

    final stoneFill = Paint()..color = const Color(0xFFD1BE96);
    final stoneLine = Paint()
      ..color = const Color(0xFF7C6848)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final polygon in geometry.foundationPolygons) {
      final path = _polygon(polygon, size);
      canvas
        ..drawPath(path, stoneFill)
        ..drawPath(path, stoneLine);
    }
    if (phaseIndex == SarangchaeBuildPhase.foundation.index) return;

    final timber = Paint()
      ..color = const Color(0xFF6F4527)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * .009;
    _segments(canvas, size, geometry.posts, timber);
    if (phaseIndex == SarangchaeBuildPhase.posts.index) return;

    final beamPaint = Paint()
      ..color = const Color(0xFF4E2F1C)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * .011;
    _segments(canvas, size, geometry.beams, beamPaint);
    if (phaseIndex == SarangchaeBuildPhase.beams.index) return;

    final rafterPaint = Paint()
      ..color = const Color(0xFF9B6A3D)
      ..strokeWidth = size.width * .0032;
    _segments(canvas, size, geometry.rafters, rafterPaint);
    _segments(canvas, size, geometry.ridges, beamPaint);
    if (phaseIndex == SarangchaeBuildPhase.rafters.index) return;

    final tileFill = Paint()..color = const Color(0xDD2C3036);
    final tileLine = Paint()
      ..color = const Color(0xFF111419)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final polygon in geometry.roofPolygons) {
      final path = _polygon(polygon, size);
      canvas
        ..drawPath(path, tileFill)
        ..drawPath(path, tileLine);
    }
    _segments(canvas, size, geometry.ridges, tileLine..strokeWidth = 4);
    if (phaseIndex == SarangchaeBuildPhase.roof.index) return;

    final wallFill = Paint()..color = const Color(0xFFE9DDC2);
    final wallLine = Paint()
      ..color = const Color(0xFF6F4527)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final polygon in geometry.wallPolygons) {
      final path = _polygon(polygon, size);
      canvas
        ..drawPath(path, wallFill)
        ..drawPath(path, wallLine);
    }
    for (var bay = 0; bay < 6; bay++) {
      final left = Offset.lerp(
        geometry.mainFrontHeads[bay],
        geometry.mainFrontFeet[bay],
        .18,
      )!;
      final right = Offset.lerp(
        geometry.mainFrontHeads[bay + 1],
        geometry.mainFrontFeet[bay + 1],
        .82,
      )!;
      final rect = Rect.fromPoints(_p(left, size), _p(right, size));
      canvas.drawRect(rect, wallLine);
      for (var bar = 1; bar <= 3; bar++) {
        final x = rect.left + rect.width * bar / 4;
        canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), wallLine);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SarangchaePilotPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.finishedImage != finishedImage;
}
