import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/motion.dart';

/// §MOTION-2(J6) — `SoriPulse` is an idle, infinitely-repeating breathing
/// scale (`_c.repeat(reverse: true)`) once active. It already honored
/// reduce-motion; this locks the *widget-test* contract that lets a screen
/// hosting it be pumped without `pumpAndSettle()` hanging (case ③, already
/// true via Flutter's built-in ticker muting under a disabled `TickerMode`)
/// and adds an explicit `_running`/`isAnimating` sync to that mute so a
/// muted-then-reactivated pulse restarts its phase from 0 (case ④, new).
void main() {
  testWidgets('① reduce-motion renders the child directly, no ticking', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const SoriPulse(child: SizedBox(key: ValueKey('child'))),
      ),
    );
    await tester.pump();

    expect(find.byType(Transform), findsNothing);
    expect(find.byKey(const ValueKey('child')), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets(
    '② motion on: scale rises above 1.0, peaks near maxScale, returns to '
    '1.0 after a full 4800ms round trip (duration is one direction)',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SoriPulse(child: SizedBox(key: ValueKey('child'))),
        ),
      );
      await tester.pump();

      double scaleOf() => tester
          .widget<Transform>(find.byType(Transform))
          .transform
          .getMaxScaleOnAxis();

      expect(scaleOf(), 1.0);

      await tester.pump(const Duration(milliseconds: 1200));
      expect(scaleOf(), greaterThan(1.0));

      await tester.pump(const Duration(milliseconds: 1200));
      expect(scaleOf(), closeTo(1.02, 0.001));

      await tester.pump(const Duration(milliseconds: 2400));
      expect(scaleOf(), closeTo(1.0, 0.001));
    },
  );

  testWidgets(
    '③ current contract: a disabled TickerMode mutes the ticker enough '
    'that pumpAndSettle() returns normally',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TickerMode(
            enabled: false,
            child: const SoriPulse(child: SizedBox(key: ValueKey('child'))),
          ),
        ),
      );
      await tester.pump();

      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    '④ switching an active pulse into a disabled TickerMode stops '
    'isAnimating (the one behavior this change adds)',
    (tester) async {
      final tickerEnabled = ValueNotifier<bool>(true);
      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: tickerEnabled,
            builder: (context, enabled, _) => TickerMode(
              enabled: enabled,
              child: const SoriPulse(child: SizedBox(key: ValueKey('child'))),
            ),
          ),
        ),
      );
      await tester.pump();

      final animatedBuilder = find.descendant(
        of: find.byType(SoriPulse),
        matching: find.byType(AnimatedBuilder),
      );
      AnimationController controllerOf() =>
          tester.widget<AnimatedBuilder>(animatedBuilder).animation
              as AnimationController;

      expect(controllerOf().isAnimating, isTrue);

      tickerEnabled.value = false;
      await tester.pump();

      expect(controllerOf().isAnimating, isFalse);
    },
  );
}
