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

    expect(find.byKey(const Key('app-loading-pulse')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppLoading applies motion preference changes at runtime', (
    tester,
  ) async {
    await tester.pumpWidget(_host(disableAnimations: false));
    expect(find.byKey(const Key('app-loading-pulse')), findsOneWidget);

    await tester.pumpWidget(_host(disableAnimations: true));
    await tester.pump();
    expect(find.byKey(const Key('app-loading-pulse')), findsNothing);

    await tester.pumpWidget(_host(disableAnimations: false));
    await tester.pump();
    expect(find.byKey(const Key('app-loading-pulse')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'AppLoading keeps its normal-motion visual out of a nested viewport when unbounded',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: false),
            child: Scaffold(body: SingleChildScrollView(child: AppLoading())),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 275));

      expect(find.byKey(const Key('app-loading-pulse')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppLoading),
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _host({required bool disableAnimations}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: const Scaffold(body: AppLoading()),
  ),
);
