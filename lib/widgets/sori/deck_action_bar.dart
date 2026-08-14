import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/storage_service.dart';
import 'chip.dart';
import 'motion.dart';
import 'pressable.dart';
import 'spotlight_coach.dart';
import 'tokens.dart';

/// 덱 액션 아이콘의 규약 경로. 에셋이 없으면 [_DeckActionButton] 이 Material
/// 아이콘으로 폴백하므로 **아트는 배포 블로커가 아니다** (폴백 우선 배포).
String deckActionAsset(String name) =>
    'assets/illustrations/deck/action_$name.webp';

/// 덱 액션 버튼의 안정 키 — 4화면 공통 finder (테스트·코치 타깃).
/// name ∈ {dontknow, skip, save, know}.
ValueKey<String> deckActionKey(String name) => ValueKey('deck-action-$name');

/// **DeckActionBar** — 4방향 덱의 하단 미니 아이콘 버튼 바 (Sori Deck 2.0).
///
/// 예전의 대형 텍스트 CTA 두 개("Gewusst" / "Weiß ich nicht")를 대체한다.
/// 스와이프가 가속 경로라면 이 바가 **접근성 정본**이다 — 스위치 컨트롤·
/// 큰 손가락·모터 장애 사용자는 여기로 같은 4가지 동작을 전부 할 수 있다.
///
/// 배치는 스와이프 방향의 공간 은유를 그대로 따른다:
/// 모름(좌) · 스킵(아래) · 저장(위) · 앎(우) 순서로, 판정 두 개가 양 끝의
/// 큰 원이고 보조 동작 두 개가 가운데 작은 원이다.
///
/// 판정 두 개는 [judgmentEnabled] 가 false 면 흐려지고, 눌러도 판정 대신
/// [onBlockedJudgment] (플립 먼저 하라는 힌트)를 부른다 — 플립 게이트를
/// 버튼까지 확장한 것이다.
class DeckActionBar extends StatelessWidget {
  const DeckActionBar({
    super.key,
    required this.onDontKnow,
    required this.onKnow,
    required this.onSkip,
    this.onSave,
    this.judgmentEnabled = true,
    this.onBlockedJudgment,
    this.dontKnowLabel,
    this.knowLabel,
  });

  final VoidCallback onDontKnow;
  final VoidCallback onKnow;
  final VoidCallback onSkip;

  /// null 이면 저장 버튼을 숨긴다 (예: custom pack — 이미 사용자 팩 소속).
  final VoidCallback? onSave;

  /// 플립 게이트. false 면 판정 두 개가 비활성 표시된다.
  final bool judgmentEnabled;

  /// 비활성 상태에서 판정 버튼을 눌렀을 때 (힌트 표시).
  final VoidCallback? onBlockedJudgment;

  /// 화면별 판정 라벨 — 기본은 `btnNichtGewusst`/`btnGewusst`.
  final String? dontKnowLabel;
  final String? knowLabel;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final VoidCallback? save = onSave;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _DeckActionButton(
          key: deckActionKey('dontknow'),
          asset: deckActionAsset('dontknow'),
          // 모름은 X 가 아니라 물음표다 — 틀린 게 아니라 아직 모르는 것.
          fallbackIcon: Icons.question_mark_rounded,
          label: dontKnowLabel ?? t.btnNichtGewusst,
          diameter: 64,
          iconSize: 32,
          background: SoriColors.lightSurfaceRaised,
          border: SoriColors.accent,
          foreground: SoriColors.accent,
          enabled: judgmentEnabled,
          onTap: judgmentEnabled ? onDontKnow : onBlockedJudgment,
        ),
        const SizedBox(width: Spacing.lg),
        _DeckActionButton(
          key: deckActionKey('skip'),
          asset: deckActionAsset('skip'),
          fallbackIcon: Icons.arrow_downward_rounded,
          label: t.btnSkip,
          diameter: 48,
          iconSize: 24,
          background: SoriColors.lightSurfaceAlt,
          foreground: SoriColors.lightTextMuted,
          onTap: onSkip,
        ),
        if (save != null) ...[
          const SizedBox(width: Spacing.lg),
          _DeckActionButton(
            key: deckActionKey('save'),
            asset: deckActionAsset('save'),
            fallbackIcon: Icons.redeem_rounded,
            label: t.deckActionSave,
            diameter: 48,
            iconSize: 24,
            background: SoriColors.gold.withValues(alpha: 0.18),
            border: SoriColors.gold,
            foreground: SoriColors.gold,
            onTap: save,
          ),
        ],
        const SizedBox(width: Spacing.lg),
        _DeckActionButton(
          key: deckActionKey('know'),
          asset: deckActionAsset('know'),
          fallbackIcon: Icons.check_rounded,
          label: knowLabel ?? t.btnGewusst,
          diameter: 64,
          iconSize: 32,
          background: SoriColors.primary,
          foreground: Colors.white,
          filled: true,
          enabled: judgmentEnabled,
          onTap: judgmentEnabled ? onKnow : onBlockedJudgment,
        ),
      ],
    );
  }
}

/// 프로세스 세션 1회 가드 — 같은 실행 안에서 화면을 여러 번 오가도 덱 코치를
/// 두 번 띄우지 않는다 (저장 플래그는 비동기라 첫 왕복에서 늦을 수 있다).
bool _soriDeckCoachShownThisSession = false;

