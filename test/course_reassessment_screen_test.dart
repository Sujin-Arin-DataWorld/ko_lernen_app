import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/can_do_segment.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/productive_mastery.dart';
import 'package:ko_lernen_app/screens/course_reassessment_screen.dart';
import 'package:ko_lernen_app/services/canonical_course_segment_loader.dart';
import 'package:ko_lernen_app/services/course_mastery_service.dart';
import 'package:ko_lernen_app/services/course_mission_navigation.dart';
import 'package:ko_lernen_app/services/productive_assessment_service.dart';

import 'support/productive_assessment_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CanonicalCourseSegmentBundle bundle;
  late ProductiveAssessmentDefinition definition;
  late CourseMasterySnapshot eligibleSnapshot;
  late CourseReassessmentRouteArguments arguments;

  setUpAll(() async {
    bundle = await CanonicalCourseSegmentLoader.load(
      productiveAssessmentCatalog: loadDraftProductiveAssessmentCatalog(),
    );
    definition = bundle.productiveAssessments.definitions.firstWhere(
      (candidate) =>
          candidate.assessmentItemId ==
          'assess_a1_01_greetings_hangul_guided_production_v1',
    );
    eligibleSnapshot = CourseMasterySnapshot(
      currentCourseUnitId: definition.courseUnitId,
    );
    arguments = CourseReassessmentRouteArguments(
      courseUnitId: definition.courseUnitId,
      canDoSegmentId: definition.canDoSegmentId,
      assessmentItemId: definition.assessmentItemId,
    );
  });

  testWidgets('unreviewed learner copy is blocked in the production route', (
    tester,
  ) async {
    var bundleLoaded = false;
    await tester.pumpWidget(
      _host(
        CourseReassessmentScreen(
          arguments: arguments,
          bundleLoader: () async {
            bundleLoaded = true;
            return bundle;
          },
          snapshotLoader: () async => eligibleSnapshot,
        ),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.text('This assessment could not be loaded safely.'),
    );

    expect(
      find.byKey(const ValueKey('course-reassessment-answer')),
      findsNothing,
    );
    expect(find.text(definition.prompt.en), findsNothing);
    expect(bundleLoaded, isFalse);
  });

  testWidgets('a passing original answer stores scored evidence only', (
    tester,
  ) async {
    ProductiveAssessmentResult? recordedResult;
    await tester.pumpWidget(
      _host(
        CourseReassessmentScreen(
          arguments: arguments,
          allowUnreviewedContentForTesting: true,
          bundleLoader: () async => bundle,
          snapshotLoader: () async => eligibleSnapshot,
          clock: () => DateTime.utc(2026, 8, 16, 12),
          evidenceRecorder:
              ({
                required result,
                required assessmentCatalog,
                required segmentCatalog,
              }) async {
                recordedResult = result;
                final evidence = [
                  for (final conceptId in definition.conceptIds)
                    ProductiveMasteryEvidence(
                      assessmentItemId: definition.assessmentItemId,
                      canDoSegmentId: definition.canDoSegmentId,
                      courseUnitId: definition.courseUnitId,
                      missionContentLinkId: definition.missionContentLinkId,
                      conceptId: conceptId,
                      evidenceMode: definition.evidenceMode,
                      rubricVersion: definition.rubricVersion,
                      score: result.score,
                      occurredAt: result.occurredAt,
                      courseEligible: true,
                      definitionFingerprint: definition.authorityFingerprint,
                      coverage: result.coverage,
                    ),
                ];
                return ProductiveCourseUpdate(
                  snapshot: eligibleSnapshot.copyWith(
                    productiveEvidence: evidence,
                  ),
                  acceptedEvidence: evidence,
                );
              },
        ),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('course-reassessment-answer')),
    );

    await tester.enterText(
      find.byKey(const ValueKey('course-reassessment-answer')),
      '안녕하세요. 반갑습니다.',
    );
    final submit = find.byKey(
      const ValueKey('course-reassessment-submit-writing'),
    );
    await _tapScrollable(tester, submit);
    await _pumpUntilFound(tester, find.text('Evidence passed'));

    expect(recordedResult, isNotNull);
    expect(recordedResult!.passed, isTrue);
    expect(find.text('Evidence passed'), findsOneWidget);
    expect(find.textContaining('안녕하세요. 반갑습니다.'), findsNothing);
  });

  testWidgets('a failed answer is not offered to durable storage', (
    tester,
  ) async {
    var writes = 0;
    await tester.pumpWidget(
      _host(
        CourseReassessmentScreen(
          arguments: arguments,
          allowUnreviewedContentForTesting: true,
          bundleLoader: () async => bundle,
          snapshotLoader: () async => eligibleSnapshot,
          clock: () => DateTime.utc(2026, 8, 16, 12),
          evidenceRecorder:
              ({
                required result,
                required assessmentCatalog,
                required segmentCatalog,
              }) async {
                writes += 1;
                return ProductiveCourseUpdate(
                  snapshot: eligibleSnapshot,
                  acceptedEvidence: const [],
                );
              },
        ),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('course-reassessment-answer')),
    );

    await tester.enterText(
      find.byKey(const ValueKey('course-reassessment-answer')),
      '모르겠어요.',
    );
    final submit = find.byKey(
      const ValueKey('course-reassessment-submit-writing'),
    );
    await _tapScrollable(tester, submit);
    await _pumpUntilFound(tester, find.text('Not secure enough yet'));

    expect(writes, 0);
    expect(find.text('Not secure enough yet'), findsOneWidget);
    expect(find.byKey(const ValueKey('course-reassessment-retry')), findsOne);
  });

  testWidgets(
    'advanced writing records its authored source-review step before input',
    (tester) async {
      final advanced = bundle.productiveAssessments.definitions.firstWhere(
        (candidate) =>
            candidate.evidenceMode == SegmentEvidenceMode.openWriting &&
            candidate.courseUnitId.startsWith('c1_'),
      );
      final assessmentBundle = bundle.productiveAssessments.bundleForSegment(
        advanced.canDoSegmentId,
      )!;
      final project = bundle
          .productiveAssessments
          .projectsById[assessmentBundle.projectId]!;
      final stepOne = project.steps.singleWhere((step) => step.order == 1);
      final sourceIds = bundle.productiveAssessments.introducedSourceIdsForStep(
        project.id,
        stepOne.id,
      );
      var snapshot = CourseMasterySnapshot(
        currentCourseUnitId: advanced.courseUnitId,
      );
      ProductiveProjectStepReviewResult? recorded;

      await tester.pumpWidget(
        _host(
          CourseReassessmentScreen(
            arguments: CourseReassessmentRouteArguments(
              courseUnitId: advanced.courseUnitId,
              canDoSegmentId: advanced.canDoSegmentId,
              assessmentItemId: advanced.assessmentItemId,
            ),
            allowUnreviewedContentForTesting: true,
            bundleLoader: () async => bundle,
            snapshotLoader: () async => snapshot,
            projectStepRecorder:
                ({
                  required result,
                  required assessmentCatalog,
                  required segmentCatalog,
                }) async {
                  recorded = result;
                  final receipt = ProductiveProjectStepEvidence(
                    projectId: result.projectId,
                    stepId: result.stepId,
                    stepOrder: result.stepOrder,
                    courseUnitId: result.courseUnitId,
                    authorityFingerprint: result.authorityFingerprint,
                    evaluatorVersion: result.evaluatorVersion,
                    reviewedSourceSnippetIds: result.reviewedSourceSnippetIds,
                  );
                  snapshot = snapshot.copyWith(
                    productiveProjectStepEvidence: [receipt],
                  );
                  return ProductiveProjectStepUpdate(
                    snapshot: snapshot,
                    acceptedEvidence: receipt,
                  );
                },
          ),
        ),
      );
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('course-reassessment-submit-project-review')),
      );
      expect(
        find.byKey(const ValueKey('course-reassessment-answer')),
        findsNothing,
      );

      for (final sourceId in sourceIds) {
        await _tapScrollable(
          tester,
          find.byKey(ValueKey('course-reassessment-reviewed-$sourceId')),
        );
        await _tapScrollable(
          tester,
          find.byKey(ValueKey('course-reassessment-provenance-$sourceId')),
        );
      }
      await _tapScrollable(
        tester,
        find.byKey(const ValueKey('course-reassessment-submit-project-review')),
      );
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('course-reassessment-answer')),
      );

      expect(recorded, isNotNull);
      expect(recorded!.passed, isTrue);
      expect(recorded!.reviewedSourceSnippetIds, unorderedEquals(sourceIds));
      expect(snapshot.productiveProjectStepEvidence, hasLength(1));
    },
  );

  testWidgets('forged prerequisite evidence cannot open a later task', (
    tester,
  ) async {
    final later = bundle.productiveAssessments.definitions.firstWhere(
      (candidate) => candidate.prerequisiteAssessmentItemIds.isNotEmpty,
    );
    final prerequisite = bundle.productiveAssessments.definitionFor(
      later.prerequisiteAssessmentItemIds.first,
    )!;
    final forged = [
      for (final conceptId in prerequisite.conceptIds)
        ProductiveMasteryEvidence(
          assessmentItemId: prerequisite.assessmentItemId,
          canDoSegmentId: prerequisite.canDoSegmentId,
          courseUnitId: prerequisite.courseUnitId,
          missionContentLinkId: 'link_forged_prerequisite_v1',
          conceptId: conceptId,
          evidenceMode: prerequisite.evidenceMode,
          rubricVersion: prerequisite.rubricVersion,
          score: 1,
          occurredAt: DateTime.utc(2026, 8, 16, 11),
          courseEligible: true,
          definitionFingerprint: prerequisite.authorityFingerprint,
          coverage: ProductiveEvidenceCoverage(),
        ),
    ];
    final snapshot = CourseMasterySnapshot(
      currentCourseUnitId: later.courseUnitId,
      productiveEvidence: forged,
    );

    await tester.pumpWidget(
      _host(
        CourseReassessmentScreen(
          arguments: CourseReassessmentRouteArguments(
            courseUnitId: later.courseUnitId,
            canDoSegmentId: later.canDoSegmentId,
            assessmentItemId: later.assessmentItemId,
          ),
          allowUnreviewedContentForTesting: true,
          bundleLoader: () async => bundle,
          snapshotLoader: () async => snapshot,
        ),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.text('An earlier piece of evidence is still missing'),
    );

    expect(
      find.text('An earlier piece of evidence is still missing'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('course-reassessment-start-oral')),
      findsNothing,
    );
  });

  testWidgets(
    'oral evidence fails closed instead of reusing scripted pronunciation',
    (tester) async {
      final oral = bundle.productiveAssessments.definitions.firstWhere(
        (candidate) =>
            candidate.evidenceMode == SegmentEvidenceMode.oralProduction,
      );
      final writing = bundle.productiveAssessments.definitionFor(
        oral.prerequisiteAssessmentItemIds.first,
      )!;
      final writingResult = _passingStructuredWritingResult(
        bundle.productiveAssessments,
        writing,
        DateTime.utc(2026, 8, 16, 11),
      );
      final writingEvidence = [
        for (final conceptId in writing.conceptIds)
          ProductiveMasteryEvidence(
            assessmentItemId: writing.assessmentItemId,
            canDoSegmentId: writing.canDoSegmentId,
            courseUnitId: writing.courseUnitId,
            missionContentLinkId: writing.missionContentLinkId,
            conceptId: conceptId,
            evidenceMode: writing.evidenceMode,
            rubricVersion: writing.rubricVersion,
            score: writingResult.score,
            occurredAt: writingResult.occurredAt,
            courseEligible: true,
            definitionFingerprint: writing.authorityFingerprint,
            coverage: writingResult.coverage,
          ),
      ];
      final assessmentBundle = bundle.productiveAssessments.bundleForSegment(
        oral.canDoSegmentId,
      )!;
      final project = bundle
          .productiveAssessments
          .projectsById[assessmentBundle.projectId]!;
      final stepOne = project.steps.singleWhere((step) => step.order == 1);
      final stepOneReceipt = _projectReceipt(
        bundle.productiveAssessments,
        project,
        stepOne,
      );
      final snapshot = CourseMasterySnapshot(
        currentCourseUnitId: oral.courseUnitId,
        productiveEvidence: writingEvidence,
        productiveProjectStepEvidence: [stepOneReceipt],
      );

      await tester.pumpWidget(
        _host(
          CourseReassessmentScreen(
            arguments: CourseReassessmentRouteArguments(
              courseUnitId: oral.courseUnitId,
              canDoSegmentId: oral.canDoSegmentId,
              assessmentItemId: oral.assessmentItemId,
            ),
            allowUnreviewedContentForTesting: true,
            bundleLoader: () async => bundle,
            snapshotLoader: () async => snapshot,
          ),
        ),
      );
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('course-reassessment-oral-unavailable')),
      );

      expect(
        find.text('Verified speaking is not available yet'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('course-reassessment-record')),
        findsNothing,
      );
    },
  );

  testWidgets('invalid route arguments fail closed with a retry surface', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const CourseReassessmentScreen.invalid()));
    await _pumpUntilFound(
      tester,
      find.text('This assessment could not be loaded safely.'),
    );

    expect(
      find.text('This assessment could not be loaded safely.'),
      findsOneWidget,
    );
  });
}

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppL10n.localizationsDelegates,
  supportedLocales: AppL10n.supportedLocales,
  home: child,
);

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Timed out waiting for $finder');
}

