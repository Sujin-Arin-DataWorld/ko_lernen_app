/// 획순 판정 회귀 그물 — 테스터(Amor, 2026-08-17)가 "일부러 획순을 틀려도
/// 인식하지 못하고 그냥 진행된다"고 보고한 건의 재발 방지.
///
/// `evaluateStroke` 를 34자 전수로 돌린다. 여기서 하는 단언은 전부 실제로
/// 측정해서 얻은 값이다 — 추정으로 쓰지 말 것.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/hangul_strokes.dart';
import 'package:ko_lernen_app/services/stroke_matcher.dart';

List<Offset> circlePoints(Offset center, double radius, {int count = 24}) => [
  for (var i = 0; i <= count; i++)
    Offset(
      center.dx + radius * math.cos(i / count * 2 * math.pi),
      center.dy + radius * math.sin(i / count * 2 * math.pi),
    ),
];

/// [stroke] 를 그대로 따라 그린 것처럼 점 목록을 만든다.
List<Offset> trace(Stroke stroke, {double jitter = 0}) => switch (stroke) {
  LineStroke(:final points) => [
    for (final p in points) Offset(p.dx + jitter, p.dy),
  ],
  CircleStroke(:final center, :final radius) => circlePoints(center, radius),
};

/// tolerance 가 손가락 입력을 받아야 해서 원리상 구별할 수 없는 획 쌍.
/// `stroke_matcher.dart` 라이브러리 주석의 "알려진 한계" 와 같은 목록이다.
/// **이 집합을 늘리는 변경은 판정이 느슨해졌다는 뜻이다.**
const Map<String, Set<String>> knownIndistinguishable = {
  'ㅃ': {'1<->4'}, // 안쪽 두 세로획 — 20px 간격
  'ㅝ': {'0<->2'}, // 위·아래 가로획 — 26px 간격
};

bool _isKnownPair(String letter, int a, int b) {
  final lo = math.min(a, b);
  final hi = math.max(a, b);
  return knownIndistinguishable[letter]?.contains('$lo<->$hi') ?? false;
}

