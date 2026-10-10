import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../services/audio_policy.dart';
import '../../services/account/cloud_write_session.dart';
import '../../services/haptic_service.dart';
import '../../services/local_data_lifetime.dart';
import '../../services/storage_service.dart';
import 'video_lease.dart';

/// All frames of the approved alpha movie, decoded portably by Flutter.
/// No AVPlayer/WebM assumption, native video controller or grant callback.
class DokkaebiRewardMovie extends StatefulWidget {
  const DokkaebiRewardMovie({
    super.key,
    required this.size,
    required this.onCreditCue,
    required this.onSettled,
    required this.onPlaybackChanged,
    this.enabled = true,
    this.asset = 'assets/animations/rewards/making_money.webp',
  });

  final double size;
  final VoidCallback onCreditCue, onSettled, onPlaybackChanged;
  final bool enabled;
  final String asset;

  static const cue = Duration(milliseconds: 3583);
  static const startPoster = 'assets/animations/rewards/making_money_start.png';
  static const endPoster = 'assets/animations/rewards/making_money_end.png';

  @override
  State<DokkaebiRewardMovie> createState() => DokkaebiRewardMovieState();
}

class DokkaebiRewardMovieState extends State<DokkaebiRewardMovie> {
  final _lifetime = LocalDataLifetime.capture();
  final _identity = cloudWriteSessionController.identityEpoch;
  late final _eligibility = VideoLeaseEligibilityBinding(onChanged: _policy);
  ui.Codec? _codec;
  ui.Image? _frame;
  Timer? _nextFrame, _watchdog;
  AudioPlayer? _audio;
  int _generation = 0, _frames = 0;
  Duration _position = Duration.zero;
  bool _started = false, _settled = false, _cueSent = false;
  bool _sound = false, _disposed = false;

  bool get playing => _started && !_settled;
  bool get soundEnabled => _sound;
  bool get _allowed =>
      mounted &&
      _lifetime.isCurrent &&
      _identity == cloudWriteSessionController.identityEpoch &&
      widget.enabled &&
      !Storage.reducedMotion &&
      !MediaQuery.disableAnimationsOf(context) &&
      _eligibility.isVisible(context);

  @override
  void initState() {
    super.initState();
    HapticService.preferencesChanged.addListener(_policy);
    AudioPolicy.instance.addListener(_audioPolicy);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _eligibility.attach(context);
    _policy();
  }

