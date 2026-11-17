import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/learner_level.dart';
import 'approved_chrome_assets.dart';
import 'c_learning_surface.dart';
import 'grammar_c.dart';
import 'pressable.dart';
import 'sheet.dart';
import 'tokens.dart';

/// The approved plan image is composed from independent art and native text.
/// Selection and persistence are owned by GrammarScreen.
Future<T?> showGrammarCPlanSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showSoriSheet<T>(
  context: context,
  maxHeightFactor: 1,
  presentation: const SoriSheetPresentation(
    backgroundColor: Colors.transparent,
  ),
  builder: (context) => SoriCMaterialSurface(
    borderRadius: BorderRadius.zero,
    raised: false,
    child: SafeArea(
      top: false,
      child: Column(
        children: [
          SoriCMaterialSurface(
            material: SoriCMaterial.jade,
            borderRadius: BorderRadius.zero,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Column(
                    children: [
                      Text(
                        AppL10n.of(context).screenGrammarTitle,
                        textAlign: TextAlign.center,
                        style: GrammarC.heading.copyWith(
                          fontSize: 23,
                          color: SoriCLearningTokens.paper,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const ApprovedChromeImage(
                            asset: ApprovedChromeAssets.cloud,
                            size: 32,
                          ),
                          const SizedBox(width: Spacing.sm),
                          Text(
                            'HANGUL SORI',
                            textScaler: TextScaler.noScaling,
                            style: GrammarC.heading.copyWith(
                              fontSize: 13,
                              color: GrammarC.gold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 4,
                  top: 0,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      key: const Key('grammar-plan-dismiss'),
                      tooltip: AppL10n.of(context).btnClose,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: SoriCLearningTokens.paper,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 2,
            width: double.infinity,
            child: ColoredBox(color: GrammarC.gold),
          ),
          Expanded(child: Builder(builder: builder)),
        ],
      ),
    ),
  ),
);

class GrammarCPlanChoice extends StatelessWidget {
  const GrammarCPlanChoice({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
    this.minInteractiveHeight = 56,
  });
  final String label;
  final String semanticLabel;
  final bool selected;
  final VoidCallback? onTap;
  final double minInteractiveHeight;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    enabled: onTap != null,
    label: semanticLabel,
    onTap: onTap,
    excludeSemantics: true,
    child: SoriPressable(
      onTap: onTap,
      surfaceDepth: 3,
      surfaceRadius: 12,
      surfaceEdgeColor: GrammarC.gold,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: minInteractiveHeight,
          minWidth: 48,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Image.asset(
                'design_assets/grammar/amount-tile.png',
                fit: BoxFit.fill,
                excludeFromSemantics: true,
              ),
            ),
            if (selected)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: GrammarC.gold, width: 2),
                    ),
                    child: const SoriCMaterialSurface(
                      material: SoriCMaterial.jade,
                      borderRadius: BorderRadius.all(Radius.circular(9)),
                      child: SizedBox(),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GrammarC.heading.copyWith(
                      fontSize: 30,
                      color: selected
                          ? SoriCLearningTokens.paper
                          : GrammarC.ink,
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: SoriCLearningTokens.paper,
                    )
                  else
                    const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class GrammarCLevelTray extends StatelessWidget {
  const GrammarCLevelTray({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.countFor,
    this.enabled = true,
  });
  final String selected;
  final ValueChanged<String?> onChanged;
  final int Function(String) countFor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned.fill(
            child: Image.asset(
              'design_assets/grammar/level-tray.png',
              fit: BoxFit.fill,
              excludeFromSemantics: true,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              constraints.maxWidth * .13,
              38,
              constraints.maxWidth * .065,
              28,
            ),
            child: Column(
              children: [
                for (var row = 0; row < 2; row++) ...[
                  if (row > 0) const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var column = 0; column < 3; column++) ...[
                        if (column > 0) const SizedBox(width: 8),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final level =
                                  LearnerLevel.values[row * 3 + column];
                              return GrammarCPlanChoice(
                                key: ValueKey(
                                  'grammar-plan-level-${level.code}',
                                ),
                                label: level.display,
                                semanticLabel:
                                    '${level.display}, ${countFor(level.code)}',
                                selected: selected.toLowerCase() == level.code,
                                onTap: enabled
                                    ? () => onChanged(level.code)
                                    : null,
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  t.grammarPlanLevelCount(
                    selected.toUpperCase(),
                    countFor(selected),
                  ),
                  textAlign: TextAlign.center,
                  style: GrammarC.heading.copyWith(fontSize: 15),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: GrammarCPaper(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: Spacing.xs,
              ),
              child: Text(
                t.grammarPlanLevelLabel,
                style: GrammarC.heading.copyWith(fontSize: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GrammarCPlanPreview extends StatelessWidget {
  const GrammarCPlanPreview({super.key, required this.count});
  final int count;
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return GrammarCPaper(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 86,
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    for (var i = 0; i < count; i++)
                      Positioned(
                        left: i * (constraints.maxWidth - 48) / (count - 1),
                        top: 3 + (i - (count - 1) / 2).abs(),
                        child: Transform.rotate(
                          angle: -.14 + .28 * i / (count - 1),
                          child: Image.asset(
                            'design_assets/grammar/daily-card.png',
                            key: ValueKey('grammar-daily-card-$i'),
                            width: 48,
                            height: 78,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.grammarPlanDailyPreview(count),
                  style: GrammarC.heading.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  t.grammarPlanPaceChangeHint,
                  style: GrammarC.body.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
