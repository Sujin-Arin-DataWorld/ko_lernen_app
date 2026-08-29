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
    await tester.pumpAndSettle();
    expect(direction, 1);
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
    expect(node.value, '1 / 8');
    expect(node.getSemanticsData().hasAction(SemanticsAction.increase), isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.decrease), isTrue);
    semantics.dispose();
  });
}
