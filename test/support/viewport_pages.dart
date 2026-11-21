import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> showViewportSection(
  WidgetTester tester,
  Finder target, {
  Finder? within,
}) async {
  if (target.hitTestable().evaluate().isNotEmpty) {
    return;
  }
  Finder control(String key) {
    final button = find.byKey(ValueKey(key));
    return (within == null
            ? button
            : find.descendant(of: within, matching: button))
        .hitTestable();
  }

  final previous = control('sori-viewport-previous');
  final next = control('sori-viewport-next');
  bool enabled(Finder button) =>
      button.evaluate().isNotEmpty &&
      tester.widget<IconButton>(button.last).onPressed != null;
  while (enabled(previous)) {
    await tester.tap(previous.last);
    await tester.pumpAndSettle();
    if (target.hitTestable().evaluate().isNotEmpty) {
      return;
    }
  }
  while (enabled(next)) {
    await tester.tap(next.last);
    await tester.pumpAndSettle();
    if (target.hitTestable().evaluate().isNotEmpty) {
      return;
    }
  }
  expect(target.hitTestable(), findsOneWidget);
}

/// Brings [target] on screen whichever body the current route uses: paged
/// screens (`SoriViewportPages`) turn to the page holding it, scrolling
/// screens scroll the first [Scrollable] by [delta] until it is built.
Future<void> revealForTap(
  WidgetTester tester,
  Finder target, {
  double delta = 180,
}) async {
  await tester.pump();
  if (target.hitTestable().evaluate().isNotEmpty) {
    return;
  }
  final paged = find
      .byKey(const ValueKey('sori-viewport-page'))
      .evaluate()
      .isNotEmpty;
  final scrollable = find.byType(Scrollable);
  if (paged || scrollable.evaluate().isEmpty) {
    await showViewportSection(tester, target);
    return;
  }
  await tester.scrollUntilVisible(target, delta, scrollable: scrollable.first);
  await tester.ensureVisible(target);
  await tester.pump();
}
