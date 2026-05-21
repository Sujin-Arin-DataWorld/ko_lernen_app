import 'package:flutter/material.dart';

import '../hanok_tokens.dart';

/// **DancheongDivider** — 단청 패턴 가로 divider.
///
/// 가운데 가는 gold stripe + 양쪽에 청적황 도트 (오방색 일부).
/// Section label 위/아래 또는 큰 화면 영역 사이 구분에 사용.
///
/// ```
///   ●     ────────────────     ●
///   ↑           gold              ↑
/// indigo dot                   red dot
/// ```
///
/// 사용:
/// ```dart
/// DancheongDivider()                  // 기본 (전체 너비)
/// DancheongDivider(narrow: true)      // 짧은 버전 (cards 안)
/// DancheongDivider.lite()             // dot 없이 stripe만
/// ```
class DancheongDivider extends StatelessWidget {
  /// 짧은 버전 (큰 카드 내부용, 50% width).
  final bool narrow;
  /// dot 없이 stripe만.
  final bool lite;
  final EdgeInsetsGeometry? padding;

  const DancheongDivider({super.key, this.narrow = false, this.padding})
      : lite = false;

  const DancheongDivider.lite({super.key, this.narrow = false, this.padding})
      : lite = true;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final stripeColor = isLight
        ? HanokColors.hwang.withValues(alpha: 0.55)
        : HanokColors.hwang.withValues(alpha: 0.70);

    final divider = LayoutBuilder(
      builder: (ctx, c) {
        final totalW = c.maxWidth.isFinite ? c.maxWidth : 200.0;
        final stripeW = narrow ? totalW * 0.5 : totalW * 0.8;

        return SizedBox(
          height: 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Stripe
              Container(
                width: stripeW,
                height: HanokSizing.dancheongStripeThin,
                decoration: BoxDecoration(
                  color: stripeColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),

              if (!lite) ...[
                // Left indigo dot (또는 dark mode에선 teal 같은 톤)
                Positioned(
                  left: narrow ? totalW * 0.22 : totalW * 0.07,
                  child: _Dot(color: HanokColors.cheong, size: HanokSizing.dancheongDotMd),
                ),
                // Right red dot
                Positioned(
                  right: narrow ? totalW * 0.22 : totalW * 0.07,
                  child: _Dot(color: HanokColors.jeok, size: HanokSizing.dancheongDotMd),
                ),
                // Center gold dot (slightly larger)
                _Dot(color: HanokColors.hwang, size: HanokSizing.dancheongDotLg),
              ],
            ],
          ),
        );
      },
    );

    if (padding != null) return Padding(padding: padding!, child: divider);
    return divider;
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final double size;
  const _Dot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
