import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/grammar.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/services/account/account_reconciliation.dart'
    as account_api;
import 'package:ko_lernen_app/services/account/reconciliation_errors.dart';
import 'package:ko_lernen_app/services/course_mastery_service.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CurriculumCatalog catalog;
  late CourseMasteryService mastery;

  setUp(() async {
    Storage.resetForTesting();
    Storage.resetCourseMasteryForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    catalog = _catalog();
    mastery = CourseMasteryService(catalog);
  });

  test('merge is commutative and idempotent for disjoint history', () {
    final first = CourseMasterySnapshot(
      placementLevel: 'a1',
      currentCourseUnitId: 'unit_root',
      evidence: [_evidence(id: 'evidence-1', second: 1)],
      scenarioCheckpoints: [_checkpoint(id: 'checkpoint-1', second: 2)],
    );
    final second = CourseMasterySnapshot(
      placementLevel: 'a1',
      currentCourseUnitId: 'unit_root',
      evidence: [_evidence(id: 'evidence-2', second: 3)],
      scenarioCheckpoints: [_checkpoint(id: 'checkpoint-2', second: 4)],
    );

    final forward = mastery.mergeForReconciliation(
      local: first,
      remote: second,
    );
    final reverse = mastery.mergeForReconciliation(
      local: second,
      remote: first,
    );
    final repeated = mastery.mergeForReconciliation(
      local: first,
      remote: first,
    );

    expect(forward.conflicts, isEmpty);
    expect(forward.snapshot!.toJson(), reverse.snapshot!.toJson());
    expect(repeated.snapshot!.toJson(), first.toJson());
  });

  test('merge reports changed bodies under the same evidence ID', () {
    final result = mastery.mergeForReconciliation(
      local: CourseMasterySnapshot(
        placementLevel: 'a1',
        currentCourseUnitId: 'unit_root',
        evidence: [_evidence(id: 'same-evidence', second: 1)],
      ),
      remote: CourseMasterySnapshot(
        placementLevel: 'a1',
        currentCourseUnitId: 'unit_root',
        evidence: [_evidence(id: 'same-evidence', second: 1, isCorrect: false)],
      ),
    );

    expect(result.snapshot, isNull);
    expect(
      result.conflicts,
      contains(
        const CourseMasteryMergeConflict(
          kind: CourseMasteryMergeConflictKind.evidence,
          id: 'same-evidence',
        ),
      ),
    );
  });

  test('merge reports changed bodies under the same checkpoint ID', () {
    final result = mastery.mergeForReconciliation(
      local: CourseMasterySnapshot(
        placementLevel: 'a1',
        currentCourseUnitId: 'unit_root',
        scenarioCheckpoints: [_checkpoint(id: 'same-checkpoint', second: 1)],
      ),
      remote: CourseMasterySnapshot(
        placementLevel: 'a1',
        currentCourseUnitId: 'unit_root',
        scenarioCheckpoints: [
          _checkpoint(id: 'same-checkpoint', second: 1, score: .8),
        ],
      ),
    );

    expect(result.snapshot, isNull);
    expect(
      result.conflicts,
      contains(
        const CourseMasteryMergeConflict(
          kind: CourseMasteryMergeConflictKind.checkpoint,
          id: 'same-checkpoint',
        ),
      ),
    );
  });

  test('merge reports nonempty placement disagreement', () {
    final result = mastery.mergeForReconciliation(
      local: const CourseMasterySnapshot(
        placementLevel: 'a1',
        currentCourseUnitId: 'unit_root',
      ),
      remote: const CourseMasterySnapshot(
        placementLevel: 'a2',
        bypassedPrerequisiteUnitIds: [
          'unit_root',
          'unit_alpha',
          'unit_beta',
          'unit_gamma',
        ],
      ),
    );

    expect(result.snapshot, isNull);
    expect(
      result.conflicts.map((conflict) => conflict.kind),
      contains(CourseMasteryMergeConflictKind.placement),
    );
  });

  test('merge reports completed and bypassed overlap as progression', () {
    final result = mastery.mergeForReconciliation(
      local: const CourseMasterySnapshot(
        currentCourseUnitId: 'unit_alpha',
        completedUnitIds: ['unit_root'],
      ),
      remote: const CourseMasterySnapshot(
        placementLevel: 'a2',
        bypassedPrerequisiteUnitIds: [
          'unit_root',
          'unit_alpha',
          'unit_beta',
          'unit_gamma',
        ],
      ),
    );

    expect(result.snapshot, isNull);
    expect(
      result.conflicts,
      contains(
        const CourseMasteryMergeConflict(
          kind: CourseMasteryMergeConflictKind.progression,
          id: 'unit_root',
        ),
      ),
    );
  });

  test('merge reports schema versions newer or older than canonical', () {
    final result = mastery.mergeForReconciliation(
      local: const CourseMasterySnapshot(
        version: 1,
        currentCourseUnitId: 'unit_root',
      ),
      remote: null,
    );

    expect(result.snapshot, isNull);
    expect(
      result.conflicts.map((conflict) => conflict.kind),
      contains(CourseMasteryMergeConflictKind.version),
    );
  });

  test('v1 migration still synthesizes missing history stable IDs', () {
    final migrated = CourseMasterySnapshot.decodeAndMigrate({
      'version': 1,
      'evidence': [
        {
          'conceptId': 'concept_greeting',
          'contentKind': 'grammar',
          'contentId': 'grammar_greeting',
          'isCorrect': true,
          'occurredAt': _time(1).toIso8601String(),
        },
      ],
      'scenarioCheckpoints': [
        {
          'scenarioId': 'scenario_greeting',
          'score': .7,
          'occurredAt': _time(2).toIso8601String(),
        },
      ],
    });

    expect(migrated.version, CourseMasterySnapshot.currentVersion);
    expect(migrated.evidence.single.id, isNotEmpty);
    expect(migrated.scenarioCheckpoints.single.id, isNotEmpty);
  });

  test('merge reports invalid catalog references with typed conflicts', () {
    final result = mastery.mergeForReconciliation(
      local: CourseMasterySnapshot(
        currentCourseUnitId: 'unit_root',
        evidence: [
          MasteryEvidence(
            id: 'unknown-evidence',
            conceptId: 'unknown-concept',
            contentKind: CurriculumContentKind.grammar,
            contentId: 'grammar_greeting',
            courseUnitId: 'unit_root',
            isCorrect: true,
            occurredAt: _time(1),
            courseEligible: true,
          ),
        ],
      ),
      remote: const CourseMasterySnapshot(completedUnitIds: ['unknown-unit']),
    );

    expect(result.snapshot, isNull);
    expect(
      result.conflicts,
      containsAll(const [
        CourseMasteryMergeConflict(
          kind: CourseMasteryMergeConflictKind.evidence,
          id: 'unknown-evidence',
        ),
        CourseMasteryMergeConflict(
          kind: CourseMasteryMergeConflictKind.progression,
          id: 'unknown-unit',
        ),
      ]),
    );
  });

  test('merge derives earliest valid current unit from resolved IDs', () {
    const local = CourseMasterySnapshot(
      currentCourseUnitId: 'unit_beta',
      completedUnitIds: ['unit_root'],
    );
    const remote = CourseMasterySnapshot(
      currentCourseUnitId: 'unit_gamma',
      completedUnitIds: ['unit_root'],
    );

    final result = mastery.mergeForReconciliation(local: local, remote: remote);

    expect(result.conflicts, isEmpty);
    expect(result.snapshot!.currentCourseUnitId, 'unit_alpha');
  });

  test(
    'browse-only histories remain outside sequential course state in both orders',
    () async {
      await Storage.setBrowseLevelCode('b2');
      final browseEvidence = CourseMasterySnapshot(
        evidence: [
          _evidence(id: 'browse-evidence', second: 1, courseEligible: false),
        ],
      );
      final browseCheckpoint = CourseMasterySnapshot(
        scenarioCheckpoints: [
          _checkpoint(
            id: 'browse-checkpoint',
            second: 2,
            courseEligible: false,
          ),
        ],
      );

      final forward = mastery.mergeForReconciliation(
        local: browseEvidence,
        remote: browseCheckpoint,
      );
      final reverse = mastery.mergeForReconciliation(
        local: browseCheckpoint,
        remote: browseEvidence,
      );

      expect(forward.conflicts, isEmpty);
      expect(forward.snapshot!.toJson(), reverse.snapshot!.toJson());
      expect(forward.snapshot!.placementLevel, isNull);
      expect(forward.snapshot!.currentCourseUnitId, isNull);
      expect(forward.snapshot!.evidence.single.id, 'browse-evidence');
      expect(
        forward.snapshot!.scenarioCheckpoints.single.id,
        'browse-checkpoint',
      );
      expect(Storage.browseLevelCode, 'b2');
    },
  );

  test('merge keeps history deterministically bounded to 300 records', () {
    final evidence = [
      for (var index = 0; index < 301; index++)
        _evidence(id: 'evidence-$index', second: index),
    ];

    final result = mastery.mergeForReconciliation(
      local: CourseMasterySnapshot(
        currentCourseUnitId: 'unit_root',
        evidence: evidence.take(151).toList(),
      ),
      remote: CourseMasterySnapshot(
        currentCourseUnitId: 'unit_root',
        evidence: evidence.skip(151).toList(),
      ),
    );

    expect(result.conflicts, isEmpty);
    expect(result.snapshot!.evidence, hasLength(300));
    expect(result.snapshot!.evidence.first.id, 'evidence-1');
    expect(result.snapshot!.evidence.last.id, 'evidence-300');
  });

  test(
    'merge priority retention preserves correction and active checkpoint symmetrically',
    () async {
      final ordinaryEvidence = [
        for (var index = 1; index <= 300; index++)
          _evidence(
            id: 'ordinary-evidence-$index',
            second: index,
            courseEligible: false,
          ),
      ];
      final ordinaryCheckpoints = [
        for (var index = 1; index <= 300; index++)
          _checkpoint(
            id: 'ordinary-checkpoint-$index',
            second: index,
            courseEligible: false,
          ),
      ];
      final first = CourseMasterySnapshot(
        placementLevel: 'a1',
        currentCourseUnitId: 'unit_root',
        evidence: [
          _correctionEvidence(id: 'old-correction', second: 0),
          ...ordinaryEvidence.take(150),
        ],
        scenarioCheckpoints: [
          _checkpoint(id: 'old-active-checkpoint', second: 0),
          ...ordinaryCheckpoints.take(150),
        ],
      );
      final second = CourseMasterySnapshot(
        placementLevel: 'a1',
        currentCourseUnitId: 'unit_root',
        evidence: ordinaryEvidence.skip(150).toList(),
        scenarioCheckpoints: ordinaryCheckpoints.skip(150).toList(),
      );

      final forward = mastery.mergeForReconciliation(
        local: first,
        remote: second,
      );
      final reverse = mastery.mergeForReconciliation(
        local: second,
        remote: first,
      );

      expect(forward.conflicts, isEmpty);
      expect(forward.snapshot!.toJson(), reverse.snapshot!.toJson());
      expect(forward.snapshot!.evidence, hasLength(300));
      expect(
        forward.snapshot!.evidence.map((entry) => entry.id),
        contains('old-correction'),
      );
      expect(forward.snapshot!.scenarioCheckpoints, hasLength(300));
      expect(
        forward.snapshot!.scenarioCheckpoints.map((entry) => entry.id),
        contains('old-active-checkpoint'),
      );

      await mastery.applyReconciledSnapshot(
        forward.snapshot!,
        expectedGeneration: null,
      );
      expect(mastery.reviewQueue.map((item) => item.conceptId), [
        'concept_correction',
      ]);
    },
  );

  test('serialized apply rejects a stale canonical generation', () async {
    final progress = CourseProgressService(
      () async => CourseMasteryService(catalog),
    );
    final captured = await progress.initializeForPlacement('a1');
    final generation = Storage.courseMasterySnapshotRawJson;
    final laterWrite = progress.recordContentAttempt(
      CurriculumContentKind.grammar,
      'grammar_greeting',
      true,
      conceptId: 'concept_greeting',
      occurredAt: _time(10),
    );
    final staleApply = progress.applyReconciledSnapshot(
      captured,
      expectedGeneration: generation,
    );

    final later = await laterWrite;
    await expectLater(
      staleApply,
      throwsA(isA<LocalReconciliationGenerationConflict>()),
    );

    final durable = CourseMasterySnapshot.fromJson(
      (jsonDecode(Storage.courseMasterySnapshotRawJson) as Map).map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    );
    expect(durable.evidence.map((item) => item.id), [
      later.snapshot.evidence.single.id,
    ]);
  });

  test('account reconciliation API re-exports the generation conflict', () {
    expect(
      const account_api.LocalReconciliationGenerationConflict(),
      isA<LocalReconciliationGenerationConflict>(),
    );
  });

  test(
    'cloud JSON merge validates, merges, and applies canonical state',
    () async {
      final progress = CourseProgressService(
        () async => CourseMasteryService(catalog),
      );
      await progress.initializeForPlacement('a1');
      final local = await progress.recordContentAttempt(
        CurriculumContentKind.grammar,
        'grammar_greeting',
        true,
        conceptId: 'concept_greeting',
        occurredAt: _time(1),
      );
      final generation = Storage.courseMasterySnapshotRawJson;
      final remote = CourseMasterySnapshot(
        placementLevel: 'a1',
        currentCourseUnitId: 'unit_root',
        evidence: [_evidence(id: 'remote-evidence', second: 2)],
      );

      final merged = await progress.mergeCloudSnapshotJson(
        jsonEncode(remote.toJson()),
        expectedGeneration: generation,
      );

      expect(
        merged.evidence.map((item) => item.id),
        containsAll([local.snapshot.evidence.single.id, 'remote-evidence']),
      );
      expect(
        jsonDecode(Storage.courseMasterySnapshotRawJson)['evidence'],
        hasLength(2),
      );
    },
  );

  test(
    'cloud merge rejects malformed remote v2 stable IDs without changing local bytes',
    () async {
      for (final malformedId in <Object?>[42, null]) {
        Storage.resetForTesting();
        Storage.resetCourseMasteryForTesting();
        SharedPreferences.setMockInitialValues({});
        await Storage.init();
        final progress = CourseProgressService(
          () async => CourseMasteryService(catalog),
        );
        await progress.initializeForPlacement('a1');
        final before = Storage.courseMasterySnapshotRawJson;
        final malformed = CourseMasterySnapshot(
          placementLevel: 'a1',
          currentCourseUnitId: 'unit_root',
          evidence: [_evidence(id: 'remote-evidence', second: 2)],
        ).toJson();
        final rawEvidence = malformed['evidence']! as List<dynamic>;
        if (malformedId == null) {
          (rawEvidence.single as Map<String, dynamic>).remove('id');
        } else {
          (rawEvidence.single as Map<String, dynamic>)['id'] = malformedId;
        }

        await expectLater(
          progress.mergeCloudSnapshotJson(
            jsonEncode(malformed),
            expectedGeneration: before,
          ),
          throwsA(isA<FormatException>()),
        );
        expect(Storage.courseMasterySnapshotRawJson, before);
      }
    },
  );

  test(
    'cloud merge rejects malformed local v2 identity fields without rewriting it',
    () async {
      final malformed = CourseMasterySnapshot(
        placementLevel: 'a1',
        currentCourseUnitId: 'unit_root',
        scenarioCheckpoints: [_checkpoint(id: 'local-checkpoint', second: 1)],
      ).toJson();
      final rawCheckpoint =
          (malformed['scenarioCheckpoints']! as List<dynamic>).single
              as Map<String, dynamic>;
      rawCheckpoint['id'] = 42;
      final before = jsonEncode(malformed);
      await Storage.setCourseMasterySnapshotRawJson(before);
      final progress = CourseProgressService(
        () async => CourseMasteryService(catalog),
      );
      final remote = const CourseMasterySnapshot(
        placementLevel: 'a1',
        currentCourseUnitId: 'unit_root',
      );

      await expectLater(
        progress.mergeCloudSnapshotJson(
          jsonEncode(remote.toJson()),
          expectedGeneration: before,
        ),
        throwsA(isA<FormatException>()),
      );

      expect(Storage.courseMasterySnapshotRawJson, before);
    },
  );
}

