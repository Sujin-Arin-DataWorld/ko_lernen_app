import 'package:flutter/material.dart';
import 'tokens.dart';

/// 콘텐츠를 [maxWidth]로 클램프하는 듀오링고식 반응형 수평 padding.
///
/// 폰(availableWidth ≤ maxWidth)에선 [base]를 그대로 돌려줘 **시각 변화 0**,
/// 넓은 화면에선 잉여폭을 좌우로 절반씩 나눠 콘텐츠를 가운데 정렬한다.
/// 상하 padding은 [base] 값을 보존한다.
///
/// 예) `soriClampPadding(1200, maxWidth: 480)` → 좌우 각 +360, 가운데 480 컬럼.
EdgeInsets soriClampPadding(
  double availableWidth, {
  double maxWidth = SoriBreakpoints.content,
  EdgeInsets base = const EdgeInsets.symmetric(horizontal: Spacing.lg),
}) {
  final extra = ((availableWidth - maxWidth) / 2).clamp(0.0, double.infinity);
  return EdgeInsets.fromLTRB(
    base.left + extra,
    base.top,
    base.right + extra,
    base.bottom,
  );
}

/// 스크롤뷰를 감싸 **padding만** 반응형으로 클램프한다. viewport는 풀블리드로
/// 유지되므로 웹 스크롤바·RefreshIndicator가 창 가장자리에 고정된다
/// (Center+ConstrainedBox로 스크롤뷰 자체를 감싸는 방식의 단점 회피).
///
/// [builder]가 넘겨주는 padding을 스크롤뷰의 `padding:` 슬롯에 그대로 사용:
/// ```dart
/// SoriContentClamp(
///   base: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, Spacing.xl),
///   builder: (context, padding) => SingleChildScrollView(
///     padding: padding,
///     child: Column(...),
///   ),
/// )
/// ```
/// SafeArea는 포함하지 않는다(화면마다 위치가 달라 이중 inset 위험) — 호출부가
/// 기존 SafeArea를 유지한다. `CustomScrollView`(sliver) 화면은 이 위젯 대신
/// [soriClampPadding] 함수를 자체 `LayoutBuilder` 안에서 직접 호출한다.
class SoriContentClamp extends StatelessWidget {
  final EdgeInsets base;
  final double maxWidth;
  final Widget Function(BuildContext context, EdgeInsets padding) builder;

  const SoriContentClamp({
    super.key,
    required this.builder,
    this.base = const EdgeInsets.symmetric(horizontal: Spacing.lg),
    this.maxWidth = SoriBreakpoints.content,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final pad = soriClampPadding(c.maxWidth, maxWidth: maxWidth, base: base);
        return builder(context, pad);
      },
    );
  }
}
