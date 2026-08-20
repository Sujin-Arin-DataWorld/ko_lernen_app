import 'package:flutter/material.dart';

import 'tokens.dart';

/// **SoriPageHeader** — 페이지 상단 에디토리얼 헤더 (2026-08-13 Phase 1).
///
/// Vocabulary급 "화면당 1메시지" 패턴의 표준형:
/// eyebrow(자간 넓은 대문자 라벨) → [SoriTextTheme.hero] 헤드라인 → 본문 한 줄.
/// `SoriStageRootHeader` 가 손으로 쓰던 구성을 토큰화한 공용판이며,
/// 온보딩·허브·카탈로그 화면이 같은 위계를 공유하게 한다.
class SoriPageHeader extends StatelessWidget {
  const SoriPageHeader({
    super.key,
    this.eyebrow,
    required this.title,
    this.body,
    this.trailing,
    this.titleStyle,
  });

  /// 헤드라인 위 소형 라벨. 대문자화는 여기서 하지 않는다 — 독일어 ß 등
  /// 로케일 정책은 호출부 소관.
  final String? eyebrow;

  final String title;
  final String? body;

  /// 헤드라인 우측에 붙는 선택적 액션 (예: 프로필 아이콘 버튼).
  final Widget? trailing;

  /// 기본 [SoriTextTheme.hero] 를 다른 위계로 낮출 때 (컴팩트 맥락).
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(eyebrow!, style: tt.eyebrow),
          const SizedBox(height: Spacing.xs),
        ],
        Semantics(
          header: true,
          child: Text(title, style: titleStyle ?? tt.hero),
        ),
        if (body != null) ...[
          const SizedBox(height: Spacing.sm),
          Text(body!, style: tt.body),
        ],
      ],
    );
    if (trailing == null) {
      return column;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: column),
        const SizedBox(width: Spacing.sm),
        trailing!,
      ],
    );
  }
}
