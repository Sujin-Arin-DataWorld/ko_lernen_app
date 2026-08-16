import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/services/canonical_course_segment_loader.dart';
import 'package:ko_lernen_app/services/productive_assessment_service.dart';

import 'support/productive_assessment_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unreviewed learner copy is draft-only and cannot auto-load', () async {
    expect(ProductiveAssessmentCatalog.runtimeContentApproved, isFalse);
    expect(
      File('assets/data/productive_assessments.json').existsSync(),
      isFalse,
    );
    expect(File(draftProductiveAssessmentPath).existsSync(), isTrue);
    await expectLater(
      CanonicalCourseSegmentLoader.load(),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'canonical productive catalog binds all 86 immutable segments',
    () async {
      final bundle = await CanonicalCourseSegmentLoader.load(
        productiveAssessmentCatalog: loadDraftProductiveAssessmentCatalog(),
      );

      expect(bundle.segments.publishedSegments, hasLength(86));
      expect(bundle.productiveAssessments.definitions, hasLength(118));
      expect(bundle.productiveAssessments.projects, hasLength(8));
      expect(bundle.productiveAssessments.sourceSnippets, hasLength(32));
      expect(bundle.productiveAssessments.bundles, hasLength(16));
      expect(
        bundle.productiveAssessments.definitions.where(
          (definition) => definition.prompt.de.trim().isEmpty,
        ),
        isEmpty,
      );
      expect(
        bundle.productiveAssessments.definitions.where(
          (definition) => definition.roleInstruction.en.trim().isEmpty,
        ),
        isEmpty,
      );
    },
  );
}
