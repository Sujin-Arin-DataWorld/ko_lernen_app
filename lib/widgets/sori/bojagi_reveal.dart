import 'dart:async';

import 'package:flutter/material.dart';

import 'placed_decoration.dart';
import 'tokens.dart';

const String kBojagiClosed =
    'assets/illustrations/reward/reward_bojagi_closed.png';
const String kBojagiOpen = 'assets/illustrations/reward/reward_bojagi_open.png';
const String kBojagiUnfolded =
    'assets/illustrations/reward/reward_bojagi_unfolded_tactile.png';
const String kNajeonChestClosed =
    'assets/illustrations/rewards/najeon/najeon_chest_closed.png';
const String kNajeonChestOpen =
    'assets/illustrations/rewards/najeon/najeon_chest_open.png';

/// One finite opening motion. A reward is supplied only after its claim
/// succeeds; the illustration never invents an item or changes ownership.
class SoriBojagiReveal extends StatefulWidget {
  const SoriBojagiReveal({
    super.key,
    this.opening = false,
    this.rewardSlug,
    this.onOpened,
    this.onRewardRevealed,
    this.najeonChest = false,
  });

  final bool opening;
  final String? rewardSlug;
  final VoidCallback? onOpened;
  final VoidCallback? onRewardRevealed;

  /// Uses the approved chest originals while preserving legacy cloth callers.
  final bool najeonChest;

  @override
  State<SoriBojagiReveal> createState() => _SoriBojagiRevealState();
}

class _SoriBojagiRevealState extends State<SoriBojagiReveal>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  bool _foreground = true;
  bool _notified = false;
  bool _rewardNotified = false;
  bool _chestPrecached = false;

  bool get _active => widget.opening || widget.rewardSlug != null;

  @override
  void initState() {
    super.initState();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _controller =
        AnimationController(
            vsync: this,
            duration: Duration(
              milliseconds: widget.rewardSlug == null ? 680 : 1050,
            ),
          )
          ..addListener(_notifyRewardRevealed)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _notifyOpened();
            }
          });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheChest();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant SoriBojagiReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    _precacheChest();
    _syncMotion();
  }

  void _precacheChest() {
    if (!widget.najeonChest || _chestPrecached) {
      return;
    }
    _chestPrecached = true;
    unawaited(precacheImage(const AssetImage(kNajeonChestClosed), context));
    unawaited(precacheImage(const AssetImage(kNajeonChestOpen), context));
  }

  void _syncMotion() {
    if (!_active) {
      return;
    }
    if (SoriMotion.reduceMotion(context)) {
      _controller.value = 1;
      _notifyOpened();
    } else if (!_foreground || !TickerMode.valuesOf(context).enabled) {
      _controller.stop();
    } else if (!_controller.isCompleted && !_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncMotion();
  }

  void _notifyOpened() {
    if (_notified || widget.rewardSlug != null || widget.onOpened == null) {
      return;
    }
    _notified = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onOpened?.call();
      }
    });
  }

  void _notifyRewardRevealed() {
    if (_rewardNotified ||
        widget.rewardSlug == null ||
        _controller.value < .78) {
      return;
    }
    _rewardNotified = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onRewardRevealed?.call();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  Widget _cloth(String asset) => Image.asset(
    asset,
    fit: BoxFit.contain,
    errorBuilder: (_, _, _) => const Icon(
      Icons.card_giftcard_rounded,
      size: 100,
      color: SoriColors.primary,
    ),
  );

  Widget _chest(double value, String? slug, Widget? reward) {
    // PR #447's sequential image handoff avoids a double lid. The originals
    // remain whole: layout compensates their different transparent margins.
    final opened = const Interval(
      .42,
      .78,
      curve: Curves.easeOutCubic,
    ).transform(value);
    final closed = 1 - const Interval(.22, .42).transform(value);
    final received = slug != null;
    final exit = received
        ? const Interval(.48, .9, curve: Curves.easeInOutCubic).transform(value)
        : 0.0;
    final rise = const Interval(
      .18,
      .78,
      curve: Curves.easeOutCubic,
    ).transform(value);
    final glow = 4 * value * (1 - value);
    return Stack(
      alignment: Alignment.center,
      children: [
        if (glow > 0)
          Positioned(
            top: 76,
            left: 20,
            right: 20,
            bottom: 28,
            child: Opacity(
              opacity: glow * (1 - exit),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF79BFD5).withValues(alpha: .24),
                      const Color(0xFF79BFD5).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (!received && closed > 0)
          Positioned(
            bottom: 0,
            width: 240,
            height: 240,
            child: Opacity(opacity: closed, child: _cloth(kNajeonChestClosed)),
          ),
        if ((received || opened > 0) && exit < 1)
          Positioned(
            // The closed original's visible base is 7.2% above its PNG edge.
            // Match that base with the open original, whose base reaches it.
            bottom: 240 * .072,
            width: 240 * 1.05,
            height: 240 * 1.05 * 1278 / 1230,
            child: Opacity(
              opacity: (received ? 1 : opened) * (1 - exit),
              child: _cloth(kNajeonChestOpen),
            ),
          ),
        if (received)
          Positioned(
            top: 12,
            left: 52,
            right: 52,
            height: 176,
            child: Opacity(
              opacity: rise,
              child: Transform.translate(
                offset: Offset(0, 64 * (1 - rise)),
                child: Transform.scale(scale: .9 + .1 * rise, child: reward),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final slug = widget.rewardSlug;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          width: 280,
          height: 280,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 280,
              height: 280,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final value = _controller.value;
                  if (widget.najeonChest) {
                    return _chest(value, slug, child);
                  }
                  final cloth = Curves.easeInOutCubic.transform(value);
                  final rise = const Interval(
                    .18,
                    .78,
                    curve: Curves.easeOutCubic,
                  ).transform(value);
                  final settle = const Interval(
                    .78,
                    1,
                    curve: Curves.easeOutCubic,
                  ).transform(value);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      if (value < 1)
                        Opacity(
                          opacity: 1 - cloth,
                          child: Transform.scale(
                            scale: 1 - .08 * cloth,
                            child: _cloth(
                              slug == null ? kBojagiClosed : kBojagiOpen,
                            ),
                          ),
                        ),
                      if (value > 0)
                        Opacity(
                          opacity: cloth,
                          child: Transform.scale(
                            scale: .86 + .14 * cloth,
                            child: _cloth(kBojagiUnfolded),
                          ),
                        ),
                      if (slug != null)
                        Positioned(
                          top: 12,
                          left: 52,
                          right: 52,
                          height: 176,
                          child: Opacity(
                            opacity: rise,
                            child: Transform.translate(
                              offset: Offset(
                                0,
                                64 * (1 - rise) - 8 * rise * (1 - settle),
                              ),
                              child: Transform.scale(
                                scale: .82 + .22 * rise - .04 * settle,
                                child: child,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
                child: slug == null
                    ? null
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              SoriColors.accent.withValues(alpha: .16),
                              SoriColors.accent.withValues(alpha: 0),
                            ],
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SoriDecorationImage(slug: slug, size: 160),
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
