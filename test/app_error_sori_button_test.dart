import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

void main() {
  testWidgets('AppError uses SoriButton for its retry action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Scaffold(
          body: AppError(message: 'Offline', onRetry: () {}),
        ),
      ),
    );

    expect(find.byType(SoriButton), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('AppError stops idle animation when motion is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: AppError(message: 'Offline')),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(
      find.descendant(
        of: find.byType(AppError),
        matching: find.byType(AnimatedBuilder),
      ),
      findsNothing,
    );
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}
