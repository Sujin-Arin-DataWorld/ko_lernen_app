// 자모 근접 교란 — 정답과 자모 하나만 다른 비단어 오답 (하다 → 할다/허다/아다).

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/services/hangul_perturbation.dart';
import 'package:ko_lernen_app/services/hangul_util.dart';

/// 두 단어가 정확히 자모 1개만 다른지 검사.
bool _oneJamoEdit(String a, String b) {
  final ra = a.runes.toList();
  final rb = b.runes.toList();
  if (ra.length != rb.length) return false;
  var diffs = 0;
  for (var i = 0; i < ra.length; i++) {
    if (ra[i] == rb[i]) continue;
    final pa = decomposeHangulSyllable(ra[i]);
    final pb = decomposeHangulSyllable(rb[i]);
    if (pa == null || pb == null) return false;
    var jamoDiffs = 0;
    if (pa.$1 != pb.$1) jamoDiffs++;
    if (pa.$2 != pb.$2) jamoDiffs++;
    if (pa.$3 != pb.$3) jamoDiffs++;
    diffs += jamoDiffs == 1 ? 1 : 2;
  }
  return diffs == 1;
}

void main() {
  test('composeHangulSyllable is the inverse of decomposeHangulSyllable', () {
    for (final word in ['하다', '양극화', '값', '띄어쓰기']) {
      for (final rune in word.runes) {
        final p = decomposeHangulSyllable(rune)!;
        expect(
          composeHangulSyllable(p.$1, p.$2, p.$3),
          String.fromCharCode(rune),
        );
      }
    }
    expect(composeHangulSyllable('ㅏ', 'ㅏ', ''), isNull); // 초성 자리에 모음
  });

  test('하다-class words yield 3 valid one-jamo near-misses', () {
    final out = nearMissDistractors('하다', rng: math.Random(7));
    expect(out, hasLength(3));
    expect(out.toSet(), hasLength(3));
    for (final d in out) {
      expect(d, isNot('하다'));
      expect(_oneJamoEdit('하다', d), isTrue, reason: '$d must be 1 edit away');
      for (final rune in d.runes) {
        expect(decomposeHangulSyllable(rune), isNotNull);
      }
    }
  });

  test('blocklist entries are avoided when alternatives exist', () {
    final rng = math.Random(7);
    final blocked = nearMissDistractors('하다', rng: math.Random(7)).toSet();
    final out = nearMissDistractors('하다', rng: rng, blocklist: blocked);
    expect(out, hasLength(3));
    for (final d in out) {
      expect(blocked.contains(d), isFalse);
    }
  });

  test('non-Hangul input returns empty', () {
    expect(nearMissDistractors('hello', rng: math.Random(1)), isEmpty);
    expect(nearMissDistractors('', rng: math.Random(1)), isEmpty);
  });

  test('mixed input mutates only the Hangul syllables', () {
    final out = nearMissDistractors('K-팝', rng: math.Random(3), count: 2);
    for (final d in out) {
      expect(d.startsWith('K-'), isTrue);
      expect(d, isNot('K-팝'));
    }
  });

  test('deterministic with a seeded Random', () {
    final a = nearMissDistractors('학교', rng: math.Random(11));
    final b = nearMissDistractors('학교', rng: math.Random(11));
    expect(a, b);
  });

  test('never returns the original even under an exhaustive blocklist', () {
    // 가능한 모든 변이를 blocklist 로 막아도 원본만은 절대 반환하지 않는다.
    final all = <String>{};
    for (var seed = 0; seed < 40; seed++) {
      all.addAll(nearMissDistractors('하다', rng: math.Random(seed), count: 3));
    }
    final out = nearMissDistractors('하다', rng: math.Random(1), blocklist: all);
    expect(out, isNot(contains('하다')));
    expect(out, hasLength(3)); // 3차 폴백이 blocklist 충돌을 허용
  });
}
