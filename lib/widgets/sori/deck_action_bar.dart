import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'motion.dart';
import 'tokens.dart';

/// **DeckActionBar** — Sori Deck 2.0 미니 원형 4-아이콘 액션 바 (2026-08-14).
///
/// 4버튼 구성:
/// - [?  모름]: 64dp 원형 · lightSurfaceRaised 바탕 + accent(#A0524A) 1.5px 테두리 · 판정 게이트
/// - [↓ 스킵]: 48dp 원형 · lightSurfaceAlt 바탕 · 항상 활성
/// - [복주머니 저장]: 48dp 원형 · gold@0.18 바탕 + gold 1.5px 테두리 (showSave: false 숨김 가능) · 항상 활성
/// - [✓ 앎]: 64dp 원형 · primary(#1F7A6B) 채움 (아이콘은 라이트) · 판정 게이트
class DeckActionBar extends StatelessWidget {
  const DeckActionBar({
    super.key,
    required this.onDontKnow,
    required this.onSkip,
    this.onSave,
    required this.onKnow,
    this.enabled = true,
    this.showSave = true,
    this.onBlockedJudgmentTap,
    this.dontKnowSemantics,
    this.knowSemantics,
    this.skipSemantics,
    this.saveSemantics,
  });

  final VoidCallback? onDontKnow;
  final VoidCallback? onSkip;
  final VoidCallback? onSave;
  final VoidCallback? onKnow;
  final bool enabled;
  final bool showSave;
  final VoidCallback? onBlockedJudgmentTap;
  final String? dontKnowSemantics;
  final String? knowSemantics;
  final String? skipSemantics;
  final String? saveSemantics;

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1. 모름 (?) 버튼 (64dp)
        _CircleActionButton(
          size: 64,
          iconSize: 30,
          backgroundColor: s.surfaceRaised,
          borderColor: SoriColors.accent,
          borderWidth: 1.5,
          assetPath: 'assets/illustrations/deck/action_dontknow.webp',
          fallbackIcon: Icons.question_mark_rounded,
          iconColor: SoriColors.accent,
          enabled: true,
          dimmed: !enabled,
          semanticsLabel: dontKnowSemantics ?? 'Nicht gewusst',
          onTap: () {
            if (!enabled) {
              onBlockedJudgmentTap?.call();
            } else {
              onDontKnow?.call();
            }
          },
        ),
        const SizedBox(width: Spacing.lg),

        // 2. 스킵 (↓) 버튼 (48dp)
        _CircleActionButton(
          size: 48,
          iconSize: 22,
          backgroundColor: s.surfaceAlt,
          borderColor: Colors.transparent,
          borderWidth: 0,
          assetPath: 'assets/illustrations/deck/action_skip.webp',
          fallbackIcon: Icons.arrow_downward_rounded,
          iconColor: s.textMuted,
          enabled: true,
          dimmed: false,
          semanticsLabel: skipSemantics ?? 'Überspringen',
          onTap: onSkip,
        ),

        // 3. 저장 (복주머니) 버튼 (48dp)
        if (showSave) ...[
          const SizedBox(width: Spacing.lg),
          _CircleActionButton(
            size: 48,
            iconSize: 22,
            backgroundColor: SoriColors.gold.withValues(alpha: 0.18),
            borderColor: SoriColors.gold,
            borderWidth: 1.5,
            assetPath: 'assets/illustrations/deck/action_save.webp',
            fallbackIcon: Icons.redeem_rounded,
            iconColor: SoriColors.goldOnLight,
            enabled: true,
            dimmed: false,
            semanticsLabel: saveSemantics ?? 'Speichern',
            onTap: onSave,
          ),
        ],

        const SizedBox(width: Spacing.lg),

        // 4. 앎 (✓) 버튼 (64dp)
        _CircleActionButton(
          size: 64,
          iconSize: 32,
          backgroundColor: SoriColors.primary,
          borderColor: Colors.transparent,
          borderWidth: 0,
          assetPath: 'assets/illustrations/deck/action_know.webp',
          fallbackIcon: Icons.check_rounded,
          iconColor: Colors.white,
          enabled: true,
          dimmed: !enabled,
          semanticsLabel: knowSemantics ?? 'Gewusst',
          onTap: () {
            if (!enabled) {
              onBlockedJudgmentTap?.call();
            } else {
              onKnow?.call();
            }
          },
        ),
      ],
    );
  }
}

class _CircleActionButton extends StatefulWidget {
  const _CircleActionButton({
    required this.size,
    required this.iconSize,
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.assetPath,
    required this.fallbackIcon,
    required this.iconColor,
    required this.enabled,
    required this.dimmed,
    required this.semanticsLabel,
    required this.onTap,
  });

  final double size;
  final double iconSize;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final String assetPath;
  final IconData fallbackIcon;
  final Color iconColor;
  final bool enabled;
  final bool dimmed;
  final String semanticsLabel;
  final VoidCallback? onTap;

  @override
  State<_CircleActionButton> createState() => _CircleActionButtonState();
}

class _CircleActionButtonState extends State<_CircleActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled
            ? (_) {
                setState(() => _pressed = false);
                HapticFeedback.selectionClick();
                widget.onTap?.call();
              }
            : null,
        onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1.0,
          duration: SoriAnimation.tap,
          curve: SoriAnimation.tapOut,
          child: Opacity(
            opacity: widget.dimmed ? 0.38 : 1.0,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                shape: BoxShape.circle,
                border: widget.borderWidth > 0
                    ? Border.all(color: widget.borderColor, width: widget.borderWidth)
                    : null,
                boxShadow: SoriElevation.low,
              ),
              child: Center(
                child: SizedBox(
                  width: widget.iconSize,
                  height: widget.iconSize,
                  child: Image.asset(
                    widget.assetPath,
                    width: widget.iconSize,
                    height: widget.iconSize,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      widget.fallbackIcon,
                      size: widget.iconSize,
                      color: widget.iconColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
