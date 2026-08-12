import '../data/sori_activity_catalog.dart';
import '../models/personal_hanok.dart';
import '../models/sori_stage_progression.dart';
import 'decoration_reward_service.dart';
import 'hanok_structure_projection_service.dart';
import 'quest_tracker.dart';
import 'storage_service.dart';
import 'today_learning_snapshot.dart';

typedef TodaySnapshotReader = Future<TodayLearningSnapshot> Function();
typedef HanokProjectionReader = Future<PersonalHanokProjection> Function();

/// Read-only aggregate used by Today and the journey previews.
abstract final class SoriStageProgressionService {
  static Future<SoriStageProgressionSnapshot> load({
    TodaySnapshotReader? loadToday,
    HanokProjectionReader? loadHanok,
  }) async {
    final todayFuture = (loadToday ?? TodayLearningSnapshotLoader.load)();
    final hanokFuture =
        (loadHanok ?? HanokStructureProjectionService.loadCurrent)();
    final questsFuture = QuestTracker.computeAll();

    final today = await todayFuture;
    final hanok = await hanokFuture;
    final quests = await questsFuture;
    final activity = activityForRoute(today.destination?.route);

    return SoriStageProgressionSnapshot(
      today: today,
      hanok: hanok,
      quests: quests,
      pendingBojagiCount: DecorationRewardService.openableBoxCount(),
      stampCount: Storage.earnedStamps.length,
      xp: Storage.xp,
      streakDays: Storage.streakDays,
      todayReward: activity?.reward,
    );
  }
}
