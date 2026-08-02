import '../models/curriculum.dart';

/// A route opened from a mission's practice list. The original libraries stay
/// available, while course-aware games receive the mission ID and can filter
/// their question pool to its graph links.
class CourseMissionDestination {
  const CourseMissionDestination({required this.route, this.arguments});

  final String route;
  final Object? arguments;
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
        arguments: link.courseUnitId,
      );
    case CurriculumContentKind.smalltalk:
      return const CourseMissionDestination(route: '/smalltalk');
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
