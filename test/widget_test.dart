// Basic smoke test — ensures the app boots without crashing.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/main.dart';

void main() {
  testWidgets('App startet ohne Crash', (WidgetTester tester) async {
    await tester.pumpWidget(const KoLernenApp());
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
