import 'package:flutter/material.dart';
import '../../features/onboarding_v2/curriculum_evidence_projector.dart';
import '../../features/onboarding_v2/onboarding_story_catalog_projector.dart';
import '../../models/learner_level.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/button.dart';
import 'onboarding_v2_presentation.dart';
import 'onboarding_v2_shell.dart';
import 'onboarding_journey_scenes.dart';
import 'onboarding_learning_demo.dart';
import 'onboarding_games_demo.dart';

/// Five previews between level selection and the final companion choice.
class OnboardingStoryScreen extends StatelessWidget {
  const OnboardingStoryScreen({
    super.key,
    required this.copy,
    required this.pageIndex,
    required this.onContinue,
    required this.onPrevious,
    this.selectedLevel,
    this.beginner = false,
    this.curriculumEvidenceProjector,
    this.rewardCatalogProjector,
    this.heritageCatalogProjector,
  });
  final OnboardingV2Copy copy;
  final int pageIndex;
  final ValueChanged<String> onContinue;
  final ValueChanged<String> onPrevious;
  final LearnerLevel? selectedLevel;
  final bool beginner;
  final OnboardingCurriculumEvidenceProjection? Function()?
  curriculumEvidenceProjector;
  final OnboardingCatalogProjectionResult<OnboardingRewardCatalogProjection>
  Function()?
  rewardCatalogProjector;
  final OnboardingCatalogProjectionResult<OnboardingHeritageCatalogProjection>
  Function()?
  heritageCatalogProjector;
  static const _ids = [
    OnboardingV2Ids.storyPersonalCurriculum,
    OnboardingV2Ids.storyLearn,
    OnboardingV2Ids.storyGamesAndRewards,
    OnboardingV2Ids.storySaveAndReview,
    OnboardingV2Ids.storyHeritageJourney,
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final level = selectedLevel ?? LearnerLevel.a1;
    final id = _ids[pageIndex];
    final title = [
      t.onboardingJourneyPathTitle,
      beginner
          ? t.onboardingJourneyLettersTitle
          : t.onboardingJourneyLearnTitle,
      t.onboardingJourneyGamesTitle,
      t.onboardingJourneyBookTitle,
      t.onboardingJourneyHanokTitle,
    ][pageIndex];
    final scene = switch (pageIndex) {
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
    return OnboardingV2PageShell(
      brandLatin: copy.brandLatin,
      brandKorean: copy.brandKorean,
      currentStep: pageIndex + 2,
      totalSteps: 7,
      showStage: false,
      progressLabel: copy.navigation.progress(pageIndex + 2, 7),
      heading: JourneyHeading(
        title: title,
        shortTitle: [
          t.onboardingJourneyPathShort,
          beginner
              ? t.onboardingJourneyLettersShort
              : t.onboardingJourneyLearnShort,
          t.onboardingJourneyGamesShort,
          t.onboardingJourneyBookShort,
          t.onboardingJourneyHanokShort,
        ][pageIndex],
        titleKey: const ValueKey('onboarding-v2-story-title'),
      ),
      bodyKey: ValueKey('onboarding-v2-story-scroll-$id'),
      body: KeyedSubtree(
        key: ValueKey('$id-${level.code}-$beginner'),
        child: scene,
      ),
      footer: OnboardingV2FooterActions(
        backKey: const ValueKey('onboarding-v2-story-back'),
        backLabel: copy.navigation.back,
        onBack: () => onPrevious(id),
        primaryAction: SoriButton.filled(
          key: const ValueKey('onboarding-v2-story-next'),
          label: copy.navigation.next,
          trailingIcon: Icons.arrow_forward,
          fullWidth: true,
          onTap: () => onContinue(id),
        ),
      ),
    );
  }
}
