import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/storage_service.dart';
import 'practice_dokkaebi_art.dart';
import 'practice_layout.dart';
import 'practice_magic.dart';
import 'practice_motion.dart';
import 'sori/button.dart';
import 'sori/dokkaebi_flame_frame.dart';
import 'sori/dokkaebi_intro.dart';
import 'sori/card.dart';
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
  bool _shown = true, _fireWord = false, _roof = false;
  bool _magical = false;
  bool _details = false;

  void _select(_Topic topic) {
    if (_topic == topic) return;
    setState(() {
      _topic = topic;
      _request++;
      _shown = _roof = false;
      _magical = false;
      _details = false;
      _spark++;
    });
  }

  void _showSwing() {
    setState(() {
      _request++;
      _shown = false;
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
          _shown = true;
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

  Widget _topics(AppL10n t, double scale, {bool compact = false}) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              compact ||
              scale > 1.4 ||
              constraints.maxWidth < SoriBreakpoints.cultureTopicsStack;
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
          final tiles = [
            for (final topic in _Topic.values)
              _TopicTile(
                key: ValueKey('dokkaebi-topic-${topic.name}'),
                label: labels[topic.index],
                artwork: artwork[topic.index],
                compact: compact,
                selected: _topic == topic,
                onTap: () => _select(topic),
              ),
          ];
          return stacked
              ? Column(
                  children: [
                    for (var i = 0; i < tiles.length; i++) ...[
                      if (i > 0) const SizedBox(height: Spacing.sm),
                      tiles[i],
                    ],
                  ],
                )
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < tiles.length; i++) ...[
                        if (i > 0) const SizedBox(width: Spacing.sm),
                        Expanded(child: tiles[i]),
                      ],
                    ],
                  ),
                );
        },
      );

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final size = MediaQuery.sizeOf(context);
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final horizontalPadding = widget.paddedBySheet ? 0.0 : Spacing.xl;
    final stageWidth = math.min(
      size.height < 600 ? 184.0 : 264.0,
      math.max(0.0, size.width - Spacing.xl * 2),
    );
    final canPlay =
        !Storage.reducedMotion &&
        !MediaQuery.disableAnimationsOf(context) &&
        TigerStageVideo.videoReady;
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
    final beside =
        scale <= 1.1 &&
        size.width - Spacing.xl * 2 >= SoriBreakpoints.cultureTopicsStack;
    final heroWidth = beside
        ? math.min(stageWidth, size.width - Spacing.xl * 2 - 108)
        : stageWidth;
    // Preserve room for the complete culture panel above the sheet footer.
    final compactHeroRatio = size.height <= 600 ? 1.1 : 1.3;
    Widget introductionStage(double viewportHeight) {
      final heroHeight = math.min(
        heroWidth * (beside ? compactHeroRatio : 1.5),
        math.max(0.0, viewportHeight - Spacing.sm),
      );
      return Center(
        child: PracticeViewportGate(
          requireFullVisibility: true,
          child: SizedBox(
            key: _stageAnchor,
            width: heroWidth,
            height: heroHeight,
            child: _IntroductionStage(
              spark: _spark,
              fireLabel: t.practiceDokkaebiFireAction,
              onFire: () => setState(() {
                _fireWord = !_fireWord;
                _spark++;
              }),
              child: Center(
                child: SizedBox(
                  width: heroHeight / 1.5,
                  child: _shown
                      ? DokkaebiIntro(
                          key: ValueKey('dokkaebi-intro-$_request'),
                          staticOnly: !canPlay,
                        )
                      : DokkaebiFlameFrame(
                          animate:
                              !Storage.reducedMotion &&
                              !MediaQuery.disableAnimationsOf(context),
                          child: PracticeDokkaebiArt(
                            key: ValueKey(
                              _magical ? PracticeDokkaebiPose.magical : pose,
                            ),
                            pose: _magical
                                ? PracticeDokkaebiPose.magical
                                : pose,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: SizedBox(
        height: size.height * .87,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, viewport) => SingleChildScrollView(
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
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Semantics(
                                      header: true,
                                      // l10n: exempt — Korean cultural name taught in every UI locale.
                                      child: Text(
                                        '도깨비',
                                        style: text.cultureTitle,
                                      ),
                                    ),
                                    const SizedBox(height: Spacing.xs),
                                    Text(
                                      t.practiceDokkaebiAbout,
                                      style: text.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              if (canPlay && !_magical)
                                _GestureAction(
                                  label: t.practiceDokkaebiGesture,
                                  onTap: _showSwing,
                                ),
                            ],
                          ),
                          const SizedBox(height: Spacing.sm),
                          if (beside)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: introductionStage(viewport.maxHeight),
                                ),
                                const SizedBox(width: Spacing.sm),
                                SizedBox(
                                  width: 100,
                                  child: _topics(t, scale, compact: true),
                                ),
                              ],
                            )
                          else
                            introductionStage(viewport.maxHeight),
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
                          if (!beside) ...[
                            const SizedBox(height: Spacing.sm),
                            _topics(t, scale),
                          ],
                          const SizedBox(height: Spacing.md),
                          _sizeTransition(
                            context,
                            PracticeMotionSurface(
                              interactive: false,
                              child: PracticeMagicFrame(
                                pulse: _spark,
                                child: SoriCard(
                                  key: const ValueKey('dokkaebi-explanation'),
                                  padding: const EdgeInsets.all(Spacing.lg),
                                  child: Semantics(
                                    liveRegion: true,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(title, style: text.h3),
                                        const SizedBox(height: Spacing.sm),
                                        Text(body, style: text.body),
                                        Semantics(
                                          expanded: _details,
                                          child: SoriButton.ghost(
                                            key: const ValueKey(
                                              'dokkaebi-details',
                                            ),
                                            label: t.catalogDetails,
                                            trailingIcon: _details
                                                ? Icons.expand_less_rounded
                                                : Icons.expand_more_rounded,
                                            onTap: () => setState(
                                              () => _details = !_details,
                                            ),
                                          ),
                                        ),
                                        if (_details &&
                                            _topic == _Topic.tales) ...[
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
                                                  _shown = false;
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
                                        if (_details &&
                                            _topic == _Topic.learning) ...[
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
                                        ] else if (_details) ...[
                                          const SizedBox(height: Spacing.lg),
                                          SoriButton.ghost(
                                            label: t
                                                .practiceDokkaebiFolkloreSource,
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
                                        if (_details &&
                                            _topic == _Topic.home) ...[
                                          const SizedBox(height: Spacing.md),
                                          Semantics(
                                            expanded: _roof,
                                            child: PracticeRaisedAction(
                                              child: SoriButton.outlined(
                                                key: const ValueKey(
                                                  'dokkaebi-roof-toggle',
                                                ),
                                                label: t
                                                    .practiceDokkaebiRoofAction,
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
                                            Text(
                                              '귀면와',
                                              style: text.cultureTitle,
                                            ),
                                            const SizedBox(height: Spacing.sm),
                                            Text(
                                              t.practiceDokkaebiRoofBody,
                                              style: text.body,
                                            ),
                                            const SizedBox(height: Spacing.md),
                                            SoriButton.ghost(
                                              label: t
                                                  .practiceDokkaebiMuseumSource,
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
                        ],
                      ),
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

class _GestureAction extends StatelessWidget {
  const _GestureAction({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    button: true,
    onTap: onTap,
    child: Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: ExcludeSemantics(
        child: SoriPressable(
          key: const ValueKey('dokkaebi-gesture'),
          onTap: onTap,
          surfaceDepth: 3,
          surfaceRadius: SoriRadius.md,
          surfaceEdgeColor: SoriSurfaces.of(context).border,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: SoriSurfaces.of(context).surface,
              borderRadius: BorderRadius.circular(SoriRadius.md),
              border: Border.all(color: SoriSurfaces.of(context).border),
            ),
            child: const Icon(Icons.play_arrow_rounded),
          ),
        ),
      ),
    ),
  );
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({
    super.key,
    required this.label,
    required this.artwork,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });
  final bool compact;
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
              constraints: BoxConstraints(
                minHeight: compact ? 96 : 88,
                maxHeight: compact ? 96 : double.infinity,
              ),
              padding: EdgeInsets.all(compact ? Spacing.xs : Spacing.sm),
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
                          width: compact ? 32 : 48,
                          height: compact ? 32 : 48,
                          fit: BoxFit.contain,
                          cacheWidth: 192,
                          excludeFromSemantics: true,
                        ),
                      ),
                      SizedBox(height: compact ? Spacing.xs : Spacing.sm),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: SoriTextTheme.of(context).menuLabel.copyWith(
                          color: ink,
                          fontSize: compact ? 13 : null,
                        ),
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

  bool get _motionEnabled =>
      TickerMode.valuesOf(context).enabled &&
      !MediaQuery.disableAnimationsOf(context) &&
      !Storage.reducedMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionEnabled) {
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
    if (oldWidget.spark != widget.spark && _motionEnabled) {
      _pulse.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: widget.child),
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
                          final enabled = _motionEnabled;
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
