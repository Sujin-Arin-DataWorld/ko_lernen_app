import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/personal_hanok_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/personal_hanok.dart';
import 'button.dart';
import 'personal_hanok_map.dart';
import 'tokens.dart';

/// A short, local-only construction celebration for one newly unlocked layer.
///
/// The caller owns persistence and queueing. This widget only presents the
/// active building: its timber rises from the map, dust settles, and a brief
/// Dancheong glint makes the completed layer legible. With reduced motion it
/// becomes a static confirmation with an explicit dismissal.
class PersonalHanokUnlockReveal extends StatefulWidget {
  final PersonalHanokProjection projection;
  final PersonalHanokMilestone milestone;
  final String milestoneLabel;
  final VoidCallback onDone;
  final Duration duration;

  const PersonalHanokUnlockReveal({
    super.key,
    required this.projection,
    required this.milestone,
    required this.milestoneLabel,
    required this.onDone,
    this.duration = const Duration(milliseconds: 2200),
  });

  @override
  State<PersonalHanokUnlockReveal> createState() =>
      _PersonalHanokUnlockRevealState();
}

class _PersonalHanokUnlockRevealState extends State<PersonalHanokUnlockReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  var _started = false;
  var _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _finish();
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && !MediaQuery.of(context).disableAnimations) {
      _started = true;
      _controller.forward();
    }
  }

  void _finish() {
    if (_completed) {
      return;
    }
    _completed = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final t = AppL10n.of(context);
    final layer = layerForMilestone(widget.milestone);
    final visualBounds = layer.visualBounds!;

    return Material(
      key: const ValueKey('personal-hanok-unlock-reveal'),
      color: Colors.black.withValues(alpha: 0.54),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Reserve enough space for localized copy and the explicit
            // reduced-motion action. On very short landscape screens the
            // surface scrolls instead of clipping a control below the edge.
            final mapHeight = math
                .max(120.0, constraints.maxHeight - 208)
                .toDouble();
            final mapWidth = math
                .min(
                  math.min(760.0, constraints.maxWidth - Spacing.lg * 2),
                  mapHeight * 4 / 3,
                )
                .toDouble();
            return SingleChildScrollView(
              padding: const EdgeInsets.all(Spacing.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(
                    0,
                    constraints.maxHeight - Spacing.lg * 2,
                  ),
                ),
                child: Center(
                  child: SizedBox(
                    width: mapWidth,
                    child: Semantics(
                      liveRegion: true,
                      label: t.hanokWorldRevealTitle(widget.milestoneLabel),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AspectRatio(
                            aspectRatio: 4 / 3,
                            child: ClipRRect(
                              borderRadius: SoriRadius.brLg,
                              child: AnimatedBuilder(
                                animation: _controller,
                                builder: (context, _) {
                                  final progress = reduceMotion
                                      ? 1.0
                                      : Curves.easeOutCubic.transform(
                                          _controller.value,
                                        );
                                  return _RevealMap(
                                    projection: widget.projection,
                                    milestone: widget.milestone,
                                    assetPath: layer.assetPath,
                                    visualBounds: visualBounds,
                                    progress: progress,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: Spacing.md),
                          _RevealCaption(
                            title: t.hanokWorldRevealTitle(
                              widget.milestoneLabel,
                            ),
                            body: t.hanokWorldRevealBody,
                            actionLabel: t.hanokWorldRevealContinue,
                            onDismiss: _finish,
                            showAction: reduceMotion,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RevealMap extends StatelessWidget {
  final PersonalHanokProjection projection;
  final PersonalHanokMilestone milestone;
  final String assetPath;
  final PersonalHanokRect visualBounds;
  final double progress;

  const _RevealMap({
    required this.projection,
    required this.milestone,
    required this.assetPath,
    required this.visualBounds,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final buildProgress = ((progress - .08) / .68)
            .clamp(0.0, 1.0)
            .toDouble();
        final glowProgress = ((progress - .62) / .38)
            .clamp(0.0, 1.0)
            .toDouble();
        return Stack(
          fit: StackFit.expand,
          children: [
            PersonalHanokMap(
              projection: projection,
              zoneLabel: (_) => '',
              showTargets: false,
              suppressedMilestones: {milestone},
            ),
            Transform.scale(
              scale: .97 + .03 * buildProgress,
              child: Opacity(
                opacity: buildProgress,
                child: ClipRect(
                  clipper: _ConstructionClipper(buildProgress),
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: CustomPaint(
                painter: _ConstructionDustPainter(
                  progress: progress,
                  visualBounds: visualBounds,
                ),
              ),
            ),
            if (glowProgress > 0)
              _DancheongGlint(
                visualBounds: visualBounds,
                canvasSize: constraints.biggest,
                progress: glowProgress,
              ),
          ],
        );
      },
    );
  }
}

class _ConstructionClipper extends CustomClipper<Rect> {
  final double progress;

  const _ConstructionClipper(this.progress);

  @override
  Rect getClip(Size size) {
    final visibleHeight = size.height * progress;
    return Rect.fromLTWH(
      0,
      size.height - visibleHeight,
      size.width,
      visibleHeight,
    );
  }

  @override
  bool shouldReclip(_ConstructionClipper oldClipper) =>
      oldClipper.progress != progress;
}

class _ConstructionDustPainter extends CustomPainter {
  final double progress;
  final PersonalHanokRect visualBounds;

  const _ConstructionDustPainter({
    required this.progress,
    required this.visualBounds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dust = ((1 - ((progress - .15) / .5).clamp(0.0, 1.0)) * .72)
        .toDouble();
    if (dust <= 0) {
      return;
    }
    final center = Offset(
      size.width * (visualBounds.left + visualBounds.width / 2),
      size.height * (visualBounds.top + visualBounds.height * .72),
    );
    final radius = size.shortestSide * (.035 + .045 * progress);
    final paint = Paint()
      ..color = SoriColors.gold.withValues(alpha: .18 * dust);
    canvas.drawCircle(center, radius * 2.1, paint);
    final speckPaint = Paint()
      ..color = SoriColors.gold.withValues(alpha: .72 * dust);
    const factors = <Offset>[
      Offset(-1.8, .3),
      Offset(-1.1, -.7),
      Offset(-.35, -.25),
      Offset(.45, -.8),
      Offset(1.2, -.35),
      Offset(1.9, .25),
    ];
    for (final factor in factors) {
      canvas.drawCircle(
        center + Offset(factor.dx * radius, factor.dy * radius),
        1.4 + progress * .8,
        speckPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ConstructionDustPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.visualBounds != visualBounds;
}

class _DancheongGlint extends StatelessWidget {
  final PersonalHanokRect visualBounds;
  final Size canvasSize;
  final double progress;

  const _DancheongGlint({
    required this.visualBounds,
    required this.canvasSize,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final left = canvasSize.width * visualBounds.left;
    final top = canvasSize.height * visualBounds.top;
    final width = canvasSize.width * visualBounds.width;
    final height = canvasSize.height * visualBounds.height;
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: SoriRadius.brSm,
            border: Border.all(
              color: SoriColors.gold.withValues(alpha: (1 - progress) * .86),
              width: 2,
            ),
            gradient: LinearGradient(
              begin: Alignment(-1 + progress * 2, -1),
              end: Alignment(-.25 + progress * 2, 1),
              colors: [
                SoriColors.primary.withValues(alpha: 0),
                SoriColors.gold.withValues(alpha: (1 - progress) * .28),
                SoriColors.primary.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RevealCaption extends StatelessWidget {
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onDismiss;
  final bool showAction;

  const _RevealCaption({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onDismiss,
    required this.showAction,
  });

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: SoriRadius.brLg,
        border: Border.all(color: SoriColors.gold.withValues(alpha: .44)),
        boxShadow: SoriElevation.low,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: text.h3, textAlign: TextAlign.center),
            const SizedBox(height: Spacing.xs),
            Text(body, style: text.bodySmall, textAlign: TextAlign.center),
            if (showAction) ...[
              const SizedBox(height: Spacing.md),
              SoriButton.filled(
                key: const ValueKey('personal-hanok-unlock-reveal-continue'),
                label: actionLabel,
                fullWidth: true,
                onTap: onDismiss,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
