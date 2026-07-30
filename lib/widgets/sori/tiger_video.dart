import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'mascot.dart';
import 'tiger_stage_rive.dart';
import 'tokens.dart';

/// **살아있는 호랑이 — 영상 버전** (Jin 제작 mp4, 2026-06-12).
///
/// 프레임 PNG 시퀀스([TigerStage])의 "전환 끊김"을 해소하는 부드러운 영상 경로.
/// H.264라 알파가 없고 배경이 흰색(~#F0F4F2)으로 박혀 있다 → [ColorFiltered]
/// `BlendMode.multiply`로 흰 배경을 크림 배경색에 흡수시킨다 (흰색×크림=크림,
/// 호랑이는 미세하게 따뜻해짐). multiply 결과는 child×색 고정값이라 밝은 배경
/// 전용 — 앱이 라이트 전용(`themeMode.light`)이라 항상 성립한다.
///
/// ⚠️ 캔버스 `saveLayer` 블렌드는 비디오가 `Texture` 엔진 레이어로 합성돼
/// 적용되지 않음 — 반드시 컴포지터 레이어인 [ColorFiltered]를 쓸 것.
///
/// 폴백 체인: !videoReady ‖ reduce-motion ‖ 로드 실패
///   → [TigerStageRive] (→ .riv 미존재 시 프레임 [TigerStage]).

/// 홈 히어로 밴드용 — 인사(launch당 1회) → 왔다갔다 루프. 항상 무음.
class TigerStageVideo extends StatefulWidget {
  /// 밴드 높이(px). 영상(1:1)은 높이 기준 정사각으로 중앙 배치.
  final double height;

  /// 폴백 [TigerStageRive]/[TigerStage]에 넘길 표정.
  final MascotEmotion fallbackEmotion;

  /// multiply 블렌드 색 — 영상 흰 배경이 이 색이 된다. 밴드 뒤 실제 배경
  /// (홈 크림 그라데이션 중간값)에 맞춘 튜닝 노브. 실기기에서 박스 경계가
  /// 보이면 이 값을 현지 배경에 더 가깝게 조정.
  final Color blendColor;

  const TigerStageVideo({
    super.key,
    this.height = 168,
    this.fallbackEmotion = MascotEmotion.smile,
    this.blendColor = const Color(0xFFF8F2E4),
  });

  /// main()에서만 true. 테스트/미배선 환경은 false → 프레임 폴백
  /// ([TigerStageRive.riveReady] 패턴 — 테스트가 플러그인 채널에 의존 안 함).
  static bool videoReady = false;

  /// 영상 소스가 **알파(투명) 채널**을 가지는가.
  ///
  /// - `false`(기본, 현재 H.264 mp4): 배경이 불투명 회색이라 흰→크림 multiply +
  ///   초상 액자(#3)로 감싸 "의도된 초상"으로 보이게 한다.
  /// - `true`(Jin이 알파 재출력 후 main.dart에서 세팅): multiply·액자 없이 raw
  ///   렌더 → 배경이 그대로 투명해 홈 크림 배경과 edge-to-edge 블렌드(#2).
  ///   ⚠️ Flutter `video_player`의 알파 합성은 기기/코덱별이라 실기기 검증 후 켤 것.
  static bool hasAlpha = false;

  // 2026-07-29 배치: 캐논 호랑이(엎드린 휴식 모델) 클립으로 교체.
  // greet = 엎드림→기상 인사(1회), pace = 엎드려 쉬는 아이들 루프.
  // 구 tiger_greet/tiger_pace.mp4는 assets_unused/video/로 이동(2026-07-30) —
  // 롤백하려면 git mv로 assets/video/에 복원 후 아래 상수만 되돌리면 된다.
  static const String greetAsset = 'assets/video/character/tiger_rise.mp4';
  static const String paceAsset = 'assets/video/character/tiger_rest.mp4';

  @override
  State<TigerStageVideo> createState() => _TigerStageVideoState();
}

