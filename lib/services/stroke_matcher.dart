/// 손가락으로 그린 획이 정답 획순과 맞는지 판정한다.
///
/// 2026-08-12: "제대로 맞게 그리면 맞은 소리 나면서 자동으로 넘어가는 게 있었는데
/// 없어졌어"(Jin). 저장소 전 이력(`git log --all -S`)을 뒤져보니 획 정확도를 보는
/// 코드는 **한 번도 없었다** — `_onStrokeEnd` 가 획 개수만 세고 있었다. 되돌리기가
/// 아니라 신규 구현이다.
///
/// 2026-08-18: 테스터(Amor)가 "일부러 획순을 틀려도 인식하지 못하고 그냥
/// 진행된다"고 보고했다. 원인은 판정 로직이 아니라 **판정 시점과 피드백**이었다 —
/// 획 수가 정답 수와 같아지는 순간 한 번만 보고, 틀리면 아무 말도 하지 않았다.
/// 그래서 획 하나를 뗄 때마다 그 획만 보는 [evaluateStroke] 를 아래에 깔고,
/// [matchStrokes] 는 그 위의 얇은 래퍼로 남긴다.
///
/// 판정 기준은 "글자를 알아볼 수 있게 그렸는가"다. 필체 교정이 아니라 학습
/// 피드백이므로 관대해야 한다:
///   - 획 **개수**와 **순서**는 본다 (획순 학습이 이 화면의 목적이다)
///   - 획 **방향**은 [evaluateStroke] 에서만 선택적으로 본다
///     ([checkDirection]). 한글 필순 규칙(위→아래·왼→오른)이 실재하므로 학습
///     화면에서는 켜지만, [matchStrokes] 의 기존 계약(거꾸로 그어도 통과)은
///     그대로 지킨다
///   - 모양은 리샘플링 후 평균 거리로 본다
///
/// **알려진 한계 (실측, 2026-08-18 — `evaluateStroke` 전수 대조):**
/// 34자 × 모든 획 쌍을 돌려보면 서로 구별 못 하는 순서쌍이 **4건** 남는다.
///   - ㅃ 의 안쪽 두 세로획(index 1↔4): 실제로 **20px** 밖에 안 떨어져 있다.
///   - ㅝ 의 위·아래 가로획(index 0↔2): 26px.
/// 손가락 입력을 받으려면 tolerance 가 이보다 커야 하므로 이 둘은 원리상
/// 구별할 수 없다. 오판 방향은 **항상 관대한 쪽**이다 — 다른 획 후보는 기대
/// 획이 떨어진 *뒤에만* 찾으므로 맞게 그은 걸 틀렸다고 하는 일은 구조적으로
/// 없다. 같은 대조에서 정상 입력은 **25px 삐뚤어져도 34자 전부 통과**한다.
/// **이걸 고치겠다고 [defaultStrokeTolerance] 를 낮추지 말 것** — 나머지 글자
/// 전부에서 정상적인 손가락 입력이 튕긴다. 정 필요하면 글자별 tolerance 를
/// `hangul_strokes.dart` 에 데이터로 넣는 게 옳은 수순이다.
///
library;

import 'dart:math' as math;
import 'dart:ui';

import '../data/hangul_strokes.dart';

/// 획 하나를 비교할 때 쓰는 표본 수. 24면 ㄹ 처럼 꺾임이 많은 획도 형태가
/// 뭉개지지 않고, 계산은 여전히 프레임 하나 안에 끝난다.
const int _samples = 24;

/// [strokeCanvas](220×220) 좌표계에서 허용하는 평균 오차(px).
///
/// 34 는 캔버스 한 변의 약 15%. 손가락 입력이라 20 이하로 조이면 정상적으로 그린
/// 것도 자주 튕기고, 50 을 넘기면 아무렇게나 그어도 통과한다.
const double defaultStrokeTolerance = 34;

