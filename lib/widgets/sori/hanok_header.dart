import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/sound_service.dart';
import 'hanok_tokens.dart';
import 'tiger_video.dart' show TigerStageVideo;
import 'tokens.dart' show SoriMotion;
import 'video_lease.dart';

/// **HanokHeader** — 모듈 상단 wide 한옥 일러스트 배너.
///
/// 10:3 가로 비율(`study_scholar.png`, `achievements.png` 등)을 위한 자리.
/// 이미지가 아직 없으면 단청 그라데이션 + 아이콘 fallback으로 자연스럽게 떨어진다.
///
/// **살아있는 헤더 (배치 계획 2026-07-29 §2-7)**: 같은 파일명 규칙의 앰비언트
/// 루프 영상(`assets/video/loops/<이름>.mp4`)이 존재하면 png 포스터 위로
/// 페이드인해 무음 루프 재생한다. 영상이 없거나(대부분의 헤더),
/// `!TigerStageVideo.videoReady`, reduce-motion이면 — 기존 정적 png 그대로.
/// 콜사이트 변경 0: `listening_hero.png` → `loops/listening_hero.mp4` 자동 유도.
///
/// ```dart
/// HanokHeader(asset: 'assets/illustrations/hanok/study_scholar.png',
///             fallbackIcon: Icons.tune)
/// ```
class HanokHeader extends StatelessWidget {
  final String asset;

  /// 자산 로드 실패 시 표시할 아이콘.
  final IconData fallbackIcon;

  /// 자산 로드 실패 시 그라데이션 톤. null이면 한옥 토큰 한지/단청.
  final Color? fallbackTint;

  /// 가로/세로 비율 — 기본 10:3 (1888×560 권장).
  final double aspectRatio;

  /// 상단 corner radius — 화면 최상단에 붙을 때는 0, 카드 안에 넣을 때는 16.
  final double radius;

  /// 루프 영상 자동 재생 여부 (영상이 존재할 때만 효과 있음).
  final bool animate;

  /// 루프 영상 경로 명시 오버라이드. null이면 png 파일명에서 유도.
  final String? loopAsset;

  const HanokHeader({
    super.key,
    required this.asset,
    this.fallbackIcon = Icons.image_outlined,
    this.fallbackTint,
    this.aspectRatio = 10 / 3,
    this.radius = 16,
    this.animate = true,
    this.loopAsset,
  });

  /// `assets/video/loops/` 에 **실제로 존재하는** 루프 파일 이름.
  ///
  /// [_derivedLoop] 이 png 이름으로 mp4 경로를 추측하기만 하고 존재 여부를
  /// 확인하지 않아서, 짝 없는 히어로 png마다 ExoPlayer를 하나씩 만들고
  /// `FileNotFoundException`으로 실패시키고 있었다(2026-07-31 logcat:
  /// `ExoPlaybackException: Source error … flutter_assets/assets/video/loops/
  /// calligraphy.mp4`). 실패해도 포스터가 남아 눈엔 안 보였지만 플레이어
  /// 인스턴스는 낭비됐다.
  ///
  /// ⚠️ `assets/video/loops/` 에 파일을 추가·삭제하면 **이 집합도 함께**
  /// 고쳐야 한다.
  static const Set<String> kLoopAssets = {
    'hanok_construction',
    'hanok_jongga',
    'kkeunmari_hero',
    'listening_hero',
    'porch',
    'scene_cafe',
    'scene_directions',
    'scene_hotel',
    'scene_market',
    'scene_restaurant',
    'study_classroom',
    'study_scholar',
    'welcome-hero',
  };

  /// 'assets/illustrations/hanok/listening_hero.png'
  ///   → 'assets/video/loops/listening_hero.mp4'
  ///
  /// 짝이 되는 루프가 [kLoopAssets] 에 없으면 **null** — 없는 파일로
  /// 플레이어를 만들지 않는다.
  String? get _derivedLoop {
    if (loopAsset != null) return loopAsset;
    final slash = asset.lastIndexOf('/');
    final dot = asset.lastIndexOf('.');
    if (slash < 0 || dot <= slash) return null;
    final name = asset.substring(slash + 1, dot);
    if (!kLoopAssets.contains(name)) return null;
    return 'assets/video/loops/$name.mp4';
  }

