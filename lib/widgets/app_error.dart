import 'package:flutter/material.dart';

import 'sori/motion.dart';
import 'sori/tokens.dart';

/// 오류 상태 — 부드럽게 등장하고, 아이콘이 잔잔히 호흡한다.
class AppError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;
  final String? retryLabel;

  const AppError({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SoriEntrance(
          duration: const Duration(milliseconds: 340),
          slideY: 14,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BreathingTransform(
                scaleEnd: 1.07,
                period: const Duration(milliseconds: 900),
                child: Icon(icon, size: 56, color: SoriColors.danger),
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: s.text, fontSize: 15, height: 1.5),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(retryLabel ?? 'Erneut versuchen'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 빈 상태 — 부드럽게 등장하고, 아이콘이 천천히 떠다닌다.
class AppEmpty extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const AppEmpty({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SoriEntrance(
          duration: const Duration(milliseconds: 340),
          slideY: 14,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BreathingTransform(
                translateY: -7,
                period: const Duration(milliseconds: 1700),
                child: Icon(icon, size: 56, color: s.textDim),
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: s.textMuted, fontSize: 14, height: 1.5),
              ),
              if (onAction != null) ...[
                const SizedBox(height: 18),
                OutlinedButton(
                  onPressed: onAction,
                  child: Text(actionLabel ?? 'Anpassen'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 작은 호흡/부유 루프 — flutter_animate 의존 제거를 위한 인라인 헬퍼.
///
/// [scaleEnd] != 1.0 이면 1.0↔scaleEnd 사이를 [period]로 ease-in-out 왕복.
/// [translateY] != 0 이면 0↔translateY(px) 사이를 동일 패턴으로 왕복.
/// `MediaQuery.disableAnimations`(prefers-reduced-motion)에선 정지 상태로 렌더.
class _BreathingTransform extends StatefulWidget {
  final Widget child;
  final double scaleEnd;
  final double translateY;
  final Duration period;

  const _BreathingTransform({
    required this.child,
    required this.period,
    this.scaleEnd = 1.0,
    this.translateY = 0,
  });

  @override
  State<_BreathingTransform> createState() => _BreathingTransformState();
}

class _BreathingTransformState extends State<_BreathingTransform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.period)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
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
        final dy = widget.translateY * t;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: widget.child,
    );
  }
}
