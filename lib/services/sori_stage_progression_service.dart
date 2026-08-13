import '../data/sori_activity_catalog.dart';
import '../models/course_mastery.dart';
import '../models/personal_hanok.dart';
import '../models/pack_progress.dart';
import '../models/sori_stage_progression.dart';
import 'decoration_reward_service.dart';
import 'course_progress_service.dart';
import 'gye_service.dart';
import 'hanok_structure_projection_service.dart';
import 'quest_tracker.dart';
import 'pack_progress_service.dart';
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
    final gyeLanternFuture = _loadGyeLanternCount();

    final today = await todayFuture;
    final hanok = await hanokFuture;
    final quests = await questsFuture;
    final gyeLanternCount = await gyeLanternFuture;
    final activity = activityForRoute(today.destination?.route);
    final activityProgress = await _loadActivityProgress();

    return SoriStageProgressionSnapshot(
      today: today,
      hanok: hanok,
      quests: quests,
      pendingBojagiCount: DecorationRewardService.openableBoxCount(),
      stampCount: Storage.earnedStamps.length,
      xp: Storage.xp,
      streakDays: Storage.streakDays,
      todayReward: activity?.reward,
      activityProgress: activityProgress,
      gameBests: _loadGameBests(),
      gyeLanternCount: gyeLanternCount,
    );
  }

  static Future<Map<String, SoriActivityProgress>>
  _loadActivityProgress() async {
    final progress = <String, SoriActivityProgress>{};
    CourseMasterySnapshot? course;
    try {
      course = await CourseProgressService.shared.readForDisplay();
    } catch (_) {
      course = null;
    }
    progress['course'] = _progress(
      'course',
      current: course?.completedUnitIds.length ?? 0,
      started: course != null,
    );

    final packs = PackProgressService.getAll().values.toList(growable: false);
    final clearedPacks = packs
        .where((item) => item.status == PackStatus.cleared)
        .length;
    progress['vocab_packs'] = _progress(
      'vocab_packs',
      current: clearedPacks,
      target: packs.isEmpty ? null : packs.length,
      started: packs.any((item) => item.status == PackStatus.inProgress),
    );
    progress['calligraphy'] = _progress(
      'calligraphy',
      current: Storage.calligraphyTotalDays,
      started: Storage.calligraphyTotalDays > 0,
    );
    progress['pronunciation'] = _progress(
      'pronunciation',
      current: Storage.pronunciationPassCount,
      target: 100,
      started: Storage.pronunciationPassCount > 0,
    );
    progress['grammar'] = _progress(
      'grammar',
      current: Storage.grammarSeen.length,
      started: Storage.grammarSeen.isNotEmpty,
    );
    progress['scenarios'] = _progress(
      'scenarios',
      current: Storage.completedScenarios.length,
      started: Storage.completedScenarios.isNotEmpty,
    );
    progress['srs'] = _progress(
      'srs',
      current: Storage.vokSeenIds.length,
      started: Storage.vokSeenIds.isNotEmpty,
    );
    for (final activity in soriActivityCatalog) {
      progress.putIfAbsent(
        activity.id,
        () => SoriActivityProgress(
          activityId: activity.id,
          state: activity.unlock.isUnlocked
              ? SoriActivityState.ready
              : SoriActivityState.locked,
        ),
      );
    }
    return Map.unmodifiable(progress);
  }

  static SoriActivityProgress _progress(
    String activityId, {
    required int current,
    int? target,
    required bool started,
  }) {
    final completed = target != null && target > 0 && current >= target;
    return SoriActivityProgress(
      activityId: activityId,
      state: completed
          ? SoriActivityState.completed
          : started
          ? SoriActivityState.inProgress
          : SoriActivityState.ready,
      current: current,
      target: target,
    );
  }

  static Map<String, int> _loadGameBests() => Map.unmodifiable(<String, int>{
    'daily_game': Storage.gameBest('daily'),
    'chosung': Storage.gameBest('chosung'),
    'syllable_cross': <int>[
      Storage.gameBest('skz_a1'),
      Storage.gameBest('skz_a2'),
      Storage.gameBest('skz_b1'),
      Storage.gameBest('skz_b2'),
    ].reduce((left, right) => left > right ? left : right),
    'cloze': Storage.gameBest('cloze'),
    'speed_match': Storage.gameBest('speed_match'),
    'sentence_arcade': Storage.gameBest('satz_arcade'),
    'kkeunmari': Storage.gameBest('kkeunmari'),
    'custom_quiz': Storage.gameBest('cp_quiz'),
    'custom_matching': Storage.gameBest('cp_matching'),
    'custom_typing': Storage.gameBest('cp_typing'),
  });

  static Future<int> _loadGyeLanternCount() async {
    try {
      final metas = await GyeService.myGyeMetas();
      var total = 0;
      for (final meta in metas) {
        total += meta.weeklyPromiseSchemaVersion == 1
            ? meta.weeklyPromiseProgress
            : meta.weeklyGoalProgress;
      }
      return total;
    } catch (_) {
      return 0;
    }
  }
}
