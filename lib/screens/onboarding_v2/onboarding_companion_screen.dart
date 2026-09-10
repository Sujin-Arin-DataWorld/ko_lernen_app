import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/button.dart';
import 'onboarding_character_media.dart';
import '../../widgets/sori/tokens.dart';
import 'onboarding_v2_presentation.dart';
import 'onboarding_v2_shell.dart';
import 'onboarding_v2_stage.dart';

class OnboardingCompanionScreen extends StatelessWidget {
  const OnboardingCompanionScreen({
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
    assert(copy.companion.companions.length == 2);
    final companionCopy = copy.companion;
    final text = SoriTextTheme.of(context);
    final progress = copy.navigation.progress(7, 7);
    final compactHeading =
        MediaQuery.sizeOf(context).height < 700 &&
        MediaQuery.textScalerOf(context).scale(16) > 24;
    return OnboardingV2PageShell(
      brandLatin: copy.brandLatin,
      brandKorean: copy.brandKorean,
      currentStep: 7,
      totalSteps: 7,
      progressLabel: progress,
      showStage: false,
      heading: OnboardingV2Heading(
        eyebrow: companionCopy.eyebrow,
        title: compactHeading ? companionCopy.eyebrow : companionCopy.title,
        body: companionCopy.body,
        showBody: false,
        announcementLabel: '$progress. ${companionCopy.title}',
      ),
      bodyKey: const ValueKey('onboarding-v2-companion-scroll'),
      body: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: OnboardingCompanionStage(
                companions: companionCopy.companions,
                selectedCompanionId: selectedCompanionId,
                onCompanionChanged: onCompanionChanged,
                showDescription:
                    constraints.maxHeight >= 300 &&
                    MediaQuery.textScalerOf(context).scale(16) <= 24,
              ),
            ),
            if (constraints.maxHeight >= 650) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                companionCopy.body,
                textAlign: TextAlign.center,
                style: text.body,
              ),
            ],
            OnboardingV2DetailsButton(
              key: const ValueKey('onboarding-v2-companion-details'),
              label: AppL10n.of(context).onboardingV2DetailsAction,
              sheetTitle: companionCopy.title,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    companionCopy.title,
                    textAlign: TextAlign.center,
                    style: text.h3,
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    companionCopy.body,
                    textAlign: TextAlign.center,
                    style: text.body,
                  ),
                  const SizedBox(height: Spacing.md),
                  for (final companion in companionCopy.companions) ...[
                    Text(
                      '${companion.name} · ${companion.koreanName}',
                      textAlign: TextAlign.center,
                      style: text.h2,
                    ),
                    Text(
                      companion.rhythm,
                      textAlign: TextAlign.center,
                      style: text.cardTitle,
                    ),
                    Text(
                      companion.body,
                      textAlign: TextAlign.center,
                      style: text.body,
                    ),
                    const SizedBox(height: Spacing.md),
                  ],
                  Text(
                    companionCopy.equalLearningNote,
                    key: const ValueKey(
                      'onboarding-v2-companion-equal-learning-note',
                    ),
                    textAlign: TextAlign.center,
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      footer: OnboardingV2FooterActions(
        backKey: const ValueKey('onboarding-v2-companion-back'),
        backLabel: copy.navigation.back,
        onBack: onBack,
        primaryAction: SoriButton.filled(
          key: const ValueKey('onboarding-v2-companion-continue'),
          label: companionCopy.continueAction,
          trailingIcon: MediaQuery.textScalerOf(context).scale(16) > 24
              ? null
              : Icons.arrow_forward_rounded,
          fullWidth: true,
          size: SoriButtonSize.md,
          onTap: selectedCompanionId == null
              ? null
              : () => onContinue(selectedCompanionId!),
        ),
      ),
    );
  }
}

typedef CompanionPreviewBuilder =
    Widget Function(BuildContext context, String companionId);

