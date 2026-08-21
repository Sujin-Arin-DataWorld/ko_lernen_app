import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/profile_screen.dart';
import 'package:ko_lernen_app/services/account/account_ui_operations.dart';
import 'package:ko_lernen_app/services/account/cloud_backup_deletion.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  testWidgets(
    'profile settings action is localized, 48dp, and keeps its route',
    (tester) async {
      final routes = <String?>[];

      Future<void> pumpProfile(Locale locale) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            locale: locale,
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.localizationsDelegates,
            onGenerateRoute: (settings) {
              routes.add(settings.name);
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => const SizedBox.shrink(),
              );
            },
            home: const ProfileScreen(
              account: AuthAccountSnapshot(
                providers: AuthProviderState(
                  isGoogleLinked: false,
                  isAppleLinked: false,
                ),
              ),
              enableCoach: false,
            ),
          ),
        );
        await tester.pump();
      }

      await pumpProfile(const Locale('en'));
      final englishAction = find.byTooltip('Settings');
      expect(englishAction, findsOneWidget);
      expect(tester.getSize(englishAction).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(englishAction).height, greaterThanOrEqualTo(48));
      await tester.tap(englishAction);
      await tester.pump();
      expect(routes, contains('/settings'));

      await pumpProfile(const Locale('de'));
      expect(find.byTooltip('Einstellungen'), findsOneWidget);
    },
  );

  testWidgets('profile remains reachable across the locked DE/EN matrix', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final journalState = ValueNotifier<CloudBackupDeletionJournalState>(
      CloudBackupDeletionJournalState.clear,
    );
    addTearDown(journalState.dispose);
    const cases = <({Size size, double textScale})>[
      (size: Size(320, 640), textScale: 2),
      (size: Size(360, 400), textScale: 1),
      (size: Size(390, 844), textScale: 1.3),
      (size: Size(720, 1024), textScale: 1.3),
      (size: Size(1280, 900), textScale: 1.3),
    ];

    for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
      for (final testCase in cases) {
        tester.view.physicalSize = testCase.size;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            locale: locale,
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.localizationsDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: true,
                textScaler: TextScaler.linear(testCase.textScale),
              ),
              child: child!,
            ),
            home: ProfileScreen.preview(
              accountOperations: const ProductionAccountUiOperations(),
              cloudDataDeletionJournalState: journalState,
              loadGyeMetas: () async => const [],
            ),
          ),
        );
        await tester.pump();

        final t = AppL10n.of(tester.element(find.byType(ProfileScreen)));
        final settingsAction = find.byTooltip(t.settingsTitle);
        expect(settingsAction, findsOneWidget);
        expect(
          tester.getSize(settingsAction),
          const Size.square(kMinInteractiveDimension),
        );
        final finalAction = find.text(t.profileViewStats);
        await tester.scrollUntilVisible(
          finalAction,
          240,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(finalAction);
        await tester.pump();
        expect(finalAction, findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }
  });

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

    await tester.scrollUntilVisible(
      find.textContaining('reviewed before anything is replaced'),
      240,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      find.textContaining('reviewed before anything is replaced'),
      findsOneWidget,
    );
  });
}