MasteryEvidence _evidence({
  required String id,
  required int second,
  bool isCorrect = true,
  bool courseEligible = true,
}) => MasteryEvidence(
  id: id,
  conceptId: 'concept_greeting',
  contentKind: CurriculumContentKind.grammar,
  contentId: 'grammar_greeting',
  courseUnitId: 'unit_root',
  isCorrect: isCorrect,
  occurredAt: _time(second),
  courseEligible: courseEligible,
);

MasteryEvidence _correctionEvidence({
  required String id,
  required int second,
}) => MasteryEvidence(
  id: id,
  conceptId: 'concept_correction',
  contentKind: CurriculumContentKind.grammar,
  contentId: 'grammar_correction',
  courseUnitId: 'unit_alpha',
  isCorrect: false,
  occurredAt: _time(second),
  errorReason: MasteryErrorReason.spellingSpacing,
  courseEligible: true,
);

ScenarioCheckpointEvidence _checkpoint({
  required String id,
  required int second,
  double score = .7,
  bool courseEligible = true,
}) => ScenarioCheckpointEvidence(
  id: id,
  scenarioId: 'scenario_greeting',
  courseUnitId: 'unit_root',
  score: score,
  occurredAt: _time(second),
  courseEligible: courseEligible,
);

DateTime _time(int second) =>
    DateTime.utc(2026, 8, 3).add(Duration(seconds: second));

