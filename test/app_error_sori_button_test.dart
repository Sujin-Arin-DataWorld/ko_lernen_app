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
}
