import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/locale_service.dart';
import 'tokens.dart';

/// **SoriAppBar** — 공용 앱바 (2026-08-13 UI 개편 Phase 1).
///
/// 저장소의 raw `AppBar(` 105곳이 수렴할 단일 지점. 규칙:
/// - 타이틀 **좌측 정렬** + [SoriTextTheme.chromeTitle] — 내비게이션 크롬
///   전용 위계(2026-09-03, §A4). [SoriTextTheme.h2] 는 화면 헤드라인이 Maru
///   Buri 로 이동한 뒤 분리됐다.
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
    this.titleBelowToolbar = false,
    this.locale,
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

  /// Gives a long scene title the full width below navigation and actions.
  final bool titleBelowToolbar;

  /// Isolated hosts with a locale separate from the app's LocaleService may
  /// pass it here so PreferredSize measures the same fonts as their context.
  final Locale? locale;

  // PreferredSize has no BuildContext. Use main.dart's selected/system locale
  // resolution; build itself measures and paints the active context tokens.
  SoriTextTheme get _measurementTypography {
    final selected = locale ?? localeNotifier.value;
    final resolved = basicLocaleListResolution(
      selected == null
          ? WidgetsBinding.instance.platformDispatcher.locales
          : [selected],
      AppL10n.supportedLocales,
    );
    return SoriTextTheme.forSurfaces(
      SoriSurfaces.light,
      fonts: SoriLocaleFonts.forLocale(resolved),
    );
  }

  /// Large display text follows mobile nonlinear scaling: body copy and
  /// controls still receive the full ambient scale, while page chrome grows
  /// only to 130%. This keeps the complete title visible without consuming the
  /// entire 320x640 viewport at a 200% accessibility setting.
  double get _chromeTextScale => math.min(math.max(1, textScale), 1.3);

  bool get _stackTitle => titleBelowToolbar || textScale >= 1.6;

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
  bool _usesAdaptiveChrome(SoriTextTheme tt) =>
      titleBelowToolbar ||
      textScale > 1 ||
      ((adaptTitleAtNormalScale ||
              eyebrow != null ||
              viewportWidth < SoriBreakpoints.narrowPhone) &&
          (_textLines(title, tt.chromeTitle) > 1 ||
              (eyebrow != null && _textLines(eyebrow!, tt.eyebrow) > 1)));

  double _titleBlockHeight(SoriTextTheme tt) {
    final titleHeight = _textMetrics(title, tt.chromeTitle).height;
    final eyebrowHeight = eyebrow == null
        ? 0.0
        : _textMetrics(eyebrow!, tt.eyebrow).height + Spacing.xs;
    final verticalPadding = _stackTitle ? Spacing.md : Spacing.sm;
    return titleHeight + eyebrowHeight + verticalPadding;
  }

  double _toolbarHeight(SoriTextTheme tt) => _stackTitle
      ? kToolbarHeight
      : math.max(kToolbarHeight, _titleBlockHeight(tt));

  @override
  Size get preferredSize {
    final tt = _measurementTypography;
    return !_usesAdaptiveChrome(tt)
        ? Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0))
        : Size.fromHeight(
            _toolbarHeight(tt) +
                (_stackTitle ? _titleBlockHeight(tt) : 0) +
                (bottom?.preferredSize.height ?? 0),
          );
  }

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    if (!_usesAdaptiveChrome(tt)) {
      return AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: eyebrow == null ? null : Spacing.xs,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        title: eyebrow == null
            ? Text(title, style: tt.chromeTitle)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(eyebrow!, style: tt.eyebrow),
                  Text(title, style: tt.chromeTitle),
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
        ? completeText(title, tt.chromeTitle)
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              completeText(eyebrow!, tt.eyebrow),
              completeText(title, tt.chromeTitle),
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
              _titleBlockHeight(tt) + (bottom?.preferredSize.height ?? 0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: _titleBlockHeight(tt),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.lg,
                      vertical: Spacing.sm,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Semantics(
                        header: true,
                        namesRoute: switch (Theme.of(context).platform) {
                          TargetPlatform.iOS || TargetPlatform.macOS => false,
                          _ => true,
                        },
                        child: scaledTitleBlock,
                      ),
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
      toolbarHeight: _toolbarHeight(tt),
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
