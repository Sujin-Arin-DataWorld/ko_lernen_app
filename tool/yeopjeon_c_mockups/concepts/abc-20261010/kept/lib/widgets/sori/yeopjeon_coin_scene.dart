import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/haptic_service.dart';
import '../../services/storage_service.dart';
import 'video_lease.dart';
import 'yeopjeon_material.dart';

/// A tactile coin scene. Tapping it changes light, never a ledger entry.
class YeopjeonCoinScene extends StatefulWidget {
  const YeopjeonCoinScene({super.key, required this.size});
  final double size;
  @override
  State<YeopjeonCoinScene> createState() => _YeopjeonCoinSceneState();
}

class _YeopjeonCoinSceneState extends State<YeopjeonCoinScene>
    with TickerProviderStateMixin {
  late final _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final _touch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final _visibility = VideoLeaseEligibilityBinding(onChanged: _sync);
  bool _reduced = true;
  bool _entered = false;
  @override
  void initState() {
    super.initState();
    HapticService.preferencesChanged.addListener(_sync);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visibility.attach(context);
    _sync();
  }

  void _sync() {
    if (!mounted) {
      return;
    }
    _reduced = Storage.reducedMotion || MediaQuery.disableAnimationsOf(context);
    if (_reduced || !_visibility.isVisible(context)) {
      _idle.stop();
      _touch.stop();
      _idle.value = 1;
      _touch.value = 0;
    } else if (!_entered) {
      _entered = true;
      _idle.forward(from: 0);
    }
  }

  void _awaken() {
    HapticService.selectionClick();
    if (!_reduced && _visibility.isVisible(context)) {
      _touch.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: AppL10n.of(context).cRewardCoinHint,
    onTap: _awaken,
    child: ExcludeSemantics(
      child: GestureDetector(
        onTap: _awaken,
        behavior: HitTestBehavior.opaque,
        child: RepaintBoundary(
          child: SizedBox.square(
            dimension: widget.size,
            child: AnimatedBuilder(
              animation: Listenable.merge([_idle, _touch]),
              builder: (_, __) {
                final landing = const Cubic(
                  .22,
                  1,
                  .36,
                  1,
                ).transform(_idle.value);
                final touch = math.sin(_touch.value * math.pi);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: widget.size * .16,
                      right: widget.size * .16,
                      top: widget.size * .59,
                      height: widget.size * .21,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          gradient: RadialGradient(
                            colors: [
                              Color.lerp(
                                const Color(0xffd3b981),
                                const Color(0xffedc56d),
                                touch,
                              )!.withValues(alpha: .5),
                              const Color(0x001c5148),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: widget.size * (.24 - touch * .025),
                      right: widget.size * (.24 - touch * .025),
                      top: widget.size * .745,
                      height: widget.size * .065,
                      child: Opacity(
                        opacity: .55 + landing * .25 - touch * .15,
                        child: const CustomPaint(painter: _CoinContactShadow()),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(
                        0,
                        -widget.size * .06 - (1 - landing) * 12 - touch * 3,
                      ),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, .002)
                          ..rotateY(-.28 + touch * .36)
                          ..rotateX(.1),
                        child: YeopjeonCoinImage(size: widget.size * .64),
                      ),
                    ),
                    Positioned(
                      left: widget.size * .08,
                      top: widget.size * .51,
                      child: Transform.rotate(
                        angle: -.38,
                        child: YeopjeonCoinImage(size: widget.size * .14),
                      ),
                    ),
                    Positioned(
                      right: widget.size * .08,
                      top: widget.size * .18,
                      child: Transform.rotate(
                        angle: .3,
                        child: YeopjeonCoinImage(size: widget.size * .14),
                      ),
                    ),
                    if (touch > 0)
                      IgnorePointer(
                        child: Opacity(
                          opacity: touch * .5,
                          child: Image.asset(
                            'assets/animations/rewards/yupjeon.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );

  @override
  void dispose() {
    _visibility.disposeBinding();
    HapticService.preferencesChanged.removeListener(_sync);
    _idle.dispose();
    _touch.dispose();
    super.dispose();
  }
}

class _CoinContactShadow extends CustomPainter {
  const _CoinContactShadow();
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(1, size.height / size.width);
    final radius = size.width / 2;
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x55473622), Color(0x00473622)],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CoinContactShadow oldDelegate) => false;
}
