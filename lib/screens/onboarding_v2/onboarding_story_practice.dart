import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/pressable.dart';
import '../../widgets/sori/speakable.dart';
import '../../widgets/sori/tokens.dart';
import 'onboarding_hanok_growth_preview.dart';

const learnedWord = '문';
const composition = 'ㅁ + ㅜ + ㄴ → 문';
const _jamoParts = 'ㅁ + ㅜ + ㄴ';
const _growthDuration = Duration(milliseconds: 420);

/// Ephemeral learning demonstration. Leaving the page discards its state.
class OnboardingJamoPractice extends StatefulWidget {
  const OnboardingJamoPractice({super.key});

  @override
  State<OnboardingJamoPractice> createState() => _OnboardingJamoPracticeState();
}

class _OnboardingJamoPracticeState extends State<OnboardingJamoPractice> {
  bool _composed = false;
  bool _playing = false;
  bool _failed = false;

  Future<void> _play() async {
    if (_playing) {
      return;
    }
    setState(() {
      _playing = true;
      _failed = false;
    });
    var played = false;
    try {
      played = await SoriSpeech.speak(learnedWord, voice: 'female');
    } catch (_) {
      // Audio is optional in this demonstration; the next action stays usable.
    }
    if (mounted) {
      setState(() {
        _playing = false;
        _failed = !played;
      });
    }
  }

