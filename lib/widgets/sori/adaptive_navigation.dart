import 'package:flutter/material.dart';

import 'tokens.dart';
import 'window_class.dart';

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

  /// 하단 탭 대신 세로 레일을 쓰는지. [AppWindowClass.compact] 를 벗어나는
  /// 순간이 곧 레일 전환점이다 — [kWindowClassMediumMin] 이
  /// [SoriBreakpoints.navigationRail] 에서 파생되므로 값은 600dp 그대로다.
  static bool usesRailForWidth(double width) =>
      windowClassFor(width).isAtLeastMedium;

  /// 라벨만 있는 96dp 레일 대신 확장 레일을 쓰는지.
  ///
  /// ⚠️ 이건 [AppWindowClass.expanded](840dp)가 아니라
  /// [SoriBreakpoints.wideTablet](1024dp) 기준이다. 840dp 는 *배치 구조를 바꿔도
  /// 되는* 지점이고, 확장 레일은 216dp 를 내주고도 콘텐츠가 좁아지지 않는
  /// 1024dp 부터라야 이득이다. 두 값을 합치지 말 것.
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
            // 박고, 그래도 넘치면 `FittedBox` 가 **줄바꿈이나 말줄임 대신
            // 전체 단어를 축소**한다.
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
                ),
              ),
            ),
          ),
      ],
    );
  }
}
