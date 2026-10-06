import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/c_profile_overview_screen.dart';
import 'package:ko_lernen_app/screens/c_settings_hub_screen.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';

void main() {
  Widget app(Widget home, List<RouteSettings> routes) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    onGenerateRoute: (settings) {
      routes.add(settings);
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const SizedBox.shrink(),
      );
    },
    home: home,
  );

  testWidgets(
    'C settings hub exposes all eight approved groups and typed focus routes',
    (tester) async {
      final routes = <RouteSettings>[];
      await tester.pumpWidget(app(const CSettingsHubScreen(), routes));
      await tester.pump();

      const ids = [
        'profile',
        'language-learning',
        'sound-motion',
        'reminders',
        'account',
        'privacy',
        'downloads',
        'help',
      ];
      for (final id in ids) {
        final finder = find.byKey(ValueKey('c-settings-hub-$id'));
        expect(finder, findsOneWidget, reason: 'missing C settings row $id');
      }

      final language = find.byKey(
        const ValueKey('c-settings-hub-language-learning'),
      );
      await tester.ensureVisible(language);
      await tester.tap(language);
      await tester.pump();
      expect(routes.last.name, '/settings/detail');
      expect(routes.last.arguments, SettingsInitialFocus.language);
    },
  );

  testWidgets('C profile guest surface keeps approved entry actions', (
    tester,
  ) async {
    final routes = <RouteSettings>[];
    await tester.pumpWidget(
      app(
        const CProfileOverviewScreen(
          account: AuthAccountSnapshot(
            providers: AuthProviderState(
              isGoogleLinked: false,
              isAppleLinked: false,
            ),
          ),
          previewMascot: MascotKind.tiger,
          previewLevel: 'a2',
          previewGoal: 'Alltag & Reise',
        ),
        routes,
      ),
    );
    await tester.pump();

    for (final id in const [
      'goal',
      'start',
      'companion',
      'gye',
      'data',
      'privacy',
    ]) {
      expect(find.byKey(ValueKey('c-profile-$id')), findsOneWidget);
    }
    expect(find.text('A2'), findsOneWidget);

    final start = find.byKey(const ValueKey('c-profile-start'));
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pump();
    expect(routes.last.name, '/settings/detail');
    expect(routes.last.arguments, SettingsInitialFocus.courseStart);
  });
}
