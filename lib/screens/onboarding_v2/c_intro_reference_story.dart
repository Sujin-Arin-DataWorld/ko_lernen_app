import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../widgets/sori/button.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/intro_motion.dart';
import 'c_intro_art.dart';
import 'c_onboarding.dart';

/// Reviewed reference artwork with native actions and accessible reading text.
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
      if (bounds.hasBoundedHeight) {
        return _fittedHero(context, bounds);
      }
      Widget at(double x, double y, double w, double h, Widget child) =>
          Positioned(
            left: x * s,
            top: y * s,
            width: w * s,
            height: h * s,
            child: child,
          );
      if (Localizations.localeOf(context).languageCode == 'de' &&
          const [1, 3, 4].contains(index)) {
        final t = AppL10n.of(context);
        final artwork = switch (index) {
          1 => (name: 'sound-original-de-hero', height: 573.052349),
          3 => (name: 'scholar-original-de-hero', height: 545.532886),
          _ => (name: 'hanok-original-de-hero', height: 527.186577),
        };
        final reading = switch (index) {
          1 => 'ㄱ + ㅏ = 가. 가 · ga.',
          3 =>
            '${t.grammarBookExample}. 안녕하세요. annyeonghaseyo. '
                '${t.introGreetingTranslation}. ${labels.join('. ')}',
          _ => labels.join('. '),
        };
        return SizedBox(
          height: contentTop[index] * s,
          child: Stack(
            children: [
              at(
                0,
                122,
                402,
                artwork.height,
                Semantics(
                  container: true,
                  header: true,
                  button: true,
                  label: '$title. $reading',
                  hint: previewLabel,
                  onTap: onPreview,
                  child: IntroPressable(
                    key: ValueKey('c-onboarding-preview-${index + 2}'),
                    onTap: onPreview,
                    pressScale: .997,
                    surfaceDepth: 0,
                    child: CIntroArt(artwork.name),
                  ),
                ),
              ),
              if (index == 1)
                at(
                  0,
                  568.787,
                  402,
                  126.265349,
                  const COnboardingSoundScene(
                    reference: true,
                    originalArtwork: true,
                  ),
                ),
            ],
          ),
        );
      }
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
                child: IntroPressable(
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
                  style: IntroTypography.localized(
                    context,
                    IntroTypography.storyTitle(
                      titleSize[index],
                      titleLine[index],
                      s,
                      index,
                    ),
                    heading: true,
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
                      style: IntroTypography.localized(
                        context,
                        IntroTypography.storyToolLabel(s),
                      ),
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
                child: SoriTextAction(
                  key: const ValueKey('c-onboarding-games-preview-button'),
                  label: AppL10n.of(context).guideAvailabilityPreview,
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
                  textStyle: IntroTypography.localized(
                    context,
                    IntroTypography.body(16, true, IntroPalette.ink),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );

  Widget _fittedHero(BuildContext context, BoxConstraints bounds) {
    final t = AppL10n.of(context);
    final compact = bounds.maxHeight < 330;
    final titleStyle = IntroTypography.localized(
      context,
      IntroTypography.storyTitle(
        compact ? 27 : 32,
        compact ? 30 : 36,
        1,
        index,
      ),
      heading: true,
    );
    final titleHeight = (TextPainter(
      text: TextSpan(text: title, style: titleStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: bounds.maxWidth - 36)).height;
    // The scene gives up decorative space first. The heading and the live sound
    // and preview controls keep their natural text height and 48dp hit targets.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 6),
          child: SizedBox(
            height: titleHeight,
            child: Semantics(
              header: true,
              child: Text(title, style: titleStyle),
            ),
          ),
        ),
        Expanded(
          child: Semantics(
            button: true,
            label: index == 1
                ? '$title. ㄱ + ㅏ = 가. 가 · ga. $previewLabel'
                : '$title. $previewLabel',
            onTap: onPreview,
            child: IntroPressable(
              key: ValueKey('c-onboarding-preview-${index + 2}'),
              onTap: onPreview,
              surfaceDepth: 0,
              pressScale: .997,
              child: _croppedScene(context),
            ),
          ),
        ),
        if (labels.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Row(
              children: [
                for (final label in labels)
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: IntroTypography.localized(
                        context,
                        IntroTypography.body(16, true, IntroPalette.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (index == 1)
          const SizedBox(height: 58, child: COnboardingSoundScene()),
        if (index == 2)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: IntroAction(
              key: const ValueKey('c-onboarding-games-preview-button'),
              label: t.guideAvailabilityPreview,
              onTap: onPreview,
              gold: false,
            ),
          ),
      ],
    );
  }

  Widget _croppedScene(BuildContext context) {
    // The original sound tiles include the exact Korean lettering. Crop away
    // only the German heading and painted listen control; the live UI owns them.
    final originalSound = index == 1;
    final canvasHeight = originalSound ? 573.052349 : 603.0;
    final top = originalSound ? 120.0 : 150.0;
    final bottom = originalSound ? 452.0 : 603.0;
    return FittedBox(
      fit: BoxFit.contain,
      child: ClipRect(
        child: SizedBox(
          width: 402,
          height: bottom - top,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: -top,
                width: 402,
                height: canvasHeight,
                child: originalSound
                    ? const CIntroArt('sound-original-de-hero')
                    : IntroStoryArtwork(index: index),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
                        context,
                        t.grammarBookExample,
                        12.5,
                        20,
                        bold: true,
                        align: TextAlign.left,
                      ),
                      const SizedBox(height: IntroSpacing.bookLine),
                      _ink(context, '안녕하세요', 26, 38, korean: true),
                      const SizedBox(height: IntroSpacing.bookLine),
                      _ink(context, 'annyeonghaseyo', 11.5, 19),
                      const SizedBox(height: IntroSpacing.bookLine),
                      _ink(
                        context,
                        t.introGreetingTranslation,
                        17,
                        24,
                        bold: true,
                      ),
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
                  child: _ink(context, '안녕하세요', 25, 35, korean: true),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _ink(
    BuildContext context,
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
    style: IntroTypography.localized(
      context,
      IntroTypography.bookInk(size, line, korean, bold),
    ),
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
      final summarySize = const [20.0, 20.0, 21.0, 20.0, 20.0][index];
      final summaryLine = const [25.0, 25.0, 26.0, 25.0, 25.0][index];
      final bodySize = const [16.0, 17.0, 16.0, 17.0, 17.0][index];
      final bodyLine = const [21.0, 22.0, 21.0, 22.0, 22.0][index];
      Widget text(
        String value,
        double size,
        double line, {
        bool bold = false,
        Color color = IntroPalette.mutedInk,
        Key? key,
      }) => Text(
        value,
        key: key,
        textAlign: index == 2 ? TextAlign.left : TextAlign.center,
        style: IntroTypography.localized(
          context,
          IntroTypography.storyBody(size, line, s, bold, color),
        ),
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
                17,
                22,
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
              text(
                t.introNextSample,
                14.5,
                20,
                color: IntroPalette.emphasisInk,
              ),
            ],
          ],
        ),
      );
    },
  );
}
