import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/personal_hanok.dart';
import 'button.dart';
import 'card.dart';
import 'cultural_help.dart';
import 'personal_hanok_map.dart';
import 'sori_term.dart';
import 'tokens.dart';

/// Glossary term id for a personal-Hanok zone, when the shipped catalog has
/// a matching entry (§W-J2 item 2) — the single source both
/// [HanokSelectedPlacePanel] here and `hanok_world_screen.dart`'s place list
/// use, so the two surfaces can never drift onto different term ids for the
/// same room. `gyeRoad` is a bridge to the separate shared courtyard, not a
/// personal room, so it never gets a door.
String? personalHanokZoneTermId(PersonalHanokZone zone) => switch (zone) {
  PersonalHanokZone.sarangbang => 'sarangbang',
  PersonalHanokZone.daecheongmaru => 'daecheong',
  PersonalHanokZone.haengrangchae => 'haengnangchae',
  PersonalHanokZone.anchae => 'anchae',
  PersonalHanokZone.huwon => 'huwon',
  PersonalHanokZone.sadang => 'sadang',
  PersonalHanokZone.gyeRoad => null,
};

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
  final String Function(PersonalHanokZone zone) zonePurpose;
  final String Function(PersonalHanokZone zone)? mapPlaceLabel;
  final String? todayExpressionKo;
  final int todaySceneMinutes;
  final EdgeInsets contentPadding;
  final Set<PersonalHanokMilestone> suppressedMilestones;

  const WorldMapViewport({
    super.key,
    required this.projection,
    required this.selectedZone,
    required this.onSelectZone,
    required this.onOpenSelectedZone,
    required this.zoneLabel,
    required this.zonePurpose,
    this.mapPlaceLabel,
    this.todayExpressionKo,
    this.todaySceneMinutes = 4,
    required this.contentPadding,
    this.suppressedMilestones = const <PersonalHanokMilestone>{},
  });

  @override
  Widget build(BuildContext context) {
    final map = PersonalHanokMap(
      projection: projection,
      zoneLabel: zoneLabel,
      mapPlaceLabel: mapPlaceLabel,
      selectedZone: selectedZone,
      todayZone: PersonalHanokZone.sarangbang,
      todayMarkerLabel: AppL10n.of(context).hanokWorldTodayMarker,
      onTapZone: onSelectZone,
      suppressedMilestones: suppressedMilestones,
    );
    final detail = HanokSelectedPlacePanel(
      selectedZone: selectedZone,
      zoneLabel: zoneLabel,
      zonePurpose: zonePurpose,
      todayExpressionKo: todayExpressionKo,
      todaySceneMinutes: todaySceneMinutes,
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

/// Selected-place detail card — label, purpose/today-scene copy, and the
/// explicit "go there" action. Public (§W-F F2) so the Hanok tab's embedded
/// sliver layout can place it as its own scroll item, separate from
/// [WorldMapViewport]'s responsive map+panel pairing.
class HanokSelectedPlacePanel extends StatelessWidget {
  final PersonalHanokZone? selectedZone;
  final String Function(PersonalHanokZone zone) zoneLabel;
  final String Function(PersonalHanokZone zone) zonePurpose;
  final String? todayExpressionKo;
  final int todaySceneMinutes;
  final VoidCallback? onOpen;

  const HanokSelectedPlacePanel({
    super.key,
    required this.selectedZone,
    required this.zoneLabel,
    required this.zonePurpose,
    required this.todayExpressionKo,
    required this.todaySceneMinutes,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final zone = selectedZone;
    final label = zone == null ? null : zoneLabel(zone);
    final purpose = zone == null ? null : zonePurpose(zone);
    final canOpen = zone != null && onOpen != null;
    final isTodayScene = zone == PersonalHanokZone.sarangbang;
    final todayDetail =
        isTodayScene &&
            todayExpressionKo != null &&
            todayExpressionKo!.trim().isNotEmpty
        ? t.hanokWorldTodaySceneDetail(
            todaySceneMinutes,
            todayExpressionKo!.trim(),
          )
        : null;
    // §W-J2 item 2: the same "Romanization · Hangul" secondary line the
    // place list already shows under its label — built straight from the
    // glossary entry, not a new ARB pair (it already carries both).
    final termId = zone == null ? null : personalHanokZoneTermId(zone);

    return CulturalGlossaryBuilder(
      builder: (context, glossary) {
        final entry = termId == null ? null : glossary?.entry(termId);
        return SoriCard(
          key: const ValueKey('hanok-world-selection-panel'),
          variant: SoriCardVariant.base,
          accent: SoriColors.primary,
          tinted: zone != null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label ?? t.hanokWorldSelectPlaceTitle, style: text.h3),
              if (entry != null) ...[
                const SizedBox(height: 2),
                SoriTerm(
                  termId: entry.termId,
                  text: '${entry.romanization} · ${entry.korean}',
                  style: text.caption,
                  surface: 'hanok_world_selection_panel',
                ),
              ],
              if (!isTodayScene || todayDetail == null) ...[
                const SizedBox(height: Spacing.xs),
                Text(
                  label == null ? t.hanokWorldSelectPlaceBody : purpose!,
                  style: text.bodySmall,
                ),
              ],
              if (todayDetail != null) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  todayDetail,
                  key: const ValueKey('hanok-world-today-scene-detail'),
                  style: text.label.copyWith(color: SoriColors.primary),
                ),
              ],
              if (label != null && !isTodayScene) ...[
                const SizedBox(height: Spacing.xs),
                Text(
                  t.hanokWorldPlaceReadyBody(label),
                  style: text.caption.copyWith(
                    color: SoriSurfaces.of(context).textMuted,
                  ),
                ),
              ],
              if (canOpen) ...[
                const SizedBox(height: Spacing.md),
                SoriButton.filled(
                  key: const ValueKey('hanok-world-open-selected'),
                  label: t.hanokWorldGoThere,
                  fullWidth: true,
                  onTap: onOpen,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
