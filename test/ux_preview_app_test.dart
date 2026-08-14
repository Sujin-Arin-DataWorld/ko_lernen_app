import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/config/ux_preview_feature.dart';
import 'package:ko_lernen_app/main.dart' as app;
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/course_mission_brief.dart';
import 'package:ko_lernen_app/models/ux_preview_catalog.dart';
import 'package:ko_lernen_app/screens/character_selection_screen.dart';
import 'package:ko_lernen_app/screens/consent_screen.dart';
import 'package:ko_lernen_app/screens/course_mission_screen.dart';
import 'package:ko_lernen_app/screens/discover_screen.dart';
import 'package:ko_lernen_app/screens/first_voice_success_screen.dart';
import 'package:ko_lernen_app/screens/gye_screen.dart';
import 'package:ko_lernen_app/screens/gye_tab_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_preview_screens.dart';
import 'package:ko_lernen_app/screens/onboarding_start_screen.dart';
import 'package:ko_lernen_app/screens/practice_hub_screen.dart';
import 'package:ko_lernen_app/screens/profile_screen.dart';
import 'package:ko_lernen_app/screens/quest_engines/hoerverstehen_quest.dart';
import 'package:ko_lernen_app/screens/sarangbang_screen.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/screens/ux_preview_app.dart';
import 'package:ko_lernen_app/screens/ux_preview_gallery_screen.dart';
import 'package:ko_lernen_app/screens/hanok_world_screen.dart';
import 'package:ko_lernen_app/screens/learning_path_screen.dart';
import 'package:ko_lernen_app/services/gye_weekly_promise_navigation.dart';

