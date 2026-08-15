import 'package:flutter/material.dart';

import 'pressable.dart';
import 'tokens.dart';

/// Enable only after Jin approves and the custom WebP set is actually bundled.
/// Keeping this false avoids noisy missing-asset requests on Flutter web while
/// preserving the intentional Material fallback for the first release.
const bool _deckCustomAssetsReady = false;

/// Stable finder shared by the four deck surfaces and their regression tests.
ValueKey<String> deckActionKey(String name) => ValueKey('deck-action-$name');

/// **SoriDeckActionBar** — 덱 화면 하단 미니 원형 아이콘 버튼 바
/// (Sori Deck 2.0 §P2-3, 2026-08-14).
///
/// 대형 텍스트 CTA("Gewusst/Weiß ich nicht")를 대체하는 4버튼 원형 바 —
/// Jin 확정(§1-2): 모름 아이콘은 X 가 아니라 **`?`**.
///
/// ```
/// [? 모름] 64dp · lightSurfaceRaised + accent 1.5px 테두리 · 판정 게이트
/// [↓ 스킵] 48dp · lightSurfaceAlt                          · 다음 카드가 있을 때
/// [복주머니 저장] 48dp · gold@0.18 + gold 1.5px 테두리     · 항상 활성
/// [✓ 앎]  64dp · primary 채움(아이콘 라이트)               · 판정 게이트
/// ```
///
/// 아이콘은 `assets/illustrations/deck/action_*.webp` 커스텀(단청 도장 계열,
/// §R-3) — Material 아이콘은 errorBuilder **폴백으로만** (폴백 우선 배포).
///
/// 판정 2개([onDontKnow]/[onKnow])는 [judgmentsEnabled] 게이트 대상 —
/// 플립 전에는 opacity 0.38 + 탭 시 [onBlockedJudgmentTap](힌트 칩)만 발화.
/// 이 게이트는 flipgate 계약의 **강화**(버튼까지 확장)다 — 절대 완화 금지.
class SoriDeckActionBar extends StatelessWidget {
  const SoriDeckActionBar({
    super.key,
    required this.onDontKnow,
    required this.onKnow,
    required this.onSkip,
    this.onSave,
    this.judgmentsEnabled = true,
    this.onBlockedJudgmentTap,
    this.showSave = true,
    this.skipEnabled = true,
    required this.dontKnowLabel,
    required this.knowLabel,
    required this.skipLabel,
    required this.saveLabel,
  });

  /// 판정: 모름 — 화면의 기존 핸들러 경유 (SRS 직접 호출 신설 금지).
  final VoidCallback? onDontKnow;

  /// 판정: 앎 — 화면의 기존 핸들러 경유.
  final VoidCallback? onKnow;

  /// 스킵(↓와 동일 의미) — 다음 카드가 있을 때 활성.
  final VoidCallback? onSkip;

  /// 저장(↑와 동일 의미) — 항상 활성. [showSave] false 면 미노출.
  final VoidCallback? onSave;

  /// 좌/우 판정 허용 (= 카드 플립 후). false 면 판정 버튼이 딤 + 힌트만.
  final bool judgmentsEnabled;

  /// 플립 전 판정 버튼 탭 → 힌트 훅.
  final VoidCallback? onBlockedJudgmentTap;

  /// custom 팩처럼 ↑ 저장이 무의미한 화면은 false (§P2-2).
  final bool showSave;

  /// False when there is no next card to defer (review deck last card).
  final bool skipEnabled;

  final String dontKnowLabel;
  final String knowLabel;
  final String skipLabel;
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final isLight = s.brightness == Brightness.light;
    return Row(
      key: const ValueKey('deck-action-bar'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _DeckActionButton(
          key: deckActionKey('dontknow'),
          label: dontKnowLabel,
          assetName: 'action_dontknow',
          fallbackIcon: Icons.question_mark_rounded,
          diameter: 64,
          iconSize: 32,
          background: isLight ? SoriColors.lightSurfaceRaised : s.surface,
          border: Border.all(color: SoriColors.accent, width: 1.5),
          iconColor: SoriColors.accent,
          onTap: judgmentsEnabled ? onDontKnow : onBlockedJudgmentTap,
          dimmed: !judgmentsEnabled,
        ),
        const SizedBox(width: Spacing.lg),
        _DeckActionButton(
          key: deckActionKey('skip'),
          label: skipLabel,
          assetName: 'action_skip',
          fallbackIcon: Icons.arrow_downward_rounded,
          diameter: 48,
          iconSize: 24,
          background: s.surfaceAlt,
          iconColor: s.text,
          onTap: skipEnabled ? onSkip : null,
          dimmed: !skipEnabled,
        ),
        if (showSave) ...[
          const SizedBox(width: Spacing.lg),
          _DeckActionButton(
            key: deckActionKey('save'),
            label: saveLabel,
            assetName: 'action_save',
            fallbackIcon: Icons.redeem_rounded,
            diameter: 48,
            iconSize: 24,
            background: SoriColors.gold.withValues(alpha: 0.18),
            border: Border.all(color: SoriColors.gold, width: 1.5),
            iconColor: isLight ? SoriColors.goldOnLight : SoriColors.gold,
            onTap: onSave,
          ),
        ],
        const SizedBox(width: Spacing.lg),
        _DeckActionButton(
          key: deckActionKey('know'),
          label: knowLabel,
          assetName: 'action_know',
          fallbackIcon: Icons.check_rounded,
          diameter: 64,
          iconSize: 32,
          background: SoriColors.primary,
          iconColor: SoriColors.lightBg,
          onTap: judgmentsEnabled ? onKnow : onBlockedJudgmentTap,
          dimmed: !judgmentsEnabled,
        ),
      ],
    );
  }
}

class _DeckActionButton extends StatelessWidget {
  const _DeckActionButton({
    super.key,
    required this.label,
    required this.assetName,
    required this.fallbackIcon,
    required this.diameter,
    required this.iconSize,
    required this.background,
    required this.iconColor,
    required this.onTap,
    this.border,
    this.dimmed = false,
  });

  final String label;
  final String assetName;
  final IconData fallbackIcon;
  final double diameter;
  final double iconSize;
  final Color background;
  final Border? border;
  final Color iconColor;
  final VoidCallback? onTap;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final Widget icon = _deckCustomAssetsReady
        ? Image.asset(
            'assets/illustrations/deck/$assetName.webp',
            width: iconSize,
            height: iconSize,
            errorBuilder: (_, _, _) =>
                Icon(fallbackIcon, size: iconSize, color: iconColor),
          )
        : Icon(fallbackIcon, size: iconSize, color: iconColor);
    return Semantics(
      button: true,
      // A visually dimmed judgment still performs the flip-first hint. Keep
      // that action exposed to assistive technology; truly unavailable
      // actions (for example Skip on the final card) have no tap action.
      enabled: onTap != null,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: SoriPressable(
          onTap: onTap,
          pressScale: 0.94,
          haptic: SoriHaptic.selection,
          // 시각 원은 48~64dp — 탭 타깃은 최소 48dp 를 항상 충족.
          child: Opacity(
            opacity: dimmed ? 0.38 : 1.0,
            child: Container(
              width: diameter,
              height: diameter,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
                border: border,
              ),
              alignment: Alignment.center,
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}
