import 'package:flutter/material.dart';
import 'sori/tokens.dart';

/// 브랜드 톤 로딩 인디케이터 — 앱 로고가 부드럽게 숨 쉰다.
class AppLoading extends StatefulWidget {
  final String? message;
  const AppLoading({super.key, this.message});

  @override
  State<AppLoading> createState() => _AppLoadingState();
}

class _AppLoadingState extends State<AppLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _logoAsset = 'assets/icons/icon-192.png';

  /// 로고 에셋 로드 실패 시 쓰는 단청 3색 — 녹청 · 석간주 · 황.
  static const _dots = [SoriColors.primary, SoriColors.accent, SoriColors.gold];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                final wave = _ctrl.value < 0.5
                    ? _ctrl.value * 2
                    : (1 - _ctrl.value) * 2;
                final pulse = Curves.easeInOut.transform(wave.clamp(0.0, 1.0));
                return Transform.scale(
                  scale: 0.96 + pulse * 0.07,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      _logoAsset,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, __, ___) => _DotFallback(
                        controllerValue: _ctrl.value,
                        colors: _dots,
                      ),
                    ),
                  ),
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