/// 4방향 덱 코치마크를 **첫 1회만** 띄운다.
///
/// `ScreenCoachMixin` 을 쓸 수 없다: 그건 State 당 coachId 가 하나라
/// 이미 'review'·'legacyVocab'·'cpPlay' 를 쓰고 있는 세 화면과 공존할 수
/// 없다. 그래서 같은 저장 플래그 체계(`kl_tut_soriDeck`)만 공유하는 헬퍼로
/// 둔다 — `Storage.kScreenCoachIds` 에 등록돼 있어 "튜토리얼 초기화"가
/// 이것도 함께 되돌린다.
Future<void> maybeShowSoriDeckCoach(
  BuildContext context,
  GlobalKey targetKey,
) async {
  if (_soriDeckCoachShownThisSession || Storage.tutSeen(kSoriDeckCoachId)) {
    return;
  }
  if (targetKey.currentContext == null) {
    return;
  }
  _soriDeckCoachShownThisSession = true;
  final t = AppL10n.of(context);
  SpotlightCoach.show(
    context,
    steps: [
      SpotlightStep(
        targetKey: targetKey,
        title: t.deckActionSave,
        body: t.coachSoriDeckBody,
        icon: Icons.swipe_rounded,
      ),
    ],
    onComplete: () {
      // ignore: discarded_futures
      Storage.setTutSeen(kSoriDeckCoachId);
    },
  );
}

/// `Storage.kScreenCoachIds` 에 등록된 덱 코치 id.
const String kSoriDeckCoachId = 'soriDeck';

/// 테스트용 — 프로세스 세션 가드 리셋.
@visibleForTesting
void resetSoriDeckCoachSessionGuard() => _soriDeckCoachShownThisSession = false;

/// 플립 전 판정을 시도했을 때 카드 위에 잠깐 뜨는 힌트 칩.
///
/// 스와이프가 "안 먹는" 게 아니라 **아직 순서가 아니라는 것**을 말해 준다 —
/// 저항 드래그(카드가 손가락을 15% 만 따라감)와 짝을 이루는 설명이다.
///
/// 표시 수명은 이 위젯이 소유한다: 화면은 [trigger] 카운터만 올리면 되고,
/// 3초 타이머는 여기서 만들고 `dispose` 에서 취소한다 — 화면마다 타이머를
/// 들고 있으면 위젯이 사라진 뒤에도 살아남는다.
class DeckFlipHint extends StatefulWidget {
  const DeckFlipHint({super.key, required this.trigger});

  /// 값이 바뀔 때마다 힌트를 3초간 보여 준다. 0 이면 표시하지 않는다.
  final int trigger;

  @override
  State<DeckFlipHint> createState() => _DeckFlipHintState();
}

class _DeckFlipHintState extends State<DeckFlipHint> {
  static const Duration _visibleFor = Duration(seconds: 3);

  Timer? _timer;
  bool _visible = false;

  @override
  void didUpdateWidget(covariant DeckFlipHint old) {
    super.didUpdateWidget(old);
    if (widget.trigger != old.trigger && widget.trigger > 0) {
      _show();
    }
  }

  void _show() {
    _timer?.cancel();
    if (!_visible) {
      setState(() => _visible = true);
    }
    _timer = Timer(_visibleFor, () {
      if (mounted) {
        setState(() => _visible = false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: SoriMotion.fast,
        child: Padding(
          padding: const EdgeInsets.only(top: Spacing.md),
          child: SoriChip(
            label: AppL10n.of(context).deckFlipFirstHint,
            accent: SoriColors.gold,
            variant: SoriChipVariant.filled,
          ),
        ),
      ),
    );
  }
}

class _DeckActionButton extends StatelessWidget {
  const _DeckActionButton({
    super.key,
    required this.asset,
    required this.fallbackIcon,
    required this.label,
    required this.diameter,
    required this.iconSize,
    required this.background,
    required this.foreground,
    this.border,
    this.filled = false,
    this.enabled = true,
    required this.onTap,
  });

  final String asset;
  final IconData fallbackIcon;
  final String label;
  final double diameter;
  final double iconSize;
  final Color background;
  final Color foreground;
  final Color? border;
  final bool filled;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color? border = this.border;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: SoriPressable(
        onTap: onTap,
        haptic: SoriHaptic.light,
        pressScale: 0.94,
        child: AnimatedOpacity(
          // 판정이 잠겨 있음을 **투명도**로 말한다 — 버튼은 사라지지 않고
          // 자리를 지켜 위 카드의 지오메트리가 흔들리지 않는다.
          opacity: enabled ? 1 : 0.38,
          duration: SoriAnimation.quick,
          child: Container(
            width: diameter,
            height: diameter,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              border: border == null
                  ? null
                  : Border.all(color: border, width: 1.5),
              boxShadow: filled ? SoriElevation.low : null,
            ),
            child: Image.asset(
              asset,
              width: iconSize,
              height: iconSize,
              // 아트가 아직 없으면 Material 아이콘으로 — 배포 블로커 아님.
              errorBuilder: (_, _, _) =>
                  Icon(fallbackIcon, size: iconSize, color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}
