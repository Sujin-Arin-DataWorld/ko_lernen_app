import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/features/onboarding_v2/first_run_runtime.dart';
import 'package:ko_lernen_app/main.dart';
import 'package:ko_lernen_app/screens/app_shell.dart';
import 'package:ko_lernen_app/screens/learning_phases_screen.dart';
import 'package:ko_lernen_app/screens/phase_task_screen.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_catalog_screen.dart';
import 'package:ko_lernen_app/screens/vocab_packs_screen.dart';
import 'package:ko_lernen_app/services/locale_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_finish_coordinator.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final localeCode = _localeFromRoute(
    ui.PlatformDispatcher.instance.defaultRouteName,
  );

  testWidgets('capture production learning routes for App Store', (
    tester,
  ) async {
    final selectedLocale = localeCode;
    if (selectedLocale == null) {
      throw StateError(
        'Expected /app-store-screenshots/de or /app-store-screenshots/en.',
      );
    }

    // The workflow installs this app on a newly created simulator. Clear its
    // sandbox once more so screenshots can never inherit a previous run's
    // learner data, then configure a local returning guest in the requested
    // language. No backend, progress, reward, or purchase state is fabricated.
    final preferences = await SharedPreferences.getInstance();
    expect(await preferences.clear(), isTrue);
    expect(await preferences.setBool('kl_consent_accepted', true), isTrue);
    expect(await preferences.setBool('kl_onboarding_completed', true), isTrue);
    expect(await preferences.setBool('kl_tut_scenario', true), isTrue);
    expect(await preferences.setInt('kl_session_count', 5), isTrue);
    expect(await preferences.setString('kl_locale', selectedLocale), isTrue);

    Storage.resetForTesting();
    await Storage.init();
    await setLocale(Locale(selectedLocale));
    DefaultVocabPackFinishOperations.initializeRecovery();

    await tester.pumpWidget(
      KoLernenApp(
        splashDisplayDuration: Duration.zero,
        firstRunCoordinator: FirstRunRuntime.createCoordinator(),
      ),
    );
    await _waitFor(tester, find.byType(AppShell));

    AppShell.openStageTab(1);
    await _waitFor(tester, find.byType(SoriStageCatalogScreen));
    await _waitForNoLoading(tester);
    await _capture(binding, tester, '01-learn-catalog');

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/course/phases', arguments: 'A1');
    await _waitFor(tester, find.byType(LearningPhasesScreen));
    await _waitFor(tester, find.byKey(const ValueKey('phase-card-KP01')));
    await _capture(binding, tester, '02-learning-phases');

    navigator.pushNamed(
      '/learning-phase/task',
      arguments: const PhaseTaskRoute('KP01', 'KP01:reading:01'),
    );
    await _waitFor(tester, find.byType(PhaseTaskScreen));
    await _waitFor(
      tester,
      find.byKey(const ValueKey('phase-task-submit')),
    );
    await _capture(binding, tester, '03-phase-task');

    navigator.pushNamed('/vocab');
    await _waitFor(tester, find.byType(VocabPacksScreen));
    await _waitForNoLoading(tester);
    await _capture(binding, tester, '04-vocabulary-packs');

    navigator.pushNamed('/scenario', arguments: 'airport_arrival');
    await _waitFor(tester, find.byType(ScenarioPlayerScreen));
    await _waitFor(
      tester,
      find.byKey(const ValueKey('scenario-intro-art-image')),
    );
    await _capture(binding, tester, '05-real-life-scenario');
  });
}

String? _localeFromRoute(String route) {
  final match = RegExp(r'^/app-store-screenshots/(de|en)$').firstMatch(route);
  return match?.group(1);
}

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 300; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 500));
      return;
    }
  }
  expect(finder, findsOneWidget);
}

Future<void> _waitForNoLoading(WidgetTester tester) async {
  for (var attempt = 0; attempt < 300; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byType(AppLoading).evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 500));
      return;
    }
  }
  expect(find.byType(AppLoading), findsNothing);
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 600));
  expect(tester.takeException(), isNull);
  final bytes = await binding.takeScreenshot(name);
  expect(bytes, isNotEmpty);
}
