import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/services/canonical_course_segment_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'canonical productive catalog binds all 86 immutable segments',
    () async {
      final bundle = await CanonicalCourseSegmentLoader.load();

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
