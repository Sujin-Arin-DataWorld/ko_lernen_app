import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// Bible §13 A — 9:16 hanji 두루마리 story image. No black outline, no UI chrome.
class ShareSlipRenderer {
  static const Size storySize = Size(1080, 1920);

  static Future<Uint8List> renderPng({
    required String korean,
    required String gloss,
    Size size = storySize,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Offset.zero & size);
    ShareSlipPainter(korean: korean, gloss: gloss).paint(canvas, size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.round(),
      size.height.round(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();
    return bytes!.buffer.asUint8List();
  }
}

class ShareSlipPainter extends CustomPainter {
  const ShareSlipPainter({required this.korean, required this.gloss});

  final String korean;
  final String gloss;

  @override
  void paint(Canvas canvas, Size size) {
    final hanji = Paint()..color = SoriColors.lightBg;
    canvas.drawRect(Offset.zero & size, hanji);

    final rng = math.Random(korean.hashCode);
    final grain = Paint()..color = SoriColors.lightText.withValues(alpha: 0.035);
    for (var i = 0; i < 420; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), rng.nextDouble() * 1.6 + 0.4, grain);
    }

    final woodDeep = Paint()..color = SoriColors.lightText.withValues(alpha: 0.28);
    final woodMid = Paint()..color = SoriColors.lightText.withValues(alpha: 0.16);
    final shelfH = size.height * 0.07;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, shelfH), woodDeep);
    canvas.drawRect(
      Rect.fromLTWH(0, shelfH * 0.55, size.width, shelfH * 0.45),
      woodMid,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - shelfH, size.width, shelfH),
      woodDeep,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - shelfH, size.width, shelfH * 0.4),
      woodMid,
    );

    final curl = Paint()..color = SoriColors.lightSurface.withValues(alpha: 0.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.08, shelfH * 0.35, size.width * 0.84, 18),
        const Radius.circular(9),
      ),
      curl,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.1,
          size.height - shelfH * 0.7,
          size.width * 0.8,
          16,
        ),
        const Radius.circular(8),
      ),
      curl,
    );

    _paintText(
      canvas,
      korean,
      Offset(size.width / 2, size.height * 0.46),
      size.width * 0.78,
      92,
      FontWeight.w700,
      SoriColors.lightText,
    );
    if (gloss.trim().isNotEmpty) {
      _paintText(
        canvas,
        gloss,
        Offset(size.width / 2, size.height * 0.58),
        size.width * 0.72,
        36,
        FontWeight.w500,
        SoriColors.lightText.withValues(alpha: 0.72),
      );
    }

    final stamp = size.width * 0.13;
    final stampOrigin = Offset(
      size.width - stamp - size.width * 0.12,
      size.height - shelfH - stamp - 36,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        stampOrigin & Size(stamp, stamp),
        const Radius.circular(6),
      ),
      Paint()..color = SoriColors.like,
    );
    _paintText(
      canvas,
      '한',
      stampOrigin + Offset(stamp / 2, stamp / 2),
      stamp * 0.8,
      42,
      FontWeight.w700,
      SoriColors.contentCtaOn,
    );
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset center,
    double maxWidth,
    double fontSize,
    FontWeight weight,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: fontSize,
          fontWeight: weight,
          height: 1.25,
          color: color,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 4,
    )..layout(maxWidth: maxWidth);
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant ShareSlipPainter oldDelegate) {
    return oldDelegate.korean != korean || oldDelegate.gloss != gloss;
  }
}
