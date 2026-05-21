import 'package:flutter/material.dart';

import '../hanok_tokens.dart';

/// **ChangsalDivider** — 창살(window lattice) 격자 divider.
///
/// 한지 창문의 정자(井) 격자무늬 한 줄을 가로로 늘어놓은 형태.
/// [DancheongDivider]보다 풍부한 décor 효과. 더 큰 section 구분 또는 hero
/// 카드 상하단에 사용.
///
/// ```
///  ┼─┼─┼─┼─┼─┼─┼─┼─┼─┼
///  │ │ │ │ │ │ │ │ │ │
///  ┼─┼─┼─┼─┼─┼─┼─┼─┼─┼
/// ```
class ChangsalDivider extends StatelessWidget {
  /// 격자 한 셀의 가로 크기. 기본 14.
  final double cellWidth;
  /// divider 높이. 셀 1개 (single row) = 14. 2 row = 28.
  final double height;
  /// 격자 색. 기본: hanjiInk (light mode) / baek subtle (dark mode)
  final Color? color;

  const ChangsalDivider({
    super.key,
    this.cellWidth = 14,
    this.height = 14,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final latticeColor = color ?? (isLight
        ? HanokColors.hanjiInk.withValues(alpha: 0.20)
        : HanokColors.baek.withValues(alpha: 0.15));

    return SizedBox(
      height: height,
      child: ClipRect(
        child: CustomPaint(
          painter: _ChangsalPainter(cellWidth: cellWidth, color: latticeColor),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ChangsalPainter extends CustomPainter {
  final double cellWidth;
  final Color color;

  _ChangsalPainter({required this.cellWidth, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Horizontal lines (top + bottom)
    canvas.drawLine(Offset(0, 0.5), Offset(size.width, 0.5), paint);
    canvas.drawLine(Offset(0, size.height - 0.5), Offset(size.width, size.height - 0.5), paint);

    // Vertical lines (cell separators)
    final cellCount = (size.width / cellWidth).floor();
    for (var i = 1; i < cellCount; i++) {
      final x = i * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Middle horizontal line (정 자 모양 만들기 — 2 row 일 때만)
    if (size.height >= 28) {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ChangsalPainter old) =>
      old.cellWidth != cellWidth || old.color != color;
}
