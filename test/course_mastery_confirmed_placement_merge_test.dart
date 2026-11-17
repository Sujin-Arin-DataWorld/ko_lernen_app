import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/can_do_segment.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/grammar.dart';
import 'package:ko_lernen_app/models/phase_task.dart';
import 'package:ko_lernen_app/models/productive_mastery.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/services/course_mastery_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';

void main() {
  late CourseMasteryService service;
  setUp(() => service = CourseMasteryService(_catalog()));

  test('proof fixtures individually satisfy strict synchronization', () {
    for (final snapshot in [_local(), _remote()]) {
      final result = service.mergeForReconciliation(
        local: snapshot,
        remote: snapshot,
      );
      expect(result.conflicts, isEmpty);
      expect(result.snapshot!.toJson(), snapshot.toJson());
    }
  });

  for (final selected in ['a1', ' A2 ']) {
    test(
      'confirmed $selected preserves every proof body and actual completion',
      () {
        final local = _local();
        final remote = _remote();
        final beforeLocal = jsonEncode(local.toJson());
        final beforeRemote = jsonEncode(remote.toJson());
        final beforeService = service.snapshot.toJson();

        final result = service.mergeForConfirmedPlacement(
          local: local,
          remote: remote,
          selectedPlacementLevel: selected,
        );

        expect(result.conflicts, isEmpty);
        final merged = result.snapshot!;
        expect(merged.placementLevel, selected.trim().toLowerCase());
        expect(merged.completedUnitIds, ['a1_root', 'a1_follow']);
        expect(merged.bypassedPrerequisiteUnitIds, isEmpty);
        expect(merged.currentCourseUnitId, 'a2_root');
        _expectBothProofBodies(merged, local, remote);
        expect(jsonEncode(local.toJson()), beforeLocal);
        expect(jsonEncode(remote.toJson()), beforeRemote);
        expect(
          service.snapshot.toJson(),
          beforeService,
          reason: 'Preview merge must not publish or persist the result.',
        );
      },
    );
  }

  test(
    'confirmation recomputes unearned bypass without granting completion',
    () {
      final local = const CourseMasterySnapshot(
        placementLevel: 'a1',
        currentCourseUnitId: 'a1_root',
      );
      final remote = const CourseMasterySnapshot(
        placementLevel: 'a2',
        currentCourseUnitId: 'a2_root',
        bypassedPrerequisiteUnitIds: ['a1_root', 'a1_follow'],
      );
      for (final selected in ['a1', 'a2']) {
        final result = service.mergeForConfirmedPlacement(
          local: local,
          remote: remote,
          selectedPlacementLevel: selected,
        );
        expect(result.conflicts, isEmpty);
        expect(result.snapshot!.completedUnitIds, isEmpty);
        expect(
          result.snapshot!.bypassedPrerequisiteUnitIds,
          selected == 'a1' ? isEmpty : ['a1_root', 'a1_follow'],
        );
        expect(
          result.snapshot!.currentCourseUnitId,
          selected == 'a1' ? 'a1_root' : 'a2_root',
        );
        expect(result.snapshot!.productiveEvidence, isEmpty);
        expect(result.snapshot!.phaseTaskEvidence, isEmpty);
      }
    },
  );

  test('confirmation is deterministic, commutative and retry-idempotent', () {
    final first = service.mergeForConfirmedPlacement(
      local: _local(),
      remote: _remote(),
      selectedPlacementLevel: 'a2',
    );
    final reversed = service.mergeForConfirmedPlacement(
      local: _remote(),
      remote: _local(),
      selectedPlacementLevel: 'a2',
    );
    expect(first.conflicts, isEmpty);
    expect(reversed.conflicts, isEmpty);
    expect(first.snapshot!.toJson(), reversed.snapshot!.toJson());
    final retried = service.mergeForConfirmedPlacement(
      local: first.snapshot!,
      remote: _remote(),
      selectedPlacementLevel: 'a2',
    );
    expect(retried.conflicts, isEmpty);
    expect(retried.snapshot!.toJson(), first.snapshot!.toJson());
  });

  test(
    'confirmation preserves distinct productive attempts in the same assessment slot',
    () {
      final first = _productive('first-slot-attempt', 1, slot: 'shared');
      final second = _productive(
        'second-slot-attempt',
        2,
        score: .9,
        slot: 'shared',
      );
      expect(first.logicalSlotId, second.logicalSlotId);
      final result = service.mergeForConfirmedPlacement(
        local: _local().copyWith(productiveEvidence: [first]),
        remote: _local().copyWith(productiveEvidence: [second]),
        selectedPlacementLevel: 'a1',
      );
      expect(result.conflicts, isEmpty);
      expect(
        result.snapshot!.productiveEvidence.map((e) => e.toJson()),
        unorderedEquals([first.toJson(), second.toJson()]),
      );
    },
  );

  test('default placement-only disagreement remains a strict conflict', () {
    final result = service.mergeForReconciliation(
      local: const CourseMasterySnapshot(placementLevel: 'a1'),
      remote: const CourseMasterySnapshot(placementLevel: 'a2'),
    );
    expect(result.snapshot, isNull);
    expect(
      result.conflicts.map((e) => e.kind),
      contains(CourseMasteryMergeConflictKind.placement),
    );
  });

  test('confirmation rejects unsupported and unpresented third levels', () {
    for (final selected in ['b1', 'c2', 'a0', '']) {
      final result = service.mergeForConfirmedPlacement(
        local: _local(),
        remote: _local(),
        selectedPlacementLevel: selected,
      );
      expect(result.snapshot, isNull);
      expect(
        result.conflicts.map((e) => e.kind),
        contains(CourseMasteryMergeConflictKind.placement),
      );
    }
  });

  test('confirmation does not hide invalid input or catalog references', () {
    final malformed = _local().copyWith(currentCourseUnitId: 'unknown-unit');
    final result = service.mergeForConfirmedPlacement(
      local: malformed,
      remote: _remote(),
      selectedPlacementLevel: 'a2',
    );
    expect(result.snapshot, isNull);
    expect(result.conflicts, isNotEmpty);
    final invalidCatalog = CourseMasteryService(_catalog(invalid: true));
    final invalid = invalidCatalog.mergeForConfirmedPlacement(
      local: _local(),
      remote: _remote(),
      selectedPlacementLevel: 'a2',
    );
    expect(invalid.snapshot, isNull);
    expect(invalid.conflicts, isNotEmpty);
  });

  for (final collision in [
    'evidence',
    'checkpoint',
    'phase',
    'productive',
    'archivedProductive',
  ]) {
    test('confirmation rejects same-ID different-body $collision proof', () {
      final local = _local();
      final other = switch (collision) {
        'evidence' => _remote().copyWith(
          evidence: [_evidence('local-e', 1, correct: true)],
        ),
        'checkpoint' => _remote().copyWith(
          scenarioCheckpoints: [_checkpoint('local-c', 1, score: .9)],
        ),
        'phase' => _remote().copyWith(
          phaseTaskEvidence: [_phase('local-phase', 1, score: .9)],
        ),
        'productive' => _remote().copyWith(
          productiveEvidence: [_productive('local-prod', 1, score: .9)],
        ),
        _ => _remote().copyWith(
          archivedProductiveEvidence: [
            _productive('local-archived', 1, score: .9),
          ],
        ),
      };
      final result = service.mergeForConfirmedPlacement(
        local: local,
        remote: other,
        selectedPlacementLevel: 'a2',
      );
      expect(result.snapshot, isNull);
      expect(
        result.conflicts.any(
          (e) => e.kind != CourseMasteryMergeConflictKind.placement,
        ),
        isTrue,
        reason: 'Consent to placement cannot suppress proof collisions.',
      );
    });
  }

  test(
    'project receipt decoding rejects a changed body under its original deterministic ID',
    () {
      final receipt = _project('local-project');
      expect(
        () => ProductiveProjectStepEvidence.fromJson({
          ...receipt.toJson(),
          'stepOrder': 3,
        }),
        throwsA(isA<FormatException>()),
      );
    },
  );

  for (final family in ['evidence', 'checkpoint', 'phase']) {
    test('confirmation rejects unpreservable $family retention overflow', () {
      final one = const CourseMasterySnapshot(
        placementLevel: 'a1',
        currentCourseUnitId: 'a1_root',
      );
      final left = switch (family) {
        'evidence' => one.copyWith(
          evidence: [for (var i = 0; i < 150; i++) _evidence('l-$i', i + 1)],
        ),
        'checkpoint' => one.copyWith(
          scenarioCheckpoints: [
            for (var i = 0; i < 150; i++) _checkpoint('l-$i', i + 1),
          ],
        ),
        _ => one.copyWith(
          phaseTaskEvidence: [
            for (var i = 0; i < 151; i++) _phase('l-$i', i + 1),
          ],
        ),
      };
      final right = switch (family) {
        'evidence' => one.copyWith(
          evidence: [for (var i = 0; i < 151; i++) _evidence('r-$i', i + 151)],
        ),
        'checkpoint' => one.copyWith(
          scenarioCheckpoints: [
            for (var i = 0; i < 151; i++) _checkpoint('r-$i', i + 151),
          ],
        ),
        _ => one.copyWith(
          phaseTaskEvidence: [
            for (var i = 0; i < 151; i++) _phase('r-$i', i + 152),
          ],
        ),
      };
      final result = service.mergeForConfirmedPlacement(
        local: left,
        remote: right,
        selectedPlacementLevel: 'a1',
      );
      expect(
        result.snapshot,
        isNull,
        reason: 'The selected course must not silently trim retained proof.',
      );
      expect(result.conflicts, isNotEmpty);
    });
  }

  test(
    'lower placement rejects a historical completion whose bypass baseline cannot survive',
    () {
      final local = const CourseMasterySnapshot(
        placementLevel: 'a1',
        currentCourseUnitId: 'a1_root',
      );
      final remote = const CourseMasterySnapshot(
        placementLevel: 'a2',
        currentCourseUnitId: 'a2_follow',
        completedUnitIds: ['a2_root'],
        bypassedPrerequisiteUnitIds: ['a1_root', 'a1_follow'],
      );
      final result = service.mergeForConfirmedPlacement(
        local: local,
        remote: remote,
        selectedPlacementLevel: 'a1',
      );
      expect(result.snapshot, isNull);
      expect(
        result.conflicts.map((e) => e.kind),
        contains(CourseMasteryMergeConflictKind.progression),
      );
    },
  );
}

