import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/storage_service.dart';
import 'spotlight_coach.dart';

/// 프로세스 세션 1회 + `tutSeen('soriDeck')` 가드 뒤 4방향 덱 코치 1스텝.
///
/// [afterCoachId] 가 있으면 그 화면 코치가 `tutSeen` 된 뒤에만 발화한다
/// (기존 코치 미발화·이미 본 경우는 즉시).
void maybeShowSoriDeckCoach(
  BuildContext context,
  GlobalKey targetKey, {
  String? afterCoachId,
}) {
  var polls = 0;
  void attempt() {
    if (!context.mounted) {
      return;
    }
    if (_firedThisSession || Storage.tutSeen('soriDeck')) {
      return;
    }
    if (afterCoachId != null &&
        !Storage.tutSeen(afterCoachId) &&
        polls++ < 200) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(const Duration(milliseconds: 250), attempt);
      });
      return;
    }
    if (targetKey.currentContext == null) {
      if (polls++ < 200) {
        WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
      }
      return;
    }
    _firedThisSession = true;
    final t = AppL10n.of(context);
    SpotlightCoach.show(
      context,
      steps: [
        SpotlightStep(
          targetKey: targetKey,
          title: t.coachSoriDeckTitle,
          body: t.coachSoriDeckBody,
          icon: Icons.swipe_rounded,
        ),
      ],
      onComplete: () => Storage.setTutSeen('soriDeck'),
    );
  }

  WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
}

bool _firedThisSession = false;

@visibleForTesting
void resetSoriDeckCoachSessionForTest() {
  _firedThisSession = false;
}
