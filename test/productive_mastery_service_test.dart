import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/can_do_segment.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/productive_mastery.dart';
import 'package:ko_lernen_app/services/canonical_course_segment_loader.dart';
import 'package:ko_lernen_app/services/course_mastery_service.dart';
import 'package:ko_lernen_app/services/course_segment_catalog.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/productive_assessment_service.dart';

import 'support/productive_assessment_fixture.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    Storage.resetCourseMasteryForTesting();
    await Storage.init();
  });

  test('write boundary rejects a pass from an easier shadow rubric', () async {
    final fixture = await _fixture();
    final canonical = fixture
        .productive
        .definitionsById['assess_a1_01_greetings_hangul_guided_production_v1']!;
    final shadow = ProductiveAssessmentDefinition(
      canDoSegmentId: canonical.canDoSegmentId,
      assessmentItemId: canonical.assessmentItemId,
      missionContentLinkId: canonical.missionContentLinkId,
      level: canonical.level,
      courseUnitId: canonical.courseUnitId,
      conceptIds: canonical.conceptIds,
      evidenceMode: canonical.evidenceMode,
      rubricVersion: canonical.rubricVersion,
      minimumScore: canonical.minimumScore,
      prompt: canonical.prompt,
      roleInstruction: canonical.roleInstruction,
      textRubric: ProductiveTextRubric(
        criteria: [
          ProductiveTextCriterion(
            id: 'forged_easy_answer',
            kind: ProductiveCriterionKind.exactAnswer,
            acceptedVariants: const ['가'],
            weight: 1,
            requiredForPass: true,
          ),
        ],
      ),
    );
    final forged = const ProductiveTextAssessmentEngine().evaluate(
      definition: shadow,
      input: '가',
      occurredAt: DateTime.utc(2026, 8, 16, 10),
    );
    expect(forged.passed, isTrue);

    await expectLater(
      fixture.service.recordProductiveAssessment(
        result: forged,
        assessmentCatalog: fixture.productive,
        segmentCatalog: fixture.segments,
      ),
      throwsFormatException,
    );
    expect(fixture.service.snapshot.productiveEvidence, isEmpty);
  });

  test(
    'reassessment stores concept proof without moving the course pointer',
    () async {
      final fixture = await _fixture();
      final definition = fixture
          .productive
          .definitionsById['assess_a1_01_greetings_hangul_guided_production_v1']!;
      const engine = ProductiveTextAssessmentEngine();
      final beforeCurrent = fixture.service.snapshot.currentCourseUnitId;
      final beforeCompleted = [...fixture.service.snapshot.completedUnitIds];

      final strong = engine.evaluate(
        definition: definition,
        input: definition.authoredContextExamples.single,
        occurredAt: DateTime.utc(2026, 8, 16, 10),
      );
      expect(strong.passed, isTrue);
      final first = await fixture.service.recordProductiveAssessment(
        result: strong,
        assessmentCatalog: fixture.productive,
        segmentCatalog: fixture.segments,
      );
      expect(first.acceptedEvidence, hasLength(definition.conceptIds.length));
      expect(first.acceptedEvidence.every((item) => item.score == 1), isTrue);
      expect(first.snapshot.currentCourseUnitId, beforeCurrent);
      expect(first.snapshot.completedUnitIds, beforeCompleted);

      final repeated = engine.evaluate(
        definition: definition,
        input: definition.authoredContextExamples.single,
        occurredAt: DateTime.utc(2026, 8, 16, 10),
      );
      expect(repeated.passed, isTrue);
      expect(repeated.score, 1);
      final retried = await fixture.service.recordProductiveAssessment(
        result: repeated,
        assessmentCatalog: fixture.productive,
        segmentCatalog: fixture.segments,
      );

      expect(
        retried.acceptedEvidence.map((item) => item.id),
        first.acceptedEvidence.map((item) => item.id),
      );
      expect(
        retried.acceptedEvidence.every(
          (item) => retried.snapshot.productiveEvidence.any(
            (persisted) => persisted.id == item.id,
          ),
        ),
        isTrue,
      );
      expect(retried.snapshot.currentCourseUnitId, beforeCurrent);
      expect(retried.snapshot.completedUnitIds, beforeCompleted);

      final beforeFailure = jsonEncode(retried.snapshot.toJson());
      final failed = engine.evaluate(
        definition: definition,
        input: '감사합니다.',
        occurredAt: DateTime.utc(2026, 8, 16, 12),
      );
      final unchanged = await fixture.service.recordProductiveAssessment(
        result: failed,
        assessmentCatalog: fixture.productive,
        segmentCatalog: fixture.segments,
      );
      expect(unchanged.acceptedEvidence, isEmpty);
      expect(jsonEncode(unchanged.snapshot.toJson()), beforeFailure);
    },
  );

  test(
    'trusted projection rejects fingerprint-valid but incomplete coverage',
    () async {
      final fixture = await _fixture();
      final definition = fixture.productive.definitions.firstWhere(
        (candidate) =>
            candidate.textRubric != null &&
            !candidate.textRubric!.requiresStructuredSubmission,
      );
      final result = const ProductiveTextAssessmentEngine().evaluate(
        definition: definition,
        input: definition.authoredContextExamples.single,
        occurredAt: DateTime.utc(2026, 8, 16, 12),
      );
      expect(result.passed, isTrue);
      final incompleteCoverage = ProductiveEvidenceCoverage(
        matchedCriterionIds: result.coverage.matchedCriterionIds.skip(1),
        semanticSlotIds: result.coverage.semanticSlotIds,
      );
      final forged = ProductiveMasteryEvidence(
        assessmentItemId: definition.assessmentItemId,
        canDoSegmentId: definition.canDoSegmentId,
        courseUnitId: definition.courseUnitId,
        missionContentLinkId: definition.missionContentLinkId,
        conceptId: definition.conceptIds.first,
        evidenceMode: definition.evidenceMode,
        rubricVersion: definition.rubricVersion,
        score: result.score,
        occurredAt: result.occurredAt,
        courseEligible: true,
        definitionFingerprint: definition.authorityFingerprint,
        coverage: incompleteCoverage,
      );

      expect(
        trustedProductiveMasteryEvidence(
          evidence: [forged],
          assessmentCatalog: fixture.productive,
        ),
        isEmpty,
      );
    },
  );

  test(
    'a stronger retry cannot prune proof anchoring a later oral seal',
    () async {
      final fixture = await _fixture();
      final project = fixture.productive.projects.first;
      final stepTwo = project.steps.singleWhere((step) => step.order == 2);
      final careBundle = fixture.productive.bundles.singleWhere(
        (bundle) =>
            bundle.projectId == project.id && bundle.stepId == stepTwo.id,
      );
      final writing =
          fixture.productive.definitionsById[careBundle.assessmentItemIds
              .singleWhere((id) => id.contains('_open_writing_'))]!;
      final oral =
          fixture.productive.definitionsById[careBundle.assessmentItemIds
              .singleWhere((id) => id.contains('_oral_production_'))]!;
      final conceptId = writing.conceptIds.single;
      final firstWriting = _evidenceFor(
        fixture.productive,
        writing,
        conceptId: conceptId,
        prerequisiteEvidenceIds: const [],
        includeOptionalTextCriteria: false,
        occurredAt: DateTime.utc(2026, 8, 16, 9),
      );
      final oralSeal = _evidenceFor(
        fixture.productive,
        oral,
        conceptId: conceptId,
        prerequisiteEvidenceIds: [firstWriting.id],
        oralDimensionScore: .8,
        occurredAt: DateTime.utc(2026, 8, 16, 10),
        oralScore: _oralScoreFor(oral, .8),
      );
      final targetIndex = fixture.curriculum.courseUnits.indexWhere(
        (unit) => unit.id == writing.courseUnitId,
      );
      final stepOne = project.steps.singleWhere((step) => step.order == 1);
      final stepOneReceipt = _receiptFor(fixture.productive, project, stepOne);
      await fixture.service.applyReconciledSnapshot(
        CourseMasterySnapshot(
          curriculumGeneration: fixture.curriculum.scenarioCorpusGeneration,
          placementLevel: 'a1',
          completedUnitIds: fixture.curriculum.courseUnits
              .take(targetIndex + 1)
              .map((unit) => unit.id)
              .toList(growable: false),
          productiveEvidence: [firstWriting, oralSeal],
          productiveProjectStepEvidence: [stepOneReceipt],
        ),
        expectedGeneration: null,
      );

      final slotValues = <String, String>{
        'claim': '우선 접근 장벽은 이용자의 참여 기회를 실제 환경에서 줄이는 문제입니다.',
        'evidence': '구체적으로 첫 자료와 둘째 자료는 이동 경로와 안내 절차가 함께 영향을 준다고 설명합니다.',
        'limitation': '그러나 두 자료만으로 모든 이용자의 경험을 같은 방식으로 일반화할 수는 없습니다.',
        'conclusion': '따라서 추가 당사자 의견을 확인하고 접근 개선의 책임과 시점을 정해야 합니다.',
      };
      final stronger = const ProductiveTextAssessmentEngine()
          .evaluateStructured(
            catalog: fixture.productive,
            definition: writing,
            submission: ProductiveStructuredWritingSubmission(
              text: slotValues.values.join(' '),
              slotValues: slotValues,
              linkedSourceSpanIds: {
                'claim': [stepTwo.snippetIds[0]],
                'evidence': [stepTwo.snippetIds[1]],
                'limitation': [stepTwo.snippetIds[0]],
                'conclusion': [stepTwo.snippetIds[1]],
              },
            ),
            occurredAt: DateTime.utc(2026, 8, 16, 11),
          );
      expect(stronger.passed, isTrue);
      expect(stronger.score, greaterThan(firstWriting.score));

      final update = await fixture.service.recordProductiveAssessment(
        result: stronger,
        assessmentCatalog: fixture.productive,
        segmentCatalog: fixture.segments,
      );
      expect(update.acceptedEvidence.single.id, firstWriting.id);
      final trusted = trustedProductiveMasteryEvidence(
        evidence: update.snapshot.productiveEvidence,
        assessmentCatalog: fixture.productive,
      );
      expect(
        trusted.map((item) => item.id),
        containsAll([firstWriting.id, oralSeal.id]),
      );
    },
  );

  test(
    'odd project receipts gate step two and step three follows a complete care seal',
    () async {
      final fixture = await _fixture();
      final project = fixture.productive.projects.first;
      final stepOne = project.steps.singleWhere((step) => step.order == 1);
      final stepTwo = project.steps.singleWhere((step) => step.order == 2);
      final stepThree = project.steps.singleWhere((step) => step.order == 3);
      final careBundle = fixture.productive.bundles.singleWhere(
        (bundle) =>
            bundle.projectId == project.id && bundle.stepId == stepTwo.id,
      );
      final writing =
          fixture.productive.definitionsById[careBundle.assessmentItemIds
              .singleWhere((id) => id.contains('_open_writing_'))]!;
      final targetIndex = fixture.curriculum.courseUnits.indexWhere(
        (unit) => unit.id == writing.courseUnitId,
      );
      await fixture.service.applyReconciledSnapshot(
        CourseMasterySnapshot(
          curriculumGeneration: fixture.curriculum.scenarioCorpusGeneration,
          placementLevel: 'a1',
          completedUnitIds: fixture.curriculum.courseUnits
              .take(targetIndex + 1)
              .map((unit) => unit.id)
              .toList(growable: false),
        ),
        expectedGeneration: null,
      );

      final writingResult = _structuredWritingResult(
        fixture.productive,
        writing,
        stepTwo,
      );
      expect(writingResult.passed, isTrue);
      await expectLater(
        fixture.service.recordProductiveAssessment(
          result: writingResult,
          assessmentCatalog: fixture.productive,
          segmentCatalog: fixture.segments,
        ),
        throwsStateError,
      );

      const reviewEngine = ProductiveProjectStepReviewEngine();
      final introducedOne = fixture.productive.introducedSourceIdsForStep(
        project.id,
        stepOne.id,
      );
      final incompleteReview = reviewEngine.evaluate(
        catalog: fixture.productive,
        projectId: project.id,
        stepId: stepOne.id,
        reviewedSourceSnippetIds: introducedOne,
        openedProvenanceSnippetIds: const [],
      );
      expect(incompleteReview.passed, isFalse);

      final stepOneResult = reviewEngine.evaluate(
        catalog: fixture.productive,
        projectId: project.id,
        stepId: stepOne.id,
        reviewedSourceSnippetIds: introducedOne,
        openedProvenanceSnippetIds: introducedOne,
      );
      final firstReceipt = await fixture.service.recordProductiveProjectStep(
        result: stepOneResult,
        assessmentCatalog: fixture.productive,
        segmentCatalog: fixture.segments,
      );
      final repeatedReceipt = await fixture.service.recordProductiveProjectStep(
        result: stepOneResult,
        assessmentCatalog: fixture.productive,
        segmentCatalog: fixture.segments,
      );
      expect(
        repeatedReceipt.acceptedEvidence.id,
        firstReceipt.acceptedEvidence.id,
      );
      expect(
        repeatedReceipt.snapshot.productiveProjectStepEvidence,
        hasLength(1),
      );

      await fixture.service.recordProductiveAssessment(
        result: writingResult,
        assessmentCatalog: fixture.productive,
        segmentCatalog: fixture.segments,
      );
      final stepThreeResult = reviewEngine.evaluate(
        catalog: fixture.productive,
        projectId: project.id,
        stepId: stepThree.id,
        reviewedSourceSnippetIds: fixture.productive.introducedSourceIdsForStep(
          project.id,
          stepThree.id,
        ),
        openedProvenanceSnippetIds: fixture.productive
            .introducedSourceIdsForStep(project.id, stepThree.id),
      );
      await expectLater(
        fixture.service.recordProductiveProjectStep(
          result: stepThreeResult,
          assessmentCatalog: fixture.productive,
          segmentCatalog: fixture.segments,
        ),
        throwsStateError,
      );

      final careProof = _proofsForBundle(
        fixture.productive,
        careBundle,
        existing: const [],
      );
      await fixture.service.applyReconciledSnapshot(
        fixture.service.snapshot.copyWith(productiveEvidence: careProof),
        expectedGeneration: null,
      );
      final stepThreeUpdate = await fixture.service.recordProductiveProjectStep(
        result: stepThreeResult,
        assessmentCatalog: fixture.productive,
        segmentCatalog: fixture.segments,
      );
      expect(
        stepThreeUpdate.snapshot.productiveProjectStepEvidence.map(
          (entry) => entry.stepOrder,
        ),
        [1, 3],
      );
    },
  );

  test(
    'all eight advanced projects require receipt-seal-receipt-seal',
    () async {
      final fixture = await _fixture();
      final evidence = <ProductiveMasteryEvidence>[];
      final receipts = <ProductiveProjectStepEvidence>[];
      for (final project in fixture.productive.projects) {
        final stepOne = project.steps.singleWhere((step) => step.order == 1);
        final stepTwo = project.steps.singleWhere((step) => step.order == 2);
        final stepThree = project.steps.singleWhere((step) => step.order == 3);
        final stepFour = project.steps.singleWhere((step) => step.order == 4);
        receipts.add(_receiptFor(fixture.productive, project, stepOne));
        final careBundle = fixture.productive.bundles.singleWhere(
          (bundle) =>
              bundle.projectId == project.id && bundle.stepId == stepTwo.id,
        );
        evidence.addAll(
          _proofsForBundle(fixture.productive, careBundle, existing: evidence),
        );
        receipts.add(_receiptFor(fixture.productive, project, stepThree));
        final transmitBundle = fixture.productive.bundles.singleWhere(
          (bundle) =>
              bundle.projectId == project.id && bundle.stepId == stepFour.id,
        );
        evidence.addAll(
          _proofsForBundle(
            fixture.productive,
            transmitBundle,
            existing: evidence,
          ),
        );
      }

      final verified = verifiedCanDoSegmentIds(
        evidence: evidence,
        projectStepEvidence: receipts,
        segmentCatalog: fixture.segments,
        assessmentCatalog: fixture.productive,
      );
      final advancedSegmentIds = fixture.segments.publishedSegments
          .where((segment) => const {'c1', 'c2'}.contains(segment.level.code))
          .map((segment) => segment.id)
          .toSet();
      expect(advancedSegmentIds, hasLength(16));
      expect(verified, containsAll(advancedSegmentIds));

      final withoutStepThree = receipts
          .where((receipt) => receipt.stepOrder != 3)
          .toList(growable: false);
      final gated = verifiedCanDoSegmentIds(
        evidence: evidence,
        projectStepEvidence: withoutStepThree,
        segmentCatalog: fixture.segments,
        assessmentCatalog: fixture.productive,
      );
      expect(
        gated.intersection(advancedSegmentIds),
        hasLength(8),
        reason: 'Only the eight step-2 CARE segments remain verified.',
      );

      final withoutStepOne = receipts
          .where((receipt) => receipt.stepOrder != 1)
          .toList(growable: false);
      final noPrefix = verifiedCanDoSegmentIds(
        evidence: evidence,
        projectStepEvidence: withoutStepOne,
        segmentCatalog: fixture.segments,
        assessmentCatalog: fixture.productive,
      );
      expect(
        noPrefix.intersection(advancedSegmentIds),
        isEmpty,
        reason: 'Step 4 cannot bypass the missing step-1/step-2 prefix.',
      );
    },
  );

  test(
    'projection rejects forged step-four proof without step-two chain',
    () async {
      final fixture = await _fixture();
      final project = fixture.productive.projects.first;
      final stepFour = project.steps.singleWhere((step) => step.order == 4);
      final laterBundle = fixture.productive.bundles.singleWhere(
        (bundle) =>
            bundle.projectId == project.id && bundle.stepId == stepFour.id,
      );
      final forged = <ProductiveMasteryEvidence>[];
      for (final assessmentId in laterBundle.assessmentItemIds) {
        final definition = fixture.productive.definitionsById[assessmentId]!;
        for (final conceptId in definition.conceptIds) {
          forged.add(
            _evidenceFor(
              fixture.productive,
              definition,
              conceptId: conceptId,
              prerequisiteEvidenceIds: const [],
            ),
          );
        }
      }

      final verified = verifiedCanDoSegmentIds(
        evidence: forged,
        projectStepEvidence: const [],
        segmentCatalog: fixture.segments,
        assessmentCatalog: fixture.productive,
      );
      expect(verified, isNot(contains(laterBundle.canDoSegmentId)));
    },
  );

  test(
    'write boundary rejects transmit prerequisites without their care chain',
    () async {
      final fixture = await _fixture();
      final project = fixture.productive.projects.first;
      final stepTwo = project.steps.singleWhere((step) => step.order == 2);
      final stepFour = project.steps.singleWhere((step) => step.order == 4);
      final careBundle = fixture.productive.bundles.singleWhere(
        (bundle) =>
            bundle.projectId == project.id && bundle.stepId == stepTwo.id,
      );
      final transmitBundle = fixture.productive.bundles.singleWhere(
        (bundle) =>
            bundle.projectId == project.id && bundle.stepId == stepFour.id,
      );
      final transmitWriting =
          fixture.productive.definitionsById[transmitBundle.assessmentItemIds
              .singleWhere((id) => id.contains('_open_writing_'))]!;
      final forgedCare = <ProductiveMasteryEvidence>[
        for (final assessmentId in careBundle.assessmentItemIds)
          for (final conceptId
              in fixture.productive.definitionsById[assessmentId]!.conceptIds)
            _evidenceFor(
              fixture.productive,
              fixture.productive.definitionsById[assessmentId]!,
              conceptId: conceptId,
              prerequisiteEvidenceIds: const [],
            ),
      ];
      final targetIndex = fixture.curriculum.courseUnits.indexWhere(
        (unit) => unit.id == transmitWriting.courseUnitId,
      );
      expect(targetIndex, greaterThanOrEqualTo(0));
      await fixture.service.applyReconciledSnapshot(
        CourseMasterySnapshot(
          curriculumGeneration: fixture.curriculum.scenarioCorpusGeneration,
          placementLevel: 'a1',
          completedUnitIds: fixture.curriculum.courseUnits
              .take(targetIndex + 1)
              .map((unit) => unit.id)
              .toList(growable: false),
          productiveEvidence: forgedCare,
        ),
        expectedGeneration: null,
      );

      final slotValues = <String, String>{
        'claim': '우선 참여형 접근은 당사자가 의사 결정 과정에 직접 참여하도록 보장해야 합니다.',
        'evidence': '구체적으로 여러 이용자의 경험 자료는 접근 장벽이 환경과 절차에서 함께 생긴다고 설명합니다.',
        'limitation': '그러나 제한된 표본만으로 모든 사람의 요구가 같다고 단정할 수는 없습니다.',
        'conclusion': '따라서 추가 의견을 확인하고 책임 주체와 개선 시점을 명확히 정해야 합니다.',
      };
      final submission = ProductiveStructuredWritingSubmission(
        text: slotValues.values.join(' '),
        slotValues: slotValues,
        linkedSourceSpanIds: {
          'claim': [stepFour.snippetIds[2]],
          'evidence': [stepFour.snippetIds[3]],
          'limitation': [stepFour.snippetIds[0]],
          'conclusion': [stepFour.snippetIds[2]],
        },
      );
      final result = const ProductiveTextAssessmentEngine().evaluateStructured(
        catalog: fixture.productive,
        definition: transmitWriting,
        submission: submission,
        occurredAt: DateTime.utc(2026, 8, 16, 13),
      );
      expect(result.passed, isTrue);

      await expectLater(
        fixture.service.recordProductiveAssessment(
          result: result,
          assessmentCatalog: fixture.productive,
          segmentCatalog: fixture.segments,
        ),
        throwsStateError,
      );
      expect(
        fixture.service.snapshot.productiveEvidence.map((item) => item.id),
        unorderedEquals(forgedCare.map((item) => item.id)),
      );
    },
  );

  test('productive proof is not truncated by the legacy evidence cap', () async {
    final fixture = await _fixture();
    final definition = fixture
        .productive
        .definitionsById['assess_a1_01_greetings_hangul_guided_production_v1']!;
    final result = const ProductiveTextAssessmentEngine().evaluate(
      definition: definition,
      input: '안녕하세요. 정보 확인을 부탁합니다.',
      occurredAt: DateTime.utc(2026, 8, 16, 10),
    );
    await fixture.service.recordProductiveAssessment(
      result: result,
      assessmentCatalog: fixture.productive,
      segmentCatalog: fixture.segments,
    );
    final proofIds = fixture.service.snapshot.productiveEvidence
        .map((item) => item.id)
        .toSet();

    for (
      var index = 0;
      index < CourseMasteryService.evidenceCap + 25;
      index++
    ) {
      await fixture.service.recordContentAttempt(
        fixture.curriculum.contentLinks.first.contentKind,
        fixture.curriculum.contentLinks.first.contentId,
        false,
        occurredAt: DateTime.utc(2026, 8, 17).add(Duration(seconds: index)),
      );
    }

    expect(fixture.service.snapshot.evidence.length, lessThanOrEqualTo(300));
    expect(
      fixture.service.snapshot.productiveEvidence.map((item) => item.id),
      containsAll(proofIds),
    );
  });

  test(
    'productive merge is commutative and selects stronger logical proof',
    () async {
      final fixture = await _fixture();
      final project = fixture.productive.projects.first;
      final stepTwo = project.steps.singleWhere((step) => step.order == 2);
      final assessmentBundle = fixture.productive.bundles.singleWhere(
        (candidate) =>
            candidate.projectId == project.id && candidate.stepId == stepTwo.id,
      );
      final definition =
          fixture.productive.definitionsById[assessmentBundle.assessmentItemIds
              .singleWhere((id) => id.contains('_open_writing_'))]!;
      final conceptId = definition.conceptIds.first;
      final low = _evidenceFor(
        fixture.productive,
        definition,
        conceptId: conceptId,
        prerequisiteEvidenceIds: const [],
        includeOptionalTextCriteria: false,
        occurredAt: DateTime.utc(2026, 8, 16, 12),
      );
      final high = _evidenceFor(
        fixture.productive,
        definition,
        conceptId: conceptId,
        prerequisiteEvidenceIds: const [],
        occurredAt: DateTime.utc(2026, 8, 16, 11),
      );
      expect(high.score, greaterThan(low.score));
      CourseMasterySnapshot snapshot(ProductiveMasteryEvidence evidence) =>
          CourseMasterySnapshot(
            curriculumGeneration: fixture.curriculum.scenarioCorpusGeneration,
            productiveEvidence: [evidence],
          );

      final forward = fixture.service.mergeForReconciliation(
        local: snapshot(low),
        remote: snapshot(high),
      );
      final reverse = fixture.service.mergeForReconciliation(
        local: snapshot(high),
        remote: snapshot(low),
      );

      expect(forward.isValid, isTrue);
      expect(forward.snapshot!.productiveEvidence.single.id, high.id);
      expect(
        jsonEncode(forward.snapshot!.toJson()),
        jsonEncode(reverse.snapshot!.toJson()),
      );
    },
  );

  test(
    'project source-review receipt sync is deterministic and additive',
    () async {
      final fixture = await _fixture();
      final project = fixture.productive.projects.first;
      final stepOne = project.steps.singleWhere((step) => step.order == 1);
      final receipt = _receiptFor(fixture.productive, project, stepOne);
      final local = CourseMasterySnapshot(
        curriculumGeneration: fixture.curriculum.scenarioCorpusGeneration,
        productiveProjectStepEvidence: [receipt],
      );
      final remote = CourseMasterySnapshot(
        curriculumGeneration: fixture.curriculum.scenarioCorpusGeneration,
      );

      final forward = fixture.service.mergeForReconciliation(
        local: local,
        remote: remote,
      );
      final reverse = fixture.service.mergeForReconciliation(
        local: remote,
        remote: local,
      );
      expect(forward.isValid, isTrue);
      expect(
        forward.snapshot!.productiveProjectStepEvidence.single.id,
        receipt.id,
      );
      expect(
        jsonEncode(forward.snapshot!.toJson()),
        jsonEncode(reverse.snapshot!.toJson()),
      );
    },
  );

  test(
    'same productive evidence ID with changed body is a typed conflict',
    () async {
      final fixture = await _fixture();
      final definition = fixture.productive.definitions.firstWhere(
        (candidate) =>
            candidate.textRubric != null &&
            !candidate.textRubric!.requiresStructuredSubmission,
      );
      final base = _evidenceFor(
        fixture.productive,
        definition,
        conceptId: definition.conceptIds.first,
        prerequisiteEvidenceIds: const [],
      );
      ProductiveMasteryEvidence evidence(DateTime occurredAt) =>
          ProductiveMasteryEvidence(
            id: 'same-productive-proof-id',
            assessmentItemId: definition.assessmentItemId,
            canDoSegmentId: definition.canDoSegmentId,
            courseUnitId: definition.courseUnitId,
            missionContentLinkId: definition.missionContentLinkId,
            conceptId: definition.conceptIds.first,
            evidenceMode: definition.evidenceMode,
            rubricVersion: definition.rubricVersion,
            score: base.score,
            occurredAt: occurredAt,
            courseEligible: true,
            definitionFingerprint: definition.authorityFingerprint,
            coverage: base.coverage,
          );
      final result = fixture.service.mergeForReconciliation(
        local: CourseMasterySnapshot(
          curriculumGeneration: fixture.curriculum.scenarioCorpusGeneration,
          productiveEvidence: [evidence(DateTime.utc(2026, 8, 16, 12))],
        ),
        remote: CourseMasterySnapshot(
          curriculumGeneration: fixture.curriculum.scenarioCorpusGeneration,
          productiveEvidence: [evidence(DateTime.utc(2026, 8, 16, 13))],
        ),
      );

      expect(result.isValid, isFalse);
      expect(
        result.conflicts,
        contains(
          const CourseMasteryMergeConflict(
            kind: CourseMasteryMergeConflictKind.productiveEvidence,
            id: 'same-productive-proof-id',
          ),
        ),
      );
    },
  );
}

