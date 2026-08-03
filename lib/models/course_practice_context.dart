import 'curriculum.dart';

/// Route provenance for an activity opened from a course mission.
///
/// It deliberately captures the graph link that opened the screen. The mastery
/// service validates the link against the catalog before allowing an attempt to
/// become course-eligible; a caller cannot grant eligibility with a UI flag.
class CoursePracticeContext {
  const CoursePracticeContext({
    required this.courseUnitId,
    required this.contentKind,
    required this.initialContentId,
    required this.contentLinkId,
  });

  factory CoursePracticeContext.fromLink(ContentLink link) =>
      CoursePracticeContext(
        courseUnitId: link.courseUnitId,
        contentKind: link.contentKind,
        initialContentId: link.contentId,
        contentLinkId: link.id,
      );

  final String courseUnitId;
  final CurriculumContentKind contentKind;
  final String initialContentId;
  final String contentLinkId;

  bool isFor(CurriculumContentKind expectedKind) =>
      contentKind == expectedKind &&
      courseUnitId.trim().isNotEmpty &&
      initialContentId.trim().isNotEmpty &&
      contentLinkId.trim().isNotEmpty;
}
