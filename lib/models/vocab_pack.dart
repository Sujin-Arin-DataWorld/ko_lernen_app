import 'vocab.dart';

/// 단어 팩 — 같은 `pack_id` 를 가진 단어들의 묶음.
///
/// 한 팩은 8~13 단어, 5~10분 학습 단위. `isReviewBoss = true` 인 단어는
/// **현재 팩**의 최종 Boss 평가 멤버다. 이전 팩/장기 복습 단어라는 뜻은 아니며,
/// Learn 단계에서 다른 현재 팩 단어와 함께 먼저 노출된다.
///
/// 팩 ID 규칙: `{level}_{topic}` 또는 split 된 경우 `{level}_{topic}_{n}`.
/// 예: `a1_greetings_1`, `a1_numbers_2`, `b2_society`.
class VocabPack {
  /// 고유 ID — Firestore key 로도 사용.
  final String id;

  /// 'A1' / 'A2' / 'B1' / 'B2'
  final String level;

  /// 팩 내 모든 단어 (pack_order 오름차순으로 정렬됨).
  final List<Vocab> words;

  const VocabPack({required this.id, required this.level, required this.words});

  int get total => words.length;

  /// 현재 팩의 Boss 평가 단어.
  ///
  /// `isReviewBoss`는 SRS/이전 팩 복습 신호가 아니다. 이 단어들도
  /// [learnWords]로 먼저 가르친 뒤 최종 4지선다 평가에 쓴다.
  Iterable<Vocab> get bossWords => words.where((v) => v.isReviewBoss);

  /// 일반 단어 (보스 제외).
  Iterable<Vocab> get normalWords => words.where((v) => !v.isReviewBoss);

  /// Learn 단계에서 의도적으로 노출할 현재 팩의 모든 단어.
  ///
  /// Boss 단어를 숨긴 첫-노출 평가가 되지 않도록 [bossWords]도 포함한다.
  Iterable<Vocab> get learnWords => words;

  /// UI 표시용 한 줄 라벨 — 토픽 (DE) 우선, 없으면 ID.
  /// VocabPackService.displayLabel(packId) 이 더 풍부함.
  String get fallbackLabel => words.isEmpty ? id : words.first.topic;

  /// `a1_greetings_2` → `a1_greetings`. 디스플레이·정렬용 base ID.
  String get baseId {
    final parts = id.split('_');
    if (parts.isNotEmpty && int.tryParse(parts.last) != null) {
      return parts.sublist(0, parts.length - 1).join('_');
    }
    return id;
  }

  /// `a1_greetings_2` → 2. 분할 안 됐으면 null.
  int? get subIndex {
    final parts = id.split('_');
    if (parts.isNotEmpty) {
      final last = int.tryParse(parts.last);
      if (last != null) return last;
    }
    return null;
  }
}
