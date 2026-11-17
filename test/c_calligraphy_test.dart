import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_calligraphy_canvas.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_calligraphy_ink.dart';
import 'package:ko_lernen_app/widgets/trace_canvas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(CCalligraphyAssets.loadBrush);

  test(
    'finger uses study pressure; pen pressure is normalized and clamped',
    () {
      expect(
        CCalligraphyMotion.pressure(const PointerDownEvent(pressure: .1)),
        .75,
      );
      expect(
        CCalligraphyMotion.pressure(
          const PointerDownEvent(
            kind: PointerDeviceKind.stylus,
            pressure: 4,
            pressureMin: 2,
            pressureMax: 6,
          ),
        ),
        .5,
      );
      expect(
        CCalligraphyMotion.pressure(
          const PointerDownEvent(
            kind: PointerDeviceKind.stylus,
            pressure: 8,
            pressureMin: 2,
            pressureMax: 6,
          ),
        ),
        1,
      );
      expect(
        CCalligraphyMotion.width(.15, 40, 1),
        greaterThan(CCalligraphyMotion.width(.15, 40, .25) * 1.8),
      );
    },
  );

  test(
    'finger tail narrows existing geometry only; a circle keeps its closure',
    () {
      CInkShape shape(List<Offset> points) {
        final stroke = CInkStroke(
          CInkPoint(points.first, Duration.zero, .75),
          stylus: false,
        );
        for (var i = 1; i < points.length; i++) {
          stroke.add(CInkPoint(points[i], Duration(milliseconds: i * 16), .75));
        }
        stroke.finish();
        return CInkShape(stroke, const Size(220, 220))..sync(0);
      }

      final line = shape(const [
        Offset(30, 40),
        Offset(130, 40),
        Offset(130, 160),
      ]);
      addTearDown(line.dispose);
      expect(line.stamps.first.position, const Offset(30, 40));
      expect(line.stamps.last.position, const Offset(130, 160));
      expect(
        line.stamps.every(
          (s) =>
              (s.position.dy - 40).abs() < 1e-8 ||
              (s.position.dx - 130).abs() < 1e-8,
        ),
        isTrue,
      );
      expect(
        line.stamps.last.width,
        lessThan(line.stamps[line.stamps.length - 16].width / 3),
      );
      final circle = shape(
        List.generate(
          161,
          (i) => Offset(
            110 + math.cos(-math.pi / 2 + i / 160 * math.pi * 2) * 60,
            110 + math.sin(-math.pi / 2 + i / 160 * math.pi * 2) * 60,
          ),
        ),
      );
      addTearDown(circle.dispose);
      expect(
        (circle.stamps.last.position - circle.stamps.first.position).distance,
        lessThan(.001),
      );
      expect(circle.stamps.last.width, greaterThan(5));
    },
  );

  test('brush load and fibers spring; texture endpoint stays on input', () {
    final brush = CCalligraphyBrush(const Offset(90, 120), 0, 1);
    brush.move(const Offset(90, 120), 16, .3, 0, 1);
    for (var t = 16; t <= 400; t += 8) {
      brush.update(t.toDouble());
    }
    expect(brush.load, greaterThan(.6));
    expect(brush.bend.distance, greaterThan(2));
    expect(brush.curve(1).$1, Offset.zero);
    expect(brush.contact, const Offset(90, 120));
    brush.lift(400);
    for (var t = 408; t <= 700; t += 8) {
      brush.update(t.toDouble());
    }
    expect(brush.load, lessThan(.03));
    expect(brush.bend.distance, lessThan(.1));
    expect(brush.opacity(700), 0);
    expect(brush.moving(700), isFalse);
    expect(brush.curve(1).$1, Offset.zero);
  });

  testWidgets(
    'C raw stroke and size match pointer coordinates; brush settles',
    (tester) async {
      final controller = TraceCanvasController();
      addTearDown(controller.dispose);
      final reports = <TraceCanvasSnapshot>[];
      final sizes = <Size>[];
      await tester.pumpWidget(
        _host(
          controller,
          onEnd: (snapshot, size) {
            reports.add(snapshot);
            sizes.add(size);
          },
        ),
      );
      final input = find.byKey(const Key('trace-canvas'));
      final ink = find.byKey(const ValueKey('trace-canvas-ghost-ㄱ'));
      expect(input.hitTestable(), findsOneWidget);
      expect(ink.hitTestable(), findsNothing);
      expect(tester.getRect(input), tester.getRect(ink));
      final origin = tester.getTopLeft(input);
      final gesture = await tester.startGesture(origin + const Offset(20, 40));
      await gesture.moveTo(origin + const Offset(120, 40));
      await tester.pump(const Duration(milliseconds: 160));
      await gesture.moveTo(origin + const Offset(120, 160));
      await tester.pump(const Duration(milliseconds: 80));
      expect(
        find.byKey(const Key('c-calligraphy-moving-brush')),
        findsOneWidget,
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(reports.single.strokes.single, const [
        Offset(20, 40),
        Offset(120, 40),
        Offset(120, 160),
      ]);
      expect(sizes.single, const Size(220, 220));
      expect(tester.binding.hasScheduledFrame, isFalse);
      controller.reset();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('c-calligraphy-moving-brush')), findsNothing);
    },
  );

  testWidgets('C reject, cancel, and retry remove only affected ink', (
    tester,
  ) async {
    final controller = TraceCanvasController();
    addTearDown(controller.dispose);
    var reports = 0;
    await tester.pumpWidget(_host(controller, onEnd: (_, _) => reports++));
    final origin = tester.getTopLeft(find.byKey(const Key('trace-canvas')));
    Future<void> draw(Offset start, Offset end) async {
      final gesture = await tester.startGesture(origin + start);
      await gesture.moveTo(origin + end);
      await gesture.up();
      await tester.pump();
    }

    await draw(const Offset(20, 20), const Offset(120, 20));
    await draw(const Offset(20, 80), const Offset(120, 80));
    controller.rejectLastStroke();
    await tester.pumpAndSettle();
    expect(controller.snapshot.strokes, const [
      [Offset(20, 20), Offset(120, 20)],
    ]);
    expect(find.byKey(const Key('trace-canvas-error-ghost')), findsOneWidget);
    final cancelled = await tester.startGesture(origin + const Offset(30, 100));
    await cancelled.moveTo(origin + const Offset(130, 100));
    await cancelled.cancel();
    await tester.pumpAndSettle();
    expect(controller.snapshot.strokes, hasLength(1));
    expect(find.byKey(const Key('c-calligraphy-moving-brush')), findsNothing);
    await draw(const Offset(20, 80), const Offset(120, 80));
    await tester.pumpAndSettle();
    expect(controller.snapshot.strokes, hasLength(2));
    expect(find.byKey(const Key('trace-canvas-error-ghost')), findsNothing);
    expect(reports, 3);
  });

  testWidgets('reduced motion retains pressure ink and schedules no motion', (
    tester,
  ) async {
    final controller = TraceCanvasController();
    addTearDown(controller.dispose);
    final capture = GlobalKey();
    await tester.pumpWidget(_host(controller, reduced: true, capture: capture));
    final origin = tester.getTopLeft(find.byKey(const Key('trace-canvas')));
    final snapshots = <List<Offset>>[];
    Future<int> pen(double pressure, int pointer) async {
      await tester.sendEventToBinding(
        PointerDownEvent(
          pointer: pointer,
          kind: PointerDeviceKind.stylus,
          position: origin + const Offset(30, 110),
          pressure: pressure,
          pressureMin: 0,
          pressureMax: 1,
        ),
      );
      await tester.sendEventToBinding(
        PointerMoveEvent(
          pointer: pointer,
          kind: PointerDeviceKind.stylus,
          position: origin + const Offset(180, 110),
          pressure: pressure,
          pressureMin: 0,
          pressureMax: 1,
          timeStamp: const Duration(milliseconds: 700),
        ),
      );
      await tester.sendEventToBinding(
        PointerUpEvent(
          pointer: pointer,
          kind: PointerDeviceKind.stylus,
          position: origin + const Offset(180, 110),
          timeStamp: const Duration(milliseconds: 720),
        ),
      );
      await tester.pump();
      snapshots.add(controller.snapshot.strokes.single);
      expect(find.byKey(const Key('c-calligraphy-moving-brush')), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);
      final boundary =
          capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      return (await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        image.dispose();
        var dark = 0;
        for (var i = 0; i < bytes!.lengthInBytes; i += 4) {
          if (bytes.getUint8(i) < 100 && bytes.getUint8(i + 1) < 100) {
            dark++;
          }
        }
        return dark;
      }))!;
    }

    final light = await pen(.25, 11);
    controller.reset();
    await tester.pump();
    final deep = await pen(1, 12);
    expect(snapshots.first, snapshots.last);
    expect(deep, greaterThan(light * 1.6));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets(
    'outside raw points stay raw; ink, brush and rejected ghost stay on paper',
    (tester) async {
      final controller = TraceCanvasController();
      addTearDown(controller.dispose);
      final capture = GlobalKey();
      TraceCanvasSnapshot? report;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: RepaintBoundary(
                key: capture,
                child: SizedBox.square(
                  dimension: 320,
                  child: ColoredBox(
                    color: Colors.white,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox.square(
                        dimension: 220,
                        child: TraceCanvas(
                          controller: controller,
                          ghost: '',
                          color: Colors.teal,
                          errorColor: Colors.red,
                          enabled: true,
                          calligraphy: true,
                          semanticLabel: 'Trace',
                          onStrokeEnd: (snapshot, _) => report = snapshot,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final origin = tester.getTopLeft(find.byKey(const Key('trace-canvas')));
      final gesture = await tester.startGesture(origin + const Offset(20, 20));
      await gesture.moveTo(origin + const Offset(290, 270));
      await tester.pump(const Duration(milliseconds: 180));
      Future<void> outsideIsWhite() async {
        final boundary =
            capture.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          image.dispose();
          for (var y = 222; y < 320; y++) {
            for (var x = 222; x < 320; x++) {
              expect(bytes.getUint32((y * 320 + x) * 4), 0xffffffff);
            }
          }
        });
      }

      await outsideIsWhite();
      await gesture.up();
      await tester.pump();
      expect(report!.strokes.single.last, const Offset(290, 270));
      controller.rejectLastStroke();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('trace-canvas-error-ghost')), findsOneWidget);
      await outsideIsWhite();
    },
  );

  testWidgets(
    'C controller replacement cancels active input and pending brush',
    (tester) async {
      final first = TraceCanvasController();
      final next = TraceCanvasController();
      addTearDown(first.dispose);
      addTearDown(next.dispose);
      await tester.pumpWidget(_host(first));
      final origin = tester.getTopLeft(find.byKey(const Key('trace-canvas')));
      final gesture = await tester.startGesture(origin + const Offset(20, 50));
      await gesture.moveTo(origin + const Offset(120, 50));
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpWidget(_host(next));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(first.snapshot.strokes, isEmpty);
      expect(next.snapshot.strokes, isEmpty);
      expect(find.byKey(const Key('c-calligraphy-moving-brush')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _host(
  TraceCanvasController controller, {
  TraceStrokeEndCallback? onEnd,
  bool reduced = false,
  GlobalKey? capture,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: capture,
          child: SizedBox.square(
            dimension: 220,
            child: ColoredBox(
              color: Colors.white,
              child: TraceCanvas(
                controller: controller,
                ghost: 'ㄱ',
                color: Colors.teal,
                errorColor: Colors.red,
                enabled: true,
                calligraphy: true,
                semanticLabel: 'Trace',
                onStrokeEnd: onEnd ?? (_, _) {},
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);
