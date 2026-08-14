import 'package:flutter/material.dart';

import 'tokens.dart';

/// **SoriAppBar** — 공용 앱바 (2026-08-13 UI 개편 Phase 1).
///
/// 저장소의 raw `AppBar(` 105곳이 수렴할 단일 지점. 규칙:
/// - 타이틀 **좌측 정렬** + [SoriTextTheme.h2] — 화면 헤드라인과 한 위계.
/// - 선택적 [eyebrow] 한 줄 (자간 넓은 소문자 라벨, 석간주).
/// - 배경 **투명** — `SoriScreenBackground` 의 한지가 비치고, 스크롤해도
///   틴트가 얹히지 않는다(`scrolledUnderElevation: 0`).
///
/// 마이그레이션은 래칫(`test/typography_guard_test.dart` "원시 AppBar")이
/// 강제하는 점진 방식 — 새 화면·리스타일 화면부터 이걸 쓴다.
class SoriAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SoriAppBar({
    super.key,
    required this.title,
    this.eyebrow,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  final String title;

  /// 타이틀 위 소형 라벨. 호출부에서 대문자화는 하지 않는다 —
  /// [SoriTextTheme.eyebrow] 스타일만 적용하고 원문 그대로 렌더.
  final String? eyebrow;

  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: eyebrow == null ? null : Spacing.xs,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: eyebrow == null
          ? Text(title, style: tt.h2)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  eyebrow!,
                  style: tt.eyebrow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: tt.h2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
      actions: actions,
    );
  }
}
