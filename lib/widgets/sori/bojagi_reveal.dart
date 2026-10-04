import 'package:flutter/material.dart';

import 'placed_decoration.dart';
import 'tokens.dart';

const String kBojagiClosed =
    'assets/illustrations/reward/reward_bojagi_closed.png';
const String kBojagiOpen = 'assets/illustrations/reward/reward_bojagi_open.png';
const String kBojagiUnfolded =
    'assets/illustrations/reward/reward_bojagi_unfolded_tactile.png';

/// One finite cloth-opening motion. A reward is supplied only after its claim
/// succeeds; the illustration never invents an item or changes ownership.
class SoriBojagiReveal extends StatefulWidget {
  const SoriBojagiReveal({
    super.key,
    this.opening = false,
    this.rewardSlug,
    this.onOpened,
    this.onRewardRevealed,
  });

  final bool opening;
  final String? rewardSlug;
  final VoidCallback? onOpened;
  final VoidCallback? onRewardRevealed;

  @override
  State<SoriBojagiReveal> createState() => _SoriBojagiRevealState();
}

class _SoriBojagiRevealState extends State<SoriBojagiReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;
  bool _notified = false;
  bool _rewardNotified = false;

  bool get _active => widget.opening || widget.rewardSlug != null;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
            vsync: this,
            duration: Duration(
              milliseconds: widget.rewardSlug == null ? 680 : 1050,
            ),
          )
          ..addListener(_notifyRewardRevealed)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) _notifyOpened();
          });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant SoriBojagiReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
    if (!_active) return;
    if (SoriMotion.reduceMotion(context)) {
      _started = true;
      _controller.value = 1;
      _notifyOpened();
    } else if (!_started) {
      _started = true;
      _controller.forward();
    }
  }

  void _notifyOpened() {
    if (_notified || widget.rewardSlug != null || widget.onOpened == null) {
      return;
    }
    _notified = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onOpened?.call();
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
      if (mounted) widget.onRewardRevealed?.call();
    });
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final slug = widget.rewardSlug;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          width: 280,
          height: 280,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final value = _controller.value;
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
    );
  }
}
