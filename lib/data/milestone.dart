import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// 학습 마일스톤 타입 — 스트릭·레벨·누적 단어.
enum MilestoneType { streak, level, vocab }

/// 달성 마일스톤 (타입 + 임계값). [id]는 중복 축하 방지 키('streak_7' 등).
class Milestone {
  final MilestoneType type;
  final int value;

  const Milestone(this.type, this.value);

  String get id => '${type.name}_$value';

  IconData get icon => switch (type) {
    MilestoneType.streak => Icons.local_fire_department_rounded,
    MilestoneType.level => Icons.star_rounded,
    MilestoneType.vocab => Icons.menu_book_rounded,
  };

  String title(AppL10n t) => switch (type) {
    MilestoneType.streak => t.milestoneStreakTitle(value),
    MilestoneType.level => t.milestoneLevelTitle(value),
    MilestoneType.vocab => t.milestoneVocabTitle(value),
  };

  String body(AppL10n t) => switch (type) {
    MilestoneType.streak => t.milestoneStreakBody,
    MilestoneType.level => t.milestoneLevelBody,
    MilestoneType.vocab => t.milestoneVocabBody,
  };

  @override
  bool operator ==(Object other) =>
      other is Milestone && other.type == type && other.value == value;

  @override
  int get hashCode => Object.hash(type, value);
}

/// 각 타입의 임계값(오름차순).
const Map<MilestoneType, List<int>> milestoneThresholds = {
  MilestoneType.streak: [3, 7, 30],
  MilestoneType.level: [5, 10],
  MilestoneType.vocab: [10, 100],
};

/// 순수 함수(테스트 대상) — 현재 스탯에서 **새로** 달성된(아직 축하 안 한)
/// 마일스톤들을 값 오름차순으로. celebrated에 든 id는 제외.
List<Milestone> newlyReachedMilestones({
  required int streak,
  required int level,
  required int vocab,
  required Set<String> celebrated,
}) {
  final out = <Milestone>[];
  void check(MilestoneType type, int current) {
    for (final th in milestoneThresholds[type]!) {
      final m = Milestone(type, th);
      if (current >= th && !celebrated.contains(m.id)) {
        out.add(m);
      }
    }
  }

  check(MilestoneType.streak, streak);
  check(MilestoneType.level, level);
  check(MilestoneType.vocab, vocab);
  return out;
}