void main() {
  const canvas = Size(220, 220); // strokeCanvas 와 동일 → 스케일 1

  test('34자 전부 정답 순서로 그리면 모든 획이 ok 다', () {
    expect(hangulStrokes, hasLength(34));
    for (final entry in hangulStrokes.entries) {
      for (var i = 0; i < entry.value.length; i++) {
        final attempt = evaluateStroke(
          target: entry.value,
          expectedIndex: i,
          drawn: trace(entry.value[i]),
          canvasSize: canvas,
        );
        expect(
          attempt.verdict,
          StrokeVerdict.ok,
          reason: '${entry.key} 의 $i 번 획을 정확히 그었는데 통과하지 못했다',
        );
      }
    }
  });

  test('25px 삐뚤어져도 34자 전부 통과한다 — 오탐이 없어야 한다', () {
    // 판정이 엄격해지는 방향의 변경은 반드시 여기서 먼저 터진다.
    // 맞게 그은 학습자를 틀렸다고 하는 것이 못 잡는 것보다 나쁘다.
    for (final entry in hangulStrokes.entries) {
      for (var i = 0; i < entry.value.length; i++) {
        final attempt = evaluateStroke(
          target: entry.value,
          expectedIndex: i,
          drawn: trace(entry.value[i], jitter: 25),
          canvasSize: canvas,
        );
        expect(
          attempt.ok,
          isTrue,
          reason: '${entry.key} 의 $i 번 획을 25px 삐뚤게 그었더니 '
              '${attempt.verdict.name} 로 튕겼다',
        );
      }
    }
  });

  test('다른 획을 그으면 wrongOrder 로 잡고, 그게 몇 번 획인지 알려준다', () {
    var checked = 0;
    for (final entry in hangulStrokes.entries) {
      final target = entry.value;
      if (target.length < 2) {
        continue;
      }
      for (var expected = 0; expected < target.length; expected++) {
        for (var actual = 0; actual < target.length; actual++) {
          if (expected == actual || _isKnownPair(entry.key, expected, actual)) {
            continue;
          }
          final attempt = evaluateStroke(
            target: target,
            expectedIndex: expected,
            drawn: trace(target[actual]),
            canvasSize: canvas,
          );
          expect(
            attempt.verdict,
            StrokeVerdict.wrongOrder,
            reason: '${entry.key}: $expected 번을 기대했는데 $actual 번을 '
                '그었다 — wrongOrder 로 잡혀야 한다',
          );
          expect(
            attempt.matchedIndex,
            actual,
            reason: '${entry.key}: 실제로 그은 획 번호를 정확히 짚어야 '
                '"그건 N번 획이에요" 라고 말해줄 수 있다',
          );
          checked++;
        }
      }
    }
    // 전수 대조가 실제로 돌았는지 — 루프가 조용히 비는 회귀 방지.
    expect(checked, greaterThan(200));
  });

  test('알려진 한계는 딱 4쌍이다 — 늘어나면 판정이 느슨해진 것이다', () {
    final confusable = <String>[];
    for (final entry in hangulStrokes.entries) {
      final target = entry.value;
      for (var expected = 0; expected < target.length; expected++) {
        for (var actual = 0; actual < target.length; actual++) {
          if (expected == actual) {
            continue;
          }
          final attempt = evaluateStroke(
            target: target,
            expectedIndex: expected,
            drawn: trace(target[actual]),
            canvasSize: canvas,
          );
          if (attempt.ok) {
            confusable.add('${entry.key} $actual->$expected');
          }
        }
      }
    }
    expect(
      confusable,
      hasLength(4),
      reason: 'ㅃ 1<->4 (20px) · ㅝ 0<->2 (26px) 양방향 4건이 전부여야 한다. '
          '실제: ${confusable.join(", ")}',
    );
  });

  group('방향', () {
    test('선 획을 거꾸로 그으면 wrongDirection — checkDirection: true', () {
      final target = hangulStrokes['ㅡ']!;
      final attempt = evaluateStroke(
        target: target,
        expectedIndex: 0,
        drawn: trace(target[0]).reversed.toList(),
        canvasSize: canvas,
      );
      expect(attempt.verdict, StrokeVerdict.wrongDirection);
    });

    test('checkDirection: false 면 거꾸로 그어도 ok — 기존 관대함 유지', () {
      final target = hangulStrokes['ㅡ']!;
      final attempt = evaluateStroke(
        target: target,
        expectedIndex: 0,
        drawn: trace(target[0]).reversed.toList(),
        canvasSize: canvas,
        checkDirection: false,
      );
      expect(attempt.verdict, StrokeVerdict.ok);
    });

    test('짧은 획도 정방향이면 wrongDirection 이 아니다', () {
      // ㅊ 의 윗점(50px)·ㅎ 의 윗점(42px)은 어느 쪽으로 그어도 오차가 작다.
      // _directionMargin 이 없으면 여기서 오탐이 난다.
      for (final letter in ['ㅊ', 'ㅎ']) {
        final target = hangulStrokes[letter]!;
        final attempt = evaluateStroke(
          target: target,
          expectedIndex: 0,
          drawn: trace(target[0]),
          canvasSize: canvas,
        );
        expect(attempt.verdict, StrokeVerdict.ok, reason: letter);
      }
    });

    test('원(ㅇ·ㅎ)은 방향을 보지 않는다 — 어느 쪽으로 돌려도 ok', () {
      final o = hangulStrokes['ㅇ']!;
      expect(
        evaluateStroke(
          target: o,
          expectedIndex: 0,
          drawn: trace(o[0]).reversed.toList(),
          canvasSize: canvas,
        ).verdict,
        StrokeVerdict.ok,
      );
      final h = hangulStrokes['ㅎ']!;
      expect(
        evaluateStroke(
          target: h,
          expectedIndex: 2,
          drawn: trace(h[2]).reversed.toList(),
          canvasSize: canvas,
        ).verdict,
        StrokeVerdict.ok,
      );
    });
  });

  group('그 밖의 판정', () {
    test('엉뚱한 낙서는 offShape — 짚어줄 획이 없으니 matchedIndex 도 없다', () {
      final target = hangulStrokes['ㄱ']!;
      final attempt = evaluateStroke(
        target: target,
        expectedIndex: 0,
        drawn: const [Offset(5, 200), Offset(40, 218)],
        canvasSize: canvas,
      );
      expect(attempt.verdict, StrokeVerdict.offShape);
      expect(attempt.matchedIndex, isNull);
    });

    test('점 하나는 tooShort', () {
      final target = hangulStrokes['ㄱ']!;
      expect(
        evaluateStroke(
          target: target,
          expectedIndex: 0,
          drawn: const [Offset(30, 55)],
          canvasSize: canvas,
        ).verdict,
        StrokeVerdict.tooShort,
      );
    });

    test('손 떨림 수준의 짧은 흔적도 tooShort — 리샘플하면 잘 맞아버린다', () {
      final target = hangulStrokes['ㄱ']!;
      expect(
        evaluateStroke(
          target: target,
          expectedIndex: 0,
          drawn: const [Offset(30, 55), Offset(36, 57)],
          canvasSize: canvas,
        ).verdict,
        StrokeVerdict.tooShort,
      );
    });

    test('캔버스가 작아도 같은 판정 — 정규화가 맞는지', () {
      final target = hangulStrokes['ㅂ']!;
      List<Offset> half(Stroke s) =>
          [for (final p in trace(s)) Offset(p.dx / 2, p.dy / 2)];
      expect(
        evaluateStroke(
          target: target,
          expectedIndex: 0,
          drawn: half(target[0]),
          canvasSize: const Size(110, 110),
        ).verdict,
        StrokeVerdict.ok,
      );
      expect(
        evaluateStroke(
          target: target,
          expectedIndex: 0,
          drawn: half(target[3]),
          canvasSize: const Size(110, 110),
        ).verdict,
        StrokeVerdict.wrongOrder,
      );
    });

    test('범위를 벗어난 expectedIndex 는 안전하게 offShape', () {
      final target = hangulStrokes['ㄱ']!;
      expect(
        evaluateStroke(
          target: target,
          expectedIndex: 5,
          drawn: trace(target[0]),
          canvasSize: canvas,
        ).verdict,
        StrokeVerdict.offShape,
      );
    });
  });

  test('한글 낱자 34자 전부 획순 데이터가 있다', () {
    // 데이터 없는 글자는 판정이 통째로 꺼져 Finish 가 영영 안 열린다.
    for (final letter in hangulStrokes.keys) {
      expect(hangulStrokes[letter], isNotEmpty, reason: letter);
    }
  });
}