import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'gallery_sentinel': 'unchanged',
      'kl_user_level': 'b2',
      'kl_xp': 321,
    });
  });

  test('compile-time gate follows debug plus ENABLE_UX_GALLERY', () {
    const requested = bool.fromEnvironment(
      'ENABLE_UX_GALLERY',
      defaultValue: false,
    );
    expect(const UxPreviewFeatureGate().isEnabled, kDebugMode && requested);
  });

  test('registry covers the exact catalog once with production screens', () {
    const registry = UxPreviewRegistry();

    expect(
      registry.panelIds,
      uxPreviewPanels.map((panel) => panel.id).toList(),
    );
    expect(registry.panelIds.toSet(), hasLength(24));

    final expectedTypes = <String, Type>{
      '01A': ConsentScreen,
      '01B': OnboardingStartScreen,
      '01C': FirstVoiceSuccessScreen,
      '01D': CharacterSelectionScreen,
      '02A': SoriStageTodayPreviewScreen,
      '02B': CourseMissionScreen,
      '02C': ScenarioPlayerScreen,
      '02D': ScenarioPlayerScreen,
      '03A': HanokWorldScreen,
      '03B': HanokWorldScreen,
      '03C': SarangbangStudyScreen,
      '04A': PracticeHubScreen,
      '04B': DiscoverScreen,
      '04C': LearningPathScreen,
      '05A': GyeTabScreen,
      '05B': GyeScreen,
      '05C': GyeScreen,
      '06A': ProfileScreen,
      '06B': SoriStageTodayPreviewScreen,
      '06C': SoriStageTodayPreviewScreen,
      '07A': SoriStageTodayPreviewScreen,
      '07B': SoriStageLessonPreviewScreen,
      '07C': SoriStageRewardReceiptPreviewScreen,
      '07D': SoriStageJourneyPreviewScreen,
    };

    for (final panel in uxPreviewPanels) {
      expect(
        registry.buildPanel(panel).runtimeType,
        expectedTypes[panel.id],
        reason: panel.id,
      );
      expect(registry.routeFor(panel), '/ux_gallery/${panel.id}');
    }
  });

  test('02A-D share one quest-bearing exact less-spicy mission', () {
    const registry = UxPreviewRegistry();
    UxPreviewPanel panel(String id) =>
        uxPreviewPanels.singleWhere((item) => item.id == id);

    final mission = registry.buildPanel(panel('02B')) as CourseMissionScreen;
    final action = registry.buildPanel(panel('02C')) as ScenarioPlayerScreen;
    final result = registry.buildPanel(panel('02D')) as ScenarioPlayerScreen;

    final brief = mission.previewBrief!;
    final actionFixture = action.previewFixture!;
    final resultFixture = result.previewFixture!;
    final sceneStep = brief.visibleSteps.singleWhere(
      (step) => step.phase == CourseMissionPhase.scene,
    );
    final assessLink = sceneStep.link;

    expect(actionFixture.scenario.id, brief.targetScenario?.id);
    expect(resultFixture.scenario.id, brief.targetScenario?.id);
    expect(actionFixture.scenario.quests, isNotEmpty);
    expect(assessLink.contentId, actionFixture.scenario.id);
    expect(brief.unit.checkpointContentIds, contains(assessLink.contentKey));
    expect(assessLink.exactlyAssesses(brief.unit), isTrue);
    expect(actionFixture.missionStep?.link.id, assessLink.id);
    expect(resultFixture.missionStep?.link.id, assessLink.id);

    final verifiedResult = resultFixture.result;
    expect(verifiedResult?.isVerified, isTrue);
    expect(verifiedResult?.courseUnit?.id, brief.unit.id);
    expect(verifiedResult?.score, 1);
    expect(
      verifiedResult?.courseUnit?.canDo.de,
      'Ich kann höflich um weniger scharfes Essen bitten.',
    );
  });

  testWidgets('preview launch returns before production startup', (
    tester,
  ) async {
    var productionStarts = 0;
    Widget? launched;

    await app.launchKoLernenApp(
      featureGate: const UxPreviewFeatureGate(enabled: true),
      runApplication: (widget) => launched = widget,
      startProduction: () async => productionStarts++,
    );

    expect(productionStarts, 0);
    expect(launched, isA<UxPreviewApp>());
    // The mock preference contains b2. A null service value proves the
    // preview branch returned before Storage.init() attached SharedPreferences.
    expect(Storage.userLevelCode, isNull);
  });

  testWidgets('disabled gate delegates to the production startup', (
    tester,
  ) async {
    var productionStarts = 0;
    var previewRuns = 0;

    await app.launchKoLernenApp(
      featureGate: const UxPreviewFeatureGate(enabled: false),
      runApplication: (_) => previewRuns++,
      startProduction: () async => productionStarts++,
    );

    expect(productionStarts, 1);
    expect(previewRuns, 0);
  });

  testWidgets('app is German themed and opens registered production routes', (
    tester,
  ) async {
    await tester.pumpWidget(const UxPreviewApp());

    final context = tester.element(find.byType(UxPreviewGalleryScreen));
    expect(Localizations.localeOf(context), const Locale('de'));
    expect(Theme.of(context).brightness, Brightness.light);

    await tester.tap(find.byKey(const ValueKey('ux-preview-panel-01A')));
    await tester.pumpAndSettle();
    expect(find.byType(ConsentScreen), findsOneWidget);
    expect(
      ModalRoute.of(tester.element(find.byType(ConsentScreen)))?.settings.name,
      '/ux_gallery/01A',
    );
  });

  testWidgets(
    '02C renders the real listening question and checks without writes',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final before = await _preferencesSnapshot();

      await tester.pumpWidget(const UxPreviewApp(initialPanelId: '02C'));
      await tester.pump();

      expect(find.byType(HoerverstehenQuest), findsOneWidget);
      expect(find.text('Weniger scharf bestellen'), findsWidgets);
      expect(find.text('Was sagt die Person?'), findsOneWidget);
      expect(
        find.text('Tippe erst, wenn du die Bitte erkannt hast.'),
        findsOneWidget,
      );
      expect(find.text('매워요.'), findsOneWidget);
      expect(find.text('안 맵게 해 주세요.'), findsOneWidget);
      expect(find.text('감사합니다.'), findsOneWidget);

      final check = find.text('Meine Antwort prüfen');
      expect(check, findsOneWidget);
      expect(find.text('Weiter'), findsNothing);
      await tester.tap(find.text('안 맵게 해 주세요.'));
      await tester.pump();
      expect(
        tester
            .widget<SoriButton>(
              find.widgetWithText(SoriButton, 'Meine Antwort prüfen'),
            )
            .onTap,
        isNotNull,
      );
      expect(find.text('Weiter'), findsNothing);
      expect(await _preferencesSnapshot(), before);
      await tester.tap(check);
      await tester.pump(const Duration(milliseconds: 1250));

      expect(find.text('Weiter'), findsOneWidget);
      expect(await _preferencesSnapshot(), before);
      expect(Storage.userLevelCode, isNull);
    },
  );

  testWidgets(
    'representative actions stay inside the no-write preview boundary',
    (tester) async {
      final before = await _preferencesSnapshot();

      for (final entry in const [
        (
          id: '03C',
          key: 'sarangbang-furnish-action',
          route: '/sarangbang/furnish',
        ),
        (id: '04A', key: 'practice-purpose-review', route: '/review'),
        (id: '04B', key: 'discover-priority-book', route: '/book'),
        (id: '04C', key: 'path-current-mission', route: '/course/mission'),
      ]) {
        await tester.pumpWidget(UxPreviewApp(initialPanelId: entry.id));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        final action = find.byKey(ValueKey(entry.key));
        await tester.scrollUntilVisible(
          action,
          240,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(action);
        await tester.pump();
        await tester.tap(action);
        await tester.pumpAndSettle();

        expect(
          find.textContaining(entry.route),
          findsOneWidget,
          reason: entry.id,
        );
        expect(await _preferencesSnapshot(), before, reason: entry.id);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }

      await tester.pumpWidget(const UxPreviewApp(initialPanelId: '01B'));
      final existingLearner = find.text('Ich kann schon etwas');
      await tester.scrollUntilVisible(
        existingLearner,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(existingLearner);
      await tester.pump();
      await tester.tap(existingLearner);
      await tester.pump();
      await tester.ensureVisible(find.text('Level wählen'));
      await tester.tap(find.text('Level wählen'));
      await tester.pump();
      expect(await _preferencesSnapshot(), before);

      await tester.pumpWidget(const UxPreviewApp(initialPanelId: '05B'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      tester
          .widget<SoriButton>(find.byKey(const ValueKey('gye-promise-primary')))
          .onTap
          ?.call();
      await tester.pump();
      expect(await _preferencesSnapshot(), before);

      await tester.pumpWidget(const UxPreviewApp(initialPanelId: '06A'));
      await tester.pump();
      final export = find.byKey(const ValueKey('profile-learning-data-export'));
      await tester.scrollUntilVisible(
        export,
        240,
        scrollable: find.byType(Scrollable).first,
      );
      tester
          .widget<ListTile>(
            find.descendant(of: export, matching: find.byType(ListTile)),
          )
          .onTap
          ?.call();
      await tester.pump();
      expect(await _preferencesSnapshot(), before);
    },
  );

  testWidgets('02B preview renders the fixed three-step mission', (
    tester,
  ) async {
    await tester.pumpWidget(const UxPreviewApp(initialPanelId: '02B'));
    await tester.pump();

    expect(find.text('Höre die Situation'), findsOneWidget);
    expect(find.text('Baue deinen Satz'), findsOneWidget);
    expect(find.text('Sprich in der Szene'), findsOneWidget);
    expect(find.text('1 Min.'), findsWidgets);
    expect(find.text('2 Min.'), findsOneWidget);
  });

  testWidgets('06A preview owns deterministic no-companion learning data', (
    tester,
  ) async {
    await tester.pumpWidget(const UxPreviewApp(initialPanelId: '06A'));
    await tester.pump();

    expect(find.text('Reise nach Korea'), findsWidgets);
    expect(find.textContaining('A1'), findsWidgets);
    expect(find.text('Keine Lernbegleitung'), findsOneWidget);
  });

  test(
    '05B fixture resolves the exact assessed scene with typed provenance',
    () async {
      const registry = UxPreviewRegistry();
      final panel = uxPreviewPanels.firstWhere((item) => item.id == '05B');
      final screen = registry.buildPanel(panel) as GyeScreen;
      final meta = await screen.metaUpdates!.first;
      final today = await screen.loadTodaySnapshot!();
      final resolution = await screen.resolvePromiseNavigation!(meta!, today);

      expect(screen.readOnlyPreview, isTrue);
      expect(screen.onOpenSafeMessage, isNotNull);
      expect(screen.onOpenReaction, isNotNull);
      expect(resolution.kind, GyePromiseNavigationKind.eligibleScene);
      expect(resolution.destination?.route, '/scenario');
      final context =
          resolution.destination?.arguments as CoursePracticeContext;
      expect(context.courseUnitId, 'a1_04_order_request_object');
      expect(context.initialContentId, 'bunshik_tteokbokki');
      expect(context.contentLinkId, 'link:e6a9f1197b48c79f58655c9a');
    },
  );

  testWidgets('05B-C show an exact scene and a reactable feed without writes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final before = await _preferencesSnapshot();

    await tester.pumpWidget(const UxPreviewApp(initialPanelId: '05B'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Meine heutige Szene öffnen'), findsOneWidget);
    expect(find.text('Zu Heute'), findsNothing);
    expect(
      find.text(
        'Kontoänderung läuft. Gruppenaktionen sind geschützt pausiert und '
        'werden nach Abschluss wieder verfügbar.',
      ),
      findsNothing,
    );
    expect(
      tester
          .widget<SoriButton>(find.byKey(const ValueKey('gye-promise-primary')))
          .onTap,
      isNotNull,
    );
    expect(await _preferencesSnapshot(), before);

    await tester.pumpWidget(const UxPreviewApp(initialPanelId: '05C'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final safeMessage = find.widgetWithText(
      SoriButton,
      'Eine sichere Nachricht senden',
    );
    await tester.scrollUntilVisible(
      safeMessage,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    tester.widget<SoriButton>(safeMessage).onTap!.call();
    await tester.pump();

    final parent = find.text('Min hat eine Quest abgeschlossen');
    await tester.scrollUntilVisible(
      parent,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(parent, findsOneWidget);
    final reactionAction = find.byTooltip('Reagieren');
    expect(reactionAction, findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/stickers/tiger_clap.png',
      ),
      findsOneWidget,
    );
    tester
        .widget<IconButton>(
          find.ancestor(of: reactionAction, matching: find.byType(IconButton)),
        )
        .onPressed!
        .call();
    await tester.pump();
    expect(await _preferencesSnapshot(), before);
    expect(Storage.userLevelCode, isNull);
  });

  testWidgets('06B preview uses the current Sori Stage Today surface', (
    tester,
  ) async {
    await tester.pumpWidget(const UxPreviewApp(initialPanelId: '06B'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('Ein Satz. Ein Bauteil.'), findsOneWidget);
    expect(find.text('Im Café bestellen'), findsWidgets);
  });

  for (final panel in uxPreviewPanels) {
    testWidgets(
      '${panel.id} renders at 308dp and 1.3x without startup writes',
      (tester) async {
        tester.view.physicalSize = const Size(308, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final before = await _preferencesSnapshot();

        await tester.pumpWidget(
          UxPreviewApp(
            initialPanelId: panel.id,
            textScaler: const TextScaler.linear(1.3),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        expect(find.byType(Scaffold), findsWidgets, reason: panel.id);
        expect(tester.takeException(), isNull, reason: panel.id);
        expect(await _preferencesSnapshot(), before, reason: panel.id);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 50));
      },
    );
  }

  for (final viewport in const <Size>[Size(390, 844), Size(1024, 1366)]) {
    testWidgets('section representatives fit ${viewport.width}dp', (
      tester,
    ) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final id in const ['01B', '02B', '03B', '04C', '05B', '06A']) {
        await tester.pumpWidget(UxPreviewApp(initialPanelId: id));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        expect(tester.takeException(), isNull, reason: '$id @ $viewport');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 50));
      }
    });
  }
}

Future<Map<String, Object?>> _preferencesSnapshot() async {
  final preferences = await SharedPreferences.getInstance();
  return {for (final key in preferences.getKeys()) key: preferences.get(key)};
}
