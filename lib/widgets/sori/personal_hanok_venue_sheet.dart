import 'package:flutter/material.dart';

import '../../data/personal_hanok_venue_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/personal_hanok.dart';
import 'button.dart';
import 'card.dart';
import 'personal_hanok_map.dart';
import 'sheet.dart';
import 'tokens.dart';

/// Opens a short place-context surface before a learner enters an established
/// Hangul Sori destination. The sheet has no navigation or persistence policy:
/// its caller receives one declarative action and decides how to launch it.
Future<PersonalHanokVenueAction?> showPersonalHanokVenueSheet({
  required BuildContext context,
  required PersonalHanokProjection projection,
  required PersonalHanokZone zone,
  required String zoneLabel,
}) => showSoriSheet<PersonalHanokVenueAction>(
  context: context,
  builder: (_) => PersonalHanokVenueSheet(
    projection: projection,
    zone: zone,
    zoneLabel: zoneLabel,
  ),
);

class PersonalHanokVenueSheet extends StatelessWidget {
  final PersonalHanokProjection projection;
  final PersonalHanokZone zone;
  final String zoneLabel;

  const PersonalHanokVenueSheet({
    super.key,
    required this.projection,
    required this.zone,
    required this.zoneLabel,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);
    final actions = personalHanokVenueActionsFor(zone);
    return Column(
      key: ValueKey('personal-hanok-venue-${zone.name}'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(zoneLabel, style: text.h2),
        const SizedBox(height: Spacing.xs),
        Text(
          _body(t, zone),
          style: text.bodySmall.copyWith(color: s.textMuted),
        ),
        const SizedBox(height: Spacing.md),
        // This is an orientation preview, not a second full-size map. Capping
        // it keeps the next learning choices reachable without scrolling on a
        // short landscape phone while still preserving the selected place.
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: ExcludeSemantics(
                child: AbsorbPointer(
                  child: PersonalHanokMap(
                    projection: projection,
                    zoneLabel: (_) => '',
                    selectedZone: zone,
                    showTargets: false,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        for (final action in actions) ...[
          SoriButton.outlined(
            key: ValueKey('personal-hanok-venue-action-${action.name}'),
            label: _actionLabel(t, action),
            fullWidth: true,
            maxLines: 2,
            onTap: () => Navigator.of(context).pop(action),
          ),
          if (action != actions.last) const SizedBox(height: Spacing.sm),
        ],
        if (actions.isEmpty)
          SoriCard(
            variant: SoriCardVariant.base,
            child: Text(
              t.hanokWorldPlaceReadyBody(zoneLabel),
              style: text.bodySmall,
            ),
          ),
      ],
    );
  }
}

String _body(AppL10n t, PersonalHanokZone zone) => switch (zone) {
  PersonalHanokZone.anchae => t.hanokVenueAnbangBody,
  PersonalHanokZone.daecheongmaru => t.hanokVenueDaecheongBody,
  PersonalHanokZone.haengrangchae => t.hanokVenueHaengrangBody,
  PersonalHanokZone.huwon => t.hanokVenueHuwonBody,
  PersonalHanokZone.sadang => t.hanokVenueSadangBody,
  PersonalHanokZone.sarangbang => t.sarangbangStudyIntroBody,
  PersonalHanokZone.gyeRoad => t.hanokWorldGyeBridgeBody,
};

String _actionLabel(AppL10n t, PersonalHanokVenueAction action) =>
    switch (action) {
      PersonalHanokVenueAction.furnishAnbang ||
      PersonalHanokVenueAction.furnishDaecheong => t.hanokVenueFurnishRoom,
      PersonalHanokVenueAction.openBookshelf => t.homeBookshelfCardTitle,
      PersonalHanokVenueAction.searchWordbook => t.wbSearchTitle,
      PersonalHanokVenueAction.captureBook => t.bookCaptureTitle,
      PersonalHanokVenueAction.openLearningPath => t.personalRoomDaecheongStudy,
      PersonalHanokVenueAction.openPractice => t.navPractice,
      PersonalHanokVenueAction.openDailyCharacter => t.dailyCharTitle,
      PersonalHanokVenueAction.openQuests => t.homeQuestsCardTitle,
      PersonalHanokVenueAction.openDojang => t.dojangTitle,
      PersonalHanokVenueAction.openStats => t.statsTitle,
    };