CourseMasterySnapshot _local() => CourseMasterySnapshot(
  placementLevel: 'a1',
  currentCourseUnitId: 'a1_follow',
  completedUnitIds: const ['a1_root'],
  evidence: [_evidence('local-e', 1)],
  scenarioCheckpoints: [_checkpoint('local-c', 1)],
  phaseTaskEvidence: [_phase('local-phase', 1)],
  productiveEvidence: [_productive('local-prod', 1)],
  productiveProjectStepEvidence: [_project('local-project')],
  archivedProductiveEvidence: [_productive('local-archived', 1)],
  archivedProductiveProjectStepEvidence: [_project('local-archived-project')],
);

CourseMasterySnapshot _remote() => CourseMasterySnapshot(
  placementLevel: 'a2',
  currentCourseUnitId: 'a2_root',
  completedUnitIds: const ['a1_root', 'a1_follow'],
  evidence: [_evidence('remote-e', 2, correct: true)],
  scenarioCheckpoints: [_checkpoint('remote-c', 2)],
  phaseTaskEvidence: [_phase('remote-phase', 2)],
  productiveEvidence: [_productive('remote-prod', 2)],
  productiveProjectStepEvidence: [_project('remote-project')],
  archivedProductiveEvidence: [_productive('remote-archived', 2)],
  archivedProductiveProjectStepEvidence: [_project('remote-archived-project')],
);

