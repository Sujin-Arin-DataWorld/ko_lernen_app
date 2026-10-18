import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/pressable.dart';
import '../../widgets/sori/type_scale.dart';
import '../../widgets/sori/intro_tokens.dart';

/// Native text and actions on the complete 941 × 1672 approved welcome artwork.
/// Reference geometry is 402 × 714.2869, centered within taller viewports.
class CIntroWelcomeReference extends StatelessWidget {
  const CIntroWelcomeReference({
    super.key,
    required this.artwork,
    required this.busy,
    required this.failed,
    required this.onStart,
    required this.onLater,
  });

  final String artwork;
  final bool busy;
  final bool failed;
  final VoidCallback onStart;
  final VoidCallback onLater;

  static const _cream = Color(0xfffff2d5);
  static const _aspect = 941 / 1672;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final media = MediaQuery.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff164c48), Color(0xff123e38)],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SoriViewportTypeScale(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final scale = width / 402;
                // Use a flowing layout before source scaling would make the CTA
                // smaller than a 48dp target, or larger text would crowd the art.
                final adaptive =
                    50 * scale < 48 || !IntroLayout.usesReferenceText(context);
                final sceneHeight = width / _aspect;
                final art = Image.asset(
                  artwork,
                  key: const ValueKey('welcome-whole-art'),
                  fit: BoxFit.contain,
                  semanticLabel: t.welcomeCharacters,
                  filterQuality: FilterQuality.medium,
                );
                if (adaptive) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(
                      top: media.padding.top + 20,
                      bottom: media.padding.bottom + 16,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(
                          width: 58,
                          height: 25,
                          child: CustomPaint(painter: _WelcomeCloud()),
                        ),
                        const SizedBox(height: 6),
                        _brand(1),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                          child: _title(
                            t.welcomeTitle,
                            width < 360 ? 22 / 28 : 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          child: _body(t.welcomeBody, 16),
                        ),
                        AspectRatio(aspectRatio: _aspect, child: art),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (failed) ...[
                                _error(t),
                                const SizedBox(height: 8),
                              ],
                              _start(t, adaptive: true),
                              const SizedBox(height: 8),
                              _later(t, adaptive: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final margin = (constraints.maxHeight - sceneHeight) / 2;
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: math.max(media.padding.top, margin),
                    bottom: math.max(media.padding.bottom, margin),
                  ),
                  child: SizedBox(
                    key: const ValueKey('welcome-reference-scene'),
                    width: width,
                    height: sceneHeight,
                    child: Stack(
                      children: [
                        Positioned.fill(child: art),
                        _at(
                          172,
                          14.5,
                          58,
                          25,
                          scale,
                          const CustomPaint(painter: _WelcomeCloud()),
                        ),
                        _at(
                          17,
                          20,
                          63,
                          46,
                          scale,
                          _partialCloud(-36, 98, 44, scale),
                        ),
                        _at(
                          306,
                          45,
                          55,
                          34,
                          scale,
                          _partialCloud(0, 96, 43, scale),
                        ),
                        _at(100, 40, 202, 18, scale, _brand(scale)),
                        _at(
                          65,
                          69,
                          272,
                          68,
                          scale,
                          Center(child: _title(t.welcomeTitle, scale)),
                        ),
                        _at(
                          75,
                          139,
                          252,
                          33,
                          scale,
                          Center(child: _body(t.welcomeBody, 12.5 * scale)),
                        ),
                        if (failed)
                          Positioned(
                            left: 24 * scale,
                            right: 24 * scale,
                            bottom: 121 * scale,
                            child: _error(t),
                          ),
                        _at(
                          84.5,
                          601.5,
                          233,
                          50,
                          scale,
                          _start(t, scale: scale),
                        ),
                        Positioned(
                          left: 151 * scale,
                          top: 650 * scale,
                          width: 100 * scale,
                          height: math.max(48, 48 * scale),
                          child: _later(t, scale: scale),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _brand(double scale) => Text(
    'HANGUL SORI',
    textAlign: TextAlign.center,
    style: IntroTypography.welcomeBrand(scale),
  );

  Widget _title(String title, double scale) => Semantics(
    header: true,
    child: Text(
      title,
      textAlign: TextAlign.center,
      style: IntroTypography.welcomeTitle(scale),
    ),
  );

  Widget _body(String body, double size) => Text(
    body,
    textAlign: TextAlign.center,
    style: IntroTypography.welcomeBody(size),
  );

  Widget _error(AppL10n t) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xf2153f3d),
      child: Text(
        t.loadErrorTryAgain,
        textAlign: TextAlign.center,
        style: IntroTypography.welcomeError,
      ),
    ),
  );

  Widget _start(AppL10n t, {double scale = 1, bool adaptive = false}) {
    final action = busy ? null : onStart;
    final label = Text(
      t.welcomeStart,
      textAlign: TextAlign.center,
      style: IntroTypography.welcomeAction(scale),
    );
    final arrow = busy
        ? const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: _cream),
          )
        : const CustomPaint(size: Size(13, 12), painter: _WelcomeArrow());
    return Semantics(
      button: true,
      enabled: !busy,
      label: t.welcomeStart,
      onTap: action,
      child: ExcludeSemantics(
        child: SoriPressable(
          onTap: action,
          pressScale: .985,
          surfaceDepth: 1.5,
          surfaceRadius: 25 * scale,
          surfaceEdgeColor: const Color(0xff3c2a16),
          child: Container(
            key: const ValueKey('welcome-start'),
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                IntroGeometry.welcomeAction * scale,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x593c2a16),
                  offset: Offset(0, 1.5),
                  blurRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                IntroGeometry.welcomeAction * scale,
              ),
              child: CustomPaint(
                painter: const _WelcomeButtonFace(),
                child: adaptive
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(child: label),
                            const SizedBox(width: 12),
                            arrow,
                          ],
                        ),
                      )
                    : Stack(
                        children: [
                          _at(54, 9.5, 123, 32, scale, Center(child: label)),
                          _at(187, 19, 13, 12, scale, Center(child: arrow)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _later(AppL10n t, {double scale = 1, bool adaptive = false}) =>
      Semantics(
        hint: t.welcomeLaterHint,
        child: TextButton(
          key: const ValueKey('welcome-later'),
          onPressed: busy ? null : onLater,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: EdgeInsets.zero,
            foregroundColor: const Color(0xffe8e5d6),
          ),
          child: Text(
            t.welcomeLater,
            style: IntroTypography.welcomeLater(scale, adaptive),
          ),
        ),
      );

  Widget _partialCloud(double x, double width, double height, double scale) =>
      ClipRect(
        child: Stack(
          children: [
            Positioned(
              left: x * scale,
              top: 0,
              width: width * scale,
              height: height * scale,
              child: const CustomPaint(
                painter: _WelcomeCloud(color: Color(0xbfc4aa6e), stroke: 1.1),
              ),
            ),
          ],
        ),
      );

  static Widget _at(
    double x,
    double y,
    double w,
    double h,
    double scale,
    Widget child,
  ) => Positioned(
    left: x * scale,
    top: y * scale,
    width: w * scale,
    height: h * scale,
    child: child,
  );
}

class _WelcomeArrow extends CustomPainter {
  const _WelcomeArrow();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 13, size.height / 12);
    canvas.drawPath(
      Path()
        ..moveTo(0, 6)
        ..lineTo(11.5, 6)
        ..moveTo(7, 1)
        ..lineTo(12, 6)
        ..lineTo(7, 11),
      Paint()
        ..color = CIntroWelcomeReference._cream
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_WelcomeArrow oldDelegate) => false;
}

class _WelcomeButtonFace extends CustomPainter {
  const _WelcomeButtonFace();
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final face = RRect.fromRectAndRadius(
      rect.deflate(.75),
      const Radius.circular(IntroGeometry.welcomeAction),
    );
    canvas.drawRRect(
      face,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff285953), Color(0xff174d48), Color(0xff113c39)],
          stops: [0, .45, 1],
        ).createShader(rect),
    );
    final cloud = const _WelcomeCloud(color: Color(0x336e9c84), stroke: 1.2);
    canvas.save();
    canvas.translate(-9, size.height - 30);
    cloud.paint(canvas, const Size(58, 26));
    canvas.restore();
    canvas.save();
    canvas.translate(size.width - 40, size.height - 19);
    cloud.paint(canvas, const Size(58, 26));
    canvas.restore();
    canvas.drawRRect(
      face,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xffffe4a6), Color(0xffd4af66), Color(0xffedcd8a)],
          stops: [0, .5, 1],
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(1.7),
        const Radius.circular(IntroGeometry.welcomeInnerRail),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x24bfddbf), Color(0x00bfddbf)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_WelcomeButtonFace oldDelegate) => false;
}

