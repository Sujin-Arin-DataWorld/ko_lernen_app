import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/audio_policy.dart';
import 'mascot.dart';
import 'mascot_preference.dart';
import 'tokens.dart';
import 'video_lease.dart';

/// **살아있는 호랑이 — 영상 버전** (Jin 제작 mp4, 2026-06-12).
///
/// 부드러운 영상 경로. (구 프레임 PNG 시퀀스 `TigerStage`/`TigerStageRive` 는
/// 2026-08-06 폐지 — 프레임 44장은 `assets_unused/` 로 옮겼고, 현재 정본은
/// `CharacterClipPlayer` + `assets/video/character/` 다.)
/// H.264라 알파가 없고 배경이 흰색(~#F0F4F2)으로 박혀 있다 → [ColorFiltered]
/// `BlendMode.multiply`로 흰 배경을 크림 배경색에 흡수시킨다 (흰색×크림=크림,
/// 호랑이는 미세하게 따뜻해짐). multiply 결과는 child×색 고정값이라 밝은 배경
/// 전용 — 앱이 라이트 전용(`themeMode.light`)이라 항상 성립한다.
///
/// ⚠️ 캔버스 `saveLayer` 블렌드는 비디오가 `Texture` 엔진 레이어로 합성돼
/// 적용되지 않음 — 반드시 컴포지터 레이어인 [ColorFiltered]를 쓸 것.
///
/// 폴백 체인: !videoReady ‖ reduce-motion ‖ 로드 실패
///   → 정적 [Mascot] (캐릭터별 표정 PNG).

/// 홈 히어로 밴드용 — 인사(launch당 1회) → 왔다갔다 루프. 항상 무음.
class TigerStageVideo extends StatefulWidget {
  /// 밴드 높이(px). 영상(1:1)은 높이 기준 정사각으로 중앙 배치.
  final double height;

  /// 폴백 [Mascot]에 넘길 표정.
  final MascotEmotion fallbackEmotion;

  /// multiply 블렌드 색 — 영상 흰 배경이 이 색이 된다. 밴드 뒤 실제 배경
  /// (홈 크림 그라데이션 중간값)에 맞춘 튜닝 노브. 실기기에서 박스 경계가
  /// 보이면 이 값을 현지 배경에 더 가깝게 조정.
  final Color blendColor;

  /// 표시할 캐릭터. `null`이면 [MascotPreference.kind]를 구독해 따라간다.
  /// 홈은 null로 두면 된다 — 설정에서 캐릭터를 바꾸면 즉시 반영된다.
  final MascotKind? kind;

  const TigerStageVideo({
    super.key,
    this.height = 168,
    this.fallbackEmotion = MascotEmotion.smile,
    this.blendColor = const Color(0xFFF8F2E4),
    this.kind,
  });

  /// main()에서만 true. 테스트/미배선 환경은 false → 프레임 폴백
  /// (정적 플래그 패턴 — 테스트가 플러그인 채널에 의존 안 함).
  static bool videoReady = false;

  // `hasAlpha` 는 2026-08-06 삭제 — 한 번도 true 로 설정된 적이 없어 raw 렌더
  // 분기가 도달 불가였고, 설명하던 "초상 액자"도 never-cage 규칙으로 이미
  // 제거된 상태였다. 알파 mp4 를 실제로 내보내게 되면 그때 되살린다.

  // 2026-07-29 배치: 캐논 호랑이(엎드린 휴식 모델) 클립으로 교체.
  // greet = 엎드림→기상 인사(1회), pace = 엎드려 쉬는 아이들 루프.
  // 구 tiger_greet/tiger_pace.mp4는 assets_unused/video/로 이동(2026-07-30) —
  // 롤백하려면 git mv로 assets/video/에 복원 후 아래 상수만 되돌리면 된다.
  // 2026-07-31: 캐릭터 대응. 이전에는 호랑이 상수 2개로 고정돼 있어서
  // 까치를 골라도 홈 히어로가 100% 호랑이였다. 4종 모두 실재 파일이다.
  /// 진입 인사 클립 (1회 재생) — Jin 2026-08-06: 온보딩 첫 만남도 선택 확정과
  /// 같은 `_choose` 클립을 쓴다(까치 magpie_choose, 호랑이 tiger_choose).
  static String greetFor(MascotKind kind) => kind == MascotKind.magpie
      ? 'assets/video/character/magpie_choose.mp4'
      : 'assets/video/character/tiger_choose.mp4';

