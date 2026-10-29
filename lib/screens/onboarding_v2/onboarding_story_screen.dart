import 'package:flutter/material.dart';

import '../../features/onboarding_v2/curriculum_evidence_projector.dart';
import '../../features/onboarding_v2/onboarding_story_catalog_projector.dart';
import '../../models/learner_level.dart';
import 'c_onboarding.dart';
import 'onboarding_v2_presentation.dart';

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

  @override
  Widget build(BuildContext context) => COnboardingStory(
    copy: copy,
    pageIndex: pageIndex,
    level: selectedLevel ?? LearnerLevel.a1,
    beginner: beginner,
    onContinue: onContinue,
    onPrevious: onPrevious,
    curriculumEvidenceProjector: curriculumEvidenceProjector,
  );
}
