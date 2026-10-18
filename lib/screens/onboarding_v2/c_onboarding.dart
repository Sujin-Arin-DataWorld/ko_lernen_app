import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/onboarding_v2/curriculum_evidence_projector.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/learner_level.dart';
import '../../widgets/sori/pressable.dart';
import '../../widgets/sori/type_scale.dart';
import 'c_intro_art.dart';
import 'c_intro_reference_setup.dart';
import 'c_intro_reference_companion.dart';
import 'c_intro_reference_story.dart';
import 'onboarding_games_demo.dart';
import 'onboarding_journey_scenes.dart';
import 'onboarding_learning_demo.dart';
import 'onboarding_v2_presentation.dart';
import 'onboarding_v2_shell.dart' show showOnboardingV2ModalWithFocusRestore;
import 'onboarding_v3_demo_support.dart';

double _introCompression(BuildContext context, double width) =>
    width <= 450 && IntroLayout.usesReferenceText(context)
    ? (934 - MediaQuery.sizeOf(context).height).clamp(0, 120).toDouble()
    : 0;

/// Editable Figma page 77:2, file rVlcMLvngw07BYJ7nRT87C.
/// This presentation owns no progress, economy, consent or preference writes.
class COnboardingFrame extends StatelessWidget {
  const COnboardingFrame({
    super.key,
    required this.step,
    required this.progress,
    required this.hero,
    required this.body,
    required this.continueLabel,
    required this.continueKey,
    required this.onContinue,
    this.bodyKey,
    this.backKey,
    this.onBack,
    this.continueLabelCandidates = const [],
  });
  final int step;
  final String progress;
  final Widget hero;
  final Widget body;
  final String continueLabel;
  final Key continueKey;
  final VoidCallback? onContinue;
  final Key? bodyKey;
  final Key? backKey;
  final VoidCallback? onBack;
  final List<String> continueLabelCandidates;

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: IntroPalette.jade,
        onPrimary: IntroPalette.white,
        surface: IntroPalette.paper,
        onSurface: IntroPalette.ink,
      ),
    ),
    child: Scaffold(
      backgroundColor: IntroPalette.jade,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 402),
          child: SoriViewportTypeScale(
            child: LayoutBuilder(
              builder: (context, bounds) {
                final w = bounds.maxWidth;
                final reference =
                    w >= 360 && IntroLayout.usesReferenceText(context);
                final ctaTop = const [
                  849.0,
                  782.0,
                  776.0,
                  763.0,
                  772.0,
                  760.0,
                  772.0,
                ][step - 1];
                final backGap = reference
                    ? const [0.0, 9.0, 13.0, 13.0, 10.0, 7.0, 4.0][step - 1]
                    : 6.0;
                final footerBottom = onBack == null
                    ? 27.0
                    : reference
                    ? 934 - ctaTop - 58 - backGap - 48
                    : 20.0;
                return Stack(
                  children: [
                    const Positioned.fill(
                      child: ColoredBox(color: IntroPalette.paper),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: w,
                      child: const CIntroArt('jade-surface', fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: w,
                      child: const ColoredBox(color: Color(0x99094838)),
                    ),
                    Positioned(
                      top: math.min(
                        // Layout below stays stable when the selected option changes.
                        (step == 1
                                    ? 307
                                    : step == 7
                                    ? 230.075943
                                    : 307) *
                                w /
                                402 -
                            0,
                        bounds.maxHeight - 120,
                      ),
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(
                            step == 1 ? IntroGeometry.paper : 0,
                          ),
                        ),
                        child: ColoredBox(
                          color: IntroPalette.paper,
                          child: Stack(
                            children: [
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                height:
                                    (step == 7 ? 703.924057 : 627) * w / 402,
                                child: const CIntroArt(
                                  'paper-footer',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (step == 7)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 526 * w / 402,
                        child: const ColoredBox(color: Color(0xff06523e)),
                      ),
                    if (step == 7)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: w,
                        child: const CIntroArt(
                          'jade-surface',
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (step == 7)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: w,
                        child: const ColoredBox(color: Color(0x99094838)),
                      ),
                    Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: MediaQuery.paddingOf(context).top,
                            ),
                            child: SingleChildScrollView(
                              key: bodyKey,
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [hero, body],
                                  ),
                                  if (step == 7 && reference)
                                    Positioned(
                                      left: 291 * w / 402,
                                      top: 105 * w / 402,
                                      width: 215 * w / 402,
                                      height: 102.527534 * w / 402,
                                      child: IgnorePointer(
                                        child: Transform(
                                          transform: Matrix4.identity()
                                            ..setEntry(0, 0, 0)
                                            ..setEntry(1, 1, 0)
                                            ..setEntry(0, 1, 1)
                                            ..setEntry(1, 0, 1),
                                          alignment: Alignment.topLeft,
                                          child: const CIntroArt('plum-branch'),
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    top: 43,
                                    left: 18,
                                    right: 18,
                                    child: _IntroHeader(
                                      step: step,
                                      progress: progress,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            step == 2 && reference ? 4 : 12,
                            16,
                            math.max(
                              footerBottom,
                              MediaQuery.paddingOf(context).bottom,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IntroAction(
                                key: continueKey,
                                label: continueLabel,
                                onTap: onContinue,
                                stableLabelCandidates: continueLabelCandidates,
                              ),
                              if (onBack != null) ...[
                                SizedBox(height: backGap),
                                TextButton(
                                  key: backKey,
                                  onPressed: onBack,
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(96, 48),
                                    padding: const EdgeInsets.only(top: 1),
                                    alignment: Alignment.topCenter,
                                  ),
                                  child: Text(
                                    AppL10n.of(context).onboardingV2Back,
                                    style: IntroTypography.backAction(step),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

class CIntroText extends StatelessWidget {
  const CIntroText(
    this.text, {
    super.key,
    this.size = 17,
    this.bold = false,
    this.center = false,
    this.color = IntroPalette.ink,
  });
  final String text;
  final double size;
  final bool bold;
  final bool center;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: center ? TextAlign.center : TextAlign.start,
    style: IntroTypography.body(size, bold, color),
  );
}

/// Whole generated button art behind an accessible, resizable native label.
class IntroAction extends StatelessWidget {
  const IntroAction({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.gold = true,
    this.arrow = true,
    this.stableLabelCandidates = const [],
    this.compactGold = false,
  });
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final bool gold;
  final bool arrow;
  final List<String> stableLabelCandidates;
  final bool compactGold;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      button: true,
      enabled: onTap != null,
      selected: selected,
      label: label,
      onTap: onTap,
      child: SoriPressable(
        onTap: onTap,
        pressScale: .995,
        surfaceDepth: 0,
        child: ExcludeSemantics(
          child: Opacity(
            opacity: onTap == null ? .48 : 1,
            child: LayoutBuilder(
              builder: (context, bounds) {
                final large = !IntroLayout.usesReferenceText(context);
                final fontSize = gold
                    ? (arrow || compactGold ? 23.0 : 20.0)
                    : 16.0;
                final textStyle = IntroTypography.primaryAction(fontSize, gold);
                var stableHeight = 0.0;
                if (large && stableLabelCandidates.isNotEmpty) {
                  for (final candidate in stableLabelCandidates) {
                    final painter = TextPainter(
                      text: TextSpan(text: candidate, style: textStyle),
                      textDirection: Directionality.of(context),
                      textScaler: MediaQuery.textScalerOf(context),
                    )..layout(maxWidth: math.max(1, bounds.maxWidth - 48));
                    stableHeight = math.max(stableHeight, painter.height);
                    painter.dispose();
                  }
                }
                final labelWidget = Text(
                  label,
                  textAlign: TextAlign.center,
                  style: IntroTypography.primaryAction(fontSize, gold),
                );
                final content = large
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: stableHeight),
                          child: Center(child: labelWidget),
                        ),
                      )
                    : SizedBox(
                        height: gold ? 58 : 48,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              left: gold ? 16 : 8,
                              right: gold ? 16 : 25,
                              top: gold ? (arrow ? 10 : 8) : 13,
                              child: labelWidget,
                            ),
                            if (arrow)
                              Positioned(
                                right: gold ? 24 : 13,
                                top: gold ? 18 : 19,
                                child: gold
                                    ? const IntroChevron()
                                    : const Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 16,
                                        color: IntroPalette.brass,
                                      ),
                              ),
                          ],
                        ),
                      );
                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    if (gold && !large && !compactGold)
                      IntroAssetBody(
                        name: 'gold-button',
                        canvas: const Size(2170, 725),
                        body: const Rect.fromLTRB(73, 205, 2102, 491),
                        visibleWidth: bounds.maxWidth,
                      )
                    else
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              gold
                                  ? (compactGold
                                        ? IntroGeometry.compactAction
                                        : IntroGeometry.action)
                                  : IntroGeometry.levelAction,
                            ),
                            gradient: LinearGradient(
                              begin: compactGold
                                  ? Alignment.topCenter
                                  : Alignment.topLeft,
                              end: compactGold
                                  ? Alignment.bottomCenter
                                  : Alignment.bottomRight,
                              stops: compactGold ? const [0, .46, 1] : null,
                              colors: compactGold
                                  ? const [
                                      Color(0xffffc95e),
                                      Color(0xffedab47),
                                      Color(0xffad691f),
                                    ]
                                  : gold
                                  ? const [
                                      Color(0xffffdf95),
                                      Color(0xffe8b456),
                                      Color(0xffbd812d),
                                    ]
                                  : const [
                                      Color(0xff0b6553),
                                      Color(0xff034a3d),
                                    ],
                            ),
                            border: Border.all(
                              color: compactGold
                                  ? const Color(0xff8f5217)
                                  : IntroPalette.brass,
                              width: compactGold ? 1.2 : 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x402f1c0a),
                                offset: Offset(0, 2),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (compactGold)
                      const Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(painter: IntroCompactGoldBevel()),
                        ),
                      ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: content,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

class _IntroHeader extends StatelessWidget {
  const _IntroHeader({required this.step, required this.progress});
  final int step;
  final String progress;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 77,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned(
          left: -3,
          top: 0,
          width: 55,
          height: 55,
          child: CIntroArt('cloud-mark'),
        ),
        Positioned(
          left: 52,
          top: 18,
          child: Text(
            AppL10n.of(context).onboardingCBrand,
            textScaler: TextScaler.noScaling,
            style: IntroTypography.brand,
          ),
        ),
        Positioned(
          right: 0,
          top: 15,
          width: 66,
          child: Semantics(
            label: progress,
            excludeSemantics: true,
            child: Text(
              '${step.toString().padLeft(2, '0')}/07',
              textAlign: TextAlign.right,
              textScaler: TextScaler.noScaling,
              style: IntroTypography.progress,
            ),
          ),
        ),
        Positioned(
          left: 54,
          top: 53,
          width: 227.2,
          height: 16,
          child: ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                7,
                (i) => i + 1 == step
                    ? const IntroMedal('', size: 16)
                    : Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: IntroPalette.brass,
                            width: 1.3,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _IntroHero extends StatelessWidget {
  const _IntroHero({
    required this.title,
    this.scene,
    this.setup = false,
    this.labels = const [],
    this.sound = false,
    this.previewLabel,
    this.onPreview,
    this.previewKey,
    this.showPreviewButton = false,
  });
  final String title;
  final String? scene;
  final bool setup;
  final List<String> labels;
  final bool sound;
  final String? previewLabel;
  final VoidCallback? onPreview;
  final Key? previewKey;
  final bool showPreviewButton;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final scale = bounds.maxWidth / 402;
      final compression = _introCompression(context, bounds.maxWidth);
      final large = !IntroLayout.usesReferenceText(context);
      final heading = Semantics(
        header: true,
        child: CIntroText(
          title,
          size: large
              ? 26
              : setup
              ? 29
              : 32,
          bold: true,
          color: IntroPalette.white,
        ),
      );
      final art = scene == null
          ? const SizedBox.shrink()
          : Semantics(
              button: onPreview != null,
              label: previewLabel,
              onTap: onPreview,
              child: SoriPressable(
                key: previewKey,
                onTap: onPreview,
                pressScale: .997,
                child: IntroStoryArtwork(
                  index: COnboardingStory.scenes.indexOf(scene!),
                ),
              ),
            );
      if (!setup && scene == null && !large && bounds.maxWidth >= 360) {
        return SizedBox(
          height: 236 * scale,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 20 * scale,
                top: 140 * scale,
                width: 280 * scale,
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: IntroTypography.companionTitle(scale),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      if (setup && !large && bounds.maxWidth >= 360) {
        return SizedBox(
          height: 307 * scale,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: 351 * scale,
                top: 101 * scale,
                width: 70 * scale,
                height: 134 * scale,
                child: const CIntroArt('header-right-leaves'),
              ),
              Positioned(
                left: 192 * scale,
                top: 76 * scale,
                width: 220 * scale,
                height: 330 * scale,
                child: const CIntroArt('taego-header'),
              ),
              Positioned(
                left: -10 * scale,
                top: 207 * scale,
                width: 218 * scale,
                height: 104 * scale,
                child: const CIntroArt('plum-branch'),
              ),
              Positioned(
                left: 20 * scale,
                top: 142 * scale,
                width: 274 * scale,
                child: Semantics(
                  header: true,
                  child: Text(title, style: IntroTypography.setupTitle(scale)),
                ),
              ),
            ],
          ),
        );
      }
      if (large) {
        return ColoredBox(
          color: IntroPalette.jade,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 150),
              Padding(padding: const EdgeInsets.all(20), child: heading),
              if (setup)
                const SizedBox(height: 190, child: CIntroArt('taego-header')),
              if (scene != null) AspectRatio(aspectRatio: 2 / 3, child: art),
              if (labels.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    children: labels
                        .map(
                          (l) => CIntroText(
                            l,
                            bold: true,
                            color: IntroPalette.white,
                          ),
                        )
                        .toList(),
                  ),
                ),
              if (sound)
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: COnboardingSoundScene(),
                ),
              if (showPreviewButton)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _previewButton(context),
                ),
            ],
          ),
        );
      }
      return SizedBox(
        height:
            (setup
                    ? 306
                    : scene == null
                    ? 238
                    : 657) *
                scale -
            compression,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            if (scene != null)
              Positioned(
                top: 54 * scale,
                left: 0,
                right: 0,
                height: 603 * scale - compression,
                child: art,
              ),
            if (setup) ...[
              Positioned(
                right: -8,
                top: 112 * scale - compression * .25,
                width: 190 * scale,
                height: 285 * scale,
                child: const CIntroArt('taego-header'),
              ),
              Positioned(
                left: -30,
                top: 200 * scale - compression * .5,
                width: 220 * scale,
                height: 147 * scale,
                child: const CIntroArt('plum-branch'),
              ),
            ],
            if (scene == 'scholar-scene' || scene == 'hanok-scene')
              Positioned(
                left: scene == 'scholar-scene' ? 0 : 24,
                right: scene == 'scholar-scene' ? 0 : 24,
                bottom: scene == 'scholar-scene' ? 14 * scale : 50 * scale,
                height: (scene == 'scholar-scene' ? 134 : 118) * scale,
                child: IgnorePointer(
                  child: CIntroArt(
                    scene == 'scholar-scene' ? 'book-tools' : 'hanok-tools',
                  ),
                ),
              ),
            Positioned(
              left: 20,
              top: 145 * scale - compression * .25,
              width: (setup ? 280 : 352) * scale,
              child: heading,
            ),
            if (labels.isNotEmpty)
              Positioned(
                left: 24,
                right: 24,
                bottom: 36 * scale,
                child: IgnorePointer(
                  child: Row(
                    children: [
                      for (final label in labels)
                        Expanded(
                          child: CIntroText(
                            label,
                            size: 16 * scale,
                            bold: true,
                            center: true,
                            color: IntroPalette.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (sound)
              Positioned(
                left: 28,
                right: 28,
                bottom: 0,
                child: const COnboardingSoundScene(),
              ),
            if (showPreviewButton)
              Positioned(right: 16, bottom: 2, child: _previewButton(context)),
          ],
        ),
      );
    },
  );

  Widget _previewButton(BuildContext context) => TextButton(
    key: const ValueKey('c-onboarding-games-preview-button'),
    onPressed: onPreview,
    style: TextButton.styleFrom(
      minimumSize: const Size(112, 48),
      backgroundColor: IntroPalette.paper,
      foregroundColor: IntroPalette.ink,
      side: const BorderSide(color: IntroPalette.brass),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(IntroGeometry.preview),
      ),
    ),
    child: CIntroText(
      AppL10n.of(context).guideAvailabilityPreview,
      size: 16,
      bold: true,
    ),
  );
}

class COnboardingSetup extends StatelessWidget {
  const COnboardingSetup({
    super.key,
    required this.copy,
    required this.selectedPurposeId,
    required this.selectedLevelCode,
    required this.beginnerSelected,
    required this.onPurposeChanged,
    required this.onLevelChanged,
    required this.onBeginnerSelected,
    required this.onContinue,
    this.onBack,
  });
  final OnboardingV2Copy copy;
  final String? selectedPurposeId;
  final String? selectedLevelCode;
  final bool beginnerSelected;
  final ValueChanged<String> onPurposeChanged;
  final ValueChanged<String> onLevelChanged;
  final VoidCallback? onBeginnerSelected;
  final ValueChanged<OnboardingSetupSelection> onContinue;
  final VoidCallback? onBack;
  static const purposeArt = {
    OnboardingV2Ids.purposeLifeTravel: 'interest-travel',
    OnboardingV2Ids.purposePeopleCulture: 'interest-culture',
    OnboardingV2Ids.purposeStudyWork: 'interest-study',
    OnboardingV2Ids.purposeKContent: 'interest-kcontent',
  };
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final level = copy.setup.levels
        .where((l) => l.code.toLowerCase() == selectedLevelCode?.toLowerCase())
        .firstOrNull;
    final label = beginnerSelected
        ? t.introNew
        : level?.code ?? copy.setup.selectLevelPrompt;
    return COnboardingFrame(
      step: 1,
      progress: copy.navigation.progress(1, 7),
      hero: _IntroHero(title: t.onboardingJourneyStartTitle, setup: true),
      bodyKey: const ValueKey('onboarding-v2-setup-scroll'),
      body: LayoutBuilder(
        builder: (context, bounds) {
          if (bounds.maxWidth >= 360 &&
              IntroLayout.usesReferenceText(context)) {
            return IntroReferenceSetup(
              copy: copy,
              selectedPurposeId: selectedPurposeId,
              selectedLevelCode: selectedLevelCode,
              beginnerSelected: beginnerSelected,
              onPurposeChanged: onPurposeChanged,
              onChooseLevel: () => _chooseLevel(context),
            );
          }
          return Container(
            decoration: const BoxDecoration(
              color: IntroPalette.paper,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(IntroGeometry.paper),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CIntroText(t.onboardingCStartLevel, size: 25, bold: true),
                const SizedBox(height: 12),
                IntroPanel(
                  selected: true,
                  padding: const EdgeInsets.all(10),
                  child: LayoutBuilder(
                    builder: (context, bounds) {
                      final large = !IntroLayout.usesReferenceText(context);
                      final words = Row(
                        children: [
                          IntroMedal(
                            beginnerSelected ? '가' : level?.code ?? '–',
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CIntroText(label, size: 24, bold: true),
                                if (level != null || beginnerSelected)
                                  CIntroText(
                                    beginnerSelected
                                        ? t.introNewHint
                                        : level!.code == 'A2'
                                        ? t.introA2Hint
                                        : level.name,
                                    size: 13,
                                    color: IntroPalette.blue,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                      final change = IntroAction(
                        key: const ValueKey('c-onboarding-change-level'),
                        label: t.onboardingCChange,
                        gold: false,
                        onTap: () => _chooseLevel(context),
                      );
                      return large
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                words,
                                const SizedBox(height: 10),
                                change,
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: words),
                                const SizedBox(width: 8),
                                SizedBox(width: 105, child: change),
                              ],
                            );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                CIntroText(
                  t.onboardingCLevelRange,
                  center: true,
                  size: 15,
                  color: IntroPalette.blue,
                ),
                const SizedBox(height: 14),
                CIntroText(t.onboardingCInterest, size: 23, bold: true),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, bounds) => Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final p in copy.setup.purposes)
                        SizedBox(
                          width: (bounds.maxWidth - 10) / 2,
                          child: Semantics(
                            label: p.title,
                            selected: p.id == selectedPurposeId,
                            button: true,
                            onTap: () => onPurposeChanged(p.id),
                            child: SoriPressable(
                              key: ValueKey('onboarding-purpose-${p.id}'),
                              onTap: () => onPurposeChanged(p.id),
                              pressScale: .985,
                              surfaceDepth: 2,
                              surfaceEdgeColor: const Color(0xffc8b394),
                              surfaceRadius: 14,
                              child: ExcludeSemantics(
                                child: IntroPanel(
                                  selected: p.id == selectedPurposeId,
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(
                                                IntroGeometry.interest,
                                              ),
                                            ),
                                        child: AspectRatio(
                                          aspectRatio: 2,
                                          child: CIntroArt(purposeArt[p.id]!),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          3,
                                          3,
                                          3,
                                          7,
                                        ),
                                        child: CIntroText(
                                          p.title,
                                          size: 15,
                                          bold: true,
                                          center: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                CIntroText(
                  t.onboardingCLater,
                  size: 15,
                  center: true,
                  color: IntroPalette.blue,
                ),
                const SizedBox(height: 4),
                CIntroText(
                  t.introNextPath,
                  size: 14,
                  bold: true,
                  center: true,
                  color: IntroPalette.blue,
                ),
              ],
            ),
          );
        },
      ),
      continueLabel: copy.navigation.next,
      continueKey: const ValueKey('onboarding-v2-setup-continue'),
      onContinue: selectedLevelCode == null
          ? null
          : () => onContinue(
              OnboardingSetupSelection(
                purposeId: selectedPurposeId,
                levelCode: selectedLevelCode!,
              ),
            ),
      backKey: const ValueKey('onboarding-v2-setup-back'),
      onBack: onBack,
    );
  }

  Future<void> _chooseLevel(BuildContext context) async {
    final t = AppL10n.of(context);
    String? draft = selectedLevelCode;
    var beginner = beginnerSelected;
    (String, bool)? result;
    await showOnboardingV2ModalWithFocusRestore(() async {
      result = await showModalBottomSheet<(String, bool)>(
        context: context,
        constraints: const BoxConstraints(maxWidth: 402),
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: IntroPalette.paper,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(IntroGeometry.adaptiveSheet),
          ),
        ),
        builder: (sheet) => SoriViewportTypeScale(
          child: StatefulBuilder(
            builder: (sheet, update) => LayoutBuilder(
              builder: (sheet, bounds) {
                if (bounds.maxWidth >= 360 &&
                    IntroLayout.usesReferenceText(sheet) &&
                    MediaQuery.sizeOf(sheet).height >= 600) {
                  return IntroReferenceLevelSheet(
                    copy: copy,
                    draft: draft,
                    beginner: beginner,
                    onSelect: (code, isBeginner) => update(() {
                      draft = code;
                      beginner = isBeginner;
                    }),
                    onClose: () => Navigator.of(sheet).pop(),
                    apply: IntroAction(
                      key: const ValueKey('intro-level-apply'),
                      label: t.introApplyLevel,
                      arrow: false,
                      onTap: draft == null
                          ? null
                          : () => Navigator.of(sheet).pop((draft!, beginner)),
                    ),
                  );
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(sheet).height * .88,
                  ),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Semantics(
                                  header: true,
                                  child: CIntroText(
                                    t.introChooseLevel,
                                    size: 23,
                                    bold: true,
                                  ),
                                ),
                              ),
                              TextButton(
                                key: const ValueKey('c-onboarding-sheet-close'),
                                onPressed: () => Navigator.of(sheet).pop(),
                                child: Text(t.btnClose),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _LevelOption(
                            key: const ValueKey('onboarding-v3-new'),
                            label: t.introNew,
                            hint: t.introNewHint,
                            selected: beginner,
                            onTap: () => update(() {
                              draft = 'A1';
                              beginner = true;
                            }),
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, bounds) {
                              final single =
                                  MediaQuery.textScalerOf(context).scale(16) >
                                  22;
                              return Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  for (final level in copy.setup.levels)
                                    SizedBox(
                                      width: single
                                          ? bounds.maxWidth
                                          : (bounds.maxWidth - 10) / 2,
                                      child: _LevelOption(
                                        key: ValueKey(
                                          'onboarding-v2-level-${level.code}',
                                        ),
                                        label: level.code,
                                        hint: level.name,
                                        selected:
                                            !beginner &&
                                            draft?.toLowerCase() ==
                                                level.code.toLowerCase(),
                                        onTap: () => update(() {
                                          draft = level.code;
                                          beginner = false;
                                        }),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          CIntroText(
                            t.onboardingCLater,
                            center: true,
                            size: 15,
                            color: IntroPalette.blue,
                          ),
                          const SizedBox(height: 18),
                          IntroAction(
                            key: const ValueKey('intro-level-apply'),
                            label: t.introApplyLevel,
                            onTap: draft == null
                                ? null
                                : () => Navigator.of(
                                    sheet,
                                  ).pop((draft!, beginner)),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    });
    if (!context.mounted || result == null) {
      return;
    }
    if (result!.$2) {
      (onBeginnerSelected ?? () => onLevelChanged('A1'))();
    } else {
      onLevelChanged(result!.$1);
    }
  }
}

class _LevelOption extends StatelessWidget {
  const _LevelOption({
    super.key,
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '$label. $hint',
    onTap: onTap,
    child: SoriPressable(
      onTap: onTap,
      child: ExcludeSemantics(
        child: IntroPanel(
          selected: selected,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (label.length == 2) ...[
                IntroMedal(label, size: 40),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CIntroText(label, size: 21, bold: true),
                    CIntroText(hint, size: 12, color: IntroPalette.blue),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  color: IntroPalette.jade,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class COnboardingSoundScene extends StatefulWidget {
  const COnboardingSoundScene({super.key, this.reference = false});
  final bool reference;
  @override
  State<COnboardingSoundScene> createState() => _COnboardingSoundSceneState();
}

class _COnboardingSoundSceneState
    extends OnboardingDemoSpeechState<COnboardingSoundScene> {
  @override
  Widget build(BuildContext context) {
    final action = IntroAction(
      key: const ValueKey('c-onboarding-original-listen'),
      label: demoPlaying
          ? AppL10n.of(context).onboardingDemoStop
          : AppL10n.of(context).onboardingJourneyListen,
      selected: demoPlaying,
      compactGold: widget.reference,
      arrow: false,
      onTap: () async {
        await demoSpeak('가');
        if (mounted && context.mounted && demoAudioFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppL10n.of(context).onboardingDemoAudioUnavailable),
            ),
          );
        }
      },
    );
    if (widget.reference) {
      return LayoutBuilder(
        builder: (context, bounds) {
          final s = bounds.maxWidth / 402;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 32 * s,
                top: 0,
                width: 137 * s,
                height: 137 * s,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IntroAssetBody(
                      name: 'speaker',
                      canvas: const Size(1312, 1199),
                      body: const Rect.fromLTRB(198, 207, 1120, 1047),
                      visibleWidth: 137 * s,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 182 * s,
                top: 42 * s,
                width: 190 * s,
                child: action,
              ),
            ],
          );
        },
      );
    }
    return Row(
      children: [
        const SizedBox.square(dimension: 100, child: CIntroArt('speaker')),
        const SizedBox(width: 12),
        Expanded(child: action),
      ],
    );
  }
}

class COnboardingStory extends StatelessWidget {
  const COnboardingStory({
    super.key,
    required this.copy,
    required this.pageIndex,
    required this.level,
    required this.beginner,
    required this.onContinue,
    required this.onPrevious,
    this.curriculumEvidenceProjector,
  });
  final OnboardingV2Copy copy;
  final int pageIndex;
  final LearnerLevel level;
  final bool beginner;
  final ValueChanged<String> onContinue;
  final ValueChanged<String> onPrevious;
  final OnboardingCurriculumEvidenceProjection? Function()?
  curriculumEvidenceProjector;
  static const ids = [
    OnboardingV2Ids.storyPersonalCurriculum,
    OnboardingV2Ids.storyLearn,
    OnboardingV2Ids.storyGamesAndRewards,
    OnboardingV2Ids.storySaveAndReview,
    OnboardingV2Ids.storyHeritageJourney,
  ];
  static const scenes = [
    'path-scene',
    'sound-scene',
    'games-scene',
    'scholar-scene',
    'hanok-scene',
  ];
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final title = [
      t.onboardingCPathTitle,
      t.onboardingCSoundTitle,
      t.onboardingCGamesTitle,
      t.onboardingCBookTitle,
      t.onboardingCHanokTitle,
    ][pageIndex];
    final summary = [
      t.onboardingCPathSummary,
      t.onboardingCSoundSummary,
      t.onboardingCGamesSummary,
      t.onboardingCBookSummary,
      t.onboardingCHanokSummary,
    ][pageIndex];
    final body = [
      t.onboardingCPathBody,
      t.onboardingCSoundBody,
      t.onboardingCGamesBody,
      t.onboardingCBookBody,
      t.onboardingCHanokBody,
    ][pageIndex];
    final previewLabel = [
      t.onboardingJourneyMethod,
      t.onboardingCtaTry,
      t.onboardingCtaGames,
      t.onboardingJourneySamplePage,
      t.onboardingJourneyGrowth,
    ][pageIndex];
    final labels = switch (pageIndex) {
      0 => [t.onboardingCDiscover, t.onboardingCPractice, t.onboardingCRetain],
      3 => [t.onboardingCPhoto, t.onboardingCUnderstand, t.onboardingCRemember],
      4 => [t.onboardingCBuild, t.onboardingCCollect, t.onboardingCCreate],
      _ => <String>[],
    };
    return COnboardingFrame(
      step: pageIndex + 2,
      progress: copy.navigation.progress(pageIndex + 2, 7),
      hero: LayoutBuilder(
        builder: (context, bounds) {
          if (bounds.maxWidth >= 360 &&
              IntroLayout.usesReferenceText(context)) {
            return IntroReferenceStoryHero(
              index: pageIndex,
              title: title,
              labels: labels,
              previewLabel: previewLabel,
              onPreview: () => _openPreview(context, previewLabel),
            );
          }
          return _IntroHero(
            title: title,
            scene: scenes[pageIndex],
            labels: labels,
            sound: pageIndex == 1,
            showPreviewButton: pageIndex == 2,
            previewLabel: previewLabel,
            previewKey: ValueKey('c-onboarding-preview-${pageIndex + 2}'),
            onPreview: () => _openPreview(context, previewLabel),
          );
        },
      ),
      bodyKey: ValueKey('onboarding-v2-story-scroll-${ids[pageIndex]}'),
      body: LayoutBuilder(
        builder: (context, bounds) {
          if (bounds.maxWidth >= 360 &&
              IntroLayout.usesReferenceText(context)) {
            return IntroReferenceStoryBody(
              index: pageIndex,
              summary: summary,
              body: body,
            );
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: CIntroText(
                    summary,
                    key: const ValueKey('onboarding-v2-story-title'),
                    size: 21,
                    bold: true,
                    center: true,
                  ),
                ),
                if (pageIndex == 0) ...[
                  const SizedBox(height: 3),
                  CIntroText(
                    t.introTwelveTools,
                    size: 19,
                    bold: true,
                    center: true,
                  ),
                ],
                const SizedBox(height: 9),
                CIntroText(
                  body,
                  size: 16,
                  center: true,
                  color: IntroPalette.blue,
                ),
                if (pageIndex == 0) ...[
                  const SizedBox(height: 5),
                  CIntroText(t.introNextSample, size: 14, center: true),
                ],
              ],
            ),
          );
        },
      ),
      continueLabel: copy.navigation.next,
      continueKey: const ValueKey('onboarding-v2-story-next'),
      onContinue: () => onContinue(ids[pageIndex]),
      backKey: const ValueKey('onboarding-v2-story-back'),
      onBack: () => onPrevious(ids[pageIndex]),
    );
  }

  void _openPreview(BuildContext context, String label) {
    final preview = switch (pageIndex) {
      0 => OnboardingPathScene(
        level: level,
        beginner: beginner,
        evidence:
            (curriculumEvidenceProjector ??
            OnboardingCurriculumEvidenceProjector.project)(),
      ),
      1 => OnboardingLearningDemo(level: level, beginner: beginner),
      2 => OnboardingGamesDemo(level: level),
      3 => OnboardingBookScene(level: level),
      _ => const OnboardingHanokScene(),
    };
    showCOnboardingSheet(context, title: label, body: preview);
  }
}

class COnboardingCompanion extends StatelessWidget {
  const COnboardingCompanion({
    super.key,
    required this.copy,
    required this.selectedCompanionId,
    required this.onCompanionChanged,
    required this.onContinue,
    this.onBack,
  });
  final OnboardingV2Copy copy;
  final String? selectedCompanionId;
  final ValueChanged<String> onCompanionChanged;
  final ValueChanged<String> onContinue;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return COnboardingFrame(
      step: 7,
      progress: copy.navigation.progress(7, 7),
      hero: _IntroHero(title: t.onboardingCCompanionTitle),
      bodyKey: const ValueKey('onboarding-v2-companion-scroll'),
      body: LayoutBuilder(
        builder: (context, bounds) {
          if (bounds.maxWidth >= 360 &&
              IntroLayout.usesReferenceText(context)) {
            return IntroReferenceCompanion(
              copy: copy,
              selectedCompanionId: selectedCompanionId,
              onCompanionChanged: onCompanionChanged,
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, bounds) {
                    final single =
                        MediaQuery.textScalerOf(context).scale(16) > 24;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 12,
                      children: [
                        for (final c in copy.companion.companions)
                          SizedBox(
                            width: single
                                ? bounds.maxWidth
                                : (bounds.maxWidth - 10) / 2,
                            child: _companion(context, c),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                IntroPanel(
                  child: LayoutBuilder(
                    builder: (context, bounds) {
                      final large = !IntroLayout.usesReferenceText(context);
                      const image = AspectRatio(
                        aspectRatio: 1.5,
                        child: CIntroArt('gye-reading'),
                      );
                      final words = Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CIntroText(
                              t.onboardingCGyeTitle,
                              size: 14,
                              bold: true,
                            ),
                            const SizedBox(height: 8),
                            CIntroText(
                              t.onboardingCGyeBody,
                              size: 12,
                              color: IntroPalette.blue,
                            ),
                          ],
                        ),
                      );
                      return large
                          ? Column(children: [image, words])
                          : ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 155),
                              child: Row(
                                children: [
                                  Expanded(child: image),
                                  Expanded(child: words),
                                ],
                              ),
                            );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
      continueLabel: selectedCompanionId == null
          ? copy.companion.continueAction
          : t.onboardingJourneyStartWith(
              copy.companion.companion(selectedCompanionId!).name,
            ),
      continueLabelCandidates: [
        copy.companion.continueAction,
        for (final companion in copy.companion.companions)
          t.onboardingJourneyStartWith(companion.name),
      ],
      continueKey: const ValueKey('onboarding-v2-companion-continue'),
      onContinue: selectedCompanionId == null
          ? null
          : () => onContinue(selectedCompanionId!),
      backKey: const ValueKey('onboarding-v2-companion-back'),
      onBack: onBack,
    );
  }

  Widget _companion(BuildContext context, OnboardingCompanionSpec companion) {
    final selected = companion.id == selectedCompanionId;
    final taego = companion.id == OnboardingV2Ids.companionTaego;
    final t = AppL10n.of(context);
    final role = taego ? t.onboardingCTaegoRole : t.onboardingCJoyRole;
    return MergeSemantics(
      child: Semantics(
        key: ValueKey('onboarding-v2-companion-semantics-${companion.id}'),
        button: true,
        selected: selected,
        label: '${companion.name}. $role',
        onTap: () => onCompanionChanged(companion.id),
        child: SoriPressable(
          key: ValueKey('onboarding-v2-companion-${companion.id}'),
          onTap: () => onCompanionChanged(companion.id),
          pressScale: .995,
          surfaceDepth: 0,
          surfaceRadius: 14,
          surfaceEdgeColor: const Color(0xffb99b6c),
          child: ExcludeSemantics(
            child: IntroPanel(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(3),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        IntroGeometry.adaptivePortrait,
                      ),
                      child: Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 2 / 3,
                            child: CIntroArt(
                              taego ? 'taego-close' : 'joy-close',
                            ),
                          ),
                          Positioned.fill(
                            child: IntroCompanionPortraitRim(
                              selected: selected,
                            ),
                          ),
                          if (selected)
                            const Positioned(
                              left: 9,
                              bottom: 9,
                              child: IntroMedal('✓', size: 43),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(3, 8, 3, 6),
                    child: CIntroText(
                      companion.name,
                      size: 25,
                      bold: true,
                      center: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 0, 6, 19),
                    child: CIntroText(
                      role,
                      size: 12,
                      center: true,
                      color: IntroPalette.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showCOnboardingSheet(
  BuildContext context, {
  required String title,
  required Widget body,
}) async {
  await showOnboardingV2ModalWithFocusRestore(
    () => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: IntroPalette.paper,
      builder: (sheet) => SoriViewportTypeScale(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheet).height * .88,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Semantics(
                  header: true,
                  child: CIntroText(title, size: 24, bold: true),
                ),
              ),
              Expanded(child: body),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: IntroAction(
                    key: const ValueKey('c-onboarding-sheet-close'),
                    label: AppL10n.of(sheet).btnClose,
                    onTap: () => Navigator.of(sheet).pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
