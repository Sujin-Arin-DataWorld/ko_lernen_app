import 'package:flutter/material.dart';

import '../../widgets/sori/button.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/sheet.dart';
import '../../widgets/sori/tokens.dart';
import 'onboarding_v2_presentation.dart';
import 'onboarding_v2_shell.dart';

/// Combined motivation and CEFR starting-point selection.
///
/// Both values are controlled by the coordinator. Choosing a tile only emits
/// draft intent; this presentation layer never changes placement or mastery.
class OnboardingSetupScreen extends StatelessWidget {
  const OnboardingSetupScreen({
    super.key,
    required this.copy,
    required this.selectedPurposeId,
    required this.selectedLevelCode,
    required this.onPurposeChanged,
    required this.onLevelChanged,
    required this.onContinue,
  });

  final OnboardingV2Copy copy;
  final String? selectedPurposeId;
  final String? selectedLevelCode;
  final ValueChanged<String> onPurposeChanged;
  final ValueChanged<String> onLevelChanged;
  final ValueChanged<OnboardingSetupSelection> onContinue;

  OnboardingLevelSpec? get _selectedLevel {
    for (final level in copy.setup.levels) {
      if (level.code == selectedLevelCode) {
        return level;
      }
    }
    return null;
  }

  bool get _canContinue =>
      selectedPurposeId != null && selectedLevelCode != null;

  @override
  Widget build(BuildContext context) {
    assert(copy.setup.purposes.length == 4);
    assert(copy.setup.levels.length == 6);
    final setup = copy.setup;
    final text = SoriTextTheme.of(context);
    final selectedLevel = _selectedLevel;

    return OnboardingV2PageShell(
      bodyKey: const ValueKey('onboarding-v2-setup-scroll'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingV2Heading(
            eyebrow: setup.eyebrow,
            title: setup.title,
            body: setup.body,
          ),
          const SizedBox(height: Spacing.xl),
          Semantics(
            header: true,
            child: Text(setup.purposeHeading, style: text.h2),
          ),
          const SizedBox(height: Spacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - Spacing.md) / 2;
              return Wrap(
                spacing: Spacing.md,
                runSpacing: Spacing.md,
                children: [
                  for (final purpose in setup.purposes)
                    SizedBox(
                      width: tileWidth,
                      child: _PurposeTile(
                        purpose: purpose,
                        selected: purpose.id == selectedPurposeId,
                        onTap: () => onPurposeChanged(purpose.id),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: Spacing.xxl),
          Semantics(
            header: true,
            child: Text(setup.levelHeading, style: text.h2),
          ),
          const SizedBox(height: Spacing.xs),
          Text(setup.levelHelp, style: text.bodySmall),
          const SizedBox(height: Spacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - Spacing.md) / 2;
              return Wrap(
                spacing: Spacing.md,
                runSpacing: Spacing.md,
                children: [
                  for (final level in setup.levels)
                    SizedBox(
                      width: tileWidth,
                      child: _LevelTile(
                        level: level,
                        selected: level.code == selectedLevelCode,
                        onTap: () => onLevelChanged(level.code),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: Spacing.md),
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              key: const ValueKey('onboarding-v2-level-compare'),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: SoriColors.primaryOnLight,
              ),
              onPressed: () => _showLevelComparison(context),
              icon: const Icon(Icons.compare_arrows_rounded),
              label: Text(setup.compareAction),
            ),
          ),
          const SizedBox(height: Spacing.md),
          if (selectedLevel == null)
            SoriCard(
              key: const ValueKey('onboarding-v2-level-prompt'),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.touch_app_outlined,
                    color: SoriColors.primary,
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Text(setup.selectLevelPrompt, style: text.body),
                  ),
                ],
              ),
            )
          else
            _SelectedLevelCard(level: selectedLevel, copy: setup),
        ],
      ),
      footer: SoriButton.filled(
        key: const ValueKey('onboarding-v2-setup-continue'),
        label: setup.continueAction,
        trailingIcon: Icons.arrow_forward_rounded,
        fullWidth: true,
        onTap: !_canContinue
            ? null
            : () => onContinue(
                OnboardingSetupSelection(
                  purposeId: selectedPurposeId!,
                  levelCode: selectedLevelCode!,
                ),
              ),
      ),
    );
  }

  Future<void> _showLevelComparison(BuildContext context) =>
      showOnboardingV2ModalWithFocusRestore(
        () => showSoriSheet<void>(
          context: context,
          scrollable: false,
          maxHeightFactor: 0.95,
          maxTextScaleFactor: 2.0,
          builder: (context) => _LevelComparisonSheet(copy: copy.setup),
        ),
      );
}