ProductiveProjectStepEvidence _receiptFor(
  ProductiveAssessmentCatalog catalog,
  ProductiveProjectDefinition project,
  ProductiveProjectStep step,
) => ProductiveProjectStepEvidence(
  projectId: project.id,
  stepId: step.id,
  stepOrder: step.order,
  courseUnitId: catalog.courseUnitIdForProjectStep(project.id, step.id),
  authorityFingerprint: catalog.projectStepAuthorityFingerprint(
    project.id,
    step.id,
  ),
  reviewedSourceSnippetIds: catalog.introducedSourceIdsForStep(
    project.id,
    step.id,
  ),
);

ProductiveAssessmentResult _structuredWritingResult(
  ProductiveAssessmentCatalog catalog,
  ProductiveAssessmentDefinition definition,
  ProductiveProjectStep step, {
  DateTime? occurredAt,
  bool includeOptionalTextCriteria = true,
}) {
  final rubric = definition.textRubric!;
  final sources = <String>{...rubric.requiredSourceSnippetIds};
  for (final group in rubric.oneOfSourceGroups) {
    sources.add(group.first);
  }
  for (final sourceId in step.snippetIds) {
    if (sources.length >= rubric.minimumDistinctSourceSpanIds) {
      break;
    }
    sources.add(sourceId);
  }
  final selectedSources = sources.toList(growable: false);
  if (selectedSources.isEmpty || selectedSources.length > 4) {
    throw StateError('Structured test fixture needs one to four sources.');
  }
  final slotValues = <String, String>{
    'claim': includeOptionalTextCriteria
        ? '우선 첫 번째 자료의 핵심 주장은 참여 경험을 구체적으로 보여 준다는 판단입니다.'
        : '우선 첫 번째 자료의 핵심 주장은 참여 경험을 실제로 보여 준다는 판단입니다.',
    'evidence': includeOptionalTextCriteria
        ? '구체적으로 첫 번째 자료와 두 번째 자료는 환경과 절차가 함께 영향을 준다고 설명합니다.'
        : '첫 번째 자료와 두 번째 자료는 환경과 절차가 함께 영향을 준다고 설명합니다.',
    'limitation': '그러나 이 자료만으로 모든 이용자의 경험을 같은 방식으로 일반화할 수는 없습니다.',
    'conclusion': '따라서 추가 자료를 확인하고 책임 주체와 개선 시점을 다시 검토해야 합니다.',
  };
  final slotIds = rubric.requiredStructuredSlotIds;
  return const ProductiveTextAssessmentEngine().evaluateStructured(
    catalog: catalog,
    definition: definition,
    submission: ProductiveStructuredWritingSubmission(
      text: slotValues.values.join(' '),
      slotValues: slotValues,
      linkedSourceSpanIds: {
        for (var index = 0; index < slotIds.length; index++)
          slotIds[index]: [selectedSources[index % selectedSources.length]],
      },
    ),
    occurredAt: occurredAt ?? DateTime.utc(2026, 8, 16, 14),
  );
}

