/// 손가락으로 그린 획이 정답 획순과 맞는지 판정한다.
///
/// 2026-08-12: "제대로 맞게 그리면 맞은 소리 나면서 자동으로 넘어가는 게 있었는데
/// 없어졌어"(Jin). 저장소 전 이력(`git log --all -S`)을 뒤져보니 획 정확도를 보는
/// 코드는 **한 번도 없었다** — `_onStrokeEnd` 가 획 개수만 세고 있었다. 되돌리기가
/// 아니라 신규 구현이다.
///
/// 판정 기준은 "글자를 알아볼 수 있게 그렸는가"다. 필체 교정이 아니라 학습
/// 피드백이므로 관대해야 한다:
///   - 획 **개수**와 **순서**는 본다 (획순 학습이 이 화면의 목적이다)
///   - 획 **방향**은 보지 않는다 — ㅡ 를 오른쪽→왼쪽으로 그어도 남는 모양은
///     같고, 여기서 막으면 학습이 아니라 시험이 된다
///   - 모양은 리샘플링 후 평균 거리로 본다
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

class StrokeMatch {
  const StrokeMatch({required this.matched, required this.meanError});

  final bool matched;

  /// 220 기준 좌표계에서의 평균 오차. 판정이 애매할 때 임계값을 조정하는 근거로
  /// 쓰라고 노출한다. 획 수가 다르면 [double.infinity].
  final double meanError;
}

/// [drawn](캔버스 로컬 좌표)이 [target] 획순과 맞는지 본다.
///
/// [canvasSize] 는 사용자가 그린 캔버스의 실제 크기 — [strokeCanvas] 로 정규화
/// 하는 데 쓴다. 정사각형이 아니어도 축별로 따로 스케일한다.
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

  final sx = strokeCanvas.width / canvasSize.width;
  final sy = strokeCanvas.height / canvasSize.height;

  var total = 0.0;
  for (var i = 0; i < target.length; i++) {
    final user = [for (final p in drawn[i]) Offset(p.dx * sx, p.dy * sy)];
    if (user.length < 2) {
      // 점 하나는 획이 아니다 — 톡 친 것.
      return const StrokeMatch(matched: false, meanError: double.infinity);
    }
    final error = switch (target[i]) {
      LineStroke(:final points) => _polylineError(points, user),
      CircleStroke(:final center, :final radius) => _circleError(
        center,
        radius,
        user,
      ),
    };
    if (error > tolerance) {
      return StrokeMatch(matched: false, meanError: error);
    }
    total += error;
  }
  return StrokeMatch(matched: true, meanError: total / target.length);
}

/// 두 폴리라인을 같은 개수로 리샘플링해 평균 거리를 구한다.
/// 뒤집어 그은 경우도 같은 모양이므로 정방향·역방향 중 나은 쪽을 쓴다.
double _polylineError(List<Offset> target, List<Offset> user) {
  final t = _resample(target, _samples);
  final u = _resample(user, _samples);
  var forward = 0.0;
  var backward = 0.0;
  for (var i = 0; i < _samples; i++) {
    forward += (t[i] - u[i]).distance;
    backward += (t[i] - u[_samples - 1 - i]).distance;
  }
  return math.min(forward, backward) / _samples;
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
