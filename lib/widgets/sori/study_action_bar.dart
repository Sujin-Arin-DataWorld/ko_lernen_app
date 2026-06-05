import 'package:flutter/material.dart';

import 'button.dart';
import 'tokens.dart';

/// 학습 화면 하단 액션 하나(라벨·아이콘·콜백).
class StudyAction {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool destructive;

  const StudyAction({
    required this.label,
    this.onTap,
    this.icon,
    this.destructive = false,
  });
}

/// **StudyActionBar** — 학습 화면 하단 액션 바. 버튼 위계를 강제한다.
///
/// 기존 플래시카드 화면들은 부수 기능(예: Zufällig/랜덤)을 큰 filled 버튼으로
/// 두고 정작 핵심 동선(Weiter/다음)은 밋밋한 outlined로 둬서 위계가 역전돼
/// "싸구려" 느낌을 줬다. 이 컴포넌트로 일관되게 정리한다:
///
/// - [primary]   — 핵심 동선 1개. filled, accent, full-width (가장 강조).
/// - [secondary] — 보조 동선 ≤2개. outlined, 한 줄에 균등 배치.
/// - [tertiary]  — 부수 동선 1개(선택). ghost, small (가장 약함).
///
/// 사용:
/// ```dart
/// StudyActionBar(
///   accent: SoriColors.warning,
///   secondary: [
///     StudyAction(label: t.btnHoeren, icon: Icons.volume_up, onTap: ...),
///     StudyAction(label: t.btnPrev, icon: Icons.arrow_back, onTap: _prev),
///   ],
///   primary: StudyAction(label: t.btnNext, icon: Icons.arrow_forward, onTap: _next),
///   tertiary: StudyAction(label: t.btnRandom, icon: Icons.shuffle, onTap: _random),
/// )
/// ```
class StudyActionBar extends StatelessWidget {
  final StudyAction primary;
  final List<StudyAction> secondary;
  final StudyAction? tertiary;
  final Color accent;

  const StudyActionBar({
    super.key,
    required this.primary,
    this.secondary = const [],
    this.tertiary,
    this.accent = SoriColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (secondary.isNotEmpty) ...[
          Row(
            children: [
              for (var i = 0; i < secondary.length; i++) ...[
                if (i > 0) const SizedBox(width: Spacing.sm),
                Expanded(
                  child: SoriButton.outlined(
                    label: secondary[i].label,
                    icon: secondary[i].icon,
                    fullWidth: true,
                    destructive: secondary[i].destructive,
                    onTap: secondary[i].onTap,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: Spacing.sm),
        ],
        SoriButton.filled(
          label: primary.label,
          icon: primary.icon,
          accent: accent,
          fullWidth: true,
          destructive: primary.destructive,
          onTap: primary.onTap,
        ),
        if (tertiary != null) ...[
          const SizedBox(height: Spacing.xs),
          SoriButton.ghost(
            label: tertiary!.label,
            icon: tertiary!.icon,
            size: SoriButtonSize.sm,
            onTap: tertiary!.onTap,
          ),
        ],
      ],
    );
  }
}