class _TigerStageVideoState extends State<TigerStageVideo>
    with WidgetsBindingObserver {
  /// 인사는 앱 launch당 1회 ([TigerStage]의 `_introPlayedThisLaunch` 패턴).
  static bool _greetPlayedThisLaunch = false;

  VideoPlayerController? _greet;
  VideoPlayerController? _pace;

  bool _initStarted = false;
  bool _ready = false; // 두 컨트롤러 initialize 완료
  bool _failed = false;
  bool _showPace = false;
  bool _greetStarted = false;
  bool _appPaused = false;

  ValueListenable<TickerModeData>? _tickerMode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 탭 비가시(IndexedStack TickerMode off) 시 디코더 정지.
    final notifier = TickerMode.getValuesNotifier(context);
    if (!identical(notifier, _tickerMode)) {
      _tickerMode?.removeListener(_syncPlayState);
      _tickerMode = notifier..addListener(_syncPlayState);
    }
    // reduce-motion/다크에선 컨트롤러 자체를 만들지 않는다(낭비 방지).
    if (!_initStarted && _shouldPlay(context)) {
      _initStarted = true;
      _init();
    }
  }

  // 앱은 라이트 전용(themeMode.light) — 다크 분기 없음. multiply 블렌드는
  // 항상 밝은 배경 위에서 동작한다.
  bool _shouldPlay(BuildContext context) =>
      TigerStageVideo.videoReady && !SoriMotion.reduceMotion(context);

  Future<void> _init() async {
    final greet = VideoPlayerController.asset(TigerStageVideo.greetAsset);
    final pace = VideoPlayerController.asset(TigerStageVideo.paceAsset);
    _greet = greet;
    _pace = pace;
    try {
      await greet.initialize();
      await pace.initialize();
      // 홈은 항상 무음 — 임베디드 AAC 트랙 차단.
      await greet.setVolume(0);
      await pace.setVolume(0);
      await pace.setLooping(true);
    } catch (_) {
      if (mounted) {
        setState(() => _failed = true);
      } else {
        _failed = true;
      }
      return;
    }
    if (!mounted) {
      return;
    }
    if (_greetPlayedThisLaunch) {
      _showPace = true;
    } else {
      _greetPlayedThisLaunch = true;
      greet.addListener(_onGreetTick);
    }
    setState(() => _ready = true);
    _syncPlayState();
  }

  /// 인사 영상 종료 감지 → 150ms 크로스페이드로 pacing 루프 전환.
  void _onGreetTick() {
    final greet = _greet;
    if (greet == null || _showPace || !_greetStarted) {
      return;
    }
    final v = greet.value;
    final done =
        v.isInitialized &&
        v.duration > Duration.zero &&
        !v.isPlaying &&
        v.position >= v.duration - const Duration(milliseconds: 80);
    if (done) {
      greet.removeListener(_onGreetTick);
      if (mounted) {
        setState(() => _showPace = true);
      }
      _syncPlayState();
    }
  }

  /// 현재 보여야 할 영상만 재생, 나머지/비가시/백그라운드는 pause.
  void _syncPlayState() {
    if (!_ready || _failed) {
      return;
    }
    final visible = (_tickerMode?.value.enabled ?? true) && !_appPaused;
    final active = _showPace ? _pace : _greet;
    final idle = _showPace ? _greet : _pace;
    idle?.pause();
    if (visible) {
      active?.play();
      if (!_showPace) {
        _greetStarted = true;
      }
    } else {
      active?.pause();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _appPaused = true;
      _syncPlayState();
    } else if (state == AppLifecycleState.resumed) {
      _appPaused = false;
      _syncPlayState();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tickerMode?.removeListener(_syncPlayState);
    _greet?.removeListener(_onGreetTick);
    _greet?.dispose();
    _pace?.dispose();
    super.dispose();
  }

  Widget _fallback() => TigerStageRive(
    height: widget.height,
    fallbackEmotion: widget.fallbackEmotion,
  );

  @override
  Widget build(BuildContext context) {
    if (!_shouldPlay(context) || _failed) {
      return _fallback();
    }
    final active = _showPace ? _pace : _greet;
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: !_ready || active == null
            // init 중(~0.2s)엔 빈 밴드 → 페이드인 (프레임 인트로와 겹침 방지).
            ? const SizedBox.shrink()
            : Center(key: ValueKey<bool>(_showPace), child: _tigerView(active)),
      ),
    );
  }

  /// 알파 여부에 따라 렌더 분기.
  /// - 알파 O: multiply·액자 없이 raw → 배경 투명, 홈 크림과 edge-to-edge(#2).
  /// - 알파 X: 흰→크림 multiply 후 초상 액자로 감싸 "의도된 초상"으로(#3).
  Widget _tigerView(VideoPlayerController active) {
    // 액자(테두리 2px + 여백)일 때 밴드 높이를 넘지 않게 정사각을 줄인다.
    final double dim = TigerStageVideo.hasAlpha
        ? widget.height
        : widget.height - 8;
    final sized = SizedBox.square(
      dimension: dim,
      child: TigerStageVideo.hasAlpha
          ? VideoPlayer(active)
          : ColorFiltered(
              colorFilter: ColorFilter.mode(
                widget.blendColor,
                BlendMode.multiply,
              ),
              child: VideoPlayer(active),
            ),
    );
    if (TigerStageVideo.hasAlpha) {
      return sized; // 투명 = 액자 없이 그대로 배경에 녹임.
    }
    // 초상 액자(#3): 은은한 한지 창 + 호랑이색 테두리 → 회색 박스를 의도된 요소로.
    return Container(
      decoration: BoxDecoration(
        color: widget.blendColor,
        borderRadius: BorderRadius.circular(SoriRadius.lg),
        border: Border.all(
          color: SoriColors.tiger.withValues(alpha: 0.28),
          width: 2,
        ),
        boxShadow: SoriElevation.low,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SoriRadius.lg - 2),
        child: sized,
      ),
    );
  }
}

