import 'today_learning_snapshot.dart';

/// Executes the route already selected by [TodayLearningSnapshot].
///
/// This deliberately owns no recommendation inputs and writes no learner
/// progress. Both Home and the Sarangbang use it so a direct Home CTA still
/// opens the exact original route and arguments. Pack access is universal and
/// therefore has no deny-capable navigation seam.
typedef TodayLearningRouteOpener =
    Future<void> Function(String route, Object? arguments);

class TodayLearningNavigation {
  const TodayLearningNavigation._();

  static Future<bool> open(
    TodayLearningDestination? destination, {
    required TodayLearningRouteOpener openRoute,
  }) async {
    if (destination == null) {
      return false;
    }

    await openRoute(destination.route, destination.arguments);
    return true;
  }
}