class _PurposeTile extends StatelessWidget {
  const _PurposeTile({
    required this.purpose,
    required this.selected,
    required this.onTap,
  });

  final OnboardingPurposeSpec purpose;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    return SoriCard(
      key: ValueKey('onboarding-v2-purpose-${purpose.id}'),
      variant: SoriCardVariant.compact,
      selectable: true,
      selected: selected,
      onTap: onTap,
      semanticLabel: '${purpose.title}. ${purpose.body}',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 104),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    purpose.icon,
                    color: selected
                        ? SoriColors.primary
                        : SoriSurfaces.of(context).textMuted,
                  ),
                  const Spacer(),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected
                        ? SoriColors.primary
                        : SoriSurfaces.of(context).textDim,
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              Text(purpose.title, style: text.cardTitle),
              const SizedBox(height: Spacing.xs),
              Text(purpose.body, style: text.cardSubtitle),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final OnboardingLevelSpec level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    return SoriCard(
      key: ValueKey('onboarding-v2-level-${level.code}'),
      variant: SoriCardVariant.compact,
      selectable: true,
      selected: selected,
      onTap: onTap,
      semanticLabel: '${level.code}. ${level.name}',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Text(
                level.code,
                style: text.h3.copyWith(
                  color: selected ? SoriColors.primary : null,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(child: Text(level.name, style: text.cardSubtitle)),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 22,
                color: selected
                    ? SoriColors.primary
                    : SoriSurfaces.of(context).textDim,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedLevelCard extends StatelessWidget {
  const _SelectedLevelCard({required this.level, required this.copy});

  final OnboardingLevelSpec level;
  final OnboardingSetupCopy copy;

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    return SoriCard(
      key: const ValueKey('onboarding-v2-selected-level'),
      variant: SoriCardVariant.hero,
      accent: SoriColors.primary,
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy.exampleLabel, style: text.label),
          const SizedBox(height: Spacing.sm),
          Text(
            level.exampleKorean,
            key: const ValueKey('onboarding-v2-level-example-ko'),
            locale: const Locale('ko'),
            style: text.koDisplay,
          ),
          const SizedBox(height: Spacing.xs),
          Text(level.exampleTranslation, style: text.gloss),
          const SizedBox(height: Spacing.lg),
          Text(copy.canDoLabel, style: text.label),
          const SizedBox(height: Spacing.xs),
          Text(level.canDo, style: text.body),
          const SizedBox(height: Spacing.md),
          Text(copy.learnHereLabel, style: text.label),
          const SizedBox(height: Spacing.xs),
          Text(level.learnHere, style: text.bodySmall),
        ],
      ),
    );
  }
}

class _LevelComparisonSheet extends StatelessWidget {
  const _LevelComparisonSheet({required this.copy});

  final OnboardingSetupCopy copy;

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SoriContentClamp(
                base: const EdgeInsets.fromLTRB(
                  Spacing.xl,
                  Spacing.sm,
                  Spacing.xl,
                  Spacing.xl,
                ),
                builder: (context, padding) => ListView(
                  controller: scrollController,
                  padding: padding,
                  children: [
                    Focus(
                      debugLabel: 'onboarding-v2-level-comparison-heading',
                      autofocus: true,
                      child: Semantics(
                        header: true,
                        focusable: true,
                        child: Text(copy.compareTitle, style: text.h1),
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(copy.compareBody, style: text.body),
                    const SizedBox(height: Spacing.xl),
                    for (final level in copy.levels) ...[
                      SoriCard(
                        key: ValueKey(
                          'onboarding-v2-level-compare-${level.code}',
                        ),
                        variant: SoriCardVariant.compact,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${level.code} · ${level.name}',
                              style: text.h3,
                            ),
                            const SizedBox(height: Spacing.sm),
                            Text(copy.canDoLabel, style: text.label),
                            const SizedBox(height: Spacing.xs),
                            Text(level.canDo, style: text.bodySmall),
                            const SizedBox(height: Spacing.sm),
                            Text(copy.learnHereLabel, style: text.label),
                            const SizedBox(height: Spacing.xs),
                            Text(level.learnHere, style: text.bodySmall),
                          ],
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                    ],
                  ],
                ),
              ),
            ),
            SoriContentClamp(
              base: const EdgeInsets.fromLTRB(
                Spacing.xl,
                Spacing.sm,
                Spacing.xl,
                Spacing.md,
              ),
              builder: (context, padding) => Padding(
                padding: padding,
                child: SoriButton.filled(
                  key: const ValueKey('onboarding-v2-level-compare-close'),
                  label: copy.compareClose,
                  fullWidth: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
