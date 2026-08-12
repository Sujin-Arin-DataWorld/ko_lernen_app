import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/config/ux_preview_feature.dart';
import 'package:ko_lernen_app/main.dart' as app;
import 'package:ko_lernen_app/models/ux_preview_catalog.dart';
import 'package:ko_lernen_app/screens/character_selection_screen.dart';
import 'package:ko_lernen_app/screens/consent_screen.dart';
import 'package:ko_lernen_app/screens/course_mission_screen.dart';
import 'package:ko_lernen_app/screens/discover_screen.dart';
import 'package:ko_lernen_app/screens/first_voice_success_screen.dart';
import 'package:ko_lernen_app/screens/gye_screen.dart';
import 'package:ko_lernen_app/screens/gye_tab_screen.dart';
import 'package:ko_lernen_app/screens/hanok_world_screen.dart';
import 'package:ko_lernen_app/screens/home_screen.dart';
import 'package:ko_lernen_app/screens/learning_path_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_start_screen.dart';
import 'package:ko_lernen_app/screens/practice_hub_screen.dart';
import 'package:ko_lernen_app/screens/profile_screen.dart';
import 'package:ko_lernen_app/screens/sarangbang_screen.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/screens/ux_preview_app.dart';
import 'package:ko_lernen_app/screens/ux_preview_gallery_screen.dart';
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
    expect(registry.panelIds.toSet(), hasLength(20));

    final expectedTypes = <String, Type>{
      '01A': ConsentScreen,
      '01B': OnboardingStartScreen,
      '01C': FirstVoiceSuccessScreen,
      '01D': CharacterSelectionScreen,
      '02A': HomeScreen,
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
      '06B': HomeScreen,
      '06C': HomeScreen,
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
