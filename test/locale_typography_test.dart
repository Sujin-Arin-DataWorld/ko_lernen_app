import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/palette_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/app_bar.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

import 'support/real_fonts.dart';

void main() {
  setUpAll(loadSoriRealFonts);

  test('locale font roles use the selected actual faces', () {
    final english = SoriLocaleFonts.forLocale(const Locale('en', 'GB'));
    expect(english.heading, 'Chubbo');
    expect(english.headingWeight, FontWeight.w700);
    expect(english.body, 'Supreme');
    expect(english.bodyWeight(FontWeight.w400), FontWeight.w400);
    expect(english.bodyWeight(FontWeight.w600), FontWeight.w700);

    final german = SoriLocaleFonts.forLocale(const Locale('de', 'AT'));
    expect(german.heading, 'Belgrano');
    expect(german.headingWeight, FontWeight.w400);
    expect(german.body, 'EncodeSansCondensed');
    expect(german.bodyWeight(FontWeight.w600), FontWeight.w600);
    expect(SoriLocaleFonts.forLocale(const Locale('fr')), german);
    expect(SoriLocaleFonts.fallback, [SoriFonts.korean]);
  });

  for (final variant in PaletteVariant.values) {
    for (final build in [AppTheme.lightFor, AppTheme.darkFor]) {
      test('$variant locale typography preserves material and type scale', () {
        final de = build(variant, locale: const Locale('de'));
        final en = build(variant, locale: const Locale('en'));
        expect(en.colorScheme, de.colorScheme);
        expect(en.scaffoldBackgroundColor, de.scaffoldBackgroundColor);
        expect(en.pageTransitionsTheme, de.pageTransitionsTheme);
        expect(en.visualDensity, de.visualDensity);
        final deStyles = _roles(de.textTheme);
        final enStyles = _roles(en.textTheme);
        for (var i = 0; i < enStyles.length; i++) {
          final deStyle = deStyles[i]!;
          final enStyle = enStyles[i]!;
          expect(enStyle.fontSize, deStyle.fontSize);
          expect(enStyle.height, deStyle.height);
          expect(enStyle.letterSpacing, deStyle.letterSpacing);
          expect(enStyle.color, deStyle.color);
          expect(enStyle.fontFamilyFallback, contains(SoriFonts.korean));
          expect(deStyle.fontFamilyFallback, contains(SoriFonts.korean));
          final heading = i < 9;
          expect(enStyle.fontFamily, heading ? 'Chubbo' : 'Supreme');
          expect(
            deStyle.fontFamily,
            heading ? 'Belgrano' : 'EncodeSansCondensed',
          );
          if (heading) {
            expect(enStyle.fontWeight, FontWeight.w700);
            expect(deStyle.fontWeight, FontWeight.w400);
          }
        }
        expect(en.textTheme.bodyMedium?.fontWeight, FontWeight.w400);
        expect(de.textTheme.bodyMedium?.fontWeight, FontWeight.w400);
        expect(en.appBarTheme.titleTextStyle?.fontFamily, 'Chubbo');
        expect(de.appBarTheme.titleTextStyle?.fontFamily, 'Belgrano');
      });
    }
  }

  for (final (locale, title) in [
    (const Locale('de'), 'Deine koreanische Lernreise geht weiter'),
    (const Locale('en'), 'Continue your Korean learning journey'),
  ]) {
    testWidgets('$locale app bar measures its actual locale fonts', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
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
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              appBar: SoriAppBar(
                title: title,
                eyebrow: 'Hangul Sori',
                textScale: 2,
                viewportWidth: 320,
                locale: locale,
              ),
              body: const Text('한국어'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.text(title));
      expect(text.style?.fontFamily, SoriLocaleFonts.forLocale(locale).heading);
      expect(
        text.style?.fontWeight,
        SoriLocaleFonts.forLocale(locale).headingWeight,
      );
      final titleRect = tester.getRect(find.text(title));
      final appBarRect = tester.getRect(find.byType(AppBar));
      expect(titleRect.bottom, lessThanOrEqualTo(appBarRect.bottom));
      expect(titleRect.right, lessThanOrEqualTo(320));
    });
  }

  testWidgets(
    'locale changes refresh token roles while retaining Korean and scale',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final locale = ValueNotifier(const Locale('de'));
      addTearDown(locale.dispose);
      late SoriTextTheme tokens;
      late TextScaler scaler;

      await tester.pumpWidget(
        ValueListenableBuilder(
          valueListenable: locale,
          builder: (_, value, __) => MaterialApp(
            locale: value,
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.localizationsDelegates,
            theme: AppTheme.lightFor(PaletteVariant.dancheong, locale: value),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Builder(
                builder: (context) {
                  tokens = SoriTextTheme.of(context);
                  scaler = MediaQuery.textScalerOf(context);
                  return Scaffold(
                    body: SingleChildScrollView(
                      child: Column(
                        children: [
                          Text(
                            value.languageCode == 'de'
                                ? 'Dein Weg'
                                : 'Your path',
                            style: tokens.hero,
                          ),
                          Text('Learn Korean · 한국어', style: tokens.body),
                          Text('안녕하세요', style: tokens.koDisplay),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tokens.hero.fontFamily, 'Belgrano');
      expect(tokens.body.fontFamily, 'EncodeSansCondensed');
      expect(tokens.koDisplay.fontFamily, SoriFonts.learningKorean);
      expect(tokens.cultureTitle.fontFamily, SoriFonts.culture);
      expect(scaler.scale(16), 32);
      expect(tester.takeException(), isNull);

      locale.value = const Locale('en');
      await tester.pumpAndSettle();
      expect(find.text('Your path'), findsOneWidget);
      expect(tokens.hero.fontFamily, 'Chubbo');
      expect(tokens.body.fontFamily, 'Supreme');
      expect(tokens.body.fontWeight, FontWeight.w400);
      expect(tokens.koDisplay.fontFamily, SoriFonts.learningKorean);
      expect(tokens.cultureTitle.fontFamily, SoriFonts.culture);
      expect(scaler.scale(16), 32);
      expect(tester.takeException(), isNull);
    },
  );
}

List<TextStyle?> _roles(TextTheme theme) => [
  theme.displayLarge,
  theme.displayMedium,
  theme.displaySmall,
  theme.headlineLarge,
  theme.headlineMedium,
  theme.headlineSmall,
  theme.titleLarge,
  theme.titleMedium,
  theme.titleSmall,
  theme.bodyLarge,
  theme.bodyMedium,
  theme.bodySmall,
  theme.labelLarge,
  theme.labelMedium,
  theme.labelSmall,
];
