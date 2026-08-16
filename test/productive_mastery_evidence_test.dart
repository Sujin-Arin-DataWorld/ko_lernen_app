import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/can_do_segment.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/productive_mastery.dart';

void main() {
  final occurredAt = DateTime.utc(2026, 8, 16, 12);

  test('productive evidence round-trips without raw learner input', () {
    final evidence = ProductiveMasteryEvidence(
      assessmentItemId: 'assess_a1_greeting_guided_production_v1',
      canDoSegmentId: 'segment_a1_greeting',
      courseUnitId: 'a1_01_greetings_hangul',
      missionContentLinkId: 'mission_a1_greeting_guided_production_v1',
      conceptId: 'concept_greeting',
      evidenceMode: SegmentEvidenceMode.guidedProduction,
      rubricVersion: 1,
      score: .8,
      occurredAt: occurredAt,
      courseEligible: true,
      definitionFingerprint: 'definition_test_greeting_v1',
      coverage: ProductiveEvidenceCoverage(
        matchedCriterionIds: const ['greeting'],
      ),
    );

    final json = evidence.toJson();
    expect(
      json.keys,
      isNot(
        containsAll(<String>[
          'answer',
          'input',
          'rawText',
          'audio',
          'transcript',
          'referenceText',
        ]),
      ),
    );
    expect(ProductiveMasteryEvidence.fromJson(json).toJson(), json);
    expect(evidence.logicalSlotId, contains('concept_greeting'));
    expect(json['evaluatorVersion'], productiveEvaluatorVersion);
    expect(json['definitionFingerprint'], 'definition_test_greeting_v1');
    expect(json['resultFingerprint'], isNotEmpty);
    expect((json['coverage']! as Map<String, dynamic>)['matchedCriterionIds'], [
      'greeting',
    ]);

    final mutated = Map<String, dynamic>.from(json)..['score'] = .9;
    expect(
      () => ProductiveMasteryEvidence.fromJson(mutated),
      throwsFormatException,
    );
    final mutatedCoverage = Map<String, dynamic>.from(json)
      ..['coverage'] = {
        ...(json['coverage']! as Map<String, dynamic>),
        'matchedCriterionIds': const <String>[],
      };
    expect(
      () => ProductiveMasteryEvidence.fromJson(mutatedCoverage),
      throwsFormatException,
    );
  });

  test('oral proof requires trusted dimensions and attempt provenance', () {
    expect(
      () => ProductiveMasteryEvidence(
        assessmentItemId: 'assess_c1_claim_oral_production_v1',
        canDoSegmentId: 'segment_c1_claim',
        courseUnitId: 'c1_unit',
        missionContentLinkId: 'mission_c1_claim_oral_production_v1',
        conceptId: 'concept_claim',
        evidenceMode: SegmentEvidenceMode.oralProduction,
        rubricVersion: 1,
        score: .8,
        occurredAt: occurredAt,
        courseEligible: true,
        definitionFingerprint: 'definition_test_oral_v1',
        coverage: ProductiveEvidenceCoverage(),
      ),
      throwsFormatException,
    );

    final evidence = ProductiveMasteryEvidence(
      assessmentItemId: 'assess_c1_claim_oral_production_v1',
      canDoSegmentId: 'segment_c1_claim',
      courseUnitId: 'c1_unit',
      missionContentLinkId: 'mission_c1_claim_oral_production_v1',
      conceptId: 'concept_claim',
      evidenceMode: SegmentEvidenceMode.oralProduction,
      rubricVersion: 1,
      score: .8,
      occurredAt: occurredAt,
      courseEligible: true,
      definitionFingerprint: 'definition_test_oral_v1',
      coverage: ProductiveEvidenceCoverage(
        matchedCriterionIds: const [
          'duration',
          'transcript_length',
          'not_near_verbatim_read_aloud',
          'pronunciation',
          'accuracy',
          'fluency',
          'semantic_slots',
          'required_sources',
          'oral_discourse:0',
          'oral_discourse:1',
          'oral_discourse:2',
        ],
        semanticSlotIds: const [
          'claim',
          'evidence',
          'limitation',
          'conclusion',
        ],
        sourceSnippetIds: const ['snippet_01', 'snippet_02'],
      ),
      oralScore: ProductiveOralScore(
        pronunciation: .8,
        accuracy: .81,
        fluency: .82,
        durationMilliseconds: 60000,
        transcriptCodePoints: 180,
        semanticSlotIds: const [
          'claim',
          'evidence',
          'limitation',
          'conclusion',
        ],
        sourceSnippetIds: const ['snippet_01', 'snippet_02'],
        discourseMarkerGroupIds: const [
          'oral_discourse:0',
          'oral_discourse:1',
          'oral_discourse:2',
        ],
      ),
      assessmentAttemptId: 'productive_oral_attempt_12345678',
    );

    expect(evidence.toJson()['assessmentAttemptId'], isNotEmpty);
    expect(evidence.toJson(), isNot(contains('referenceText')));
    expect(evidence.toJson(), isNot(contains('transcript')));
  });

  test('v2 migration never backfills productive proof', () {
    final forged = ProductiveMasteryEvidence(
      assessmentItemId: 'assess_a1_greeting_guided_production_v1',
      canDoSegmentId: 'segment_a1_greeting',
      courseUnitId: 'a1_01_greetings_hangul',
      missionContentLinkId: 'mission_a1_greeting_guided_production_v1',
      conceptId: 'concept_greeting',
      evidenceMode: SegmentEvidenceMode.guidedProduction,
      rubricVersion: 1,
      score: 1,
      occurredAt: occurredAt,
      courseEligible: true,
      definitionFingerprint: 'definition_test_greeting_v1',
      coverage: ProductiveEvidenceCoverage(
        matchedCriterionIds: const ['greeting'],
      ),
    );
    final migrated = CourseMasterySnapshot.decodeAndMigrate({
      'version': 2,
      'completedUnitIds': const ['a1_01_greetings_hangul'],
      'bypassedPrerequisiteUnitIds': const <String>[],
      'evidence': const <Object>[],
      'scenarioCheckpoints': const <Object>[],
      'productiveEvidence': [forged.toJson()],
    });

    expect(migrated.version, 3);
    expect(migrated.completedUnitIds, ['a1_01_greetings_hangul']);
    expect(migrated.productiveEvidence, isEmpty);
    expect(migrated.toJson()['productiveEvidence'], isEmpty);
  });

  test('canonical v3 requires an explicit immutable evidence list', () {
    expect(
      () => CourseMasterySnapshot.decodeAndMigrate({
        'version': 3,
        'completedUnitIds': const <String>[],
        'bypassedPrerequisiteUnitIds': const <String>[],
        'evidence': const <Object>[],
        'scenarioCheckpoints': const <Object>[],
      }),
      throwsFormatException,
    );
  });

  test(
    'project step receipt round-trips without source body or learner text',
    () {
      final receipt = ProductiveProjectStepEvidence(
        projectId: 'project_c1_evidence_v1',
        stepId: 'step_c1_evidence_01_v1',
        stepOrder: 1,
        courseUnitId: 'c1_01_evidence_public_reasoning',
        authorityFingerprint: 'project_step_authority_test_v1',
        reviewedSourceSnippetIds: const ['snippet_c1_evidence_01_v1'],
      );
      final json = receipt.toJson();
      expect(ProductiveProjectStepEvidence.fromJson(json).toJson(), json);
      expect(
        json.keys,
        isNot(
          containsAll(['answer', 'note', 'sourceText', 'audio', 'transcript']),
        ),
      );
      expect(
        () => ProductiveProjectStepEvidence.fromJson({
          ...json,
          'id': 'forged_receipt_id',
        }),
        throwsFormatException,
      );
    },
  );
}
