import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart'
    show AttributedString, LocaleStringAttribute;

import '../../widgets/sori/pressable.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/window_class.dart';
import 'onboarding_character_media.dart';
import 'onboarding_v2_presentation.dart';

/// Decorative artwork never substitutes for the interactive learning surface.
/// Preserve the complete composition; no crop, tint or duplicate caption.
class OnboardingStoryStage extends StatelessWidget {
  const OnboardingStoryStage({
    super.key,
    required this.page,
    this.questComplete = false,
  });
  final OnboardingStoryPageSpec page;
  final bool questComplete;

  @override
  Widget build(BuildContext context) {
    final asset = switch (page.visualKind) {
      OnboardingStoryVisualKind.personalCurriculum =>
        'assets/illustrations/hanok/gate_final.png',
      OnboardingStoryVisualKind.learn =>
        'assets/illustrations/hanok/study_scholar.png',
      OnboardingStoryVisualKind.saveAndReview =>
        'assets/illustrations/activities/srs.webp',
      OnboardingStoryVisualKind.gamesAndRewards =>
        questComplete
            ? 'assets/illustrations/reward/reward_bojagi_open.png'
            : 'assets/illustrations/reward/reward_bojagi_closed.png',
      OnboardingStoryVisualKind.heritageJourney =>
        'assets/illustrations/personal_hanok_v3/world/main-gate.png',
    };
    final nativeGate =
        page.visualKind == OnboardingStoryVisualKind.heritageJourney;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return Semantics(
      image: true,
      label: page.heroSemanticLabel,
      child: ExcludeSemantics(
        child: Center(
          child: ConstrainedBox(
            constraints: nativeGate
                ? BoxConstraints(
                    maxWidth: 1100 / pixelRatio,
                    maxHeight: 733 / pixelRatio,
                  )
                : const BoxConstraints(),
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }
}

/// Kept for callers outside the journey. Setup itself is an input-led surface.
class OnboardingSetupStage extends StatelessWidget {
  const OnboardingSetupStage({
    super.key,
    required this.copy,
    required this.choosingLevel,
    required this.selectedPurposeTitle,
  });
  final OnboardingSetupCopy copy;
  final bool choosingLevel;
  final String? selectedPurposeTitle;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/illustrations/hanok/madang(light).png',
    fit: BoxFit.contain,
    semanticLabel: choosingLevel ? copy.levelHeading : copy.purposeHeading,
  );
}

class OnboardingCompanionStage extends StatefulWidget {
  const OnboardingCompanionStage({
    super.key,
    required this.companions,
    required this.selectedCompanionId,
    required this.onCompanionChanged,
    this.showDescription = true,
  });
  final List<OnboardingCompanionSpec> companions;
  final String? selectedCompanionId;
  final ValueChanged<String> onCompanionChanged;
  final bool showDescription;
  @override
  State<OnboardingCompanionStage> createState() =>
      _OnboardingCompanionStageState();
}

class _OnboardingCompanionStageState extends State<OnboardingCompanionStage> {
  int _replay = 0;
  @override
  Widget build(BuildContext context) {
    // Comparison order is a product contract, independent of catalog ordering.
    final ordered = [
      widget.companions.firstWhere(
        (c) => c.id == OnboardingV2Ids.companionTaego,
      ),
      widget.companions.firstWhere((c) => c.id == OnboardingV2Ids.companionJoy),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, companion) in ordered.indexed) ...[
          if (index > 0) const SizedBox(width: Spacing.md),
          Expanded(
            child: _CompanionStageChoice(
              companion: companion,
              selected: companion.id == widget.selectedCompanionId,
              replayToken: _replay,
              showDescription: widget.showDescription,
              onTap: () {
                setState(() => _replay++);
                widget.onCompanionChanged(companion.id);
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _CompanionStageChoice extends StatelessWidget {
  const _CompanionStageChoice({
    required this.companion,
    required this.selected,
    required this.replayToken,
    required this.onTap,
    required this.showDescription,
  });
  final OnboardingCompanionSpec companion;
  final bool selected;
  final int replayToken;
  final bool showDescription;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    final text = SoriTextTheme.of(context);
    final isJoy = companion.id == OnboardingV2Ids.companionJoy;
    return Semantics(
      key: ValueKey('onboarding-v2-companion-semantics-${companion.id}'),
      button: true,
      enabled: true,
      selected: selected,
      attributedLabel: _companionSemanticLabel(companion),
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: SoriPressable(
          key: ValueKey('onboarding-v2-companion-${companion.id}'),
          onTap: onTap,
          child: AnimatedContainer(
            duration: SoriMotion.respect(
              context,
              const Duration(milliseconds: 180),
            ),
            padding: const EdgeInsets.all(Spacing.sm),
            decoration: BoxDecoration(
              color: selected ? surfaces.surfaceAlt : surfaces.bg,
              borderRadius: BorderRadius.circular(SoriRadius.md),
              border: Border.all(
                color: selected ? SoriColors.primary : surfaces.border,
                width: 2,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactNames =
                    constraints.maxWidth < SoriAdaptiveWidth.companionNameRow &&
                    MediaQuery.textScalerOf(context).scale(16) > 24;
                final artwork = Stack(
                  fit: StackFit.expand,
                  children: [
                    LayoutBuilder(
                      builder: (context, artConstraints) =>
                          OnboardingCharacterMedia(
                            characterId: isJoy ? 'magpie' : 'tiger',
                            size: artConstraints.biggest.shortestSide,
                            active: selected,
                            motion: selected
                                ? OnboardingCharacterMotion.select
                                : OnboardingCharacterMotion.idle,
                            replayToken: replayToken,
                          ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: selected ? SoriColors.primary : surfaces.textDim,
                        size: 24,
                      ),
                    ),
                  ],
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: constraints.hasBoundedHeight
                      ? MainAxisSize.max
                      : MainAxisSize.min,
                  children: [
                    if (constraints.hasBoundedHeight)
                      Expanded(child: artwork)
                    else
                      AspectRatio(aspectRatio: 1, child: artwork),
                    const SizedBox(height: Spacing.sm),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: Spacing.sm,
                      children: [
                        Text(
                          companion.name,
                          textAlign: TextAlign.center,
                          style: text.h2,
                        ),
                        if (!compactNames)
                          Text(
                            companion.koreanName,
                            locale: const Locale('ko'),
                            textAlign: TextAlign.center,
                            style: text.meta,
                          ),
                      ],
                    ),
                    if (showDescription) ...[
                      const SizedBox(height: Spacing.sm),
                      Text(
                        companion.rhythm,
                        textAlign: TextAlign.center,
                        style: text.bodySmall,
                      ),
                      if (constraints.maxHeight >= 520) ...[
                        const SizedBox(height: Spacing.sm),
                        Text(
                          companion.body,
                          textAlign: TextAlign.center,
                          style: text.bodySmall,
                        ),
                      ],
                    ],
                    const SizedBox(height: Spacing.sm),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingConfirmationStage extends StatelessWidget {
  const OnboardingConfirmationStage({
    super.key,
    required this.companion,
    required this.preview,
  });
  final OnboardingCompanionSpec companion;
  final Widget preview;
  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: '${companion.name}. ${companion.rhythm}',
    child: ExcludeSemantics(
      child: Column(
        children: [
          Expanded(child: IgnorePointer(child: preview)),
          const SizedBox(height: Spacing.sm),
          Text(
            '${companion.name}  ${companion.koreanName}',
            textAlign: TextAlign.center,
            style: SoriTextTheme.of(context).h2,
          ),
        ],
      ),
    ),
  );
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
