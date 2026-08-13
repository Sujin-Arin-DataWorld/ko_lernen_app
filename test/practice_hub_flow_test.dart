import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/config/sori_stage_feature.dart';
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
    tester.view.physicalSize = const Size(308, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: MediaQuery.withClampedTextScaling(
          minScaleFactor: 1.3,
          maxScaleFactor: 1.3,
          child: const PracticeHubScreen.preview(previewDueCount: 12),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Ohne Tagesmission'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Üben')),
      findsOneWidget,
    );
    expect(find.text('Was willst du gerade festigen?'), findsOneWidget);
    expect(
      find.text('Wähle eine Absicht, nicht erst ein Spiel.'),
      findsOneWidget,
    );
    expect(find.text('Fällige Wörter wiederholen'), findsOneWidget);
    expect(find.text('12 Wörter warten auf Kontext'), findsOneWidget);
    expect(find.text('Etwas gezielt üben'), findsOneWidget);
    expect(find.text('Aussprache, Grammatik oder Schreiben'), findsOneWidget);
    // 2026-08-12: "Frei spielen" → "Spielen" (Jin — 굳이 길게 쓸 이유가 없다).
    expect(find.text('Spielen'), findsOneWidget);
    expect(find.text('Wortkette, Buchstaben, kurze Spiele'), findsOneWidget);
    expect(find.text('Meine Wörter öffnen'), findsOneWidget);
    expect(find.text('Gespeicherte Wörter und Bücher'), findsOneWidget);
    expect(find.text('Dein Lernraum'), findsNothing);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    final allActivities = find.byKey(const ValueKey('practice-all-activities'));
    await tester.scrollUntilVisible(
      allActivities,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(allActivities);
    await tester.pump();
    await tester.tap(allActivities);
    await tester.pump();

    expect(find.text('Spielen'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Deine Wörter'),
      360,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Deine Wörter'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Dein Lernraum'),
      360,
      scrollable: find.byType(Scrollable).first,
    );
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
        home: const AppShell(featureGate: SoriStageFeatureGate(enabled: false)),
      ),
    );

    final navigation = tester.widget<NavigationBar>(find.byType(NavigationBar));
    final practice = navigation.destinations[1] as NavigationDestination;
    expect(practice.label, 'Üben');
    await tester.pump(const Duration(seconds: 1));
  });
}
