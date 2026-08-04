import 'package:flutter/material.dart';
import 'sori/tokens.dart';

/// 브랜드 톤 로딩 인디케이터 — 앱 로고가 부드럽게 숨 쉰다.
class AppLoading extends StatefulWidget {
  final String? message;

  /// 옵션 일러스트 — 주어지면 로고 대신 이 PNG가 숨 쉰다(없으면/실패 시 로고).
  final String? asset;
  final double assetSize;

  const AppLoading({super.key, this.message, this.asset, this.assetSize = 124});

  @override
  State<AppLoading> createState() => _AppLoadingState();
}

class _AppLoadingState extends State<AppLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _motionEnabled = false;

  static const _logoAsset = 'assets/icons/icon-192.png';

  /// 로고 에셋 로드 실패 시 쓰는 단청 3색 — 녹청 · 석간주 · 황.
  static const _dots = [SoriColors.primary, SoriColors.accent, SoriColors.gold];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled = !MediaQuery.maybeOf(context)!.disableAnimations;
    if (_motionEnabled == enabled) {
      return;
    }
    _motionEnabled = enabled;
    if (enabled) {
      _ctrl.repeat();
    } else {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.asset != null ? widget.assetSize : 58,
            height: widget.asset != null ? widget.assetSize : 58,
            child: reduceMotion
                ? _visual(0)
                : AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, __) {
                      final wave = _ctrl.value < 0.5
                          ? _ctrl.value * 2
                          : (1 - _ctrl.value) * 2;
                      return _visual(
                        Curves.easeInOut.transform(wave.clamp(0.0, 1.0)),
                      );
                    },
                  ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.message!,
              style: TextStyle(color: s.textMuted, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _visual(double pulse) {
    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.asset(
        _logoAsset,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) =>
            _DotFallback(controllerValue: _ctrl.value, colors: _dots),
      ),
    );
    final visual = widget.asset == null
        ? logo
        : Image.asset(
            widget.asset!,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => logo,
          );
    return Transform.scale(scale: 0.96 + pulse * 0.07, child: visual);
  }
}

class _DotFallback extends StatelessWidget {
  final double controllerValue;
  final List<Color> colors;

  const _DotFallback({required this.controllerValue, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        final phase = (controllerValue - i * 0.16) % 1.0;
        final lift = phase < 0.5
            ? Curves.easeOut.transform(1 - (phase * 4 - 1).abs())
            : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Transform.translate(
            offset: Offset(0, -lift * 13),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[i],
                shape: BoxShape.circle,
                boxShadow: lift > 0.25
                    ? [
                        BoxShadow(
                          color: colors[i].withValues(alpha: 0.40 * lift),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      }),
    );
  }
}
