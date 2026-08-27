import '../../l10n/generated/app_localizations.dart';
import 'onboarding_v2_copy_builder.dart';
import 'onboarding_v2_presentation.dart';

/// Production localization seam used by the first-run orchestrator.
OnboardingV2Copy onboardingV2Copy(AppL10n t) =>
    OnboardingV2CopyBuilder.fromLocalizations(t);