CurriculumCatalog _catalog() {
  const units = <Map<String, dynamic>>[
    {
      'id': 'unit_root',
      'level': 'a1',
      'order': 1,
      'title': {'ko': 'root', 'de': 'root', 'en': 'root'},
      'canDo': {'ko': 'root', 'de': 'root', 'en': 'root'},
      'requiredConceptIds': ['concept_greeting'],
      'checkpointContentIds': ['scenario:scenario_greeting'],
    },
    {
      'id': 'unit_alpha',
      'level': 'a1',
      'order': 2,
      'title': {'ko': 'alpha', 'de': 'alpha', 'en': 'alpha'},
      'canDo': {'ko': 'alpha', 'de': 'alpha', 'en': 'alpha'},
      'prerequisiteUnitIds': ['unit_root'],
    },
    {
      'id': 'unit_beta',
      'level': 'a1',
      'order': 3,
      'title': {'ko': 'beta', 'de': 'beta', 'en': 'beta'},
      'canDo': {'ko': 'beta', 'de': 'beta', 'en': 'beta'},
      'prerequisiteUnitIds': ['unit_root'],
    },
    {
      'id': 'unit_gamma',
      'level': 'a1',
      'order': 4,
      'title': {'ko': 'gamma', 'de': 'gamma', 'en': 'gamma'},
      'canDo': {'ko': 'gamma', 'de': 'gamma', 'en': 'gamma'},
      'prerequisiteUnitIds': ['unit_root'],
    },
  ];
  const concept = <String, dynamic>{
    'id': 'concept_greeting',
    'level': 'a1',
    'kind': 'speechStyle',
    'title': {'ko': 'greeting', 'de': 'greeting', 'en': 'greeting'},
    'explanation': {'ko': 'greeting', 'de': 'greeting', 'en': 'greeting'},
  };
  const correctionConcept = <String, dynamic>{
    'id': 'concept_correction',
    'level': 'a1',
    'kind': 'situation',
    'title': {'ko': 'correction', 'de': 'correction', 'en': 'correction'},
    'explanation': {'ko': 'correction', 'de': 'correction', 'en': 'correction'},
  };
  final grammar = Grammar(
    id: 'grammar_greeting',
    pattern: 'greeting',
    level: 'a1',
    typeDe: 'Test',
    explanationDe: '',
    exampleKorean: '',
    exampleGerman: '',
    note: '',
  );
  final correctionGrammar = Grammar(
    id: 'grammar_correction',
    pattern: 'correction',
    level: 'a1',
    typeDe: 'Test',
    explanationDe: '',
    exampleKorean: '',
    exampleGerman: '',
    note: '',
  );
  final scenario = Scenario(
    id: 'scenario_greeting',
    level: LearnerLevel.a1,
    emoji: 'S',
    register: Register.polite,
    title: const LocalizedText(ko: 'scenario', de: 'scenario', en: 'scenario'),
    intro: const LocalizedText(ko: 'scenario', de: 'scenario', en: 'scenario'),
    vocab: const [],
    grammarIds: const ['grammar_greeting'],
    dialog: const [],
    quests: const [],
    courseUnitId: 'unit_root',
    speechStyle: SpeechStyle.polite,
    relationshipContext: 'service',
    intent: 'greet',
    conceptIds: const ['concept_greeting'],
  );
  return CurriculumCatalog.fromDataForTesting(
    manifestJson: const {
      'version': 2,
      'courseUnits': units,
      'concepts': [concept, correctionConcept],
      'surfaceForms': <Map<String, dynamic>>[],
      'formFamilies': <Map<String, dynamic>>[],
      'contentLinks': <Map<String, dynamic>>[],
      'vocabPackUnitMap': <String, String>{},
      'smalltalkCategoryUnitMap': <String, String>{},
      'clozeTopicUnitMap': <String, String>{},
      'grammarRuleMap': {
        'grammar_greeting': {
          'courseUnitId': 'unit_root',
          'conceptIds': ['concept_greeting'],
        },
        'grammar_correction': {
          'courseUnitId': 'unit_alpha',
          'conceptIds': ['concept_correction'],
        },
      },
    },
    vocab: const [],
    grammar: [grammar, correctionGrammar],
    smalltalk: const [],
    cloze: const [],
    satz: const [],
    scenarios: [scenario],
  );
}