  /// 인사 후 아이들 루프. (현재 TigerStageVideo 위젯이 미인스턴스화라 휴면 —
  /// magpie_full10 폐지 후 까치는 magpie_perched 로 대체.)
  static String paceFor(MascotKind kind) => kind == MascotKind.magpie
      ? 'assets/video/character/magpie_perched.mp4'
      : 'assets/video/character/tiger_rest.mp4';

  /// 호랑이 기본값 — 하위호환용. 신규 코드는 [greetFor]/[paceFor]를 쓸 것.
  static const String greetAsset = 'assets/video/character/tiger_rise.mp4';
  static const String paceAsset = 'assets/video/character/tiger_rest.mp4';

  /// 첫 인사 동반 효과음 (`assets/sfx/` — AssetSource 경로라 'assets/' 생략).
  /// 까치 `greet_magpie.mp3` 는 2026-07-31 제작·실재. 호랑이는 기존 정본
  /// `tiger_greet.mp3` 유지 (`greet_tiger.mp3` 와 이중 존재 — 정리는 Jin 판단).
  static String greetSfxFor(MascotKind kind) => kind == MascotKind.magpie
      ? 'sfx/greet_magpie.mp3'
      : 'sfx/tiger_greet.mp3';

  @override
  State<TigerStageVideo> createState() => _TigerStageVideoState();
}

class _TigerStageVideoState extends State<TigerStageVideo> {
  /// 인사는 앱 launch당 1회 (구 프레임 시퀀스의 `_introPlayedThisLaunch` 패턴).
  static bool _greetPlayedThisLaunch = false;

  VideoPlayerController? _video;
  VideoLeaseRequest<VideoPlayerController>? _lease;
  late final VideoLeaseEligibilityBinding _eligibility;
  MascotKind? _builtFor;
  bool _ready = false;
  bool _failed = false;
  bool _showPace = false;
  bool _greetStarted = false;
  bool _handoffStarted = false;
  int _transitionGeneration = 0;

  /// 이 위젯이 그려야 할 캐릭터. 명시 인자 > 전역 선택값.
  MascotKind get _kind => widget.kind ?? MascotPreference.kind.value;

  @override
  void initState() {
    super.initState();
    _showPace = _greetPlayedThisLaunch;
    _eligibility = VideoLeaseEligibilityBinding(onChanged: _syncEligibility);
    if (widget.kind == null) {
      MascotPreference.kind.addListener(_onKindChanged);
    }
  }

