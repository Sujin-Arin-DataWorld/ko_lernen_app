import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/card.dart';
import 'package:ko_lernen_app/widgets/sori/persona_card_motion.dart';

void main() {
  testWidgets(
    'finger position tilts and depresses a card, release activates once',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(onTap: () => taps++));
      final rect = tester.getRect(find.byKey(_cardKey));
      final gesture = await tester.startGesture(
        rect.topLeft + const Offset(32, 32),
        kind: PointerDeviceKind.touch,
      );
      await tester.pump(const Duration(milliseconds: 90));
      expect(_edge(tester), 2);
      expect(_motion(tester).transform!.entry(0, 2).abs(), greaterThan(.01));
      expect(_motion(tester).transform!.entry(1, 2).abs(), greaterThan(.01));
      expect(taps, 0);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(_edge(tester), 6);
      expect(_motion(tester).transform!.entry(0, 2), closeTo(0, .0001));
      expect(taps, 1);
    },
  );

  testWidgets('scrolling cancels depression and does not open the card', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(_host(onTap: () => taps++, scrollable: true));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_cardKey)),
      kind: PointerDeviceKind.touch,
    );
    await tester.pump();
    expect(_edge(tester), 2);
    await gesture.moveBy(const Offset(0, -70));
    await tester.pump();
    expect(_edge(tester), 6);
    await gesture.moveBy(const Offset(0, -70));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 0);
    expect(
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
      greaterThan(0),
    );
  });

  testWidgets('cancelled touch restores the card without activation', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(_host(onTap: () => taps++));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_cardKey)),
      kind: PointerDeviceKind.touch,
    );
    await tester.pump();
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(_edge(tester), 6);
    expect(taps, 0);
  });

  testWidgets(
    'reduced motion keeps static depth and immediate press feedback',
    (tester) async {
      await tester.pumpWidget(_host(onTap: () {}, reduced: true));
      final gesture = await tester.startGesture(
        tester.getTopLeft(find.byKey(_cardKey)) + const Offset(24, 24),
        kind: PointerDeviceKind.touch,
      );
      await tester.pump();
      expect(_motion(tester).duration, Duration.zero);
      expect(_motion(tester).transform!.entry(0, 2), closeTo(0, .0001));
      expect(_motion(tester).transform!.entry(1, 2), closeTo(0, .0001));
      expect(_motion(tester).transform!.entry(1, 3), 0);
      expect(_edge(tester), 2);
      await gesture.up();
      await tester.pump();
      expect(_edge(tester), 6);
      expect(tester.binding.transientCallbackCount, 0);
    },
  );
}

const _cardKey = ValueKey('touch-card');

Widget _host({
  required VoidCallback onTap,
  bool reduced = false,
  bool scrollable = false,
}) => MaterialApp(
  theme: AppTheme.light,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(
      body: Builder(
        builder: (context) {
          final card = Padding(
            padding: const EdgeInsets.all(24),
            child: SoriPersonaCardMotion(
              interactive: true,
              entrance: false,
              child: SoriCard(
                key: _cardKey,
                onTap: onTap,
                child: const SizedBox(width: 220, height: 180),
              ),
            ),
          );
          return scrollable
              ? ListView(children: [card, const SizedBox(height: 1600)])
              : Align(alignment: Alignment.topLeft, child: card);
        },
      ),
    ),
  ),
);

AnimatedContainer _motion(WidgetTester tester) => tester.widget(
  find
      .descendant(
        of: find.byType(SoriPersonaCardMotion),
        matching: find.byType(AnimatedContainer),
      )
      .first,
);

double _edge(WidgetTester tester) =>
    (_motion(tester).decoration! as BoxDecoration).boxShadow!.first.offset.dy;
