import 'package:flutter/material.dart';

import '../../models/guide_contract.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/pressable.dart';
import '../../widgets/sori/tokens.dart';
import 'guide_presentation.dart';

class TodayGuideChecklistCard extends StatelessWidget {
  const TodayGuideChecklistCard({
    super.key,
    required this.copy,
    required this.topics,
    required this.onOpenGuide,
    required this.onDismiss,
    required this.onDestinationRequested,
    this.onNonLiveTopicRequested,
  });

  final TodayGuideChecklistCopy copy;
  final List<GuideTopicViewModel> topics;
  final VoidCallback onOpenGuide;
  final VoidCallback onDismiss;
  final GuideTopicCallback onDestinationRequested;
  final GuideTopicCallback? onNonLiveTopicRequested;

  @override
  Widget build(BuildContext context) {
    final textTheme = SoriTextTheme.of(context);
    final surfaces = SoriSurfaces.of(context);
    return SoriCard(
      key: const ValueKey('today-guide-checklist-card'),
      variant: SoriCardVariant.hero,
      accent: SoriColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(copy.title, style: textTheme.h2),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Semantics(
                button: true,
                label: copy.dismissLabel,
                child: IconButton(
                  key: const ValueKey('today-guide-dismiss'),
                  tooltip: copy.dismissLabel,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
          Text(copy.description, style: textTheme.bodySmall),
          const SizedBox(height: Spacing.md),
          Text(
            copy.progressLabel,
            style: textTheme.label.copyWith(color: surfaces.text),
          ),
          const SizedBox(height: Spacing.md),
          for (var index = 0; index < topics.length; index++) ...[
            _ChecklistTopicRow(
              topic: topics[index],
              completedLabel: copy.completedLabel,
              onActivate: guideTopicActivation(
                topic: topics[index].spec,
                onLiveTopicRequested: onDestinationRequested,
                onNonLiveTopicRequested: onNonLiveTopicRequested,
              ),
            ),
            if (index != topics.length - 1)
              Divider(height: 1, color: surfaces.border),
          ],
          const SizedBox(height: Spacing.lg),
          SoriButton.outlined(
            key: const ValueKey('today-guide-open-hub'),
            label: copy.openGuideLabel,
            trailingIcon: Icons.arrow_forward_rounded,
            fullWidth: true,
            onTap: onOpenGuide,
          ),
        ],
      ),
    );
  }
}

class _ChecklistTopicRow extends StatelessWidget {
  const _ChecklistTopicRow({
    required this.topic,
    required this.completedLabel,
    required this.onActivate,
  });

  final GuideTopicViewModel topic;
  final String completedLabel;
  final GuideTopicCallback? onActivate;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    final textTheme = SoriTextTheme.of(context);
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: Row(
          children: [
            Icon(
              topic.isCompleted
                  ? Icons.check_circle_rounded
                  : _checklistIcon(topic.spec.availability),
              color: topic.isCompleted
                  ? SoriColors.success
                  : _checklistColor(topic.spec.availability, surfaces),
              size: 24,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(topic.title, style: textTheme.h3),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    topic.isCompleted
                        ? completedLabel
                        : topic.availabilityLabel,
                    style: textTheme.caption,
                  ),
                ],
              ),
            ),
            if (onActivate != null) ...[
              const SizedBox(width: Spacing.sm),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: surfaces.textMuted,
              ),
            ],
          ],
        ),
      ),
    );

    if (onActivate == null) {
      return Semantics(
        key: ValueKey('today-guide-topic-${topic.spec.id.stableId}'),
        enabled: false,
        label: '${topic.title}, ${topic.availabilityLabel}',
        excludeSemantics: true,
        child: content,
      );
    }
    return Semantics(
      key: ValueKey('today-guide-topic-${topic.spec.id.stableId}'),
      button: true,
      enabled: true,
      label: topic.isCompleted
          ? '${topic.title}, $completedLabel'
          : '${topic.title}, ${topic.availabilityLabel}',
      onTap: () => onActivate!(topic.spec),
      excludeSemantics: true,
      child: SoriPressable(
        onTap: () => onActivate!(topic.spec),
        child: content,
      ),
    );
  }
}

Color _checklistColor(
  FeatureAvailability availability,
  SoriSurfaces surfaces,
) => switch (availability) {
  FeatureAvailability.live => SoriColors.primary,
  FeatureAvailability.preview => SoriColors.info,
  FeatureAvailability.comingSoon => SoriColors.goldOnLight,
  FeatureAvailability.unavailable => surfaces.textDim,
};

IconData _checklistIcon(FeatureAvailability availability) =>
    switch (availability) {
      FeatureAvailability.live => Icons.radio_button_unchecked_rounded,
      FeatureAvailability.preview => Icons.visibility_outlined,
      FeatureAvailability.comingSoon => Icons.schedule_rounded,
      FeatureAvailability.unavailable => Icons.block_rounded,
    };