/// 획 하나로 인정할 최소 길이. [strokeCanvas] 기준(px).
///
/// 가장 짧은 기준 획은 ㅎ 의 윗점(42)·ㅊ 의 윗점(50) 이라 18 은 안전하다.
/// 정규화 **후** 재므로 작은 캔버스일수록 실제 손가락 거리 기준으로는 느슨해진다.
const double minStrokeLength = 18;

/// 획의 **양 끝점**이 기준 획의 끝점에서 이만큼 안에 있어야 그 획으로 인정한다.
///
/// 평균 거리만 보면 서로 교차하거나 나란한 짧은 획들이 뭉개진다 — ㅉ 의 두
/// 삐침(평균 33)·ㅝ 의 세로와 아래 가로(평균 30)가 그랬다. 끝점은 그 둘을
/// 분명히 가른다(각각 66·69). 캔버스 한 변의 25% 라 유령 글자를 따라 그린
/// 손가락 입력은 넉넉히 통과한다.
const double _endpointTolerance = 55;

/// 정방향/역방향 오차가 이만큼 벌어져야 "거꾸로 그었다"고 단정한다.
///
/// 짧은 획(ㅊ 의 첫 점획 등)은 어느 쪽으로 그어도 오차가 둘 다 작다. 여유 없이
/// 단순 비교하면 정상적으로 그은 짧은 획을 방향 오답으로 튕긴다.
const double _directionMargin = 8;

class StrokeMatch {
  const StrokeMatch({required this.matched, required this.meanError});

  final bool matched;

  /// 220 기준 좌표계에서의 평균 오차. 판정이 애매할 때 임계값을 조정하는 근거로
  /// 쓰라고 노출한다. 획 수가 다르면 [double.infinity].
  final double meanError;
}

/// 획 하나에 대한 판정 결과.
enum StrokeVerdict {
  /// 기대한 획을 맞게 그었다.
  ok,

  /// 기대한 획은 아니지만 **아직 안 그린 다른 획**과 맞는다.
  /// 이게 테스터가 지적한 바로 그 경우 — "그건 3번 획이에요"라고 말해줄 수 있다.
  wrongOrder,

  /// 모양·위치는 맞는데 반대 방향으로 그었다 (ㅇ·ㅎ 의 원은 방향을 안 본다).
  wrongDirection,

  /// 어느 획과도 맞지 않는다.
  offShape,

  /// 점 하나 — 획이 아니다.
  tooShort,
}

/// 방금 그은 획 하나에 대한 판정.
class StrokeAttempt {
  const StrokeAttempt({
    required this.verdict,
    required this.expectedIndex,
    this.matchedIndex,
    this.error = double.infinity,
  });

  final StrokeVerdict verdict;

  /// 이번에 그렸어야 할 획의 index.
  final int expectedIndex;

  /// [StrokeVerdict.wrongOrder] 일 때, 실제로 맞은 획의 index. 그 외엔 null.
  final int? matchedIndex;

  /// 기대 획([expectedIndex])과의 오차. 220 기준 좌표계.
  final double error;

  bool get ok => verdict == StrokeVerdict.ok;
}