ProductiveAssessmentResult _connectedEvidenceResult(
  ProductiveAssessmentCatalog catalog,
  ProductiveAssessmentDefinition definition,
  DateTime occurredAt,
) {
  final rubric = definition.connectedEvidenceRubric!;
  final bundle = catalog.bundleForSegment(definition.canDoSegmentId)!;
  final step = catalog.projectStepFor(bundle.projectId, bundle.stepId)!;
  final rolesBySource = <String, Set<ProductiveEvidenceRole>>{};

  void addRole(String sourceId, ProductiveEvidenceRole role) {
    final snippet = catalog.snippetsById[sourceId];
    if (snippet == null || !snippet.supportedRoles.contains(role)) {
      return;
    }
    rolesBySource.putIfAbsent(sourceId, () => {}).add(role);
  }

  for (final relationship in rubric.relationshipRequirements) {
    final sourceId = relationship.oneOfSourceSnippetIds.firstWhere(
      (candidate) =>
          step.snippetIds.contains(candidate) &&
          catalog.snippetsById[candidate]!.supportedRoles.contains(
            relationship.role,
          ),
    );
    addRole(sourceId, relationship.role);
  }
  for (final role in rubric.requiredRoles) {
    if (rolesBySource.values.any((roles) => roles.contains(role))) {
      continue;
    }
    final sourceId = step.snippetIds.firstWhere(
      (candidate) =>
          catalog.snippetsById[candidate]!.supportedRoles.contains(role),
    );
    addRole(sourceId, role);
  }
  for (final sourceId in rubric.requiredSourceSnippetIds) {
    if (rolesBySource.containsKey(sourceId)) {
      continue;
    }
    addRole(sourceId, catalog.snippetsById[sourceId]!.supportedRoles.first);
  }
  for (final group in rubric.oneOfSourceGroups) {
    if (group.any(rolesBySource.containsKey)) {
      continue;
    }
    final sourceId = group.firstWhere(step.snippetIds.contains);
    addRole(sourceId, catalog.snippetsById[sourceId]!.supportedRoles.first);
  }
  for (final sourceId in step.snippetIds) {
    if (rolesBySource.length >= rubric.minimumSourceNodes) {
      break;
    }
    addRole(sourceId, catalog.snippetsById[sourceId]!.supportedRoles.first);
  }
  final result = const ProductiveConnectedEvidenceEngine().evaluate(
    catalog: catalog,
    definition: definition,
    nodes: [
      for (final entry in rolesBySource.entries)
        ProductiveEvidenceNode(sourceSnippetId: entry.key, roles: entry.value),
    ],
    occurredAt: occurredAt,
  );
  if (!result.passed) {
    throw StateError(
      'Canonical connected-evidence fixture did not satisfy its rubric.',
    );
  }
  return result;
}