  @override
  void dispose() {
    if (_playing) {
      unawaited(SoriSpeech.stop().catchError((Object _) {}));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.hasBoundedHeight && constraints.maxHeight < 150;
        return SoriCard(
          key: const ValueKey('onboarding-v2-story-hero'),
          padding: EdgeInsets.all(compact ? Spacing.xs : Spacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                liveRegion: true,
                label: _failed
                    ? t.onboardingV2AudioUnavailable
                    : _composed
                    ? composition
                    : null,
                excludeSemantics: _failed || _composed,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _composed ? composition : _jamoParts,
                    key: const ValueKey('onboarding-v2-jamo-result'),
                    locale: const Locale('ko'),
                    textAlign: TextAlign.center,
                    style: text.koDisplay,
                  ),
                ),
              ),
              SizedBox(height: compact ? Spacing.xs : Spacing.sm),
              SoriButton.filled(
                key: const ValueKey('onboarding-v2-jamo-action'),
                semanticLabel: _failed ? t.onboardingV2AudioUnavailable : null,
                label: _failed
                    ? t.btnRetry
                    : _composed
                    ? (_playing
                          ? t.onboardingV2AudioPlaying
                          : t.onboardingV2PlayGa)
                    : t.onboardingV2ComposeGa,
                size: SoriButtonSize.md,
                fullWidth: true,
                onTap: _playing
                    ? null
                    : _composed
                    ? _play
                    : () {
                        setState(() => _composed = true);
                        unawaited(_play());
                      },
              ),
              if (_failed && constraints.maxHeight >= 380) ...[
                const SizedBox(height: Spacing.sm),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    t.onboardingV2AudioUnavailable,
                    textAlign: TextAlign.center,
                    style: text.bodySmall,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// A recognition question followed by an independently opened demo gift.
/// This widget has no reward, XP, persistence, or progression service access.
class OnboardingRewardPractice extends StatefulWidget {
  const OnboardingRewardPractice({super.key, required this.character});

  final Widget character;

  @override
  State<OnboardingRewardPractice> createState() =>
      _OnboardingRewardPracticeState();
}

class _OnboardingRewardPracticeState extends State<OnboardingRewardPractice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal;

  @override
  void initState() {
    super.initState();
    _reveal =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 800),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() {});
          }
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_opened && MediaQuery.disableAnimationsOf(context)) {
      _reveal.value = 1;
    }
    if (_correct && MediaQuery.disableAnimationsOf(context)) {
      _growthReady = true;
    }
  }

  void _unwrap() {
    if (!_correct || !_growthReady || !_giftDiscovered || _opened) {
      return;
    }
    setState(() => _opened = true);
    if (MediaQuery.disableAnimationsOf(context)) {
      _reveal.value = 1;
    } else {
      _reveal.forward();
    }
  }

  @override
  void dispose() {
    _growthTimer?.cancel();
    _reveal.dispose();
    super.dispose();
  }

  bool _correct = false;
  bool _wrong = false;
  bool _growthComplete = false;
  bool _growthReady = false;
  bool _giftDiscovered = false;
  bool _opened = false;
  Timer? _growthTimer;

  void _answer(String answer) {
    _growthTimer?.cancel();
    final correct = answer == learnedWord;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    setState(() {
      _correct = correct;
      _wrong = !correct;
      _growthComplete = correct;
      _growthReady = correct && reduceMotion;
      _giftDiscovered = false;
    });
    if (correct && !reduceMotion) {
      _growthTimer = Timer(_growthDuration, () {
        if (mounted) {
          setState(() => _growthReady = true);
        }
      });
    }
  }

  void _discoverGift() {
    if (!_correct || !_growthReady || _giftDiscovered) {
      return;
    }
    setState(() => _giftDiscovered = true);
  }

  void _replay() {
    _growthTimer?.cancel();
    _reveal.stop();
    _reveal.value = 0;
    setState(() {
      _correct = false;
      _wrong = false;
      _growthComplete = false;
      _growthReady = false;
      _giftDiscovered = false;
      _opened = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final giftLabel = !_opened
        ? t.onboardingV2UnwrapGift
        : _reveal.isCompleted
        ? t.onboardingV2GiftOpened
        : t.onboardingV2GiftOpening;
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaledBodySize = MediaQuery.textScalerOf(context).scale(16);
        final showDemoNote =
            scaledBodySize <= 18 &&
            (!constraints.hasBoundedHeight || constraints.maxHeight >= 220);
        final giftEnabled = _giftDiscovered && !_opened;
        final scene = AnimatedSwitcher(
          duration: SoriMotion.respect(context, _growthDuration),
          child: !_giftDiscovered
              ? OnboardingHanokGrowthPreview(
                  key: const ValueKey('onboarding-v2-growth-scene'),
                  complete: _growthComplete,
                )
              : Row(
                  key: const ValueKey('onboarding-v2-gift-scene'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: widget.character),
                    Expanded(
                      child: Semantics(
                        key: const ValueKey('onboarding-v2-gift-action'),
                        button: true,
                        enabled: giftEnabled,
                        label: giftLabel,
                        onTap: giftEnabled ? _unwrap : null,
                        excludeSemantics: true,
                        child: SoriPressable(
                          onTap: giftEnabled ? _unwrap : null,
                          child: AnimatedBuilder(
                            animation: _reveal,
                            builder: (context, child) => _BojagiReveal(
                              progress: _reveal.value,
                              opened: _opened,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
        return Column(
          key: const ValueKey('onboarding-v2-story-hero'),
          mainAxisSize: constraints.hasBoundedHeight
              ? MainAxisSize.max
              : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (constraints.hasBoundedHeight)
              Expanded(child: scene)
            else
              AspectRatio(aspectRatio: 1.8, child: scene),
            const SizedBox(height: Spacing.sm),
            if (!_giftDiscovered) ...[
              Semantics(
                liveRegion: _wrong || _correct,
                child: Text(
                  _correct
                      ? t.onboardingV2RecognitionCorrect
                      : _wrong
                      ? t.onboardingV2RecognitionRetry
                      : t.onboardingV2RecognitionPrompt,
                  key: _correct
                      ? const ValueKey('onboarding-v2-answer-correct')
                      : _wrong
                      ? const ValueKey('onboarding-v2-answer-retry')
                      : null,
                  textAlign: TextAlign.center,
                  style: text.body,
                ),
              ),
              const SizedBox(height: Spacing.sm),
            ],
            if (!_correct)
              Row(
                children: [
                  for (final (index, syllable) in const [
                    learnedWord,
                    '눈',
                    '물',
                  ].indexed) ...[
                    if (index > 0) const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Semantics(
                        label: syllable,
                        child: SoriButton.outlined(
                          key: ValueKey('onboarding-v2-answer-$syllable'),
                          label: syllable,
                          onTap: () => _answer(syllable),
                        ),
                      ),
                    ),
                  ],
                ],
              )
            else if (!_giftDiscovered)
              SoriButton.filled(
                key: const ValueKey('onboarding-v2-discover-gift'),
                label: t.onboardingV2DiscoverGift,
                size: SoriButtonSize.md,
                fullWidth: true,
                onTap: _growthReady ? _discoverGift : null,
              )
            else if (_opened && _reveal.isCompleted)
              SoriButton.outlined(
                key: const ValueKey('onboarding-v2-replay-demo'),
                label: t.onboardingV2ReplayDemo,
                size: SoriButtonSize.md,
                fullWidth: true,
                onTap: _replay,
              )
            else
              SoriButton.filled(
                key: const ValueKey('onboarding-v2-unwrap-gift'),
                label: giftLabel,
                size: SoriButtonSize.md,
                fullWidth: true,
                onTap: giftEnabled ? _unwrap : null,
              ),
            if (showDemoNote) ...[
              const SizedBox(height: Spacing.sm),
              Semantics(
                liveRegion: _opened,
                child: Text(
                  t.onboardingV2RewardDemoNote,
                  textAlign: TextAlign.center,
                  style: text.bodySmall,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BojagiReveal extends StatelessWidget {
  const _BojagiReveal({required this.progress, required this.opened});
  final double progress;
  final bool opened;

  @override
  Widget build(BuildContext context) {
    // 0–120 ms: anticipation; 120–340 ms: cloth opens; 300–750 ms:
    // the gift rises with a brief burst, then rests above the open parcel.
    final anticipation = math.sin((progress / .15).clamp(0.0, 1.0) * math.pi);
    final opening = const Interval(
      .15,
      .425,
      curve: Curves.easeInOutCubic,
    ).transform(progress);
    final gift = const Interval(
      .375,
      .94,
      curve: Curves.easeOutBack,
    ).transform(progress);
    final burst = const Interval(
      .375,
      .94,
      curve: Curves.easeOutCubic,
    ).transform(progress);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return Stack(
          key: ValueKey('onboarding-v2-gift-$opened'),
          fit: StackFit.expand,
          children: [
            if (opening < 1)
              Transform(
                key: const ValueKey('onboarding-v2-gift-anticipation'),
                alignment: const Alignment(0, .5),
                transform: Matrix4.diagonal3Values(
                  1 + .06 * anticipation,
                  1 - .09 * anticipation,
                  1,
                ),
                child: Opacity(
                  opacity: 1 - opening,
                  child: Image.asset(
                    'assets/illustrations/reward/reward_bojagi_closed.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            if (opening > 0)
              Opacity(
                opacity: opening,
                child: Transform.scale(
                  scale: .93 + .07 * opening,
                  child: Image.asset(
                    'assets/illustrations/reward/reward_bojagi_open.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            if (progress > .375) ...[
              CustomPaint(
                key: const ValueKey('onboarding-v2-gift-sparks'),
                painter: _GiftSparks(progress: burst),
              ),
              Positioned(
                top: size.height * (.42 - .28 * gift),
                left: size.width * .28,
                width: size.width * .44,
                height: size.height * .38,
                child: Transform.scale(
                  key: const ValueKey('onboarding-v2-gift-pop'),
                  scale: gift,
                  child: Image.asset(
                    'assets/illustrations/stamps/stamp_taegeuk.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _GiftSparks extends CustomPainter {
  const _GiftSparks({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) {
      return;
    }
    final center = Offset(size.width * .5, size.height * .36);
    final radius = size.shortestSide * (.14 + .28 * progress);
    final paint = Paint()
      ..color = SoriColors.gold.withValues(alpha: (1 - progress).clamp(0, 1))
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 8; index++) {
      final angle = index * math.pi / 4;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * radius,
        center + direction * (radius + 6),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GiftSparks oldDelegate) =>
      oldDelegate.progress != progress;
}