/// 방금 그은 획 [drawn] 하나를 기대 획 `target[expectedIndex]` 와 대조한다.
///
/// 기대 획이 떨어지면 **나머지 모든 기준 획**과 대조해 가장 닮은 것을 찾는다.
/// 이미 그린 획도 후보에 넣는다 — "그건 방금 그은 1번 획이에요" 가
/// "모르겠어요" 보다 낫다. [checkDirection] 이 true 면 선 획의 진행 방향까지 본다.
///
/// [canvasSize] 는 사용자가 그린 캔버스의 실제 크기 — [strokeCanvas] 로 정규화
/// 하는 데 쓴다. 정사각형이 아니어도 축별로 따로 스케일한다.
StrokeAttempt evaluateStroke({
  required List<Stroke> target,
  required int expectedIndex,
  required List<Offset> drawn,
  required Size canvasSize,
  double tolerance = defaultStrokeTolerance,
  bool checkDirection = true,
}) {
  if (expectedIndex < 0 || expectedIndex >= target.length) {
    return StrokeAttempt(
      verdict: StrokeVerdict.offShape,
      expectedIndex: expectedIndex,
    );
  }
  if (canvasSize.width <= 0 || canvasSize.height <= 0) {
    return StrokeAttempt(
      verdict: StrokeVerdict.offShape,
      expectedIndex: expectedIndex,
    );
  }
  if (drawn.length < 2) {
    // 점 하나는 획이 아니다 — 톡 친 것.
    return StrokeAttempt(
      verdict: StrokeVerdict.tooShort,
      expectedIndex: expectedIndex,
    );
  }

  final sx = strokeCanvas.width / canvasSize.width;
  final sy = strokeCanvas.height / canvasSize.height;
  final user = [for (final p in drawn) Offset(p.dx * sx, p.dy * sy)];
  if (_polylineLength(user) < minStrokeLength) {
    // 손 떨림 수준의 짧은 흔적. 리샘플하면 점 뭉치가 돼 엉뚱하게 잘 맞는다.
    return StrokeAttempt(
      verdict: StrokeVerdict.tooShort,
      expectedIndex: expectedIndex,
    );
  }

  final expected = _errorAgainst(target[expectedIndex], user);
  if (expected.value <= tolerance &&
      expected.endpointError <= _endpointTolerance) {
    if (checkDirection &&
        expected.directional &&
        expected.backward + _directionMargin < expected.forward) {
      return StrokeAttempt(
        verdict: StrokeVerdict.wrongDirection,
        expectedIndex: expectedIndex,
        error: expected.value,
      );
    }
    return StrokeAttempt(
      verdict: StrokeVerdict.ok,
      expectedIndex: expectedIndex,
      error: expected.value,
    );
  }

  // 기대 획이 아니라면, 다른 획을 그은 건 아닌지 본다.
  var bestIndex = -1;
  var bestError = double.infinity;
  for (var i = 0; i < target.length; i++) {
    if (i == expectedIndex) {
      continue;
    }
    final other = _errorAgainst(target[i], user);
    if (other.value <= tolerance &&
        other.endpointError <= _endpointTolerance &&
        other.value < bestError) {
      bestIndex = i;
      bestError = other.value;
    }
  }
  if (bestIndex >= 0) {
    return StrokeAttempt(
      verdict: StrokeVerdict.wrongOrder,
      expectedIndex: expectedIndex,
      matchedIndex: bestIndex,
      error: expected.value,
    );
  }

  return StrokeAttempt(
    verdict: StrokeVerdict.offShape,
    expectedIndex: expectedIndex,
    error: expected.value,
  );
}

/// [drawn](캔버스 로컬 좌표)이 [target] 획순과 맞는지 본다.
///
/// [evaluateStroke] 를 순서대로 돌리는 얇은 래퍼다. 방향은 보지 않아
/// "거꾸로 그어도 통과" 라는 기존 계약이 그대로 유지된다.
StrokeMatch matchStrokes({
  required List<Stroke> target,
  required List<List<Offset>> drawn,
  required Size canvasSize,
  double tolerance = defaultStrokeTolerance,
}) {
  if (target.isEmpty || drawn.length != target.length) {
    return const StrokeMatch(matched: false, meanError: double.infinity);
  }
  if (canvasSize.width <= 0 || canvasSize.height <= 0) {
    return const StrokeMatch(matched: false, meanError: double.infinity);
  }

  var total = 0.0;
  for (var i = 0; i < target.length; i++) {
    final attempt = evaluateStroke(
      target: target,
      expectedIndex: i,
      drawn: drawn[i],
      canvasSize: canvasSize,
      tolerance: tolerance,
      checkDirection: false,
    );
    if (!attempt.ok) {
      return StrokeMatch(matched: false, meanError: attempt.error);
    }
    total += attempt.error;
  }
  return StrokeMatch(matched: true, meanError: total / target.length);
}

/// 한 획에 대한 오차. 선 획만 방향([directional])을 논할 수 있다.
class _StrokeError {
  const _StrokeError({
    required this.forward,
    required this.backward,
    required this.endpointForward,
    required this.endpointBackward,
    required this.directional,
  });

