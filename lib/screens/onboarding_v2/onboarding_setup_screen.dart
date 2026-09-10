import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

import '../../widgets/sori/button.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/pressable.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/window_class.dart';
import 'onboarding_v2_presentation.dart';
import 'onboarding_v2_shell.dart';

/// Combined motivation and CEFR starting-point selection.
///
/// Both values are controlled by the coordinator. Choosing a tile only emits
/// draft intent; this presentation layer never changes placement or mastery.
class OnboardingSetupScreen extends StatefulWidget {
  const OnboardingSetupScreen({
    super.key,
    required this.copy,
    required this.selectedPurposeId,
    required this.selectedLevelCode,
    required this.onPurposeChanged,
    required this.onLevelChanged,
    required this.onContinue,
    this.onBack,
  });

  final OnboardingV2Copy copy;
  final String? selectedPurposeId;
  final String? selectedLevelCode;
  final ValueChanged<String> onPurposeChanged;
  final ValueChanged<String> onLevelChanged;
  final ValueChanged<OnboardingSetupSelection> onContinue;
  final VoidCallback? onBack;

  @override
  State<OnboardingSetupScreen> createState() => _OnboardingSetupScreenState();
}

class _OnboardingSetupScreenState extends State<OnboardingSetupScreen> {
  late bool _choosingLevel;
  final ScrollController _scrollController = ScrollController();

  OnboardingV2Copy get copy => widget.copy;
  String? get selectedPurposeId => widget.selectedPurposeId;
  String? get selectedLevelCode => widget.selectedLevelCode;

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
  void initState() {
    super.initState();
    _choosingLevel = selectedPurposeId != null;
  }

