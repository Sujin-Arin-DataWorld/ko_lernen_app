import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/app_shell.dart';
import 'package:ko_lernen_app/screens/practice_hub_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_tut_practice_hub': true,
      'kl_tut_home_tour': true,
    });
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
        home: const PracticeHubScreen.preview(),
      ),
    );
    await tester.pump();

    expect(find.text('Was möchtest du gerade festigen?'), findsNWidgets(2));
    expect(find.text('Fällige Wörter wiederholen'), findsOneWidget);
    expect(find.text('Etwas gezielt üben'), findsOneWidget);
    expect(find.text('Dein Lernraum'), findsNothing);

    final allActivities = find.byKey(const ValueKey('practice-all-activities'));
    await tester.scrollUntilVisible(
      allActivities,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(allActivities);
    await tester.pump();

    await tester.scrollUntilVisible(find.text('Frei spielen'), 360);
    expect(find.text('Frei spielen'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Deine Wörter'), 360);
    expect(find.text('Deine Wörter'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Dein Lernraum'), 360);
    expect(find.text('Dein Lernraum'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('04A labels the primary tab Üben', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const AppShell(),
      ),
    );

    final navigation = tester.widget<NavigationBar>(find.byType(NavigationBar));
    final practice = navigation.destinations[1] as NavigationDestination;
    expect(practice.label, 'Üben');
    await tester.pump(const Duration(seconds: 1));
  });
}
