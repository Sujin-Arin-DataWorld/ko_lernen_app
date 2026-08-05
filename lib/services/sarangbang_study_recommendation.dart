import 'mission_recommender.dart';
import 'today_learning_snapshot.dart';

/// Compatibility names for callers that still describe the shared answer by
/// its Sarangbang presentation. New code should depend on the generic
/// [TodayLearningSnapshot] because Home uses exactly the same answer.
typedef SarangbangStudyRecommendation = TodayLearningSnapshot;
typedef SarangbangStudyDestination = TodayLearningDestination;

/// Compatibility forwarding point. It must never assemble recommendation
/// inputs itself: [TodayLearningSnapshotLoader] is the only source.
@Deprecated('Use TodayLearningSnapshotLoader.load instead.')
class SarangbangStudyRecommendationLoader {
  const SarangbangStudyRecommendationLoader._();

  static Future<TodayLearningSnapshot> load() =>
      TodayLearningSnapshotLoader.load();
}

/// Compatibility routing helper for existing callers and tests.
SarangbangStudyDestination? sarangbangDestinationFor(MissionPick? pick) =>
    todayLearningDestinationFor(pick);
