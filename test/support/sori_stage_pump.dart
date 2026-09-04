// §MOTION-2(J6) — Any screen with an active SoriPulse (idle "keep going"
// breathing scale, lib/widgets/sori/motion.dart) runs an
// AnimationController.repeat(reverse: true) that never settles on its own.
// pumpAndSettle() on such a screen either times out (10 min budget) or
// spins until the test framework kills it. Do not use tester.pumpAndSettle()
// on a screen that can host SoriStageCatalogScreen or SoriStageShell with an
// active continue-hero — use the two helpers below instead.

import 'package:flutter_test/flutter_test.dart';

/// Bounded settle for screens that may host an idle `SoriPulse`: pumps once,
/// then pumps [settle] a total of [frames] times. Drop-in replacement for
/// `pumpAndSettle()` when the screen's *own* entrance/sheet transitions are
/// what need time to finish — not an indefinitely repeating idle animation.
Future<void> pumpSoriStage(
  WidgetTester tester, {
  Duration settle = const Duration(milliseconds: 600),
  int frames = 2,
}) async {
  await tester.pump();
  for (var i = 0; i < frames; i++) {
    await tester.pump(settle);
  }
}

/// Polls (real event-loop steps via [WidgetTester.runAsync], so real I/O
/// continuations bound to the real zone — e.g. `rootBundle` reads started
/// under `tester.tap`'s own `runAsync` — actually get a chance to run) until
/// [finder] resolves to at least one widget, or [timeout] elapses. Returns as
/// soon as [finder] is found; the caller still asserts on it (a timeout is
/// not itself a failure here — the assertion after this call is what fails).
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
  Duration step = const Duration(milliseconds: 100),
}) async {
  await tester.runAsync(() async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump();
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      await Future<void>.delayed(step);
    }
  });
}