List<ProductiveMasteryEvidence> _proofsForBundle(
  ProductiveAssessmentCatalog catalog,
  ProductiveAssessmentBundle bundle, {
  required List<ProductiveMasteryEvidence> existing,
}) {
  final available = <ProductiveMasteryEvidence>[...existing];
  final pending = bundle.assessmentItemIds
      .map((id) => catalog.definitionsById[id]!)
      .toList();
  final produced = <ProductiveMasteryEvidence>[];
  while (pending.isNotEmpty) {
    final readyIndex = pending.indexWhere(
      (definition) => definition.prerequisiteAssessmentItemIds.every(
        (id) => available.any((entry) => entry.assessmentItemId == id),
      ),
    );
    if (readyIndex < 0) {
      throw StateError('Productive bundle prerequisites cannot be resolved.');
    }
    final definition = pending.removeAt(readyIndex);
    final prerequisiteIds = <String>{
      for (final prerequisiteId in definition.prerequisiteAssessmentItemIds)
        for (final entry in available)
          if (entry.assessmentItemId == prerequisiteId) entry.id,
    }.toList()..sort();
    final records = [
      for (final conceptId in definition.conceptIds)
        _evidenceFor(
          catalog,
          definition,
          conceptId: conceptId,
          prerequisiteEvidenceIds: prerequisiteIds,
        ),
    ];
    available.addAll(records);
    produced.addAll(records);
  }
  return produced;
}

