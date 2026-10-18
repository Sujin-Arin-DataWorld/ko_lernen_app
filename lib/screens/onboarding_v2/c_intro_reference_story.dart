import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/pressable.dart';
import 'c_intro_art.dart';
import 'c_onboarding.dart';

/// Native text over complete generated scenes. Coordinates follow Figma 77:2.
class IntroReferenceStoryHero extends StatelessWidget {
  const IntroReferenceStoryHero({
    super.key,
    required this.index,
    required this.title,
    required this.labels,
    required this.previewLabel,
    required this.onPreview,
  });
  final int index;
  final String title;
  final List<String> labels;
  final String previewLabel;
  final VoidCallback onPreview;
  static const contentTop = [667.0, 706.0, 657.0, 677.0, 660.0];
  static const artTop = [41.0, 0.0, 9.0, 21.0, 43.0];
  static const titleTop = [138.0, 140.0, 144.0, 133.0, 138.0];
  static const titleSize = [39.0, 43.0, 37.0, 40.0, 34.0];
  static const titleLine = [40.5, 47.0, 40.5, 41.0, 35.5];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final s = bounds.maxWidth / 402;
      Widget at(double x, double y, double w, double h, Widget child) =>
          Positioned(
            left: x * s,
            top: y * s,
            width: w * s,
            height: h * s,
            child: child,
          );
      return SizedBox(
        height: index == 2
            ? math.max(contentTop[index] * s, 607 * s + 48 + 2)
            : contentTop[index] * s,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            at(
              0,
              artTop[index],
              402,
              index == 1 ? 600 : 603,
              Semantics(
                button: true,
                label: previewLabel,
                onTap: onPreview,
                child: SoriPressable(
                  key: ValueKey('c-onboarding-preview-${index + 2}'),
                  onTap: onPreview,
                  pressScale: .997,
                  surfaceDepth: 0,
                  child: IntroStoryArtwork(index: index),
                ),
              ),
            ),
            at(
              20,
              titleTop[index],
              352,
              110,
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: IntroTypography.storyTitle(
                    titleSize[index],
                    titleLine[index],
                    s,
                    index,
                  ),
                ),
              ),
            ),
            if (index == 3)
              at(
                14,
                545,
                374,
                125,
                const IgnorePointer(child: CIntroArt('book-tools')),
              ),
            if (index == 4)
              at(
                3.122533918,
                527,
                397.091950497,
                132.363983499,
                const IgnorePointer(child: CIntroArt('hanok-tools')),
              ),
            if (labels.isNotEmpty)
              for (var i = 0; i < 3; i++)
                at(
                  (index == 0
                      ? [20.0, 143.0, 265.0]
                      : index == 3
                      ? [28.0, 145.0, 262.0]
                      : [25.0, 144.0, 263.0])[i],
                  index == 0
                      ? 607
                      : index == 3
                      ? 631
                      : 620,
                  index == 3 ? 112 : 116,
                  26,
                  IgnorePointer(
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: IntroTypography.storyToolLabel(s),
                    ),
                  ),
                ),
            if (index == 1)
              at(
                0,
                566,
                402,
                137,
                const COnboardingSoundScene(reference: true),
              ),
            if (index == 2)
              Positioned(
                left: 274 * s,
                top: 607 * s,
                width: 112 * s,
                height: 48,
                child: TextButton(
                  key: const ValueKey('c-onboarding-games-preview-button'),
                  onPressed: onPreview,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(112, 48),
                    backgroundColor: IntroPalette.paper,
                    foregroundColor: IntroPalette.ink,
                    side: const BorderSide(color: IntroPalette.brass),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        IntroGeometry.preview,
                      ),
                    ),
                  ),
                  child: CIntroText(
                    AppL10n.of(context).guideAvailabilityPreview,
                    size: 16,
                    bold: true,
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

/// This is shared with the flowing large-text layout, so educational text stays
/// native and readable after its text-free illustration is substituted.
class IntroStoryArtwork extends StatelessWidget {
  const IntroStoryArtwork({super.key, required this.index});
  final int index;
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 402,
        height: index == 1 ? 600 : 603,
        child: Stack(
          children: [
            Positioned.fill(child: CIntroArt(COnboardingStory.scenes[index])),
            if (index == 1) ...[
              for (final p in const [
                ('ㄱ', 32.0, 377.0, 69.0, 77.0, 54.0),
                ('ㅏ', 125.0, 375.0, 65.0, 77.0, 54.0),
                ('가', 246.0, 337.0, 124.0, 130.0, 98.0),
              ])
                Positioned(
                  left: p.$2,
                  top: p.$3,
                  width: p.$4,
                  height: p.$5,
                  child: Center(
                    child: Text(
                      p.$1,
                      textScaler: TextScaler.noScaling,
                      style: IntroTypography.soundGlyph(p.$6),
                    ),
                  ),
                ),
              for (final p in const [('+', 103.0, 25.0), ('=', 206.0, 29.0)])
                Positioned(
                  left: p.$2,
                  top: 399,
                  width: p.$3,
                  height: 44,
                  child: Text(
                    p.$1,
                    textAlign: TextAlign.center,
                    textScaler: TextScaler.noScaling,
                    style: IntroTypography.soundOperator,
                  ),
                ),
              Positioned(
                left: 104,
                top: 511,
                width: 196,
                height: 52,
                child: Text.rich(
                  const TextSpan(
                    children: [
                      TextSpan(text: '가', style: IntroTypography.koreanSample),
                      TextSpan(
                        text: ' · ga',
                        style: IntroTypography.romanizedSample,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  textScaler: TextScaler.noScaling,
                  style: IntroTypography.soundReading,
                ),
              ),
            ],
            if (index == 3) ...[
              Positioned(
                left: 77,
                top: 265,
                width: 138,
                height: 121,
                child: Transform.rotate(
                  angle: -8.5 * math.pi / 180,
                  alignment: Alignment.topLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ink(
                        t.grammarBookExample,
                        12.5,
                        20,
                        bold: true,
                        align: TextAlign.left,
                      ),
                      const SizedBox(height: 3),
                      _ink('안녕하세요', 26, 38, korean: true),
                      const SizedBox(height: 3),
                      _ink('annyeonghaseyo', 11.5, 19),
                      const SizedBox(height: 3),
                      _ink(t.introGreetingTranslation, 17, 24, bold: true),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 84,
                top: 455,
                width: 144,
                height: 36,
                child: Transform.rotate(
                  angle: -5 * math.pi / 180,
                  alignment: Alignment.topLeft,
                  child: _ink('안녕하세요', 25, 35, korean: true),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _ink(
    String value,
    double size,
    double line, {
    bool bold = false,
    bool korean = false,
    TextAlign align = TextAlign.center,
  }) => Text(
    value,
    textScaler: TextScaler.noScaling,
    textAlign: align,
    style: IntroTypography.bookInk(size, line, korean, bold),
  );
}

class IntroReferenceStoryBody extends StatelessWidget {
  const IntroReferenceStoryBody({
    super.key,
    required this.index,
    required this.summary,
    required this.body,
  });
  final int index;
  final String summary, body;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final t = AppL10n.of(context), s = bounds.maxWidth / 402;
      final summarySize = const [23.0, 23.2, 25.3, 24.0, 21.5][index];
      final summaryLine = const [30.0, 31.0, 34.0, 31.0, 31.0][index];
      final bodySize = const [16.4, 19.5, 17.6, 19.5, 18.7][index];
      final bodyLine = const [23.0, 26.0, 26.0, 25.0, 25.0][index];
      Widget text(
        String value,
        double size,
        double line, {
        bool bold = false,
        Color color = IntroPalette.blue,
        Key? key,
      }) => Text(
        value,
        key: key,
        textAlign: index == 2 ? TextAlign.left : TextAlign.center,
        style: IntroTypography.storyBody(size, line, s, bold, color),
      );
      return Padding(
        padding: EdgeInsets.fromLTRB(
          (index == 2 ? 30 : 18) * s,
          0,
          (index == 2 ? 16 : 18) * s,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: text(
                summary,
                summarySize,
                summaryLine,
                bold: true,
                color: IntroPalette.ink,
                key: const ValueKey('onboarding-v2-story-title'),
              ),
            ),
            if (index == 0)
              text(
                t.introTwelveTools,
                20.5,
                30,
                bold: true,
                color: IntroPalette.ink,
              ),
            SizedBox(
              height:
                  (index == 0
                      ? 4
                      : index == 1
                      ? 2
                      : index == 2
                      ? 9
                      : 0) *
                  s,
            ),
            text(body, bodySize, bodyLine),
            if (index == 0) ...[
              SizedBox(height: 4 * s),
              text(t.introNextSample, 14.5, 20, color: IntroPalette.ink),
            ],
          ],
        ),
      );
    },
  );
}
