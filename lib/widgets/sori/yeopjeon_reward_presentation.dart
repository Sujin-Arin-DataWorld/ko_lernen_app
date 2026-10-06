import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/companion_art.dart';
import '../../models/sori_stage_progression.dart';
import '../../models/yeopjeon_reward_moment.dart';
import '../../services/audio_policy.dart';
import '../../services/haptic_service.dart';
import '../../services/learning_journey.dart';
import '../../services/local_data_lifetime.dart';
import '../../services/sound_service.dart';
import '../../services/storage_service.dart';
import 'activity_illustration.dart';
import 'game_reward.dart';
import 'tokens.dart';
import 'video_lease.dart';
import 'sheet.dart';
import 'yeopjeon_wallet_card.dart';

enum _RewardPhase { awaitingFrame, preparingVideo, video, collection, settled }

/// The same confirmed receipt on native lesson results and the return sheet.
/// Media callbacks have no access to economic or learning mutations.
class YeopjeonRewardPresentation extends StatefulWidget {
  const YeopjeonRewardPresentation({
    super.key,
    required this.moment,
    this.attempt,
    this.maxStageSize = 256,
    this.leaseCoordinator,
    this.onOpenWallet,
  });
  final YeopjeonRewardMoment moment;
  final LearningAttempt? attempt;
  final double maxStageSize;
  final VideoLeaseCoordinator<VideoPlayerController>? leaseCoordinator;
  final VoidCallback? onOpenWallet;

  @override
  State<YeopjeonRewardPresentation> createState() =>
      _YeopjeonRewardPresentationState();
}