void _expectBothProofBodies(
  CourseMasterySnapshot actual,
  CourseMasterySnapshot local,
  CourseMasterySnapshot remote,
) {
  for (final key in [
    'evidence',
    'scenarioCheckpoints',
    'phaseTaskEvidence',
    'productiveEvidence',
    'productiveProjectStepEvidence',
    'archivedProductiveEvidence',
    'archivedProductiveProjectStepEvidence',
  ]) {
    final expected = [
      ...(local.toJson()[key] as List),
      ...(remote.toJson()[key] as List),
    ];
    expect(actual.toJson()[key], unorderedEquals(expected), reason: key);
  }
}

DateTime _time(int second) =>
    DateTime.utc(2026, 10, 1).add(Duration(seconds: second));
MasteryEvidence _evidence(String id, int second, {bool correct = false}) =>
    MasteryEvidence(
      id: id,
      conceptId: 'concept_greeting',
      contentKind: CurriculumContentKind.grammar,
      contentId: 'grammar_greeting',
      courseUnitId: 'a1_root',
      isCorrect: correct,
      occurredAt: _time(second),
      courseEligible: false,
    );
ScenarioCheckpointEvidence _checkpoint(
  String id,
  int second, {
  double score = .8,
}) => ScenarioCheckpointEvidence(
  id: id,
  scenarioId: 'scenario_greeting',
  courseUnitId: 'a1_root',
  score: score,
  occurredAt: _time(second),
  courseEligible: false,
);
PhaseAttemptEvidence _phase(String id, int second, {double score = .8}) =>
    PhaseAttemptEvidence.fromJson({
      'attemptId': id,
      'phaseId': 'KP01',
      'taskId': 'KP01:task',
      'contentHash': 'a' * 64,
      'contentRevision': 1,
      'rubricVersion': 1,
      'minimumScore': .7,
      'evaluatorVersion': 'phase-structured-v1',
      'mode': 'assessment',
      'score': score,
      'passedCriterionIds': ['criterion'],
      'occurredAt': _time(second).toIso8601String(),
    });
