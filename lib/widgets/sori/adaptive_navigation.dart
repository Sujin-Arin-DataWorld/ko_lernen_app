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
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<SoriAdaptiveNavigationItem> items;

  const SoriAdaptiveNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  }) : assert(items.length >= 2);

  static bool usesRailForWidth(double width) => width >= SoriBreakpoints.tablet;

  static bool usesExtendedRailForWidth(double width) =>
      width >= SoriBreakpoints.wideTablet;

  static double railWidthForWidth(double width) =>
      usesExtendedRailForWidth(width) ? 216 : 88;

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
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      extended: extended,
      minWidth: 88,
      minExtendedWidth: 216,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      destinations: [
        for (final item in items)
          NavigationRailDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: extended ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }
}
