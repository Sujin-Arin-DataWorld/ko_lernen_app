/// 자모 근접 교란(near-miss) 오답 생성 (순수 Dart, 2026-08-13 테스터 피드백 ④).
///
/// 테스터 예시 그대로: "machen?" → 할다 / 허다 / 하다 / 하가 — 정답과 자모
/// **하나만** 다른 비단어 오답. 소리·모양이 가까운 자모끼리만 바꿔 "비슷해서
/// 헷갈리는" 보기를 만든다.
///
/// 실제 단어와의 충돌은 [nearMissDistractors] 의 `blocklist`(CSV 표제어)로
/// 배제한다 — 변이가 우연히 정답의 동의어를 만들면 정답이 2개가 되는 사고를
/// 원천 차단 (비단어 오답이 곧 테스터가 원한 형태이기도 하다).
library;

import 'dart:math' as math;

import 'hangul_util.dart';

/// 소리/모양 이웃 그룹 — 같은 그룹 안에서만 서로 교체된다.
const List<List<String>> _choGroups = [
  ['ㄱ', 'ㅋ', 'ㄲ'],
  ['ㄷ', 'ㅌ', 'ㄸ'],
  ['ㅂ', 'ㅍ', 'ㅃ'],
  ['ㅅ', 'ㅆ'],
  ['ㅈ', 'ㅊ', 'ㅉ'],
  ['ㅎ', 'ㅇ'],
  ['ㄴ', 'ㄹ', 'ㅁ'],
];

const List<List<String>> _jungGroups = [
  ['ㅏ', 'ㅓ'],
  ['ㅐ', 'ㅔ'],
  ['ㅗ', 'ㅜ'],
  ['ㅑ', 'ㅕ'],
  ['ㅛ', 'ㅠ'],
  ['ㅡ', 'ㅜ'],
  ['ㅢ', 'ㅣ'],
  ['ㅚ', 'ㅙ', 'ㅞ'],
];

/// `''` = 받침 없음 → 받침 추가/삭제도 한 번의 교란으로 취급 (하다 → 할다).
const List<List<String>> _jongGroups = [
  ['', 'ㄹ', 'ㄴ', 'ㅇ'],
  ['ㄴ', 'ㅇ', 'ㅁ'],
  ['ㄱ', 'ㄲ', 'ㅋ'],
  ['ㅂ', 'ㅍ'],
  ['ㅅ', 'ㅆ', 'ㄷ'],
];

Map<String, List<String>> _neighborsOf(List<List<String>> groups) {
  final map = <String, Set<String>>{};
  for (final group in groups) {
    for (final a in group) {
      for (final b in group) {
        if (a != b) {
          (map[a] ??= <String>{}).add(b);
        }
      }
    }
  }
  return map.map((k, v) => MapEntry(k, v.toList(growable: false)));
}

final Map<String, List<String>> _choNeighbors = _neighborsOf(_choGroups);
final Map<String, List<String>> _jungNeighbors = _neighborsOf(_jungGroups);
final Map<String, List<String>> _jongNeighbors = _neighborsOf(_jongGroups);

class _Candidate {
  final String word;
  final int position; // 몇 번째 음절을 바꿨나
  final int slot; // 0=초성, 1=중성, 2=종성

  const _Candidate(this.word, this.position, this.slot);
}

/// [word] 와 자모 하나만 다른 오답 [count]개.
///
/// - 음절이 아닌 문자(공백·라틴 등)는 건드리지 않는다. 한글 음절이 하나도
///   없으면 `[]`.
/// - 오답끼리 (음절 위치, 자모 슬롯)을 최대한 다르게 뽑아 하다→할다/허다/아다
///   같은 다양한 모양을 만든다. 공간이 모자라면(짧은 단어) 같은 슬롯도 허용.
/// - [blocklist] 의 실제 단어와 겹치는 변이는 피한다. 수학적으로 다른 선택지가
///   없을 때만 마지막 수단으로 허용 (원본과 같은 문자열은 절대 반환 안 함).
List<String> nearMissDistractors(
  String word, {
  int count = 3,
  required math.Random rng,
  Set<String> blocklist = const {},
}) {
  final runes = word.runes.toList(growable: false);
  final candidates = <_Candidate>[];

  for (var i = 0; i < runes.length; i++) {
    final parts = decomposeHangulSyllable(runes[i]);
    if (parts == null) continue;

    void addAll(int slot, List<String>? neighbors) {
      for (final n in neighbors ?? const <String>[]) {
        final syllable = switch (slot) {
          0 => composeHangulSyllable(n, parts.$2, parts.$3),
          1 => composeHangulSyllable(parts.$1, n, parts.$3),
          _ => composeHangulSyllable(parts.$1, parts.$2, n),
        };
        if (syllable == null) continue;
        final mutated = String.fromCharCodes([
          ...runes.sublist(0, i),
          syllable.runes.first,
          ...runes.sublist(i + 1),
        ]);
        candidates.add(_Candidate(mutated, i, slot));
      }
    }

    addAll(0, _choNeighbors[parts.$1]);
    addAll(1, _jungNeighbors[parts.$2]);
    addAll(2, _jongNeighbors[parts.$3]);
  }

  if (candidates.isEmpty) return const [];
  candidates.shuffle(rng);

  final out = <String>[];
  final usedSlots = <String>{};
  bool taken(String w) => w == word || out.contains(w);

  // 1차: (위치, 슬롯) 다양화 + blocklist 준수.
  for (final c in candidates) {
    if (out.length >= count) break;
    final slotKey = '${c.position}-${c.slot}';
    if (usedSlots.contains(slotKey)) continue;
    if (taken(c.word) || blocklist.contains(c.word)) continue;
    out.add(c.word);
    usedSlots.add(slotKey);
  }
  // 2차: 슬롯 중복 허용, blocklist 는 계속 준수.
  for (final c in candidates) {
    if (out.length >= count) break;
    if (taken(c.word) || blocklist.contains(c.word)) continue;
    out.add(c.word);
  }
  // 3차(마지막 수단): blocklist 충돌 허용 — 원본만은 불가.
  for (final c in candidates) {
    if (out.length >= count) break;
    if (taken(c.word)) continue;
    out.add(c.word);
  }
  return out;
}
