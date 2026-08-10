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

/// Typed `/vocab/pack` arguments. Direct library routes retain their legacy
/// string pack IDs; only a matching mission route needs graph provenance.
class VocabPackRouteArguments {
  const VocabPackRouteArguments({
    required this.packId,
    required this.courseContext,
  });

  final String packId;
  final CoursePracticeContext courseContext;
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

/// Keeps the legacy unit-ID route contract for direct library links while
/// preserving typed provenance for a vocab route opened from a course mission.
/// An unknown argument intentionally becomes unrestricted browse mode.
String? courseUnitIdFromVocabRouteArguments(Object? arguments) {
  final context = coursePracticeContextFromRouteArguments(
    arguments,
    CurriculumContentKind.vocab,
  );
  return context?.courseUnitId ?? (arguments is String ? arguments : null);
}

/// Preserves a vocab mission context only for the pack that contains the
/// original graph-linked word. A neighbouring scoped pack must not claim the
/// same step merely because it belongs to the same course unit.
CoursePracticeContext? vocabCourseContextForPack({
  required CoursePracticeContext? courseContext,
  required Iterable<String> contentIds,
}) {
  if (courseContext == null ||
      !courseContext.isFor(CurriculumContentKind.vocab) ||
      !contentIds.contains(courseContext.initialContentId)) {
    return null;
  }
  return courseContext;
}

/// Reads the legacy string pack ID or a typed mission-pack route.
String? vocabPackIdFromRouteArguments(Object? arguments) => switch (arguments) {
  VocabPackRouteArguments(:final packId) => packId,
  String() => arguments,
  _ => null,
};

/// A pack context is accepted only when it is explicitly a vocab context.
CoursePracticeContext? vocabCourseContextFromPackRouteArguments(
  Object? arguments,
) => switch (arguments) {
  VocabPackRouteArguments(:final courseContext)
      when courseContext.isFor(CurriculumContentKind.vocab) =>
    courseContext,
  _ => null,
};

/// Avoids changing direct pack navigation while allowing a mission-link route
/// to retain its immutable provenance through the pack player and a retry.
Object vocabPackRouteArguments({
  required String packId,
  CoursePracticeContext? courseContext,
}) {
  if (courseContext == null ||
      !courseContext.isFor(CurriculumContentKind.vocab)) {
    return packId;
  }
  return VocabPackRouteArguments(packId: packId, courseContext: courseContext);
}

/// Reads either a direct scenario ID or the exact scenario link from a course
/// mission. Unknown arguments deliberately fail to an empty route value.
String? scenarioIdFromRouteArguments(Object? arguments) {
  final context = coursePracticeContextFromRouteArguments(
    arguments,
    CurriculumContentKind.scenario,
  );
  return context?.initialContentId ?? (arguments is String ? arguments : null);
}

CourseMissionDestination? destinationForCourseLink(ContentLink link) {
  switch (link.contentKind) {
    case CurriculumContentKind.scenario:
      return CourseMissionDestination(
        route: '/scenario',
        arguments: CoursePracticeContext.fromLink(link),
      );
    case CurriculumContentKind.vocab:
      return CourseMissionDestination(
        route: '/vocab',
        arguments: CoursePracticeContext.fromLink(link),
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
