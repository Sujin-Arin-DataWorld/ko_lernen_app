import 'package:flutter/material.dart';

import 'c_onboarding.dart';
import 'onboarding_v2_presentation.dart';

/// Level intent is a draft, never an assessment or progression unlock.
class OnboardingSetupScreen extends StatelessWidget {
  const OnboardingSetupScreen({
    super.key,
    required this.copy,
    required this.selectedPurposeId,
    required this.selectedLevelCode,
    required this.onPurposeChanged,
    required this.onLevelChanged,
    required this.onContinue,
    this.onBack,
    this.beginnerSelected = false,
    this.onBeginnerSelected,
  });
  final OnboardingV2Copy copy;
  final String? selectedPurposeId;
  final String? selectedLevelCode;
  final ValueChanged<String> onPurposeChanged;
  final ValueChanged<String> onLevelChanged;
  final ValueChanged<OnboardingSetupSelection> onContinue;
  final VoidCallback? onBack;
  final bool beginnerSelected;
  final VoidCallback? onBeginnerSelected;

  @override
  Widget build(BuildContext context) => COnboardingSetup(
    copy: copy,
    selectedPurposeId: selectedPurposeId,
    selectedLevelCode: selectedLevelCode,
    beginnerSelected: beginnerSelected,
    onPurposeChanged: onPurposeChanged,
    onLevelChanged: onLevelChanged,
    onBeginnerSelected: onBeginnerSelected,
    onContinue: onContinue,
    onBack: onBack,
  );
}
