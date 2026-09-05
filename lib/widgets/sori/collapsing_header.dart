import 'package:flutter/material.dart';

import 'page_header.dart';
import 'tokens.dart';

/// **SoriCollapsingHeader** — 스크롤에 반응해 접히는 pinned 페이지 헤더
/// (2026-09-03, §E3, W-F·W-G 공용).
///
/// 펼친 상태는 [SoriPageHeader] (eyebrow → hero 헤드라인 → body, 우측
/// [trailing])를 그대로 보여준다. 스크롤이 진행되면 큰 헤드라인이 위로
/// 미끄러지며 fade-out 하고, `kToolbarHeight`(56dp) 크롬 바
/// ([collapsedTitle] + [trailing])가 fade-in 한다. `pinned: true` — 최소
/// 56dp는 스크롤이 얼마나 진행되든 항상 화면에 남는다.
///
/// **측정**: 펼친 높이는 위젯 트리를 실제로 한 번 그려보는 2-pass 방식이
/// 아니라, `SliverLayoutBuilder`로 얻은 가로폭과 [SoriTextTheme] 상수를
/// `TextPainter`로 재는 방식이다(`SoriAppBar`·`_cellAspectRatio`와 같은
/// 기존 관례) — 첫 프레임부터 정확하고, 별도 rebuild 지연이 없다.
/// [expandedBuilder]로 커스텀 콘텐츠를 주더라도 이 실측 높이(eyebrow/title/
/// body 기준)를 예산으로 쓴다 — 커스텀 콘텐츠는 그 안에 맞춰야 한다.
///
/// ```dart
/// CustomScrollView(
///   slivers: [
///     SoriCollapsingHeader(
///       eyebrow: t.soriStageNavLearn,
///       title: t.soriStageLearnTitle,
///       body: t.soriStageLearnBody,
///       collapsedTitle: t.soriStageNavLearn,
///       trailing: profileButton,
///     ),
///     ...
///   ],
/// )
/// ```
class SoriCollapsingHeader extends StatelessWidget {
  const SoriCollapsingHeader({
    super.key,
    this.eyebrow,
    required this.title,
    this.body,
    this.trailing,
    this.trailingSlots = 1,
    this.expandedBuilder,
    required this.collapsedTitle,
  });

  /// 헤드라인 위 소형 라벨. [SoriPageHeader]와 같은 계약 — 대문자화는
  /// 호출부 소관.
  final String? eyebrow;

  final String title;
  final String? body;

  /// 펼친 헤더와 접힌 56dp 크롬 바 양쪽에 그려지는 우측 액션 (예: 프로필
  /// 아이콘 버튼, 또는 여러 액션을 담은 `Row`). 두 상태 모두에서 접근
  /// 가능해야 한다.
  final Widget? trailing;

  /// [trailing]에 나란히 들어있는 48dp 액션 개수 (§W-G G5.2). 텍스트 폭
  /// 예산(`_measureExpandedHeight`)의 [_trailingReserve] 계산에만 쓰인다 —
  /// [trailing] 자체의 실제 레이아웃은 언제나 호출부가 준 위젯 그대로다.
  /// 기본 1은 기존 단일 트레일링 아이콘 호출부(카탈로그·Hanok)를 그대로
  /// 유지한다.
  final int trailingSlots;

  /// 펼친 상태 콘텐츠를 커스터마이즈한다. 기본은 [SoriPageHeader]
  /// (eyebrow/title/body/trailing).
  final WidgetBuilder? expandedBuilder;

  /// 접힌 56dp 크롬 바 제목. 반드시 짧은 nav 라벨(`soriStageNav*`), 320dp
  /// 1줄 — LAYOUT-3 가드(`sori_stage_root_header_lines_test.dart`)가 잰다.
  final String collapsedTitle;

  /// [trailing]이 있을 때 헤드라인 텍스트 폭에서 미리 빼 두는 여유 —
  /// [slots]개의 48dp 액션(WCAG 터치 타깃)이 [Spacing.xs] 갭으로 나란히
  /// 놓인 폭이다(§W-G G5.2 확정 공식). `slots == 1`이면 48 하나뿐이다.
  static double _trailingReserve(int slots) =>
      48 * slots + (slots - 1) * Spacing.xs;

  /// §LAYOUT-3(J11): exposes the exact text-width budget
  /// `_measureExpandedHeight` lays hero/eyebrow/body text out against —
  /// `crossAxisExtent` minus the trailing-slot reserve — so a layout-budget
  /// test (`sori_stage_root_header_lines_test.dart`) measures against the
  /// same number the real header does, instead of re-deriving it and
  /// silently drifting out of sync.
  @visibleForTesting
  static double expandedTextWidth({
    required double crossAxisExtent,
    required bool hasTrailing,
    int trailingSlots = 1,
  }) => (crossAxisExtent - (hasTrailing ? _trailingReserve(trailingSlots) : 0))
      .clamp(1.0, double.infinity);

  Widget _buildExpanded(BuildContext context) =>
      expandedBuilder?.call(context) ??
      SoriPageHeader(
        eyebrow: eyebrow,
        title: title,
        body: body,
        trailing: trailing,
      );

  /// [SoriPageHeader]의 실제 레이아웃(eyebrow + xs 갭 → hero title → sm 갭 +
  /// body, trailing 있으면 Row)을 `TextPainter`로 그대로 재현한다 — 렌더와
  /// 측정이 같은 상수를 참조하므로 조용히 갈라질 수 없다.
  double _measureExpandedHeight(BuildContext context, double crossAxisExtent) {
    final tt = SoriTextTheme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final locale = Localizations.localeOf(context);
    final hasTrailing = trailing != null;
    final textWidth = expandedTextWidth(
      crossAxisExtent: crossAxisExtent,
      hasTrailing: hasTrailing,
      trailingSlots: trailingSlots,
    );

    double lineHeight(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: scaler,
        locale: locale,
      )..layout(maxWidth: textWidth);
      final measured = painter.height;
      painter.dispose();
      return measured;
    }

