import 'package:flutter/material.dart';

import 'tokens.dart';

/// **SoriSectionHeader** — 한지 에디토리얼 섹션 헤더.
///
/// 명조(serif) 제목 + 뒤로 이어지는 단청 골드 hairline rule. 잡지 섹션
/// 헤더식(제목 좌 · 얇은 선 우)으로, 균일 카드스택의 밋밋한 볼드-텍스트
/// 헤더를 대체해 리듬과 위계를 만든다.
class SoriSectionHeader extends StatelessWidget {
  final String title;

  /// 제목 우측 끝에 붙는 선택적 액션(예: "모두 보기").
  final Widget? trailing;

  const SoriSectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: 2,
        top: Spacing.xs,
        bottom: Spacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 명조 제목(D1 serif h2).
          Flexible(child: Text(title, style: tt.h2)),
          const SizedBox(width: Spacing.md),
          // 단청 골드 hairline — 남은 폭을 채운다(에디토리얼 rule).
          Expanded(
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                color: SoriColors.gold.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: Spacing.sm),
            // §W-A2: 고정폭 trailing 이 제목·헤어라인과 합쳐 폭을 넘던
            // 자리 — Flexible 로 감싸 필요하면 줄바꿈으로 흡수한다.
            Flexible(child: trailing!),
          ],
        ],
      ),
    );
  }
}
