import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/learner_level.dart';
import 'onboarding_v2_presentation.dart';

/// The only AppL10n-to-presentation mapping for first-run V2.
///
/// Keeping this adapter outside the widgets lets tests inject compact fixtures
/// while production always obtains visible copy from the generated DE/EN ARB
/// contract.
abstract final class OnboardingV2CopyBuilder {
  static OnboardingV2Copy fromLocalizations(AppL10n t) => OnboardingV2Copy(
    navigation: OnboardingNavigationCopy(
      back: t.onboardingV2Back,
      next: t.onboardingV2Next,
      finishStory: t.onboardingV2StoryFinish,
      progressBuilder: t.onboardingV2StoryProgress,
    ),
    storyPages: [
      OnboardingStoryPageSpec(
        id: OnboardingV2Ids.storyPersonalCurriculum,
        eyebrow: t.onboardingV2Story1Eyebrow,
        title: t.onboardingV2Story1Title,
        body: t.onboardingV2Story1Body,
        heroSemanticLabel: t.onboardingV2Story1HeroSemantics,
        visualKind: OnboardingStoryVisualKind.personalCurriculum,
        curriculumEvidenceCopy: OnboardingCurriculumEvidenceCopy(
          claim: t.onboardingV2Story1CurriculumClaim,
          sourcesAction: t.onboardingV2Story1CurriculumSourcesAction,
          sourcesTitle: t.onboardingV2Story1CurriculumSourcesTitle,
          sourcesBody: t.onboardingV2Story1CurriculumSourcesBody,
          cefrAuthorityLabel: t.onboardingV2Story1CurriculumCefrAuthority,
          niklAuthorityLabel: t.onboardingV2Story1CurriculumNiklAuthority,
          documentLabel: t.onboardingV2Story1CurriculumDocument,
          versionLabel: t.onboardingV2Story1CurriculumVersion,
          checkedAtLabel: t.onboardingV2Story1CurriculumCheckedAt,
          urlLabel: t.onboardingV2Story1CurriculumUrl,
          openSourceBuilder: t.onboardingV2Story1CurriculumOpenSource,
          closeAction: t.onboardingV2Story1CurriculumSourcesClose,
        ),
        highlights: [
          OnboardingStoryHighlight(
            title: t.onboardingV2Story1Item1Title,
            body: t.onboardingV2Story1Item1Body,
            icon: Icons.route_outlined,
          ),
          OnboardingStoryHighlight(
            title: t.onboardingV2Story1Item2Title,
            body: t.onboardingV2Story1Item2Body,
            icon: Icons.photo_camera_outlined,
          ),
          OnboardingStoryHighlight(
            title: t.onboardingV2Story1Item3Title,
            body: t.onboardingV2Story1Item3Body,
            icon: Icons.document_scanner_outlined,
          ),
          OnboardingStoryHighlight(
            title: t.onboardingV2Story1Item4Title,
            body: t.onboardingV2Story1Item4Body,
            icon: Icons.account_tree_outlined,
          ),
        ],
      ),
      OnboardingStoryPageSpec(
        id: OnboardingV2Ids.storyLearn,
        eyebrow: t.onboardingV2Story2Eyebrow,
        title: t.onboardingV2Story2Title,
        body: t.onboardingV2Story2Body,
        heroSemanticLabel: t.onboardingV2Story2HeroSemantics,
        visualKind: OnboardingStoryVisualKind.learn,
        highlights: [
          OnboardingStoryHighlight(
            title: t.onboardingV2Story2Item1Title,
            body: t.onboardingV2Story2Item1Body,
            icon: Icons.translate_rounded,
          ),
          OnboardingStoryHighlight(
            title: t.onboardingV2Story2Item2Title,
            body: t.onboardingV2Story2Item2Body,
            icon: Icons.gesture_rounded,
          ),
          OnboardingStoryHighlight(
            title: t.onboardingV2Story2Item3Title,
            body: t.onboardingV2Story2Item3Body,
            icon: Icons.graphic_eq_rounded,
          ),
          OnboardingStoryHighlight(
            title: t.onboardingV2Story2Item4Title,
            body: t.onboardingV2Story2Item4Body,
            icon: Icons.forum_outlined,
          ),
        ],
      ),
      OnboardingStoryPageSpec(
        id: OnboardingV2Ids.storySaveAndReview,
        eyebrow: t.onboardingV2Story3Eyebrow,
        title: t.onboardingV2Story3Title,
        body: t.onboardingV2Story3Body,
        heroSemanticLabel: t.onboardingV2Story3HeroSemantics,
        visualKind: OnboardingStoryVisualKind.saveAndReview,
        statusLabel: t.onboardingV2Story3Status,
        highlights: [
          OnboardingStoryHighlight(
            title: t.onboardingV2Story3Item1Title,
            body: t.onboardingV2Story3Item1Body,
            icon: Icons.flip_rounded,
          ),
          OnboardingStoryHighlight(
            title: t.onboardingV2Story3Item2Title,
            body: t.onboardingV2Story3Item2Body,
            icon: Icons.swipe_rounded,
          ),
          OnboardingStoryHighlight(
            title: t.onboardingV2Story3Item3Title,
            body: t.onboardingV2Story3Item3Body,
            icon: Icons.favorite_outline_rounded,
          ),
          OnboardingStoryHighlight(
            title: t.onboardingV2Story3Item4Title,
            body: t.onboardingV2Story3Item4Body,
            icon: Icons.bookmark_border_rounded,
          ),
        ],
      ),
      OnboardingStoryPageSpec(
        id: OnboardingV2Ids.storyGamesAndRewards,
        eyebrow: t.onboardingV2Story4Eyebrow,
        title: t.onboardingV2Story4Title,
        body: t.onboardingV2Story4Body,
        heroSemanticLabel: t.onboardingV2Story4HeroSemantics,
        visualKind: OnboardingStoryVisualKind.gamesAndRewards,
        statusLabel: t.onboardingV2Story4Status,
        highlights: [
          OnboardingStoryHighlight(
            title: t.onboardingV2Story4Item1Title,
            body: t.onboardingV2Story4Item1Body,
            icon: Icons.lightbulb_outline_rounded,
          ),
        ],
        rewardCatalogCopy: OnboardingRewardCatalogCopy(
          title: t.onboardingV2Story4CatalogTitle,
          bodyBuilder: t.onboardingV2Story4CatalogBody,
          possibleRewardBuilder: t.onboardingV2Story4PossibleReward,
        ),
      ),
      OnboardingStoryPageSpec(
        id: OnboardingV2Ids.storyHeritageJourney,
        eyebrow: t.onboardingV2Story5Eyebrow,
        title: t.onboardingV2Story5Title,
        body: t.onboardingV2Story5Body,
        heroSemanticLabel: t.onboardingV2Story5HeroSemantics,
        visualKind: OnboardingStoryVisualKind.heritageJourney,
        statusLabel: t.onboardingV2Story5Status,
        highlights: [
          OnboardingStoryHighlight(
            title: t.onboardingV2Story5Item1Title,
            body: t.onboardingV2Story5Item1Body,
            icon: Icons.collections_bookmark_outlined,
          ),
          OnboardingStoryHighlight(
            title: t.onboardingV2Story5Item2Title,
            body: t.onboardingV2Story5Item2Body,
            icon: Icons.inventory_2_outlined,
          ),
          OnboardingStoryHighlight(
            title: t.onboardingV2Story5Item3Title,
            body: t.onboardingV2Story5Item3Body,
            icon: Icons.chair_outlined,
          ),
          OnboardingStoryHighlight(
            title: t.onboardingV2Story5Item4Title,
            body: t.onboardingV2Story5Item4Body,
            icon: Icons.map_outlined,
          ),
        ],
        heritageCatalogCopy: OnboardingHeritageCatalogCopy(
          previewLabel: t.onboardingV2Story5PreviewLabel,
          inPreparationLabel: t.onboardingV2Story5InPreparationLabel,
          assetReviewNote: t.onboardingV2Story5AssetReviewNote,
          sourcesAction: t.onboardingV2Story5SourcesAction,
          sourcesTitleBuilder: t.onboardingV2Story5SourcesTitle,
          sourcesBody: t.onboardingV2Story5SourcesBody,
          institutionLabel: t.onboardingV2Story5SourceInstitution,
          yearLabel: t.onboardingV2Story5SourceYear,
          yearValueBuilder: t.onboardingV2Story5SourceYearValue,
          yearPublished: t.onboardingV2Story5SourceYearPublished,
          yearUpdated: t.onboardingV2Story5SourceYearUpdated,
          yearAccessed: t.onboardingV2Story5SourceYearAccessed,
          titleLabel: t.onboardingV2Story5SourceTitle,
          authorLabel: t.onboardingV2Story5SourceAuthor,
          licenseLabel: t.onboardingV2Story5SourceLicense,
          licenseKoglType1: t.onboardingV2Story5SourceLicenseKoglType1,
          licenseCitationOnly: t.onboardingV2Story5SourceLicenseCitationOnly,
          licenseSeparatelyApproved:
              t.onboardingV2Story5SourceLicenseSeparatelyApproved,
          urlLabel: t.onboardingV2Story5SourceUrl,
          openSourceBuilder: t.onboardingV2Story5OpenSource,
          closeAction: t.onboardingV2Story5SourcesClose,
        ),
      ),
    ],
    setup: OnboardingSetupCopy(
      eyebrow: t.onboardingV2SetupEyebrow,
      title: t.onboardingV2SetupTitle,
      body: t.onboardingV2SetupBody,
      purposeHeading: t.onboardingV2SetupPurposeHeading,
      levelHeading: t.onboardingV2SetupLevelHeading,
      levelHelp: t.onboardingV2SetupLevelHelp,
      selectLevelPrompt: t.onboardingV2SetupSelectLevelPrompt,
      exampleLabel: t.onboardingV2SetupExampleLabel,
      canDoLabel: t.onboardingV2SetupCanDoLabel,
      learnHereLabel: t.onboardingV2SetupLearnHereLabel,
      compareAction: t.onboardingV2SetupCompareAction,
      compareTitle: t.onboardingV2SetupCompareTitle,
      compareBody: t.onboardingV2SetupCompareBody,
      compareClose: t.onboardingV2SetupCompareClose,
      continueAction: t.onboardingV2SetupContinue,
      purposes: [
        OnboardingPurposeSpec(
          id: OnboardingV2Ids.purposeLifeTravel,
          title: t.onboardingV2PurposeLifeTravelTitle,
          body: t.onboardingV2PurposeLifeTravelBody,
          icon: Icons.travel_explore_outlined,
        ),
        OnboardingPurposeSpec(
          id: OnboardingV2Ids.purposePeopleCulture,
          title: t.onboardingV2PurposePeopleCultureTitle,
          body: t.onboardingV2PurposePeopleCultureBody,
          icon: Icons.people_outline_rounded,
        ),
        OnboardingPurposeSpec(
          id: OnboardingV2Ids.purposeStudyWork,
          title: t.onboardingV2PurposeStudyWorkTitle,
          body: t.onboardingV2PurposeStudyWorkBody,
          icon: Icons.work_outline_rounded,
        ),
        OnboardingPurposeSpec(
          id: OnboardingV2Ids.purposeKContent,
          title: t.onboardingV2PurposeKContentTitle,
          body: t.onboardingV2PurposeKContentBody,
          icon: Icons.subscriptions_outlined,
        ),
      ],
      levels: [
        OnboardingLevelSpec(
          code: LearnerLevel.a1.display,
          name: t.onboardingLevelA1,
          exampleKorean: t.onboardingV2LevelA1ExampleKo,
          exampleTranslation: t.onboardingExampleA1Trans,
          canDo: t.onboardingLevelA1Can,
          learnHere: t.onboardingLevelA1Learn,
        ),
        OnboardingLevelSpec(
          code: LearnerLevel.a2.display,
          name: t.onboardingLevelA2,
          exampleKorean: t.onboardingV2LevelA2ExampleKo,
          exampleTranslation: t.onboardingExampleA2Trans,
          canDo: t.onboardingLevelA2Can,
          learnHere: t.onboardingLevelA2Learn,
        ),
        OnboardingLevelSpec(
          code: LearnerLevel.b1.display,
          name: t.onboardingLevelB1,
          exampleKorean: t.onboardingV2LevelB1ExampleKo,
          exampleTranslation: t.onboardingExampleB1Trans,
          canDo: t.onboardingLevelB1Can,
          learnHere: t.onboardingLevelB1Learn,
        ),
        OnboardingLevelSpec(
          code: LearnerLevel.b2.display,
          name: t.onboardingLevelB2,
          exampleKorean: t.onboardingV2LevelB2ExampleKo,
          exampleTranslation: t.onboardingExampleB2Trans,
          canDo: t.onboardingLevelB2Can,
          learnHere: t.onboardingLevelB2Learn,
        ),
        OnboardingLevelSpec(
          code: LearnerLevel.c1.display,
          name: t.onboardingLevelC1,
          exampleKorean: t.onboardingV2LevelC1ExampleKo,
          exampleTranslation: t.onboardingExampleC1Trans,
          canDo: t.onboardingLevelC1Can,
          learnHere: t.onboardingLevelC1Learn,
        ),
        OnboardingLevelSpec(
          code: LearnerLevel.c2.display,
          name: t.onboardingLevelC2,
          exampleKorean: t.onboardingV2LevelC2ExampleKo,
          exampleTranslation: t.onboardingExampleC2Trans,
          canDo: t.onboardingLevelC2Can,
          learnHere: t.onboardingLevelC2Learn,
        ),
      ],
    ),
    companion: OnboardingCompanionCopy(
      eyebrow: t.onboardingV2CompanionEyebrow,
      title: t.onboardingV2CompanionTitle,
      body: t.onboardingV2CompanionBody,
      equalLearningNote: t.onboardingV2CompanionEqualNote,
      continueAction: t.onboardingV2CompanionContinue,
      confirmationEyebrow: t.onboardingV2ConfirmationEyebrow,
      confirmationBody: t.onboardingV2ConfirmationBody,
      startAction: t.onboardingV2ConfirmationStart,
      changeAction: t.onboardingV2ConfirmationChange,
      companions: [
        OnboardingCompanionSpec(
          id: OnboardingV2Ids.companionTaego,
          name: t.characterRomanTiger,
          koreanName: t.characterNameTiger,
          rhythm: t.onboardingV2CompanionTaegoRhythm,
          body: t.onboardingV2CompanionTaegoBody,
          selectedMessage: t.onboardingV2CompanionTaegoSelected,
        ),
        OnboardingCompanionSpec(
          id: OnboardingV2Ids.companionJoy,
          name: t.characterRomanMagpie,
          koreanName: t.characterNameMagpie,
          rhythm: t.onboardingV2CompanionJoyRhythm,
          body: t.onboardingV2CompanionJoyBody,
          selectedMessage: t.onboardingV2CompanionJoySelected,
        ),
      ],
    ),
  );
}
