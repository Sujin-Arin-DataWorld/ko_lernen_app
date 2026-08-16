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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CanonicalCourseSegmentBundle bundle;
  late ProductiveAssessmentDefinition definition;
  late CourseMasterySnapshot eligibleSnapshot;
  late CourseReassessmentRouteArguments arguments;

  setUpAll(() async {
    bundle = await CanonicalCourseSegmentLoader.load();
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

  testWidgets('a passing original answer stores scored evidence only', (
    tester,
  ) async {
    ProductiveAssessmentResult? recordedResult;
    await tester.pumpWidget(
      _host(
        CourseReassessmentScreen(
          arguments: arguments,
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
            score: 1,
            occurredAt: DateTime.utc(2026, 8, 16, 11),
            courseEligible: true,
            definitionFingerprint: writing.authorityFingerprint,
          ),
      ];
      final snapshot = CourseMasterySnapshot(
        currentCourseUnitId: oral.courseUnitId,
        productiveEvidence: writingEvidence,
      );

      await tester.pumpWidget(
        _host(
          CourseReassessmentScreen(
            arguments: CourseReassessmentRouteArguments(
              courseUnitId: oral.courseUnitId,
              canDoSegmentId: oral.canDoSegmentId,
              assessmentItemId: oral.assessmentItemId,
            ),
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
