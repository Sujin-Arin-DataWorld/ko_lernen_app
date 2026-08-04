import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/app_loading.dart';

void main() {
  testWidgets('AppLoading renders a static visual when motion is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: AppLoading()),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(AppLoading),
        matching: find.byType(AnimatedBuilder),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
