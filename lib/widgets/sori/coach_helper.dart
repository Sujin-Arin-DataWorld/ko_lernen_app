import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/storage_service.dart';
import 'spotlight_coach.dart';

bool _sessionSoriDeckCoachShown = false;

/// Sori Deck 2.0 4방향 스와이프 안내 코치마크 (프로세스 세션당 1회, 영구 플래그 1회).
Future<void> maybeShowSoriDeckCoach(
  BuildContext context, {
  required GlobalKey targetKey,
}) async {
  if (_sessionSoriDeckCoachShown) return;
  if (Storage.tutSeen('soriDeck')) return;

  _sessionSoriDeckCoachShown = true;
  await Storage.setTutSeen('soriDeck');

  if (!context.mounted) return;

  final t = AppL10n.of(context);
  await SpotlightCoach.show(
    context,
    steps: [
      SpotlightStep(
        targetKey: targetKey,
        title: 'Sori Deck',
        body: t.coachSoriDeckBody,
        icon: Icons.swipe_rounded,
        cutoutPadding: const EdgeInsets.all(12),
        cutoutRadius: 20,
      ),
    ],
  );
}
