import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> showViewportSection(
  WidgetTester tester,
  Finder target, {
  Finder? within,
}) async {
  // SoriViewportPages counts its pages after layout and shows the pager on
  // the following frame; render that frame before deciding where we are.
  await tester.pump();
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
  final indicator = find.byKey(const ValueKey('sori-viewport-page'));
  String? page() => indicator.evaluate().length == 1
      ? tester.widget<Text>(indicator).data
      : null;
  bool enabled(Finder button) =>
      button.evaluate().isNotEmpty &&
      tester.widget<IconButton>(button.last).onPressed != null;
  final pageCount = int.tryParse(page()?.split('/').last ?? '') ?? 100;
  for (var index = 0; index < pageCount && enabled(previous); index++) {
    final lastPage = page();
    await tester.tap(previous.last);
    await tester.pumpAndSettle();
    if (target.hitTestable().evaluate().isNotEmpty) {
      return;
    }
    if (lastPage != null && lastPage == page()) break;
  }
  for (var index = 0; index < pageCount && enabled(next); index++) {
    final lastPage = page();
    await tester.tap(next.last);
    await tester.pumpAndSettle();
    if (target.hitTestable().evaluate().isNotEmpty) {
      return;
    }
    if (lastPage != null && lastPage == page()) break;
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
