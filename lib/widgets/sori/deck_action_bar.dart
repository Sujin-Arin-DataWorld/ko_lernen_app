import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'motion.dart';
import 'tokens.dart';

/// 학습 덱 하단 미니 원형 액션 바 (UI/UX 개편 2 §P2-3).
///
/// [? 모름] [↓ 스킵] [저장] [✓ 앎] — 대형 텍스트 CTA 교체.
/// Material 아이콘은 커스텀 에셋 errorBuilder 폴백.
class SoriDeckActionBar extends StatefulWidget {
  const SoriDeckActionBar({
    super.key,
    required this.onDontKnow,
    required this.onKnow,
    required this.onSkip,
    this.onSave,
    this.showSave = true,
    this.judgmentEnabled = true,
    this.onJudgmentBlocked,
    required this.dontKnowLabel,
    required this.knowLabel,
    required this.skipLabel,
    required this.saveLabel,
  });

  final VoidCallback onDontKnow;
  final VoidCallback onKnow;
  final VoidCallback onSkip;
  final VoidCallback? onSave;
  final bool showSave;

  /// 플립 게이트 — false 면 판정 버튼 반투명 + [onJudgmentBlocked].
  final bool judgmentEnabled;
  final VoidCallback? onJudgmentBlocked;

  final String dontKnowLabel;
  final String knowLabel;
  final String skipLabel;
  final String saveLabel;

  @override
  State<SoriDeckActionBar> createState() => _SoriDeckActionBarState();
}

class _SoriDeckActionBarState extends State<SoriDeckActionBar> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _DeckActionButton(
          size: 64,
          label: widget.dontKnowLabel,
          asset: 'assets/illustrations/deck/action_dontknow.webp',
          fallbackIcon: Icons.question_mark_rounded,
          background: SoriColors.lightSurfaceRaised,
          borderColor: SoriColors.accent,
          iconColor: SoriColors.accent,
          iconSize: 32,
          enabled: widget.judgmentEnabled,
          dimmedWhenDisabled: true,
          onTap: () {
            if (!widget.judgmentEnabled) {
              widget.onJudgmentBlocked?.call();
              return;
            }
            widget.onDontKnow();
          },
        ),
        const SizedBox(width: Spacing.lg),
        _DeckActionButton(
          size: 48,
          label: widget.skipLabel,
          asset: 'assets/illustrations/deck/action_skip.webp',
          fallbackIcon: Icons.arrow_downward_rounded,
          background: SoriColors.lightSurfaceAlt,
          iconColor: SoriSurfaces.of(context).text,
          iconSize: 24,
          onTap: widget.onSkip,
        ),
        if (widget.showSave) ...[
          const SizedBox(width: Spacing.lg),
          _DeckActionButton(
            size: 48,
            label: widget.saveLabel,
            asset: 'assets/illustrations/deck/action_save.webp',
            fallbackIcon: Icons.redeem_rounded,
            background: SoriColors.gold.withValues(alpha: 0.18),
            borderColor: SoriColors.gold,
            iconColor: SoriColors.gold,
            iconSize: 24,
            onTap: widget.onSave,
          ),
        ],
        const SizedBox(width: Spacing.lg),
        _DeckActionButton(
          size: 64,
          label: widget.knowLabel,
          asset: 'assets/illustrations/deck/action_know.webp',
          fallbackIcon: Icons.check_rounded,
          background: SoriColors.primary,
          iconColor: Colors.white,
          iconSize: 32,
          enabled: widget.judgmentEnabled,
          dimmedWhenDisabled: true,
          onTap: () {
            if (!widget.judgmentEnabled) {
              widget.onJudgmentBlocked?.call();
              return;
            }
            widget.onKnow();
          },
        ),
      ],
    );
  }
}

class _DeckActionButton extends StatefulWidget {
  const _DeckActionButton({
    required this.size,
    required this.label,
    required this.asset,
    required this.fallbackIcon,
    required this.background,
    required this.iconColor,
    required this.iconSize,
    this.borderColor,
    this.enabled = true,
    this.dimmedWhenDisabled = false,
    this.onTap,
  });

  final double size;
  final String label;
  final String asset;
  final IconData fallbackIcon;
  final Color background;
  final Color iconColor;
  final double iconSize;
  final Color? borderColor;
  final bool enabled;
  final bool dimmedWhenDisabled;
  final VoidCallback? onTap;

  @override
  State<_DeckActionButton> createState() => _DeckActionButtonState();
}

class _DeckActionButtonState extends State<_DeckActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: SoriAnimation.tap,
      reverseDuration: SoriAnimation.tap,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dim = widget.dimmedWhenDisabled && !widget.enabled;
    final opacity = dim ? 0.38 : 1.0;
    return Semantics(
      button: true,
      label: widget.label,
      enabled: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          // ignore: discarded_futures
          _ctrl.forward();
        },
        onTapUp: (_) {
          // ignore: discarded_futures
          _ctrl.reverse();
          // ignore: discarded_futures
          HapticFeedback.selectionClick();
          widget.onTap?.call();
        },
        onTapCancel: () {
          // ignore: discarded_futures
          _ctrl.reverse();
        },
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            final scale = 1.0 - 0.06 * _ctrl.value;
            return Transform.scale(scale: scale, child: child);
          },
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: widget.size,
              height: widget.size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.background,
                shape: BoxShape.circle,
                border: widget.borderColor == null
                    ? null
                    : Border.all(color: widget.borderColor!, width: 1.5),
              ),
              child: Image.asset(
                widget.asset,
                width: widget.iconSize,
                height: widget.iconSize,
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
    );
  }
}
