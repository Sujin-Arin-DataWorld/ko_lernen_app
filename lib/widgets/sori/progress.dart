import 'package:flutter/material.dart';

import 'progress_meter.dart';
import 'tokens.dart';

/// **SoriProgressBar** — Duolingo 식 두꺼운 라운드 progress.
///
/// 사용:
/// ```dart
/// SoriProgressBar(value: 0.6, thickness: 10)  // linear
/// SoriProgressBar(value: 0.6, thickness: 10, color: SoriColors.success, animated: true)
/// ```
///
/// §W-D D1: 내부는 [SoriProgressMeter.bar] 로 위임한다 — 이 클래스는 기존
/// 13개 호출부(`grep -rn "SoriProgressBar("`, 2026-09-03 실측: `quests_screen`
/// 2곳이 `trackColor`, 여러 곳이 `animated: false` 사용)의 API·시각 결과를
/// 그대로 지키는 얇은 어댑터로만 남는다. `duration` 은 받되 쓰지 않는다 —
/// 실측상 모든 호출부가 기본값(`SoriMotion.verySlow` = 600ms)을 그대로
/// 두고 있고, 그 값은 [SoriProgressMeter] 의 고정 600ms 등장 애니메이션과
/// 우연히 일치한다.
class SoriProgressBar extends StatelessWidget {
  final double value; // 0.0 - 1.0
  final double thickness;
  final Color? color;
  final Color? trackColor;
  final bool animated;
  final Duration duration;

  const SoriProgressBar({
    super.key,
    required this.value,
    this.thickness = 8,
    this.color,
    this.trackColor,
    this.animated = false,
    this.duration = SoriMotion.verySlow,
  });

  @override
  Widget build(BuildContext context) => SoriProgressMeter.bar(
    value: value,
    height: thickness,
    color: color,
    trackColor: trackColor,
    animate: animated,
  );
}
