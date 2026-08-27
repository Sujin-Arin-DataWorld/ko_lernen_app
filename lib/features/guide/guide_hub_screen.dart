import 'package:flutter/material.dart';

import '../../models/guide_contract.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/standard_page.dart';
import '../../widgets/sori/tokens.dart';
import 'guide_presentation.dart';

class GuideHubScreen extends StatelessWidget {
  const GuideHubScreen({
    super.key,
    required this.copy,
    required this.topics,
    required this.onDestinationRequested,
    this.onNonLiveTopicRequested,
    this.footer,
  });

  static const routeName = '/guide';

  final GuideHubCopy copy;
  final List<GuideTopicViewModel> topics;
  final GuideTopicCallback onDestinationRequested;
  final GuideTopicCallback? onNonLiveTopicRequested;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return SoriStandardPage(
      appBarTitle: copy.appBarTitle,
      eyebrow: copy.eyebrow,
      headline: copy.title,
      description: copy.description,
      children: [
        for (var index = 0; index < topics.length; index++) ...[
          _GuideTopicCard(
            topic: topics[index],
            completedLabel: copy.completedLabel,
            onActivate: guideTopicActivation(
              topic: topics[index].spec,
              onLiveTopicRequested: onDestinationRequested,
              onNonLiveTopicRequested: onNonLiveTopicRequested,
            ),
          ),
          if (index != topics.length - 1) const SizedBox(height: Spacing.md),
        ],
        if (footer != null) ...[const SizedBox(height: Spacing.xl), footer!],
      ],
    );
  }
}

class _GuideTopicCard extends StatelessWidget {
  const _GuideTopicCard({
    required this.topic,
    required this.completedLabel,
    required this.onActivate,
  });

  final GuideTopicViewModel topic;
  final String completedLabel;
  final GuideTopicCallback? onActivate;

  @override
  Widget build(BuildContext context) {
    final textTheme = SoriTextTheme.of(context);
    return SoriCard(
      key: ValueKey('guide-topic-${topic.spec.id.stableId}'),
      accent: _statusColor(topic.spec.availability),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _AvailabilityBadge(
                availability: topic.spec.availability,
                label: topic.availabilityLabel,
              ),
              if (topic.isCompleted)
                _StatusLabel(
                  icon: Icons.check_circle_rounded,
                  label: completedLabel,
                  color: SoriColors.success,
                ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Semantics(
            header: true,
            child: Text(topic.title, style: textTheme.h2),
          ),
          const SizedBox(height: Spacing.sm),
          Text(topic.description, style: textTheme.bodySmall),
          if (onActivate != null) ...[
            const SizedBox(height: Spacing.lg),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: SoriButton.outlined(
                key: ValueKey('guide-topic-action-${topic.spec.id.stableId}'),
                label: topic.actionLabel,
                semanticLabel: '${topic.title}: ${topic.actionLabel}',
                trailingIcon: Icons.arrow_forward_rounded,
                onTap: () => onActivate!(topic.spec),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.availability, required this.label});

  final FeatureAvailability availability;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _StatusLabel(
      icon: _statusIcon(availability),
      label: label,
      color: _statusColor(availability),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    final foreground = surfaces.brightness == Brightness.light
        ? Color.alphaBlend(SoriColors.lightText.withValues(alpha: 0.32), color)
        : Color.alphaBlend(Colors.white.withValues(alpha: 0.42), color);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: foreground, width: 1.25),
          borderRadius: SoriRadius.brPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: foreground),
            const SizedBox(width: Spacing.xs),
            Flexible(
              child: Text(
                label,
                style: SoriTextTheme.of(context).caption.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(FeatureAvailability availability) => switch (availability) {
  FeatureAvailability.live => SoriColors.success,
  FeatureAvailability.preview => SoriColors.info,
  FeatureAvailability.comingSoon => SoriColors.goldOnLight,
  FeatureAvailability.unavailable => SoriColors.danger,
};

IconData _statusIcon(FeatureAvailability availability) =>
    switch (availability) {
      FeatureAvailability.live => Icons.check_circle_outline_rounded,
      FeatureAvailability.preview => Icons.visibility_outlined,
      FeatureAvailability.comingSoon => Icons.schedule_rounded,
      FeatureAvailability.unavailable => Icons.block_rounded,
    };
