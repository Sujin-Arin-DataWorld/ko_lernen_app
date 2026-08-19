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
    label: 'Explore',
    icon: Icons.explore_outlined,
    selectedIcon: Icons.explore_rounded,
  ),
  SoriAdaptiveNavigationItem(
    label: 'Lerngruppe',
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

  testWidgets('uses a labeled rail from medium tablet widths', (tester) async {
    await _pump(tester, width: 600);

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsOneWidget);
  });

  testWidgets('uses a labeled rail on portrait tablets', (tester) async {
    await _pump(tester, width: 800);

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
    expect(rail.labelType, NavigationRailLabelType.all);
    expect(rail.minWidth, 96);
    // 2026-08-19: 글자 배율은 SoriTypeScale(MaterialApp.builder) 하나로 모았다
    // — 이 테스트는 builder 를 안 쓰므로 label fontSize 는 이제 comfort 배율
    // 없이 토큰값 그대로 나온다.
    expect(tester.widget<Text>(find.text('Practice')).style!.fontSize, 13);
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

  testWidgets('keeps long rail labels stable at large text scale', (
    tester,
  ) async {
    await _pump(tester, width: 800, textScale: 1.3);

    expect(find.text('Lerngruppe'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // Jin 태블릿 실기기 2026-08-06: 96dp 레일에서 `Lerngruppe` 가 줄바꿈 기회가
  // 없는 합성어라 "Lerngrupp / e" 로 **글자 사이에서** 끊겼다. 예외는 안 나므로
  // 기존 "no exception" 회귀로는 못 잡는다 — 실제로 몇 줄로 그려졌는지 본다.
  for (final scale in <double>[1.0, 1.3]) {
    testWidgets('rail labels never wrap mid-word (×$scale)', (tester) async {
      await _pump(tester, width: 800, textScale: scale, constrainToRail: true);

      for (final item in items) {
        final finder = find.text(item.label);
        expect(finder, findsOneWidget, reason: item.label);
        // 한 줄이면 대략 fontSize×1.4 이내. 두 줄이면 그 2배가 된다.
        expect(
          tester.getSize(finder).height,
          lessThan(14.3 * scale * 1.9),
          reason: '${item.label} wrapped onto a second line',
        );
      }
    });

    testWidgets('rail labels stay inside the 96dp rail (×$scale)', (
      tester,
    ) async {
      await _pump(tester, width: 800, textScale: scale, constrainToRail: true);

      for (final item in items) {
        // `Text` 자체는 `softWrap: false` 라 자연 폭 그대로 레이아웃된다 —
        // 화면이 실제로 내주는 폭은 이를 축소하는 `FittedBox` 쪽이다.
        final box = find.ancestor(
          of: find.text(item.label),
          matching: find.byType(FittedBox),
        );
        expect(box, findsOneWidget, reason: item.label);
        expect(
          tester.getSize(box).width,
          lessThanOrEqualTo(96),
          reason: item.label,
        );
      }
    });
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  ValueChanged<int>? onDestinationSelected,
  double textScale = 1,
  bool constrainToRail = false,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final rail = SoriAdaptiveNavigation(
    selectedIndex: 0,
    onDestinationSelected: onDestinationSelected ?? (_) {},
    items: items,
  );
  // `NavigationRail` 은 목적지에 **minWidth 만** 건다(maxWidth 없음). 그래서
  // 폭이 자유로운 테스트 하니스에서는 라벨이 절대 안 좁아지고, 실기기에서
  // 라벨이 깨진 조건 자체가 재현되지 않는다. `AppShell` 은 레일을
  // `SizedBox(width: railWidthForWidth(...))` 안에 넣는다 — 그걸 그대로 흉내낸다.
  final navigation = Scaffold(
    body: constrainToRail
        ? Row(
            children: [
              SizedBox(
                width: SoriAdaptiveNavigation.railWidthForWidth(width),
                child: rail,
              ),
              const Expanded(child: SizedBox.shrink()),
            ],
          )
        : rail,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: textScale == 1
          ? navigation
          : MediaQuery.withClampedTextScaling(
              minScaleFactor: textScale,
              maxScaleFactor: textScale,
              child: navigation,
            ),
    ),
  );
}
