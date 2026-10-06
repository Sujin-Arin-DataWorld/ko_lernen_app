import 'package:flutter/material.dart';
import 'tokens.dart';
import 'window_class.dart';
import 'c_gallery/c_materials.dart';

@immutable
class SoriAdaptiveNavigationItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// Optional approved artwork; legacy destinations keep their Material icons.
  /// Selection is conveyed by the navigation indicator and label, never tint.
  final String? artworkAsset;

  const SoriAdaptiveNavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.artworkAsset,
  });
}

/// Keeps primary navigation comfortable on phones and Android tablets.
///
/// Phones retain the familiar bottom bar. At tablet widths the rail prevents
/// large empty bottom space; it is labeled in portrait and expands in wide
/// landscape layouts. This is based on logical viewport width, not a device
/// manufacturer or model name.
class SoriAdaptiveNavigation extends StatelessWidget {
  static const double _compactRailWidth = 96;
  static const double _largeTextRailWidth = 144;
  static const double _expandedRailWidth = 216;
  static const double _largeTextExpandedRailWidth = 256;

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<SoriAdaptiveNavigationItem> items;
  final bool imageOnly;

  const SoriAdaptiveNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
    this.imageOnly = false,
  }) : assert(items.length >= 2);

  /// 하단 탭 대신 세로 레일을 쓰는지. [AppWindowClass.compact] 를 벗어나는
  /// 순간이 곧 레일 전환점이다 — [kWindowClassMediumMin] 이
  /// [SoriBreakpoints.navigationRail] 에서 파생되므로 값은 600dp 그대로다.
  static bool usesRailForWidth(double width) =>
      windowClassFor(width).isAtLeastMedium;

  /// 라벨만 있는 96dp 레일 대신 확장 레일을 쓰는지.
  ///
  /// 보통 글자 크기에서는 [SoriBreakpoints.wideTablet](1024dp)부터 확장한다.
  /// 큰 글자에서는 라벨을 축소하지 않도록 600dp 이상에서도 확장한다.
  static bool usesExtendedRailForWidth(double width, {double textScale = 1}) =>
      width >= SoriBreakpoints.wideTablet ||
      (usesRailForWidth(width) && textScale >= 1.75);

  static double railWidthForWidth(
    double width, {
    double textScale = 1,
    bool imageOnly = false,
  }) {
    if (imageOnly) {
      return _compactRailWidth;
    }
    if (usesExtendedRailForWidth(width, textScale: textScale)) {
      return textScale >= 1.75
          ? _largeTextExpandedRailWidth
          : _expandedRailWidth;
    }
    return textScale >= 1.3 ? _largeTextRailWidth : _compactRailWidth;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    if (!usesRailForWidth(width)) {
      return CPaperPanel(
        radius: 1,
        padding: EdgeInsets.zero,
        child: NavigationBar(
          height: 64,
          backgroundColor: CPalette.paper,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          indicatorColor: CPalette.jade,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: CPalette.brass, width: 1.3),
          ),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: [
            for (final item in items)
              NavigationDestination(
                icon: _destinationArt(context, item),
                selectedIcon: _destinationArt(context, item, selected: true),
                label: item.label,
              ),
          ],
        ),
      );
    }

    final extended =
        !imageOnly && usesExtendedRailForWidth(width, textScale: textScale);
    final railWidth = railWidthForWidth(
      width,
      textScale: textScale,
      imageOnly: imageOnly,
    );
    final railLabelStyle = SoriTextTheme.of(
      context,
    ).label.copyWith(letterSpacing: 0);
    return NavigationRail(
      backgroundColor: CPalette.paper,
      indicatorColor: CPalette.jade,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CPalette.brass),
      ),
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      extended: extended,
      minWidth: extended ? _compactRailWidth : railWidth,
      minExtendedWidth: railWidth,
      labelType: extended || imageOnly
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      destinations: [
        for (final item in items)
          NavigationRailDestination(
            icon: Tooltip(
              message: item.label,
              child: _destinationArt(context, item),
            ),
            selectedIcon: Tooltip(
              message: item.label,
              child: _destinationArt(context, item, selected: true),
            ),
            // 라벨은 **한 줄 고정**이다. 예전엔 `maxLines: 2` 였는데, 독일어
            // 합성어에는 줄바꿈 기회가 없어서 Flutter 가 글자 사이를 끊었다 —
            // 좁은 레일에서 `Lerngruppe` 가 "Lerngrupp / e" 로 떨어져 UI 가
            // 미완성처럼 보였다(2026-08-06 Jin 태블릿 실기기). 한 줄로 못을
            // 박고, 그래도 넘치면 `FittedBox` 가 **줄바꿈이나 말줄임 대신
            // 전체 단어를 축소**한다.
            label: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: extended
                  ? Text(
                      item.label,
                      style: railLabelStyle,
                      maxLines: 1,
                      softWrap: false,
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.label,
                        style: railLabelStyle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
            ),
          ),
      ],
    );
  }

  Widget _destinationArt(
    BuildContext context,
    SoriAdaptiveNavigationItem item, {
    bool selected = false,
  }) {
    final asset = item.artworkAsset;
    if (asset == null) {
      return Icon(selected ? item.selectedIcon : item.icon);
    }
    final size = ['Lernen', 'Learn', 'Hanok', 'Gye'].contains(item.label)
        ? 44.0
        : 40.0;
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
    );
  }
}
