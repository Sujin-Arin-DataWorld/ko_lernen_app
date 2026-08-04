import 'package:flutter/material.dart';
import 'tokens.dart';

/// Browsing surfaces can use more of a tablet without turning learning text
/// into an overlong desktop line. The phone column remains unchanged through
/// 600dp, then grows smoothly to a 640dp tablet column at 720dp.
double soriAdaptiveContentMaxWidth(double availableWidth) {
  final progress =
      ((availableWidth - SoriBreakpoints.grid) /
              (SoriBreakpoints.tablet - SoriBreakpoints.grid))
          .clamp(0.0, 1.0)
          .toDouble();
  return SoriBreakpoints.content +
      (SoriBreakpoints.tabletContent - SoriBreakpoints.content) * progress;
}

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
  final double? maxWidth;
  final Widget Function(BuildContext context, EdgeInsets padding) builder;

  const SoriContentClamp({
    super.key,
    required this.builder,
    this.base = const EdgeInsets.symmetric(horizontal: Spacing.lg),
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final resolvedMaxWidth =
            maxWidth ?? soriAdaptiveContentMaxWidth(c.maxWidth);
        final pad = soriClampPadding(
          c.maxWidth,
          maxWidth: resolvedMaxWidth,
          base: base,
        );
        return builder(context, pad);
      },
    );
  }
}

/// 가용 [width]에서 [target] 폭 카드가 몇 개 들어가는지 산출해 grid 컬럼 수로
/// 반환한다. [min]~[max]로 클램프한다.
///
/// 폰(360~430)에서 기존 컬럼 수를 보존하려면 **호출부에서 [min]을 그 화면의
/// 현재 컬럼 수로 지정**한다 — 폰 산출값이 min 밑으로 내려가지 않으면 시각 변화 0.
/// 예) dojangcheop(현재 3컬럼): `soriGridColumns(width, target: 110, min: 3)`
///     → 360px서 3(유지), 768px서 더 많이.
///
/// [outerPadding]은 그리드 좌우 여백 합(기본 [Spacing.lg]×2), [spacing]은
/// 카드 사이 간격이다.
int soriGridColumns(
  double width, {
  double target = SoriBreakpoints.gridCardMin,
  int min = 2,
  int max = 6,
  double outerPadding = Spacing.lg * 2,
  double spacing = Spacing.lg,
}) {
  final usable = (width - outerPadding).clamp(0.0, double.infinity);
  // n*target + (n-1)*spacing ≤ usable  →  n ≤ (usable + spacing)/(target + spacing)
  final raw = ((usable + spacing) / (target + spacing)).floor();
  return raw.clamp(min, max);
}

/// 비스크롤 콘텐츠(Column/Expanded/Stack)를 [maxWidth]로 가운데 클램프한다.
/// 폰(부모 폭 ≤ maxWidth)에선 [child]가 폰 폭을 그대로 채워 **시각 변화 0**,
/// 넓은 화면에서만 단일 중앙 컬럼이 된다.
///
/// 내부 `SizedBox(width: double.infinity)`가 자식에게 항상 클램프된 폭을
/// 꽉 채우게 강제하므로, 감싸는 Column의 `crossAxisAlignment`(start/center/
/// stretch)와 **무관하게** 폰에서 정렬이 보존된다(= 회귀 0). 이 폭 강제가 없으면
/// 폭을 다 안 쓰는 Column을 Align이 중앙으로 밀어 폰에서 정렬이 바뀐다.
///
/// [SoriContentClamp]와의 차이: 저쪽은 *스크롤뷰 padding 슬롯*만 클램프해
/// viewport는 풀블리드(스크롤바·RefreshIndicator가 창 가장자리). 이쪽은
/// *위젯 자체*를 ConstrainedBox로 감싼다 → 스크롤 없는 Column 화면 전용.
/// 배경은 호출부의 Scaffold/Stack에 남겨야 풀블리드가 유지된다(이 위젯은
/// 콘텐츠만 감쌀 것).
///
/// ```dart
/// body: SafeArea(
///   child: SoriCenterClamp(
///     child: Padding(
///       padding: const EdgeInsets.all(Spacing.lg),
///       child: Column(children: [...]),
///     ),
///   ),
/// )
/// ```
class SoriCenterClamp extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  const SoriCenterClamp({
    super.key,
    required this.child,
    this.maxWidth = SoriBreakpoints.content,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
