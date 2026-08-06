import 'package:flutter/material.dart';

import 'tokens.dart';

@immutable
class SoriAdaptiveNavigationItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const SoriAdaptiveNavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
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
  static const double _expandedRailWidth = 216;

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<SoriAdaptiveNavigationItem> items;

  const SoriAdaptiveNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  }) : assert(items.length >= 2);

  static bool usesRailForWidth(double width) =>
      width >= SoriBreakpoints.navigationRail;

  static bool usesExtendedRailForWidth(double width) =>
      width >= SoriBreakpoints.wideTablet;

  static double railWidthForWidth(double width) =>
      usesExtendedRailForWidth(width) ? _expandedRailWidth : _compactRailWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (!usesRailForWidth(width)) {
      return NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: [
          for (final item in items)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
        ],
      );
    }

    final extended = usesExtendedRailForWidth(width);
    final railLabelStyle = SoriTextTheme.of(
      context,
    ).label.copyWith(letterSpacing: 0);
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      extended: extended,
      minWidth: _compactRailWidth,
      minExtendedWidth: _expandedRailWidth,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      destinations: [
        for (final item in items)
          NavigationRailDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            // 라벨은 **한 줄 고정**이다. 예전엔 `maxLines: 2` 였는데, 독일어
            // 합성어에는 줄바꿈 기회가 없어서 Flutter 가 글자 사이를 끊었다 —
            // 96dp 레일에서 `Lerngruppe` 가 "Lerngrupp / e" 로 떨어져 UI 가
            // 미완성처럼 보였다(2026-08-06 Jin 태블릿 실기기). 한 줄로 못을
            // 박고, 그래도 넘치면 `FittedBox` 가 **줄바꿈 대신 축소**한다.
            label: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  style: railLabelStyle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