ProductiveMasteryEvidence _productive(
  String id,
  int second, {
  double score = .8,
  String? slot,
}) => ProductiveMasteryEvidence(
  id: id,
  assessmentItemId: 'assessment-${slot ?? id}',
  canDoSegmentId: 'segment-${slot ?? id}',
  courseUnitId: 'a1_root',
  missionContentLinkId: 'mission-${slot ?? id}',
  conceptId: 'concept_greeting',
  evidenceMode: SegmentEvidenceMode.guidedProduction,
  rubricVersion: 1,
  score: score,
  occurredAt: _time(second),
  courseEligible: true,
  definitionFingerprint: 'definition-${slot ?? id}',
  coverage: ProductiveEvidenceCoverage(
    matchedCriterionIds: const ['criterion'],
  ),
);
ProductiveProjectStepEvidence _project(String id, {int order = 1}) =>
    ProductiveProjectStepEvidence(
      projectId: 'project-$id',
      stepId: 'step-$id',
      stepOrder: order,
      courseUnitId: 'a1_root',
      authorityFingerprint: 'authority-$id',
      reviewedSourceSnippetIds: const ['source'],
    );

CurriculumCatalog _catalog({bool invalid = false}) =>
    CurriculumCatalog.fromDataForTesting(
      manifestJson: {
        'version': 2,
        'courseUnits': [
          {
            'id': 'a1_root',
            'level': 'a1',
            'order': 1,
            'title': {'ko': 'root', 'de': 'root', 'en': 'root'},
            'canDo': {'ko': 'root', 'de': 'root', 'en': 'root'},
            'requiredConceptIds': ['concept_greeting'],
            'checkpointContentIds': ['scenario:scenario_greeting'],
          },
          {
            'id': 'a1_follow',
            'level': 'a1',
            'order': 2,
            'title': {'ko': 'follow', 'de': 'follow', 'en': 'follow'},
            'canDo': {'ko': 'follow', 'de': 'follow', 'en': 'follow'},
            'prerequisiteUnitIds': [invalid ? 'unknown-unit' : 'a1_root'],
          },
          {
            'id': 'a2_root',
            'level': 'a2',
            'order': 1,
            'title': {'ko': 'a2 root', 'de': 'a2 root', 'en': 'a2 root'},
            'canDo': {'ko': 'a2 root', 'de': 'a2 root', 'en': 'a2 root'},
            'prerequisiteUnitIds': ['a1_follow'],
          },
          {
            'id': 'a2_follow',
            'level': 'a2',
            'order': 2,
            'title': {'ko': 'a2 follow', 'de': 'a2 follow', 'en': 'a2 follow'},
            'canDo': {'ko': 'a2 follow', 'de': 'a2 follow', 'en': 'a2 follow'},
            'prerequisiteUnitIds': ['a2_root'],
          },
        ],
        'concepts': [
          {
            'id': 'concept_greeting',
            'level': 'a1',
            'kind': 'speechStyle',
            'title': {'ko': 'greeting', 'de': 'greeting', 'en': 'greeting'},
            'explanation': {
              'ko': 'greeting',
              'de': 'greeting',
              'en': 'greeting',
            },
          },
        ],
        'surfaceForms': <Map<String, dynamic>>[],
        'formFamilies': <Map<String, dynamic>>[],
        'contentLinks': <Map<String, dynamic>>[],
        'vocabPackUnitMap': <String, String>{},
        'smalltalkCategoryUnitMap': <String, String>{},
        'clozeTopicUnitMap': <String, String>{},
        'grammarRuleMap': {
          'grammar_greeting': {
            'courseUnitId': 'a1_root',
            'conceptIds': ['concept_greeting'],
          },
        },
      },
      vocab: const [],
      grammar: [
        Grammar(
          id: 'grammar_greeting',
          pattern: 'greeting',
          level: 'a1',
          typeDe: 'Test',
          explanationDe: '',
          exampleKorean: '',
          exampleGerman: '',
          note: '',
        ),
      ],
      smalltalk: const [],
      cloze: const [],
      satz: const [],
      scenarios: [
        Scenario(
          id: 'scenario_greeting',
          level: LearnerLevel.a1,
          emoji: 'S',
          register: Register.polite,
          title: const LocalizedText(ko: 'scene', de: 'scene', en: 'scene'),
          intro: const LocalizedText(ko: 'scene', de: 'scene', en: 'scene'),
          vocab: const [],
          grammarIds: const ['grammar_greeting'],
          dialog: const [],
          quests: const [],
          courseUnitId: 'a1_root',
          speechStyle: SpeechStyle.polite,
          relationshipContext: 'service',
          intent: 'greet',
          conceptIds: const ['concept_greeting'],
        ),
      ],
    );
