import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'support/real_fonts.dart';

void main() {
  setUpAll(loadSoriRealFonts);
  for (final action in [
    'In einer anderen Situation üben',
    'Try a different situation',
  ]) {
    testWidgets('$action stays readable at 320dp and 200% text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 844),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    SoriButton.filled(
                      label: action,
                      fullWidth: true,
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),
                    SoriButton.outlined(
                      label: '오늘은 약속이 있어. 내일은 어때?',
                      textRole: SoriButtonTextRole.learning,
                      fullWidth: true,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final menu = tester.widget<Text>(find.text(action));
      final lesson = tester.widget<Text>(find.text('오늘은 약속이 있어. 내일은 어때?'));
      expect(menu.style?.fontFamily, SoriFonts.interface);
      expect(lesson.style?.fontFamily, SoriFonts.sans);
      expect(menu.maxLines, isNull);
      expect(lesson.maxLines, isNull);
      expect(tester.getRect(find.text(action)).right, lessThanOrEqualTo(296));
    });
  }
}
