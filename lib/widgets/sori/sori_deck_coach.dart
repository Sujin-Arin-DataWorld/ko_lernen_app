import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/storage_service.dart';
import 'spotlight_coach.dart';

/// UI/UX 개편 2 §P2-5 — 4방향 덱 스와이프 코치 (공용 헬퍼).
///
/// [ScreenCoachMixin] 은 State 당 coachId 1개라 review/legacy/cpPlay 와
/// 공유할 수 없다. 이 헬퍼가 `soriDeck` 플래그 + 프로세스 세션 가드를
/// 직접 걸고 [SpotlightCoach] 1스텝을 띄운다.
void maybeShowSoriDeckCoach(BuildContext context, GlobalKey targetKey) {
  assert(
    Storage.kScreenCoachIds.contains('soriDeck'),
    'coachId "soriDeck" missing from Storage.kScreenCoachIds',
  );
  if (_firedThisSession || Storage.tutSeen('soriDeck')) {
    return;
  }
  if (!context.mounted) {
    return;
  }
  final t = AppL10n.of(context);
  _firedThisSession = true;
  SpotlightCoach.show(
    context,
    steps: [
      SpotlightStep(
        targetKey: targetKey,
        title: t.coachSoriDeckBody,
        body: '',
        icon: Icons.swipe_rounded,
      ),
    ],
    onComplete: () => Storage.setTutSeen('soriDeck'),
  );
}

bool _firedThisSession = false;

/// 기존 화면 코치가 끝난 뒤(또는 이미 본 뒤) [maybeShowSoriDeckCoach] 를 예약.
///
/// [screenCoachId] 의 `Storage.tutSeen` 이 true 가 되고 [coachReady] 가
/// true 일 때 발화한다. 기존 코치 오버레이와 겹치지 않게 한다.
void scheduleSoriDeckCoachAfter(
  BuildContext context, {
  required GlobalKey targetKey,
  required String screenCoachId,
  required bool Function() coachReady,
}) {
  var polls = 0;
  void tick() {
    if (!context.mounted) {
      return;
    }
    if (!coachReady()) {
      if (polls++ > 180) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => tick());
      return;
    }
    if (!Storage.tutSeen(screenCoachId)) {
      // 기존 코치 표시 중 — 완료(tutSeen)까지 대기.
      if (polls++ > 3600) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => tick());
      return;
    }
    maybeShowSoriDeckCoach(context, targetKey);
  }

  WidgetsBinding.instance.addPostFrameCallback((_) => tick());
}