    var height = 0.0;
    if (eyebrow case final eyebrowText?) {
      height += lineHeight(eyebrowText, tt.eyebrow) + Spacing.xs;
    }
    height += lineHeight(title, tt.hero);
    if (body case final bodyText?) {
      height += Spacing.sm + lineHeight(bodyText, tt.body);
    }
    if (hasTrailing && height < 48) {
      height = 48;
    }
    return height;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = SoriMotion.reduceMotion(context);
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final measured = _measureExpandedHeight(
          context,
          constraints.crossAxisExtent,
        );
        // 이 pinned 슬리버의 높이가 뷰포트 전체 높이에 닿거나 넘으면, 그
        // 프레임에서 뒤따르는 슬리버(레벨 필터·그리드 등)가 아예 레이아웃을
        // 못 받는다 — 320dp 폭 + 200% 글자 + 조금 긴 body 문자열 조합에서
        // 재현됨(2026-09-05, W10 T-H4 조사, listening_screen.dart). 뷰포트의
        // 60%로 상한을 둬 "헤더가 화면 전체를 삼키는" 극단만 막는다 —
        // 보통 폭/스케일에서는 실측값이 이 상한보다 한참 작아 시각 변화 0.
        final viewportCeiling = constraints.viewportMainAxisExtent.isFinite
            ? (constraints.viewportMainAxisExtent * 0.6).clamp(
                kToolbarHeight,
                double.infinity,
              )
            : double.infinity;
        final expandedHeight = measured < kToolbarHeight
            ? kToolbarHeight
            : measured > viewportCeiling
            ? viewportCeiling
            : measured;
        return SliverPersistentHeader(
          pinned: true,
          delegate: _SoriCollapsingHeaderDelegate(
            expandedHeight: expandedHeight,
            collapsedTitle: collapsedTitle,
            trailing: trailing,
            reduceMotion: reduceMotion,
            expandedBuilder: _buildExpanded,
          ),
        );
      },
    );
  }
}

class _SoriCollapsingHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SoriCollapsingHeaderDelegate({
    required this.expandedHeight,
    required this.collapsedTitle,
    required this.trailing,
    required this.reduceMotion,
    required this.expandedBuilder,
  });

  final double expandedHeight;
  final String collapsedTitle;
  final Widget? trailing;
  final bool reduceMotion;
  final WidgetBuilder expandedBuilder;

  @override
  double get minExtent => kToolbarHeight;

  @override
  double get maxExtent => expandedHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final tt = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);
    final range = (maxExtent - minExtent).clamp(1.0, double.infinity);
    final rawProgress = (shrinkOffset / range).clamp(0.0, 1.0);
    // reduce-motion: 중간 보간 없이 두 상태를 즉시 스냅한다(WCAG 2.3.3).
    final progress = reduceMotion
        ? (rawProgress < 0.5 ? 0.0 : 1.0)
        : rawProgress;
    final currentExtent = (maxExtent - shrinkOffset).clamp(
      minExtent,
      maxExtent,
    );
    final expandedOpacity = (1 - progress).clamp(0.0, 1.0);
    final collapsedOpacity = progress;

    return ClipRect(
      child: SizedBox(
        height: currentExtent,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 접힌 상태에서만 불투명해지는 배경 — pinned 크롬 바 아래로
            // 스크롤되는 그리드 콘텐츠를 가린다. 펼친 상태(progress 0)에선
            // 완전 투명이라 SoriScreenBackground의 한지 결이 그대로 비친다.
            Positioned.fill(
              child: ColoredBox(color: s.bg.withValues(alpha: progress)),
            ),
            // §E3 검수: trailing(프로필 버튼 등)이 두 레이어 모두에 있어
            // 둘 다 동시에 트리에 남아 있으면 `find.byTooltip`/`find.text` 가
            // 중복(2개)으로 잡힌다 — 실제 반응형/접근성 테스트에서 재현됨.
            // Visibility(maintainState: false)로 완전히 안 보이는 쪽은
            // 트리에서 통째로 뺀다. 중간 전환 프레임(0<progress<1)에서만
            // 둘 다 잠깐 공존한다(크로스페이드에 필요).
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Visibility(
                visible: expandedOpacity > 0,
                maintainState: false,
                child: Opacity(
                  key: const ValueKey('sori-collapsing-header-expanded'),
                  opacity: expandedOpacity,
                  child: IgnorePointer(
                    ignoring: expandedOpacity < 1,
                    child: Transform.translate(
                      offset: Offset(0, -progress * 12),
                      child: expandedBuilder(context),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: minExtent,
              child: Visibility(
                visible: collapsedOpacity > 0,
                maintainState: false,
                child: Opacity(
                  key: const ValueKey('sori-collapsing-header-collapsed'),
                  opacity: collapsedOpacity,
                  child: IgnorePointer(
                    ignoring: collapsedOpacity < 1,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            collapsedTitle,
                            style: tt.chromeTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (trailing != null) trailing!,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SoriCollapsingHeaderDelegate oldDelegate) {
    return expandedHeight != oldDelegate.expandedHeight ||
        collapsedTitle != oldDelegate.collapsedTitle ||
        trailing != oldDelegate.trailing ||
        reduceMotion != oldDelegate.reduceMotion;
  }
}