ProductiveMasteryEvidence _evidenceFor(
  ProductiveAssessmentCatalog catalog,
  ProductiveAssessmentDefinition definition, {
  required String conceptId,
  required List<String> prerequisiteEvidenceIds,
  DateTime? occurredAt,
  double oralDimensionScore = 1,
  bool includeOptionalTextCriteria = true,
  ProductiveOralScore? oralScore,
}) {
  final timestamp = occurredAt ?? DateTime.utc(2026, 8, 16, 12);
  final isOral = definition.evidenceMode == SegmentEvidenceMode.oralProduction;
  final resolvedOralScore = isOral
      ? oralScore ?? _oralScoreFor(definition, oralDimensionScore)
      : null;
  final result = isOral
      ? null
      : _resultForDefinition(
          catalog,
          definition,
          timestamp,
          includeOptionalTextCriteria: includeOptionalTextCriteria,
        );
  final resolvedScore = resolvedOralScore == null
      ? result!.score
      : (resolvedOralScore.pronunciation +
                resolvedOralScore.accuracy +
                resolvedOralScore.fluency) /
            3;
  return ProductiveMasteryEvidence(
    assessmentItemId: definition.assessmentItemId,
    canDoSegmentId: definition.canDoSegmentId,
    courseUnitId: definition.courseUnitId,
    missionContentLinkId: definition.missionContentLinkId,
    conceptId: conceptId,
    evidenceMode: definition.evidenceMode,
    rubricVersion: definition.rubricVersion,
    score: resolvedScore,
    occurredAt: timestamp,
    courseEligible: true,
    definitionFingerprint: definition.authorityFingerprint,
    prerequisiteEvidenceIds: prerequisiteEvidenceIds,
    coverage:
        result?.coverage ?? _oralCoverageFor(definition, resolvedOralScore!),
    oralScore: resolvedOralScore,
    assessmentAttemptId: isOral
        ? 'productive_oral_attempt_projection_12345678'
        : null,
  );
}

