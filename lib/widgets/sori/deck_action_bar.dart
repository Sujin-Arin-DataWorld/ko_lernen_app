import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'motion.dart';
import 'tokens.dart';

class SoriDeckHintController extends ChangeNotifier {
  Timer? _timer;
  bool _visible = false;

  bool get visible => _visible;

  void show() {
    _timer?.cancel();
    _visible = true;
    notifyListeners();
    _timer = Timer(const Duration(seconds: 3), () {
      _visible = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class SoriDeckFlipHint extends StatelessWidget {
  const SoriDeckFlipHint({
    super.key,
    required this.controller,
    required this.child,
  });

  final SoriDeckHintController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned(
          left: Spacing.md,
          right: Spacing.md,
          top: Spacing.md,
          child: IgnorePointer(
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => AnimatedOpacity(
                opacity: controller.visible ? 1 : 0,
                duration: SoriMotion.fast,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md,
                      vertical: Spacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: SoriSurfaces.of(context).surface,
                      borderRadius: SoriRadius.brMd,
                      border: Border.all(
                        color: SoriColors.primary.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      AppL10n.of(context).deckFlipFirstHint,
                      textAlign: TextAlign.center,
                      style: SoriTextTheme.of(
                        context,
                      ).label.copyWith(color: SoriSurfaces.of(context).text),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Four-direction Sori Deck controls. Buttons are the accessible source of
/// truth; gestures are only a faster path to the same actions.
class DeckActionBar extends StatelessWidget {
  const DeckActionBar({
    super.key,
    required this.judgmentsEnabled,
    required this.onDontKnow,
    required this.onSkip,
    required this.onKnow,
    this.onSave,
    this.onBlockedJudgment,
    this.showSave = true,
  });

  final bool judgmentsEnabled;
  final VoidCallback onDontKnow;
  final VoidCallback onSkip;
  final VoidCallback onKnow;
  final VoidCallback? onSave;
  final VoidCallback? onBlockedJudgment;
  final bool showSave;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _DeckActionButton(
          semanticLabel: t.btnNichtGewusst,
          assetName: 'action_dontknow.webp',
          fallbackIcon: Icons.question_mark_rounded,
          size: 64,
          foreground: SoriColors.accent,
          background: SoriSurfaces.of(context).surface,
          border: SoriColors.accent,
          enabled: judgmentsEnabled,
          onTap: judgmentsEnabled ? onDontKnow : onBlockedJudgment,
        ),
        const SizedBox(width: Spacing.lg),
        _DeckActionButton(
          semanticLabel: t.btnSkip,
          assetName: 'action_skip.webp',
          fallbackIcon: Icons.arrow_downward_rounded,
          size: 48,
          foreground: SoriSurfaces.of(context).text,
          background: SoriSurfaces.of(context).surfaceAlt,
          onTap: onSkip,
        ),
        if (showSave) ...[
          const SizedBox(width: Spacing.lg),
          _DeckActionButton(
            semanticLabel: t.deckActionSave,
            assetName: 'action_save.webp',
            fallbackIcon: Icons.redeem_rounded,
            size: 48,
            foreground: SoriColors.goldOnLight,
            background: SoriColors.gold.withValues(alpha: 0.18),
            border: SoriColors.gold,
            onTap: onSave,
          ),
        ],
        const SizedBox(width: Spacing.lg),
        _DeckActionButton(
          semanticLabel: t.btnGewusst,
          assetName: 'action_know.webp',
          fallbackIcon: Icons.check_rounded,
          size: 64,
          foreground: SoriColors.lightBg,
          background: SoriColors.primary,
          enabled: judgmentsEnabled,
          onTap: judgmentsEnabled ? onKnow : onBlockedJudgment,
        ),
      ],
    );
  }
}

class _DeckActionButton extends StatefulWidget {
  const _DeckActionButton({
    required this.semanticLabel,
    required this.assetName,
    required this.fallbackIcon,
    required this.size,
    required this.foreground,
    required this.background,
    required this.onTap,
    this.border,
    this.enabled = true,
  });

  final String semanticLabel;
  final String assetName;
  final IconData fallbackIcon;
  final double size;
  final Color foreground;
  final Color background;
  final Color? border;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  State<_DeckActionButton> createState() => _DeckActionButtonState();
}

class _DeckActionButtonState extends State<_DeckActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final opacity = widget.enabled ? 1.0 : 0.38;
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      enabled: widget.enabled,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: SoriAnimation.tap,
        curve: SoriAnimation.tapOut,
        child: Opacity(
          opacity: opacity,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: widget.onTap == null
                ? null
                : (_) => setState(() => _pressed = true),
            onTapCancel: widget.onTap == null
                ? null
                : () => setState(() => _pressed = false),
            onTapUp: widget.onTap == null
                ? null
                : (_) => setState(() => _pressed = false),
            onTap: widget.onTap,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.background,
                shape: BoxShape.circle,
                border: widget.border == null
                    ? null
                    : Border.all(color: widget.border!, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Image.asset(
                'assets/illustrations/deck/${widget.assetName}',
                width: widget.size >= 60 ? 32 : 24,
                height: widget.size >= 60 ? 32 : 24,
                errorBuilder: (_, _, _) => Icon(
                  widget.fallbackIcon,
                  color: widget.foreground,
                  size: widget.size >= 60 ? 32 : 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
