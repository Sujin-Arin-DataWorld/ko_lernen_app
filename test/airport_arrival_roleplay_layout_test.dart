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
import 'package:ko_lernen_app/widgets/sori/mascot_pop.dart';
import 'package:ko_lernen_app/widgets/sori/scenario_write_after_roleplay_card.dart';
import 'package:ko_lernen_app/widgets/sori/tts_speed_control.dart';

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
    expect(find.byType(ScenarioWriteAfterRoleplayCard), findsNothing);
    expect(find.text('Ja, hier bitte.'), findsOneWidget);
    expect(
      tester.getSize(find.byType(SatzBauenQuest)).height,
      greaterThan(0),
      reason:
          'the production airport roleplay must not collapse to a blank page',
    );
  });

  testWidgets(
    'business roleplay keeps audio speed, word builder and CTA in one viewport',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late Scenario meeting;
      await tester.runAsync(() async {
        await ScenarioLoader.load();
        meeting = ScenarioLoader.byId('business_meeting_intro')!;
      });

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: ScenarioPlayerScreen.preview(
            fixture: ScenarioPlayerPreviewFixture.action(
              scenario: meeting,
              stage: ScenarioStage.rollenspiel,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(SatzBauenQuest), findsOneWidget);
      expect(find.byType(TtsSpeedControl), findsOneWidget);
      expect(find.byType(MascotPartner), findsNothing);
      expect(find.text('Weiter'), findsNothing);
      expect(find.textContaining('저는 김은수라고 합니다.'), findsOneWidget);
      expect(find.text('Erneut anhören'), findsOneWidget);
      expect(find.byKey(const ValueKey('quest-submit')), findsOneWidget);

      final buttonRect = tester.getRect(
        find.byKey(const ValueKey('quest-submit')),
      );
      final logicalHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(buttonRect.bottom, lessThanOrEqualTo(logicalHeight));
    },
  );

  testWidgets(
    'business roleplay remains usable at 308dp and 200 percent text',
    (tester) async {
      tester.view.physicalSize = const Size(308, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late Scenario meeting;
      await tester.runAsync(() async {
        await ScenarioLoader.load();
        meeting = ScenarioLoader.byId('business_meeting_intro')!;
      });

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: ScenarioPlayerScreen.preview(
            fixture: ScenarioPlayerPreviewFixture.action(
              scenario: meeting,
              stage: ScenarioStage.rollenspiel,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(TtsSpeedControl), findsOneWidget);
      expect(find.byKey(const ValueKey('quest-submit')), findsOneWidget);
      expect(
        tester.getRect(find.byKey(const ValueKey('quest-submit'))).bottom,
        lessThanOrEqualTo(700),
      );
    },
  );
}
