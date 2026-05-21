import 'package:flutter/material.dart';
import 'sori/tokens.dart';

/// 브랜드 톤 로딩 인디케이터 — 단청 3색 점이 물결치듯 튀어오른다.
/// 로고에 의존하지 않음 (로고 교체와 무관하게 안정적으로 동작).
class AppLoading extends StatefulWidget {
  final String? message;
  const AppLoading({super.key, this.message});

  @override
  State<AppLoading> createState() => _AppLoadingState();
}

class _AppLoadingState extends State<AppLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  /// 단청 3색 — 녹청 · 석간주 · 황
  static const _dots = [
    SoriColors.primary,
    SoriColors.accent,
    SoriColors.gold,
  ];

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
            height: 24,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(3, (i) {
                  // 점마다 위상차 — 물결처럼 순차로 튀어오름
                  final phase = (_ctrl.value - i * 0.16) % 1.0;
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
                          color: _dots[i],
                          shape: BoxShape.circle,
                          boxShadow: lift > 0.25
                              ? [
                                  BoxShadow(
                                    color: _dots[i]
                                        .withValues(alpha: 0.40 * lift),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  );
                }),
              ),
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
