import '../models/course_practice_context.dart';
import '../models/curriculum.dart';
import '../models/vocab_pack.dart';
import 'vocab_pack_service.dart';

const String courseReassessmentRoute = '/course/reassessment';

/// Typed request for a completed-unit productive reassessment. The route never
/// carries a boolean eligibility flag; the productive service revalidates all
/// IDs against the immutable assessment and segment catalogs before writing.
class CourseReassessmentRouteArguments {
  CourseReassessmentRouteArguments({
    required String courseUnitId,
    required String canDoSegmentId,
    required String assessmentItemId,
  }) : courseUnitId = _requiredReassessmentId(courseUnitId, 'courseUnitId'),
       canDoSegmentId = _requiredReassessmentId(
         canDoSegmentId,
         'canDoSegmentId',
       ),
       assessmentItemId = _requiredReassessmentId(
         assessmentItemId,
         'assessmentItemId',
       );

  final String courseUnitId;
  final String canDoSegmentId;
  final String assessmentItemId;
}

CourseReassessmentRouteArguments? reassessmentArgumentsFromRoute(
  Object? arguments,
) {
  if (arguments is! CourseReassessmentRouteArguments) {
    return null;
  }
  return arguments;
}

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

/// Reads either a typed mission edge or the retained direct-library unit ID.
/// The returned context is still required before any answer may be marked as
/// mission-routed evidence.
String? courseUnitIdFromActivityRouteArguments(
  Object? arguments,
  CurriculumContentKind expectedKind,
) =>
    coursePracticeContextFromRouteArguments(
      arguments,
      expectedKind,
    )?.courseUnitId ??
    (arguments is String ? arguments : null);

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
        arguments: CoursePracticeContext.fromLink(link),
      );
    case CurriculumContentKind.satz:
      return CourseMissionDestination(
        route: '/satz_arcade',
        arguments: CoursePracticeContext.fromLink(link),
      );
  }
}

/// Resolves the first mission action to the actual activity screen. Vocabulary
/// links need one data lookup because the graph stores a word ID while the
/// player route is pack-based; falling back to the pack marketplace would add
/// another decision and break the brief's single-action contract.
Future<CourseMissionDestination?> directDestinationForCourseLink(
  ContentLink link, {
  Future<List<VocabPack>> Function()? vocabPacksLoader,
}) async {
  if (link.contentKind != CurriculumContentKind.vocab) {
    return destinationForCourseLink(link);
  }
  final packs = await (vocabPacksLoader ?? VocabPackService.loadAll)();
  VocabPack? sourcePack;
  for (final pack in packs) {
    if (pack.words.any((word) => word.id == link.contentId)) {
      sourcePack = pack;
      break;
    }
  }
  if (sourcePack == null) return null;
  return CourseMissionDestination(
    route: '/vocab/pack',
    arguments: vocabPackRouteArguments(
      packId: sourcePack.id,
      courseContext: CoursePracticeContext.fromLink(link),
    ),
  );
}

String _requiredReassessmentId(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized.contains(RegExp(r'\s'))) {
    throw FormatException(
      'Course reassessment $field must be a nonempty stable ID.',
    );
  }
  return normalized;
}
