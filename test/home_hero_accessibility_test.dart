import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/home_hero.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';

void main() {
  testWidgets('home hero keeps the complete greeting at 320dp and 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const greeting =
        'Guten Morgen, heute üben wir gemeinsam besonders aufmerksam Koreanisch';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: SoriCharacterHero(
                greeting: greeting,
                bubble: '천천히, 또렷하게 배워요.',
                phase: SoriDayPhase.morning,
                kind: MascotKind.magpie,
                forceStatic: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final greetingText = tester.widget<Text>(find.text(greeting));
    final paragraph = tester.renderObject<RenderParagraph>(find.text(greeting));
    expect(greetingText.maxLines, isNull);
    expect(greetingText.overflow, isNull);
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });
}