/// Confirmation is deliberately independent from the choose-video lifecycle.
/// The optional [previewBuilder] is decorative and pointer-inert; only the
/// persistent CTA invokes [onStart]. A failed or stalled preview therefore
/// cannot trap the learner.
class OnboardingCompanionConfirmationScreen extends StatefulWidget {
  const OnboardingCompanionConfirmationScreen({
    super.key,
    required this.copy,
    required this.companionId,
    required this.onStart,
    required this.onChange,
    this.previewBuilder,
  });

  final OnboardingV2Copy copy;
  final String companionId;
  final VoidCallback onStart;
  final VoidCallback onChange;
  final CompanionPreviewBuilder? previewBuilder;

  @override
  State<OnboardingCompanionConfirmationScreen> createState() =>
      _OnboardingCompanionConfirmationScreenState();
}

class _OnboardingCompanionConfirmationScreenState
    extends State<OnboardingCompanionConfirmationScreen> {
  final FocusNode _headingFocus = FocusNode(
    debugLabel: 'onboarding-v2-companion-confirmation-heading',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _headingFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _headingFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companionCopy = widget.copy.companion;
    final companion = companionCopy.companion(widget.companionId);
    final text = SoriTextTheme.of(context);
    final isJoy = companion.id == OnboardingV2Ids.companionJoy;
    final progress = widget.copy.navigation.progress(7, 7);
    final preview =
        widget.previewBuilder?.call(context, companion.id) ??
        OnboardingCharacterMedia(
          characterId: isJoy ? 'magpie' : 'tiger',
          motion: OnboardingCharacterMotion.confirm,
          size: 320,
        );

    return OnboardingV2PageShell(
      brandLatin: widget.copy.brandLatin,
      brandKorean: widget.copy.brandKorean,
      currentStep: 7,
      totalSteps: 7,
      progressLabel: progress,
      showStage: false,
      bodyKey: const ValueKey('onboarding-v2-confirmation-scroll'),
      heading: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Focus(
            focusNode: _headingFocus,
            child: Semantics(
              key: const ValueKey('onboarding-v2-confirmation-live-heading'),
              header: true,
              liveRegion: true,
              focusable: true,
              label: '$progress. ${companion.selectedMessage}',
              child: ExcludeSemantics(
                child: Text(
                  companion.selectedMessage,
                  textAlign: TextAlign.center,
                  style: text.h1,
                ),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: OnboardingConfirmationStage(
                key: const ValueKey('onboarding-v2-confirmation-hero'),
                companion: companion,
                preview: preview,
              ),
            ),
            if (constraints.maxHeight >= 420 &&
                MediaQuery.textScalerOf(context).scale(16) <= 24) ...[
              const SizedBox(height: Spacing.md),
              Text(
                companionCopy.confirmationBody,
                textAlign: TextAlign.center,
                style: text.body,
              ),
            ],
            OnboardingV2DetailsButton(
              key: const ValueKey('onboarding-v2-confirmation-details'),
              label: AppL10n.of(context).onboardingV2DetailsAction,
              sheetTitle: companion.selectedMessage,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    companionCopy.confirmationBody,
                    textAlign: TextAlign.center,
                    style: text.body,
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    companion.rhythm,
                    textAlign: TextAlign.center,
                    style: text.cardTitle,
                  ),
                  Text(
                    companion.body,
                    textAlign: TextAlign.center,
                    style: text.body,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      footer: OnboardingV2FooterActions(
        backKey: const ValueKey('onboarding-v2-confirmation-change'),
        backLabel: widget.copy.navigation.back,
        backSemanticLabel: companionCopy.changeAction,
        onBack: widget.onChange,
        primaryAction: SoriButton.filled(
          key: const ValueKey('onboarding-v2-confirmation-start'),
          label: companionCopy.startAction,
          fullWidth: true,
          size: SoriButtonSize.md,
          onTap: widget.onStart,
        ),
      ),
    );
  }
}
