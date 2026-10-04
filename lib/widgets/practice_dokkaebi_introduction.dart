import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/storage_service.dart';
import 'practice_character_clip.dart';
import 'practice_dokkaebi_art.dart';
import 'practice_dokkaebi_clip.dart';
import 'practice_layout.dart';
import 'practice_magic.dart';
import 'practice_motion.dart';
import 'sori/button.dart';
import 'sori/external_link.dart';
import 'sori/pressable.dart';
import 'sori/tiger_video.dart';
import 'sori/tokens.dart';

enum _Topic { tales, home, learning }

/// A voluntary introduction. Exploration never creates practice or rewards.
class PracticeDokkaebiIntroduction extends StatefulWidget {
  const PracticeDokkaebiIntroduction({super.key, this.paddedBySheet = false});

  /// The shared sheet already owns its horizontal content inset.
  final bool paddedBySheet;

  @override
  State<PracticeDokkaebiIntroduction> createState() =>
      _PracticeDokkaebiIntroductionState();
}

class _PracticeDokkaebiIntroductionState
    extends State<PracticeDokkaebiIntroduction> {
  final _stageAnchor = GlobalKey();
  _Topic _topic = _Topic.learning;
  int _request = 1, _spark = 0;
  int _swingCount = 0;
  bool _play = false, _shown = false, _fireWord = false, _roof = false;
  bool _magical = false;
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
  }

  void _select(_Topic topic) {
    if (_topic == topic) return;
    setState(() {
      _topic = topic;
      _request++;
      _shown = _play = _roof = false;
      _magical = false;
      _spark++;
    });
  }

  void _showSwing() {
    setState(() {
      _request++;
      _swingCount++;
      _shown = _play = false;
    });
    final request = _request;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final anchor = _stageAnchor.currentContext;
      if (!mounted || anchor == null || request != _request) return;
      await Scrollable.ensureVisible(
        anchor,
        alignment: .1,
        duration: SoriMotion.respect(context, SoriMotion.medium),
      );
      if (mounted && request == _request) {
        setState(() {
          _shown = _play = true;
        });
      }
    });
  }

  Duration _duration(BuildContext context, Duration value) =>
      Storage.reducedMotion
      ? Duration.zero
      : SoriMotion.respect(context, value);

  Widget _sizeTransition(BuildContext context, Widget child) {
    final duration = _duration(context, SoriMotion.medium);
    return duration == Duration.zero
        ? child
        : AnimatedSize(
            duration: duration,
            alignment: Alignment.topCenter,
            child: child,
          );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final clip = PracticeDokkaebiClip.forRequest(_swingCount);
    final text = SoriTextTheme.of(context);
    final size = MediaQuery.sizeOf(context);
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final horizontalPadding = widget.paddedBySheet ? 0.0 : Spacing.xl;
    final canPlay =
        !Storage.reducedMotion &&
        !MediaQuery.disableAnimationsOf(context) &&
        TigerStageVideo.videoReady &&
        Theme.of(context).brightness == Brightness.light;
    final (title, body, pose) = switch (_topic) {
      _Topic.tales => (
        t.practiceDokkaebiTalesTitle,
        t.practiceDokkaebiTalesBody,
        PracticeDokkaebiPose.helping,
      ),
      _Topic.home => (
        t.practiceDokkaebiHomeTitle,
        t.practiceDokkaebiHomeBody,
        PracticeDokkaebiPose.review,
      ),
      _Topic.learning => (
        t.practiceDokkaebiLearningTitle,
        t.practiceDokkaebiLearningBody,
        PracticeDokkaebiPose.inviting,
      ),
    };
    return SafeArea(
      top: false,
      child: SizedBox(
        height: size.height * .87,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  Spacing.sm,
                  horizontalPadding,
                  Spacing.xl,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          header: true,
                          // l10n: exempt — Korean cultural name taught in every UI locale.
                          child: Text('도깨비', style: text.cultureTitle),
                        ),
                        const SizedBox(height: Spacing.sm),
                        Text(t.practiceDokkaebiAbout, style: text.body),
                        const SizedBox(height: Spacing.lg),
                        Center(
                          child: PracticeViewportGate(
                            requireFullVisibility: true,
                            child: SizedBox.square(
                              key: _stageAnchor,
                              dimension: size.height < 600 ? 128 : 184,
                              child: _IntroductionStage(
                                spark: _spark,
                                fireLabel: t.practiceDokkaebiFireAction,
                                onFire: () => setState(() {
                                  _fireWord = !_fireWord;
                                  _spark++;
                                }),
                                child: AnimatedSwitcher(
                                  duration: _duration(
                                    context,
                                    const Duration(milliseconds: 150),
                                  ),
                                  child: !_shown
                                      ? PracticeDokkaebiArt(
                                          key: ValueKey(
                                            _magical
                                                ? PracticeDokkaebiPose.magical
                                                : pose,
                                          ),
                                          pose: _magical
                                              ? PracticeDokkaebiPose.magical
                                              : pose,
                                        )
                                      : PracticeCharacterClip(
                                          key: ValueKey(
                                            'dokkaebi-intro-$_request',
                                          ),
                                          videoAsset: clip.videoAsset,
                                          startAsset: clip.startAsset,
                                          endAsset: clip.endAsset,
                                          explaining: true,
                                          play: _play,
                                          onRequested: () {
                                            if (mounted) {
                                              setState(() => _play = false);
                                            }
                                          },
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_fireWord) ...[
                          const SizedBox(height: Spacing.md),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              t.practiceDokkaebiFireWord,
                              key: const ValueKey('dokkaebi-fire-word'),
                              textAlign: TextAlign.center,
                              style: text.body,
                            ),
                          ),
                        ],
                        const SizedBox(height: Spacing.lg),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final stacked =
                                scale > 1.4 ||
                                constraints.maxWidth <
                                    SoriBreakpoints.cultureTopicsStack;
                            final labels = [
                              t.practiceDokkaebiTopicTales,
                              t.practiceDokkaebiTopicHome,
                              t.practiceDokkaebiTopicLearning,
                            ];
                            const artwork = [
                              'assets/illustrations/tactile/dokkaebi_topics/tales.webp',
                              'assets/illustrations/tactile/dokkaebi_topics/home.webp',
                              'assets/illustrations/tactile/dokkaebi_topics/learning.webp',
                            ];
                            return Wrap(
                              spacing: Spacing.sm,
                              runSpacing: Spacing.md,
                              children: [
                                for (final topic in _Topic.values)
                                  SizedBox(
                                    width: stacked
                                        ? constraints.maxWidth
                                        : (constraints.maxWidth - 16) / 3,
                                    child: _TopicTile(
                                      key: ValueKey(
                                        'dokkaebi-topic-${topic.name}',
                                      ),
                                      label: labels[topic.index],
                                      artwork: artwork[topic.index],
                                      selected: _topic == topic,
                                      onTap: () => _select(topic),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: Spacing.xl),
                        _sizeTransition(
                          context,
                          PracticeMotionSurface(
                            interactive: false,
                            child: PracticeMagicFrame(
                              pulse: _spark,
                              child: PracticeDialogueBubble(
                                child: Semantics(
                                  liveRegion: true,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(title, style: text.h3),
                                      const SizedBox(height: Spacing.md),
                                      Text(body, style: text.body),
                                      if (_topic == _Topic.tales) ...[
                                        const SizedBox(height: Spacing.lg),
                                        Text(
                                          t.practiceDokkaebiFormNote,
                                          style: text.caption,
                                        ),
                                        const SizedBox(height: Spacing.md),
                                        PracticeRaisedAction(
                                          child: SoriButton.outlined(
                                            key: const ValueKey(
                                              'dokkaebi-form-toggle',
                                            ),
                                            label: _magical
                                                ? t.practiceDokkaebiFormReturn
                                                : t.practiceDokkaebiFormAction,
                                            fullWidth: true,
                                            onTap: () {
                                              setState(() {
                                                _magical = !_magical;
                                                _shown = _play = false;
                                                _request++;
                                                _spark++;
                                              });
                                              final anchor =
                                                  _stageAnchor.currentContext;
                                              if (anchor != null) {
                                                Scrollable.ensureVisible(
                                                  anchor,
                                                  alignment: .1,
                                                  duration: _duration(
                                                    context,
                                                    SoriMotion.medium,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                      if (_topic == _Topic.learning) ...[
                                        const SizedBox(height: Spacing.lg),
                                        Text(
                                          t.practiceDokkaebiLearningNote,
                                          style: text.bodySmall,
                                        ),
                                        const SizedBox(height: Spacing.md),
                                        Text(
                                          t.practiceDokkaebiAppStory,
                                          style: text.caption,
                                        ),
                                      ] else ...[
                                        const SizedBox(height: Spacing.lg),
                                        SoriButton.ghost(
                                          label:
                                              t.practiceDokkaebiFolkloreSource,
                                          trailingIcon:
                                              Icons.open_in_new_rounded,
                                          onTap: () => openExternalUrl(
                                            context,
                                            _topic == _Topic.tales
                                                ? 'https://encykorea.aks.ac.kr/Article/E0015531'
                                                : 'https://encykorea.aks.ac.kr/Article/E0015527',
                                          ),
                                        ),
                                      ],
                                      if (_topic == _Topic.home) ...[
                                        const SizedBox(height: Spacing.md),
                                        Semantics(
                                          expanded: _roof,
                                          child: PracticeRaisedAction(
                                            child: SoriButton.outlined(
                                              key: const ValueKey(
                                                'dokkaebi-roof-toggle',
                                              ),
                                              label:
                                                  t.practiceDokkaebiRoofAction,
                                              trailingIcon: _roof
                                                  ? Icons.expand_less_rounded
                                                  : Icons.expand_more_rounded,
                                              fullWidth: true,
                                              onTap: () => setState(
                                                () => _roof = !_roof,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (_roof) ...[
                                          const SizedBox(height: Spacing.lg),
                                          // l10n: exempt — Korean artifact name taught in every UI locale.
                                          Text('귀면와', style: text.cultureTitle),
                                          const SizedBox(height: Spacing.sm),
                                          Text(
                                            t.practiceDokkaebiRoofBody,
                                            style: text.body,
                                          ),
                                          const SizedBox(height: Spacing.md),
                                          SoriButton.ghost(
                                            label:
                                                t.practiceDokkaebiMuseumSource,
                                            trailingIcon:
                                                Icons.open_in_new_rounded,
                                            onTap: () => openExternalUrl(
                                              context,
                                              'https://www.museum.go.kr/site/main/relic/search/view?relicId=1478',
                                            ),
                                          ),
                                        ],
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (canPlay && !_magical) ...[
                          const SizedBox(height: Spacing.xl),
                          PracticeRaisedAction(
                            child: SoriButton.outlined(
                              label: t.practiceDokkaebiGesture,
                              fullWidth: true,
                              onTap: _showSwing,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                Spacing.lg,
                horizontalPadding,
                Spacing.lg,
              ),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: PracticeRaisedAction(
                    primary: true,
                    child: SoriButton.filled(
                      label: t.practiceDokkaebiReturn,
                      fullWidth: true,
                      onTap: () => Navigator.of(context).pop(),
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
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({
    super.key,
    required this.label,
    required this.artwork,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String artwork;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    final ink = surfaces.brightness == Brightness.light
        ? SoriColors.primaryOnLight
        : SoriColors.primaryOnDark;
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      onTap: onTap,
      child: ExcludeSemantics(
        child: SoriPressable(
          onTap: onTap,
          pressScale: .99,
          surfaceDepth: 3,
          surfaceRadius: SoriRadius.md,
          surfaceEdgeColor: surfaces.border,
          tactileTilt: true,
          child: Padding(
            padding: const EdgeInsets.only(bottom: Spacing.xs),
            child: Container(
              constraints: const BoxConstraints(minHeight: 88),
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: selected ? ink.withValues(alpha: .06) : surfaces.surface,
                borderRadius: BorderRadius.circular(SoriRadius.md),
                border: Border.all(
                  color: selected ? ink : surfaces.border,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Image.asset(
                          artwork,
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                          cacheWidth: 192,
                          excludeFromSemantics: true,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: SoriTextTheme.of(
                          context,
                        ).menuLabel.copyWith(color: ink),
                      ),
                    ],
                  ),
                  if (selected)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: ink,
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

/// Two discoverable fire buttons float in a bounded stage; a tap pulses once.
class _IntroductionStage extends StatefulWidget {
  const _IntroductionStage({
    required this.child,
    required this.spark,
    required this.fireLabel,
    required this.onFire,
  });
  final Widget child;
  final int spark;
  final String fireLabel;
  final VoidCallback onFire;

  @override
  State<_IntroductionStage> createState() => _IntroductionStageState();
}

class _IntroductionStageState extends State<_IntroductionStage>
    with TickerProviderStateMixin {
  late final _orbit = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  late final _pulse = AnimationController(
    vsync: this,
    duration: SoriMotion.medium,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.valuesOf(context).enabled) {
      if (!_orbit.isAnimating) _orbit.repeat();
    } else {
      _orbit.stop();
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void didUpdateWidget(_IntroductionStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spark != widget.spark &&
        TickerMode.valuesOf(context).enabled) {
      _pulse.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: Padding(padding: const EdgeInsets.all(8), child: widget.child),
      ),
      for (var i = 0; i < 2; i++)
        Positioned(
          left: i == 0 ? 0 : null,
          right: i == 1 ? 0 : null,
          top: i == 0 ? 24 : 72,
          child: Tooltip(
            richMessage: TextSpan(
              children: [
                WidgetSpan(
                  child: ExcludeSemantics(child: Text(widget.fireLabel)),
                ),
              ],
            ),
            excludeFromSemantics: true,
            ignorePointer: true,
            child: Semantics(
              label: widget.fireLabel,
              button: true,
              onTap: widget.onFire,
              child: ExcludeSemantics(
                child: SoriPressable(
                  key: ValueKey('dokkaebi-intro-fire-$i'),
                  pressScale: 1,
                  onTap: widget.onFire,
                  child: SizedBox.square(
                    dimension: 48,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_orbit, _pulse]),
                        builder: (context, child) {
                          final enabled = TickerMode.valuesOf(context).enabled;
                          final angle =
                              _orbit.value * math.pi * 2 + i * math.pi;
                          final bump = enabled
                              ? math.sin(_pulse.value * math.pi)
                              : 0.0;
                          return Transform.translate(
                            offset: enabled
                                ? Offset(0, math.sin(angle) * 4)
                                : Offset.zero,
                            child: Transform.scale(
                              scale: 1 + bump * .12,
                              child: child,
                            ),
                          );
                        },
                        child: Image.asset(
                          'assets/illustrations/decorations/decoration_dokkaebi_fire.png',
                          width: 26,
                          height: 26,
                          cacheWidth: 128,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );

  @override
  void dispose() {
    _orbit.dispose();
    _pulse.dispose();
    super.dispose();
  }
}
