import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/storage_service.dart';
import 'yeopjeon_material.dart';
import 'yeopjeon_reward_style.dart';

/// Count only the confirmed receipt, using the wallet's presentation clock.
class YeopjeonEarnedAmount extends StatelessWidget {
  const YeopjeonEarnedAmount({
    super.key,
    required this.amount,
    required this.started,
    required this.settled,
    required this.presentationMs,
  });
  final int amount;
  final bool started, settled;
  final double presentationMs;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final progress = (presentationMs / 840).clamp(0.0, 1.0);
    final value = settled || progress >= 1
        ? amount
        : (amount * math.sin(progress * math.pi / 2)).floor();
    final digits = amount.toString().length;
    final size = digits <= 2 ? 44.0 : math.max(24.0, 40 * 4 / (digits + 1));
    return Semantics(
      key: const ValueKey('reward-final-announcement'),
      liveRegion: settled && started,
      excludeSemantics: true,
      label: settled
          ? '${t.cRewardConfirmed} +$amount ${t.cRewardCurrency}'
          : '+$amount ${t.cRewardCurrency}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const YeopjeonCoinImage(size: 30),
          const SizedBox(height: 6),
          SizedBox(
            key: const ValueKey('reward-confirmed-amount'),
            height: MediaQuery.textScalerOf(context).scale(size) * 1.1,
            width: double.infinity,
            child: Center(
              child: Text(
                started || settled ? '+$value' : t.cRewardEarnedLabel,
                key: const ValueKey('reward-earned-value'),
                style:
                    YeopjeonRewardStyle.text(
                      started || settled ? size : 14,
                      bold: started || settled,
                      color: YeopjeonRewardStyle.jade,
                    ).copyWith(
                      height: 1.1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t.cRewardCurrency,
            style: YeopjeonRewardStyle.text(
              14,
              color: YeopjeonRewardStyle.jade,
            ),
          ),
        ],
      ),
    );
  }
}

/// Presentation only: one finite local credit timeline, no wallet writes.
class YeopjeonCreditBadge extends StatefulWidget {
  const YeopjeonCreditBadge({
    super.key,
    required this.receiptId,
    required this.balance,
    required this.fromBalance,
    required this.start,
    this.onTap,
    this.reduceMotion = false,
    this.onPresentation,
  });
  final String receiptId;
  final int balance;
  final int? fromBalance;
  final bool start, reduceMotion;
  final VoidCallback? onTap;
  final ValueChanged<double>? onPresentation;
  @override
  State<YeopjeonCreditBadge> createState() => _YeopjeonCreditBadgeState();
}

