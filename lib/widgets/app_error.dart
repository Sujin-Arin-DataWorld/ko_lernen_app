import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import 'sori/button.dart';
import 'sori/motion.dart';
import 'sori/tokens.dart';

/// 오류 상태 기본 일러스트 — 태고(호랑이) 정면 정본.
///
/// 계획 §8.1(오류 = 태고 정적) · ASSET_GAP §3-2(신규 이미지 0, 배선만).
/// 정지 PNG 다. 캐릭터 **클립**(`tiger_walking_front.mp4` 등)은 오류·로딩에
/// 쓰지 않는다 — 디코더 예산 규정.
const String kTaegoErrorAsset =
    'assets/illustrations/mascot/tiger_sitting2.png';

/// 오류 상태 — 부드럽게 등장하고, 일러스트가 잔잔히 호흡한다.
///
/// §8.1: 기술 문구 금지 — 원인 1줄 + "Erneut versuchen" 1버튼.
/// **오프라인은 별도 카피**: `t.errorOffline`
/// ("Kein Internet — dein Fortschritt ist lokal sicher.")를 message 로 넘길 것.
class AppError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;
  final String? retryLabel;

  /// 옵션 일러스트 — 주어지면 아이콘 대신 PNG(없으면/실패 시 아이콘).
  final String? asset;

  const AppError({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.retryLabel,
    this.asset = kTaegoErrorAsset,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = constraints.hasBoundedHeight
            ? math.max(0.0, constraints.maxHeight - Spacing.xl * 2)
            : 0.0;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Center(
              child: SoriEntrance(
                duration: const Duration(milliseconds: 340),
                slideY: 14,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _BreathingTransform(
                      scaleEnd: 1.07,
                      period: const Duration(milliseconds: 900),
                      child: asset != null
                          ? Image.asset(
                              asset!,
                              height: 124,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                icon,
                                size: 56,
                                color: SoriColors.danger,
                              ),
                            )
                          : Icon(icon, size: 56, color: SoriColors.danger),
                    ),
                    const SizedBox(height: Spacing.md),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: SoriTextTheme.of(context).body,
                    ),
                    if (onRetry != null) ...[
                      const SizedBox(height: Spacing.lg),
                      SoriButton.filled(
                        onTap: onRetry,
                        icon: Icons.refresh,
                        label: retryLabel ?? t.btnRetry,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 작은 호흡/부유 루프 — flutter_animate 의존 제거를 위한 인라인 헬퍼.
///
/// [scaleEnd] != 1.0 이면 1.0↔scaleEnd 사이를 [period]로 ease-in-out 왕복.
/// `MediaQuery.disableAnimations`(prefers-reduced-motion)에선 정지 상태로 렌더.
class _BreathingTransform extends StatefulWidget {
  final Widget child;
  final double scaleEnd;
  final Duration period;

  const _BreathingTransform({
    required this.child,
    required this.period,
    this.scaleEnd = 1.0,
  });

  @override
  State<_BreathingTransform> createState() => _BreathingTransformState();
}

class _BreathingTransformState extends State<_BreathingTransform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _motionEnabled = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.period);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled = !SoriMotion.reduceMotion(context);
    if (_motionEnabled == enabled) {
      return;
    }
    _motionEnabled = enabled;
    if (enabled) {
      _c.repeat(reverse: true);
    } else {
      _c.stop();
    }
  }

  @override
  void didUpdateWidget(covariant _BreathingTransform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) {
      _c.duration = widget.period;
    }
  }

  @override
  void dispose() {
    _c.stop();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (SoriMotion.reduceMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Curves.easeInOut.transform(_c.value);
        final scale = 1.0 + (widget.scaleEnd - 1.0) * t;
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}
