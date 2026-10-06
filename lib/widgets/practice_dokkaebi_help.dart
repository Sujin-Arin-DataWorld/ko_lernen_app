import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import 'practice_character_clip.dart';
import 'practice_dokkaebi_art.dart';
import 'practice_dokkaebi_canvas.dart';
import 'practice_dokkaebi_clip.dart';
import 'practice_dokkaebi_introduction.dart';
import 'practice_motion.dart';
import 'sori/pressable.dart';
import 'sori/tokens.dart';

class PracticeDokkaebiHelp extends StatelessWidget {
  const PracticeDokkaebiHelp({
    super.key,
    required this.child,
    this.compact = false,
  });
  final Widget child;
  final bool compact;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      Spacing.lg,
      compact ? Spacing.xs : Spacing.sm,
      Spacing.lg,
      compact ? Spacing.sm : Spacing.lg,
    ),
    child: child,
  );
}

/// The action belongs to the puzzle's edge, rather than to the help text.
class PracticeDokkaebiStage extends StatelessWidget {
  const PracticeDokkaebiStage({
    super.key,
    required this.requestId,
    required this.play,
    required this.helping,
    this.size = 176,
    this.onRequested,
    this.onImpact,
  });
  final int requestId;
  final bool play, helping;
  final double size;
  final VoidCallback? onRequested, onImpact;
  @override
  Widget build(BuildContext context) => PracticeViewportGate(
    requireFullVisibility: true,
    child: _DokkaebiStage(
      requestId: requestId,
      play: play,
      helping: helping,
      size: size,
      onRequested: onRequested,
      onImpact: onImpact,
    ),
  );
}

class _DokkaebiStage extends StatefulWidget {
  const _DokkaebiStage({
    required this.requestId,
    required this.play,
    required this.helping,
    required this.size,
    this.onRequested,
    this.onImpact,
  });
  final int requestId;
  final bool play, helping;
  final double size;
  final VoidCallback? onRequested, onImpact;
  @override
  State<_DokkaebiStage> createState() => _DokkaebiStageState();
}

class _DokkaebiStageState extends State<_DokkaebiStage>
    with SingleTickerProviderStateMixin {
  static const _fire =
      'assets/illustrations/decorations/decoration_dokkaebi_fire.png';
  late final _orbit = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  bool _postersCached = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_postersCached) {
      _postersCached = true;
      for (final clip in PracticeDokkaebiClip.values) {
        precacheImage(AssetImage(clip.startAsset), context);
        precacheImage(AssetImage(clip.endAsset), context);
      }
    }
    if (TickerMode.valuesOf(context).enabled) {
      if (!_orbit.isAnimating) _orbit.repeat();
    } else {
      _orbit.stop();
    }
  }

  void _impact(int request) {
    if (!mounted ||
        request != widget.requestId ||
        !TickerMode.valuesOf(context).enabled) {
      return;
    }
    widget.onImpact?.call();
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.requestId;
    final clip = PracticeDokkaebiClip.forRequest(request);
    return RepaintBoundary(
      child: SizedBox(
        key: const ValueKey('dokkaebi-motion-stage'),
        width: widget.size,
        height: widget.size / PracticeDokkaebiCanvas.aspectRatio,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: TickerMode.valuesOf(context).enabled
                    ? const Duration(milliseconds: 150)
                    : Duration.zero,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeOut,
                child: widget.requestId == 0
                    ? PracticeDokkaebiRestingArt(
                        key: const ValueKey('dokkaebi-idle-art'),
                        pose: widget.helping
                            ? PracticeDokkaebiPose.helping
                            : PracticeDokkaebiPose.ready,
                      )
                    : PracticeDokkaebiCanvas(
                        key: ValueKey('dokkaebi-canvas-${widget.requestId}'),
                        child: PracticeCharacterClip(
                          key: ValueKey('dokkaebi-clip-${widget.requestId}'),
                          videoAsset: clip.videoAsset,
                          startAsset: clip.startAsset,
                          endAsset: clip.endAsset,
                          // Preserve each MP4's matching poster and contact time.
                          impactAt: clip.impactAt,
                          play: widget.play,
                          explaining: widget.helping,
                          onRequested: widget.onRequested,
                          onImpact: () => _impact(request),
                        ),
                      ),
              ),
            ),
            for (var i = 0; i < 2; i++)
              Positioned(
                left: widget.size * (i == 0 ? .16 : .79),
                top: widget.size * (i == 0 ? .45 : .57),
                child: ExcludeSemantics(
                  child: IgnorePointer(
                    child: !TickerMode.valuesOf(context).enabled
                        ? Image.asset(
                            _fire,
                            key: ValueKey('dokkaebi-fire-$i'),
                            width: 26,
                            height: 26,
                            cacheWidth: 128,
                          )
                        : TweenAnimationBuilder<double>(
                            tween: Tween(end: request * math.pi / 2),
                            duration: TickerMode.valuesOf(context).enabled
                                ? const Duration(milliseconds: 250)
                                : Duration.zero,
                            child: Image.asset(
                              _fire,
                              key: ValueKey('dokkaebi-fire-$i'),
                              width: 26,
                              height: 26,
                              cacheWidth: 128,
                            ),
                            builder: (context, phase, child) => AnimatedBuilder(
                              animation: _orbit,
                              child: child,
                              builder: (context, child) {
                                final angle =
                                    _orbit.value * 2 * math.pi +
                                    i * math.pi +
                                    phase;
                                return Transform.translate(
                                  offset: TickerMode.valuesOf(context).enabled
                                      ? Offset(
                                          math.cos(angle) * 5,
                                          math.sin(angle) * 7,
                                        )
                                      : Offset.zero,
                                  child: Transform.rotate(
                                    angle: TickerMode.valuesOf(context).enabled
                                        ? math.sin(angle) * .1
                                        : 0,
                                    child: child,
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _orbit.dispose();
    super.dispose();
  }
}

/// Explicitly opened introduction: it never requests a hint or writes a result.
Future<void> showPracticeDokkaebiIntroduction(BuildContext context) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/games/dokkaebi-introduction'),
      builder: (_) => const PracticeDokkaebiIntroduction(),
    ),
  );
}

/// The fire opens the game introduction without reserving a header paragraph.
class PracticeDokkaebiFireAction extends StatelessWidget {
  const PracticeDokkaebiFireAction({super.key});
  @override
  Widget build(BuildContext context) =>
      const PracticeViewportGate(child: _FireAction());
}

class _FireAction extends StatelessWidget {
  const _FireAction();

  @override
  Widget build(BuildContext context) {
    final label = AppL10n.of(context).practiceDokkaebiMeet;
    return Semantics(
      label: label,
      button: true,
      child: SoriPressable(
        key: const ValueKey('dokkaebi-introduction'),
        onTap: () => showPracticeDokkaebiIntroduction(context),
        child: ExcludeSemantics(
          child: SizedBox.square(
            dimension: 48,
            child: Center(
              child: Image.asset(
                'assets/illustrations/decorations/decoration_dokkaebi_fire.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
