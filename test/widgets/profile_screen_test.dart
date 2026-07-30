import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/profile_screen.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  testWidgets('English profile exposes localized safe account explanation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const ProfileScreen(
          account: AuthAccountSnapshot(
            providers: AuthProviderState(
              isGoogleLinked: false,
              isAppleLinked: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.textContaining('reviewed before anything is replaced'),
      findsOneWidget,
    );
  });
}