ProductiveAssessmentResult _resultForDefinition(
  ProductiveAssessmentCatalog catalog,
  ProductiveAssessmentDefinition definition,
  DateTime occurredAt, {
  bool includeOptionalTextCriteria = true,
}) {
  if (definition.textRubric case final rubric?) {
    if (!rubric.requiresStructuredSubmission) {
      final example = definition.authoredContextExamples.single;
      return const ProductiveTextAssessmentEngine().evaluate(
        definition: definition,
        input: example,
        occurredAt: occurredAt,
      );
    }
    final bundle = catalog.bundleForSegment(definition.canDoSegmentId)!;
    final step = catalog.projectStepFor(bundle.projectId, bundle.stepId)!;
    return _structuredWritingResult(
      catalog,
      definition,
      step,
      occurredAt: occurredAt,
      includeOptionalTextCriteria: includeOptionalTextCriteria,
    );
  }
  if (definition.connectedEvidenceRubric != null) {
    return _connectedEvidenceResult(catalog, definition, occurredAt);
  }
  throw StateError('Oral definitions require a trusted oral summary.');
}

ProductiveEvidenceCoverage _oralCoverageFor(
  ProductiveAssessmentDefinition definition,
  ProductiveOralScore score,
) {
  final rubric = definition.oralRubric!;
  return ProductiveEvidenceCoverage(
    matchedCriterionIds: [
      'duration',
      'transcript_length',
      'not_near_verbatim_read_aloud',
      'pronunciation',
      'accuracy',
      'fluency',
      'semantic_slots',
      'required_sources',
      for (var index = 0; index < rubric.oneOfSourceGroups.length; index++)
        'oral_source_group:$index',
      for (var index = 0; index < rubric.discourseMarkerGroups.length; index++)
        'oral_discourse:$index',
    ],
    semanticSlotIds: score.semanticSlotIds,
    sourceSnippetIds: score.sourceSnippetIds,
  );
}

