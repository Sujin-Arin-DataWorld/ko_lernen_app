import '../models/pack_progress.dart';
import '../models/learner_level.dart';
import 'pack_progress_service.dart';
import 'storage_service.dart';

/// 추천된 다음 행동의 종류.
enum LessonKind {
  /// 진행 중인 팩 — "이어서 학습".
  continueLearning,

  /// 잠금 해제됐지만 미시작 팩 — "새 단어 시작".
  newChallenge,
}

/// **다음 레슨 추천 엔진**
///
/// 홈의 학습 경로(Lernpfad)와 **동일한 알고리즘**으로 "지금 할 한 가지"를
/// 고른다. 온보딩에서 고른 레벨이 있으면 그 레벨의 팩만 스캔하고, 아직
/// 선택하지 않은 신규 사용자만 A1부터 C2까지 차례로 스캔해서
/// `cleared`/`locked` 가 아닌 첫 팩을 추천한다. 이렇게 해야 홈 hero CTA의
/// 목적지와 경로의 "지금(now)" 노드가 항상 일치한다(일관성 = 품질).
///
/// 비용: [PackProgressService.loadLevelView] 는 캐시된 팩 리스트 + 로컬
/// SharedPreferences 진행도만 읽으므로 사실상 무료.
class LessonRecommenderService {
  static final List<String> _levels = List.unmodifiable(
    LearnerLevel.values.map((level) => level.display),
  );

  static String? _selectedLevel() {
    return LearnerLevel.fromCode(Storage.userLevelCode)?.display;
  }

  /// 지금 추천할 팩. 모든 팩을 클리어했으면 `null` (호출자가 복습 등으로 대체).
  static Future<LessonPath?> getNextLesson() async {
    try {
      final selected = _selectedLevel();
      for (final level in selected == null ? _levels : [selected]) {
        final view = await PackProgressService.loadLevelView(level);
        for (final node in view) {
          final status = node.progress.status;
          if (status == PackStatus.inProgress) {
            return LessonPath(
              kind: LessonKind.continueLearning,
              packId: node.pack.id,
              level: level,
            );
          }
          if (status == PackStatus.available) {
            return LessonPath(
              kind: LessonKind.newChallenge,
              packId: node.pack.id,
              level: level,
            );
          }
          // cleared / locked → 다음 팩으로 계속 스캔.
        }
      }
      return null; // 전부 클리어.
    } catch (_) {
      return null; // best-effort.
    }
  }

  /// 사용자의 현재 작업 레벨 — 아직 클리어 안 한 팩이 남은 가장 낮은 레벨.
  /// 전부 끝났으면 최상위 레벨(C2). 실패 시 A1.
  static Future<String> getUserLevel() async {
    try {
      final selected = _selectedLevel();
      if (selected != null) return selected;
      for (final level in _levels) {
        final view = await PackProgressService.loadLevelView(level);
        final hasOpen = view.any(
          (n) => n.progress.status != PackStatus.cleared,
        );
        if (hasOpen) return level;
      }
      return _levels.last; // 전부 클리어 → 최상위.
    } catch (_) {
      return _levels.first;
    }
  }
}

/// 추천 레슨 경로 (홈 hero CTA 렌더용).
class LessonPath {
  final LessonKind kind;
  final String packId;
  final String level; // 'A1' through 'C2'

  const LessonPath({
    required this.kind,
    required this.packId,
    required this.level,
  });
}
