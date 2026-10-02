import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/bojagi_reveal.dart';

void main() {
  testWidgets('cloth opens once and can be disposed during the motion', (
    tester,
  ) async {
    var opened = 0;
    var opening = false;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (_, setState) {
            update = setState;
            return SoriBojagiReveal(opening: opening, onOpened: () => opened++);
          },
        ),
      ),
    );
    expect(opened, 0);
    update(() => opening = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(opened, 0);
    expect(find.image(const AssetImage(kBojagiUnfolded)), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    expect(opened, 1);
    expect(find.image(const AssetImage(kBojagiClosed)), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    expect(opened, 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion exposes the final received item immediately', (
    tester,
  ) async {
    var revealed = 0;
    Widget receipt() => MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: SoriBojagiReveal(
          rewardSlug: 'decoration_soban',
          onRewardRevealed: () => revealed++,
        ),
      ),
    );
    await tester.pumpWidget(receipt());
    expect(revealed, 1);
    expect(find.image(const AssetImage(kBojagiUnfolded)), findsOneWidget);
    expect(find.image(const AssetImage(kBojagiOpen)), findsNothing);
    for (final opacity in tester.widgetList<Opacity>(find.byType(Opacity))) {
      expect(opacity.opacity, 1);
    }
    await tester.pumpWidget(receipt());
    await tester.pump(const Duration(seconds: 2));
    expect(revealed, 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing before reward emergence cancels its callback', (
    tester,
  ) async {
    var revealed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SoriBojagiReveal(
          rewardSlug: 'decoration_soban',
          onRewardRevealed: () => revealed++,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 450));
    expect(revealed, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(revealed, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });
}
