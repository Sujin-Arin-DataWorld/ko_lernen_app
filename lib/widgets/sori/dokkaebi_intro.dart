import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/storage_service.dart';
import 'dokkaebi_flame_frame.dart';

import 'video_lease.dart';

/// Canonical, one-shot introduction. Only blue fire continues after the clip.
class DokkaebiIntro extends StatefulWidget {
  const DokkaebiIntro({super.key, this.onFinished, this.staticOnly = false});
  final VoidCallback? onFinished;
  final bool staticOnly;
  static const videoAsset = 'assets/video/character/dokkaebi_intro.mp4';
  static const finalAsset = 'assets/illustrations/dokkaebi_intro/final.webp';

  @override
  State<DokkaebiIntro> createState() => _DokkaebiIntroState();
}

class _DokkaebiIntroState extends State<DokkaebiIntro> {
  late final VideoLeaseEligibilityBinding _visibility;
  VideoLeaseRequest<VideoPlayerController>? _lease;
  VideoPlayerController? _video;
  bool _finished = false;
  bool _failed = false;
  bool _visible = true;

  bool get _reduced =>
      widget.staticOnly ||
      Storage.reducedMotion ||
      MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _visibility = VideoLeaseEligibilityBinding(onChanged: _sync);
    _lease = soriVideoLease.register(
      asset: DokkaebiIntro.videoAsset,
      eligible: false,
      prepare: (video) async {
        await video.setVolume(0);
        await video.setLooping(false);
        await video.setPlaybackSpeed(1.04);
      },
      onGranted: (video) {
        if (!mounted || _finished) {
          return;
        }
        setState(() => _video = video);
        video.addListener(_tick);
        unawaited(_play(video));
      },
      onRevoked: () {
        _video?.removeListener(_tick);
        _video = null;
        if (mounted) {
          setState(() {});
        }
      },
      onFailed: (_, _) {
        if (mounted) {
          setState(() => _failed = true);
          _finish();
        }
      },
    );
  }

  Future<void> _play(VideoPlayerController video) async {
    try {
      await video.play();
    } catch (_) {
      if (mounted) {
        setState(() => _failed = true);
        _finish();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visibility.attach(context);
    _sync();
  }

  @override
  void didUpdateWidget(covariant DokkaebiIntro oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (!mounted) {
      return;
    }
    final visible = _visibility.isVisible(context);
    if (_visible != visible) {
      setState(() => _visible = visible);
    }
    _lease?.setEligible(visible && !_reduced && !_finished && !_failed);
    if (_reduced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _finish();
        }
      });
    }
  }

  void _tick() {
    final value = _video?.value;
    if (value == null) {
      return;
    }
    if (value.hasError) {
      setState(() => _failed = true);
      _finish();
    } else if (value.isInitialized &&
        value.duration > Duration.zero &&
        value.position >= value.duration) {
      _finish();
    }
  }

  void _finish() {
    if (_finished) {
      return;
    }
    _video?.removeListener(_tick);
    _video = null;
    setState(() => _finished = true);
    final lease = _lease;
    _lease = null;
    if (lease != null) {
      unawaited(lease.release());
    }
    widget.onFinished?.call();
  }

  @override
  void dispose() {
    _video?.removeListener(_tick);
    _visibility.disposeBinding();
    final lease = _lease;
    if (lease != null) {
      unawaited(lease.release());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    return Semantics(
      label: AppL10n.of(context).cultureDokkaebiName,
      image: true,
      child: ExcludeSemantics(
        child: DokkaebiFlameFrame(
          animate: _visible && !_reduced,
          child: video != null && !_reduced && !_finished && !_failed
              ? FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: video.value.size.width,
                    height: video.value.size.height,
                    child: VideoPlayer(video),
                  ),
                )
              : Image.asset(
                  DokkaebiIntro.finalAsset,
                  fit: BoxFit.contain,
                  cacheWidth: 768,
                ),
        ),
      ),
    );
  }
}