class _YeopjeonRewardPresentationState extends State<YeopjeonRewardPresentation>
    with TickerProviderStateMixin {
  final _stackKey = GlobalKey();
  final _amountKey = GlobalKey();
  final _walletKey = GlobalKey();
  final _lifetime = LocalDataLifetime.capture();
  late final _visibility = VideoLeaseEligibilityBinding(
    onChanged: _visibilityChanged,
  );
  late final _collection = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final _walletAccent = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  _RewardPhase _phase = _RewardPhase.awaitingFrame;
  VideoLeaseRequest<VideoPlayerController>? _lease;
  VideoPlayerController? _video;
  Timer? _deadline;
  Size? _window;
  bool _started = false;
  bool _feedbackGiven = false;
  bool _walletCued = false;
  bool _invalid = false;
  bool get _reduced =>
      Storage.reducedMotion || SoriMotion.reduceMotion(context);

  @override
  void initState() {
    super.initState();
    HapticService.preferencesChanged.addListener(_preferencesChanged);
    LocalDataLifetime.changes.addListener(_accountChanged);
    AudioPolicy.instance.addListener(_audioChanged);
    _collection.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _phase = _RewardPhase.settled);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visibility.attach(context);
    final window = MediaQuery.sizeOf(context);
    if (_started && (_reduced || (_window != null && _window != window))) {
      _settle(rebuild: false);
    }
    _window = window;
  }

  @override
  void didUpdateWidget(covariant YeopjeonRewardPresentation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Callers key by claim IDs. Replacing a payload in place still cannot
    // replay a consumed presentation or keep a stale texture alive.
    if (oldWidget.moment != widget.moment) {
      _settle(rebuild: false);
    }
  }

  void _accountChanged() {
    if (!_lifetime.isCurrent) {
      _invalid = true;
      _settle();
    }
  }

  void _preferencesChanged() {
    if (mounted && _reduced) {
      _settle();
    }
  }

  void _visibilityChanged() {
    if (mounted && _started && !_visibility.isVisible(context)) {
      _settle();
    }
  }

  void _onShown() {
    if (_started ||
        !mounted ||
        !_lifetime.isCurrent ||
        !_visibility.isVisible(context)) {
      return;
    }
    _started = true;
    if (_reduced) {
      _shortFeedback();
      _settle();
    } else if (widget.moment.playMintVideo) {
      setState(() => _phase = _RewardPhase.preparingVideo);
      // One deadline, from the first exposed reward frame. A late controller
      // is disposed by the shared coordinator and can never restart the film.
      _deadline = Timer(const Duration(seconds: 1), _startCollection);
      _lease = (widget.leaseCoordinator ?? soriVideoLease).register(
        asset: CompanionArt.mintVideo,
        eligible: _visibility.isVisible(context),
        prepare: (video) async {
          _lifetime.assertCurrent();
          await video.setLooping(false);
          await video.setVolume(
            AudioPolicy.instance.rewardVideoVolume(
              asset: CompanionArt.mintVideo,
            ),
          );
        },
        onGranted: _onGranted,
        onFailed: (_, __) => _startCollection(),
        onRevoked: _onRevoked,
      );
    } else {
      _startCollection();
    }
  }

  void _onGranted(VideoPlayerController video) {
    if (!mounted ||
        _phase != _RewardPhase.preparingVideo ||
        _reduced ||
        !_lifetime.isCurrent ||
        !_visibility.isVisible(context)) {
      _releaseVideo();
      return;
    }
    _deadline?.cancel();
    _deadline = null;
    _video = video..addListener(_videoTick);
    setState(() => _phase = _RewardPhase.video);
    unawaited(_play(video));
  }

  Future<void> _play(VideoPlayerController video) async {
    try {
      await video.play();
    } catch (_) {
      if (mounted && identical(video, _video)) {
        _startCollection();
      }
    }
  }

  void _onRevoked() {
    _video?.removeListener(_videoTick);
    _video = null;
    if (mounted && _phase == _RewardPhase.video) {
      // A different explicit reveal took the lease. Finish this presentation
      // instead of re-entering it when the other reveal closes.
      _settle();
    }
  }

  void _videoTick() {
    final value = _video?.value;
    if (value == null || !mounted) {
      return;
    }
    if (!_lifetime.isCurrent || !_visibility.isVisible(context)) {
      _settle();
    } else if (value.hasError) {
      _startCollection();
    } else {
      // Coins emerge at frame 89 of the original 24fps film. Use playback
      // position, so buffering cannot desynchronise the wallet cue.
      if (!_walletCued &&
          value.position >= const Duration(milliseconds: 3700)) {
        _walletCued = true;
        _walletAccent.forward(from: 0);
        unawaited(HapticService.heavyImpact());
      }
      if (value.duration > Duration.zero &&
          !value.isPlaying &&
          value.position >= value.duration - const Duration(milliseconds: 80)) {
        _settle();
      }
    }
  }

  void _audioChanged() {
    final video = _video;
    if (video != null) {
      unawaited(_applyVolume(video));
    }
  }

  Future<void> _applyVolume(VideoPlayerController video) async {
    try {
      await video.setVolume(
        AudioPolicy.instance.rewardVideoVolume(asset: CompanionArt.mintVideo),
      );
    } catch (_) {
      // Disposal may race a speech/settings notification.
    }
  }

  void _shortFeedback() {
    if (_feedbackGiven || _walletCued || !_lifetime.isCurrent) {
      return;
    }
    _feedbackGiven = true;
    if (AudioPolicy.instance.learningSpeechActive) {
      unawaited(HapticService.heavyImpact());
    } else {
      SoundService.complete();
    }
  }

  void _startCollection() {
    if (!mounted ||
        _phase == _RewardPhase.collection ||
        _phase == _RewardPhase.settled ||
        !_lifetime.isCurrent) {
      return;
    }
    if (!_visibility.isVisible(context)) {
      _settle();
      return;
    }
    _deadline?.cancel();
    _deadline = null;
    setState(
      () => _phase = _reduced ? _RewardPhase.settled : _RewardPhase.collection,
    );
    _releaseVideo();
    _shortFeedback();
    if (!_reduced) {
      _collection.forward(from: 0);
    }
  }

  void _settle({bool rebuild = true}) {
    _deadline?.cancel();
    _deadline = null;
    _phase = _RewardPhase.settled;
    _collection.stop();
    _walletAccent.stop();
    _releaseVideo();
    if (rebuild && mounted) {
      setState(() {});
    }
  }

  void _releaseVideo() {
    _video?.removeListener(_videoTick);
    _video = null;
    final lease = _lease;
    _lease = null;
    if (lease != null) {
      unawaited(lease.release());
    }
  }

  Offset? _centre(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    final stack = _stackKey.currentContext?.findRenderObject();
    if (box is! RenderBox ||
        stack is! RenderBox ||
        !box.hasSize ||
        !stack.hasSize) {
      return null;
    }
    return stack.globalToLocal(box.localToGlobal(box.size.center(Offset.zero)));
  }

  Widget _recordVisible(Widget child) {
    for (final claim in widget.moment.claims.entries) {
      child = LearningRewardPresentation(
        attempt: widget.attempt,
        kind: SoriRewardKind.yeopjeon,
        amount: claim.value,
        identity: claim.key,
        onShown: _onShown,
        child: child,
      );
    }
    return child;
  }

  void _openWallet() {
    _settle();
    if (widget.onOpenWallet case final open?) {
      open();
    } else {
      showSoriSheet<void>(
        context: context,
        builder: (_) => const YeopjeonWalletCard(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_invalid || widget.moment.amount <= 0) {
      return const SizedBox.shrink();
    }
    final t = AppL10n.of(context);
    final type = SoriTextTheme.of(context);
    final surfaces = SoriSurfaces.of(context);
    final media = MediaQuery.of(context);
    final compact = media.size.height < 700 || media.textScaler.scale(16) > 22;
    return RepaintBoundary(
      child: SoriRewardSurface(
        gold: true,
        padding: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(compact ? Spacing.sm + 4 : Spacing.md),
          child: LayoutBuilder(
            builder: (context, bounds) {
              final stageSize = math.min(
                compact
                    ? math.min(widget.maxStageSize, 160.0)
                    : widget.maxStageSize,
                bounds.maxWidth,
              );
              return Stack(
                key: _stackKey,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _recordVisible(
                        Semantics(
                          liveRegion: true,
                          label: t.yeopjeonEarned(widget.moment.amount),
                          child: AnimatedBuilder(
                            animation: _collection,
                            child: ExcludeSemantics(
                              child: Column(
                                key: _amountKey,
                                children: [
                                  Text(
                                    '+${widget.moment.amount}',
                                    key: const ValueKey(
                                      'reward-confirmed-amount',
                                    ),
                                    style: type.h2.copyWith(
                                      fontSize: compact ? 32 : 40,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    t.rewardYeopjeonReceived,
                                    textAlign: TextAlign.center,
                                    style: type.bodySmall.copyWith(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            builder: (_, child) => Transform.scale(
                              scale: _phase == _RewardPhase.collection
                                  ? 1 +
                                        .025 *
                                            math.sin(
                                              math.pi *
                                                  (_collection.value / .15)
                                                      .clamp(0, 1),
                                            )
                                  : 1,
                              child: child,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      if (widget.moment.playMintVideo)
                        Center(
                          child: SizedBox.square(
                            key: const ValueKey('reward-mint-stage'),
                            dimension: stageSize,
                            child: ClipRRect(
                              borderRadius: SoriRadius.brMd,
                              child: ColoredBox(
                                // The original opaque stage is intentional in both themes.
                                color: const Color(0xFFFFFDFC),
                                child: ExcludeSemantics(
                                  child:
                                      _video != null &&
                                          _phase == _RewardPhase.video
                                      ? VideoPlayer(_video!)
                                      : Image.asset(
                                          CompanionArt.mintPoster,
                                          fit: BoxFit.contain,
                                          cacheWidth:
                                              (stageSize *
                                                      MediaQuery.devicePixelRatioOf(
                                                        context,
                                                      ))
                                                  .ceil(),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        AnimatedBuilder(
                          animation: _collection,
                          child: Image.asset(
                            SoriArtwork.yeopjeon,
                            height: 104,
                            cacheHeight:
                                (104 * MediaQuery.devicePixelRatioOf(context))
                                    .ceil(),
                            excludeFromSemantics: true,
                          ),
                          builder: (_, child) => Opacity(
                            opacity:
                                _phase == _RewardPhase.collection &&
                                    _collection.value >= .15 &&
                                    _collection.value < .65
                                ? 0
                                : 1,
                            child: child,
                          ),
                        ),
                      const SizedBox(height: Spacing.md),
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          _collection,
                          _walletAccent,
                        ]),
                        builder: (context, _) {
                          final landing = _phase == _RewardPhase.collection
                              ? math.sin(
                                  math.pi *
                                      ((_collection.value - .65) / .35).clamp(
                                        0,
                                        1,
                                      ),
                                )
                              : _phase == _RewardPhase.video
                              ? math.sin(math.pi * _walletAccent.value)
                              : 0.0;
                          return SoriRewardSurface(
                            key: _walletKey,
                            padding: const EdgeInsets.all(Spacing.sm + 4),
                            onTap: _openWallet,
                            semanticLabel: t.rewardViewWallet,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: SoriColors.gold.withValues(
                                  alpha: .15 * landing,
                                ),
                                borderRadius: SoriRadius.brMd,
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    SoriArtwork.yeopjeon,
                                    width: 28,
                                    height: 28,
                                    excludeFromSemantics: true,
                                    cacheWidth: (28 * media.devicePixelRatio)
                                        .ceil(),
                                  ),
                                  const SizedBox(width: Spacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.rewardConfirmedBalance(
                                            widget.moment.balance,
                                          ),
                                          key: const ValueKey(
                                            'reward-confirmed-balance',
                                          ),
                                          style: type.label.copyWith(
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (!compact) ...[
                                          const SizedBox(height: 2),
                                        ExcludeSemantics(
                                          child: Text(
                                            t.rewardViewWallet,
                                            style: type.bodySmall.copyWith(
                                              fontSize: 12,
                                              color: surfaces.textMuted,
                                            ),
                                          ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  if (_phase == _RewardPhase.collection)
                    AnimatedBuilder(
                      animation: _collection,
                      child: IgnorePointer(
                        key: const ValueKey('reward-flight-coin'),
                        child: ExcludeSemantics(
                          child: Image.asset(
                            SoriArtwork.yeopjeon,
                            width: 48,
                            height: 48,
                            cacheWidth:
                                (48 * MediaQuery.devicePixelRatioOf(context))
                                    .ceil(),
                          ),
                        ),
                      ),
                      builder: (_, child) {
                        final start = _centre(_amountKey);
                        final end = _centre(_walletKey);
                        final time = _collection.value;
                        if (start == null ||
                            end == null ||
                            time < .15 ||
                            time >= 1) {
                          return const SizedBox.shrink();
                        }
                        final f = Curves.easeInOutCubic.transform(
                          ((time - .15) / .5).clamp(0, 1),
                        );
                        final control = Offset(
                          math.min(bounds.maxWidth - 30, start.dx + 72),
                          (start.dy + end.dy) / 2,
                        );
                        final p =
                            start * ((1 - f) * (1 - f)) +
                            control * (2 * (1 - f) * f) +
                            end * (f * f);
                        return Positioned(
                          left: p.dx - 24,
                          top: p.dy - 24,
                          child: Opacity(
                            opacity: 1 - ((time - .65) / .35).clamp(0, 1),
                            child: child,
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _deadline?.cancel();
    _phase = _RewardPhase.settled;
    _releaseVideo();
    _visibility.disposeBinding();
    HapticService.preferencesChanged.removeListener(_preferencesChanged);
    LocalDataLifetime.changes.removeListener(_accountChanged);
    AudioPolicy.instance.removeListener(_audioChanged);
    _collection.dispose();
    _walletAccent.dispose();
    super.dispose();
  }
}
