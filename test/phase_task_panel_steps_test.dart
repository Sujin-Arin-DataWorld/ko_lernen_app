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

PhaseAttemptEvidence _evidence(
  PhaseTask task, {
  bool assessment = true,
  double? score = 1.0,
}) => PhaseAttemptEvidence.fromJson({
  'attemptId': 'a-${task.id}',
  'phaseId': task.phaseId,
  'taskId': task.id,
  'contentHash': task.contentHash,
  'contentRevision': task.contentRevision,
  'rubricVersion': task.rubricVersion,
  'minimumScore': task.minimumScore,
  'evaluatorVersion': PhaseTaskResult.evaluatorVersion,
  'mode': assessment ? 'assessment' : 'practice',
  'score': score,
  'passedCriterionIds': <String>[],
  'occurredAt': '2026-01-01T00:00:00Z',
});

Future<void> _pump(
  WidgetTester tester,
  String phaseId,
  String locale, {
  List<LearningPhaseStep> steps = const [],
}) async {
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
        body: SingleChildScrollView(
          child: PhaseTaskPanel(phaseId: phaseId, steps: steps),
        ),
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
    final phases = (await tester.runAsync(LearningPhaseCatalog.load))!;
    final steps = phases.first.steps;
    await _pump(tester, 'KP01', 'de', steps: steps);
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

  group('step completion', () {
    late Map<String, PhaseTask> byId;
    late LearningPhase phase;

    setUp(() async {
      final catalog = await PhaseTaskCatalog.load();
      phase = (await LearningPhaseCatalog.load()).first;
      byId = {for (final t in catalog.forPhase('KP01')) t.id: t};
    });

    // The strongest honest record for a task: a passed assessment when the
    // task can be machine-scored, otherwise an unscored submission.
    PhaseAttemptEvidence completing(PhaseTask task) {
      final unscorable =
          task.skill == 'speaking' ||
          task.assessment.questions.any((q) => q.kind == 'freeText');
      final e = unscorable ? _evidence(task, score: null) : _passed(task);
      expect(phaseTaskDone(task, [e]), isTrue, reason: task.id);
      return e;
    }

    Map<String, List<PhaseAttemptEvidence>> attemptsFor(Iterable<String> ids) =>
        {
          for (final id in ids) id: [completing(byId[id]!)],
        };

    test('existing task records complete their step after the split', () {
      final first = phase.steps.first;
      final attempts = attemptsFor(first.taskIds);
      final done = phaseStepCompletion(phase.steps, byId, attempts);
      expect(done.first, isTrue);
      expect(done.skip(1), everyElement(isFalse));
      attempts.remove(first.taskIds.last);
      expect(phaseStepCompletion(phase.steps, byId, attempts).first, isFalse);
    });

    test('a scored practice attempt alone never completes a task', () {
      final task = byId['KP01:grammar:01']!;
      expect(
        phaseTaskDone(task, [_evidence(task, assessment: false)]),
        isFalse,
      );
      expect(
        phaseTaskDone(task, [_evidence(task, assessment: false, score: 0)]),
        isFalse,
      );
      // A failed assessment does not count either.
      expect(phaseTaskDone(task, [_evidence(task, score: 0)]), isFalse);
    });

    test('a later practice run cannot hide an earlier completing attempt', () {
      final task = byId['KP01:grammar:03']!;
      final later = PhaseAttemptEvidence.fromJson({
        ..._evidence(task, assessment: false, score: 0).toJson(),
        'attemptId': 'later',
        'occurredAt': '2026-02-01T00:00:00Z',
      });
      expect(phaseTaskDone(task, [later, _passed(task)]), isTrue);
    });

    test('submitting a speaking task completes KP01.2', () {
      final second = phase.steps[1];
      expect(second.taskIds, contains('KP01:speaking:01'));
      final attempts = attemptsFor(second.taskIds);
      expect(phaseStepCompletion(phase.steps, byId, attempts)[1], isTrue);
      attempts.remove('KP01:speaking:01');
      expect(phaseStepCompletion(phase.steps, byId, attempts)[1], isFalse);
    });

    test('an earlier content revision never counts', () {
      final speaking = byId['KP01:speaking:01']!;
      final stale = PhaseAttemptEvidence.fromJson({
        ..._evidence(speaking, score: null).toJson(),
        'contentHash': 'f' * 64,
      });
      expect(phaseTaskDone(speaking, [stale]), isFalse);
    });

    test('a step naming an unknown task is not done and does not throw', () {
      final first = phase.steps.first;
      final attempts = attemptsFor(first.taskIds);
      final missing = Map.of(byId)..remove(first.taskIds.first);
      expect(
        phaseStepCompletion(phase.steps, missing, attempts).first,
        isFalse,
      );
    });
  });
}

PhaseAttemptEvidence _passed(PhaseTask task) {
  final ids = [for (final q in task.assessment.questions) q.id];
  return PhaseAttemptEvidence.fromJson({
    ..._evidence(task).toJson(),
    'passedCriterionIds': ids,
  });
}
