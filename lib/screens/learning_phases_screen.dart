import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/learning_phase_catalog.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/illustrated_card.dart';
import '../widgets/sori/level_filter_bar.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';

class LearningPhasesScreen extends StatefulWidget {
  const LearningPhasesScreen({
    super.key,
    this.initialLevel = 'A1',
    this.loader,
  });

  final String initialLevel;
  final Future<List<LearningPhase>> Function()? loader;

  @override
  State<LearningPhasesScreen> createState() => _LearningPhasesScreenState();
}

class _LearningPhasesScreenState extends State<LearningPhasesScreen> {
  late String _level;
  late Future<List<LearningPhase>> _phases;

  @override
  void initState() {
    super.initState();
    _level =
        LearningPhaseCatalog.levels.contains(widget.initialLevel.toUpperCase())
        ? widget.initialLevel.toUpperCase()
        : 'A1';
    _phases = (widget.loader ?? LearningPhaseCatalog.load)();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final type = SoriTextTheme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return SoriStandardFrame(
      appBarTitle: t.learningPhasesTitle,
      maxWidth: SoriMaxWidth.hub,
      padding: const EdgeInsets.all(Spacing.lg),
      builder: (context, padding) => FutureBuilder<List<LearningPhase>>(
        future: _phases,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AppError(
              message: t.loadErrorTryAgain,
              onRetry: () => setState(() {
                _phases = (widget.loader ?? LearningPhaseCatalog.load)();
              }),
            );
          }
          if (!snapshot.hasData) {
            return const AppLoading();
          }
          final phases = snapshot.data!
              .where((p) => p.level == _level)
              .toList();
          return ListView(
            padding: padding,
            children: [
              Text(t.learningPhasesIntro, style: type.body),
              const SizedBox(height: Spacing.md),
              SoriLevelFilterBar(
                selected: _level.toLowerCase(),
                onChanged: (level) =>
                    setState(() => _level = level!.toUpperCase()),
              ),
              const SizedBox(height: Spacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Natural card heights keep long DE titles and 200% text legible.
                  final columns =
                      windowClassFor(constraints.maxWidth).isAtLeastMedium
                      ? 2
                      : 1;
                  final width =
                      (constraints.maxWidth - Spacing.md * (columns - 1)) /
                      columns;
                  return Wrap(
                    spacing: Spacing.md,
                    runSpacing: Spacing.md,
                    children: [
                      for (final phase in phases)
                        SizedBox(
                          width: width,
                          child: SoriIllustratedCard(
                            key: ValueKey('phase-card-${phase.id}'),
                            title: phase.title.pick(lang),
                            subtitle: phase.levelPhase,
                            illustrationAsset: phase.illustrationAsset,
                            fallback: const _PreparingImage(),
                            shrinkWrap: true,
                            onTap: () => Navigator.of(
                              context,
                            ).pushNamed('/course/phase', arguments: phase),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class LearningPhaseDetailScreen extends StatelessWidget {
  const LearningPhaseDetailScreen({super.key, required this.phase});

  final LearningPhase phase;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final type = SoriTextTheme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return SoriStandardFrame(
      appBarTitle: phase.levelPhase,
      maxWidth: SoriMaxWidth.prose,
      padding: const EdgeInsets.all(Spacing.lg),
      builder: (context, padding) => ListView(
        padding: padding,
        children: [
          SoriIllustratedCard(
            title: phase.title.pick(lang),
            subtitle: phase.goal.pick(lang),
            illustrationAsset: phase.illustrationAsset,
            fallback: const _PreparingImage(),
            shrinkWrap: true,
          ),
          const SizedBox(height: Spacing.lg),
          Text(t.learningPhasePracticeTitle, style: type.h2),
          const SizedBox(height: Spacing.sm),
          Text(phase.practiceFocus.pick(lang), style: type.body),
          const SizedBox(height: Spacing.sm),
          Text(t.learningPhasePracticeScope, style: type.bodySmall),
          const SizedBox(height: Spacing.md),
          for (final unit in phase.practiceUnits)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: SoriCard(
                key: ValueKey('phase-mission-${unit.id}'),
                onTap: () => Navigator.of(context).pushNamed(
                  '/scenario',
                  arguments: learningPhaseScenarioId(unit),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            unit.title.pick(lang),
                            style: type.cardTitle,
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(unit.canDo.pick(lang), style: type.bodySmall),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PreparingImage extends StatelessWidget {
  const _PreparingImage();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Spacing.lg),
    child: Text(
      AppL10n.of(context).learningPhaseImagePreparing,
      textAlign: TextAlign.center,
      style: SoriTextTheme.of(context).bodySmall,
    ),
  );
}
