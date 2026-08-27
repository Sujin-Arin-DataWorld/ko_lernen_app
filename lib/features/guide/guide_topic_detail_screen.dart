import 'package:flutter/material.dart';

import '../../widgets/sori/button.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/standard_page.dart';
import '../../widgets/sori/tokens.dart';
import 'guide_presentation.dart';

/// A read-only explanation shown before any guide destination is opened.
///
/// The screen owns no permission, media, storage, reward, or SDK call. Every
/// live action is injected and remains independently selectable, so a learner
/// is never forced through several routes to finish a topic.
class GuideTopicDetailScreen extends StatelessWidget {
  const GuideTopicDetailScreen({
    super.key,
    required this.module,
    required this.onActionRequested,
    this.onScenarioCategoryRequested,
  });

  final GuideTopicModuleViewModel module;
  final GuideModuleActionCallback onActionRequested;
  final GuideScenarioCategoryCallback? onScenarioCategoryRequested;

  @override
  Widget build(BuildContext context) {
    final textTheme = SoriTextTheme.of(context);
    final surfaces = SoriSurfaces.of(context);
    return SoriStandardPage(
      appBarTitle: module.appBarTitle,
      eyebrow: module.eyebrow,
      headline: module.topic.title,
      description: module.topic.description,
      children: [
        Semantics(
          header: true,
          child: Text(module.stepsTitle, style: textTheme.h2),
        ),
        const SizedBox(height: Spacing.md),
        for (var index = 0; index < module.steps.length; index++) ...[
          _GuideStep(step: module.steps[index]),
          if (index != module.steps.length - 1)
            const SizedBox(height: Spacing.sm),
        ],
        const SizedBox(height: Spacing.xl),
        SoriCard(
          key: ValueKey(
            'guide-module-passive-notice-${module.topic.spec.id.stableId}',
          ),
          accent: SoriColors.info,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.shield_outlined,
                  color: surfaces.text,
                  size: 24,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(module.passiveNotice, style: textTheme.bodySmall),
              ),
            ],
          ),
        ),
        if (module.actions.isNotEmpty) ...[
          const SizedBox(height: Spacing.xl),
          Semantics(
            header: true,
            child: Text(module.actionsTitle, style: textTheme.h2),
          ),
          const SizedBox(height: Spacing.md),
          for (var index = 0; index < module.actions.length; index++) ...[
            SoriButton.outlined(
              key: ValueKey(
                'guide-module-action-${module.actions[index].spec.id.stableId}',
              ),
              label: module.actions[index].label,
              semanticLabel:
                  '${module.topic.title}: ${module.actions[index].label}',
              trailingIcon: Icons.arrow_forward_rounded,
              fullWidth: true,
              onTap: () => onActionRequested(module.actions[index]),
            ),
            if (index != module.actions.length - 1)
              const SizedBox(height: Spacing.sm),
          ],
        ],
        if (module.scenarioCategories case final categories?) ...[
          const SizedBox(height: Spacing.xl),
          _GuideScenarioCategorySection(
            section: categories,
            onCategoryRequested: onScenarioCategoryRequested,
          ),
        ],
      ],
    );
  }
}

class _GuideScenarioCategorySection extends StatelessWidget {
  const _GuideScenarioCategorySection({
    required this.section,
    required this.onCategoryRequested,
  });

  final GuideScenarioCategorySectionViewModel section;
  final GuideScenarioCategoryCallback? onCategoryRequested;

  @override
  Widget build(BuildContext context) {
    final textTheme = SoriTextTheme.of(context);
    return Semantics(
      key: const ValueKey('guide-scenario-categories-section'),
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(section.title, style: textTheme.h2),
          ),
          if (section.summary case final summary?) ...[
            const SizedBox(height: Spacing.xs),
            Text(
              summary,
              key: const ValueKey('guide-scenario-categories-summary'),
              style: textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: Spacing.md),
          switch (section.status) {
            GuideScenarioCategorySectionStatus.loading => Semantics(
              key: const ValueKey('guide-scenario-categories-loading'),
              label: section.statusLabel,
              child: const ExcludeSemantics(
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            GuideScenarioCategorySectionStatus.empty => SoriCard(
              key: const ValueKey('guide-scenario-categories-empty'),
              child: Text(section.statusLabel, style: textTheme.bodySmall),
            ),
            GuideScenarioCategorySectionStatus.failed => SoriCard(
              key: const ValueKey('guide-scenario-categories-failed'),
              accent: SoriColors.warning,
              child: Text(section.statusLabel, style: textTheme.bodySmall),
            ),
            GuideScenarioCategorySectionStatus.ready => Column(
              children: [
                for (
                  var index = 0;
                  index < section.categories.length;
                  index++
                ) ...[
                  SoriButton.outlined(
                    key: ValueKey(
                      'guide-scenario-category-'
                      '${section.categories[index].destination.shelfId}',
                    ),
                    label:
                        '${section.categories[index].label} · '
                        '${section.categories[index].countLabel}',
                    semanticLabel:
                        '${section.categories[index].label}. '
                        '${section.categories[index].countLabel}',
                    trailingIcon: Icons.arrow_forward_rounded,
                    fullWidth: true,
                    onTap: onCategoryRequested == null
                        ? null
                        : () => onCategoryRequested!(section.categories[index]),
                  ),
                  if (index != section.categories.length - 1)
                    const SizedBox(height: Spacing.sm),
                ],
              ],
            ),
          },
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({required this.step});

  final GuideModuleStepViewModel step;

  @override
  Widget build(BuildContext context) {
    final textTheme = SoriTextTheme.of(context);
    final surfaces = SoriSurfaces.of(context);
    return SoriCard(
      key: ValueKey('guide-module-step-${step.number}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Container(
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SoriColors.primary.withValues(alpha: 0.12),
                border: Border.all(color: surfaces.text, width: 1.25),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${step.number}',
                style: textTheme.label.copyWith(color: surfaces.text),
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(child: Text(step.body, style: textTheme.bodySmall)),
        ],
      ),
    );
  }
}
