import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/onboarding_start_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/card.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_consent_accepted': true});
    await Storage.init();
  });

  testWidgets('shows one purpose and one start point before the first scene', (
    tester,
  ) async {
    await tester.pumpWidget(_host());

    expect(find.text('What do you want to speak Korean for?'), findsOneWidget);
    expect(find.text('Open my first scene'), findsOneWidget);
    expect(_cardFor(tester, 'Getting around Korea').selected, isTrue);
    expect(_cardFor(tester, 'I am just starting').selected, isTrue);
  });

  testWidgets('changes the visible purpose without adding another CTA', (
    tester,
  ) async {
    await tester.pumpWidget(_host());

    await tester.tap(find.text('Talking with people'));
    await tester.pump();

    expect(_cardFor(tester, 'Talking with people').selected, isTrue);
    expect(_cardFor(tester, 'Getting around Korea').selected, isFalse);
    expect(find.text('Open my first scene'), findsOneWidget);
  });
}

Widget _host() => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: const OnboardingStartScreen(),
);

SoriCard _cardFor(WidgetTester tester, String text) => tester.widget<SoriCard>(
  find.ancestor(of: find.text(text), matching: find.byType(SoriCard)).first,
);
