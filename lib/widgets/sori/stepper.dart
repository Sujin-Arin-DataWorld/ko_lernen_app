import 'package:flutter/material.dart';

import 'tokens.dart';

/// One [SoriStepper] step's icon + label.
class SoriStepData {
  const SoriStepData({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// **SoriStepper** — 가로 단계 진행 표시 (§W-G G1.3).
///
/// `soriStageGyeFlow`의 화살표 문장("Mission abschließen → Laterne →
/// gemeinsame Hanok")을 대체한다 — 같은 3단계 흐름을 텍스트 화살표 대신
/// 시각 스텝(아이콘 24dp 원형 매트 + `tt.label` 라벨, 단계 사이 얇은
/// 연결선)으로 보여준다. 현재 단계([currentStep])만 `SoriColors.primary`,
/// 나머지는 muted — 완료/대기 구분 없이 "지금 여기" 하나만 강조한다.
///
/// 각 단계는 `Expanded`(동일 폭 3등분)라서 라벨이 길어도(예: "Gemeinsame
/// Hanok") 오버플로 없이 자기 칸 안에서 줄바꿈한다 — 큰 텍스트 배율에서도
/// 안전하다.
class SoriStepper extends StatelessWidget {
  const SoriStepper({super.key, required this.steps, this.currentStep = 0});

  final List<SoriStepData> steps;

  /// 0-based 현재 단계 인덱스. [steps] 범위를 벗어나면 클램프한다.
  final int currentStep;

  static const double _iconMat = 24;
  static const double _lineThickness = 1.5;

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);
    final current = steps.isEmpty
        ? 0
        : currentStep.clamp(0, steps.length - 1);
    final mutedLine = s.border;

    Widget line() =>
        Expanded(child: Container(height: _lineThickness, color: mutedLine));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: _SoriStepNode(
              key: ValueKey('sori-stepper-step-$i'),
              data: steps[i],
              active: i == current,
              leading: i == 0 ? null : line(),
              trailing: i == steps.length - 1 ? null : line(),
              iconMat: _iconMat,
              textTheme: tt,
              surfaces: s,
            ),
          ),
      ],
    );
  }
}

class _SoriStepNode extends StatelessWidget {
  const _SoriStepNode({
    super.key,
    required this.data,
    required this.active,
    required this.leading,
    required this.trailing,
    required this.iconMat,
    required this.textTheme,
    required this.surfaces,
  });

  final SoriStepData data;
  final bool active;
  final Widget? leading;
  final Widget? trailing;
  final double iconMat;
  final SoriTextTheme textTheme;
  final SoriSurfaces surfaces;

  @override
  Widget build(BuildContext context) {
    final accent = active ? SoriColors.primary : surfaces.textMuted;
    // §W-G2 item 1: 스크린리더가 "지금 여기"를 알 수 있게 `selected`를
    // 노출한다. 내부 `Text`는 이미 같은 라벨을 자기 시맨틱스로도 내보내므로
    // `ExcludeSemantics`로 겹치지 않게 감싸 하나의 노드로 합친다.
    return Semantics(
      container: true,
      selected: active,
      label: data.label,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                leading ?? const Spacer(),
                Container(
                  width: iconMat,
                  height: iconMat,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? SoriColors.primarySoft
                        : surfaces.surfaceAlt,
                  ),
                  alignment: Alignment.center,
                  child: Icon(data.icon, size: 14, color: accent),
                ),
                trailing ?? const Spacer(),
              ],
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              data.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: textTheme.label.copyWith(color: accent),
            ),
          ],
        ),
      ),
    );
  }
}
