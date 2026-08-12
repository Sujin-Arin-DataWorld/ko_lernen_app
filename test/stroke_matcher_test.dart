import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/hangul_strokes.dart';
import 'package:ko_lernen_app/services/stroke_matcher.dart';

/// 원 둘레를 [count] 등분한 점 목록.
List<Offset> circlePoints(Offset center, double radius, {int count = 24}) => [
  for (var i = 0; i <= count; i++)
    Offset(
      center.dx + radius * math.cos(i / count * 2 * math.pi),
      center.dy + radius * math.sin(i / count * 2 * math.pi),
    ),
];

/// [stroke] 를 그대로 따라 그린 것처럼 점 목록을 만든다.
/// [jitter] 만큼 x 로 밀어 "조금 삐뚤게 그린" 상황을 흉내낸다.
List<Offset> trace(Stroke stroke, {double jitter = 0}) => switch (stroke) {
  LineStroke(:final points) => [
    for (final p in points) Offset(p.dx + jitter, p.dy),
  ],
  CircleStroke(:final center, :final radius) => circlePoints(center, radius),
};

void main() {
  const canvas = Size(220, 220); // strokeCanvas 와 동일 → 스케일 1

  group('정확히 따라 그리면 통과', () {
    test('ㄱ — 한 획', () {
      final target = hangulStrokes['ㄱ']!;
      final drawn = [for (final s in target) trace(s)];
      final r = matchStrokes(target: target, drawn: drawn, canvasSize: canvas);
      expect(r.matched, isTrue);
      expect(r.meanError, lessThan(1));
    });

    test('ㄹ — 세 획', () {
      final target = hangulStrokes['ㄹ']!;
      final drawn = [for (final s in target) trace(s)];
      expect(
        matchStrokes(target: target, drawn: drawn, canvasSize: canvas).matched,
        isTrue,
      );
    });

    test('조금 삐뚤어도 통과한다 — 필체 교정이 아니라 학습 피드백이다', () {
      final target = hangulStrokes['ㄴ']!;
      final drawn = [for (final s in target) trace(s, jitter: 12)];
      expect(
        matchStrokes(target: target, drawn: drawn, canvasSize: canvas).matched,
        isTrue,
      );
    });

    test('거꾸로 그어도 통과한다 — 남는 모양이 같다', () {
      final target = hangulStrokes['ㄴ']!;
      final drawn = [for (final s in target) trace(s).reversed.toList()];
      expect(
        matchStrokes(target: target, drawn: drawn, canvasSize: canvas).matched,
        isTrue,
      );
    });
  });

  group('틀리면 떨어진다', () {
    test('획 수가 모자라면 실패', () {
      final target = hangulStrokes['ㄹ']!; // 3획
      final r = matchStrokes(
        target: target,
        drawn: [trace(target.first)],
        canvasSize: canvas,
      );
      expect(r.matched, isFalse);
      expect(r.meanError, double.infinity);
    });

    test('획 수가 많아도 실패', () {
      final target = hangulStrokes['ㄱ']!; // 1획
      final drawn = [trace(target.first), trace(target.first)];
      expect(
        matchStrokes(target: target, drawn: drawn, canvasSize: canvas).matched,
        isFalse,
      );
    });

    test('엉뚱한 곳에 그으면 실패', () {
      final target = hangulStrokes['ㄱ']!;
      final drawn = [
        [const Offset(5, 200), const Offset(30, 215)],
      ];
      expect(
        matchStrokes(target: target, drawn: drawn, canvasSize: canvas).matched,
        isFalse,
      );
    });

    test('점 하나만 톡 친 것은 획이 아니다', () {
      final target = hangulStrokes['ㄱ']!;
      final drawn = [
        [const Offset(30, 55)],
      ];
      expect(
        matchStrokes(target: target, drawn: drawn, canvasSize: canvas).matched,
        isFalse,
      );
    });

    test('획 순서가 뒤바뀌면 실패한다 — 획순 학습이 이 화면의 목적이다', () {
      final target = hangulStrokes['ㅂ']!; // 4획, 획마다 위치가 뚜렷이 다르다
      final drawn = [
        trace(target[3]),
        trace(target[2]),
        trace(target[1]),
        trace(target[0]),
      ];
      expect(
        matchStrokes(target: target, drawn: drawn, canvasSize: canvas).matched,
        isFalse,
      );
    });
  });

  group('캔버스 크기 정규화', () {
    test('절반 크기 캔버스에 절반 좌표로 그려도 통과', () {
      final target = hangulStrokes['ㄴ']!;
      final drawn = [
        for (final s in target)
          [for (final p in trace(s)) Offset(p.dx / 2, p.dy / 2)],
      ];
      expect(
        matchStrokes(
          target: target,
          drawn: drawn,
          canvasSize: const Size(110, 110),
        ).matched,
        isTrue,
      );
    });

    test('캔버스 크기가 0이면 안전하게 실패', () {
      final target = hangulStrokes['ㄱ']!;
      expect(
        matchStrokes(
          target: target,
          drawn: [trace(target.first)],
          canvasSize: Size.zero,
        ).matched,
        isFalse,
      );
    });
  });

  group('동그라미(ㅇ)는 시작점·방향을 안 본다', () {
    test('어디서 시작해도 통과', () {
      final target = hangulStrokes['ㅇ']!;
      final full = trace(target.first);
      final rotated = [...full.sublist(8), ...full.sublist(0, 8)];
      expect(
        matchStrokes(
          target: target,
          drawn: [rotated],
          canvasSize: canvas,
        ).matched,
        isTrue,
      );
    });

    test('너무 작게 그리면 실패', () {
      final target = hangulStrokes['ㅇ']!;
      final tiny = circlePoints(const Offset(110, 110), 8);
      expect(
        matchStrokes(
          target: target,
          drawn: [tiny],
          canvasSize: canvas,
        ).matched,
        isFalse,
      );
    });
  });
}
