import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/adaptive_navigation.dart';

const items = [
  SoriAdaptiveNavigationItem(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  SoriAdaptiveNavigationItem(
    label: 'Practice',
    icon: Icons.sports_esports_outlined,
    selectedIcon: Icons.sports_esports_rounded,
  ),
  SoriAdaptiveNavigationItem(
    label: 'Group',
    icon: Icons.groups_2_outlined,
    selectedIcon: Icons.groups_2_rounded,
  ),
  SoriAdaptiveNavigationItem(
    label: 'Profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person_rounded,
  ),
];

void main() {
  testWidgets('uses a bottom bar on phone-width layouts', (tester) async {
    await _pump(tester, width: 360);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('uses a labeled rail on portrait tablets', (tester) async {
    await _pump(tester, width: 800);

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
    expect(rail.labelType, NavigationRailLabelType.all);
    expect(find.text('Practice'), findsOneWidget);
  });

  testWidgets('expands the rail on wide tablet layouts', (tester) async {
    await _pump(tester, width: 1280);

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('forwards destination selection from the tablet rail', (
    tester,
  ) async {
    var selected = -1;
    await _pump(
      tester,
      width: 800,
      onDestinationSelected: (value) => selected = value,
    );

    await tester.tap(find.byIcon(Icons.sports_esports_outlined));
    await tester.pump();

    expect(selected, 1);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  ValueChanged<int>? onDestinationSelected,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SoriAdaptiveNavigation(
          selectedIndex: 0,
          onDestinationSelected: onDestinationSelected ?? (_) {},
          items: items,
        ),
      ),
    ),
  );
}
