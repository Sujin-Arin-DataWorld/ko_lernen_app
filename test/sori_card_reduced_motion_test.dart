import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/card.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

void main() {
  testWidgets('selectable card removes its transition for reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(_host(disableAnimations: false));
    expect(_cardAnimation(tester).duration, SoriMotion.fast);

    await tester.pumpWidget(_host(disableAnimations: true));
    expect(_cardAnimation(tester).duration, Duration.zero);
  });
}

Widget _host({required bool disableAnimations}) => MaterialApp(
  theme: AppTheme.light,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Scaffold(
      body: SoriCard(
        selectable: true,
        selected: true,
        onTap: () {},
        child: const Text('Auswahl'),
      ),
    ),
  ),
);

AnimatedContainer _cardAnimation(WidgetTester tester) => tester.widget(
  find.descendant(
    of: find.byType(SoriCard),
    matching: find.byType(AnimatedContainer),
  ),
);
