import 'package:flutter/material.dart';

import '../../models/gye.dart';
import '../../models/hanok_stage.dart';
import 'madang_background.dart';
import 'tokens.dart';

/// 계 공동 한옥 — 종갓집 배경 위에 계 추가 요소(gye_* 8장)를 합성. plan §7.5.
///
/// **물성화(Step C)**: "내 학습이 우리 한옥을 올린다".
/// - 완성된 요소(누적 달성 주간목표) = 실체(1.0, 영구).
/// - **다음 요소 = 이번 주 진행률만큼 실체화**(`weeklyGoalProgress`) + 은은한 호흡
///   ("여기를 함께 짓는 중"). 팩을 깰수록 다음 건물이 ghost→실체로 차오른다.
/// - 그 뒤 요소 = ghost(0.22)로 "앞으로 지어갈 모습" 미리보기.
///
/// 좌표는 시안값 — 실기기 육안 튜닝 필요(Jin).
class GyeHanok extends StatefulWidget {
  final GyeMeta meta;

  const GyeHanok({super.key, required this.meta});

  @override
  State<GyeHanok> createState() => _GyeHanokState();
}

class _GyeHanokState extends State<GyeHanok>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

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

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// 영구 unlock — 기본 1개 + 누적 달성 주간목표 1개당 1요소.
  /// `weekly_goal_rollover` CF가 100% 달성 시 `lifetimeGoalsAchieved`를 올리며,
  /// 주간 진행도 리셋과 무관하게 공동 한옥은 줄어들지 않는다(영구 성장). plan §8.1.
  int get _unlocked =>
      (1 + widget.meta.lifetimeGoalsAchieved).clamp(1, _elements.length);

  /// 요소 기본 실체화 — 완성(1.0) / 다음=이번 주 진행률 ramp / 그 뒤=ghost.
  double _baseOpacity(int i, int unlocked) {
    if (i < unlocked) {
      return 1.0;
    }
    if (i == unlocked && widget.meta.weeklyGoalPacks > 0) {
      final frac = (widget.meta.weeklyGoalProgress / widget.meta.weeklyGoalPacks)
          .clamp(0.0, 1.0);
      return (0.22 + 0.78 * frac).clamp(0.22, 1.0);
    }
    return 0.22;
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = _unlocked;
    final reduce = SoriMotion.reduceMotion(context);
    return MadangBackground(
      stage: HanokStage.jongga,
      child: LayoutBuilder(
        builder: (ctx, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          return AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              return Stack(
                children: [
                  for (var i = 0; i < _elements.length; i++)
                    _element(i, unlocked, w, h, reduce),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _element(int i, int unlocked, double w, double h, bool reduce) {
    final base = _baseOpacity(i, unlocked);
    // "짓는 중" = 다음 요소(미완성). 진행률과 무관하게 은은히 호흡해 살아있게.
    final building = i == unlocked && base < 1.0;
    // C-3: 이번 주 목표를 다 채운 다음 요소 = 완성 축하 (금빛 반짝).
    final complete =
        i == unlocked && base >= 1.0 && widget.meta.weeklyGoalPacks > 0;
    final p = reduce ? 0.0 : _pulse.value;
    final opacity = building ? (base + p * 0.14).clamp(0.0, 1.0) : base;

    Widget child = Image.asset(
      'assets/illustrations/gye/${_elements[i].slug}.png',
      width: w * _elements[i].width,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
    if (complete) {
      child = ColorFiltered(
        colorFilter: ColorFilter.mode(
          SoriColors.gold.withValues(alpha: p * 0.4),
          BlendMode.srcATop,
        ),
        child: child,
      );
    }

    return Positioned(
      left: w * _elements[i].left,
      bottom: h * _elements[i].bottom,
      width: w * _elements[i].width,
      child: IgnorePointer(
        child: Opacity(opacity: opacity, child: child),
      ),
    );
  }
}
