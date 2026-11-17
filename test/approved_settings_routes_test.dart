import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/app_shell.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/learning_journey.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/approved_chrome_assets.dart';
import 'package:ko_lernen_app/widgets/sori/settings_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/sori_stage_pump.dart';

import 'support/real_fonts.dart';

void main() {
  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  setUp(() async {
    LearningJourneyObserver.shared.cancel();
    CourseProgressService.shared.resetForTesting();
    Storage.resetForTesting();
    AppShell.requestedStageTab.value = -1;
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_tut_home_tour': true,
      'kl_tut_gye_tab': true,
    });
    await Storage.init();
  });

  testWidgets(
    'all five root tabs open settings through the approved gold gear',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final navigator = GlobalKey<NavigatorState>();
      var settingsVisits = 0;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: const AppShell(),
          onGenerateRoute: (settings) {
            expect(settings.name, '/settings');
            settingsVisits++;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) =>
                  const Scaffold(body: Text('settings destination')),
            );
          },
        ),
      );
      await pumpSoriStage(tester);
      const tabs = ['Today', 'Learn', 'Games', 'Hanok', 'Gye'];
      for (var index = 0; index < tabs.length; index++) {
        if (index > 0) {
          await tester.tap(find.byTooltip(tabs[index]).last);
          await pumpSoriStage(tester);
        }
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          index,
        );
        final button = find.byType(SoriSettingsButton);
        expect(button, findsOneWidget, reason: tabs[index]);
        final image = tester.widget<ApprovedChromeImage>(
          find.descendant(
            of: button,
            matching: find.byType(ApprovedChromeImage),
          ),
        );
        expect(image.asset, ApprovedChromeAssets.settings, reason: tabs[index]);
        final size = tester.getSize(button);
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
        await tester.tap(button);
        await pumpSoriStage(tester);
        expect(find.text('settings destination'), findsOneWidget);
        expect(settingsVisits, index + 1);
        navigator.currentState!.pop();
        await pumpSoriStage(tester);
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          index,
          reason: 'Returning from settings preserves ${tabs[index]}.',
        );
      }
      expect(tester.takeException(), isNull);
    },
  );
}