Future<void> _tapScrollable(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  await tester.dragUntilVisible(
    finder,
    find.byType(ListView),
    const Offset(0, -200),
  );
  await tester.pump();
  await tester.tap(finder);
}

ProductiveProjectStepEvidence _projectReceipt(
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

ProductiveAssessmentResult _passingStructuredWritingResult(
  ProductiveAssessmentCatalog catalog,
  ProductiveAssessmentDefinition definition,
  DateTime occurredAt,
) {
  final rubric = definition.textRubric!;
  final assessmentBundle = catalog.bundleForSegment(definition.canDoSegmentId)!;
  final step = catalog.projectStepFor(
    assessmentBundle.projectId,
    assessmentBundle.stepId,
  )!;
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
  final slotValues = <String, String>{
    'claim': '우선 첫 번째 자료는 참여자의 경험을 구체적으로 보여 준다는 판단입니다.',
    'evidence': '구체적으로 첫 번째 자료와 두 번째 자료는 환경과 절차가 함께 영향을 준다고 설명합니다.',
    'limitation': '그러나 이 자료만으로 모든 이용자의 경험을 같은 방식으로 일반화할 수는 없습니다.',
    'conclusion': '따라서 추가 자료를 확인하고 책임 주체와 개선 시점을 다시 검토해야 합니다.',
  };
  return const ProductiveTextAssessmentEngine().evaluateStructured(
    catalog: catalog,
    definition: definition,
    submission: ProductiveStructuredWritingSubmission(
      text: slotValues.values.join(' '),
      slotValues: slotValues,
      linkedSourceSpanIds: {
        for (
          var index = 0;
          index < rubric.requiredStructuredSlotIds.length;
          index++
        )
          rubric.requiredStructuredSlotIds[index]: [
            selectedSources[index % selectedSources.length],
          ],
      },
    ),
    occurredAt: occurredAt,
  );
}
