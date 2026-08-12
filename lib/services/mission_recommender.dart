import '../models/curriculum.dart';
import '../models/pack_progress.dart';
import '../models/scenario.dart';
import '../models/vocab_pack.dart';

/// 홈 블록 3 "미션 히어로" 추천 엔진 — **순수 함수** (계획 §6.1·§10.1).
///
/// 우선순위: ① 현재 코스 미션 > ② 진행 중 팩 > ③ due 복습(≥[reviewThreshold])
/// > ④ 시나리오 추천(R-REC: 레벨 ≤ 사용자 레벨, H-6). null = 오늘 다 함.
///
/// 문구·내비게이션 콜백은 호출측(홈) 몫 — 여기는 데이터 결정만. State 에서
/// 분리해 단위 테스트 가능하게 한 것 (2026-08-04 감사 #5·#8).
sealed class MissionPick {
  const MissionPick();
}

final class CoursePick extends MissionPick {
  final CourseUnit unit;

  /// 1-based "Mission {n} von {total}" 표기용.
  final int missionNumber;
  final int totalMissions;

  /// 진행 링 0..1 (완료 미션 / 전체).
  final double fraction;

  /// true = "Weitermachen" / false = "Los geht's".
  final bool started;

  const CoursePick({
    required this.unit,
    required this.missionNumber,
    required this.totalMissions,
    required this.fraction,
    required this.started,
  });
}

final class PackPick extends MissionPick {
  final VocabPack pack;
  final double fraction;
  const PackPick({required this.pack, required this.fraction});
}

final class ReviewPick extends MissionPick {
  final int dueCount;
  const ReviewPick({required this.dueCount});
}

final class ScenarioPick extends MissionPick {
  final String scenarioId;
  final LearnerLevel level;
  const ScenarioPick({required this.scenarioId, required this.level});
}

MissionPick? recommendMission({
  required List<CourseUnit> courseUnits,
  required String? currentCourseUnitId,
  required Set<String> completedUnitIds,
  required ({VocabPack pack, PackProgress progress})? nowNode,
  required int dueCount,
  required ({String id, LearnerLevel level})? scenario,
  required bool scenarioCompleted,
  required LearnerLevel userLevel,
  int reviewThreshold = 10,
}) {
  // ① 현재 코스 미션.
  if (courseUnits.isNotEmpty) {
    final total = courseUnits.length;
    CourseUnit? unit;
    if (currentCourseUnitId != null) {
      for (final u in courseUnits) {
        if (u.id == currentCourseUnitId) {
          unit = u;
          break;
        }
      }
    }
    if (unit == null && completedUnitIds.length < total) {
      // 진단 전(스냅샷 비어 있음) — order 순 첫 미완 미션.
      final remaining =
          courseUnits.where((u) => !completedUnitIds.contains(u.id)).toList()
            ..sort((a, b) => a.order.compareTo(b.order));
      if (remaining.isNotEmpty) {
        unit = remaining.first;
      }
    }
    if (unit != null) {
      final done = completedUnitIds.length;
      final n = done + 1 > total ? total : done + 1;
      return CoursePick(
        unit: unit,
        missionNumber: n,
        totalMissions: total,
        fraction: done / total,
        started: done > 0,
      );
    }
  }
  // ② 진행 중 팩 — 시작했고 아직 안 끝난 현재 노드.
  final node = nowNode;
  if (node != null &&
      node.progress.progressFraction > 0 &&
      node.progress.status != PackStatus.cleared) {
    return PackPick(pack: node.pack, fraction: node.progress.progressFraction);
  }
  // ③ 오늘 복습.
  if (dueCount >= reviewThreshold) {
    return ReviewPick(dueCount: dueCount);
  }
  // ④ 시나리오 — R-REC 레벨 가드(H-6).
  final sc = scenario;
  if (sc != null && !scenarioCompleted && sc.level.index <= userLevel.index) {
    return ScenarioPick(scenarioId: sc.id, level: sc.level);
  }
  return null;
}

/// §10.2: 현재 노드 ±1 = 3개 슬라이스 (경계는 클램프, [nowIndex] < 0 = 뒤 3개).
List<T> previewWindow<T>(List<T> items, int nowIndex) {
  if (items.isEmpty) {
    return const [];
  }
  var i = nowIndex < 0 ? items.length - 1 : nowIndex;
  if (i >= items.length) {
    i = items.length - 1;
  }
  var start = i - 1 < 0 ? 0 : i - 1;
  var end = start + 3;
  if (end > items.length) {
    end = items.length;
    start = end - 3 < 0 ? 0 : end - 3;
  }
  return items.sublist(start, end);
}