class _YeopjeonCreditBadgeState extends State<YeopjeonCreditBadge>
    with SingleTickerProviderStateMixin {
  static const _steps = [80, 170, 260, 350, 460, 590, 740];
  static const _fractions = [.1, .28, .47, .67, .82, .93, 1.0];
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1040),
    animationBehavior: AnimationBehavior.preserve,
  );
  bool _consumed = false;
  bool _presentationPending = false;

  @override
  void initState() {
    super.initState();
    _motion.addListener(_present);
  }

  void _present() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      // Skip/reduced-motion updates can settle the controller during build.
      // Notify the sibling goal after this frame, never while it is building.
      if (_presentationPending) return;
      _presentationPending = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _presentationPending = false;
        if (mounted) widget.onPresentation?.call(_motion.value * 1040);
      });
      return;
    }
    widget.onPresentation?.call(_motion.value * 1040);
  }

  bool get _static =>
      widget.reduceMotion ||
      Storage.reducedMotion ||
      MediaQuery.disableAnimationsOf(context) ||
      !TickerMode.valuesOf(context).enabled ||
      widget.fromBalance == null ||
      widget.fromBalance! >= widget.balance;

  void _sync() {
    if (_static) {
      _consumed = true;
      _motion.value = 1;
    } else if (widget.start && !_consumed) {
      _consumed = true;
      _motion.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(YeopjeonCreditBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.receiptId != widget.receiptId) {
      _motion.stop();
      _motion.value = 0;
      _consumed = false;
    } else if (oldWidget.balance != widget.balance) {
      _motion.stop();
      _motion.value = 1;
      _consumed = true;
    }
    _sync();
  }

  int _value(int step) => step < 0
      ? widget.fromBalance!
      : math.min(
          widget.balance,
          widget.fromBalance! +
              math.max(
                1,
                ((widget.balance - widget.fromBalance!) * _fractions[step])
                    .round(),
              ),
        );

  @override
  Widget build(BuildContext context) {
    final label = AppL10n.of(context).yeopjeonBalance(widget.balance);
    final style = const TextStyle(
      fontFamily: 'Paperlogy',
      fontSize: 16,
      height: 1.25,
      color: Color(0xff1c2520),
      fontWeight: FontWeight.w600,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    final digits = math.max(3, widget.balance.toString().length);
    final line = 28 * MediaQuery.textScalerOf(context).scale(16) / 16;
    final width = TextPainter(
      text: TextSpan(text: '8' * digits, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final slotWidth = width.width + 2;
    width.dispose();
    return Semantics(
      button: widget.onTap != null,
      label: label,
      onTap: widget.onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _motion,
            builder: (context, _) {
              final ms = _motion.value * 1040;
              final finalValue = _static || ms >= 840;
              var step = -1;
              for (var i = 0; i < _steps.length; i++) {
                if (ms >= _steps[i]) {
                  step = i;
                }
              }
              final value = finalValue ? widget.balance : _value(step);
              final rolling =
                  !finalValue && step >= 0 && ms < _steps[step] + 90;
              final roll = rolling
                  ? const Cubic(
                      .16,
                      .65,
                      .32,
                      1,
                    ).transform(((ms - _steps[step]) / 90).clamp(0, 1))
                  : 0.0;
              final rim = ms >= 840 && ms < 1040 && !_static
                  ? math.sin((ms - 840) / 200 * math.pi)
                  : 0.0;
              return Container(
                key: const ValueKey('yeopjeon-credit-badge'),
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xfff6ede0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color.lerp(
                      const Color(0xffbda77f),
                      const Color(0xffefc674),
                      rim,
                    )!,
                    width: 1 + rim,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0xff775c35), offset: Offset(0, 3)),
                    BoxShadow(
                      color: Color(0x25101f17),
                      offset: Offset(0, 5),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: 28,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, .006)
                                ..rotateY(
                                  !_static && ms < 840
                                      ? .2 * math.sin(ms / 45)
                                      : 0,
                                ),
                              child: const YeopjeonCoinImage(size: 28),
                            ),
                          ),
                          if (!_static && _motion.isAnimating)
                            for (var i = 0; i < 4; i++) _mark(i, ms),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    SizedBox(
                      width: slotWidth,
                      height: line,
                      child: ClipRect(
                        child: Stack(
                          children: [
                            Transform.translate(
                              offset: Offset(0, rolling ? -line * roll : 0),
                              child: SizedBox(
                                width: slotWidth,
                                height: line,
                                child: Center(
                                  child: Text(
                                    '${rolling ? _value(step - 1) : value}',
                                    key: const ValueKey(
                                      'yeopjeon-header-value',
                                    ),
                                    style: style,
                                  ),
                                ),
                              ),
                            ),
                            if (rolling)
                              Transform.translate(
                                offset: Offset(0, line * (1 - roll)),
                                child: SizedBox(
                                  width: slotWidth,
                                  height: line,
                                  child: Center(
                                    child: Text('$value', style: style),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _mark(int index, double ms) {
    final t = ((ms - [0, 170, 350, 590][index]) / 230).clamp(0.0, 1.0);
    final opacity = t < .25 ? t / .25 : (1 - t) / .75;
    return Positioned(
      left: [1.0, 17.0, 7.0, 16.0][index],
      top: 7 - 18 * t,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Text(
            index.isEven ? '+' : '++',
            style: const TextStyle(
              fontFamily: 'Paperlogy',
              fontSize: 14,
              height: 1,
              fontWeight: FontWeight.w700,
              color: Color(0xff1c5148),
              shadows: [Shadow(color: Color(0xfff9df9e), offset: Offset(0, 1))],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }
}
