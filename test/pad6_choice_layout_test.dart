import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/widgets/sori/cloze_prompt.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';
import 'package:ko_lernen_app/widgets/sori/responsive.dart';

import 'support/real_fonts.dart';

void main() {
  setUpAll(loadSoriRealFonts);

  const choices = ['하나', '둘', '셋', '넷'];

  Future<void> pumpChoices(
    WidgetTester tester, {
    required double width,
    TextScaler scaler = TextScaler.noScaling,
    List<String> options = choices,
  }) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = Size(width, 360);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(size: Size(width, 360), textScaler: scaler),
            child: SizedBox(
              width: width,
              height: 360,
              child: ClozeOptionsList(
                options: options,
                acceptedAnswers: {options.first},
                picked: null,
                revealed: false,
                onPick: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Pad-width short answers form a bounded two by two board', (
    tester,
  ) async {
    await pumpChoices(tester, width: 520);
    final tiles = find.byType(QuizChoice);
    expect(tiles, findsNWidgets(4));
    final first = tester.getRect(tiles.at(0));
    final second = tester.getRect(tiles.at(1));
    final third = tester.getRect(tiles.at(2));
    expect(first.top, closeTo(second.top, 1));
    expect(first.right, lessThan(second.left));
    expect(first.bottom, lessThan(third.top));
    expect(first.height, inInclusiveRange(88, 110));
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text and phone width retain one readable column', (
    tester,
  ) async {
    for (final scenario in [
      (width: 360.0, scaler: TextScaler.noScaling),
      (width: 520.0, scaler: const TextScaler.linear(2)),
    ]) {
      await pumpChoices(tester, width: scenario.width, scaler: scenario.scaler);
      final tiles = find.byType(QuizChoice);
      expect(
        tester.getRect(tiles.at(0)).bottom,
        lessThan(tester.getRect(tiles.at(1)).top),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('browsing cards use two columns only with enough content width', (
    tester,
  ) async {
    Future<List<Rect>> layout(double width, TextScaler scaler) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(size: Size(width, 400), textScaler: scaler),
              child: SizedBox(
                width: width,
                child: SoriAdaptiveCardWrap(
                  children: [
                    for (var index = 0; index < 2; index++)
                      SizedBox(key: ValueKey('card-$index'), height: 120),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      return [
        tester.getRect(find.byKey(const ValueKey('card-0'))),
        tester.getRect(find.byKey(const ValueKey('card-1'))),
      ];
    }

    final portrait = await layout(592, TextScaler.noScaling);
    expect(portrait[0].bottom, lessThan(portrait[1].top));
    final landscape = await layout(760, TextScaler.noScaling);
    expect(landscape[0].right, lessThan(landscape[1].left));
    final largeText = await layout(760, const TextScaler.linear(2));
    expect(largeText[0].bottom, lessThan(largeText[1].top));
    expect(tester.takeException(), isNull);
  });
}