  @override
  void didUpdateWidget(covariant OnboardingSetupScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (selectedPurposeId == null && _choosingLevel) {
      _choosingLevel = false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showPurpose() {
    setState(() => _choosingLevel = false);
    _resetScroll();
  }

  void _showLevel() {
    if (selectedPurposeId == null) {
      return;
    }
    setState(() => _choosingLevel = true);
    _resetScroll();
  }

  void _resetScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(copy.setup.purposes.length == 4);
    assert(copy.setup.levels.length == 6);
    final setup = copy.setup;
    final text = SoriTextTheme.of(context);
    final selectedLevel = _selectedLevel;
    final progress = copy.navigation.progress(6, 7);

    return OnboardingV2PageShell(
      brandLatin: copy.brandLatin,
      brandKorean: copy.brandKorean,
      currentStep: 6,
      totalSteps: 7,
      progressLabel: progress,
      showStage: false,
      heading: OnboardingV2Heading(
        eyebrow: setup.eyebrow,
        title: _choosingLevel ? setup.levelHeading : setup.purposeHeading,
        body: _choosingLevel ? setup.levelHelp : setup.body,
        showBody: false,
        announcementLabel:
            '$progress. ${_choosingLevel ? setup.levelHeading : setup.purposeHeading}',
      ),
      bodyKey: const ValueKey('onboarding-v2-setup-scroll'),
      bodyScrollController: _scrollController,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final largeText = MediaQuery.textScalerOf(context).scale(16) > 24;
          final levelBudget =
              windowClassFor(constraints.maxWidth) == AppWindowClass.compact
              ? 460
              : 330;
          final compactChoice =
              largeText ||
              constraints.maxHeight < (_choosingLevel ? levelBudget : 300);
          final generous = constraints.maxHeight >= 600 && !largeText;
          return AnimatedSwitcher(
            duration: SoriMotion.respect(
              context,
              const Duration(milliseconds: 260),
            ),
            child: Column(
              key: ValueKey(
                _choosingLevel
                    ? 'onboarding-v2-setup-level-stage'
                    : 'onboarding-v2-setup-purpose-stage',
              ),
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_choosingLevel) ...[
                  if (compactChoice)
                    SoriButton.outlined(
                      key: const ValueKey('onboarding-v2-level-picker'),
                      label: selectedLevel == null
                          ? setup.levelHeading
                          : '${selectedLevel.code} · ${selectedLevel.name}',
                      semanticLabel: selectedLevel == null
                          ? setup.selectLevelPrompt
                          : null,
                      fullWidth: true,
                      onTap: () => _showLevelPicker(context),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, tileConstraints) {
                        final columns =
                            windowClassFor(tileConstraints.maxWidth) ==
                                AppWindowClass.compact
                            ? 2
                            : 3;
                        final tileWidth =
                            (tileConstraints.maxWidth -
                                Spacing.sm * (columns - 1)) /
                            columns;
                        return Wrap(
                          alignment: WrapAlignment.center,
                          spacing: Spacing.sm,
                          runSpacing: Spacing.sm,
                          children: [
                            for (final level in setup.levels)
                              SizedBox(
                                width: tileWidth,
                                child: _LevelTile(
                                  level: level,
                                  selected: level.code == selectedLevelCode,
                                  onTap: () =>
                                      widget.onLevelChanged(level.code),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  if (generous) ...[
                    const SizedBox(height: Spacing.md),
                    Text(
                      setup.levelHelp,
                      textAlign: TextAlign.center,
                      style: text.body,
                    ),
                  ],
                  const SizedBox(height: Spacing.sm),
                  if (compactChoice && largeText)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (selectedLevel != null)
                          Expanded(
                            child: OnboardingV2DetailsButton(
                              key: const ValueKey(
                                'onboarding-v2-level-example-action',
                              ),
                              label: AppL10n.of(
                                context,
                              ).onboardingV2DetailsAction,
                              sheetTitle: setup.exampleLabel,
                              child: _SelectedLevelCard(
                                level: selectedLevel,
                                copy: setup,
                              ),
                            ),
                          ),
                        IconButton(
                          key: const ValueKey('onboarding-v2-level-compare'),
                          tooltip: setup.compareAction,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                          onPressed: () => _showLevelComparison(context),
                          icon: const Icon(Icons.compare_arrows_rounded),
                        ),
                      ],
                    )
                  else ...[
                    if (selectedLevel != null)
                      OnboardingV2DetailsButton(
                        key: const ValueKey(
                          'onboarding-v2-level-example-action',
                        ),
                        label: setup.exampleLabel,
                        child: _SelectedLevelCard(
                          level: selectedLevel,
                          copy: setup,
                        ),
                      ),
                    TextButton.icon(
                      key: const ValueKey('onboarding-v2-level-compare'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        foregroundColor: SoriColors.primaryOnLight,
                      ),
                      onPressed: () => _showLevelComparison(context),
                      icon: const Icon(Icons.compare_arrows_rounded),
                      label: Text(
                        setup.compareAction,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ] else ...[
                  if (compactChoice)
                    SoriButton.outlined(
                      key: const ValueKey('onboarding-v2-purpose-picker'),
                      label: selectedPurposeId == null
                          ? setup.purposeHeading
                          : setup.purposes
                                .firstWhere((p) => p.id == selectedPurposeId)
                                .title,
                      fullWidth: true,
                      onTap: () => _showPurposePicker(context),
                    )
                  else
                    for (final purpose in setup.purposes)
                      _PurposeTile(
                        purpose: purpose,
                        selected: purpose.id == selectedPurposeId,
                        showBody: generous,
                        onTap: () => widget.onPurposeChanged(purpose.id),
                      ),
                  if (generous) ...[
                    const SizedBox(height: Spacing.md),
                    Text(
                      setup.body,
                      textAlign: TextAlign.center,
                      style: text.body,
                    ),
                  ],
                  OnboardingV2DetailsButton(
                    key: const ValueKey('onboarding-v2-purpose-details'),
                    label: AppL10n.of(context).onboardingV2DetailsAction,
                    sheetTitle: setup.purposeHeading,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          setup.body,
                          textAlign: TextAlign.center,
                          style: text.body,
                        ),
                        const SizedBox(height: Spacing.md),
                        for (final purpose in setup.purposes) ...[
                          Text(
                            purpose.title,
                            textAlign: TextAlign.center,
                            style: text.cardTitle,
                          ),
                          Text(
                            purpose.body,
                            textAlign: TextAlign.center,
                            style: text.body,
                          ),
                          const SizedBox(height: Spacing.md),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      footer: OnboardingV2FooterActions(
        backKey: const ValueKey('onboarding-v2-setup-back'),
        backLabel: copy.navigation.back,
        onBack: _choosingLevel ? _showPurpose : widget.onBack,
        primaryAction: SoriButton.filled(
          key: const ValueKey('onboarding-v2-setup-continue'),
          label: _choosingLevel ? setup.continueAction : copy.navigation.next,
          trailingIcon: MediaQuery.textScalerOf(context).scale(16) > 24
              ? null
              : Icons.arrow_forward_rounded,
          fullWidth: true,
          size: SoriButtonSize.md,
          onTap: _choosingLevel
              ? !_canContinue
                    ? null
                    : () => widget.onContinue(
                        OnboardingSetupSelection(
                          purposeId: selectedPurposeId!,
                          levelCode: selectedLevelCode!,
                        ),
                      )
              : selectedPurposeId == null
              ? null
              : _showLevel,
        ),
      ),
    );
  }

  Future<void> _showPurposePicker(BuildContext context) =>
      showOnboardingV2ModalWithFocusRestore(
        () => showOnboardingV2ReadingModal<void>(
          context: context,
          builder: (sheetContext) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Focus(
                autofocus: true,
                child: Semantics(
                  header: true,
                  child: Text(
                    copy.setup.purposeHeading,
                    textAlign: TextAlign.center,
                    style: SoriTextTheme.of(sheetContext).h2,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),
              for (final purpose in copy.setup.purposes)
                _PurposeTile(
                  purpose: purpose,
                  selected: purpose.id == selectedPurposeId,
                  onTap: () {
                    widget.onPurposeChanged(purpose.id);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              const SizedBox(height: Spacing.md),
              SoriButton.outlined(
                label: AppL10n.of(sheetContext).btnClose,
                fullWidth: true,
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
      );

  Future<void> _showLevelPicker(BuildContext context) =>
      showOnboardingV2ModalWithFocusRestore(
        () => showOnboardingV2ReadingModal<void>(
          context: context,
          builder: (sheetContext) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Focus(
                autofocus: true,
                child: Semantics(
                  header: true,
                  child: Text(
                    copy.setup.levelHeading,
                    textAlign: TextAlign.center,
                    style: SoriTextTheme.of(sheetContext).h2,
                  ),
                ),
              ),
              Text(
                copy.setup.levelHelp,
                textAlign: TextAlign.center,
                style: SoriTextTheme.of(sheetContext).body,
              ),
              const SizedBox(height: Spacing.md),
              for (final level in copy.setup.levels) ...[
                _LevelTile(
                  level: level,
                  selected: level.code == selectedLevelCode,
                  onTap: () {
                    widget.onLevelChanged(level.code);
                    Navigator.of(sheetContext).pop();
                  },
                ),
                const SizedBox(height: Spacing.sm),
              ],
              const SizedBox(height: Spacing.md),
              SoriButton.outlined(
                label: AppL10n.of(sheetContext).btnClose,
                fullWidth: true,
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
      );

  Future<void> _showLevelComparison(BuildContext context) =>
      showOnboardingV2ModalWithFocusRestore(
        () => showOnboardingV2ReadingModal<void>(
          context: context,
          scrollable: false,
          maxHeightFactor: 0.95,
          builder: (context) => _LevelComparisonSheet(copy: copy.setup),
        ),
      );
}

class _PurposeTile extends StatelessWidget {
  const _PurposeTile({
    required this.purpose,
    required this.selected,
    required this.onTap,
    this.showBody = true,
  });

  final OnboardingPurposeSpec purpose;
  final bool showBody;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    final surfaces = SoriSurfaces.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '${purpose.title}. ${purpose.body}',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: SoriPressable(
          key: ValueKey('onboarding-v2-purpose-${purpose.id}'),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.xs,
              vertical: Spacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: surfaces.border)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Icon(
                    purpose.icon,
                    color: selected ? SoriColors.primary : surfaces.textMuted,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        purpose.title,
                        textAlign: TextAlign.center,
                        style: text.cardTitle,
                      ),
                      if (showBody) ...[
                        const SizedBox(height: Spacing.xs),
                        Text(
                          purpose.body,
                          textAlign: TextAlign.center,
                          style: text.cardSubtitle,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? SoriColors.primary : surfaces.textDim,
                ),
              ],
            ),
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
      padding: const EdgeInsets.all(Spacing.sm),
      selectable: true,
      selected: selected,
      onTap: onTap,
      semanticLabel: '${level.code}. ${level.name}',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      level.code,
                      textAlign: TextAlign.center,
                      style: text.h3.copyWith(
                        color: selected ? SoriColors.primary : null,
                      ),
                    ),
                  ),
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
              const SizedBox(height: Spacing.xs),
              Text(
                level.name,
                textAlign: TextAlign.center,
                style: text.bodySmall,
                softWrap: true,
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
                  size: SoriButtonSize.md,
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