  @override
  Widget build(BuildContext context) {
    final tint = fallbackTint ?? HanokColors.cheong;
    final poster = Image.asset(
      asset,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => _Fallback(icon: fallbackIcon, tint: tint),
    );

    final loop = _derivedLoop;
    final live =
        animate &&
        loop != null &&
        TigerStageVideo.videoReady &&
        !SoriMotion.reduceMotion(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: live ? SoriPosterLoop(videoAsset: loop, poster: poster) : poster,
      ),
    );
  }
}

/// **SoriPosterLoop** — png 포스터 → (영상 준비되면) 무음 루프 크로스페이드.
///
/// 초기화 실패(영상 미존재 포함)는 조용히 포스터 유지 — 콜사이트마다 영상이
/// 있을 필요가 없다. [HanokHeader] 내부용이었다가 시나리오 인트로 아트·
/// 온보딩 프리뷰 등 임의 포스터 위 루프 승격에 재사용하도록 공개(2026-07-30).
///
/// ⚠️ 게이트 책임은 호출측: `TigerStageVideo.videoReady &&
/// !SoriMotion.reduceMotion(context)`일 때만 빌드할 것 — 이 위젯 자체는
/// 항상 컨트롤러를 초기화한다.
class SoriPosterLoop extends StatefulWidget {
  final String videoAsset;
  final Widget poster;

  /// 루프 음량. **기본 0(무음)이 의도된 값**이다 — 이 위젯은 화면 상단에
  /// 상시 떠 있는 배경 루프라, 소리를 켜면 발음 TTS와 계속 겹치고 한 화면에
  /// 여러 개가 뜨면 소리도 겹친다. 일회성 연출(대문 인트로 등)만 소리를 쓴다.
  /// 특정 콜사이트에서 앰비언스를 원하면 0.15~0.3 정도를 넘길 것.
  final double volume;

  const SoriPosterLoop({
    super.key,
    required this.videoAsset,
    required this.poster,
    this.volume = 0,
  });

  @override
  State<SoriPosterLoop> createState() => _SoriPosterLoopState();
}

class _SoriPosterLoopState extends State<SoriPosterLoop> {
  VideoPlayerController? _video;
  VideoLeaseRequest<VideoPlayerController>? _lease;
  late final VideoLeaseEligibilityBinding _eligibility;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _eligibility = VideoLeaseEligibilityBinding(onChanged: _syncEligibility);
    _lease = soriVideoLease.register(
      asset: widget.videoAsset,
      eligible: false,
      prepare: (video) async {
        await video.setVolume(SoundService.enabled ? widget.volume : 0);
        await video.setLooping(true);
      },
      onGranted: _onGranted,
      onRevoked: _onRevoked,
      onFailed: _onFailed,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _eligibility.attach(context);
    _syncEligibility();
  }

  void _syncEligibility() {
    if (!mounted) {
      return;
    }
    _lease?.setEligible(
      _eligibility.isEligible(context, videoReady: TigerStageVideo.videoReady),
    );
  }

  void _onGranted(VideoPlayerController video) {
    _video = video;
    if (mounted) {
      setState(() => _ready = true);
    }
    unawaited(video.play());
  }

  void _onRevoked() {
    _video = null;
    _ready = false;
    if (mounted) {
      setState(() {});
    }
  }

  void _onFailed(Object _, StackTrace __) {
    _video = null;
    _ready = false;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _eligibility.disposeBinding();
    final lease = _lease;
    _lease = null;
    if (lease != null) {
      unawaited(lease.release());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.poster,
        if (_ready && video != null)
          AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 400),
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: video.value.size.width,
                height: video.value.size.height,
                child: VideoPlayer(video),
              ),
            ),
          ),
      ],
    );
  }
}

class _Fallback extends StatelessWidget {
  final IconData icon;
  final Color tint;

  const _Fallback({required this.icon, required this.tint});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HanokColors.hanjiCream,
            Color.alphaBlend(
              tint.withValues(alpha: 0.16),
              HanokColors.hanjiCream,
            ),
          ],
        ),
      ),
      child: Center(
        child: Icon(icon, size: 48, color: tint.withValues(alpha: 0.55)),
      ),
    );
  }
}
