import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import 'sori/motion.dart';
import 'sori/tokens.dart';

/// 오류 상태 기본 일러스트 — 태고(호랑이) 정면 정본.
///
/// 계획 §8.1(오류 = 태고 정적) · ASSET_GAP §3-2(신규 이미지 0, 배선만).
/// 정지 PNG 다. 캐릭터 **클립**(`tiger_walking_front.mp4` 등)은 오류·로딩에
/// 쓰지 않는다 — 디코더 예산 규정.
const String kTaegoErrorAsset =
    'assets/illustrations/mascot/tiger_front.png';

/// 오류 상태 — 부드럽게 등장하고, 일러스트가 잔잔히 호흡한다.
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
    final s = SoriSurfaces.of(context);
    final t = AppL10n.of(context);
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
                child: asset != null
                    ? Image.asset(
                        asset!,
                        height: 124,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            Icon(icon, size: 56, color: SoriColors.danger),
                      )
                    : Icon(icon, size: 56, color: SoriColors.danger),
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
                  label: Text(retryLabel ?? t.btnRetry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 빈 상태 — **폐기 예정**. 신규 코드는 `SoriEmptyState`를 쓴다.
///
/// 계획 §8.1이 빈 상태 표준을 `SoriEmptyState`(조이 + 출구 CTA) 하나로
/// 정했는데 이 위젯은 일러스트 슬롯이 없어 아이콘까지밖에 못 간다.
/// 마지막 사용처(`grammar_screen`)를 옮겼으므로 호출부는 0.
@Deprecated('SoriEmptyState 를 사용하세요 (계획 §8.1 빈 상태 표준)')
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
