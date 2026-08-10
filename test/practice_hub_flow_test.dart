import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/practice_hub_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_tut_practice_hub': true});
    await Storage.init();
  });

  testWidgets('separates review, focused practice, free play, and my space', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const PracticeHubScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Was möchtest du gerade festigen?'), findsOneWidget);
    expect(find.text('Fällige Wörter wiederholen'), findsNWidgets(2));
    expect(find.text('Etwas gezielt üben'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Frei spielen'), 360);
    expect(find.text('Frei spielen'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Deine Wörter'), 360);
    expect(find.text('Deine Wörter'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Dein Lernraum'), 360);
    expect(find.text('Dein Lernraum'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