  const _StrokeError.omnidirectional(double value)
    : forward = value,
      backward = value,
      endpointForward = 0,
      endpointBackward = 0,
      directional = false;

  final double forward;
  final double backward;

  /// 시작점·끝점 오차 중 큰 쪽. 원([CircleStroke])은 끝점 개념이 없어 0.
  final double endpointForward;
  final double endpointBackward;
  final bool directional;

  bool get _forwardWins => forward <= backward;
  double get value => math.min(forward, backward);
  double get endpointError => _forwardWins ? endpointForward : endpointBackward;
}

_StrokeError _errorAgainst(Stroke target, List<Offset> user) =>
    switch (target) {
      LineStroke(:final points) => _polylineError(points, user),
      CircleStroke(:final center, :final radius) => _StrokeError
          .omnidirectional(_circleError(center, radius, user)),
    };

/// 두 폴리라인을 같은 개수로 리샘플링해 평균 거리를 구한다.
/// 정방향·역방향을 따로 돌려준다 — 모양 판정엔 나은 쪽을, 방향 판정엔 둘의
/// 차이를 쓴다.
_StrokeError _polylineError(List<Offset> target, List<Offset> user) {
  final t = _resample(target, _samples);
  final u = _resample(user, _samples);
  var forward = 0.0;
  var backward = 0.0;
  for (var i = 0; i < _samples; i++) {
    forward += (t[i] - u[i]).distance;
    backward += (t[i] - u[_samples - 1 - i]).distance;
  }
  return _StrokeError(
    forward: forward / _samples,
    backward: backward / _samples,
    endpointForward: math.max(
      (t.first - u.first).distance,
      (t.last - u.last).distance,
    ),
    endpointBackward: math.max(
      (t.first - u.last).distance,
      (t.last - u.first).distance,
    ),
    directional: true,
  );
}

/// ㅇ·ㅎ 의 동그라미. 시작점과 방향이 사람마다 달라 폴리라인으로 비교하면
/// 멀쩡히 그린 원도 떨어진다 → 중심과 반지름만 본다.
double _circleError(Offset center, double radius, List<Offset> user) {
  var cx = 0.0;
  var cy = 0.0;
  for (final p in user) {
    cx += p.dx;
    cy += p.dy;
  }
  final drawnCenter = Offset(cx / user.length, cy / user.length);
  var meanRadius = 0.0;
  for (final p in user) {
    meanRadius += (p - drawnCenter).distance;
  }
  meanRadius /= user.length;
  return (drawnCenter - center).distance + (meanRadius - radius).abs();
}

/// 폴리라인의 총 길이.
double _polylineLength(List<Offset> points) {
  var length = 0.0;
  for (var i = 1; i < points.length; i++) {
    length += (points[i] - points[i - 1]).distance;
  }
  return length;
}

/// 폴리라인을 길이 기준으로 [count] 개 등간격 점으로 다시 뽑는다.
List<Offset> _resample(List<Offset> points, int count) {
  if (points.length == 1) {
    return List<Offset>.filled(count, points.first);
  }
  final segments = <double>[];
  var length = 0.0;
  for (var i = 1; i < points.length; i++) {
    final d = (points[i] - points[i - 1]).distance;
    segments.add(d);
    length += d;
  }
  if (length == 0) {
    return List<Offset>.filled(count, points.first);
  }

  final out = <Offset>[points.first];
  final step = length / (count - 1);
  var seg = 0;
  var walked = 0.0; // 현재 세그먼트 시작까지의 누적 길이
  for (var i = 1; i < count - 1; i++) {
    final wanted = step * i;
    while (seg < segments.length - 1 && walked + segments[seg] < wanted) {
      walked += segments[seg];
      seg++;
    }
    final within = segments[seg] == 0
        ? 0.0
        : ((wanted - walked) / segments[seg]).clamp(0.0, 1.0);
    out.add(Offset.lerp(points[seg], points[seg + 1], within)!);
  }
  out.add(points.last);
  return out;
}
