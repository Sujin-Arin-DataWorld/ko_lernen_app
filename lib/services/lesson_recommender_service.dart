import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/services/pack_progress_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';

/// **다음 레슨 추천 엔진**
///
/// 사용자 진행도를 바탕으로:
/// 1. 진행 중인 팩 계속 (우선)
/// 2. 다 했으면 다음 레벨 첫 팩 제안
/// 3. 선호도 기반 (이력에서 자주 본 레벨)
class LessonRecommenderService {
  /// "계속 배우기" 또는 "새로운 도전" 경로 생성
  static Future<LessonPath?> getNextLesson() async {
    try {
      final allPacks = await VocabPackService.loadAll();
      final progress = PackProgressService.getAll();

      // 1. 진행 중인 팩 우선
      for (final pack in allPacks) {
        final p = progress[pack.id];
        if (p?.status == PackStatus.inProgress) {
          return LessonPath(
            title: '계속 배우기',
            subtitle: VocabPackService.displayLabel(pack.id),
            packId: pack.id,
            icon: '📚',
          );
        }
      }

      // 2. 다음 레벨 첫 팩 제안
      final cleared = progress.values
          .where((p) => p.status == PackStatus.cleared)
          .length;

      // 5팩마다 레벨 올림 (A1×5 → A2×5 → B1×5 → B2×5)
      final nextLevelIndex = (cleared ~/ 5) + 1;
      final nextLevelStr = nextLevelIndex <= 2 ? 'A$nextLevelIndex' : 'B${nextLevelIndex - 2}';

      final nextAvailable = allPacks.firstWhere(
        (p) => p.level == nextLevelStr && (progress[p.id]?.status ?? PackStatus.locked) != PackStatus.cleared,
        orElse: () => allPacks.first,
      );

      return LessonPath(
        title: '새로운 도전',
        subtitle: VocabPackService.displayLabel(nextAvailable.id),
        packId: nextAvailable.id,
        icon: '⭐',
      );
    } catch (_) {
      return null; // Best-effort fallback
    }
  }

  /// 사용자 레벨에 기반한 추천
  /// A1/A2/B1/B2 중 가장 많이 진행 중인 레벨 반환
  static String getUserLevel() {
    final progress = PackProgressService.getAll();
    final levels = <String, int>{};

    for (final p in progress.values) {
      if (p.status == PackStatus.inProgress || p.status == PackStatus.available) {
        // 팩 ID에서 레벨 추출 (예: a1_greetings → A1)
        final packId = p.packId;
        if (packId.startsWith('a1_')) levels['A1'] = (levels['A1'] ?? 0) + 1;
        if (packId.startsWith('a2_')) levels['A2'] = (levels['A2'] ?? 0) + 1;
        if (packId.startsWith('b1_')) levels['B1'] = (levels['B1'] ?? 0) + 1;
        if (packId.startsWith('b2_')) levels['B2'] = (levels['B2'] ?? 0) + 1;
      }
    }

    // 가장 많은 팩이 있는 레벨
    final mostCommon = levels.entries.fold<String>('A1',
        (prev, e) => (levels[prev] ?? 0) < e.value ? e.key : prev);

    return mostCommon;
  }
}

/// 추천 레슨 경로 (홈 카드 렌더용)
class LessonPath {
  final String title; // "계속 배우기" 또는 "새로운 도전"
  final String subtitle; // 팩 이름
  final String packId;
  final String icon; // 📚 또는 ⭐

  LessonPath({
    required this.title,
    required this.subtitle,
    required this.packId,
    required this.icon,
  });
}