  @override
  void didUpdateWidget(DokkaebiRewardMovie oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) {
      settle();
    }
    _policy();
  }

  void _notify(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _lifetime.isCurrent) {
        callback();
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _policy() {
    if (!mounted || _disposed) {
      return;
    }
    if (!_allowed) {
      settle();
    } else if (!_started && !_settled) {
      unawaited(_start());
    }
  }

  bool _current(int generation) =>
      !_disposed && _allowed && generation == _generation && !_settled;

  void _releaseStale() {
    if (!_lifetime.isCurrent ||
        _identity != cloudWriteSessionController.identityEpoch) {
      settle();
    }
  }

  Future<void> _start() async {
    if (!_allowed || playing) {
      return;
    }
    final generation = ++_generation;
    _started = true;
    _settled = false;
    _frames = 0;
    _position = Duration.zero;
    _notify(widget.onPlaybackChanged);
    _watchdog = Timer(const Duration(seconds: 9), settle);
    try {
      final data = await DefaultAssetBundle.of(context).load(widget.asset);
      if (!_current(generation)) {
        _releaseStale();
        return;
      }
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        targetWidth: _decodeSize,
        allowUpscaling: false,
      );
      if (!_current(generation)) {
        codec.dispose();
        _releaseStale();
        return;
      }
      _codec = codec;
      await _decode(generation);
    } catch (_) {
      if (_current(generation)) {
        settle();
      }
    }
  }

  int get _decodeSize => math.min(
    960,
    math.max(1, (widget.size * MediaQuery.devicePixelRatioOf(context)).ceil()),
  );

  Future<void> _decode(int generation) async {
    final codec = _codec;
    if (codec == null || !_current(generation)) {
      _releaseStale();
      return;
    }
    try {
      final frame = await codec.getNextFrame();
      if (!_current(generation)) {
        frame.image.dispose();
        _releaseStale();
        return;
      }
      // Retain one source frame (at most 960²), and scale it on the GPU once.
      // A per-frame Picture.toImage round trip adds latency on mobile/web.
      final image = frame.image;
      if (!_current(generation) || !identical(codec, _codec)) {
        image.dispose();
        _releaseStale();
        return;
      }
      final previous = _frame;
      setState(() => _frame = image);
      previous?.dispose();
      _frames++;
      // A stalled decode may fall back, but a slow device making progress must
      // not lose the end of the original performance to a total-time deadline.
      _watchdog?.cancel();
      _watchdog = Timer(const Duration(seconds: 9), settle);
      final duration = frame.duration > Duration.zero
          ? frame.duration
          : const Duration(microseconds: 41667);
      if (!_cueSent && _position >= DokkaebiRewardMovie.cue) {
        _cueSent = true;
        widget.onCreditCue();
      }
      _nextFrame = Timer(duration, () {
        _position += duration;
        if (_frames >= codec.frameCount) {
          settle();
        } else {
          unawaited(_decode(generation));
        }
      });
    } catch (_) {
      if (_current(generation)) {
        settle();
      }
    }
  }

  void settle() {
    if (_disposed || _settled) {
      return;
    }
    _settled = true;
    _release();
    if (mounted) {
      setState(() {});
      _notify(widget.onSettled);
      _notify(widget.onPlaybackChanged);
    }
  }

  void replay() {
    if (!_allowed || playing) {
      return;
    }
    // The cue stays consumed across replay. Only the movie restarts.
    _started = false;
    _settled = false;
    unawaited(_start());
  }

  Future<void> toggleSound() async {
    if (!playing || !_allowed) {
      return;
    }
    _sound = !_sound;
    _notify(widget.onPlaybackChanged);
    if (!_sound) {
      await _stopAudio();
      return;
    }
    final generation = _generation;
    final policy = AudioPolicy.instance;
    final volume = policy.volumeFor(
      SoundChannel.companion,
      asset: 'animations/rewards/making_money.mp3',
    );
    if (volume <= 0) {
      return;
    }
    final player = AudioPlayer();
    _audio = player;
    try {
      await player.setReleaseMode(ReleaseMode.stop);
      await player.play(
        AssetSource('animations/rewards/making_money.mp3'),
        volume: volume,
        position: _position,
      );
      if (!_current(generation) || !_sound || !identical(player, _audio)) {
        await player.dispose();
      }
    } catch (_) {
      if (identical(player, _audio)) {
        _audio = null;
      }
      await player.dispose();
    }
  }

  void _audioPolicy() {
    final player = _audio;
    if (player == null) {
      return;
    }
    final volume = AudioPolicy.instance.volumeFor(
      SoundChannel.companion,
      asset: 'animations/rewards/making_money.mp3',
    );
    if (volume <= 0 || !_allowed) {
      unawaited(_stopAudio());
    } else {
      unawaited(player.setVolume(volume));
    }
  }

  Future<void> _stopAudio() async {
    final audio = _audio;
    _audio = null;
    if (audio != null) {
      try {
        await audio.dispose();
      } catch (_) {
        // Visual completion is independent of the optional audio backend.
      }
    }
  }

  void _release() {
    _generation++;
    _sound = false;
    _nextFrame?.cancel();
    _watchdog?.cancel();
    _nextFrame = null;
    _watchdog = null;
    _codec?.dispose();
    _codec = null;
    _frame?.dispose();
    _frame = null;
    unawaited(_stopAudio());
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: SizedBox.square(
        key: const ValueKey('reward-movie-full-frame'),
        dimension: widget.size,
        child: _frame == null
            ? Image.asset(
                _settled
                    ? DokkaebiRewardMovie.endPoster
                    : DokkaebiRewardMovie.startPoster,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              )
            : RawImage(
                image: _frame,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
      ),
    ),
  );

  @override
  void dispose() {
    _disposed = true;
    _release();
    _eligibility.disposeBinding();
    HapticService.preferencesChanged.removeListener(_policy);
    AudioPolicy.instance.removeListener(_audioPolicy);
    super.dispose();
  }
}
