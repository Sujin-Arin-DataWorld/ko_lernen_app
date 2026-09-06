import 'package:flutter/foundation.dart';

import 'personal_hanok.dart';
import 'quest.dart';
import '../services/today_learning_snapshot.dart';

enum SoriStageTab { today, learn, games, hanok, gye }

/// W10 T-L1: the Learn tab renders its catalog in three labeled sections —
/// today's core learning path first, then the wider practice surface, then
/// the review/reinforcement tools at the bottom (Jin, 2026-09-05). Games-tab
/// entries never carry a section (stays `null`).
enum SoriLearnSection { today, explore, review }

enum SoriActivityColorRole {
  listening,
  speaking,
  review,
  completion,
  reward,
  collaboration,
  hanok,
}

enum SoriRewardKind {
  none,
  xp,
  stamp,
  questProgress,
  hanokProgress,
  bojagi,
  gyeLantern,
  personalBest,
}

enum SoriActivityState { ready, inProgress, completed, locked }

enum SoriCopyKey {
  firstCompletion,
  finishSession,
  verifiedLearning,
  rewardXp,
  rewardQuest,
  rewardHanok,
  rewardStamp,
  rewardBest,
  rewardNone,
  rewardQuestProgress,
  rewardHanokPiece,
  rewardBojagi,
  rewardGyeLantern,
}

@immutable
class SoriLocalizedCopy {
  const SoriLocalizedCopy({
    required this.de,
    required this.en,
    this.key,
    this.activityId,
    this.isActivityDescription = false,
  });

  final String de;
  final String en;
  final SoriCopyKey? key;
  final String? activityId;
  final bool isActivityDescription;
}

@immutable
class RewardContractItem {
  const RewardContractItem({
    required this.kind,
    required this.label,
    this.amount,
    this.permanent = false,
  });

  final SoriRewardKind kind;
  final SoriLocalizedCopy label;
  final int? amount;
  final bool permanent;
}

/// What the learner can earn before starting an activity.
///
/// This is deliberately an expectation, never proof that a reward was paid.
@immutable
class RewardContract {
  const RewardContract({
    required this.activityId,
    required this.condition,
    this.items = const [],
  });

  final String activityId;
  final SoriLocalizedCopy condition;
  final List<RewardContractItem> items;
}

@immutable
class RewardReceiptItem {
  const RewardReceiptItem({
    required this.kind,
    required this.label,
    this.amount,
  });

  final SoriRewardKind kind;
  final SoriLocalizedCopy label;
  final int? amount;
}

/// Only concrete changes observed after an activity may enter this receipt.
@immutable
class RewardReceipt {
  const RewardReceipt({
    required this.activityId,
    required this.receiptId,
    required this.items,
  });

  final String activityId;
  final String receiptId;
  final List<RewardReceiptItem> items;

  bool get isEmpty => items.isEmpty;
}

@immutable
class ActivityUnlockCondition {
  const ActivityUnlockCondition.unlocked()
    : isUnlocked = true,
      explanation = null;

  const ActivityUnlockCondition.locked(this.explanation) : isUnlocked = false;

  final bool isUnlocked;
  final SoriLocalizedCopy? explanation;
}

@immutable
class ActivityCatalogEntry {
  const ActivityCatalogEntry({
    required this.id,
    required this.tab,
    required this.title,
    required this.description,
    required this.route,
    required this.minutes,
    required this.colorRole,
    required this.iconName,
    required this.reward,
    this.ownsRoute = true,
    this.detailRouteAliases = const <String>[],
    this.unlock = const ActivityUnlockCondition.unlocked(),
    this.arguments,
    this.learnSection,
  });

  final String id;
  final SoriStageTab tab;
  final SoriLocalizedCopy title;
  final SoriLocalizedCopy description;
  final String route;
  final Object? arguments;
  final int minutes;
  final SoriActivityColorRole colorRole;
  final String iconName;
  final RewardContract reward;
  final bool ownsRoute;
  final List<String> detailRouteAliases;
  final ActivityUnlockCondition unlock;

  /// W10 T-L1: which Learn-tab section this entry renders under. Always
  /// `null` for `SoriStageTab.games` entries.
  final SoriLearnSection? learnSection;
}

@immutable
class SoriActivityProgress {
  const SoriActivityProgress({
    required this.activityId,
    required this.state,
    this.current,
    this.target,
  });

  final String activityId;
  final SoriActivityState state;
  final int? current;
  final int? target;
}

@immutable
class SoriStageProgressionSnapshot {
  SoriStageProgressionSnapshot({
    required this.today,
    required this.hanok,
    required List<QuestProgress> quests,
    required this.pendingBojagiCount,
    required this.stampCount,
    required this.xp,
    required this.streakDays,
    required this.todayReward,
    Map<String, SoriActivityProgress> activityProgress = const {},
    Map<String, int> gameBests = const {},
    this.gyeLanternCount = 0,
  }) : quests = List.unmodifiable(quests),
       activityProgress = Map.unmodifiable(activityProgress),
       gameBests = Map.unmodifiable(gameBests);

  final TodayLearningSnapshot today;
  final PersonalHanokProjection hanok;
  final List<QuestProgress> quests;
  final int pendingBojagiCount;
  final int stampCount;
  final int xp;
  final int streakDays;
  final RewardContract? todayReward;
  final Map<String, SoriActivityProgress> activityProgress;
  final Map<String, int> gameBests;
  final int gyeLanternCount;

  List<QuestProgress> get closestQuests {
    final candidates =
        quests.where((quest) => quest.active && !quest.completed).toList()
          ..sort((left, right) => right.fraction.compareTo(left.fraction));
    return List.unmodifiable(candidates.take(3));
  }
}

/// §W2-Task2 (검수#7): 리시트 "before" 캡처 중 `openActivity()` 직전에
/// **동기로** 읽어야 하는 로컬 필드만 모은 값. `Storage`/
/// `DecorationRewardService` 게터는 전부 동기(SharedPreferences 는
/// `Storage.init()` 이후 인메모리)라 await 없이 즉시 구할 수 있다.
typedef SoriStageLocalBeforeFields = ({
  int xp,
  int stamps,
  int streakDays,
  int pendingBojagiCount,
  Map<String, int> gameBests,
});

/// 네트워크/로컬-비동기 계산이 필요한 "before" 필드(quests·hanok·gye
/// 라운턴). `openActivity()` 와 **병행** 실행되고, 활동에서 돌아온 뒤에만
/// await 된다 — 라우트 전환을 절대 막지 않는다.
typedef SoriStageNetworkBeforeFields = ({
  List<QuestProgress> quests,
  PersonalHanokProjection hanok,
  int gyeLanternCount,
});
