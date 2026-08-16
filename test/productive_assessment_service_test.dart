import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/can_do_segment.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/models/productive_mastery.dart';
import 'package:ko_lernen_app/services/productive_assessment_service.dart';
import 'package:ko_lernen_app/services/pronunciation_assessment_client.dart';

const _text = CurriculumText(ko: '과제', de: 'Aufgabe', en: 'Task');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final occurredAt = DateTime.utc(2026, 8, 16, 12);

  test(
    'productive asset parses all executable definitions and projects',
    () async {
      final catalog = await ProductiveAssessmentCatalog.load();

      expect(catalog.definitions, hasLength(118));
      expect(catalog.projects, hasLength(8));
      expect(catalog.sourceSnippets, hasLength(32));
      expect(catalog.bundles, hasLength(16));
    },
  );

  test('every A1-B2 authored answer passes its reviewed rubric', () async {
    final catalog = await ProductiveAssessmentCatalog.load();
    const engine = ProductiveTextAssessmentEngine();
    final basicDefinitions = catalog.definitions.where(
      (definition) => const {
        LearnerLevel.a1,
        LearnerLevel.a2,
        LearnerLevel.b1,
        LearnerLevel.b2,
      }.contains(definition.level),
    );

    expect(basicDefinitions, hasLength(70));
    final failures = <String>[];
    for (final definition in basicDefinitions) {
      expect(
        definition.authoredContextExamples,
        hasLength(1),
        reason: definition.assessmentItemId,
      );
      expect(
        definition.textRubric!.criteria.map((criterion) => criterion.id),
        isNot(contains(anyOf('meaning_anchor', 'context_detail'))),
        reason: definition.assessmentItemId,
      );
      final result = engine.evaluate(
        definition: definition,
        input: definition.authoredContextExamples.single,
        occurredAt: occurredAt,
      );
      if (!result.passed) {
        failures.add(
          '${definition.assessmentItemId}: '
          '${result.criteria.where((criterion) => !criterion.matched).map((criterion) => criterion.id).join(', ')}',
        );
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('guided writing normalizes NFC and whitespace deterministically', () {
    final definition = _textDefinition(
      suffix: 'a1_greeting',
      mode: SegmentEvidenceMode.guidedProduction,
      criteria: [
        ProductiveTextCriterion(
          id: 'greeting',
          kind: ProductiveCriterionKind.exactAnswer,
          acceptedVariants: const ['안녕하세요'],
          weight: 1,
          requiredForPass: true,
        ),
      ],
    );
    const engine = ProductiveTextAssessmentEngine();

    final first = engine.evaluate(
      definition: definition,
      input: '  안녕하세요。 ',
      occurredAt: occurredAt,
    );
    final second = engine.evaluate(
      definition: definition,
      input: '안녕하세요.',
      occurredAt: occurredAt,
    );

    expect(first.passed, isTrue);
    expect(second.passed, isTrue);
    expect(first.score, second.score);
    expect(
      engine
          .evaluate(
            definition: definition,
            input: '감사합니다',
            occurredAt: occurredAt,
          )
          .passed,
      isFalse,
    );
  });

  test(
    'self introduction requires one learner-chosen identity in all registers',
    () async {
      final catalog = await ProductiveAssessmentCatalog.load();
      final definition = catalog
          .definitionsById['assess_a1_02_self_intro_identity_connected_production_v1']!;
      const engine = ProductiveTextAssessmentEngine();

      expect(
        engine
            .evaluate(
              definition: definition,
              input: '저는 아린입니다. 저는 아린이에요. 나는 아린이야.',
              occurredAt: occurredAt,
            )
            .passed,
        isTrue,
      );
      expect(
        engine
            .evaluate(
              definition: definition,
              input: '저는 수진입니다. 저는 민수예요. 나는 수진이야.',
              occurredAt: occurredAt,
            )
            .passed,
        isFalse,
      );
    },
  );

  test('structured writing ties four answer slots to this step and text', () {
    final fixture = _advancedFixture();
    const engine = ProductiveTextAssessmentEngine();
    final valid = ProductiveStructuredWritingSubmission(
      text: '자료의 주장은 제한적입니다. 근거의 표본은 작습니다. 그러나 반례가 있습니다. 따라서 결론을 다시 검토해야 합니다.',
      slotValues: const {
        'claim': '자료의 주장은 제한적입니다',
        'support': '근거의 표본은 작습니다',
        'limitation': '반례가 있습니다',
        'conclusion': '결론을 다시 검토해야 합니다',
      },
      linkedSourceSpanIds: const {
        'claim': ['snippet_test_01'],
        'support': ['snippet_test_01'],
        'limitation': ['snippet_test_02'],
        'conclusion': ['snippet_test_02'],
      },
    );

    final passed = engine.evaluateStructured(
      catalog: fixture.catalog,
      definition: fixture.writing,
      submission: valid,
      occurredAt: occurredAt,
    );
    expect(passed.passed, isTrue);

    final detachedSlot = engine.evaluateStructured(
      catalog: fixture.catalog,
      definition: fixture.writing,
      submission: ProductiveStructuredWritingSubmission(
        text: valid.text,
        slotValues: {...valid.slotValues, 'claim': '본문에 없는 임의 주장입니다'},
        linkedSourceSpanIds: valid.linkedSourceSpanIds,
      ),
      occurredAt: occurredAt,
    );
    expect(detachedSlot.passed, isFalse);

    final futureSource = engine.evaluateStructured(
      catalog: fixture.catalog,
      definition: fixture.writing,
      submission: ProductiveStructuredWritingSubmission(
        text: valid.text,
        slotValues: valid.slotValues,
        linkedSourceSpanIds: {
          ...valid.linkedSourceSpanIds,
          'claim': const ['snippet_test_03'],
        },
      ),
      occurredAt: occurredAt,
    );
    expect(futureSource.passed, isFalse);

    expect(
      () => engine.evaluate(
        definition: fixture.writing,
        input: valid.text,
        occurredAt: occurredAt,
      ),
      throwsFormatException,
    );
  });

  test('connected evidence enforces authored source and role mapping', () {
    final fixture = _advancedFixture();
    const engine = ProductiveConnectedEvidenceEngine();

    final passed = engine.evaluate(
      catalog: fixture.catalog,
      definition: fixture.connected,
      nodes: [
        ProductiveEvidenceNode(
          sourceSnippetId: 'snippet_test_01',
          roles: const [ProductiveEvidenceRole.support],
        ),
        ProductiveEvidenceNode(
          sourceSnippetId: 'snippet_test_02',
          roles: const [ProductiveEvidenceRole.limitation],
        ),
      ],
      occurredAt: occurredAt,
    );
    expect(passed.passed, isTrue);

    final swapped = engine.evaluate(
      catalog: fixture.catalog,
      definition: fixture.connected,
      nodes: [
        ProductiveEvidenceNode(
          sourceSnippetId: 'snippet_test_01',
          roles: const [ProductiveEvidenceRole.limitation],
        ),
        ProductiveEvidenceNode(
          sourceSnippetId: 'snippet_test_02',
          roles: const [ProductiveEvidenceRole.support],
        ),
      ],
      occurredAt: occurredAt,
    );
    expect(swapped.passed, isFalse);

    final futureSource = engine.evaluate(
      catalog: fixture.catalog,
      definition: fixture.connected,
      nodes: [
        ProductiveEvidenceNode(
          sourceSnippetId: 'snippet_test_01',
          roles: const [ProductiveEvidenceRole.support],
        ),
        ProductiveEvidenceNode(
          sourceSnippetId: 'snippet_test_03',
          roles: const [ProductiveEvidenceRole.limitation],
        ),
      ],
      occurredAt: occurredAt,
    );
    expect(futureSource.passed, isFalse);
  });

  test(
    'read-aloud stays practice-only while trusted oral production persists no raw speech',
    () async {
      final fixture = _advancedFixture();
      final writing = fixture.writing;
      final oral = fixture.oral;
      final submission = ProductiveStructuredWritingSubmission(
        text:
            '우선 첫 번째 자료의 주장은 참여자의 경험을 보여 줍니다. '
            '첫 번째 자료와 두 번째 자료를 비교하면 근거의 범위가 제한적임을 알 수 있습니다. '
            '그러나 두 번째 자료는 비교 집단이 없어 인과관계를 확정할 수 없다는 한계를 밝힙니다. '
            '따라서 다른 지역의 자료를 더 확인한 뒤 결론을 다시 검토해야 합니다.',
        slotValues: const {
          'claim': '우선 첫 번째 자료의 주장은 참여자의 경험을 보여 줍니다',
          'support': '첫 번째 자료와 두 번째 자료를 비교하면 근거의 범위가 제한적임을 알 수 있습니다',
          'limitation': '그러나 두 번째 자료는 비교 집단이 없어 인과관계를 확정할 수 없다는 한계를 밝힙니다',
          'conclusion': '따라서 다른 지역의 자료를 더 확인한 뒤 결론을 다시 검토해야 합니다',
        },
        linkedSourceSpanIds: const {
          'claim': ['snippet_test_01'],
          'support': ['snippet_test_01', 'snippet_test_02'],
          'limitation': ['snippet_test_02'],
          'conclusion': ['snippet_test_01', 'snippet_test_02'],
        },
      );
      final writingResult = const ProductiveTextAssessmentEngine()
          .evaluateStructured(
            catalog: fixture.catalog,
            definition: writing,
            submission: submission,
            occurredAt: occurredAt,
          );
      expect(writingResult.passed, isTrue);
      final writingEvidence = ProductiveMasteryEvidence(
        assessmentItemId: writing.assessmentItemId,
        canDoSegmentId: writing.canDoSegmentId,
        courseUnitId: writing.courseUnitId,
        missionContentLinkId: writing.missionContentLinkId,
        conceptId: writing.conceptIds.single,
        evidenceMode: SegmentEvidenceMode.openWriting,
        rubricVersion: 1,
        score: 1,
        occurredAt: occurredAt,
        courseEligible: true,
        definitionFingerprint: writing.authorityFingerprint,
      );
      final gateway = _RecordingPronunciationGateway();
      const engine = ProductiveOralAssessmentEngine();

      final withoutConsent = await engine.evaluate(
        definition: oral,
        referenceWritingResult: writingResult,
        referenceWritingEvidence: writingEvidence,
        gateway: gateway,
        pcm16: Uint8List.fromList([0, 0]),
        userConsented: false,
        occurredAt: occurredAt.add(const Duration(minutes: 1)),
      );
      expect(withoutConsent.passed, isFalse);
      expect(gateway.calls, 0);

      final readAloud = await engine.evaluate(
        definition: oral,
        referenceWritingResult: writingResult,
        referenceWritingEvidence: writingEvidence,
        gateway: gateway,
        pcm16: Uint8List.fromList([0, 0]),
        userConsented: true,
        occurredAt: occurredAt.add(const Duration(minutes: 2)),
      );
      expect(readAloud.passed, isFalse);
      expect(gateway.calls, 0);

      const anchorRichWritingText =
          '제 판단부터 말하면 첫 번째 자료가 보여 주는 경험은 중요합니다. '
          '우선 그 판단의 근거로 첫 번째 자료와 두 번째 자료를 함께 살펴보겠습니다. '
          '그러나 다만 주의할 한계는 비교 집단이 없어서 인과관계를 확정하기 어렵다는 점입니다. '
          '따라서 종합해서 말씀드리면 다른 지역 자료까지 확인한 뒤 결론을 다시 검토해야 합니다.';
      final anchorRichSubmission = ProductiveStructuredWritingSubmission(
        text: anchorRichWritingText,
        slotValues: const {
          'claim': '제 판단부터 말하면 첫 번째 자료가 보여 주는 경험은 중요합니다',
          'support': '우선 그 판단의 근거로 첫 번째 자료와 두 번째 자료를 함께 살펴보겠습니다',
          'limitation': '그러나 다만 주의할 한계는 비교 집단이 없어서 인과관계를 확정하기 어렵다는 점입니다',
          'conclusion': '따라서 종합해서 말씀드리면 다른 지역 자료까지 확인한 뒤 결론을 다시 검토해야 합니다',
        },
        linkedSourceSpanIds: const {
          'claim': ['snippet_test_01'],
          'support': ['snippet_test_01', 'snippet_test_02'],
          'limitation': ['snippet_test_02'],
          'conclusion': ['snippet_test_01', 'snippet_test_02'],
        },
      );
      final anchorRichWritingResult = const ProductiveTextAssessmentEngine()
          .evaluateStructured(
            catalog: fixture.catalog,
            definition: writing,
            submission: anchorRichSubmission,
            occurredAt: occurredAt.add(const Duration(seconds: 150)),
          );
      expect(anchorRichWritingResult.passed, isTrue);
      final anchorRichWritingEvidence = ProductiveMasteryEvidence(
        assessmentItemId: writing.assessmentItemId,
        canDoSegmentId: writing.canDoSegmentId,
        courseUnitId: writing.courseUnitId,
        missionContentLinkId: writing.missionContentLinkId,
        conceptId: writing.conceptIds.single,
        evidenceMode: SegmentEvidenceMode.openWriting,
        rubricVersion: 1,
        score: anchorRichWritingResult.score,
        occurredAt: anchorRichWritingResult.occurredAt,
        courseEligible: true,
        definitionFingerprint: writing.authorityFingerprint,
      );
      final nearVerbatimTranscripts = [
        anchorRichWritingText,
        anchorRichWritingText.replaceAll('.', '   '),
        anchorRichWritingText.replaceFirst('중요합니다', '중요해요'),
        '$anchorRichWritingText 덧붙여 같은 판단을 한 번 더 강조하겠습니다. '
            '이 추가 문장은 앞서 쓴 내용을 바꾸지 않습니다.',
        anchorRichWritingText.replaceFirst(
          '비교 집단이 없어서 인과관계를 확정하기 어렵다는 점입니다',
          '',
        ),
      ];
      for (var index = 0; index < nearVerbatimTranscripts.length; index++) {
        final nearVerbatim = await engine.evaluateProduction(
          catalog: fixture.catalog,
          definition: oral,
          referenceWritingResult: anchorRichWritingResult,
          referenceWritingEvidence: anchorRichWritingEvidence,
          referenceWritingSubmission: anchorRichSubmission,
          authority: _RecordingOralProductionAuthority(
            nearVerbatimTranscripts[index],
          ),
          pcm16: Uint8List.fromList([0, 0]),
          userConsented: true,
          occurredAt: occurredAt.add(Duration(minutes: 3 + index)),
        );
        expect(nearVerbatim.passed, isFalse);
        expect(
          nearVerbatim.criteria
              .singleWhere(
                (criterion) => criterion.id == 'not_near_verbatim_read_aloud',
              )
              .matched,
          isFalse,
        );
      }

      const oralParaphrase =
          '제 판단부터 말하면 두 자료만으로 정책 효과를 확정하기는 어렵습니다. '
          '우선 그 판단의 근거로 자료 1에는 참여 경험이 담겼지만 자료 2에는 비교 집단이 없다는 점을 들겠습니다. '
          '그러나 다만 주의할 한계는 한 지역의 짧은 관찰을 전체 상황으로 넓혀 해석할 수 없다는 것입니다. '
          '따라서 추가 지역을 조사해야 하며, 종합해서 말씀드리면 새 근거를 반영해 잠정 결론을 다시 검토하겠습니다.';
      final authority = _RecordingOralProductionAuthority(oralParaphrase);
      final passed = await engine.evaluateProduction(
        catalog: fixture.catalog,
        definition: oral,
        referenceWritingResult: writingResult,
        referenceWritingEvidence: writingEvidence,
        referenceWritingSubmission: submission,
        authority: authority,
        pcm16: Uint8List.fromList([0, 0]),
        userConsented: true,
        occurredAt: occurredAt.add(const Duration(minutes: 7)),
      );
      expect(passed.passed, isTrue);
      expect(passed.assessmentAttemptId, authority.lastAssessmentAttemptId);
      expect(authority.locale, 'ko-KR');

      final evidence = ProductiveMasteryEvidence(
        assessmentItemId: oral.assessmentItemId,
        canDoSegmentId: oral.canDoSegmentId,
        courseUnitId: oral.courseUnitId,
        missionContentLinkId: oral.missionContentLinkId,
        conceptId: oral.conceptIds.single,
        evidenceMode: SegmentEvidenceMode.oralProduction,
        rubricVersion: 1,
        score: passed.score,
        occurredAt: passed.occurredAt,
        courseEligible: true,
        definitionFingerprint: oral.authorityFingerprint,
        prerequisiteEvidenceIds: [writingEvidence.id],
        oralScore: passed.oralScore,
        assessmentAttemptId: passed.assessmentAttemptId,
      );
      expect(evidence.toJson(), isNot(contains('referenceText')));
      expect(evidence.toJson(), isNot(contains('audio')));
      expect(evidence.toJson(), isNot(contains('transcript')));
      expect(evidence.oralScore!.durationMilliseconds, 60000);
    },
  );
}

ProductiveAssessmentDefinition _textDefinition({
  required String suffix,
  required SegmentEvidenceMode mode,
  required List<ProductiveTextCriterion> criteria,
  ProductiveTextRubric? rubric,
}) {
  final snakeMode = switch (mode) {
    SegmentEvidenceMode.guidedProduction => 'guided_production',
    SegmentEvidenceMode.dictation => 'dictation',
    SegmentEvidenceMode.connectedProduction => 'connected_production',
    SegmentEvidenceMode.openWriting => 'open_writing',
    SegmentEvidenceMode.oralProduction => 'oral_production',
    SegmentEvidenceMode.connectedEvidence => 'connected_evidence',
  };
  return ProductiveAssessmentDefinition(
    canDoSegmentId: 'segment_$suffix',
    assessmentItemId: 'assess_${suffix}_${snakeMode}_v1',
    missionContentLinkId: 'mission_${suffix}_${snakeMode}_v1',
    level: suffix.startsWith('c1') ? LearnerLevel.c1 : LearnerLevel.a1,
    courseUnitId: suffix.startsWith('c1') ? 'unit_c1' : 'unit_a1',
    conceptIds: [
      suffix.startsWith('c1') ? 'concept_claim' : 'concept_greeting',
    ],
    evidenceMode: mode,
    rubricVersion: 1,
    minimumScore: .7,
    prompt: _text,
    roleInstruction: _text,
    textRubric: rubric ?? ProductiveTextRubric(criteria: criteria),
  );
}

_AdvancedFixture _advancedFixture() {
  final writing = ProductiveAssessmentDefinition(
    canDoSegmentId: 'segment_c1_test',
    assessmentItemId: 'assess_c1_test_open_writing_v1',
    missionContentLinkId: 'mission_c1_test_open_writing_v1',
    level: LearnerLevel.c1,
    courseUnitId: 'unit_c1',
    conceptIds: const ['concept_claim'],
    evidenceMode: SegmentEvidenceMode.openWriting,
    rubricVersion: 1,
    minimumScore: .7,
    prompt: _text,
    roleInstruction: _text,
    textRubric: ProductiveTextRubric(
      minInputCodePoints: 30,
      maxInputCodePoints: 300,
      requiredStructuredSlotIds: const [
        'claim',
        'support',
        'limitation',
        'conclusion',
      ],
      minimumDistinctSourceSpanIds: 2,
      discourseMarkerGroups: const [
        ['그러나'],
        ['따라서'],
        ['다시'],
      ],
      criteria: [
        ProductiveTextCriterion(
          id: 'required_conclusion',
          kind: ProductiveCriterionKind.tokenSequence,
          acceptedVariants: const ['다시 검토해야 합니다'],
          weight: 1,
          requiredForPass: true,
        ),
      ],
    ),
  );
  final oral = ProductiveAssessmentDefinition(
    canDoSegmentId: 'segment_c1_test',
    assessmentItemId: 'assess_c1_test_oral_production_v1',
    missionContentLinkId: 'mission_c1_test_oral_production_v1',
    level: LearnerLevel.c1,
    courseUnitId: 'unit_c1',
    conceptIds: const ['concept_claim'],
    evidenceMode: SegmentEvidenceMode.oralProduction,
    rubricVersion: 1,
    minimumScore: .7,
    prompt: _text,
    roleInstruction: _text,
    prerequisiteAssessmentItemIds: [writing.assessmentItemId],
    oralRubric: ProductiveOralRubric(
      minimumPronunciation: .7,
      minimumAccuracy: .7,
      minimumFluency: .7,
      minimumDurationMilliseconds: 45000,
      maximumDurationMilliseconds: 120000,
      minimumTranscriptCodePoints: 120,
      requiredSemanticSlotIds: const [
        'claim',
        'support',
        'limitation',
        'conclusion',
      ],
      semanticSlotMentionVariants: const {
        'claim': ['제 판단부터 말하면'],
        'support': ['그 판단의 근거로'],
        'limitation': ['다만 주의할 한계는'],
        'conclusion': ['종합해서 말씀드리면'],
      },
      requiredSourceSnippetIds: const ['snippet_test_01', 'snippet_test_02'],
      oneOfSourceGroups: const [],
      sourceMentionVariants: const {
        'snippet_test_01': ['첫 번째 자료', '자료 1'],
        'snippet_test_02': ['두 번째 자료', '자료 2'],
      },
      discourseMarkerGroups: const [
        ['우선'],
        ['그러나'],
        ['따라서'],
      ],
    ),
  );
  final connected = ProductiveAssessmentDefinition(
    canDoSegmentId: 'segment_c1_test',
    assessmentItemId: 'assess_c1_test_connected_evidence_v1',
    missionContentLinkId: 'mission_c1_test_connected_evidence_v1',
    level: LearnerLevel.c1,
    courseUnitId: 'unit_c1',
    conceptIds: const ['concept_claim'],
    evidenceMode: SegmentEvidenceMode.connectedEvidence,
    rubricVersion: 1,
    minimumScore: .7,
    prompt: _text,
    roleInstruction: _text,
    connectedEvidenceRubric: ProductiveConnectedEvidenceRubric(
      requiredRoles: const [
        ProductiveEvidenceRole.support,
        ProductiveEvidenceRole.limitation,
      ],
      requiredSourceSnippetIds: const ['snippet_test_01', 'snippet_test_02'],
      relationshipRequirements: [
        ProductiveEvidenceRelationshipRequirement(
          id: 'support_key',
          role: ProductiveEvidenceRole.support,
          oneOfSourceSnippetIds: const ['snippet_test_01'],
        ),
        ProductiveEvidenceRelationshipRequirement(
          id: 'limitation_key',
          role: ProductiveEvidenceRole.limitation,
          oneOfSourceSnippetIds: const ['snippet_test_02'],
        ),
      ],
    ),
  );
  final project = ProductiveProjectDefinition(
    id: 'project_test_v1',
    steps: [
      ProductiveProjectStep(
        id: 'step_test_01',
        order: 1,
        snippetIds: const ['snippet_test_01'],
        prerequisiteStepIds: const [],
        action: _text,
        assessmentItemIds: const [],
      ),
      ProductiveProjectStep(
        id: 'step_test_02',
        order: 2,
        snippetIds: const ['snippet_test_01', 'snippet_test_02'],
        prerequisiteStepIds: const ['step_test_01'],
        action: _text,
        assessmentItemIds: [
          writing.assessmentItemId,
          oral.assessmentItemId,
          connected.assessmentItemId,
        ],
      ),
      ProductiveProjectStep(
        id: 'step_test_03',
        order: 3,
        snippetIds: const [
          'snippet_test_01',
          'snippet_test_02',
          'snippet_test_03',
        ],
        prerequisiteStepIds: const ['step_test_02'],
        action: _text,
        assessmentItemIds: const [],
      ),
      ProductiveProjectStep(
        id: 'step_test_04',
        order: 4,
        snippetIds: const [
          'snippet_test_01',
          'snippet_test_02',
          'snippet_test_03',
          'snippet_test_04',
        ],
        prerequisiteStepIds: const ['step_test_03'],
        action: _text,
        assessmentItemIds: const [],
      ),
    ],
  );
  final snippets = [
    _snippet('01', 'step_test_01', const [ProductiveEvidenceRole.support]),
    _snippet('02', 'step_test_02', const [ProductiveEvidenceRole.limitation]),
    _snippet('03', 'step_test_03', const [ProductiveEvidenceRole.limitation]),
    _snippet('04', 'step_test_04', const [ProductiveEvidenceRole.context]),
  ];
  final catalog = ProductiveAssessmentCatalog.fromDefinitions(
    [writing, oral, connected],
    projects: [project],
    sourceSnippets: snippets,
    bundles: [
      ProductiveAssessmentBundle(
        canDoSegmentId: 'segment_c1_test',
        projectId: project.id,
        stepId: 'step_test_02',
        assessmentItemIds: [
          writing.assessmentItemId,
          oral.assessmentItemId,
          connected.assessmentItemId,
        ],
      ),
    ],
  );
  return _AdvancedFixture(
    catalog: catalog,
    writing: writing,
    oral: oral,
    connected: connected,
  );
}

ProductiveSourceSnippet _snippet(
  String number,
  String stepId,
  List<ProductiveEvidenceRole> roles,
) => ProductiveSourceSnippet(
  id: 'snippet_test_$number',
  projectId: 'project_test_v1',
  stepId: stepId,
  provenance: _text,
  text: _text,
  supportedRoles: roles,
);

final class _AdvancedFixture {
  const _AdvancedFixture({
    required this.catalog,
    required this.writing,
    required this.oral,
    required this.connected,
  });

  final ProductiveAssessmentCatalog catalog;
  final ProductiveAssessmentDefinition writing;
  final ProductiveAssessmentDefinition oral;
  final ProductiveAssessmentDefinition connected;
}

final class _RecordingPronunciationGateway
    implements PronunciationAssessmentGateway {
  int calls = 0;
  String? lastAssessmentId;
  String? lastReferenceText;

  @override
  Future<PronunciationAssessmentResult> assess({
    required Uint8List pcm16,
    required String referenceText,
    required String assessmentId,
  }) async {
    calls++;
    lastAssessmentId = assessmentId;
    lastReferenceText = referenceText;
    return PronunciationAssessmentResult(
      assessmentId: assessmentId,
      pronunciationScore: 82,
      accuracyScore: 84,
      fluencyScore: 80,
      completenessScore: 86,
    );
  }
}

final class _RecordingOralProductionAuthority
    implements ProductiveOralProductionAuthority {
  _RecordingOralProductionAuthority(this.transcript);

  final String transcript;
  String? lastAssessmentAttemptId;
  String? locale;

  @override
  Future<ProductiveOralProductionAuthorityResult> assessUnscripted({
    required Uint8List pcm16,
    required String locale,
    required String assessmentAttemptId,
  }) async {
    this.locale = locale;
    lastAssessmentAttemptId = assessmentAttemptId;
    return ProductiveOralProductionAuthorityResult(
      assessmentAttemptId: assessmentAttemptId,
      recognizedTranscript: transcript,
      durationMilliseconds: 60000,
      pronunciation: .82,
      accuracy: .84,
      fluency: .8,
    );
  }
}
