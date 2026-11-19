import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/intro_motion.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/type_scale.dart';
import '../../widgets/sori/intro_tokens.dart';
import '../../widgets/sori/approved_chrome_assets.dart';

/// Native text and actions on the complete 941 × 1672 approved welcome artwork.
/// The image fills the viewport; only native text and actions use safe insets.
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

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          artwork,
          key: const ValueKey('welcome-whole-art'),
          fit: BoxFit.cover,
          semanticLabel: t.welcomeCharacters,
          filterQuality: FilterQuality.medium,
        ),
        // One continuous picture owns the background, including system insets.
        // Only interactive content is inset; no second scene or colored bands.
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SoriViewportTypeScale(
                child: LayoutBuilder(
                  builder: (context, bounds) {
                    final compact = bounds.maxHeight < 690;
                    final accessibility = !IntroLayout.usesReferenceText(
                      context,
                    );
                    final titleScale = compact ? .9 : 1.0;
                    final top = Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: compact ? 28 : 38,
                          width: 74,
                          child: Image.asset(
                            ApprovedChromeAssets.cloud,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                          ),
                        ),
                        _brand(context, 1),
                        const SizedBox(height: 10),
                        _title(context, t.welcomeTitle, titleScale),
                        const SizedBox(height: 8),
                        _body(context, t.welcomeBody, 16),
                      ],
                    );
                    final actions = Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (failed) ...[
                          _error(context, t),
                          const SizedBox(height: 8),
                        ],
                        _start(context, t, adaptive: true),
                        const SizedBox(height: 4),
                        _later(context, t, adaptive: true),
                      ],
                    );
                    return Padding(
                      key: const ValueKey('welcome-reference-scene'),
                      padding: EdgeInsets.fromLTRB(
                        24,
                        compact ? 12 : 28,
                        24,
                        8,
                      ),
                      child: accessibility
                          ? LayoutBuilder(
                              builder: (context, contentBounds) =>
                                  SingleChildScrollView(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: contentBounds.maxHeight,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          top,
                                          const SizedBox(height: 24),
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 380,
                                            ),
                                            child: actions,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                            )
                          : Column(
                              children: [
                                top,
                                const Spacer(),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 380,
                                  ),
                                  child: actions,
                                ),
                              ],
                            ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _brand(BuildContext context, double scale) => Text(
    'HANGUL SORI',
    textAlign: TextAlign.center,
    style: IntroTypography.localized(
      context,
      IntroTypography.welcomeBrand(scale),
      heading: true,
    ),
  );

  Widget _title(BuildContext context, String title, double scale) => Semantics(
    header: true,
    child: Text(
      title,
      textAlign: TextAlign.center,
      style: IntroTypography.localized(
        context,
        IntroTypography.welcomeTitle(scale),
        heading: true,
      ),
    ),
  );

  Widget _body(BuildContext context, String body, double size) => Text(
    body,
    textAlign: TextAlign.center,
    style: IntroTypography.localized(context, IntroTypography.welcomeBody(size))
        .copyWith(
          shadows: const [
            Shadow(
              color: Color(0xff0c302d),
              offset: Offset(0, 1),
              blurRadius: 2.5,
            ),
            Shadow(
              color: Color(0xff0c302d),
              offset: Offset(-.65, 0),
              blurRadius: .4,
            ),
            Shadow(
              color: Color(0xff0c302d),
              offset: Offset(.65, 0),
              blurRadius: .4,
            ),
            Shadow(
              color: Color(0xff0c302d),
              offset: Offset(0, -.65),
              blurRadius: .4,
            ),
            Shadow(
              color: Color(0xff0c302d),
              offset: Offset(0, .65),
              blurRadius: .4,
            ),
          ],
        ),
  );

  Widget _error(BuildContext context, AppL10n t) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xf2153f3d),
      child: Text(
        t.loadErrorTryAgain,
        textAlign: TextAlign.center,
        style: IntroTypography.localized(context, IntroTypography.welcomeError),
      ),
    ),
  );

  Widget _start(
    BuildContext context,
    AppL10n t, {
    double scale = 1,
    bool adaptive = false,
  }) {
    final action = busy ? null : onStart;
    final label = Text(
      t.welcomeStart,
      textAlign: TextAlign.center,
      style: IntroTypography.localized(
        context,
        IntroTypography.welcomeAction(scale).copyWith(fontSize: 22),
      ),
    );
    final arrow = busy
        ? const SizedBox(
            width: 14,
            height: 14,
            child: SoriLoadingIndicator(strokeWidth: 1.5, color: _cream),
          )
        : const CustomPaint(size: Size(13, 12), painter: _WelcomeArrow());
    return Semantics(
      button: true,
      enabled: !busy,
      label: t.welcomeStart,
      onTap: action,
      child: ExcludeSemantics(
        child: IntroPressable(
          onTap: action,
          pressScale: .995,
          surfaceDepth: 0,
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

  Widget _later(
    BuildContext context,
    AppL10n t, {
    double scale = 1,
    bool adaptive = false,
  }) => Semantics(
    hint: t.welcomeLaterHint,
    child: SoriTextAction(
      key: const ValueKey('welcome-later'),
      label: t.welcomeLater,
      onPressed: busy ? null : onLater,
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: EdgeInsets.zero,
        foregroundColor: const Color(0xffe8e5d6),
      ),
      textStyle: IntroTypography.localized(
        context,
        IntroTypography.welcomeLater(scale, adaptive),
      ),
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
