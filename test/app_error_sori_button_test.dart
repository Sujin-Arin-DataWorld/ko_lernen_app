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

    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppError remains scroll-reachable at 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 420),
            textScaler: TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: AppError(
              message: 'Die Übung konnte nicht geladen werden.',
              onRetry: _noop,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Erneut versuchen'));
    expect(find.text('Erneut versuchen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
