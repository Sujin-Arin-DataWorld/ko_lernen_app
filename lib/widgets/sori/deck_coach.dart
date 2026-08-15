import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/storage_service.dart';
import 'spotlight_coach.dart';
import 'tokens.dart';

/// **Sori Deck 발견성 도우미** (§P2-5, 2026-08-14).
///
/// ① [SoriDeckFlipHint] — 플립 전 수평 저항 드래그(원시 24px+) 또는 판정
///    버튼 탭 시 카드 상단에 페이드인(150ms)하는 힌트 칩. 3초 자동 소멸,
///    트리거([ValueNotifier] 펄스)당 1회.
/// ② [maybeShowSoriDeckCoach] — 4방향 스와이프 1스텝 스포트라이트 코치.
///    `ScreenCoachMixin` 은 State 당 coachId 1개 구조라 이미 'review'/
///    'legacyVocab'/'cpPlay' 를 점유한 화면과 공유할 수 없어 **공용 헬퍼**로
///    푼다. `Storage.tutSeen('soriDeck')` + 프로세스 세션 1회 가드.

/// 힌트 칩 — 화면은 카드 슬롯 위 `Stack` 에 겹치고, 블록된 시도마다
/// `trigger.value++` 로 펄스를 보낸다.
class SoriDeckFlipHint extends StatefulWidget {
  const SoriDeckFlipHint({super.key, required this.trigger});

  final ValueNotifier<int> trigger;

  @override
  State<SoriDeckFlipHint> createState() => _SoriDeckFlipHintState();
}

class _SoriDeckFlipHintState extends State<SoriDeckFlipHint> {
  bool _visible = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    widget.trigger.addListener(_onPulse);
  }

  @override
  void didUpdateWidget(covariant SoriDeckFlipHint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      oldWidget.trigger.removeListener(_onPulse);
      widget.trigger.addListener(_onPulse);
    }
  }

  @override
  void dispose() {
    widget.trigger.removeListener(_onPulse);
    _hideTimer?.cancel();
    super.dispose();
  }

  void _onPulse() {
    if (!mounted) {
      return;
    }
    setState(() => _visible = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _visible = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final tt = SoriTextTheme.of(context);
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: SoriMotion.fast,
        curve: Curves.easeOut,
        child: Semantics(
          container: true,
          liveRegion: _visible,
          label: _visible ? t.deckFlipFirstHint : null,
          child: ExcludeSemantics(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.xs + 2,
              ),
              decoration: BoxDecoration(
                color: s.brightness == Brightness.light
                    ? SoriColors.lightSurfaceRaised
                    : s.surface,
                borderRadius: SoriRadius.brPill,
                border: Border.all(color: SoriColors.accent, width: 1.5),
                boxShadow: s.brightness == Brightness.light
                    ? SoriElevation.low
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.touch_app_outlined,
                    size: 16,
                    color: SoriColors.accent,
                  ),
                  const SizedBox(width: Spacing.xs),
                  // Flexible — 좁은 카드 폭(가로 폰·분할 화면)에서 칩이 넘치는
                  // 대신 말줄임한다.
                  Flexible(
                    child: Text(
                      t.deckFlipFirstHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.label.copyWith(color: SoriColors.accent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 같은 세션에 화면을 오가도 재발화 안 함 — 프로세스 전역.
bool _soriDeckCoachFiredThisSession = false;
int _soriDeckCoachResetRevision = Storage.tutorialResetRevision;

void _syncSoriDeckCoachReset() {
  final revision = Storage.tutorialResetRevision;
  if (_soriDeckCoachResetRevision != revision) {
    _soriDeckCoachResetRevision = revision;
    _soriDeckCoachFiredThisSession = false;
  }
}

/// 테스트 전용 — 세션 가드 리셋.
@visibleForTesting
void resetSoriDeckCoachForTesting() {
  _soriDeckCoachFiredThisSession = false;
  _soriDeckCoachResetRevision = Storage.tutorialResetRevision;
}

/// 4방향 덱 스와이프 1스텝 코치. [targetKey] = 카드 슬롯.
///
/// [afterCoachIds] 의 기존 화면 코치가 전부 표시된 뒤에만 발화한다 —
/// 첫 진입에서는 화면 자체 코치가 우선하고, soriDeck 은 그 다음 진입에서
/// 겹침 없이 뜬다 (기존 코치 미발화 화면이면 빈 리스트로 즉시 발화).
void maybeShowSoriDeckCoach(
  BuildContext context, {
  required GlobalKey targetKey,
  List<String> afterCoachIds = const [],
  bool supportsSave = true,
}) {
  _syncSoriDeckCoachReset();
  if (_soriDeckCoachFiredThisSession || Storage.tutSeen('soriDeck')) {
    return;
  }
  for (final id in afterCoachIds) {
    if (!Storage.tutSeen(id)) {
      return;
    }
  }
  if (targetKey.currentContext == null) {
    return;
  }
  final t = AppL10n.of(context);
  _soriDeckCoachFiredThisSession = true;
  SpotlightCoach.show(
    context,
    steps: [
      SpotlightStep(
        targetKey: targetKey,
        title: t.coachSoriDeckTitle,
        body: supportsSave ? t.coachSoriDeckBody : t.coachSoriDeckBodyNoSave,
        // 4방향 화살표 글리프 — 커스텀 페인터 대신 기존 코치 아이콘 슬롯 재사용.
        icon: Icons.open_with_rounded,
        cutoutRadius: SoriRadius.lg,
      ),
    ],
    onComplete: () {
      // ignore: discarded_futures
      Storage.setTutSeen('soriDeck');
    },
  );
}
