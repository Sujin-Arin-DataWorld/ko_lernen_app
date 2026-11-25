import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';
import 'c_materials.dart';

/// The illustration sits on a native, resizable walnut-and-paper button face.
/// Raster label plates are deliberately not used: type, face, rim and depth
/// remain crisp and share the same geometry at every supported text size.
class CFreeLearningArt extends StatelessWidget {
  const CFreeLearningArt(this.id, {super.key, this.label});
  final String id;
  final String? label;

  static const atlas =
      'assets/illustrations/c_learning/free-shelf-objects-v2.png';
  static const _regions = {
    'vocab_packs': Rect.fromLTRB(12, 48, 359, 385),
    'grammar': Rect.fromLTRB(365, 48, 725, 385),
    'book_capture': Rect.fromLTRB(731, 48, 1080, 385),
    'word_web': Rect.fromLTRB(12, 381, 372, 722),
    'pronunciation': Rect.fromLTRB(389, 381, 722, 722),
    'listening': Rect.fromLTRB(731, 381, 1080, 722),
    'scenarios': Rect.fromLTRB(12, 727, 359, 1047),
    'smalltalk': Rect.fromLTRB(365, 727, 725, 1047),
    'hangul': Rect.fromLTRB(731, 727, 1080, 1047),
    'calligraphy': Rect.fromLTRB(12, 1057, 359, 1387),
    'srs': Rect.fromLTRB(365, 1057, 725, 1387),
    'my_words': Rect.fromLTRB(731, 1057, 1080, 1387),
  };

  static Rect _normalized(Rect source) => Rect.fromLTWH(
    source.left / 1086,
    source.top / 1448,
    source.width / 1086,
    source.height / 1448,
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final rect = _regions[id] ?? _regions['my_words']!;
      final split = rect.top < 100
          ? 283.0
          : rect.top < 500
          ? 619.0
          : rect.top < 900
          ? 947.0
          : 1284.0;
      final width = math.min(constraints.maxWidth, 220.0);
      final artHeight = width * .675;
      final illustrationHeight = (split - rect.top) * width / rect.width;
      final art = SizedBox(
        width: width,
        height: artHeight,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: width,
            height: illustrationHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CAtlasArt(
                    path: atlas,
                    region: _normalized(
                      Rect.fromLTRB(rect.left, rect.top, rect.right, split),
                    ),
                    fit: BoxFit.fill,
                  ),
                ),
                ..._letters(rect, width),
              ],
            ),
          ),
        ),
      );
      final title = label;
      if (title == null) {
        return ExcludeSemantics(child: FittedBox(child: art));
      }
      final style = SoriTextTheme.of(context).label
          .copyWith(fontWeight: FontWeight.w700, color: CPalette.ink);
      final measure = TextPainter(
        text: TextSpan(text: title, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: width - 16);
      final plateHeight = math.max(38.0, measure.height.ceilToDouble() + 12);
      measure.dispose();
      return Center(
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(child: art),
              SizedBox(
                height: plateHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const CustomPaint(painter: _ShelfPlinthPainter()),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 3, 8, 7),
                      child: Center(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: style,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  List<Widget> _letters(Rect rect, double width) {
    final scale = width / rect.width;
    Widget glyph(String text, Rect box, double size, {double angle = 0}) =>
        Positioned(
          left: (box.left - rect.left) * scale,
          top: (box.top - rect.top) * scale,
          width: box.width * scale,
          height: box.height * scale,
          child: Transform.rotate(
            angle: angle,
            child: Center(
              child: Text(
                text,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: size * scale,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff125c4f),
                ),
              ),
            ),
          ),
        );
    return switch (id) {
      'grammar' => [
        glyph('가', const Rect.fromLTWH(526, 197, 70, 72), 58),
        glyph('다', const Rect.fromLTWH(611, 197, 70, 72), 58),
      ],
      'word_web' => [
        glyph('크다', const Rect.fromLTWH(53, 466, 125, 105), 49, angle: -.14),
        glyph('작다', const Rect.fromLTWH(201, 468, 119, 105), 49, angle: .10),
      ],
      'hangul' => [
        glyph('ㄱ', const Rect.fromLTWH(795, 797, 107, 108), 78, angle: -.13),
        glyph('ㅏ', const Rect.fromLTWH(917, 797, 108, 109), 78, angle: .05),
      ],
      'calligraphy' => [
        glyph('가', const Rect.fromLTWH(94, 1130, 147, 110), 75, angle: .24),
      ],
      _ => const [],
    };
  }
}

/// Lighting follows the reference's upper-left light. The paper is inset in
/// a beveled wooden face, so there is no stretched image seam under the text.
class _ShelfPlinthPainter extends CustomPainter {
  const _ShelfPlinthPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Rect.fromLTWH(3, -1, size.width - 6, size.height - 1);
    final frame = RRect.fromRectAndRadius(bounds, const Radius.circular(6));
    canvas.drawShadow(
      Path()..addRRect(frame),
      const Color(0xc900100c),
      3,
      false,
    );
    canvas.drawRRect(
      frame,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xffad6738), Color(0xff70401f), Color(0xff3b1c10)],
          stops: [0, .35, 1],
        ).createShader(bounds),
    );
    canvas.drawRRect(
      frame.deflate(.5),
      Paint()
        ..color = const Color(0xffe0aa69)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );
    // Fine grain follows the face instead of competing with the label.
    canvas.save();
    canvas.clipRRect(frame);
    for (var i = 0; i < 5; i++) {
      final y = 1.5 + i * (size.height - 3) / 4;
      canvas.drawPath(
        Path()
          ..moveTo(3, y)
          ..cubicTo(
            size.width * .25,
            y + 2,
            size.width * .7,
            y - 2,
            size.width - 3,
            y + .5,
          ),
        Paint()
          ..color = const Color(0x4070230c)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .65,
      );
    }
    canvas.restore();
    final paperBounds = Rect.fromLTRB(7, 2, size.width - 7, size.height - 5);
    final rim = RRect.fromRectAndRadius(paperBounds, const Radius.circular(4));
    canvas.drawRRect(
      rim.shift(const Offset(0, 1.3)),
      Paint()..color = const Color(0xff38200e),
    );
    canvas.drawRRect(
      rim,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xfffff8e8), Color(0xfff5e6c8), Color(0xffecd3a9)],
          stops: [0, .72, 1],
        ).createShader(paperBounds),
    );
    canvas.drawRRect(
      rim,
      Paint()
        ..color = const Color(0xffdfb674)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawRRect(
      rim.deflate(1.1),
      Paint()
        ..color = const Color(0x99fffdf5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7,
    );
  }

  @override
  bool shouldRepaint(_ShelfPlinthPainter oldDelegate) => false;
}
