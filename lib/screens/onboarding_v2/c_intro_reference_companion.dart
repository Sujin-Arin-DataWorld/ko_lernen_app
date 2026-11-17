import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/intro_motion.dart';
import 'c_intro_art.dart';
import 'onboarding_v2_presentation.dart';

/// Native 07 controls reserve readable labels before shrinking the portraits.
/// Unbounded previews retain the approved 402 x 934 reference coordinates.
/// Selection only changes paint and semantics; both cards keep their bounds.
class IntroReferenceCompanion extends StatelessWidget {
  const IntroReferenceCompanion({
    super.key,
    required this.copy,
    required this.selectedCompanionId,
    required this.onCompanionChanged,
  });

  final OnboardingV2Copy copy;
  final String? selectedCompanionId;
  final ValueChanged<String> onCompanionChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final s = bounds.maxWidth / 402;
      if (bounds.hasBoundedHeight) {
        final t = AppL10n.of(context);
        final cardWidth = (bounds.maxWidth - 24 - 8) / 2;
        final roleStyle = IntroTypography.localized(
          context,
          IntroTypography.body(16, false, IntroPalette.mutedInk),
        ).copyWith(height: 1.2);
        var roleHeight = 0.0;
        for (final role in [t.onboardingCTaegoRole, t.onboardingCJoyRole]) {
          final painter = TextPainter(
            text: TextSpan(text: role, style: roleStyle),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 2,
          )..layout(maxWidth: cardWidth - 8);
          if (painter.height > roleHeight) {
            roleHeight = painter.height;
          }
          painter.dispose();
        }
        // Both complete portrait masters are 1024 x 1536. Their natural aspect
        // sets the card ceiling; spare window height stays outside the cards.
        final cardHeight = (cardWidth - 8) * 1.5 + 8 + 4 + 24 + 4 + roleHeight;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: cardHeight),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final id in [
                        OnboardingV2Ids.companionTaego,
                        OnboardingV2Ids.companionJoy,
                      ]) ...[
                        if (id == OnboardingV2Ids.companionJoy)
                          const SizedBox(width: 8),
                        Expanded(
                          child: _FiniteCompanionCard(
                            companion: copy.companion.companion(id),
                            roleHeight: roleHeight,
                            selected: selectedCompanionId == id,
                            onTap: () => onCompanionChanged(id),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const _FiniteGye(),
            ],
          ),
        );
      }
      return SizedBox(
        height: 525 * s,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final item in [
              (id: OnboardingV2Ids.companionTaego, x: 7.0, width: 195.0),
              (id: OnboardingV2Ids.companionJoy, x: 210.0, width: 188.0),
            ])
              Positioned(
                left: item.x * s,
                top: 0,
                width: item.width * s,
                height: 360 * s,
                child: _ReferenceCompanionCard(
                  companion: copy.companion.companion(item.id),
                  selected: selectedCompanionId == item.id,
                  scale: s,
                  onTap: () => onCompanionChanged(item.id),
                ),
              ),
            Positioned(
              left: 12 * s,
              top: 369 * s,
              width: 378 * s,
              height: 156 * s,
              child: _ReferenceGye(scale: s),
            ),
          ],
        ),
      );
    },
  );
}

class _FiniteCompanionCard extends StatelessWidget {
  const _FiniteCompanionCard({
    required this.companion,
    required this.roleHeight,
    required this.selected,
    required this.onTap,
  });

