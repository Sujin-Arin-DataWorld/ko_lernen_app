import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/ildu_turntable_catalog.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/widgets/sori/hanok_turntable_2d.dart';

void main() {
  testWidgets('horizontal drags move only between the eight supplied frames', (
    tester,
  ) async {
    var direction = 0;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
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
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
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
    expect(node.value, '1 / 8, 100%');
    expect(node.getSemanticsData().hasAction(SemanticsAction.increase), isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.decrease), isTrue);
    semantics.dispose();
  });

  testWidgets('pinch and controls zoom without synthesizing extra frames', (
    tester,
  ) async {
    var direction = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              height: 180,
              child: StatefulBuilder(
                builder: (context, setState) => HanokTurntable2D(
                  frames: kIlDuSarangchaeTurntable.frames,
                  direction: direction,
                  semanticsLabel: 'Sarangchae rotation',
                  onDirectionChanged: (next) {
                    setState(() {
                      direction = next;
                    });
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final zoomOut = find.byKey(const ValueKey('hanok-turntable-zoom-out'));
    expect(tester.widget<IconButton>(zoomOut).onPressed, isNotNull);
    tester.widget<IconButton>(zoomOut).onPressed!();
    await tester.pump();
    expect(_turntableScale(tester), .75);
    final zoomIn = find.byKey(const ValueKey('hanok-turntable-zoom-in'));
    expect(tester.widget<IconButton>(zoomIn).onPressed, isNotNull);
    tester.widget<IconButton>(zoomIn).onPressed!();
    await tester.pump();
    expect(_turntableScale(tester), 1);

    final dragArea = find.byKey(const ValueKey('hanok-turntable-drag-area'));
    final center = tester.getCenter(dragArea);
    final first = await tester.startGesture(
      center - const Offset(24, 0),
      pointer: 1,
    );
    final second = await tester.startGesture(
      center + const Offset(24, 0),
      pointer: 2,
    );
    await first.moveTo(center - const Offset(72, 0));
    await second.moveTo(center + const Offset(72, 0));
    await tester.pump();

    expect(_turntableScale(tester), greaterThan(1));
    expect(direction, 0);

    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hanok-turntable-zoom-reset')));
    await tester.pump();
    expect(_turntableScale(tester), 1);
  });
}

double _turntableScale(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find.byKey(const ValueKey('hanok-turntable-image-transform')),
  );
  return transform.transform.entry(0, 0);
}
