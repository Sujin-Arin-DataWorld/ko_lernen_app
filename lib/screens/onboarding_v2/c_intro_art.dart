import 'package:flutter/material.dart';

import '../../widgets/sori/intro_tokens.dart';
export '../../widgets/sori/intro_tokens.dart';

/// Whole, newly generated assets. Provenance is in
/// tool/einleitung_generated_assets.json. No screenshot atlas or source rects.
class CIntroArt extends StatelessWidget {
  const CIntroArt(this.name, {super.key, this.fit = BoxFit.contain});
  final String name;
  final BoxFit fit;
  static const directory = 'assets/illustrations/einleitung_generated';

  @override
  Widget build(BuildContext context) => Image.asset(
    '$directory/intro-$name.png',
    fit: fit,
    excludeFromSemantics: true,
    filterQuality: FilterQuality.medium,
  );
}

class IntroCompactGoldBevel extends CustomPainter {
  const IntroCompactGoldBevel();
  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(1.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect,
        const Radius.circular(IntroGeometry.compactBevel),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xe6ffedb0), Color(0x20ffedb0), Color(0x734d2608)],
          stops: [0, .5, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant IntroCompactGoldBevel oldDelegate) => false;
}

class IntroPanel extends StatelessWidget {
  const IntroPanel({
    super.key,
    required this.child,
    this.selected = false,
    this.padding = EdgeInsets.zero,
    this.radius = 14,
  });
  final Widget child;
  final bool selected;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: IntroPalette.paper,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: selected ? IntroPalette.jade : const Color(0xffe1caa8),
        width: selected ? 2 : 1,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x302f1c0a),
          offset: Offset(0, 3),
          blurRadius: 3,
        ),
      ],
    ),
    child: Padding(padding: padding, child: child),
  );
}

class IntroMedal extends StatelessWidget {
  const IntroMedal(this.label, {super.key, this.size = 48});
  final String label;

  /// Width of the visible metal, excluding the transparent master margins.
  final double size;

  @override
  Widget build(BuildContext context) {
    final (name, bounds) = switch (label.toUpperCase()) {
      'A1' => ('level-a1', const Rect.fromLTRB(101, 104, 1149, 1133)),
      'A2' => ('level-a2', const Rect.fromLTRB(103, 106, 1146, 1132)),
      'B1' => ('level-b1', const Rect.fromLTRB(102, 104, 1148, 1133)),
      'B2' => ('level-b2', const Rect.fromLTRB(102, 104, 1149, 1134)),
      'C1' => ('level-c1', const Rect.fromLTRB(103, 104, 1147, 1134)),
      'C2' => ('level-c2', const Rect.fromLTRB(102, 104, 1148, 1133)),
      '가' => ('level-beginner', const Rect.fromLTRB(104, 103, 1146, 1133)),
      '✓' => ('check', const Rect.fromLTRB(171, 169, 1079, 1071)),
      _ => ('level-blank', const Rect.fromLTRB(103, 109, 1144, 1126)),
    };
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            IntroAssetBody(
              name: name,
              canvas: const Size(1254, 1254),
              body: bounds,
              visibleWidth: size,
            ),
            if (label == '–')
              Center(
                child: Text('–', style: IntroTypography.medalPlaceholder(size)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Positions the complete PNG by its measured visible bounds; never crops it.
class IntroAssetBody extends StatelessWidget {
  const IntroAssetBody({
    super.key,
    required this.name,
    required this.canvas,
    required this.body,
    required this.visibleWidth,
  });
  final String name;
  final Size canvas;
  final Rect body;
  final double visibleWidth;

  @override
  Widget build(BuildContext context) {
    final scale = visibleWidth / body.width;
    return Positioned(
      left: -body.left * scale,
      top: -body.top * scale,
      width: canvas.width * scale,
      height: canvas.height * scale,
      child: CIntroArt(name),
    );
  }
}

class IntroChevron extends StatelessWidget {
  const IntroChevron({super.key});
  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size(10, 16), painter: _IntroChevronPainter());
}

class _IntroChevronPainter extends CustomPainter {
  const _IntroChevronPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(1, 1)
      ..lineTo(8, 8)
      ..lineTo(1, 15);
    canvas.drawPath(
      path.shift(const Offset(1, 0)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xffffe8ac),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = IntroPalette.ink,
    );
  }

  @override
  bool shouldRepaint(_IntroChevronPainter oldDelegate) => false;
}
