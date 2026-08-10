import 'today_learning_snapshot.dart';

/// Executes the route already selected by [TodayLearningSnapshot].
///
/// This deliberately owns no recommendation inputs and writes no learner
/// progress. Both Home and the Sarangbang use it so a direct Home CTA still
/// passes through the established pack-access gate before opening the exact
/// original route and arguments.
typedef TodayLearningPackAccessGate = Future<bool> Function(String level);
typedef TodayLearningRouteOpener =
    Future<void> Function(String route, Object? arguments);

class TodayLearningNavigation {
  const TodayLearningNavigation._();

  static Future<bool> open(
    TodayLearningDestination? destination, {
    required TodayLearningPackAccessGate ensurePackAccess,
    required TodayLearningRouteOpener openRoute,
  }) async {
    if (destination == null) {
      return false;
    }

    final level = destination.packAccessLevel;
    if (level != null && !await ensurePackAccess(level)) {
      return false;
    }

    await openRoute(destination.route, destination.arguments);
    return true;
  }
}
