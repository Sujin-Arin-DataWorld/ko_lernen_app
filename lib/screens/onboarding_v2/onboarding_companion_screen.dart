import 'package:flutter/material.dart';

import '../../widgets/sori/button.dart';
import '../../widgets/sori/mascot.dart';
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
    final selected = selectedCompanionId == null
        ? null
        : companionCopy.companion(selectedCompanionId!);
    final progress = copy.navigation.progress(7, 7);
    return OnboardingV2PageShell(
      currentStep: 7,
      totalSteps: 7,
      progressLabel: progress,
      stageKey: ValueKey(
        'onboarding-v2-companion-stage-${selectedCompanionId ?? 'empty'}',
      ),
      stage: OnboardingCompanionStage(
        companions: companionCopy.companions,
        selectedCompanionId: selectedCompanionId,
        onCompanionChanged: onCompanionChanged,
      ),
      bodyKey: const ValueKey('onboarding-v2-companion-scroll'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingV2Heading(
            eyebrow: companionCopy.eyebrow,
            title: companionCopy.title,
            body: companionCopy.body,
            announcementLabel: '$progress. ${companionCopy.title}',
          ),
          if (selected != null) ...[
            const SizedBox(height: Spacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(vertical: Spacing.md),
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(
                    color: SoriSurfaces.of(context).border,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    selected.id == OnboardingV2Ids.companionJoy
                        ? Icons.auto_awesome_rounded
                        : Icons.route_rounded,
                    color: selected.id == OnboardingV2Ids.companionTaego
                        ? SoriColors.tigerOnLight
                        : SoriColors.primary,
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(selected.rhythm, style: text.cardTitle),
                        const SizedBox(height: Spacing.xs),
                        Text(selected.body, style: text.cardSubtitle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: Spacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.balance_rounded,
                size: 20,
                color: SoriColors.highlight,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  key: const ValueKey(
                    'onboarding-v2-companion-equal-learning-note',
                  ),
                  companionCopy.equalLearningNote,
                  style: text.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
      footer: LayoutBuilder(
        builder: (context, constraints) {
          final back = SoriButton.outlined(
            key: const ValueKey('onboarding-v2-companion-back'),
            label: copy.navigation.back,
            fullWidth: true,
            maxLines: 1,
            onTap: onBack,
          );
          final next = SoriButton.filled(
            key: const ValueKey('onboarding-v2-companion-continue'),
            label: companionCopy.continueAction,
            trailingIcon: Icons.arrow_forward_rounded,
            fullWidth: true,
            maxLines: 1,
            onTap: selectedCompanionId == null
                ? null
                : () => onContinue(selectedCompanionId!),
          );
          if (constraints.maxWidth < SoriBreakpoints.contentActionStack) {
            return Column(
              children: [
                next,
                const SizedBox(height: Spacing.sm),
                back,
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 4, child: back),
              const SizedBox(width: Spacing.md),
              Expanded(flex: 6, child: next),
            ],
          );
        },
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
    final kind = companion.id == OnboardingV2Ids.companionJoy
        ? MascotKind.magpie
        : MascotKind.tiger;
    final accent = companion.id == OnboardingV2Ids.companionJoy
        ? SoriColors.primary
        : SoriColors.tigerOnLight;
    final showPreview =
        widget.previewBuilder != null && !SoriMotion.reduceMotion(context);
    final progress = widget.copy.navigation.progress(7, 7);
    final preview = showPreview
        ? widget.previewBuilder!(context, companion.id)
        : Mascot(
            kind: kind,
            emotion: MascotEmotion.smile,
            size: 220,
            animate: false,
          );

    return OnboardingV2PageShell(
      currentStep: 7,
      totalSteps: 7,
      progressLabel: progress,
      stageKey: ValueKey('onboarding-v2-confirmation-stage-${companion.id}'),
      stage: OnboardingConfirmationStage(
        key: const ValueKey('onboarding-v2-confirmation-hero'),
        companion: companion,
        preview: preview,
      ),
      bodyKey: const ValueKey('onboarding-v2-confirmation-scroll'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            companionCopy.confirmationEyebrow.toUpperCase(),
            style: text.eyebrow,
          ),
          const SizedBox(height: Spacing.sm),
          Focus(
            focusNode: _headingFocus,
            child: Semantics(
              key: const ValueKey('onboarding-v2-confirmation-live-heading'),
              header: true,
              liveRegion: true,
              focusable: true,
              label: companion.selectedMessage,
              child: ExcludeSemantics(
                child: Text(companion.selectedMessage, style: text.h1),
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
          Text(companionCopy.confirmationBody, style: text.body),
          const SizedBox(height: Spacing.lg),
          Container(
            key: const ValueKey('onboarding-v2-confirmation-details'),
            padding: const EdgeInsets.symmetric(vertical: Spacing.md),
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: SoriSurfaces.of(context).border),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  kind == MascotKind.magpie
                      ? Icons.auto_awesome_rounded
                      : Icons.route_rounded,
                  color: accent,
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(companion.rhythm, style: text.cardTitle),
                      const SizedBox(height: Spacing.xs),
                      Text(companion.body, style: text.cardSubtitle),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SoriButton.filled(
            key: const ValueKey('onboarding-v2-confirmation-start'),
            label: companionCopy.startAction,
            trailingIcon: Icons.arrow_forward_rounded,
            fullWidth: true,
            maxLines: 1,
            onTap: widget.onStart,
          ),
          const SizedBox(height: Spacing.xs),
          SoriButton.ghost(
            key: const ValueKey('onboarding-v2-confirmation-change'),
            label: companionCopy.changeAction,
            fullWidth: true,
            maxLines: 1,
            onTap: widget.onChange,
          ),
        ],
      ),
    );
  }
}
