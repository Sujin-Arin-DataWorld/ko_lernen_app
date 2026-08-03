import '../models/course_practice_context.dart';
import '../models/curriculum.dart';

/// A route opened from a mission's practice list. The original libraries stay
/// available, while course-aware games receive the mission ID and can filter
/// their question pool to its graph links.
class CourseMissionDestination {
  const CourseMissionDestination({required this.route, this.arguments});

  final String route;
  final Object? arguments;
}

/// Returns trusted-looking mission provenance only for the activity family
/// expected by a route. Direct library arguments intentionally fall back to
/// browse mode instead of becoming unlock evidence.
CoursePracticeContext? coursePracticeContextFromRouteArguments(
  Object? arguments,
  CurriculumContentKind expectedKind,
) {
  if (arguments is! CoursePracticeContext || !arguments.isFor(expectedKind)) {
    return null;
  }
  return arguments;
}

CourseMissionDestination? destinationForCourseLink(ContentLink link) {
  switch (link.contentKind) {
    case CurriculumContentKind.scenario:
      return CourseMissionDestination(
        route: '/scenario',
        arguments: link.contentId,
      );
    case CurriculumContentKind.vocab:
      return CourseMissionDestination(
        route: '/vocab',
        arguments: link.courseUnitId,
      );
    case CurriculumContentKind.grammar:
      return CourseMissionDestination(
        route: '/grammar',
        arguments: CoursePracticeContext.fromLink(link),
      );
    case CurriculumContentKind.smalltalk:
      return CourseMissionDestination(
        route: '/smalltalk',
        arguments: CoursePracticeContext.fromLink(link),
      );
    case CurriculumContentKind.cloze:
      return CourseMissionDestination(
        route: '/cloze',
        arguments: link.courseUnitId,
      );
    case CurriculumContentKind.satz:
      return CourseMissionDestination(
        route: '/satz_arcade',
        arguments: link.courseUnitId,
      );
  }
}
