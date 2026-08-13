/// 4지선다 오답(distractor) 선별 (순수 Dart, 2026-08-13 테스터 피드백 ④).
///
/// 기존에는 같은 레벨 풀에서 **순수 랜덤** 3개를 뽑아, 품사만 봐도 오답을
/// 배제할 수 있었다 ("하다 단어는 명사가 아니니 제외…"). 여기서는 정답과
/// 같은 품사·레벨의 후보를 우선 채워 소거법을 어렵게 만든다.
library;

import 'dart:math' as math;

/// 오답 후보 — 화면 표시 언어 기준으로 미리 평탄화한 값.
/// (Vocab 은 `translationFor(lang)`/`posFor(lang)` 로, 커스텀팩 단어는
/// posDe/level '' 로 만든다 — 빈 값은 계층에서 자연 강등된다.)
class DistractorCandidate {
  /// 안정 키 (한국어 표제어) — 정답 자신 제외용.
  final String id;

  /// 표시 언어의 뜻 (선택지에 그대로 노출).
  final String translation;

  /// 표시 언어의 품사 라벨. '' 허용.
  final String pos;

  /// 'A1'…'B2'. 커스텀 단어는 ''.
  final String level;

  const DistractorCandidate({
    required this.id,
    required this.translation,
    this.pos = '',
    this.level = '',
  });
}

/// [target] 의 뜻과 함께 보여줄 오답 [count]개 (표시 언어 번역 문자열).
///
/// 계층 폴백 — 위 계층부터 채우고 모자라면 아래로:
///   ① 품사 있음 ∧ 같은 품사 ∧ 같은 레벨
///   ② 품사 있음 ∧ 같은 품사 (레벨 무관)
///   ③ 같은 레벨 (품사 무관)
///   ④ 나머지 전부
/// 각 계층 안에서는 [rng] 로 셔플. 정답과 같은 단어/같은 번역은 제외하고
/// 번역 문자열 기준으로 중복 제거. 풀이 작으면 [count] 미만을 반환한다
/// (호출 측 UI 는 선택지 개수만큼 렌더).
List<String> buildTranslationDistractors({
  required DistractorCandidate target,
  required List<DistractorCandidate> pool,
  required math.Random rng,
  int count = 3,
}) {
  final correct = target.translation.trim();
  final seen = <String>{correct};

  // 후보 정리: 자기 자신·정답 번역·중복 번역 제거.
  final usable = <DistractorCandidate>[];
  for (final c in pool) {
    final t = c.translation.trim();
    if (c.id == target.id || t.isEmpty || !seen.add(t)) continue;
    usable.add(c);
  }

  final targetPos = target.pos.trim();
  final targetLevel = target.level.trim();
  bool samePos(DistractorCandidate c) =>
      targetPos.isNotEmpty && c.pos.trim() == targetPos;
  bool sameLevel(DistractorCandidate c) =>
      targetLevel.isNotEmpty && c.level.trim() == targetLevel;

  final tiers = <List<DistractorCandidate>>[[], [], [], []];
  for (final c in usable) {
    final int tier;
    if (samePos(c) && sameLevel(c)) {
      tier = 0;
    } else if (samePos(c)) {
      tier = 1;
    } else if (sameLevel(c)) {
      tier = 2;
    } else {
      tier = 3;
    }
    tiers[tier].add(c);
  }

  final out = <String>[];
  for (final tier in tiers) {
    if (out.length >= count) break;
    tier.shuffle(rng);
    for (final c in tier) {
      out.add(c.translation.trim());
      if (out.length >= count) break;
    }
  }
  return out;
}
