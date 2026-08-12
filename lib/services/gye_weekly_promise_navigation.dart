import '../models/curriculum.dart';
import '../models/gye.dart';
import '../models/gye_weekly_promise.dart';
import 'course_mission_navigation.dart';
import 'curriculum_catalog.dart';
import 'mission_recommender.dart';
import 'today_learning_snapshot.dart';

/// How the Gye CTA can truthfully enter learning.
enum GyePromiseNavigationKind {
  /// The current course unit owns the promise's one exact assessed scene.
  eligibleScene,

  /// The scene is not currently course-eligible, so use Today's honest next
  /// action without claiming that it will contribute to the Gye promise.
  todayFallback,

  /// Neither an eligible scene nor a Today destination is available.
  unavailable,
}

class GyePromiseNavigationResolution {
  const GyePromiseNavigationResolution({required this.kind, this.destination});

  final GyePromiseNavigationKind kind;
  final TodayLearningDestination? destination;
}

/// Resolves the 05B CTA without writing progress or inventing course evidence.
///
/// An exact scene is opened only through the catalog's existing assessed
/// [ContentLink]. [destinationForCourseLink] then creates the same typed
/// course provenance used by CourseMissionScreen. Any stale, missing or
/// ambiguous relationship falls back to the already-selected Today route.
abstract final class GyeWeeklyPromiseNavigation {
  static Future<GyePromiseNavigationResolution> load({
    required GyeMeta meta,
    required TodayLearningSnapshot today,
    Future<CurriculumCatalog> Function()? loadCatalog,
  }) async {
    try {
      final catalog = await (loadCatalog ?? CurriculumCatalog.load)();
      if (catalog.validationIssues.isNotEmpty) {
        return _todayFallback(today);
      }
      return resolve(
        meta: meta,
        today: today,
        contentLinks: catalog.contentLinks,
      );
    } catch (_) {
      return _todayFallback(today);
    }
  }

  static GyePromiseNavigationResolution resolve({
    required GyeMeta meta,
    required TodayLearningSnapshot today,
    required Iterable<ContentLink> contentLinks,
  }) {
    if (today.isUnavailable) {
      return const GyePromiseNavigationResolution(
        kind: GyePromiseNavigationKind.unavailable,
      );
    }
    final definition = GyeWeeklyPromises.byId(meta.weeklyPromiseId);
    final activePick = today.pick;
    final validPromise =
        meta.weeklyPromiseSchemaVersion == 1 &&
        definition != null &&
        meta.weeklyPromiseTarget == definition.target;
    if (!validPromise ||
        activePick is! CoursePick ||
        activePick.unit.id != definition.courseUnitId ||
        today.destination?.route != '/course/mission') {
      return _todayFallback(today);
    }

    final exactLinks = contentLinks
        .where(
          (link) =>
              link.contentKind == CurriculumContentKind.scenario &&
              link.contentId == definition.scenarioId &&
              link.courseUnitId == definition.courseUnitId &&
              link.id == definition.missionContentLinkId &&
              link.exactlyAssesses(activePick.unit),
        )
        .toList(growable: false);
    if (exactLinks.length != 1) {
      return _todayFallback(today);
    }

    final courseDestination = destinationForCourseLink(exactLinks.single);
    if (courseDestination == null || courseDestination.route != '/scenario') {
      return _todayFallback(today);
    }
    return GyePromiseNavigationResolution(
      kind: GyePromiseNavigationKind.eligibleScene,
      destination: TodayLearningDestination(
        route: courseDestination.route,
        arguments: courseDestination.arguments,
      ),
    );
  }

  static GyePromiseNavigationResolution _todayFallback(
    TodayLearningSnapshot today,
  ) => today.isUnavailable
      ? const GyePromiseNavigationResolution(
          kind: GyePromiseNavigationKind.unavailable,
        )
      : GyePromiseNavigationResolution(
          kind: today.destination == null
              ? GyePromiseNavigationKind.unavailable
              : GyePromiseNavigationKind.todayFallback,
          destination: today.destination,
        );
}
