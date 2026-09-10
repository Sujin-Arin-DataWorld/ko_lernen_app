import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum OnboardingCharacterMotion { idle, select, confirm }

typedef OnboardingCharacterMediaFailure =
    void Function(Object error, StackTrace stackTrace);

/// Transparent, onboarding-only companion media.
///
/// The widget owns a single animated WebP codec. The bundled idle is a poster;
/// select and confirm play the authored choose gesture once and return to it.
/// An explicitly supplied idle animation may loop. Reduced motion,
/// a disabled [TickerMode], and a background app all
/// release the codec immediately.
class OnboardingCharacterMedia extends StatefulWidget {
  const OnboardingCharacterMedia({
    super.key,
    required this.characterId,
    this.motion = OnboardingCharacterMotion.idle,
    this.active = true,
    this.replayToken = 0,
    this.size = 320,
    this.posterAsset,
    this.animationAsset,
    this.fallback,
    this.onFailure,
  }) : assert(characterId == 'tiger' || characterId == 'magpie'),
       assert(size > 0);

  final String characterId;
  final OnboardingCharacterMotion motion;
  final bool active;
  final int replayToken;
  final double size;
  final String? posterAsset;
  final String? animationAsset;
  final Widget? fallback;
  final OnboardingCharacterMediaFailure? onFailure;

  String get resolvedPosterAsset {
    final stem = _characterStem(characterId);
    return posterAsset ??
        'assets/illustrations/onboarding/companions/${stem}_idle.png';
  }

  String get resolvedAnimationAsset {
    final stem = _characterStem(characterId);
    return animationAsset ??
        'assets/illustrations/onboarding/companions/${stem}_choose.webp';
  }

  static String _characterStem(String characterId) {
    return switch (characterId) {
      'tiger' => 'taego',
      'magpie' => 'joy',
      _ => throw ArgumentError.value(
        characterId,
        'characterId',
        "Expected 'tiger' or 'magpie'.",
      ),
    };
  }

  @override
  State<OnboardingCharacterMedia> createState() =>
      _OnboardingCharacterMediaState();
}