ProductiveOralScore _oralScoreFor(
  ProductiveAssessmentDefinition definition,
  double score,
) {
  final rubric = definition.oralRubric!;
  final sources = <String>{...rubric.requiredSourceSnippetIds};
  for (final group in rubric.oneOfSourceGroups) {
    sources.add(group.first);
  }
  return ProductiveOralScore(
    pronunciation: score,
    accuracy: score,
    fluency: score,
    durationMilliseconds: rubric.minimumDurationMilliseconds,
    transcriptCodePoints: rubric.minimumTranscriptCodePoints,
    semanticSlotIds: rubric.requiredSemanticSlotIds,
    sourceSnippetIds: sources,
    discourseMarkerGroupIds: [
      for (var index = 0; index < rubric.discourseMarkerGroups.length; index++)
        'oral_discourse:$index',
    ],
  );
}

Future<_ServiceFixture> _fixture() async {
  final curriculum = await CurriculumCatalog.load();
  final bundle = await CanonicalCourseSegmentLoader.load(
    curriculumCatalog: curriculum,
    productiveAssessmentCatalog: loadDraftProductiveAssessmentCatalog(),
  );
  final service = CourseMasteryService(curriculum);
  await service.initializeForPlacement('a1');
  return _ServiceFixture(
    service: service,
    curriculum: curriculum,
    segments: bundle.segments,
    productive: bundle.productiveAssessments,
  );
}

final class _ServiceFixture {
  const _ServiceFixture({
    required this.service,
    required this.curriculum,
    required this.segments,
    required this.productive,
  });

  final CourseMasteryService service;
  final CurriculumCatalog curriculum;
  final CourseSegmentCatalog segments;
  final ProductiveAssessmentCatalog productive;
}
