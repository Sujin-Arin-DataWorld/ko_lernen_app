import 'package:flutter/material.dart';

/// Approved Einleitung Figma 77:2 / Welcome 85:32 typography and material tokens.
/// Keep reference metrics separate from the flowing accessibility layout.
abstract final class IntroFonts {
  static const sans = 'Roboto';
  static const condensed = 'RobotoCondensed';
  static const serif = 'Lora';
  static const brand = 'NotoSerif';
  static const korean = 'NotoSansKR';
  static const koreanDisplay = 'MaruBuri';
}

abstract final class IntroLayout {
  /// Fixed artwork coordinates are approved at 100% text size only.
  /// Check both body and display sizes for nonlinear platform text scalers.
  static bool usesReferenceText(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return scaler.scale(16) <= 16 && scaler.scale(40) <= 40;
  }
}

abstract final class IntroGeometry {
  static const heroClearance = 150.0;
  static const headerPortraitHeight = 190.0;
  static const changeActionWidth = 105.0;

  /// Preview activities need a little less chrome below this available height
  /// when accessibility text is enlarged; reference artwork is unchanged.
  static const previewWorkingHeight = 720.0;
  static const card = 14.0;
  static const interest = 13.0;
  static const interestArt = 12.0;
  static const selectionInset = 9.0;
  static const levelField = 15.0;
  static const levelAction = 22.0;
  static const companionCard = 16.0;
  static const portrait = 15.0;
  static const portraitRail = 15.7;
  static const adaptivePortrait = 11.0;
  static const preview = 12.0;
  static const welcomeAction = 25.0;
  static const welcomeInnerRail = 24.0;
  static const handle = 3.0;
  static const levelSheet = 28.0;
  static const adaptiveSheet = 24.0;
  static const paper = 26.0;
  static const compactAction = 12.0;
  static const action = 16.0;
  static const compactBevel = 10.5;
}

/// Measured offsets inside the approved artwork composition, not a second
/// application spacing grid. Standard page gaps still use Spacing/SoriGaps.
abstract final class IntroSpacing {
  static const backBaselineInset = 1.0;
  static const bookLine = 3.0;
  static const portraitMat = 3.0;
  static const welcomeBrandGap = 6.0;
  static const heroInset = 20.0;
  static const heroCaptionInset = 18.0;
  static const cardInset = 10.0;
  static const inlineGap = 10.0;
  static const sectionGap = 14.0;
  static const actionGap = 18.0;
  static const detailGap = 9.0;
  static const captionGap = 5.0;
}

abstract final class IntroPalette {
  static const jade = Color(0xff054b43);
  static const ink = Color(0xff102722);
  static const paper = Color(0xfffff2dc);
  static const brass = Color(0xffd7ac61);
  static const mutedInk = Color(0xff425d54);
  static const emphasisInk = Color(0xff1d5146);
  static const calligraphyInk = Color(0xff071c21);
  static const white = Color(0xfffffaf0);
}

abstract final class IntroTypography {
  static const welcomeCream = Color(0xfffff2d5);

  static TextStyle medalPlaceholder(double size) => TextStyle(
    fontFamily: IntroFonts.sans,
    fontSize: size * .4,
    color: IntroPalette.ink,
  );

  static const secondaryInk = TextStyle(color: IntroPalette.mutedInk);

  static TextStyle gyeBody(double s) => TextStyle(
    fontFamily: IntroFonts.condensed,
    fontFamilyFallback: const [IntroFonts.korean],
    // Reviewed 07 artwork caption only; adaptive Gye copy uses the body token.
    fontSize: 12.5 * s,
    letterSpacing: 0,
    height: 20 / 12.5,
    color: const Color(0xff10252b),
  );

  static TextStyle companionWords(
    double size,
    double line,
    double scale,
    bool bold,
    Color color,
  ) => TextStyle(
    fontFamily: IntroFonts.condensed,
    fontFamilyFallback: const [IntroFonts.korean],
    fontSize: size * scale,
    letterSpacing: 0,
    height: line / size,
    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    color: color,
  );

  static TextStyle setupWords(double size, double s, bool bold, Color color) =>
      TextStyle(
        fontFamily: IntroFonts.sans,
        fontFamilyFallback: const [IntroFonts.korean],
        fontSize: size * s,
        height: 1.25,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: color,
      );

  static TextStyle interestLabel(double s) => TextStyle(
    fontFamily: IntroFonts.sans,
    fontSize: 17 * s,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: IntroPalette.ink,
  );

  static TextStyle levelWords(
    double size,
    double s,
    bool serif,
    bool bold,
    Color color,
  ) => TextStyle(
    fontFamily: serif ? IntroFonts.serif : IntroFonts.sans,
    fontSize: size * s,
    height: 1.25,
    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    color: color,
  );

  static TextStyle sheetClose(double s) => TextStyle(
    fontFamily: IntroFonts.sans,
    fontSize: 15 * s,
    letterSpacing: 0,
    height: 1.25,
    color: IntroPalette.mutedInk,
  );

  static TextStyle storyTitle(
    double size,
    double line,
    double scale,
    int index,
  ) => TextStyle(
    fontFamily: IntroFonts.sans,
    fontWeight: FontWeight.w700,
    fontSize: size * scale,
    height: line / size,
    letterSpacing: index == 1
        ? 1.3
        : index == 4
        ? .35
        : 0,
    color: IntroPalette.white,
  );

