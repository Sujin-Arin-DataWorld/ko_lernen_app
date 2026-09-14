import 'package:flutter/material.dart';

import '../../models/guide_contract.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/pressable.dart';
import '../../widgets/sori/tokens.dart';
import 'guide_presentation.dart';

class TodayGuideChecklistCard extends StatefulWidget {
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
  State<TodayGuideChecklistCard> createState() =>
      _TodayGuideChecklistCardState();
}

class _TodayGuideChecklistCardState extends State<TodayGuideChecklistCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final copy = widget.copy;
    final topics = widget.topics;
    final incomplete = topics.where((topic) => !topic.isCompleted);
    final visible = _expanded ? topics : incomplete.take(1).toList();
    final t = AppL10n.of(context);
    final textTheme = SoriTextTheme.of(context);
    final surfaces = SoriSurfaces.of(context);
    return SoriCard(
      key: const ValueKey('today-guide-checklist-card'),
      variant: SoriCardVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(copy.title, style: textTheme.cardTitle),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              IconButton(
                key: const ValueKey('today-guide-expand'),
                tooltip: _expanded ? t.todayGuideCollapse : t.todayGuideExpand,
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
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
                  onPressed: widget.onDismiss,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),

          if (_expanded)
            Text(
              copy.progressLabel,
              style: textTheme.label.copyWith(color: surfaces.text),
            ),
          if (_expanded) const SizedBox(height: Spacing.md),
          for (var index = 0; index < visible.length; index++) ...[
            _ChecklistTopicRow(
              topic: visible[index],
              completedLabel: copy.completedLabel,
              onActivate: guideTopicActivation(
                topic: visible[index].spec,
                onLiveTopicRequested: widget.onDestinationRequested,
                onNonLiveTopicRequested: widget.onNonLiveTopicRequested,
              ),
            ),
            if (index != visible.length - 1)
              Divider(height: 1, color: surfaces.border),
          ],
          if (_expanded)
            SoriButton.ghost(
              key: const ValueKey('today-guide-open-hub'),
              label: copy.openGuideLabel,
              trailingIcon: Icons.arrow_forward_rounded,
              fullWidth: true,
              onTap: widget.onOpenGuide,
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
                  Text(topic.title, style: textTheme.body),
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
