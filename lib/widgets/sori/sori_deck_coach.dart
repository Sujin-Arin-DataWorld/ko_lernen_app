import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/storage_service.dart';
import 'spotlight_coach.dart';
import 'tokens.dart';

bool _soriDeckCoachShownThisSession = false;

/// Shows the shared four-direction deck coach after a screen's older coach has
/// already been completed. The process guard prevents overlapping coaches
/// while the persisted `soriDeck` flag keeps it one-time across launches.
void maybeShowSoriDeckCoach(
  BuildContext context, {
  required GlobalKey targetKey,
  required bool existingCoachSeen,
}) {
  if (_soriDeckCoachShownThisSession ||
      Storage.tutSeen('soriDeck') ||
      !existingCoachSeen ||
      targetKey.currentContext == null) {
    return;
  }
  _soriDeckCoachShownThisSession = true;
  final t = AppL10n.of(context);
  SpotlightCoach.show(
    context,
    steps: [
      SpotlightStep(
        targetKey: targetKey,
        title: t.coachSoriDeckTitle,
        body: t.coachSoriDeckBody,
        icon: Icons.swipe_rounded,
        cutoutPadding: const EdgeInsets.all(Spacing.sm),
        cutoutRadius: SoriRadius.lg,
      ),
    ],
    onComplete: () => Storage.setTutSeen('soriDeck'),
  );
}