  @override
  void didUpdateWidget(TigerStageVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      _onKindChanged();
    }
  }

  void _onKindChanged() {
    if (!mounted || _builtFor == _kind) {
      return;
    }
    unawaited(_restartForCurrentKind());
  }

  Future<void> _restartForCurrentKind() async {
    final transition = ++_transitionGeneration;
    final lease = _lease;
    _lease = null;
    if (lease != null) {
      await lease.release();
    }
    if (!mounted || transition != _transitionGeneration) {
      return;
    }
    _showPace = _greetPlayedThisLaunch;
    _greetStarted = false;
    _handoffStarted = false;
    _failed = false;
    _registerCurrentPhase();
    _syncEligibility();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _eligibility.attach(context);
    if (_lease == null) {
      _registerCurrentPhase();
    }
    _syncEligibility();
  }

  void _registerCurrentPhase() {
    if (_lease != null) {
      return;
    }
    final kind = _kind;
    final pacePhase = _showPace;
    _builtFor = kind;
    _lease = soriVideoLease.register(
      asset: pacePhase
          ? TigerStageVideo.paceFor(kind)
          : TigerStageVideo.greetFor(kind),
      eligible: false,
      prepare: (video) async {
        // audio-policy: exempt — 홈 히어로 영상은 정책상 상시 무음(트랙 없음)
        await video.setVolume(0);
        if (pacePhase) {
          await video.setLooping(true);
        }
      },
      onGranted: (video) => _onGranted(video, pacePhase: pacePhase),
      onRevoked: _onRevoked,
      onFailed: _onFailed,
    );
  }

  void _syncEligibility() {
    if (!mounted) {
      return;
    }
    _lease?.setEligible(
      _eligibility.isEligible(context, videoReady: TigerStageVideo.videoReady),
    );
  }

  bool _shouldPlay(BuildContext context) =>
      TigerStageVideo.videoReady && !SoriMotion.reduceMotion(context);

  void _onGranted(VideoPlayerController video, {required bool pacePhase}) {
    _video = video;
    if (!pacePhase) {
      video.addListener(_onGreetTick);
    }
    if (mounted) {
      setState(() {
        _ready = true;
        _failed = false;
      });
    }
    _greetStarted = !pacePhase;
    unawaited(video.play());
  }

  void _onRevoked() {
    _video?.removeListener(_onGreetTick);
    _video = null;
    _ready = false;
    if (mounted) {
      setState(() {});
    }
  }

  void _onFailed(Object _, StackTrace __) {
    _video = null;
    _ready = false;
    _failed = true;
    if (mounted) {
      setState(() {});
    }
  }

  void _onGreetTick() {
    final video = _video;
    if (video == null || _showPace || !_greetStarted || _handoffStarted) {
      return;
    }
    final v = video.value;
    final done =
        v.isInitialized &&
        v.duration > Duration.zero &&
        !v.isPlaying &&
        v.position >= v.duration - const Duration(milliseconds: 80);
    if (done) {
      _handoffStarted = true;
      video.removeListener(_onGreetTick);
      _greetPlayedThisLaunch = true;
      unawaited(_handoffToPace());
    }
  }

  /// Greeting ownership is fully revoked and disposed before pace competes.
  Future<void> _handoffToPace() async {
    final transition = ++_transitionGeneration;
    final greetingLease = _lease;
    _lease = null;
    if (greetingLease != null) {
      await greetingLease.release();
    }
    if (!mounted || transition != _transitionGeneration) {
      return;
    }
    setState(() {
      _showPace = true;
      _ready = false;
      _failed = false;
    });
    _registerCurrentPhase();
    _syncEligibility();
  }

  @override
  void dispose() {
    _transitionGeneration += 1;
    if (widget.kind == null) {
      MascotPreference.kind.removeListener(_onKindChanged);
    }
    _eligibility.disposeBinding();
    _video?.removeListener(_onGreetTick);
    final lease = _lease;
    _lease = null;
    if (lease != null) {
      unawaited(lease.release());
    }
    super.dispose();
  }

  /// 폴백은 캐릭터 무관하게 정적 [Mascot] 이다 — 2026-08-06 프레임 시퀀스
  /// (`TigerStage`/`TigerStageRive`, tiger_anim 44장) 폐지 후 호랑이도 까치와
  /// 같은 경로를 쓴다. 표정 PNG 는 `assets/illustrations/mascot/tiger_*.png`.
  Widget _fallback() => Center(
    child: Mascot(
      kind: _kind,
      emotion: widget.fallbackEmotion,
      size: widget.height * 0.82,
      animate: true,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final active = _video;
    if (!_shouldPlay(context) || _failed || !_ready || active == null) {
      return _fallback();
    }
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Center(key: ValueKey<bool>(_showPace), child: _tigerView(active)),
    );
  }

  /// 흰 매트(H.264라 알파 없음) mp4를 `BlendMode.multiply` 로 렌더한다.
  /// multiply(흰색, blendColor) == blendColor 이므로 클립 배경은 blendColor
  /// 단색이 되고, 뒤 표면이 같은 색일 때만 경계가 보이지 않는다.
  Widget _tigerView(VideoPlayerController active) {
    // Jin 2026-08-05: 캐릭터를 액자/박스에 가두지 않는다. 흰 배경 mp4를
    // multiply로 홈 크림 배경에 그대로 녹여 캐릭터만 떠 보이게 한다(테두리·여백
    // 없이 밴드 높이 그대로 정사각).
    return SizedBox.square(
      dimension: widget.height,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(widget.blendColor, BlendMode.multiply),
        child: VideoPlayer(active),
      ),
    );
  }
}

/// 온보딩 첫 만남용 — 인사 영상 1회 + (옵션) 풀 오디오 mp3 동시 재생.
///
/// 영상 자체는 muted, 음성은 캐릭터별 [TigerStageVideo.greetSfxFor]
/// (호랑이 `tiger_greet.mp3` · 까치 `greet_magpie.mp3`).
/// init 전·실패·!videoReady·reduce-motion → 정적 [Mascot.tiger] 폴백.
class TigerGreetClip extends StatefulWidget {
  final double size;
  final bool playAudio;

  /// 표시할 캐릭터. `null`이면 [MascotPreference.kind] 현재값.
  final MascotKind? kind;

  /// multiply 블렌드 색 — 화면의 플랫 배경색과 일치시키면 완전히 녹는다.
  final Color blendColor;

  const TigerGreetClip({
    super.key,
    this.size = 200,
    this.playAudio = false,
    this.blendColor = SoriColors.lightBg,
    this.kind,
  });

  @override
  State<TigerGreetClip> createState() => _TigerGreetClipState();
}