class _WelcomeCloud extends CustomPainter {
  const _WelcomeCloud({this.color = const Color(0xffd8b777), this.stroke = .9});
  final Color color;
  final double stroke;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(8, 36)
      ..lineTo(30, 36)
      ..cubicTo(32, 27, 38, 23, 43, 24)
      ..cubicTo(44, 11, 55, 3, 67, 4)
      ..cubicTo(80, 4, 86, 11, 89, 20)
      ..cubicTo(101, 17, 112, 25, 112, 36)
      ..lineTo(128, 36)
      ..cubicTo(137, 36, 137, 44, 128, 44)
      ..lineTo(109, 44)
      ..cubicTo(105, 55, 91, 60, 80, 55)
      ..cubicTo(70, 62, 54, 59, 47, 52)
      ..cubicTo(39, 55, 31, 51, 29, 44)
      ..lineTo(8, 44)
      ..cubicTo(0, 44, 0, 36, 8, 36)
      ..close()
      ..moveTo(67, 20)
      ..cubicTo(58, 15, 51, 21, 53, 29)
      ..cubicTo(55, 36, 64, 35, 65, 29)
      ..cubicTo(66, 25, 63, 24, 61, 25)
      ..moveTo(45, 34)
      ..cubicTo(34, 30, 31, 42, 39, 47)
      ..cubicTo(47, 52, 56, 44, 53, 38)
      ..moveTo(85, 29)
      ..cubicTo(96, 24, 104, 33, 100, 41)
      ..cubicTo(96, 48, 85, 45, 86, 38)
      ..cubicTo(86, 34, 90, 33, 93, 35);
    final matrix = Matrix4.diagonal3Values(
      size.width / 137,
      size.height / 59,
      1,
    );
    canvas.drawPath(
      path.transform(matrix.storage),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_WelcomeCloud oldDelegate) =>
      color != oldDelegate.color || stroke != oldDelegate.stroke;
}
