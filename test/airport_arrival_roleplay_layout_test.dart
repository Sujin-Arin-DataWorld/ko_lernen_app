import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/quest_engines/satz_bauen_quest.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    ScenarioLoader.reset();
  });

  testWidgets('production airport roleplay paints its first learner turn', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late Scenario airport;
    await tester.runAsync(() async {
      await ScenarioLoader.load();
      airport = ScenarioLoader.byId('airport_arrival')!;
    });

    expect(airport.dialog.where((line) => line.speaker == 'user'), isNotEmpty);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: ScenarioPlayerScreen.preview(
          fixture: ScenarioPlayerPreviewFixture.action(
            scenario: airport,
            stage: ScenarioStage.rollenspiel,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SatzBauenQuest), findsOneWidget);
    expect(find.text('Ja, hier bitte.'), findsOneWidget);
    expect(
      tester.getSize(find.byType(SatzBauenQuest)).height,
      greaterThan(0),
      reason:
          'the production airport roleplay must not collapse to a blank page',
    );
  });
}