  final OnboardingCompanionSpec companion;
  final double roleHeight;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final taego = companion.id == OnboardingV2Ids.companionTaego;
    final role = taego ? t.onboardingCTaegoRole : t.onboardingCJoyRole;
    return MergeSemantics(
      child: Semantics(
        key: ValueKey('onboarding-v2-companion-semantics-${companion.id}'),
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        label: '${companion.name}. $role',
        onTap: onTap,
        child: IntroPressable(
          key: ValueKey('onboarding-v2-companion-${companion.id}'),
          onTap: onTap,
          pressScale: .995,
          surfaceDepth: 0,
          child: ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xccfff6e7),
                borderRadius: BorderRadius.circular(
                  IntroGeometry.companionCard,
                ),
                border: Border.all(color: const Color(0xfff5e5cf)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2e967b53),
                    offset: Offset(0, 1.5),
                    blurRadius: 1,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              IntroGeometry.portrait,
                            ),
                            child: CIntroArt(
                              taego ? 'taego-close' : 'joy-close',
                            ),
                          ),
                          Positioned.fill(
                            child: IntroCompanionPortraitRim(
                              selected: selected,
                            ),
                          ),
                          Positioned(
                            left: 4,
                            bottom: 4,
                            child: IntroSelectionMotion(
                              selected: selected,
                              child: const IntroMedal('✓', size: 28),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 24,
                      child: Center(
                        child: Text(
                          companion.name,
                          textAlign: TextAlign.center,
                          style: IntroTypography.localized(
                            context,
                            IntroTypography.body(18, true, IntroPalette.ink),
                            heading: true,
                          ).copyWith(height: 1.2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: roleHeight,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          role,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: IntroTypography.localized(
                            context,
                            IntroTypography.body(
                              16,
                              false,
                              IntroPalette.mutedInk,
                            ),
                          ).copyWith(height: 1.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FiniteGye extends StatelessWidget {
  const _FiniteGye();

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x99fff6e7),
        borderRadius: BorderRadius.circular(IntroGeometry.card),
        border: Border.all(color: const Color(0xfffff9e9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3d967b53),
            offset: Offset(0, 1.4),
            blurRadius: 1.1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            const Expanded(
              flex: 2,
              child: AspectRatio(
                aspectRatio: 1.5,
                child: CIntroArt('gye-reading'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.onboardingCGyeTitle,
                    style: IntroTypography.localized(
                      context,
                      IntroTypography.body(18, true, IntroPalette.ink),
                      heading: true,
                    ).copyWith(height: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.onboardingCGyeBody,
                    style: IntroTypography.localized(
                      context,
                      IntroTypography.body(16, false, IntroPalette.mutedInk),
                    ).copyWith(height: 1.2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceCompanionCard extends StatelessWidget {
  const _ReferenceCompanionCard({
    required this.companion,
    required this.selected,
    required this.scale,
    required this.onTap,
  });

  final OnboardingCompanionSpec companion;
  final bool selected;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = AppL10n.of(context);
    final taego = companion.id == OnboardingV2Ids.companionTaego;
    final role = taego ? t.onboardingCTaegoRole : t.onboardingCJoyRole;
    return MergeSemantics(
      child: Semantics(
        key: ValueKey('onboarding-v2-companion-semantics-${companion.id}'),
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        label: '${companion.name}. $role',
        onTap: onTap,
        child: IntroPressable(
          key: ValueKey('onboarding-v2-companion-${companion.id}'),
          onTap: onTap,
          pressScale: .995,
          surfaceDepth: 0,
          child: ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xccfff6e7),
                borderRadius: BorderRadius.circular(
                  IntroGeometry.companionCard * s,
                ),
                border: Border.all(
                  color: const Color(0xfff5e5cf),
                  width: .65 * s,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x2e967b53),
                    offset: Offset(0, 1.5 * s),
                    blurRadius: s,
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: (taego ? 3 : 0) * s,
                    top: 3 * s,
                    width: (taego ? 190 : 188) * s,
                    height: 285 * s,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        IntroGeometry.portrait * s,
                      ),
                      child: CIntroArt(taego ? 'taego-close' : 'joy-close'),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 288 * s,
                    child: IntroCompanionPortraitRim(
                      selected: selected,
                      scale: s,
                    ),
                  ),
                  Positioned(
                    left: (taego ? 11 : 132) * s,
                    top: 239 * s,
                    child: IntroSelectionMotion(
                      selected: selected,
                      child: IntroMedal('✓', size: 46 * s),
                    ),
                  ),
                  Positioned(
                    left: 3 * s,
                    right: 3 * s,
                    top: 294 * s,
                    height: 34 * s,
                    child: _ReferenceWords(
                      companion.name,
                      size: 26,
                      line: 34,
                      scale: s,
                      bold: true,
                      center: true,
                      color: const Color(0xff09121a),
                    ),
                  ),
                  Positioned(
                    left: 4 * s,
                    right: 4 * s,
                    top: 325 * s,
                    height: 26 * s,
                    child: _ReferenceWords(
                      role,
                      size: taego ? 17.5 : 15,
                      line: 26,
                      scale: s,
                      center: true,
                      color: IntroPalette.mutedInk,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The jade rail and two gold bevels are paint-only overlays. They never add
/// border padding or change the portrait's layout when selection changes.
class IntroCompanionPortraitRim extends StatelessWidget {
  const IntroCompanionPortraitRim({
    super.key,
    required this.selected,
    this.scale = 1,
  });

  final bool selected;
  final double scale;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _PortraitRimPainter(selected: selected, scale: scale),
    ),
  );
}

class _PortraitRimPainter extends CustomPainter {
  const _PortraitRimPainter({required this.selected, required this.scale});

  final bool selected;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    if (!selected) return;
    final s = scale;
    final bounds = Offset.zero & size;
    final rail = RRect.fromRectAndRadius(
      bounds.deflate(1.3 * s),
      Radius.circular(IntroGeometry.portraitRail * s),
    );
    canvas.drawRRect(
      rail.shift(Offset(0, 2 * s)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6 * s
        ..color = const Color(0x3d5a3919)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.2 * s),
    );
    void stroke(
      Rect rect,
      double radius,
      double width,
      List<Color> colors,
      List<double> stops,
    ) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.deflate(width / 2),
          Radius.circular(radius - width / 2),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
            stops: stops,
          ).createShader(rect),
      );
    }

    stroke(
      bounds,
      17 * s,
      2.6 * s,
      const [Color(0xff087b6a), Color(0xff00594d), Color(0xff003e33)],
      const [0, .42, 1],
    );
    stroke(
      bounds,
      17 * s,
      .85 * s,
      const [Color(0xffffe6a5), Color(0xffc69a4d), Color(0xff81531f)],
      const [0, .35, 1],
    );
    stroke(
      bounds.deflate(3 * s),
      14 * s,
      .75 * s,
      const [Color(0xfffff0bc), Color(0xffc6a05a), Color(0xffe5c57d)],
      const [0, .5, 1],
    );
  }

  @override
  bool shouldRepaint(_PortraitRimPainter oldDelegate) =>
      oldDelegate.selected != selected || oldDelegate.scale != scale;
}

class _ReferenceGye extends StatelessWidget {
  const _ReferenceGye({required this.scale});
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = AppL10n.of(context);
    final body = t.onboardingCGyeBody;
    final split = body.indexOf('. ');
    final bodySpans = split < 0
        ? [TextSpan(text: body)]
        : [
            TextSpan(text: '${body.substring(0, split + 1)}\n'),
            TextSpan(
              text: body.substring(split + 2),
              style: IntroTypography.secondaryInk,
            ),
          ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x99fff6e7),
        borderRadius: BorderRadius.circular(IntroGeometry.card * s),
        border: Border.all(color: const Color(0xfffff9e9), width: s),
        boxShadow: [
          BoxShadow(
            color: const Color(0x3d967b53),
            offset: Offset(0, 1.4 * s),
            blurRadius: 1.1 * s,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(IntroGeometry.card * s),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 6.667 * s,
              width: 214 * s,
              height: 142.667 * s,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  IntroGeometry.interestArt * s,
                ),
                child: const CIntroArt('gye-reading'),
              ),
            ),
            Positioned(
              left: 222 * s,
              top: 44 * s,
              width: 156 * s,
              height: 24 * s,
              child: _ReferenceWords(
                t.onboardingCGyeTitle,
                size: 17,
                line: 24,
                scale: s,
                bold: true,
                color: const Color(0xff111820),
              ),
            ),
            Positioned(
              left: 223 * s,
              top: 67 * s,
              width: 155 * s,
              height: 44 * s,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(children: bodySpans),
                  style: IntroTypography.gyeBody(s),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceWords extends StatelessWidget {
  const _ReferenceWords(
    this.text, {
    required this.size,
    required this.line,
    required this.scale,
    required this.color,
    this.bold = false,
    this.center = false,
  });

  final String text;
  final double size, line, scale;
  final Color color;
  final bool bold, center;

  @override
  Widget build(BuildContext context) => Align(
    alignment: center ? Alignment.center : Alignment.centerLeft,
    child: Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: IntroTypography.companionWords(size, line, scale, bold, color),
    ),
  );
}