  static TextStyle storyToolLabel(double s) => TextStyle(
    fontFamily: IntroFonts.sans,
    fontSize: 17.5 * s,
    height: 24 / 17.5,
    fontWeight: FontWeight.w700,
    color: IntroPalette.white,
  );

  static TextStyle soundGlyph(double size) => TextStyle(
    fontFamily: IntroFonts.koreanDisplay,
    fontWeight: FontWeight.w600,
    fontSize: size,
    height: 1.05,
    color: IntroPalette.jade,
  );

  static const soundOperator = TextStyle(
    fontFamily: IntroFonts.sans,
    fontSize: 37,
    height: 44 / 37,
    fontWeight: FontWeight.w700,
    color: Color(0xffffe6a1),
  );

  static const koreanSample = TextStyle(
    fontFamily: IntroFonts.koreanDisplay,
    fontWeight: FontWeight.w400,
  );

  static const romanizedSample = TextStyle(fontFamily: IntroFonts.serif);

  static const soundReading = TextStyle(
    fontSize: 40,
    height: 52 / 40,
    color: IntroPalette.ink,
  );

  static TextStyle bookInk(double size, double line, bool korean, bool bold) =>
      TextStyle(
        fontFamily: korean ? IntroFonts.koreanDisplay : IntroFonts.sans,
        fontSize: size,
        height: line / size,
        fontWeight: korean
            ? FontWeight.w600
            : bold
            ? FontWeight.w700
            : FontWeight.w400,
        color: korean ? IntroPalette.calligraphyInk : IntroPalette.ink,
      );

  static TextStyle storyBody(
    double size,
    double line,
    double s,
    bool bold,
    Color color,
  ) => TextStyle(
    fontFamily: IntroFonts.sans,
    fontSize: size * s,
    letterSpacing: 0,
    height: line / size,
    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    color: color,
  );

  static TextStyle welcomeBrand(double scale) => TextStyle(
    fontFamily: IntroFonts.brand,
    fontWeight: FontWeight.w400,
    // Reviewed 85:32 brand lockup; not an interface/body-text size preset.
    fontSize: 12 * scale,
    height: 1.5,
    letterSpacing: 1.7 * scale,
    color: const Color(0xfff5d18a),
  );

  static TextStyle welcomeTitle(double scale) => TextStyle(
    fontFamily: IntroFonts.serif,
    fontWeight: FontWeight.w400,
    fontVariations: const [FontVariation('wght', 600)],
    fontSize: 28 * scale,
    letterSpacing: 0,
    height: 30.5 / 28,
    color: welcomeCream,
  );

  static TextStyle welcomeBody(double size) => TextStyle(
    fontFamily: IntroFonts.sans,
    fontWeight: FontWeight.w400,
    fontSize: size,
    letterSpacing: 0,
    height: 16 / 12.5,
    color: const Color(0xffdce5df),
  );

  static const welcomeError = TextStyle(
    fontFamily: IntroFonts.sans,
    fontSize: 16,
    color: welcomeCream,
  );

  static TextStyle welcomeAction(double scale) => TextStyle(
    fontFamily: IntroFonts.serif,
    fontWeight: FontWeight.w400,
    fontVariations: const [FontVariation('wght', 600)],
    fontSize: 20 * scale,
    letterSpacing: 0,
    height: 1.5,
    color: welcomeCream,
  );

  static TextStyle welcomeLater(double scale, bool adaptive) => TextStyle(
    fontFamily: IntroFonts.sans,
    fontWeight: FontWeight.w400,
    fontSize: (adaptive ? 16 : 12) * scale,
    letterSpacing: 0,
    height: 1.5,
    decoration: TextDecoration.underline,
  );

  static TextStyle backAction(int step) => TextStyle(
    fontFamily: step == 7 ? IntroFonts.condensed : IntroFonts.sans,
    fontSize: step == 7 ? 18 : 20,
    height: 1.25,
    letterSpacing: 0,
    color: step == 7 ? const Color(0xff101b1b) : IntroPalette.mutedInk,
  );

  static TextStyle body(double size, bool bold, Color color) => TextStyle(
    fontFamily: IntroFonts.sans,
    fontFamilyFallback: const [IntroFonts.korean],
    letterSpacing: 0,
    fontSize: size,
    height: 1.25,
    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    color: color,
  );

  static TextStyle primaryAction(double fontSize, bool gold) => TextStyle(
    fontFamily: IntroFonts.sans,
    letterSpacing: 0,
    fontFamilyFallback: const [IntroFonts.korean],
    fontSize: fontSize,
    height: gold ? 1.4 : 1.25,
    fontWeight: gold ? FontWeight.w700 : FontWeight.w400,
    color: gold ? IntroPalette.ink : IntroPalette.white,
  );

  static const brand = TextStyle(
    fontFamily: IntroFonts.brand,
    fontSize: 15,
    height: 22 / 15,
    letterSpacing: 2.8,
    color: IntroPalette.brass,
  );

  static const progress = TextStyle(
    fontFamily: IntroFonts.brand,
    fontSize: 21,
    height: 27 / 21,
    color: Color(0xffefe6b4),
  );

  static TextStyle companionTitle(double scale) => TextStyle(
    fontFamily: IntroFonts.sans,
    fontSize: 36 * scale,
    height: 37 / 36,
    fontWeight: FontWeight.w700,
    color: IntroPalette.white,
  );

  static TextStyle setupTitle(double scale) => TextStyle(
    fontFamily: IntroFonts.sans,
    fontSize: 31.5 * scale,
    height: 35.5 / 31.5,
    fontWeight: FontWeight.w700,
    color: IntroPalette.white,
  );
}
