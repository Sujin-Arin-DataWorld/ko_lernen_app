import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/learning_phase_catalog.dart';
import 'package:ko_lernen_app/services/phase_task_catalog.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/phase_task_panel.dart';

PhaseAttemptEvidence _evidence(PhaseTask task, {bool assessment = true}) =>
    PhaseAttemptEvidence.fromJson({
      'attemptId': 'a-${task.id}',
      'phaseId': task.phaseId,
      'taskId': task.id,
      'contentHash': task.contentHash,
      'contentRevision': task.contentRevision,
      'rubricVersion': task.rubricVersion,
      'minimumScore': task.minimumScore,
      'evaluatorVersion': PhaseTaskResult.evaluatorVersion,
      'mode': assessment ? 'assessment' : 'practice',
      'score': 1.0,
      'passedCriterionIds': <String>[],
      'occurredAt': '2026-01-01T00:00:00Z',
    });

Future<void> _pump(WidgetTester tester, String phaseId, String locale) async {
  tester.view.physicalSize = const Size(800, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  // Real asset I/O must finish outside the fake-async test zone.
  await tester.runAsync(() async {
    await LearningPhaseCatalog.load();
    await PhaseTaskCatalog.load();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: Locale(locale),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: Scaffold(
        body: SingleChildScrollView(child: PhaseTaskPanel(phaseId: phaseId)),
      ),
    ),
  );
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LearningPhaseCatalog.resetForTesting();
    PhaseTaskCatalog.resetForTesting();
    CurriculumCatalog.reset();
    rootBundle.clear();
  });

  testWidgets('KP01 shows four ordered steps with their tasks grouped', (
    tester,
  ) async {
    await _pump(tester, 'KP01', 'de');
    final phases = await LearningPhaseCatalog.load();
    final steps = phases.first.steps;
    expect(steps.map((s) => s.id), ['KP01.1', 'KP01.2', 'KP01.3', 'KP01.4']);
    double top(Finder f) => tester.getTopLeft(f).dy;
    var previous = -1.0;
    for (final (i, step) in steps.indexed) {
      final header = find.byKey(ValueKey('phase-step-${step.id}'));
      expect(header, findsOneWidget);
      expect(find.text('${i + 1}. ${step.title.de}'), findsOneWidget);
      expect(top(header), greaterThan(previous));
      previous = top(header);
      for (final id in step.taskIds) {
        final card = find.byKey(ValueKey('phase-task-$id'));
        expect(card, findsOneWidget);
        expect(top(card), greaterThan(previous));
        previous = top(card);
      }
    }
    expect(find.byKey(const ValueKey('phase-next-step')), findsOneWidget);
    expect(find.textContaining('Nächster Schritt'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  test(
    'earlier KP01 task records still complete their step after the split',
    () async {
      final catalog = await PhaseTaskCatalog.load();
      final phase = (await LearningPhaseCatalog.load()).first;
      final byId = {for (final t in catalog.forPhase('KP01')) t.id: t};
      final first = phase.steps.first;
      final history = {
        for (final id in first.taskIds)
          id: _evidence(byId[id]!, assessment: false),
      };
      // Speaking/practice-only tasks count once a scored attempt exists.
      final done = phaseStepCompletion(phase.steps, byId, history);
      expect(done.first, isTrue);
      expect(done.skip(1), everyElement(isFalse));
      history.remove(first.taskIds.last);
      expect(phaseStepCompletion(phase.steps, byId, history).first, isFalse);
    },
  );
}
