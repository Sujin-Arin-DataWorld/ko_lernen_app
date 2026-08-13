import 'package:flutter/foundation.dart';

import 'personal_hanok.dart';
import 'quest.dart';
import '../services/today_learning_snapshot.dart';

enum SoriStageTab { today, learn, games, hanok, gye }

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

  String resolve(String languageCode) => languageCode == 'de' ? de : en;
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
    this.detailRouteAliases = const <String>[],
    this.unlock = const ActivityUnlockCondition.unlocked(),
    this.arguments,
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
  final List<String> detailRouteAliases;
  final ActivityUnlockCondition unlock;
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
