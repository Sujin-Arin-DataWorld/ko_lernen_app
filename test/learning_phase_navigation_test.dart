import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/features/onboarding_v2/first_run_runtime.dart';
import 'package:ko_lernen_app/main.dart';
import 'package:ko_lernen_app/screens/learning_phases_screen.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/screens/splash_screen.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/learning_phase_catalog.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_finish_coordinator.dart';

import 'support/sori_speech_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    CourseProgressService.shared.resetForTesting();
    LearningPhaseCatalog.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_tut_scenario': true});
    await Storage.init();
    DefaultVocabPackFinishOperations.initializeRecovery();
  });

  testWidgets(
    'real Phase routes open related practice without mission provenance',
    (tester) async {
      stubSoriSpeech();
      // This test covers navigation with real bundled data, not cold loading.
      // Let catalog compute isolates finish outside the widget fake clock.
      final phases = await tester.runAsync(LearningPhaseCatalog.load);
      expect(phases, hasLength(30));
      await tester.pumpWidget(
        KoLernenApp(
          splashDisplayDuration: Duration.zero,
          firstRunCoordinator: FirstRunRuntime.createCoordinator(),
        ),
      );
      for (var frame = 0; frame < 30; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(SplashScreen).evaluate().isEmpty) break;
      }
      expect(find.byType(SplashScreen), findsNothing);
      final savedMastery = Storage.courseMasterySnapshotRawJson;
      expect(PackCompletionStorage.invalid, isFalse);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pushNamed('/course/phases', arguments: 'a2');
      await _pumpUntil(tester, find.byType(LearningPhasesScreen));
      final phaseCard = find.byKey(const ValueKey('phase-card-KP05'));
      await _pumpUntil(tester, phaseCard);
      expect(find.byKey(const ValueKey('phase-card-KP01')), findsNothing);
      await tester.scrollUntilVisible(
        phaseCard,
        250,
        scrollable: find
            .descendant(
              of: find.byType(LearningPhasesScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(phaseCard);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(phaseCard);
      await _pumpUntil(tester, find.byType(LearningPhaseDetailScreen));
      final detail = tester.widget<LearningPhaseDetailScreen>(
        find.byType(LearningPhaseDetailScreen),
      );
      expect(detail.phase.id, 'KP05');
      expect(Storage.courseMasterySnapshotRawJson, savedMastery);

      final unit = detail.phase.practiceUnits.first;
      final mission = find.byKey(ValueKey('phase-mission-${unit.id}'));
      await tester.scrollUntilVisible(
        mission,
        250,
        scrollable: find
            .descendant(
              of: find.byType(LearningPhaseDetailScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(mission);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(mission);
      await _pumpUntil(tester, find.byType(ScenarioPlayerScreen));
      final scenario = tester.widget<ScenarioPlayerScreen>(
        find.byType(ScenarioPlayerScreen),
      );
      expect(scenario.scenarioId, learningPhaseScenarioId(unit));
      expect(scenario.courseContext, isNull);
      expect(tester.takeException(), isNull);
      // Route and entry evidence only: no lesson completion or audio claim.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 400));
    },
  );
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var frame = 0; frame < 100; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsOneWidget);
}
