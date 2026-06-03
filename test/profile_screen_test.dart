import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/consent_screen.dart';
import 'package:ko_lernen_app/screens/profile_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

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

  testWidgets('ProfileScreen baut im Gast-Modus ohne Firebase fehlerfrei',
      (tester) async {
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
