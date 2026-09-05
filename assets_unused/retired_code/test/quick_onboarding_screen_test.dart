import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/consent_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_start_screen.dart';
import 'package:ko_lernen_app/screens/quick_onboarding_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
  });

  testWidgets('legacy quick route starts at consent for a fresh learner', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();

    await tester.pumpWidget(_host());

    expect(find.byType(ConsentScreen), findsOneWidget);
    expect(find.byType(OnboardingStartScreen), findsNothing);
  });

  testWidgets('legacy quick route skips auto-intro after consent', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'kl_consent_accepted': true});
    await Storage.init();

    await tester.pumpWidget(_host());

    expect(find.byType(OnboardingStartScreen), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
  });
}

Widget _host() => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: const QuickOnboardingScreen(),
);
