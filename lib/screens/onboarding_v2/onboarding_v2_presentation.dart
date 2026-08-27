import 'package:flutter/material.dart';

import '../../models/learner_level.dart';

/// Presentation-only identifiers. The first-run coordinator owns persistence
/// and maps these stable string IDs to its domain enums.
abstract final class OnboardingV2Ids {
  static const storyPersonalCurriculum = 'personalCurriculum';
  static const storyLearn = 'learn';
  static const storySaveAndReview = 'saveAndReview';
  static const storyGamesAndRewards = 'gamesAndRewards';
  static const storyHeritageJourney = 'heritageJourney';

  static const purposeLifeTravel = 'lifeTravel';
  static const purposePeopleCulture = 'peopleCulture';
  static const purposeStudyWork = 'studyWork';
  static const purposeKContent = 'kContent';

  static const companionTaego = 'taego';
  static const companionJoy = 'joy';

  static final levels = List<String>.unmodifiable(
    LearnerLevel.values.map((level) => level.display),
  );
}

enum OnboardingStoryVisualKind {
  personalCurriculum,
  learn,
  saveAndReview,
  gamesAndRewards,
  heritageJourney,
}

@immutable
class OnboardingStoryHighlight {
  const OnboardingStoryHighlight({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}

@immutable
class OnboardingRewardCatalogCopy {
  const OnboardingRewardCatalogCopy({
    required this.title,
    required this.bodyBuilder,
    required this.possibleRewardBuilder,
  });

  final String title;
  final String Function(int count) bodyBuilder;
  final String Function(String reward) possibleRewardBuilder;
}

@immutable
class OnboardingCurriculumEvidenceCopy {
  const OnboardingCurriculumEvidenceCopy({
    required this.claim,
    required this.sourcesAction,
    required this.sourcesTitle,
    required this.sourcesBody,
    required this.cefrAuthorityLabel,
    required this.niklAuthorityLabel,
    required this.documentLabel,
    required this.versionLabel,
    required this.checkedAtLabel,
    required this.urlLabel,
    required this.openSourceBuilder,
    required this.closeAction,
  });

  final String claim;
  final String sourcesAction;
  final String sourcesTitle;
  final String sourcesBody;
  final String cefrAuthorityLabel;
  final String niklAuthorityLabel;
  final String documentLabel;
  final String versionLabel;
  final String checkedAtLabel;
  final String urlLabel;
  final String Function(String sourceTitle) openSourceBuilder;
  final String closeAction;
}

@immutable
class OnboardingHeritageCatalogCopy {
  const OnboardingHeritageCatalogCopy({
    required this.previewLabel,
    required this.inPreparationLabel,
    required this.assetReviewNote,
    required this.sourcesAction,
    required this.sourcesTitleBuilder,
    required this.sourcesBody,
    required this.institutionLabel,
    required this.yearLabel,
    required this.yearValueBuilder,
    required this.yearPublished,
    required this.yearUpdated,
    required this.yearAccessed,
    required this.titleLabel,
    required this.authorLabel,
    required this.licenseLabel,
    required this.licenseKoglType1,
    required this.licenseCitationOnly,
    required this.licenseSeparatelyApproved,
    required this.urlLabel,
    required this.openSourceBuilder,
    required this.closeAction,
  });

  final String previewLabel;
  final String inPreparationLabel;
  final String assetReviewNote;
  final String sourcesAction;
  final String Function(String estateName) sourcesTitleBuilder;
  final String sourcesBody;
  final String institutionLabel;
  final String yearLabel;
  final String Function(int year, String basis) yearValueBuilder;
  final String yearPublished;
  final String yearUpdated;
  final String yearAccessed;
  final String titleLabel;
  final String authorLabel;
  final String licenseLabel;
  final String licenseKoglType1;
  final String licenseCitationOnly;
  final String licenseSeparatelyApproved;
  final String urlLabel;
  final String Function(String sourceTitle) openSourceBuilder;
  final String closeAction;
}

@immutable
class OnboardingStoryPageSpec {
  const OnboardingStoryPageSpec({
    required this.id,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.heroSemanticLabel,
    required this.visualKind,
    required this.highlights,
    this.statusLabel,
    this.curriculumEvidenceCopy,
    this.rewardCatalogCopy,
    this.heritageCatalogCopy,
  });

  final String id;
  final String eyebrow;
  final String title;
  final String body;
  final String heroSemanticLabel;
  final OnboardingStoryVisualKind visualKind;
  final List<OnboardingStoryHighlight> highlights;

  /// Visible truth-status text such as "reward examples" or "coming soon".
  /// It must never be conveyed through blur, color, or opacity alone.
  final String? statusLabel;

  /// Localized framing for registry-derived CEFR/NIKL evidence. The widget
  /// renders it only when the public claim validator produces a projection.
  final OnboardingCurriculumEvidenceCopy? curriculumEvidenceCopy;

  /// Localized framing for catalog-derived reward examples. Reward labels
  /// themselves always come from the central activity catalog.
  final OnboardingRewardCatalogCopy? rewardCatalogCopy;

  /// Localized framing for the source-backed heritage preview.
  final OnboardingHeritageCatalogCopy? heritageCatalogCopy;
}

@immutable
class OnboardingNavigationCopy {
  const OnboardingNavigationCopy({
    required this.back,
    required this.next,
    required this.finishStory,
    this.progressTemplate = '',
    this.progressBuilder,
  }) : assert(
         progressBuilder != null || progressTemplate != '',
         'Provide a localized progressBuilder or progressTemplate',
       );
  final String back;
  final String next;
  final String finishStory;
  final String progressTemplate;
  final String Function(int current, int total)? progressBuilder;

  String progress(int current, int total) =>
      progressBuilder?.call(current, total) ??
      progressTemplate
          .replaceAll('{current}', '$current')
          .replaceAll('{total}', '$total');
}

@immutable
class OnboardingPurposeSpec {
  const OnboardingPurposeSpec({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
  });

  final String id;
  final String title;
  final String body;
  final IconData icon;
}

@immutable
class OnboardingLevelSpec {
  const OnboardingLevelSpec({
    required this.code,
    required this.name,
    required this.exampleKorean,
    required this.exampleTranslation,
    required this.canDo,
    required this.learnHere,
  });

  final String code;
  final String name;
  final String exampleKorean;
  final String exampleTranslation;
  final String canDo;
  final String learnHere;
}

@immutable
class OnboardingSetupCopy {
  const OnboardingSetupCopy({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.purposeHeading,
    required this.levelHeading,
    required this.levelHelp,
    required this.selectLevelPrompt,
    required this.exampleLabel,
    required this.canDoLabel,
    required this.learnHereLabel,
    required this.compareAction,
    required this.compareTitle,
    required this.compareBody,
    required this.compareClose,
    required this.continueAction,
    required this.purposes,
    required this.levels,
  });

  final String eyebrow;
  final String title;
  final String body;
  final String purposeHeading;
  final String levelHeading;
  final String levelHelp;
  final String selectLevelPrompt;
  final String exampleLabel;
  final String canDoLabel;
  final String learnHereLabel;
  final String compareAction;
  final String compareTitle;
  final String compareBody;
  final String compareClose;
  final String continueAction;
  final List<OnboardingPurposeSpec> purposes;
  final List<OnboardingLevelSpec> levels;
}

@immutable
class OnboardingSetupSelection {
  const OnboardingSetupSelection({
    required this.purposeId,
    required this.levelCode,
  });

  final String purposeId;
  final String levelCode;
}

@immutable
class OnboardingCompanionSpec {
  const OnboardingCompanionSpec({
    required this.id,
    required this.name,
    required this.koreanName,
    required this.rhythm,
    required this.body,
    required this.selectedMessage,
  });

  final String id;
  final String name;
  final String koreanName;
  final String rhythm;
  final String body;
  final String selectedMessage;
}

@immutable
class OnboardingCompanionCopy {
  const OnboardingCompanionCopy({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.equalLearningNote,
    required this.continueAction,
    required this.confirmationEyebrow,
    required this.confirmationBody,
    required this.startAction,
    required this.changeAction,
    required this.companions,
  });

  final String eyebrow;
  final String title;
  final String body;
  final String equalLearningNote;
  final String continueAction;
  final String confirmationEyebrow;
  final String confirmationBody;
  final String startAction;
  final String changeAction;
  final List<OnboardingCompanionSpec> companions;

  OnboardingCompanionSpec companion(String id) => companions.firstWhere(
    (candidate) => candidate.id == id,
    orElse: () => companions.first,
  );
}

@immutable
class OnboardingV2Copy {
  const OnboardingV2Copy({
    required this.brandLatin,
    required this.brandKorean,
    required this.syllableGa,
    required this.navigation,
    required this.storyPages,
    required this.setup,
    required this.companion,
  });

  final String brandLatin;
  final String brandKorean;
  final String syllableGa;
  final OnboardingNavigationCopy navigation;
  final List<OnboardingStoryPageSpec> storyPages;
  final OnboardingSetupCopy setup;
  final OnboardingCompanionCopy companion;
}
