import 'dart:async';

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
    // W10 T-L3: the catalog merged 'custom_quiz'/'custom_matching'/
    // 'custom_typing' into one 'custom_practice' tile — the three
    // underlying per-mode scores still live separately in Storage (the
    // quiz/matching/typing exercises inside Meine Wörter are unchanged),
    // so this takes their max, same pattern as 'syllable_cross' above.
    'custom_practice': <int>[
      Storage.gameBest('cp_quiz'),
      Storage.gameBest('cp_matching'),
      Storage.gameBest('cp_typing'),
    ].reduce((left, right) => left > right ? left : right),
  });

  static Future<int> _loadGyeLanternCount() =>
      GyeService.refreshGyeLanternCache();

  /// §W2-Task2: 리시트 "before" 의 동기 로컬 절반. `capture()` 가
  /// `openActivity()` 바로 앞의 같은 동기 실행 구간에서 호출한다.
  static SoriStageLocalBeforeFields captureLocalBeforeFields() => (
    xp: Storage.xp,
    stamps: Storage.earnedStamps.length,
    streakDays: Storage.streakDays,
    pendingBojagiCount: DecorationRewardService.openableBoxCount(),
    gameBests: _loadGameBests(),
  );

  /// §W2-Task2: 리시트 "before" 의 네트워크/비동기 절반. `openActivity()`
  /// 와 병행 실행된다 — quests·hanok 은 로컬(메모이즈된 asset) 계산이라
  /// 그대로 await 하고, gye 라운턴만 순수 네트워크라 캐시값을 즉시 쓰고
  /// 새로고침은 기다리지 않는다(남는 노출 위험: 다른 기기에서 막 늘어난
  /// 라운턴은 이번 영수증에 늦게 반영될 수 있다 — 실제 저장된 보상에는
  /// 영향 없음, 영수증 표시만 한 박자 늦을 수 있다).
  static Future<SoriStageNetworkBeforeFields> loadNetworkBeforeFields() async {
    final hanokFuture = HanokStructureProjectionService.loadCurrent();
    final questsFuture = QuestTracker.computeAll();
    final gyeLanternBefore = GyeService.cachedGyeLanternCount;
    unawaited(GyeService.refreshGyeLanternCache());
    return (
      quests: await questsFuture,
      hanok: await hanokFuture,
      gyeLanternCount: gyeLanternBefore,
    );
  }
}
