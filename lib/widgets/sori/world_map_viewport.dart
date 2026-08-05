import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/personal_hanok.dart';
import 'button.dart';
import 'card.dart';
import 'personal_hanok_map.dart';
import 'tokens.dart';

/// Responsive presentation for the canonical personal Hanok map.
///
/// The owner supplies selection and navigation callbacks. This widget has no
/// storage, progress, or route policy: tapping art selects a completed place;
/// the explicit detail action is the only point that asks the owner to open it.
class WorldMapViewport extends StatelessWidget {
  final PersonalHanokProjection projection;
  final PersonalHanokZone? selectedZone;
  final ValueChanged<PersonalHanokZone> onSelectZone;
  final VoidCallback? onOpenSelectedZone;
  final String Function(PersonalHanokZone zone) zoneLabel;
  final EdgeInsets contentPadding;
  final Set<PersonalHanokMilestone> suppressedMilestones;

  const WorldMapViewport({
    super.key,
    required this.projection,
    required this.selectedZone,
    required this.onSelectZone,
    required this.onOpenSelectedZone,
    required this.zoneLabel,
    required this.contentPadding,
    this.suppressedMilestones = const <PersonalHanokMilestone>{},
  });

  @override
  Widget build(BuildContext context) {
    final map = PersonalHanokMap(
      projection: projection,
      zoneLabel: zoneLabel,
      selectedZone: selectedZone,
      todayZone: PersonalHanokZone.sarangbang,
      todayMarkerLabel: AppL10n.of(context).hanokWorldTodayMarker,
      onTapZone: onSelectZone,
      suppressedMilestones: suppressedMilestones,
    );
    final detail = _SelectedPlacePanel(
      selectedZone: selectedZone,
      zoneLabel: zoneLabel,
      onOpen: onOpenSelectedZone,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= SoriBreakpoints.tablet;
        if (!isTablet) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              map,
              Padding(
                padding: EdgeInsets.fromLTRB(
                  contentPadding.left,
                  Spacing.md,
                  contentPadding.right,
                  0,
                ),
                child: detail,
              ),
            ],
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: contentPadding.left),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: map),
              const SizedBox(width: Spacing.lg),
              SizedBox(width: 280, child: detail),
            ],
          ),
        );
      },
    );
  }
}

class _SelectedPlacePanel extends StatelessWidget {
  final PersonalHanokZone? selectedZone;
  final String Function(PersonalHanokZone zone) zoneLabel;
  final VoidCallback? onOpen;

  const _SelectedPlacePanel({
    required this.selectedZone,
    required this.zoneLabel,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final zone = selectedZone;
    final label = zone == null ? null : zoneLabel(zone);
    final canOpen = zone != null && onOpen != null;

    return SoriCard(
      key: const ValueKey('hanok-world-selection-panel'),
      variant: SoriCardVariant.base,
      accent: SoriColors.primary,
      tinted: zone != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (zone == PersonalHanokZone.sarangbang) ...[
            Text(
              t.hanokWorldTodayMarker,
              style: text.label.copyWith(color: SoriColors.primary),
            ),
            const SizedBox(height: 4),
          ],
          Text(label ?? t.hanokWorldSelectPlaceTitle, style: text.h3),
          const SizedBox(height: Spacing.xs),
          Text(
            label == null
                ? t.hanokWorldSelectPlaceBody
                : t.hanokWorldPlaceReadyBody(label),
            style: text.bodySmall,
          ),
          if (canOpen) ...[
            const SizedBox(height: Spacing.md),
            SoriButton.filled(
              key: const ValueKey('hanok-world-open-selected'),
              label: t.hanokWorldOpenPlace(label!),
              fullWidth: true,
              onTap: onOpen,
            ),
          ],
        ],
      ),
    );
  }
}
