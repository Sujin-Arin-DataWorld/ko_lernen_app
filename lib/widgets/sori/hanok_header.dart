import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'hanok_tokens.dart';
import 'tiger_video.dart' show TigerStageVideo;
import 'tokens.dart' show SoriMotion;

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

  /// 'assets/illustrations/hanok/listening_hero.png'
  ///   → 'assets/video/loops/listening_hero.mp4'
  String? get _derivedLoop {
    if (loopAsset != null) return loopAsset;
    final slash = asset.lastIndexOf('/');
    final dot = asset.lastIndexOf('.');
    if (slash < 0 || dot <= slash) return null;
    final name = asset.substring(slash + 1, dot);
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
    final live = animate &&
        loop != null &&
        TigerStageVideo.videoReady &&
        !SoriMotion.reduceMotion(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: live ? _HeaderLoop(videoAsset: loop, poster: poster) : poster,
      ),
    );
  }
}

/// png 포스터 → (영상 준비되면) 무음 루프 크로스페이드.
/// 초기화 실패(영상 미존재 포함)는 조용히 포스터 유지 — 헤더마다 영상이
/// 있을 필요가 없다.
class _HeaderLoop extends StatefulWidget {
  final String videoAsset;
  final Widget poster;

  const _HeaderLoop({required this.videoAsset, required this.poster});

  @override
  State<_HeaderLoop> createState() => _HeaderLoopState();
}

class _HeaderLoopState extends State<_HeaderLoop> {
  VideoPlayerController? _video;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final video = VideoPlayerController.asset(widget.videoAsset);
    _video = video;
    try {
      await video.initialize();
      await video.setVolume(0);
      await video.setLooping(true);
    } catch (_) {
      // 영상 없음/실패 — 포스터 유지.
      return;
    }
    if (!mounted) return;
    setState(() => _ready = true);
    await video.play();
  }

  @override
  void dispose() {
    _video?.dispose();
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
