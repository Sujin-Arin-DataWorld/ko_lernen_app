import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart'
    show AttributedString, LocaleStringAttribute;

import '../../widgets/sori/button.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/mascot.dart';
import '../../widgets/sori/tokens.dart';
import 'onboarding_v2_presentation.dart';
import 'onboarding_v2_shell.dart';

class OnboardingCompanionScreen extends StatelessWidget {
  const OnboardingCompanionScreen({
    super.key,
    required this.copy,
    required this.selectedCompanionId,
    required this.onCompanionChanged,
    required this.onContinue,
  });

  final OnboardingV2Copy copy;
  final String? selectedCompanionId;
  final ValueChanged<String> onCompanionChanged;
  final ValueChanged<String> onContinue;

  @override
  Widget build(BuildContext context) {
    assert(copy.companion.companions.length == 2);
    final companionCopy = copy.companion;
    final text = SoriTextTheme.of(context);
    return OnboardingV2PageShell(
      bodyKey: const ValueKey('onboarding-v2-companion-scroll'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingV2Heading(
            eyebrow: companionCopy.eyebrow,
            title: companionCopy.title,
            body: companionCopy.body,
          ),
          const SizedBox(height: Spacing.lg),
          SoriCard(
            accent: SoriColors.highlight,
            tinted: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.balance_rounded, color: SoriColors.highlight),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(
                    companionCopy.equalLearningNote,
                    style: text.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xl),
          for (final companion in companionCopy.companions) ...[
            _CompanionTile(
              companion: companion,
              selected: companion.id == selectedCompanionId,
              onTap: () => onCompanionChanged(companion.id),
            ),
            if (companion != companionCopy.companions.last)
              const SizedBox(height: Spacing.md),
          ],
        ],
      ),
      footer: SoriButton.filled(
        key: const ValueKey('onboarding-v2-companion-continue'),
        label: companionCopy.continueAction,
        trailingIcon: Icons.arrow_forward_rounded,
        fullWidth: true,
        onTap: selectedCompanionId == null
            ? null
            : () => onContinue(selectedCompanionId!),
      ),
    );
  }
}

class _CompanionTile extends StatelessWidget {
  const _CompanionTile({
    required this.companion,
    required this.selected,
    required this.onTap,
  });

  final OnboardingCompanionSpec companion;
  final bool selected;
  final VoidCallback onTap;

  MascotKind get _kind => companion.id == OnboardingV2Ids.companionJoy
      ? MascotKind.magpie
      : MascotKind.tiger;

  Color get _accent => companion.id == OnboardingV2Ids.companionJoy
      ? SoriColors.primary
      : SoriColors.tigerOnLight;

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    final portrait = DecoratedBox(
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(SoriRadius.md),
      ),
      child: SizedBox(
        width: 112,
        height: 112,
        child: Center(
          child: Mascot(
            kind: _kind,
            emotion: MascotEmotion.smile,
            size: 100,
            animate: false,
          ),
        ),
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: companion.name,
            style: text.h3,
            children: [
              TextSpan(
                text: '  ${companion.koreanName}',
                locale: const Locale('ko'),
                style: text.cardSubtitle,
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(companion.rhythm, style: text.label.copyWith(color: _accent)),
        const SizedBox(height: Spacing.sm),
        Text(companion.body, style: text.bodySmall),
      ],
    );
    final selectionIcon = Icon(
      selected
          ? Icons.check_circle_rounded
          : Icons.radio_button_unchecked_rounded,
      color: selected ? _accent : SoriSurfaces.of(context).textDim,
    );
    return Semantics(
      key: ValueKey('onboarding-v2-companion-semantics-${companion.id}'),
      button: true,
      enabled: true,
      selected: selected,
      attributedLabel: _companionSemanticLabel(companion),
      onTap: onTap,
      excludeSemantics: true,
      child: SoriCard(
        key: ValueKey('onboarding-v2-companion-${companion.id}'),
        variant: SoriCardVariant.hero,
        selectable: true,
        selected: selected,
        onTap: onTap,
        child: ExcludeSemantics(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < SoriBreakpoints.contentActionStack) {
                return Column(
                  children: [
                    portrait,
                    const SizedBox(height: Spacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: details),
                        const SizedBox(width: Spacing.sm),
                        selectionIcon,
                      ],
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  portrait,
                  const SizedBox(width: Spacing.lg),
                  Expanded(child: details),
                  const SizedBox(width: Spacing.sm),
                  selectionIcon,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

AttributedString _companionSemanticLabel(OnboardingCompanionSpec companion) {
  final prefix = '${companion.name}. ';
  final label =
      '$prefix${companion.koreanName}. ${companion.rhythm}. ${companion.body}';
  return AttributedString(
    label,
    attributes: [
      LocaleStringAttribute(
        locale: const Locale('ko'),
        range: TextRange(
          start: prefix.length,
          end: prefix.length + companion.koreanName.length,
        ),
      ),
    ],
  );
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

    return OnboardingV2PageShell(
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
          const SizedBox(height: Spacing.xl),
          ExcludeSemantics(
            child: SoriCard(
              key: const ValueKey('onboarding-v2-confirmation-hero'),
              variant: SoriCardVariant.hero,
              accent: accent,
              tinted: true,
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(SoriRadius.lg),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: accent.withValues(alpha: 0.08)),
                      if (showPreview)
                        IgnorePointer(
                          child: widget.previewBuilder!(context, companion.id),
                        ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(Spacing.lg),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: SoriCard.resolvedBackground(context),
                              shape: BoxShape.circle,
                              boxShadow: SoriElevation.low,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(Spacing.sm),
                              child: Mascot(
                                kind: kind,
                                emotion: MascotEmotion.smile,
                                size: 104,
                                animate: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
            onTap: widget.onStart,
          ),
          const SizedBox(height: Spacing.xs),
          TextButton(
            key: const ValueKey('onboarding-v2-confirmation-change'),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: widget.onChange,
            child: Text(companionCopy.changeAction),
          ),
        ],
      ),
    );
  }
}
