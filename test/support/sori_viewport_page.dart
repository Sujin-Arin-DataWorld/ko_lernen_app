import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> showSoriViewportSection(WidgetTester tester, Finder target) async {
  await tester.pump();
  if (target.hitTestable().evaluate().isNotEmpty) return;

  for (final direction in ['previous', 'next']) {
    final control = find
        .byKey(ValueKey('sori-viewport-$direction'))
        .hitTestable();
    for (var page = 0; page < 200; page++) {
      if (control.evaluate().isEmpty ||
          tester.widget<IconButton>(control.first).onPressed == null) {
        break;
      }
      await tester.tap(control.first);
      await tester.pump();
      await tester.pump();
      if (target.hitTestable().evaluate().isNotEmpty) return;
    }
  }
  expect(target.hitTestable(), findsWidgets);
}
