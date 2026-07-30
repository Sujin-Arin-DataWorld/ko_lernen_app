import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/consent_screen.dart';
import 'package:ko_lernen_app/screens/profile_screen.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

/// Smoke-Test für den Profil-Hub (Tier 1 — 2026-06-03).
///
/// Ohne Firebase liefert [AuthService] sichere Defaults
/// (`isGoogleLinked == false`), also muss die Gast-Karte mit dem Sichern-CTA
/// rendern — ohne Build-Exception. (Mascot `animate: true` ist eine
/// Endlos-Animation → `pumpAndSettle` würde hängen; daher endliche `pump`.)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  testWidgets('ProfileScreen baut im Gast-Modus ohne Firebase fehlerfrei', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const ProfileScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Gast-Karte → Sichern-CTA (settingsCloudSignInPrompt, de).
    expect(find.text('Mit Google sichern'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('pending cloud deletion disables connected-account sign out', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pending = ValueNotifier<bool>(true);
    addTearDown(pending.dispose);

    await tester.pumpWidget(
      _wrap(
        ProfileScreen(
          account: const AuthAccountSnapshot(
            providers: AuthProviderState(
              isGoogleLinked: true,
              isAppleLinked: false,
            ),
            displayName: 'Durable learner',
          ),
          cloudDataDeletionPending: pending,
        ),
      ),
    );
    await tester.pump();

    final signOut = tester.widget<SoriButton>(
      find.widgetWithText(SoriButton, 'Abmelden'),
    );
    expect(signOut.onTap, isNull);
  });

  testWidgets('ConsentScreen (Tier 0) baut fehlerfrei', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const ConsentScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Zustimmen-CTA (consentAgreeCta, de) muss rendern.
    expect(find.text('Zustimmen & loslegen'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('ConsentScreen Opt-in: Analytics/Crash default AUS, '
      'nur Angekreuztes wird persistiert (TTDSG §25)', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Preview gesehen + Level offen → _accept navigiert zur Level-Auswahl
    // (AppShell würde TigerStage-Timer hinterlassen → Test-Invariante).
    await Storage.setIntroPreviewSeen();

    await tester.pumpWidget(_wrap(const ConsentScreen()));
    await tester.pump();

    // Default: beide Checkboxen aus, nichts persistiert.
    expect(Storage.analyticsConsent, isFalse);
    expect(Storage.crashConsent, isFalse);
    final boxes = find.byType(Checkbox);
    expect(boxes, findsNWidgets(2));
    expect(tester.widget<Checkbox>(boxes.at(0)).value, isFalse);
    expect(tester.widget<Checkbox>(boxes.at(1)).value, isFalse);

    // Nur Analytics ankreuzen, dann zustimmen.
    await tester.tap(boxes.at(0));
    await tester.pump();
    await tester.tap(find.text('Zustimmen & loslegen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(Storage.consentAccepted, isTrue);
    expect(Storage.analyticsConsent, isTrue);
    expect(Storage.crashConsent, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    // SoriEntrance-Stagger-Timer der Zielseite ausklingen lassen
    // (one-shot Future.delayed, nach dispose no-op).
    await tester.pump(const Duration(seconds: 2));
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: child,
  );
}
