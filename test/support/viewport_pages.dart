import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> showViewportSection(WidgetTester tester, Finder target) async {
  if (target.hitTestable().evaluate().isNotEmpty) {
    return;
  }
  Finder control(String key) => find.byKey(ValueKey(key)).hitTestable();
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
