import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/audio_policy.dart';
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

  /// 포스터·영상 BoxFit. 기본 cover(꽉 채움·크롭 가능). contain 이면 크롭 없이
  /// 전부 보인다(듀오 히어로처럼 잘리면 안 되는 자산용).
  final BoxFit fit;

  const HanokHeader({
    super.key,
    required this.asset,
    this.fallbackIcon = Icons.image_outlined,
    this.fallbackTint,
    this.aspectRatio = 10 / 3,
    this.radius = 16,
    this.animate = true,
    this.loopAsset,
    this.fit = BoxFit.cover,
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
    'taego-joy-duo',
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
    final loop = _derivedLoop;
    final live =
        animate &&
        loop != null &&
        TigerStageVideo.videoReady &&
        !SoriMotion.reduceMotion(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 이 배너는 **장식**이다. 10:3 이라 높이가 폭을 따라가는데, 세로가 짧은
        // 뷰포트(가로 폰·분할 화면·넓고 낮은 창)에서는 그 높이가 화면의 30~40%
        // 를 먹고 학습 카드·정답 버튼을 밀어내 오버플로를 만든다.
        //
        // 접을지 말지는 **자기 높이가 화면에서 차지하는 비율**로 정한다.
        // `높이 < 640` 같은 순수 절대 규칙은 360×640 짜리 흔한 세로 폰에서도
        // 배너를 지워 실기기 디자인을 바꾼다.
        //
        //   360×640 세로 폰    108/640  = 17%  → 유지
        //   360×400 분할 화면  108/400  = 27%  → 접음
        //   800×600 낮은 창    193/600  = 32%  → 접음
        //   800×1280 태블릿    193/1280 = 15%  → 유지
        //
        // 다만 비율만으로는 **가로 태블릿(1280×800)** 까지 걸린다: 배너 182/800
        // = 22.8% 로 임계값을 6px 차이로 넘겨 멀쩡한 화면의 배너가 사라졌다
        // (골든 3장이 잡았다 — learn_hub·settings·vocab_packs @ expanded).
        // 그래서 비율 판정은 **애초에 세로가 짧을 때만** 묻는다. 800dp 넘게
        // 높은 창은 배너가 몇 %든 콘텐츠가 들어갈 자리가 남는다.
        //
        // [_askBelowHeight] 는 "짧다"의 정의가 아니라 **질문을 할 구간**이다.
        // 실제 판정은 여전히 비율이 한다 — 그래서 360×640 세로 폰은 이 구간에
        // 들어오고도(640 < 700) 17% 라서 배너를 지킨다.
        //
        // 정보가 없는 요소부터 버리는 게 순서다 — 콘텐츠는 건드리지 않는다.
        final viewportHeight = MediaQuery.sizeOf(context).height;
        final width = constraints.maxWidth;
        if (width.isFinite &&
            viewportHeight > 0 &&
            viewportHeight < _askBelowHeight) {
          final bannerHeight = width / aspectRatio;
          if (bannerHeight > viewportHeight * _maxViewportShare) {
            return const SizedBox.shrink();
          }
        }

        // 포스터는 표시 폭에 맞춰 디코드(cacheWidth)해 1200px+ PNG 를 배너
        // 실제 폭으로만 디코드한다 — 시각 동일, 디코드 메모리·시간 절감.
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final poster = Image.asset(
          asset,
          fit: fit,
          cacheWidth: width.isFinite && width > 0
              ? (width * dpr).round()
              : null,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) =>
              _Fallback(icon: fallbackIcon, tint: tint),
        );

        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: live
                ? SoriPosterLoop(videoAsset: loop, poster: poster, fit: fit)
                : poster,
          ),
        );
      },
    );
  }

  /// 장식 배너가 차지해도 되는 화면 높이의 최대 비율.
  static const double _maxViewportShare = 0.22;

  /// 이 높이 **미만**일 때만 비율 판정을 한다. 가로로 든 폰(≈360–430)과 분할
  /// 화면은 전부 아래, 세로 폰(640~)·세로 태블릿(1024~)·가로 태블릿(720~800)
  /// 은 위다 — 즉 실기기 세로 화면의 배너는 이 게이트에서 이미 안전하다.
  static const double _askBelowHeight = 700;
}

