import 'package:flutter/material.dart';

import '../../models/gye.dart';
import '../../models/hanok_stage.dart';
import 'madang_background.dart';

/// 계 공동 한옥 — 종갓집 배경 위에 계 추가 요소(gye_* 8장)를 합성. plan §7.5.
///
/// 합산 진행도가 높을수록 요소가 순서대로 잠금 해제. **현재 unlock은 placeholder
/// (`weeklyGoalProgress` 기반)** — 3e Cloud Function이 계원 합산 진행도로 대체.
/// 잠긴 요소는 흐리게(ghost) 그려 "함께 지어갈 모습"을 미리 보여준다(자산 8장 모두 노출).
/// 좌표는 시안값 — 실기기 육안 튜닝 필요(Jin).
class GyeHanok extends StatelessWidget {
  final GyeMeta meta;

  const GyeHanok({super.key, required this.meta});

  // (slug, leftFrac, bottomFrac, widthFrac) — 리스트 순서 = 잠금 해제 순 + 뒤→앞 z순.
  // (slug, leftFrac, bottomFrac, widthFrac) — 리스트 순서 = 뒤→앞 z순 + 잠금 해제 순.
  // PIL 합성 프리뷰(393×280)로 보정한 시안값. 실기기에서 미세 조정 가능.
  static const List<({String slug, double left, double bottom, double width})>
      _elements = [
    // 뒤(건물)
    (slug: 'gye_gate_grand', left: 0.31, bottom: 0.00, width: 0.46),
    (slug: 'gye_haenglangchae', left: 0.00, bottom: 0.16, width: 0.40),
    (slug: 'gye_byeoldang', left: 0.64, bottom: 0.18, width: 0.34),
    (slug: 'gye_jeongja', left: 0.72, bottom: 0.46, width: 0.26),
    // 앞(조경)
    (slug: 'gye_garden', left: 0.00, bottom: 0.00, width: 0.33),
    (slug: 'gye_jangmyeongdeung_pair', left: 0.30, bottom: 0.05, width: 0.15),
    (slug: 'gye_pond_large', left: 0.28, bottom: 0.01, width: 0.40),
    (slug: 'gye_bridge', left: 0.40, bottom: 0.085, width: 0.20),
  ];

  /// placeholder — 최소 1개 + 주간 3팩당 1개. 3e CF가 합산 진행도로 대체.
  int get _unlocked =>
      (1 + meta.weeklyGoalProgress ~/ 3).clamp(1, _elements.length);

  @override
  Widget build(BuildContext context) {
    final unlocked = _unlocked;
    return MadangBackground(
      stage: HanokStage.jongga,
      child: LayoutBuilder(
        builder: (ctx, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          return Stack(
            children: [
              for (var i = 0; i < _elements.length; i++)
                Positioned(
                  left: w * _elements[i].left,
                  bottom: h * _elements[i].bottom,
                  width: w * _elements[i].width,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: i < unlocked ? 1.0 : 0.22,
                      child: Image.asset(
                        'assets/illustrations/gye/${_elements[i].slug}.png',
                        width: w * _elements[i].width,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
