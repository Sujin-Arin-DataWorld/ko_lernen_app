import 'package:flutter/material.dart';

import '../hanok_tokens.dart';

/// **GiwaPattern** — 기와(roof tile) 반복 패턴 row.
///
/// 작은 호 모양 (∩) 시리즈가 가로로 반복. Hero card 상단 또는 하단 footer
/// 에 한옥 지붕 모티프 추가. 자체로는 작고 subtle.
///
/// ```
///  ∩∩∩∩∩∩∩∩∩∩∩∩∩∩∩∩∩∩∩∩
/// ```
///
/// 사용:
/// ```dart
/// GiwaPattern()                        // 기본
/// GiwaPattern(color: HanokColors.giwaShadow)
/// GiwaPattern(height: 16, tileWidth: 14)
/// ```
class GiwaPattern extends StatelessWidget {
  /// 한 기와 너비 (height와 비례). 기본 12.
  final double tileWidth;

  /// 패턴 전체 높이. 기본 [HanokSizing.giwaRowHeight] (12).
  final double height;

  /// 기와 색. 기본: dark mode = giwaHi / light mode = giwaShadow
  final Color? color;

  /// 가로 fill 비율 (0~1, 1이면 width 전체)
  final double fillRatio;

  const GiwaPattern({
    super.key,
    this.tileWidth = 12,
    this.height = HanokSizing.giwaRowHeight,
    this.color,
    this.fillRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tileColor =
        color ?? (isLight ? HanokColors.giwaShadow : HanokColors.giwaHi);

    return SizedBox(
      height: height,
      child: ClipRect(
        child: CustomPaint(
          painter: _GiwaPainter(
            tileWidth: tileWidth,
            tileColor: tileColor,
            fillRatio: fillRatio,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _GiwaPainter extends CustomPainter {
  final double tileWidth;
  final Color tileColor;
  final double fillRatio;

  _GiwaPainter({
    required this.tileWidth,
    required this.tileColor,
    required this.fillRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0) return;

    final paint = Paint()
      ..color = tileColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = tileColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final usableW = size.width * fillRatio;
    final startX = (size.width - usableW) / 2;
    final tileCount = (usableW / tileWidth).floor();
    final actualWidth = tileCount * tileWidth;
    final realStartX = startX + (usableW - actualWidth) / 2;

    // 각 기와: 살짝 휘어 올라간 호 (Arc, half-circle)
    for (var i = 0; i < tileCount; i++) {
      final cx = realStartX + i * tileWidth + tileWidth / 2;
      final rect = Rect.fromCenter(
        center: Offset(cx, size.height * 0.7),
        width: tileWidth * 0.95,
        height: size.height * 0.85,
      );
      // Fill half (subtle)
      canvas.drawArc(rect, 3.14159, 3.14159, false, fillPaint);
      // Stroke arc (outline)
      canvas.drawArc(rect, 3.14159, 3.14159, false, paint);
    }
  }

  @override
  bool shouldRepaint(_GiwaPainter old) =>
      old.tileWidth != tileWidth ||
      old.tileColor != tileColor ||
      old.fillRatio != fillRatio;
}
