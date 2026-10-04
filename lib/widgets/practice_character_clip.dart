import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/haptic_service.dart';
import '../services/storage_service.dart';
import 'sori/tiger_video.dart';
import 'sori/video_lease.dart';

/// Silent, one-shot explanation gesture. Text never depends on playback.
/// Uses the app's shared native lease and keeps a matching full-body poster.
class PracticeCharacterClip extends StatefulWidget {
  const PracticeCharacterClip({
    super.key,
    this.play = false,
    this.explaining = false,
    this.onRequested,
    this.onFinished,
    required this.videoAsset,
    required this.startAsset,
    required this.endAsset,
    this.impactAt,
    this.onImpact,
  });

  final String videoAsset, startAsset, endAsset;
  final Duration? impactAt;
  final VoidCallback? onImpact;
  final bool play;
  final bool explaining;
  final VoidCallback? onRequested;
  final VoidCallback? onFinished;

  @override
  State<PracticeCharacterClip> createState() => _PracticeCharacterClipState();
}

class _PracticeCharacterClipState extends State<PracticeCharacterClip> {
  VideoPlayerController? _video;
  VideoLeaseRequest<VideoPlayerController>? _lease;
  late final VideoLeaseEligibilityBinding _eligibility;
  late final OneShotVideoLeaseCompletion _completion;
  bool _finished = false;
  bool _impacted = false;
  bool _videoVisible = false;
  bool _postersCached = false;
  Timer? _impactTimer;
  Timer? _frameReadyTimer;
  late final bool _requested;

  bool get _unavailable =>
      Storage.reducedMotion ||
      MediaQuery.disableAnimationsOf(context) ||
      !TigerStageVideo.videoReady ||
      Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _requested = widget.play;
    if (_requested) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onRequested?.call();
        }
      });
    }
    _eligibility = VideoLeaseEligibilityBinding(onChanged: _sync);
    _completion = OneShotVideoLeaseCompletion(
      fallbackCompleteAfter: const Duration(seconds: 4),
      onRelease: _retire,
    );
    HapticService.preferencesChanged.addListener(_preferencesChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested && !_postersCached) {
      _postersCached = true;
      unawaited(precacheImage(AssetImage(widget.startAsset), context));
      unawaited(precacheImage(AssetImage(widget.endAsset), context));
    }
    _eligibility.attach(context);
    _sync();
  }

  void _preferencesChanged() {
    if (!mounted) {
      return;
    }
    _sync();
    setState(() {});
  }

  void _sync() {
    if (!mounted || !_requested || _finished) {
      return;
    }
    final visible = _eligibility.isVisible(context);
    _completion.visibilityChanged(visible);
    if (_unavailable || !visible) {
      unawaited(_completion.naturalCompletion());
      return;
    }
    _lease ??= soriVideoLease.register(
      asset: widget.videoAsset,
      eligible: false,
      prepare: (video) async {
        // audio-policy: exempt — approved character gesture is always silent.
        await video.setVolume(0);
        await video.setLooping(false);
      },
      onGranted: _granted,
      onRevoked: _revoked,
      onFailed: (_, __) => unawaited(_completion.naturalCompletion()),
    );
    _completion.leaseRequested();
    _lease?.setEligible(_eligibility.isEligible(context, videoReady: true));
  }

  void _granted(VideoPlayerController video) {
    _video = video;
    _completion.leaseGranted();
    video.addListener(_tick);
    if (mounted) {
      setState(() {});
    }
    unawaited(_play(video));
  }

  Future<void> _play(VideoPlayerController video) async {
    try {
      // Mount the native surface behind its matching poster before playback.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || _finished || !identical(video, _video)) {
        return;
      }
      await video.play();
      unawaited(_waitForFrame(video));
      // Anchor to native playback, rather than coarse position polling.
      if (mounted &&
          !_finished &&
          identical(video, _video) &&
          widget.impactAt != null) {
        _impactTimer = Timer(widget.impactAt!, _impact);
      }
    } catch (_) {
      await _completion.naturalCompletion();
    }
  }

  Future<void> _waitForFrame(VideoPlayerController video) async {
    if (!mounted || _finished || _videoVisible || !identical(video, _video)) {
      return;
    }
    try {
      // play() can resolve before the native decoder has its first frame.
      // Keep the matching poster over it until actual playback time advances.
      final position = await video.position;
      if (!mounted || _finished || _videoVisible || !identical(video, _video)) {
        return;
      }
      if (position != null &&
          position > Duration.zero &&
          video.value.isPlaying &&
          !video.value.isBuffering) {
        setState(() => _videoVisible = true);
      } else {
        _frameReadyTimer = Timer(
          const Duration(milliseconds: 50),
          () => unawaited(_waitForFrame(video)),
        );
      }
    } catch (_) {
      await _completion.naturalCompletion();
    }
  }

  void _impact() {
    if (!mounted ||
        _finished ||
        _impacted ||
        _unavailable ||
        !(_video?.value.isPlaying ?? false) ||
        (_video?.value.isBuffering ?? false) ||
        !_eligibility.isVisible(context)) {
      return;
    }
    _impacted = true;
    _impactTimer?.cancel();
    widget.onImpact?.call();
  }

  void _tick() {
    final value = _video?.value;
    if (value == null) {
      return;
    }
    if (value.hasError) {
      unawaited(_completion.naturalCompletion());
      return;
    }
    if (widget.impactAt != null && value.position >= widget.impactAt!) {
      _impact();
    }
    if (value.isCompleted) {
      unawaited(_completion.naturalCompletion());
      return;
    }
    _completion.completeFromPlayback(
      isInitialized: value.isInitialized,
      duration: value.duration,
      isPlaying: value.isPlaying,
      position: value.position,
    );
  }

  void _revoked() {
    _impactTimer?.cancel();
    _frameReadyTimer?.cancel();
    _video?.removeListener(_tick);
    _video = null;
    // A route/lease handoff stops the gesture instead of replaying it later.
    if (!_finished) {
      unawaited(_completion.naturalCompletion());
    }
  }

  Future<void> _retire() async {
    _finished = true;
    _impactTimer?.cancel();
    _frameReadyTimer?.cancel();
    _video?.removeListener(_tick);
    _video = null;
    final lease = _lease;
    _lease = null;
    if (mounted) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onFinished?.call();
        }
      });
    }
    await lease?.release();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            if (video != null && !_unavailable && !_finished)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: video.value.size.width,
                    height: video.value.size.height,
                    child: VideoPlayer(video),
                  ),
                ),
              ),
            // Native web video surfaces can paint an opaque empty frame while
            // decoding. Paint the poster above the mounted surface, then fade
            // only the poster once playback advances; hiding the surface itself
            // delays its first paint and leaves a gap during a cold start.
            AnimatedOpacity(
              opacity: video != null && _videoVisible && !_finished ? 0 : 1,
              duration: _unavailable || _finished
                  ? Duration.zero
                  : const Duration(milliseconds: 150),
              child: Image.asset(
                widget.explaining && (_finished || _unavailable || !_requested)
                    ? widget.endAsset
                    : widget.startAsset,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _impactTimer?.cancel();
    _frameReadyTimer?.cancel();
    HapticService.preferencesChanged.removeListener(_preferencesChanged);
    _eligibility.disposeBinding();
    _completion.dispose();
    _video?.removeListener(_tick);
    unawaited(_lease?.release());
    super.dispose();
  }
}
