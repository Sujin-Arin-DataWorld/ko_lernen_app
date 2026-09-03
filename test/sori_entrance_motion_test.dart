import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/motion.dart';

/// §MOTION-1(J5) — `SoriEntrance` must not schedule an uncancellable
/// `Future<void>.delayed` regardless of reduce-motion: reduce-motion skips
/// the timer entirely (final state on the first frame), and the motion-on
/// path uses a cancellable `Timer` disposed with the widget. Cases ①③ end
/// without `pumpAndSettle`/`pump(delay)` — a leftover pending timer fails
/// the test itself (Flutter's "Timer is still pending" check), which is the
/// regression this guards against.
void main() {
  testWidgets(
    '① reduce-motion: no timer, no opacity ramp, no pending frames',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: SoriEntrance(
            delay: const Duration(milliseconds: 120),
            child: const SizedBox(key: ValueKey('child')),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Opacity), findsNothing);
      expect(find.byKey(const ValueKey('child')), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 0);
      // Intentionally no pumpAndSettle/pump(delay) here — a leftover Timer
      // would surface as a framework failure at test teardown.
    },
  );

  testWidgets(
    '② motion on: opacity starts at 0, reaches 1 after delay + duration',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SoriEntrance(
            delay: const Duration(milliseconds: 120),
            duration: const Duration(milliseconds: 540),
            child: const SizedBox(key: ValueKey('child')),
          ),
        ),
      );
      await tester.pump();

      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);

      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 540));

      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    },
  );

  testWidgets(
    '③ unmounting while the delay timer is pending leaves no pending timer',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SoriEntrance(
            delay: const Duration(milliseconds: 500),
            child: const SizedBox(key: ValueKey('child')),
          ),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(const SizedBox());
      // Intentionally no further pump/pumpAndSettle — if dispose() failed
      // to cancel the delay Timer, the framework itself would flag the
      // pending timer at test teardown.
    },
  );

  testWidgets(
    '④ reduce-motion is judged once — a later MediaQuery flip does not '
    're-trigger the entrance',
    (tester) async {
      final reduceMotion = ValueNotifier<bool>(true);
      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: reduceMotion,
            builder: (context, disabled, _) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: disabled,
              ),
              child: SoriEntrance(
                child: const SizedBox(key: ValueKey('child')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Opacity), findsNothing);

      reduceMotion.value = false;
      await tester.pump();

      expect(tester.binding.transientCallbackCount, 0);
    },
  );
}