/// **SoriPosterLoop** — png 포스터 → (영상 준비되면) 영상 크로스페이드.
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

  /// 포스터·영상 BoxFit — [HanokHeader.fit] 을 그대로 전달받는다(기본 cover).
  final BoxFit fit;

  /// `true`면 기존 앰비언트 헤더처럼 반복하고, `false`면 한 번 재생한 뒤
  /// 마지막 프레임을 유지한다. 시작/끝 구도가 다른 건축 성장 영상은 반복 시
  /// 완성 한옥이 빈 마당으로 튀므로 반드시 원샷으로 사용한다.
  final bool loop;

  /// 루프 음량은 **파라미터로 받지 않는다.** [AudioPolicy] 가 단일 진실원천이다
  /// (ADR-002 §3-2) — `SoundChannel.ambience` 의 on/off·볼륨·에셋별 정규화
  /// 게인·TTS 더킹이 전부 `volumeFor()` 한 곳에서 결정된다.
  ///
  /// 채널 기본값이 off 라, 사용자가 설정에서 켜기 전까지는 종전과 동일하게 무음이다.
  /// 콜사이트가 볼륨을 넘겨 정책을 우회하던 구조를 제거한 것이다(2026-08-02).
  const SoriPosterLoop({
    super.key,
    required this.videoAsset,
    required this.poster,
    this.fit = BoxFit.cover,
    this.loop = true,
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
    // 설정에서 앰비언스를 켜고 끄거나 볼륨을 움직이면 살아 있는 컨트롤러에
    // 즉시 반영된다. TTS 더킹도 같은 통지를 타고 온다.
    AudioPolicy.instance.addListener(_applyVolume);
    _lease = soriVideoLease.register(
      asset: widget.videoAsset,
      eligible: false,
      prepare: (video) async {
        await video.setVolume(_ambienceVolume());
        await video.setLooping(widget.loop);
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

  /// 이 루프의 최종 음량 — 마스터·채널 on/off, 채널 볼륨, 에셋별 정규화 게인,
  /// TTS 더킹이 전부 반영된 값. 꺼져 있으면 정확히 0.0 이다.
  double _ambienceVolume() => AudioPolicy.instance.volumeFor(
    SoundChannel.ambience,
    asset: widget.videoAsset,
  );

  /// [AudioPolicy] 통지 → 재생 중인 컨트롤러에 즉시 반영.
  void _applyVolume() {
    final video = _video;
    if (video == null) {
      return;
    }
    unawaited(video.setVolume(_ambienceVolume()));
  }

  void _onGranted(VideoPlayerController video) {
    _video = video;
    // prepare 이후 lease 승인 사이에 설정이 바뀌었을 수 있다.
    unawaited(video.setVolume(_ambienceVolume()));
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
    AudioPolicy.instance.removeListener(_applyVolume);
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
    final showVideo = _ready && video != null;
    return Stack(
      fit: StackFit.expand,
      children: [
        // 영상이 준비되면 포스터를 내린다. 영상(welcome_hero2)과 포스터
        // (welcome-hero.png)는 프레이밍이 달라, contain 슬롯(레벨 화면 히어로)
        // 에서 둘을 겹치면 포스터 호랑이가 영상 위/옆으로 삐져나와 "작은 호랑이"
        // 가 겹쳐 보였다(Jin 2026-08-05). 준비 전에는 포스터가 자리를 지킨다.
        // cover 슬롯(HanokHeader 배너)에서는 포스터가 어차피 완전히 가려져
        // 있었으므로 시각 변화 없음.
        if (!showVideo) widget.poster,
        if (showVideo)
          FittedBox(
            fit: widget.fit,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: video.value.size.width,
              height: video.value.size.height,
              child: VideoPlayer(video),
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
