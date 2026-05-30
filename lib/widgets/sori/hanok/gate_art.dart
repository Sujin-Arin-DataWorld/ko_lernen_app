import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Layered sotdae-mun gate art.
///
/// **v2 자산 정리 (2026-05-29)** — Jin이 보낸 PNG들의 좌표계를 표준화:
/// - `gate_frame.png` (941×1672) — arch + roof + dancheong; **doorway 투명** +
///   **외부 투명** (knockout 완료). Stack의 BOTTOM 레이어가 보이도록.
/// - `gate_door_left.png` (500×1450) — 순수 좌측 문짝 panel. canvas 전체를 채움.
///   hinge = 캔버스 LEFT edge.
/// - `gate_door_right.png` (500×1450) — 순수 우측 문짝 panel. canvas 전체를 채움.
///   hinge = 캔버스 RIGHT edge.
///
/// 문 위치는 frame의 doorway rect 좌표계(195/1080, 615/1920, 345/1080, 1000/1920)
/// 비율을 그대로 유지 — Jin의 원본 frame이 1080×1920 spec 비율을 그대로 따르므로
/// 941×1672 캔버스에서도 같은 fraction이 통한다.
///
/// 문은 `Transform.rotateY` 로 경첩 기준 perspective 회전하며,
/// `gate_frame.png` 가 TOP 레이어에 있어 문이 frame의 두 기둥 뒤로 자연스럽게
/// 사라지는 시각 효과를 만든다 (frame은 doorway가 투명이므로 문이 안 보이는 게
/// 아니라, 회전 각도가 90°에 가까워질수록 문의 화면 투영이 좁아져 사라지는 것).
class HanokGateArt extends StatelessWidget {
  final double openAmount;
  final FilterQuality filterQuality;

  const HanokGateArt({
    super.key,
    this.openAmount = 0,
    this.filterQuality = FilterQuality.medium,
  });

  static const frameAsset = 'assets/illustrations/hanok/gate_frame.png';
  static const leftDoorAsset = 'assets/illustrations/hanok/gate_door_left.png';
  static const rightDoorAsset =
      'assets/illustrations/hanok/gate_door_right.png';

  static const _sourceW = 1080.0;
  static const _sourceH = 1920.0;
  static const _doorLeft = 195.0 / _sourceW;
  static const _doorTop = 615.0 / _sourceH;
  static const _doorW = 345.0 / _sourceW;
  static const _doorH = 1000.0 / _sourceH;
  static const _doorRightLeft = 540.0 / _sourceW;

  @override
  Widget build(BuildContext context) {
    final open = openAmount.clamp(0.0, 1.0);
    // 0.48π ≈ 86° — 거의 90°지만 살짝 덜 열어 단청 detail이 끝까지 보임.
    final angle = open * math.pi * 0.48;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            // ── 좌측 문짝 — 경첩이 좌측 edge, 안쪽(우측)으로 회전해 열림 ──
            Positioned(
              left: w * _doorLeft,
              top: h * _doorTop,
              width: w * _doorW,
              height: h * _doorH,
              child: Transform(
                alignment: Alignment.centerLeft,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0018) // perspective depth
                  ..rotateY(-angle),
                child: Image.asset(
                  leftDoorAsset,
                  fit: BoxFit.fill,
                  filterQuality: filterQuality,
                ),
              ),
            ),
            // ── 우측 문짝 — 경첩이 우측 edge, 안쪽(좌측)으로 회전해 열림 ──
            Positioned(
              left: w * _doorRightLeft,
              top: h * _doorTop,
              width: w * _doorW,
              height: h * _doorH,
              child: Transform(
                alignment: Alignment.centerRight,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0018)
                  ..rotateY(angle),
                child: Image.asset(
                  rightDoorAsset,
                  fit: BoxFit.fill,
                  filterQuality: filterQuality,
                ),
              ),
            ),
            // ── 프레임(지붕·단청·기둥) — TOP 레이어. doorway는 투명이라
            // 그 너머가 보이고, 외부도 투명이라 한지 cream 위로 자연스럽게 떠 있음.
            Positioned.fill(
              child: Image.asset(
                frameAsset,
                fit: BoxFit.fill,
                filterQuality: filterQuality,
              ),
            ),
          ],
        );
      },
    );
  }
}