class _OnboardingCharacterMediaState extends State<OnboardingCharacterMedia>
    with WidgetsBindingObserver {
  ui.Codec? _codec;
  ui.Image? _frame;
  Timer? _frameTimer;
  ValueListenable<TickerModeData>? _tickerMode;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  String? _playingAsset;
  int _generation = 0;
  int _framesShown = 0;
  int _targetWidth = 1;
  bool _reduceMotion = false;
  bool _posterFailed = false;
  bool _oneShotCompleted = false;
  bool _animationFailed = false;
  final Set<String> _reportedFailures = <String>{};

  bool get _eligible =>
      widget.active &&
      (widget.motion != OnboardingCharacterMotion.idle ||
          widget.animationAsset != null) &&
      !_reduceMotion &&
      (_tickerMode?.value.enabled ?? true) &&
      _lifecycleState == AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tickerMode = TickerMode.getValuesNotifier(context);
    if (!identical(tickerMode, _tickerMode)) {
      _tickerMode?.removeListener(_handleEligibilityChanged);
      _tickerMode = tickerMode..addListener(_handleEligibilityChanged);
    }

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final physicalWidth = math.max(
      1,
      (widget.size * MediaQuery.devicePixelRatioOf(context)).ceil(),
    );
    final decodeSizeChanged = physicalWidth != _targetWidth;
    final motionPreferenceChanged = reduceMotion != _reduceMotion;
    _targetWidth = physicalWidth;
    _reduceMotion = reduceMotion;

    if (decodeSizeChanged || motionPreferenceChanged) {
      _restartPlayback(rebuild: false);
    } else {
      _syncPlayback(rebuild: false);
    }
  }

  @override
  void didUpdateWidget(covariant OnboardingCharacterMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    final posterChanged =
        oldWidget.characterId != widget.characterId ||
        oldWidget.posterAsset != widget.posterAsset;
    if (posterChanged) {
      _posterFailed = false;
    }

    final playbackChanged =
        oldWidget.characterId != widget.characterId ||
        oldWidget.motion != widget.motion ||
        oldWidget.animationAsset != widget.animationAsset ||
        oldWidget.replayToken != widget.replayToken ||
        oldWidget.size != widget.size;
    if (oldWidget.size != widget.size) {
      _targetWidth = math.max(
        1,
        (widget.size * MediaQuery.devicePixelRatioOf(context)).ceil(),
      );
    }
    if (playbackChanged) {
      _oneShotCompleted = false;
      _animationFailed = false;
      _restartPlayback(rebuild: false);
    } else {
      _syncPlayback(rebuild: false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_lifecycleState == state) {
      return;
    }
    _lifecycleState = state;
    _syncPlayback();
  }

  void _syncPlayback({bool rebuild = true}) {
    if (!_eligible) {
      _stopPlayback(rebuild: rebuild);
      return;
    }
    if (_animationFailed ||
        (widget.motion != OnboardingCharacterMotion.idle &&
            _oneShotCompleted)) {
      return;
    }
    if (_codec == null && _playingAsset == null) {
      unawaited(_startPlayback());
    }
  }

  void _handleEligibilityChanged() {
    _syncPlayback();
  }

  void _restartPlayback({bool rebuild = true}) {
    _stopPlayback(rebuild: rebuild);
    _syncPlayback(rebuild: rebuild);
  }

  Future<void> _startPlayback() async {
    if (!_eligible || !mounted) {
      return;
    }
    final generation = ++_generation;
    final asset = widget.resolvedAnimationAsset;
    final bundle = DefaultAssetBundle.of(context);
    _playingAsset = asset;

    try {
      final data = await bundle.load(asset);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        targetWidth: _targetWidth,
        allowUpscaling: false,
      );
      if (!_isCurrent(generation, asset)) {
        codec.dispose();
        return;
      }
      _codec = codec;
      _framesShown = 0;
      await _decodeNextFrame(generation, asset);
    } catch (error, stackTrace) {
      if (_isCurrent(generation, asset)) {
        _animationFailed = true;
        _reportFailure(asset, error, stackTrace);
        _stopPlayback();
      }
    }
  }

  Future<void> _decodeNextFrame(int generation, String asset) async {
    final codec = _codec;
    if (codec == null || !_isCurrent(generation, asset)) {
      return;
    }

    try {
      final frameInfo = await codec.getNextFrame();
      final displayFrame = await _fitFrameToTarget(frameInfo.image);
      if (!_isCurrent(generation, asset) || !identical(codec, _codec)) {
        displayFrame.dispose();
        return;
      }

      final oldFrame = _frame;
      setState(() {
        _frame = displayFrame;
        _framesShown += 1;
      });
      oldFrame?.dispose();

      final oneShotComplete =
          widget.motion != OnboardingCharacterMotion.idle &&
          _framesShown >= codec.frameCount;
      if (codec.frameCount <= 1 && !oneShotComplete) {
        codec.dispose();
        _codec = null;
        return;
      }

      final duration = frameInfo.duration <= Duration.zero
          ? const Duration(milliseconds: 100)
          : frameInfo.duration;
      _frameTimer = Timer(duration, () {
        if (oneShotComplete) {
          _oneShotCompleted = true;
          _stopPlayback();
        } else {
          unawaited(_decodeNextFrame(generation, asset));
        }
      });
    } catch (error, stackTrace) {
      if (_isCurrent(generation, asset)) {
        _animationFailed = true;
        _reportFailure(asset, error, stackTrace);
        _stopPlayback();
      }
    }
  }

  Future<ui.Image> _fitFrameToTarget(ui.Image decoded) async {
    final longestSide = math.max(decoded.width, decoded.height);
    if (longestSide <= _targetWidth) {
      return decoded;
    }

    final scale = _targetWidth / longestSide;
    final targetWidth = math.max(1, (decoded.width * scale).round());
    final targetHeight = math.max(1, (decoded.height * scale).round());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      decoded,
      Rect.fromLTWH(0, 0, decoded.width.toDouble(), decoded.height.toDouble()),
      Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
      Paint()..filterQuality = FilterQuality.medium,
    );
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(targetWidth, targetHeight);
    } finally {
      picture.dispose();
      decoded.dispose();
    }
  }

  bool _isCurrent(int generation, String asset) {
    return mounted &&
        _eligible &&
        generation == _generation &&
        _playingAsset == asset &&
        widget.resolvedAnimationAsset == asset;
  }

  void _stopPlayback({bool rebuild = true}) {
    _generation += 1;
    _frameTimer?.cancel();
    _frameTimer = null;
    _codec?.dispose();
    _codec = null;
    _playingAsset = null;
    _framesShown = 0;
    final oldFrame = _frame;
    if (oldFrame != null) {
      if (mounted && rebuild) {
        setState(() {
          _frame = null;
        });
      } else {
        _frame = null;
      }
      oldFrame.dispose();
    }
  }

  void _reportFailure(String asset, Object error, StackTrace stackTrace) {
    if (_reportedFailures.add(asset)) {
      widget.onFailure?.call(error, stackTrace);
    }
  }

  Widget _buildFallback() {
    return widget.fallback ??
        const Center(
          child: Icon(
            Icons.pets_outlined,
            key: ValueKey('onboarding-character-neutral-fallback'),
            size: 56,
          ),
        );
  }

  Widget _buildPoster() {
    if (_posterFailed) {
      return _buildFallback();
    }
    final asset = widget.resolvedPosterAsset;
    return Image(
      image: ResizeImage(
        AssetImage(asset),
        width: _targetWidth,
        height: _targetWidth,
        policy: ResizeImagePolicy.fit,
      ),
      key: ValueKey('onboarding-character-poster-$asset'),
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        _reportFailure(asset, error, stackTrace ?? StackTrace.current);
        if (!_posterFailed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_posterFailed) {
              setState(() {
                _posterFailed = true;
              });
            }
          });
        }
        return _buildFallback();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final frame = _frame;
    return SizedBox.square(
      dimension: widget.size,
      child: frame == null
          ? _buildPoster()
          : RawImage(
              key: ValueKey('onboarding-character-animation-$_playingAsset'),
              image: frame,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
    );
  }

  @override
  void dispose() {
    _tickerMode?.removeListener(_handleEligibilityChanged);
    _tickerMode = null;
    WidgetsBinding.instance.removeObserver(this);
    _stopPlayback(rebuild: false);
    super.dispose();
  }
}
