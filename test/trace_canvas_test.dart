import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/trace_canvas.dart';

void main() {
  testWidgets('completed pointer strokes are reported in draw order', (
    tester,
  ) async {
    final controller = TraceCanvasController();
    addTearDown(controller.dispose);
    final reports = <TraceCanvasSnapshot>[];
    final sizes = <Size>[];
    await tester.pumpWidget(
      _host(
        controller,
        onStrokeEnd: (snapshot, size) {
          reports.add(snapshot);
          sizes.add(size);
        },
      ),
    );

    await _draw(tester, const [Offset(10, 20), Offset(40, 60)]);
    await _draw(tester, const [Offset(80, 30), Offset(100, 90)]);

    expect(reports, hasLength(2));
    expect(reports.first.strokes, const [
      [Offset(10, 20), Offset(40, 60)],
    ]);
    expect(reports.last.strokes, const [
      [Offset(10, 20), Offset(40, 60)],
      [Offset(80, 30), Offset(100, 90)],
    ]);
    expect(sizes, everyElement(const Size(220, 220)));
  });

  testWidgets('published snapshots cannot mutate either stroke-list level', (
    tester,
  ) async {
    final controller = TraceCanvasController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller));
    await _draw(tester, const [Offset(10, 20), Offset(40, 60)]);

    final snapshot = controller.snapshot;
    expect(
      () => snapshot.strokes.add(const [Offset.zero]),
      throwsUnsupportedError,
    );
    expect(
      () => snapshot.strokes.first.add(const Offset(99, 99)),
      throwsUnsupportedError,
    );
    expect(controller.snapshot.strokes.first, const [
      Offset(10, 20),
      Offset(40, 60),
    ]);
  });

  testWidgets(
    'pointer cancel removes the unfinished stroke without reporting',
    (tester) async {
      final controller = TraceCanvasController();
      addTearDown(controller.dispose);
      var reports = 0;
      await tester.pumpWidget(
        _host(controller, onStrokeEnd: (_, _) => reports++),
      );

      final gesture = await _start(tester, const Offset(10, 20));
      await gesture.moveTo(_global(tester, const Offset(40, 60)));
      await gesture.cancel();
      await tester.pump();

      expect(controller.snapshot.strokes, isEmpty);
      expect(reports, 0);
    },
  );

  testWidgets('reject moves only the last stroke into a visible error ghost', (
    tester,
  ) async {
    final controller = TraceCanvasController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller));
    await _draw(tester, const [Offset(10, 20), Offset(40, 60)]);

    controller.rejectLastStroke();
    await tester.pump();

    expect(controller.snapshot.strokes, isEmpty);
    expect(find.byKey(const Key('trace-canvas-error-ghost')), findsOneWidget);

    controller.clearErrorGhost();
    await tester.pump();
    expect(find.byKey(const Key('trace-canvas-error-ghost')), findsNothing);
  });

  testWidgets('next-stroke hint and reset have observable lifecycle', (
    tester,
  ) async {
    final controller = TraceCanvasController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller));

    controller.showNextStrokeHint(const [Offset(30, 40), Offset(90, 40)]);
    await tester.pump();
    expect(
      find.byKey(const Key('trace-canvas-next-stroke-hint')),
      findsOneWidget,
    );

    await _draw(tester, const [Offset(10, 20), Offset(40, 60)]);
    controller.reset();
    await tester.pump();
    expect(controller.snapshot.strokes, isEmpty);
    expect(
      find.byKey(const Key('trace-canvas-next-stroke-hint')),
      findsNothing,
    );
    expect(find.byKey(const Key('trace-canvas-error-ghost')), findsNothing);
  });

  testWidgets('semantic label names the drawing surface', (tester) async {
    final semantics = tester.ensureSemantics();
    final controller = TraceCanvasController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(controller, semanticLabel: 'Trace the Korean letter'),
    );

    expect(find.bySemanticsLabel('Trace the Korean letter'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('replacing the controller cancels its active pointer stroke', (
    tester,
  ) async {
    final first = TraceCanvasController();
    final second = TraceCanvasController();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await tester.pumpWidget(_host(first));

    final gesture = await _start(tester, const Offset(10, 20));
    await gesture.moveTo(_global(tester, const Offset(40, 60)));
    await tester.pumpWidget(_host(second));

    expect(first.snapshot.strokes, isEmpty);
    expect(second.snapshot.strokes, isEmpty);
    await gesture.cancel();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing the widget cancels an active pointer safely', (
    tester,
  ) async {
    final controller = TraceCanvasController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller));

    final gesture = await _start(tester, const Offset(10, 20));
    await gesture.moveTo(_global(tester, const Offset(40, 60)));
    await tester.pumpWidget(const SizedBox.shrink());
    await gesture.cancel();
    await tester.pump();

    expect(controller.snapshot.strokes, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

Widget _host(
  TraceCanvasController controller, {
  TraceStrokeEndCallback? onStrokeEnd,
  String semanticLabel = 'Trace canvas',
}) => MaterialApp(
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox.square(
        dimension: 220,
        child: TraceCanvas(
          key: const ValueKey('trace-canvas-under-test'),
          controller: controller,
          ghost: 'ㄱ',
          color: Colors.teal,
          errorColor: Colors.red,
          enabled: true,
          semanticLabel: semanticLabel,
          onStrokeEnd: onStrokeEnd ?? (_, _) {},
        ),
      ),
    ),
  ),
);

Future<TestGesture> _start(WidgetTester tester, Offset local) =>
    tester.startGesture(_global(tester, local));

Offset _global(WidgetTester tester, Offset local) =>
    tester.getTopLeft(find.byKey(const Key('trace-canvas'))) + local;

Future<void> _draw(WidgetTester tester, List<Offset> points) async {
  final gesture = await _start(tester, points.first);
  for (final point in points.skip(1)) {
    await gesture.moveTo(_global(tester, point));
  }
  await gesture.up();
  await tester.pump();
}
