import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// **SoriAppBar** — 공용 앱바 (2026-08-13 UI 개편 Phase 1).
///
/// 저장소의 raw `AppBar(` 105곳이 수렴할 단일 지점. 규칙:
/// - 타이틀 **좌측 정렬** + [SoriTextTheme.h2] — 화면 헤드라인과 한 위계.
/// - 선택적 [eyebrow] (자간 넓은 소문자 라벨, 석간주). 좁은 폭과 큰
///   글자에서는 내용을 자르지 않고 여러 줄로 확장한다.
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
    this.bottom,
    required this.textScale,
    required this.viewportWidth,
    this.adaptTitleAtNormalScale = false,
  });

  final String title;

  /// 타이틀 위 소형 라벨. 호출부에서 대문자화는 하지 않는다 —
  /// [SoriTextTheme.eyebrow] 스타일만 적용하고 원문 그대로 렌더.
  final String? eyebrow;

  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final double textScale;
  final double viewportWidth;

  /// Enables measured multi-line chrome for user-authored or otherwise
  /// unbounded titles even at the default system text scale. Eyebrow chrome and
  /// narrow phones are measured automatically.
  final bool adaptTitleAtNormalScale;

  static const _titleStyle = TextStyle(
    fontFamily: SoriFonts.sans,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    height: 1.3,
  );
  static const _eyebrowStyle = TextStyle(
    fontFamily: SoriFonts.sans,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    height: 1.2,
  );

  /// Large display text follows mobile nonlinear scaling: body copy and
  /// controls still receive the full ambient scale, while page chrome grows
  /// only to 130%. This keeps the complete title visible without consuming the
  /// entire 320x640 viewport at a 200% accessibility setting.
  double get _chromeTextScale => math.min(math.max(1, textScale), 1.3);

  bool get _stackTitle => textScale >= 1.6;

  double get _titleAvailableWidth {
    if (_stackTitle) {
      return math.max(96, viewportWidth - Spacing.lg * 2);
    }
    final leadingWidth = leading != null || automaticallyImplyLeading
        ? kToolbarHeight
        : 0.0;
    final actionsWidth = (actions?.length ?? 0) * kMinInteractiveDimension;
    final horizontalSpacing = eyebrow == null ? Spacing.lg * 2 : Spacing.xs * 2;
    return math.max(
      96,
      viewportWidth - leadingWidth - actionsWidth - horizontalSpacing,
    );
  }

  ({double height, int lines}) _textMetrics(String value, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.linear(_chromeTextScale),
    )..layout(maxWidth: _titleAvailableWidth);
    final result = (
      height: painter.height,
      lines: painter.computeLineMetrics().length,
    );
    painter.dispose();
    return result;
  }

  int _textLines(String value, TextStyle style) =>
      _textMetrics(value, style).lines;

  /// Keep ordinary bounded 100% chrome pixel-stable. Eyebrow chrome, narrow
  /// phones, and explicitly unbounded titles expand instead of clipping or
  /// hiding measured multi-line copy.
  bool get _usesAdaptiveChrome =>
      textScale > 1 ||
      ((adaptTitleAtNormalScale ||
              eyebrow != null ||
              viewportWidth < SoriBreakpoints.narrowPhone) &&
          (_textLines(title, _titleStyle) > 1 ||
              (eyebrow != null && _textLines(eyebrow!, _eyebrowStyle) > 1)));

  double get _titleBlockHeight {
    final titleHeight = _textMetrics(title, _titleStyle).height;
    final eyebrowHeight = eyebrow == null
        ? 0.0
        : _textMetrics(eyebrow!, _eyebrowStyle).height + Spacing.xs;
    final verticalPadding = _stackTitle ? Spacing.md : Spacing.sm;
    return titleHeight + eyebrowHeight + verticalPadding;
  }

  double get _toolbarHeight => _stackTitle
      ? kToolbarHeight
      : math.max(kToolbarHeight, _titleBlockHeight);

  @override
  Size get preferredSize => !_usesAdaptiveChrome
      ? Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0))
      : Size.fromHeight(
          _toolbarHeight +
              (_stackTitle ? _titleBlockHeight : 0) +
              (bottom?.preferredSize.height ?? 0),
        );

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    if (!_usesAdaptiveChrome) {
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
                  Text(eyebrow!, style: tt.eyebrow),
                  Text(title, style: tt.h2),
                ],
              ),
        actions: actions,
        bottom: bottom,
      );
    }
    Widget completeText(String value, TextStyle style) => Text(
      value,
      style: style,
      maxLines: _textLines(value, style),
      overflow: TextOverflow.clip,
    );
    final titleBlock = eyebrow == null
        ? completeText(title, tt.h2)
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              completeText(eyebrow!, tt.eyebrow),
              completeText(title, tt.h2),
            ],
          );
    final scaledTitleBlock = MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(_chromeTextScale)),
      child: titleBlock,
    );
    final stackedBottom = !_stackTitle
        ? bottom
        : PreferredSize(
            preferredSize: Size.fromHeight(
              _titleBlockHeight + (bottom?.preferredSize.height ?? 0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: _titleBlockHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.lg,
                      vertical: Spacing.sm,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: scaledTitleBlock,
                    ),
                  ),
                ),
                if (bottom != null) bottom!,
              ],
            ),
          );
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: _toolbarHeight,
      centerTitle: false,
      titleSpacing: eyebrow == null ? null : Spacing.xs,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: _stackTitle ? null : scaledTitleBlock,
      actions: actions,
      bottom: stackedBottom,
    );
  }
}