/// 온보딩 첫 만남용 — 인사 영상 1회 + (옵션) 풀 오디오 mp3 동시 재생.
///
/// 영상 자체는 muted, 음성은 Jin 제공 `assets/sfx/tiger_greet.mp3`가 정본.
/// init 전·실패·!videoReady·reduce-motion → 정적 [Mascot.tiger] 폴백.
class TigerGreetClip extends StatefulWidget {
  final double size;
  final bool playAudio;

  /// multiply 블렌드 색 — 화면의 플랫 배경색과 일치시키면 완전히 녹는다.
  final Color blendColor;

  const TigerGreetClip({
    super.key,
    this.size = 200,
    this.playAudio = false,
    this.blendColor = SoriColors.lightBg,
  });

  @override
  State<TigerGreetClip> createState() => _TigerGreetClipState();
}

class _TigerGreetClipState extends State<TigerGreetClip> {
  VideoPlayerController? _video;
  AudioPlayer? _audio;
  bool _initStarted = false;
  bool _ready = false;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initStarted &&
        TigerStageVideo.videoReady &&
        !SoriMotion.reduceMotion(context)) {
      _initStarted = true;
      _init();
    }
  }

  Future<void> _init() async {
    final video = VideoPlayerController.asset(TigerStageVideo.greetAsset);
    _video = video;
    try {
      await video.initialize();
      await video.setVolume(0);
    } catch (_) {
      if (mounted) {
        setState(() => _failed = true);
      } else {
        _failed = true;
      }
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _ready = true);
    await video.play();
    if (widget.playAudio) {
      // best-effort — 웹 autoplay 차단 등은 조용히 무시.
      try {
        final audio = AudioPlayer();
        _audio = audio;
        await audio.play(AssetSource('sfx/tiger_greet.mp3'));
      } catch (_) {
        // 음성 실패해도 영상은 계속.
      }
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    _audio?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    final live =
        TigerStageVideo.videoReady &&
        !SoriMotion.reduceMotion(context) &&
        !_failed;
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: !live
            ? Mascot(
                kind: MascotKind.tiger,
                emotion: MascotEmotion.smile,
                size: widget.size * 0.8,
                animate: true,
              )
            : (!_ready || video == null)
            ? const SizedBox.shrink()
            : ColorFiltered(
                colorFilter: ColorFilter.mode(
                  widget.blendColor,
                  BlendMode.multiply,
                ),
                child: VideoPlayer(video),
              ),
      ),
    );
  }
}
