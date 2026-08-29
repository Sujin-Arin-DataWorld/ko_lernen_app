import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/ildu_turntable_catalog.dart';
import 'package:ko_lernen_app/widgets/sori/hanok_turntable_2d.dart';

void main() {
  testWidgets('horizontal drags move only between the eight supplied frames', (
    tester,
  ) async {
    var direction = 0;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 260,
              height: 160,
              child: StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  return HanokTurntable2D(
                    frames: kIlDuSarangchaeTurntable.frames,
                    direction: direction,
                    semanticsLabel: 'Sarangchae rotation',
                    zoomInLabel: 'Zoom in',
                    zoomOutLabel: 'Zoom out',
                    resetZoomLabel: 'Reset zoom',
                    onDirectionChanged: (next) =>
                        update(() => direction = next),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hanok-turntable-frame-0')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('hanok-turntable-drag-area')),
      const Offset(-40, 0),
    );
    await tester.pump();
    expect(direction, 1);
    expect(find.byType(HanokTurntableFrameImage), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hanok-turntable-frame-1')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('hanok-turntable-drag-area')),
      const Offset(70, 0),
    );
    await tester.pumpAndSettle();
    expect(direction, 7);
    expect(
      find.byKey(const ValueKey('hanok-turntable-frame-7')),
      findsOneWidget,
    );
  });

  testWidgets('exposes accessible increase and decrease actions', (
    tester,
  ) async {
    var direction = 0;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 240,
          height: 160,
          child: HanokTurntable2D(
            frames: kIlDuSarangchaeTurntable.frames,
            direction: direction,
            semanticsLabel: 'Sarangchae rotation',
            zoomInLabel: 'Zoom in',
            zoomOutLabel: 'Zoom out',
            resetZoomLabel: 'Reset zoom',
            onDirectionChanged: (next) => direction = next,
          ),
        ),
      ),
    );

    final semanticsFinder = find.byKey(
      const ValueKey('hanok-turntable-semantics'),
    );
    expect(semanticsFinder, findsOneWidget);
    final node = tester.getSemantics(semanticsFinder);
    expect(node.label, 'Sarangchae rotation');
    expect(node.value, '1 / 8, 100%');
    expect(node.getSemanticsData().hasAction(SemanticsAction.increase), isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.decrease), isTrue);
    semantics.dispose();
  });

  testWidgets('pinch and controls zoom without inventing rotation frames', (
    tester,
  ) async {
    var direction = 0;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 200,
              child: StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  return HanokTurntable2D(
                    frames: kIlDuAraechaeTurntable.frames,
                    direction: direction,
                    semanticsLabel: 'Araechae rotation and zoom',
                    zoomInLabel: 'Zoom in',
                    zoomOutLabel: 'Zoom out',
                    resetZoomLabel: 'Reset zoom',
                    onDirectionChanged: (next) =>
                        update(() => direction = next),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester
          .widget<HanokTurntableFrameImage>(
            find.byType(HanokTurntableFrameImage),
          )
          .cacheWidth,
      2560,
    );

    double currentScale() => tester
        .widget<Transform>(
          find.byKey(const ValueKey('hanok-turntable-zoom-layer')),
        )
        .transform
        .storage[0];

    expect(currentScale(), 1);
    await tester.tap(find.byKey(const ValueKey('hanok-turntable-zoom-in')));
    await tester.pump();
    expect(currentScale(), 1.25);
    expect(direction, 0);

    await tester.tap(find.byKey(const ValueKey('hanok-turntable-zoom-reset')));
    await tester.pump();
    expect(currentScale(), 1);

    final dragArea = find.byKey(const ValueKey('hanok-turntable-drag-area'));
    final center = tester.getCenter(dragArea);
    final first = await tester.startGesture(
      center.translate(-24, 20),
      pointer: 1,
    );
    final second = await tester.startGesture(
      center.translate(24, 20),
      pointer: 2,
    );
    await tester.pump();
    await first.moveTo(center.translate(-60, 20));
    await second.moveTo(center.translate(60, 20));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pump();

    expect(currentScale(), greaterThan(1));
    expect(direction, 0);

    await tester.drag(dragArea, const Offset(-40, 0));
    await tester.pumpAndSettle();
    expect(direction, 1);
    expect(
      find.byKey(const ValueKey('hanok-turntable-frame-1')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('hanok-turntable-zoom-reset')));
    await tester.pump();
    expect(currentScale(), 1);
  });
}
