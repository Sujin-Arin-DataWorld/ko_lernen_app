import 'package:flutter/material.dart';

import '../../features/onboarding_v2/curriculum_evidence_projector.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/learner_level.dart';
import '../../widgets/sori/c_gallery/c_materials.dart';
import '../../widgets/sori/c_gallery/c_objects.dart';
import '../../widgets/sori/pressable.dart';
import 'onboarding_games_demo.dart';
import 'onboarding_journey_scenes.dart';
import 'onboarding_learning_demo.dart';
import 'onboarding_v2_presentation.dart';
import 'onboarding_v2_shell.dart' show showOnboardingV2ModalWithFocusRestore;
import 'onboarding_v3_demo_support.dart';

/// The approved, flattened crops are illustration layers, never a phone-sized
/// screenshot with navigation hotspots. No source pixels are regenerated.
/// Text baked into a scene remains part of that illustration; native captions
/// provide its localized, scalable meaning without erasing flowers or hats.
class COnboardingArt extends StatelessWidget {
  const COnboardingArt(this.name, {super.key, required this.aspectRatio});
  final String name;
  final double aspectRatio;
  static const directory = 'assets/illustrations/concept_c/einleitung';

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: aspectRatio,
    child: LayoutBuilder(
      builder: (context, constraints) => Image.asset(
        '$directory/$name.png',
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        cacheWidth:
            (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                .ceil(),
        errorBuilder: (context, error, stack) =>
            Center(child: Text(AppL10n.of(context).onboardingDemoUnavailable)),
      ),
    ),
  );
}

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: 'Paperlogy'),
        colorScheme: theme.colorScheme.copyWith(
          primary: CPalette.jade,
          onPrimary: CPalette.paper,
          surface: CPalette.paper,
          onSurface: CPalette.ink,
        ),
      ),
      child: Scaffold(
        backgroundColor: CPalette.deepJade,
        body: Stack(
          children: [
            const Positioned.fill(child: _CIntroMaterial(CMaterial.jade)),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      _CIntroHeader(step: step, progress: progress),
                      Expanded(
                        child: SingleChildScrollView(
                          key: bodyKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              hero,
                              _CIntroPaper(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    12,
                                    14,
                                    16,
                                  ),
                                  child: body,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _CIntroPaper(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Opacity(
                                opacity: onContinue == null ? .5 : 1,
                                child: CMaterialAction(
                                  key: continueKey,
                                  label: continueLabel,
                                  onTap: onContinue,
                                  surfaceTexture: const _CIntroMaterial(
                                    CMaterial.brass,
                                  ),
                                ),
                              ),
                              if (onBack != null)
                                TextButton(
                                  key: backKey,
                                  onPressed: onBack,
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(96, 48),
                                    foregroundColor: CPalette.ink,
                                  ),
                                  child: CIntroText(
                                    AppL10n.of(context).onboardingV2Back,
                                    size: 17,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CIntroHeader extends StatelessWidget {
  const _CIntroHeader({required this.step, required this.progress});
  final int step;
  final String progress;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
    child: Column(
      children: [
        Row(
          children: [
            const SizedBox(
              width: 27,
              child: COnboardingArt(
                'common-cloud-logo-context',
                aspectRatio: 82 / 74,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'HANGUL SORI',
                style: TextStyle(
                  fontFamily: 'Paperlogy',
                  fontSize: 14,
                  letterSpacing: 2.1,
                  fontWeight: FontWeight.w600,
                  color: Color(0xfff4d694),
                ),
              ),
            ),
            Semantics(
              label: progress,
              excludeSemantics: true,
              child: Text(
                '${step.toString().padLeft(2, '0')} / 07',
                style: const TextStyle(
                  fontFamily: 'Paperlogy',
                  fontSize: 16,
                  color: CPalette.paper,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              7,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox.square(
                  dimension: 16,
                  child: index + 1 == step
                      ? const CObjectArt(CObject.seal)
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xffddb977),
                              width: 1.2,
                            ),
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

class _CIntroPaper extends StatelessWidget {
  const _CIntroPaper({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: CPalette.paper,
    child: Stack(
      children: [
        const Positioned.fill(child: _CIntroMaterial(CMaterial.paper)),
        child,
      ],
    ),
  );
}

/// Neutral material regions from the exact package; PNG bytes stay intact.
class _CIntroMaterial extends StatelessWidget {
  const _CIntroMaterial(this.material);
  final CMaterial material;
  @override
  Widget build(BuildContext context) => CAtlasArt(
    path:
        '${COnboardingArt.directory}/${switch (material) {
          CMaterial.jade => 'common-jade-material-sample',
          CMaterial.brass => 'common-gold-button-material-sample',
          _ => 'common-hanji-material-sample',
        }}.png',
    // The left 80px of the paper sample includes a clipped stamp, not grain.
    region: material == CMaterial.paper
        ? const Rect.fromLTRB(.12, 0, 1, 1)
        : const Rect.fromLTWH(0, 0, 1, 1),
    fit: BoxFit.fill,
  );
}

class CIntroText extends StatelessWidget {
  const CIntroText(
    this.text, {
    super.key,
    this.size = 17,
    this.bold = false,
    this.center = false,
  });
  final String text;
  final double size;
  final bool bold;
  final bool center;
  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: center ? TextAlign.center : TextAlign.start,
    style: TextStyle(
      fontFamily: 'Paperlogy',
      fontSize: size,
      height: 1.22,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: CPalette.ink,
    ),
  );
}

/// The same callbacks feed the durable first-run coordinator; this class owns
/// no preference, placement, economy or account writes.
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
    OnboardingV2Ids.purposeLifeTravel: ('01-alltag-reise', 333 / 181),
    OnboardingV2Ids.purposePeopleCulture: ('01-menschen-kultur', 336 / 181),
    OnboardingV2Ids.purposeStudyWork: ('01-studium-beruf', 333 / 165),
    OnboardingV2Ids.purposeKContent: ('01-k-content', 336 / 166),
  };

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final level = copy.setup.levels
        .where((l) => l.code.toLowerCase() == selectedLevelCode?.toLowerCase())
        .firstOrNull;
    final levelLabel = beginnerSelected
        ? t.onboardingJourneyNew
        : level == null
        ? copy.setup.selectLevelPrompt
        : level.code;
    return COnboardingFrame(
      step: 1,
      progress: copy.navigation.progress(1, 7),
      hero: Semantics(
        header: true,
        label: t.onboardingJourneyStartTitle,
        child: const COnboardingArt('01-taego-header', aspectRatio: 747 / 350),
      ),
      bodyKey: const ValueKey('onboarding-v2-setup-scroll'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CIntroText(t.onboardingCStartLevel, size: 25, bold: true),
          const SizedBox(height: 10),
          CImageTap(
            label: '$levelLabel. ${t.onboardingCChange}',
            onTap: () => _chooseLevel(context),
            child: CPaperPanel(
              surfaceTexture: const _CIntroMaterial(CMaterial.paper),
              child: Row(
                children: [
                  const CObjectArt(CObject.seal, size: 44),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CIntroText(levelLabel, size: 22, bold: true),
                        if (beginnerSelected)
                          CIntroText(t.onboardingJourneyNewHint, size: 14)
                        else if (level != null)
                          CIntroText(level.name, size: 14),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  CMaterialAction(
                    key: const ValueKey('c-onboarding-change-level'),
                    label: t.onboardingCChange,
                    compact: true,
                    gold: false,
                    surfaceTexture: const _CIntroMaterial(CMaterial.jade),
                    onTap: () => _chooseLevel(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),
          CIntroText(t.onboardingCLevelRange, center: true, size: 15),
          const SizedBox(height: 14),
          CIntroText(t.onboardingCInterest, size: 23, bold: true),
          const SizedBox(height: 9),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 9,
              runSpacing: 10,
              children: [
                for (final item in copy.setup.purposes)
                  SizedBox(
                    width: (constraints.maxWidth - 9) / 2,
                    child: CImageTap(
                      key: ValueKey('onboarding-purpose-${item.id}'),
                      label: item.title,
                      selected: selectedPurposeId == item.id,
                      onTap: () => onPurposeChanged(item.id),
                      child: CPaperPanel(
                        surfaceTexture: const _CIntroMaterial(CMaterial.paper),
                        padding: const EdgeInsets.all(3),
                        radius: 12,
                        child: Column(
                          children: [
                            if (purposeArt[item.id] case final art?)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: COnboardingArt(
                                  art.$1,
                                  aspectRatio: art.$2,
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(3, 6, 3, 7),
                              child: CIntroText(
                                item.title,
                                size: 15,
                                bold: true,
                                center: true,
                              ),
                            ),
                            if (selectedPurposeId == item.id)
                              const SizedBox(
                                height: 3,
                                width: 50,
                                child: ColoredBox(color: CPalette.jade),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          CIntroText(t.onboardingCLater, center: true, size: 15),
        ],
      ),
      continueLabel: t.onboardingCtaPath,
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

  void _chooseLevel(BuildContext context) {
    final t = AppL10n.of(context);
    showCOnboardingSheet(
      context,
      title: t.onboardingCStartLevel,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CMaterialAction(
              key: const ValueKey('onboarding-v3-new'),
              label: t.onboardingJourneyNew,
              selected: beginnerSelected,
              gold: false,
              surfaceTexture: const _CIntroMaterial(CMaterial.jade),
              onTap: () {
                Navigator.of(context).pop();
                (onBeginnerSelected ?? () => onLevelChanged('A1'))();
              },
            ),
            const SizedBox(height: 14),
            for (final level in copy.setup.levels) ...[
              CImageTap(
                key: ValueKey('onboarding-v2-level-${level.code}'),
                label: '${level.code}. ${level.name}. ${level.canDo}',
                selected:
                    !beginnerSelected &&
                    selectedLevelCode?.toLowerCase() ==
                        level.code.toLowerCase(),
                onTap: () {
                  Navigator.of(context).pop();
                  onLevelChanged(level.code);
                },
                child: CPaperPanel(
                  surfaceTexture: const _CIntroMaterial(CMaterial.paper),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CIntroText(
                        '${level.code} · ${level.name}',
                        size: 20,
                        bold: true,
                      ),
                      const SizedBox(height: 5),
                      CIntroText(level.canDo, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

/// The visible sound button is an image-backed native control at its original
/// scene coordinates, with the same crop. It never creates learning rewards.
class COnboardingSoundScene extends StatefulWidget {
  const COnboardingSoundScene({super.key});
  @override
  State<COnboardingSoundScene> createState() => _COnboardingSoundSceneState();
}

class _COnboardingSoundSceneState
    extends OnboardingDemoSpeechState<COnboardingSoundScene> {
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 747 / 1068,
    child: LayoutBuilder(
      builder: (context, bounds) => Stack(
        children: [
          const Positioned.fill(
            child: COnboardingArt(
              '03-sound-full-scene',
              aspectRatio: 747 / 1068,
            ),
          ),
          Positioned(
            left: bounds.maxWidth * 329 / 747,
            top: bounds.maxHeight * 903 / 1068,
            width: bounds.maxWidth * 371 / 747,
            height: bounds.maxHeight * 134 / 1068,
            child: CImageTap(
              key: const ValueKey('c-onboarding-original-listen'),
              label: demoPlaying
                  ? AppL10n.of(context).onboardingDemoStop
                  : '${AppL10n.of(context).onboardingDemoListen}: 가',
              selected: demoPlaying,
              onTap: () async {
                await demoSpeak('가');
                if (mounted && context.mounted && demoAudioFailed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppL10n.of(context).onboardingDemoAudioUnavailable,
                      ),
                    ),
                  );
                }
              },
              child: const COnboardingArt(
                '03-listen-button-reference',
                aspectRatio: 371 / 134,
              ),
            ),
          ),
        ],
      ),
    ),
  );
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
    ('02-joy-book-full-scene', 747 / 980),
    ('03-sound-full-scene', 747 / 1068),
    ('04-dokkaebi-games-full-scene', 747 / 930),
    ('05-talsunbi-book-full-scene', 747 / 1017),
    ('06-hanok-culture-full-scene', 747 / 983),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final scene = scenes[pageIndex];
    final title = [
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
    return COnboardingFrame(
      step: pageIndex + 2,
      progress: copy.navigation.progress(pageIndex + 2, 7),
      hero: Semantics(
        label: [
          t.onboardingCPathArt,
          t.onboardingCSoundArt,
          t.onboardingCGamesArt,
          t.onboardingCBookArt,
          t.onboardingCHanokArt,
        ][pageIndex],
        child: pageIndex == 1
            ? const COnboardingSoundScene()
            : COnboardingArt(scene.$1, aspectRatio: scene.$2),
      ),
      bodyKey: ValueKey('onboarding-v2-story-scroll-${ids[pageIndex]}'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: CIntroText(
              title,
              key: const ValueKey('onboarding-v2-story-title'),
              size: 23,
              bold: true,
              center: true,
            ),
          ),
          const SizedBox(height: 5),
          CIntroText(body, center: true),
          const SizedBox(height: 12),
          CMaterialAction(
            key: ValueKey('c-onboarding-preview-${pageIndex + 2}'),
            label: previewLabel,
            gold: false,
            surfaceTexture: const _CIntroMaterial(CMaterial.jade),
            onTap: () => _openPreview(context, previewLabel),
          ),
        ],
      ),
      continueLabel: [
        t.onboardingCtaTry,
        t.onboardingCtaGames,
        t.onboardingCtaBook,
        t.onboardingCtaHanok,
        t.onboardingCtaCompanion,
      ][pageIndex],
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
      hero: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Semantics(
          header: true,
          child: Text(
            t.onboardingJourneyCompanionTitle,
            style: const TextStyle(
              fontFamily: 'Paperlogy',
              fontSize: 30,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: CPalette.paper,
            ),
          ),
        ),
      ),
      bodyKey: const ValueKey('onboarding-v2-companion-scroll'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              var nameWidth = 0.0;
              for (final companion in copy.companion.companions) {
                final painter = TextPainter(
                  text: TextSpan(
                    text: companion.name,
                    style: const TextStyle(
                      fontFamily: 'Paperlogy',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                )..layout();
                if (painter.width > nameWidth) nameWidth = painter.width;
                painter.dispose();
              }
              if ((constraints.maxWidth - 9) / 2 < nameWidth + 12) {
                return Column(
                  children: [
                    for (final companion in copy.companion.companions) ...[
                      _companion(context, companion),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (
                    var i = 0;
                    i < copy.companion.companions.length;
                    i++
                  ) ...[
                    if (i > 0) const SizedBox(width: 9),
                    Expanded(
                      child: _companion(context, copy.companion.companions[i]),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          CPaperPanel(
            surfaceTexture: const _CIntroMaterial(CMaterial.paper),
            padding: const EdgeInsets.all(5),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final art = ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const COnboardingArt(
                    '07-gye-reading-scene',
                    aspectRatio: 400 / 287,
                  ),
                );
                final words = Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CIntroText(t.onboardingCGyeTitle, size: 17, bold: true),
                      const SizedBox(height: 5),
                      CIntroText(t.onboardingCGyeBody, size: 15),
                    ],
                  ),
                );
                if (MediaQuery.textScalerOf(context).scale(17) > 22) {
                  return Column(children: [art, words]);
                }
                return Row(
                  children: [
                    Expanded(child: art),
                    Expanded(child: words),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const ValueKey('onboarding-v2-companion-details'),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => showCOnboardingSheet(
              context,
              title: copy.companion.title,
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: CIntroText(
                  '${copy.companion.body}\n\n${copy.companion.equalLearningNote}',
                ),
              ),
            ),
            child: CIntroText(t.onboardingV2DetailsAction, size: 16),
          ),
        ],
      ),
      continueLabel: selectedCompanionId == null
          ? copy.companion.continueAction
          : t.onboardingJourneyStartWith(
              copy.companion.companion(selectedCompanionId!).name,
            ),
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
    final name =
        '07-${taego ? 'taego' : 'joy'}-${selected ? 'selected' : 'unselected'}';
    final role = taego
        ? AppL10n.of(context).onboardingCTaegoRole
        : AppL10n.of(context).onboardingCJoyRole;
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
          pressScale: .99,
          surfaceDepth: 3,
          surfaceRadius: 14,
          surfaceEdgeColor: CPalette.oakEdge,
          child: ExcludeSemantics(
            child: CPaperPanel(
              surfaceTexture: const _CIntroMaterial(CMaterial.paper),
              padding: EdgeInsets.zero,
              radius: 14,
              child: Column(
                children: [
                  COnboardingArt(name, aspectRatio: (taego ? 374 : 359) / 546),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(3, 7, 3, 6),
                    child: CIntroText(
                      companion.name,
                      size: 24,
                      bold: true,
                      center: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
                    child: CIntroText(role, size: 15, center: true),
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
      backgroundColor: CPalette.paper,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * .88,
        child: _CIntroPaper(
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
                  padding: const EdgeInsets.all(12),
                  child: CMaterialAction(
                    key: const ValueKey('c-onboarding-sheet-close'),
                    label: AppL10n.of(sheetContext).btnClose,
                    surfaceTexture: const _CIntroMaterial(CMaterial.brass),
                    onTap: () => Navigator.of(sheetContext).pop(),
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