class _TigerGreetClipState extends State<TigerGreetClip> {
  VideoPlayerController? _video;
  VideoLeaseRequest<VideoPlayerController>? _lease;
  late final VideoLeaseEligibilityBinding _eligibility;
  late final OneShotVideoLeaseCompletion _completion;
  AudioPlayer? _audio;
  bool _ready = false;
  bool _failed = false;
  bool _audioStarted = false;

  @override
  void initState() {
    super.initState();
    _eligibility = VideoLeaseEligibilityBinding(onChanged: _syncEligibility);
    _completion = OneShotVideoLeaseCompletion(
      fallbackCompleteAfter: const Duration(milliseconds: 1200),
      onRelease: _releaseAfterCompletion,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _eligibility.attach(context);
    if (_lease == null) {
      _registerLease();
    }
    _syncEligibility();
  }

  MascotKind get _kind => widget.kind ?? MascotPreference.kind.value;

  void _registerLease() {
    _lease = soriVideoLease.register(
      asset: TigerStageVideo.greetFor(_kind),
      eligible: false,
      // audio-policy: exempt — 온보딩 인사 클립 정책상 무음(음성은 별도 mp3)
      prepare: (video) => video.setVolume(0),
      onGranted: _onGranted,
      onRevoked: _onRevoked,
      onFailed: _onFailed,
    );
  }

  void _syncEligibility() {
    if (!mounted) {
      return;
    }
    _completion.visibilityChanged(_eligibility.isVisible(context));
    final eligible = _eligibility.isEligible(
      context,
      videoReady: TigerStageVideo.videoReady,
    );
    if (eligible) {
      _completion.leaseRequested();
    }
    _lease?.setEligible(eligible);
    if (!TigerStageVideo.videoReady || SoriMotion.reduceMotion(context)) {
      _completion.fallbackNeeded();
    }
  }

  void _onGranted(VideoPlayerController video) {
    _video = video;
    _completion.leaseGranted();
    video.addListener(_onTick);
    if (mounted) {
      setState(() {
        _ready = true;
        _failed = false;
      });
    }
    unawaited(video.play());
    unawaited(_playAudioOnce());
  }

  void _onRevoked() {
    _video?.removeListener(_onTick);
    _video = null;
    _ready = false;
    _completion.leaseRevoked();
    if (mounted) {
      setState(() {});
    }
  }

  void _onFailed(Object _, StackTrace __) {
    _video = null;
    _ready = false;
    _failed = true;
    if (mounted) {
      setState(() {});
    }
    _completion.fallbackNeeded();
  }

  void _onTick() {
    final video = _video;
    if (video == null) {
      return;
    }
    final value = video.value;
    if (_completion.completeFromPlayback(
      isInitialized: value.isInitialized,
      duration: value.duration,
      isPlaying: value.isPlaying,
      position: value.position,
    )) {
      video.removeListener(_onTick);
    }
  }

  Future<void> _releaseAfterCompletion() async {
    _onRevoked();
    final lease = _lease;
    _lease = null;
    if (lease != null) {
      await lease.release();
    }
  }

  Future<void> _playAudioOnce() async {
    // 캐릭터별 인사 SFX — 까치 `greet_magpie.mp3` 는 07-31 제작·배선 완료라
    // 구 "까치용 파일 없음" 호랑이 전용 가드를 정리했다 (2026-08-03).
    // 소리 규칙(사람 목소리·TTS 금지, 동물 소리만)은 파일 차원에서 유지.
    if (!_audioStarted && widget.playAudio) {
      // companion 채널 게이트 — 현재 유일 호출부가 playAudio:false 라 죽은
      // 경로지만, 되살아나는 순간 설정을 뚫는 유일한 소리가 되는 걸 막는다.
      final volume = AudioPolicy.instance.volumeFor(SoundChannel.companion);
      if (volume <= 0) {
        return;
      }
      _audioStarted = true;
      // best-effort — 웹 autoplay 차단 등은 조용히 무시.
      try {
        final audio = AudioPlayer();
        _audio = audio;
        await audio.play(
          AssetSource(TigerStageVideo.greetSfxFor(_kind)),
          volume: volume,
        );
      } catch (_) {
        // 음성 실패해도 영상은 계속.
      }
    }
  }

  @override
  void dispose() {
    _completion.dispose();
    _eligibility.disposeBinding();
    _video?.removeListener(_onTick);
    final lease = _lease;
    _lease = null;
    if (lease != null) {
      unawaited(lease.release());
    }
    _audio?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _failed || !_ready || video == null
            ? Mascot(
                kind: _kind,
                emotion: MascotEmotion.smile,
                size: widget.size * 0.8,
                animate: true,
              )
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
