import 'dart:math' as math;

import 'package:flutter/material.dart';

/// **SoriSwipeRails** — 덱 카드 네 변의 방향 어포던스 레일 (Sori Deck 3.0,
/// 2026-08-18).
///
/// Jin 요구: *"어떤 방향으로 슬라이스하면 어떤 결과가 있는지 말 안 해도
/// 유저가 알게끔"*. 스탬프(`_Stamp`)는 드래그를 시작해야 뜨므로 **정지
/// 상태에서는 아무 정보도 없었다**. 레일은 정지 상태에서도 옅게(0.16) 늘
/// 보여서
///
/// - **어느 방향이 살아 있는지** (꺼진 방향은 레일 자체가 없다 — 예: 커스텀
///   팩의 ↑ 저장, 자모 카드의 ↑),
/// - **각 방향이 무슨 뜻인지** (색은 그 방향 **배지에서 온다** — 호출부가 정한
///   판정 색과 같아진다. 배지가 없는 방향은 중립색으로 빠진다),
/// - **얼마나 더 밀어야 확정되는지** (커밋 진행도에 비례해 길이·불투명도·
///   두께가 자란다. 1.0 에서 변을 꽉 채우고 임계 햅틱이 함께 울린다)
///
/// 를 한 번에 읽힌다.
///
/// 카드 **안쪽**에 그린다(= 카드와 함께 이동·회전한다). 슬롯 기준 고정 트랙도
/// 후보였지만, 덱 화면마다 `heightFactor` 가 달라 카드와 슬롯 사이에 여백이
/// 생기면 레일이 카드에서 떨어져 뜬다. 카드에 붙이면 어떤 레이아웃에서도
/// 변 위에 정확히 앉는다.
///
/// ⚠️ 새 pill/chip 크롬이 아니다 (순수 기하 요소) — `jin-no-ios-style-badges`.
/// 장식이므로 [IgnorePointer] + [ExcludeSemantics] 로 감싸 쓴다(호출부 담당).
class SoriSwipeRails extends StatelessWidget {
  const SoriSwipeRails({
    super.key,
    required this.left,
    required this.right,
    required this.up,
    required this.down,
    this.inset = 10,
  });

  /// 방향별 `(진행도 0..1, 색)`. **null 이면 그 방향은 꺼져 있어 레일을 그리지
  /// 않는다** — "그 방향이 없다"는 것도 정보다.
  final SoriRailState? left;
  final SoriRailState? right;
  final SoriRailState? up;
  final SoriRailState? down;

  /// 카드 모서리 곡률(SoriRadius.lg = 20)을 피해 변의 직선 구간에 앉히는 여백.
  ///
  /// ⚠️ 10 은 임의 값이 아니다. [SoriCard] 는 `accent` 가 있으면 `left: 0,
  /// width: 4` 로 **전체 높이 세로 막대**를 그린다(card.dart:196-203). 초판의
  /// inset 6 은 그 막대 바로 옆(x 6~9)에 레일을 놓아 왼쪽 변에 세로 막대가
  /// 두 개 서는 꼴이었다 — 어포던스를 만들려다 시각 노이즈를 넣은 것이다.
  /// 10 이면 accent 막대와 6px 떨어져 "카드 안의 표시"로 읽힌다.
  final double inset;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: CustomPaint(
            painter: _RailsPainter(
              left: left,
              right: right,
              up: up,
              down: down,
              inset: inset,
            ),
          ),
        ),
      ),
    );
  }
}

/// 한 방향 레일의 상태.
@immutable
class SoriRailState {
  const SoriRailState({required this.progress, required this.color});

  /// 커밋 진행도 0..1. 1.0 = 지금 놓으면 확정.
  final double progress;
  final Color color;

  @override
  bool operator ==(Object other) =>
      other is SoriRailState &&
      other.progress == progress &&
      other.color == color;

  @override
  int get hashCode => Object.hash(progress, color);
}

class _RailsPainter extends CustomPainter {
  const _RailsPainter({
    required this.left,
    required this.right,
    required this.up,
    required this.down,
    required this.inset,
  });

  final SoriRailState? left;
  final SoriRailState? right;
  final SoriRailState? up;
  final SoriRailState? down;
  final double inset;

  /// 정지 상태 길이 — 변 길이 비율이 아니라 **고정 44dp**(변보다 길면 변에 맞춤).
  ///
  /// 초판은 변의 40% 였는데, 그러면 긴 변에서 레일이 테두리만큼 길어져
  /// [SoriCard] 의 accent 막대와 같은 종류로 보였다. 짧은 고정 길이는 "여기를
  /// 밀어라"는 **표시**로 읽히고, 드래그하면 변을 채우며 자란다 — 정지/진행의
  /// 차이가 길이로 드러난다.
  static const double _restLength = 44;
  static const double _restAlpha = 0.16;
  static const double _activeAlpha = 0.90;
  static const double _restThickness = 3;
  static const double _activeThickness = 5;

  @override
  void paint(Canvas canvas, Size size) {
    _paintRail(canvas, size, left, _RailEdge.left);
    _paintRail(canvas, size, right, _RailEdge.right);
    _paintRail(canvas, size, up, _RailEdge.top);
    _paintRail(canvas, size, down, _RailEdge.bottom);
  }

  void _paintRail(
    Canvas canvas,
    Size size,
    SoriRailState? state,
    _RailEdge edge,
  ) {
    if (state == null) {
      return;
    }
    final double t = state.progress.clamp(0.0, 1.0);
    final double alpha = _restAlpha + (_activeAlpha - _restAlpha) * t;
    final double thickness =
        _restThickness + (_activeThickness - _restThickness) * t;
    final bool vertical = edge == _RailEdge.left || edge == _RailEdge.right;
    final double edgeLength = vertical ? size.height : size.width;
    final double usable = (edgeLength - inset * 2).clamp(0.0, edgeLength);
    final double rest = math.min(_restLength, usable);
    final double length = rest + (usable - rest) * t;
    if (length <= 0 || thickness <= 0) {
      return;
    }
    final double center = edgeLength / 2;
    final Paint paint = Paint()
      ..color = state.color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    final Rect rect;
    switch (edge) {
      case _RailEdge.left:
        rect = Rect.fromLTWH(
          inset,
          center - length / 2,
          thickness,
          length,
        );
      case _RailEdge.right:
        rect = Rect.fromLTWH(
          size.width - inset - thickness,
          center - length / 2,
          thickness,
          length,
        );
      case _RailEdge.top:
        rect = Rect.fromLTWH(
          center - length / 2,
          inset,
          length,
          thickness,
        );
      case _RailEdge.bottom:
        rect = Rect.fromLTWH(
          center - length / 2,
          size.height - inset - thickness,
          length,
          thickness,
        );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(thickness / 2)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_RailsPainter old) =>
      old.left != left ||
      old.right != right ||
      old.up != up ||
      old.down != down ||
      old.inset != inset;
}

enum _RailEdge { left, right, top, bottom }
