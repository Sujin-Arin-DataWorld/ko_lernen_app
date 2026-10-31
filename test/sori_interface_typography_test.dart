import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/palette_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'support/real_fonts.dart';

void main() {
  setUpAll(loadSoriRealFonts);
  for (final (locale, action) in [
    (const Locale('de'), 'In einer anderen Situation üben'),
    (const Locale('en'), 'Try a different situation'),
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
          locale: locale,
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          theme: AppTheme.lightFor(PaletteVariant.dancheong, locale: locale),
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
      expect(menu.style?.fontFamily, SoriLocaleFonts.forLocale(locale).body);
      expect(menu.style?.fontFamilyFallback, contains(SoriFonts.korean));
      expect(lesson.style?.fontFamily, SoriFonts.sans);
      expect(menu.maxLines, isNull);
      expect(lesson.maxLines, isNull);
      expect(tester.getRect(find.text(action)).right, lessThanOrEqualTo(296));
    });
  }
}
