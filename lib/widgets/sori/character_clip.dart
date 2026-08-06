import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/audio_policy.dart';
import 'mascot.dart';
import 'mascot_preference.dart';
import 'tiger_video.dart';
import 'tokens.dart';
import 'video_lease.dart';

/// **캐릭터 클립 카탈로그** — `assets/video/character/`의 흰 배경 H.264 mp4.
///
/// 배치 계획(docs/INTEGRATION_2026-07-29.md) §2의 캐릭터 클립 16종.
/// 모든 클립은 흰 배경(≈#FFFFFF)으로 렌더되어 [TigerStageVideo]와 동일한
/// multiply 블렌드 방식으로 라이트 배경에 녹는다.
class CharacterClips {
  CharacterClips._();

  static const String _base = 'assets/video/character';

  // ── 호랑이 ──────────────────────────────────────────────
  static const String tigerRise = '$_base/tiger_rise.mp4'; // 엎드림→기상 인사
  static const String tigerRoar = '$_base/tiger_roar.mp4'; // 레벨업 포효
  static const String tigerCelebrateHifive =
      '$_base/tiger_celebrate_hifive.mp4'; // 정답 하이파이브
  static const String tigerRest = '$_base/tiger_rest.mp4'; // 아이들(귀·깜빡임)
  static const String tigerSitting2 = '$_base/tiger_sitting2.mp4'; // 프로필 초상
  static const String tigerBob = '$_base/tiger_walking_front.mp4'; // 게임 대기 바운스
  static const String tigerStretch = '$_base/tiger_stretch.mp4'; // 세션 완료
  static const String tigerThinking = '$_base/tiger_thinking.mp4'; // 퀴즈 생각
  static const String tigerChoose = '$_base/tiger_choose.mp4'; // 선택 확정 목례
  static const String tigerGreetPawflash =
      '$_base/tiger_greet_pawflash.mp4'; // 첫 인사 — 앞발 번쩍

  /// 정면 보행 — 원샷 전용.
  ///
  /// 걸어오며 피사체가 38% 커지고 루프 이음새가 인접프레임 대비 8.3배라
  /// `loop: true` 로 쓰면 5초마다 크기가 튄다. 반드시 `loop: false`.
  static const String tigerWalkingFront =
      '$_base/tiger_walking_front.mp4'; // 정면 보행(원샷)

  /// 신기록 보너스 포효.
  ///
  /// 전용 클립 `tiger_roar_seated_bonus.mp4` 는 에셋 폴더에 존재한 적이 없다
  /// (2026-07-31 확인). 참조만 남아 있어 신기록을 내도 [CharacterClipPlayer]가
  /// 로드 실패 → 정적 마스코트로 조용히 폴백, 연출이 통째로 사라진 상태였다.
  /// Jin 지시로 기본 포효 클립으로 대체 — 전용 클립이 들어오면 이 한 줄만
  /// 되돌리면 된다.
  static const String tigerRoarSeatedBonus = tigerRoar;

  // ── 까치 ────────────────────────────────────────────────
  static const String magpieFlight = '$_base/magpie_flight.mp4'; // 인트로 비행
  static const String magpieCelebrate = '$_base/magpie_celebrate.mp4'; // 정답 축하
  static const String magpieWorry = '$_base/magpie_worry.mp4'; // 오답 위로
  static const String magpiePerched = '$_base/magpie_perched.mp4'; // 듣기 대기
  static const String magpieChoose = '$_base/magpie_choose.mp4'; // 선택 확정 착지
  static const String magpieBob = '$_base/magpie_bob.mp4'; // 대기 홉(루프, 현재 미사용)
  static const String magpieBob2 = '$_base/magpie_bob2.mp4'; // 프로필 아바타(까치)
  /// 홈 히어로(까치) 대기 루프. 파일명 magpie_walking_front.mp4 로 통일 —
  /// 구 magpie_bob3 / magpie_walking_forward 와 동일 클립이라 하나로 합쳤다
  /// (Jin 2026-08-06).
  static const String magpieWalkingFront = '$_base/magpie_walking_front.mp4';
  // magpie_flourish·magpie_sing·magpie_soar·magpie_greet_chirp 는 Jin 이 에셋에서
  // 삭제 → 상수 제거(코드 참조 0건 확인). magpie_greet_chirp 은 magpie_celebrate 와
  // 사실상 동일해 폐지(2026-08-06). 파일 복원 시 상수만 되살리면 된다.

  /// 프로필 초상에 사용할 포즈. 프로필 화면은 생성 시 하나를 골라 해당
  /// 화면이 살아 있는 동안 유지한다.
  // Jin 2026-08-06: 프로필 호랑이는 tiger_sitting2(앉은 루프) 고정 — 원샷 보행
  // tiger_walking_front 는 루프 시 사라지거나 튀어서 교체.
  static const List<String> _tigerProfileClips = [tigerSitting2];
  static const List<String> _magpieProfileClips = [
    magpiePerched,
    magpieChoose,
    magpieFlight,
  ];

  /// [kind]의 프로필 포즈 수.
  static int profileClipCountFor(MascotKind kind) =>
      _profileClipsFor(kind).length;

  /// [choice]번째 프로필 포즈. 호출 측은 [profileClipCountFor] 범위의
  /// 무작위 인덱스를 전달한다.
  static String profileClipFor(MascotKind kind, int choice) =>
      _profileClipsFor(kind)[choice];

  static List<String> _profileClipsFor(MascotKind kind) =>
      kind == MascotKind.magpie ? _magpieProfileClips : _tigerProfileClips;

  /// 첫 인사 클립 (말 없이 — 동물 몸짓만; 소리는 별도 SFX 훅).
  /// 까치 전용 인사(magpie_greet_chirp)는 celebrate 와 중복이라 폐지 →
  /// magpie_choose 로 대체(Jin 2026-08-06).
  static String greetFor(MascotKind kind) =>
      kind == MascotKind.magpie ? magpieChoose : tigerGreetPawflash;

  /// 세션/레슨 완료 클립 — 캐릭터별. 호랑이는 포효, 까치는 축하 날갯짓.
  static String sessionCompleteFor(MascotKind kind) =>
      kind == MascotKind.magpie ? magpieCelebrate : tigerRoar;

  /// "생각 중" 루프 — 호랑이만 전용 클립이 있고 까치는 대기 자세를 쓴다.
  static String thinkingFor(MascotKind kind) =>
      kind == MascotKind.magpie ? magpiePerched : tigerThinking;

  /// 선택 확정 클립.
  static String chooseFor(MascotKind kind) =>
      kind == MascotKind.magpie ? magpieChoose : tigerChoose;

  /// 게임 종료 피드백 클립 — [GameOverCard] 등 결과 카드용.
  ///
  /// 감정에 맞는 클립이 없는 조합(예: 호랑이 worry)은 null → 호출측이
  /// 기존 정적 [Mascot]을 그대로 쓴다. [newBest]면 호랑이는 하이파이브
  /// 대신 포효([tigerRoarSeatedBonus] — 현재 `tiger_roar.mp4`).
  static String? feedbackFor(
    MascotKind kind,
    MascotEmotion emotion, {
    bool newBest = false,
  }) {
    switch (emotion) {
      case MascotEmotion.celebrate:
        if (kind == MascotKind.magpie) return magpieCelebrate;
        return newBest ? tigerRoarSeatedBonus : tigerCelebrateHifive;
      case MascotEmotion.worry:
        return kind == MascotKind.magpie ? magpieWorry : null;
      case MascotEmotion.thinking:
        return kind == MascotKind.tiger ? tigerThinking : null;
      default:
        return null;
    }
  }

  /// 클립 → 동반 효과음(`assets/sfx/*.mp3`).
  ///
  /// **캐릭터 mp4에는 오디오 트랙이 없다** — 소스가 크로마키 합성이라 출력
  /// 단계에서 소리가 실리지 않았다. 그래서 포효·짹짹은 영상이 아니라 이
  /// 별도 mp3로 재생한다(볼륨·설정 제어가 쉽다는 이점도 있다).
  /// 파일이 없으면 SoundService 와 같은 철학으로 조용히 무음.
  ///
  /// 매핑이 없는 클립(대기 루프·생각 중 등)은 null — 상시 루프에까지 소리를
  /// 붙이면 TTS와 겹쳐 학습을 방해한다. **일회성 연출에만** 소리를 준다.
  static String? sfxFor(String clipAsset) {
    switch (clipAsset) {
      case tigerGreetPawflash:
      case tigerRise:
        return 'sfx/greet_tiger.mp3';
      // Jin 2026-08-06: 전용 포효 음원 growl_tiger.mp3 도착 → 매핑 부활.
      // 레벨업·마일스톤·세션완료(호랑이) 포효에 붙는다. tigerRoarSeatedBonus 는
      // tigerRoar 와 동일 상수라 이 케이스가 함께 커버한다.
      case tigerRoar:
        return 'sfx/growl_tiger.mp3';
      case tigerCelebrateHifive:
      case tigerStretch:
        return 'sfx/celebrate_tiger.mp3';
      case magpieCelebrate:
      case magpieFlight:
        return 'sfx/celebrate_magpie.mp3';
      default:
        return null;
    }
  }
}

/// **CharacterClipPlayer** — 캐릭터 클립 범용 재생 위젯.
///
/// [TigerGreetClip]의 패턴을 모든 클립·양 캐릭터로 일반화한 것:
/// - 흰 배경 mp4를 muted 재생, [blendColor] multiply로 배경에 흡수.
/// - 게이트: `TigerStageVideo.videoReady && !SoriMotion.reduceMotion`.
/// - 실패/게이트오프 → 정적 [Mascot] 폴백 (기존 UX 그대로 유지).
/// - [loop]=false(원샷)일 때 종료되면 [onCompleted] 1회 호출 — 실패·폴백
///   경로에서도 [fallbackCompleteAfter] 뒤에 반드시 호출되므로 네비게이션
///   체인에 안전하게 쓸 수 있다.
/// - [sfxAsset]: 위젯 표시와 동시에 best-effort로 재생할 효과음
///   (예: 'sfx/greet_tiger.mp3'). 영상 lease grant 를 **기다리지 않는다** —
///   느린 디코더 핸드오프에 소리가 유실되지 않게. 파일이 없거나 실패해도
///   조용히 무시.
class CharacterClipPlayer extends StatefulWidget {
  final String asset;
  final double size;
  final bool loop;
  final Color blendColor;

  /// 폴백 마스코트. `null`이면 [MascotPreference] 의 선택 캐릭터를 쓴다.
  final MascotKind? fallbackKind;
  final MascotEmotion fallbackEmotion;

  /// 정적 [Mascot] 폴백을 그릴지. `false`면 영상 미준비/실패 시 정적 마스코트
  /// 대신 **투명**(빈 SizedBox) — 흰 카드/박스가 안 생겨 배경이 그대로 비친다.
  /// 상시 루프로 영상이 거의 항상 떠 있는 곳(홈 히어로 등)에서 폴백이 순간
  /// 번쩍이며 "정적+영상 둘 다" 보이는 걸 막는다(Jin 2026-08-06).
  ///
  /// ⚠️ `false` 는 **영상이 실제로 뜰 곳에서만** 안전하다. 영상이 범주적으로
  /// 불가한 상황(기기 미지원·reduce-motion)에서 끄면 자리가 통째로 빈칸이
  /// 된다 — 그 판별은 [videoUnavailable] 을 쓸 것.
  final bool staticFallback;

  /// 영상 경로가 **범주적으로 불가**한가 — 기기가 영상을 못 틀거나
  /// (`TigerStageVideo.videoReady == false`) reduce-motion 이 켜져 있어
  /// `VideoLeaseEligibility` 가 lease 를 절대 승인하지 않는 경우.
  ///
  /// 이때는 [staticFallback] 을 켜야 한다. 반대로 "영상은 뜰 건데 아직 로드
  /// 중"인 짧은 순간은 여기 해당하지 않으므로 투명이 맞다.
  ///
  /// **다크도 여기 포함된다.** multiply 는 밝은 배경 전용이다 —
  /// `multiply(#FFFFFF, C) == C` 라 흰 매트는 [blendColor] 단색 사각형으로
  /// 칠해진다. 다크 배경 위에서는 밝은 blendColor 면 크림 사각형이 그대로
  /// 뜨고, 어두운 blendColor 로 바꾸면 이번엔 캐릭터가 새까매진다. 즉 다크는
  /// 색 조정으로 못 고치고 영상 경로 자체가 불가 → 정적 [Mascot] 로 간다.
  /// (현재 `main.dart` 가 `themeMode.light` 고정이라 잠복 상태의 지뢰다.)
  static bool videoUnavailable(BuildContext context) =>
      !TigerStageVideo.videoReady ||
      SoriMotion.reduceMotion(context) ||
      Theme.of(context).brightness == Brightness.dark;
  final VoidCallback? onCompleted;
  final Duration fallbackCompleteAfter;
  final String? sfxAsset;

  const CharacterClipPlayer({
    super.key,
    required this.asset,
    this.size = 180,
    this.loop = false,
    this.blendColor = SoriColors.lightBg,
    this.fallbackKind,
    this.fallbackEmotion = MascotEmotion.smile,
    this.staticFallback = true,
    this.onCompleted,
    this.fallbackCompleteAfter = const Duration(milliseconds: 1200),
    this.sfxAsset,
  });

  @override
  State<CharacterClipPlayer> createState() => _CharacterClipPlayerState();
}

class _CharacterClipPlayerState extends State<CharacterClipPlayer> {
  VideoPlayerController? _video;
  VideoLeaseRequest<VideoPlayerController>? _lease;
  late final VideoLeaseEligibilityBinding _eligibility;
  late final OneShotVideoLeaseCompletion? _completion;
  AudioPlayer? _audio;
  bool _ready = false;
  bool _failed = false;
  bool _sfxStarted = false;

  /// `staticFallback:false` 전용 워치독. 영상이 이 시간 안에 안 뜨면 정적
  /// 마스코트로 메운다 — 자리가 빈칸으로 남는 것보다 낫다. 200ms 크로스페이드
  /// 라 영상이 뒤늦게 와도 자연스럽게 넘어간다. `staticFallback:true` 인
  /// 호출부는 이미 정적이 떠 있으므로 타이머를 아예 만들지 않는다(테스트 환경은
  /// `videoReady=false` → 전부 이쪽이라 pending timer 가 생기지 않는다).
  static const Duration _kFallbackWatchdog = Duration(milliseconds: 900);
  bool _fallbackDue = false;
  Timer? _fallbackWatchdog;

  @override
  void initState() {
    super.initState();
    _eligibility = VideoLeaseEligibilityBinding(onChanged: _syncEligibility);
    _completion = widget.loop
        ? null
        : OneShotVideoLeaseCompletion(
            fallbackCompleteAfter: widget.fallbackCompleteAfter,
            onRelease: _releaseAfterCompletion,
            onCompleted: () => widget.onCompleted?.call(),
          );
    _lease = soriVideoLease.register(
      asset: widget.asset,
      eligible: false,
      prepare: (video) async {
        // 캐릭터 mp4 내장 트랙은 정책상 상시 무음 — 2개(greet_pawflash·perched)는
        // 트랙이 있지만 소리는 companion 채널 mp3 가 담당한다 (ADR-002 §11-정정).
        // audio-policy: exempt — 내장 트랙 상시 무음(정책), 채널 볼륨 아님
        await video.setVolume(0);
        await video.setLooping(widget.loop);
      },
      onGranted: _onGranted,
      onRevoked: _onRevoked,
      onFailed: _onFailed,
    );
    if (!widget.staticFallback) {
      _fallbackWatchdog = Timer(_kFallbackWatchdog, () {
        if (mounted && !_ready) {
          setState(() => _fallbackDue = true);
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _eligibility.attach(context);
    _syncEligibility();
    // 효과음은 영상 lease 와 **독립**으로, 위젯이 보이는 순간 바로 재생한다.
    // grant 를 기다리면 디코더 핸드오프가 느린 기기에서 워치독
    // (fallbackCompleteAfter)이 먼저 화면을 넘겨 소리가 통째로 사라진다
    // (2026-08-02 실기기: 까치 첫 인사 무음). reduce-motion 이어도 재생 —
    // "애니메이션 줄이기"는 움직임에 대한 설정이지 소리에 대한 설정이 아니다.
    if (_eligibility.isVisible(context)) {
      _playSfxOnce();
    }
    if (CharacterClipPlayer.videoUnavailable(context)) {
      _completion?.fallbackNeeded();
    }
  }

  void _syncEligibility() {
    if (!mounted) {
      return;
    }
    // 영상 경로가 **범주적으로 불가**하면(기기 미지원·reduce-motion·다크)
    // lease 를 아예 요청하지 않는다 — 다크에서 흰 매트를 multiply 하면 배경이
    // blendColor 단색 사각형으로 그대로 칠해지기 때문(multiply(#FFFFFF,C)==C).
    final unavailable = CharacterClipPlayer.videoUnavailable(context);
    _completion?.visibilityChanged(_eligibility.isVisible(context));
    final eligible =
        !unavailable &&
        _eligibility.isEligible(
          context,
          videoReady: TigerStageVideo.videoReady,
        );
    if (eligible) {
      _completion?.leaseRequested();
    }
    _lease?.setEligible(eligible);
    if (unavailable) {
      _completion?.fallbackNeeded();
    }
  }

  /// 동반 효과음 — 명시 지정([CharacterClipPlayer.sfxAsset])이 없으면
  /// 클립에서 자동 유도. 볼륨·on/off 는 [AudioPolicy] companion 채널이 결정한다.
  ///
  /// **루프 재생은 자동 유도를 무시한다** — [CharacterClips.sfxFor]의 인사·
  /// 축하음은 일회성 연출용인데, 같은 클립을 대기 루프로 쓰는 화면(구 캐릭터
  /// 선택 미리보기 tiger_rise, 프로필 초상 tigerStretch·magpieFlight)에서
  /// 마운트마다 소리가 반복 재생되는 사고가 났다(2026-08-02 실기기).
  Future<void> _playSfxOnce() async {
    final volume = AudioPolicy.instance.volumeFor(SoundChannel.companion);
    if (volume <= 0) return;
    final sfx =
        widget.sfxAsset ??
        (widget.loop ? null : CharacterClips.sfxFor(widget.asset));
    if (sfx == null) return;
    if (_sfxStarted) return;
    _sfxStarted = true;
    try {
      final audio = AudioPlayer();
      _audio = audio;
      await audio.setReleaseMode(ReleaseMode.release);
      await audio.play(AssetSource(sfx), volume: volume);
    } catch (_) {
      // 효과음은 항상 best-effort — 파일이 없으면 무음.
    }
  }

  void _onGranted(VideoPlayerController video) {
    _video = video;
    // 영상이 왔으니 워치독은 필요 없다. 이미 정적으로 메워 뒀다면
    // AnimatedSwitcher 가 크로스페이드로 영상에 넘긴다.
    _fallbackWatchdog?.cancel();
    _fallbackWatchdog = null;
    _fallbackDue = false;
    _completion?.leaseGranted();
    if (!widget.loop) {
      video.addListener(_onTick);
    }
    if (mounted) {
      setState(() {
        _ready = true;
        _failed = false;
      });
    }
    unawaited(video.play());
    unawaited(_playSfxOnce());
  }

  void _onRevoked() {
    _video?.removeListener(_onTick);
    _video = null;
    _ready = false;
    // 텍스처가 회수됐다(원샷 종료·다른 화면에 lease 양보 등). 여기서 폴백을
    // 켜 두지 않으면 `staticFallback:false` 인 곳은 자리가 빈칸으로 남는다
    // — 프로필 호랑이가 걸어 들어온 뒤 사라지던 경로가 정확히 이거였다.
    _fallbackDue = true;
    _completion?.leaseRevoked();
    if (mounted) {
      setState(() {});
    }
  }

  void _onFailed(Object _, StackTrace __) {
    _failed = true;
    if (mounted) {
      setState(() {});
    }
    unawaited(_playSfxOnce());
    _completion?.fallbackNeeded();
  }

  void _onTick() {
    final video = _video;
    final completion = _completion;
    if (video == null || completion == null) return;
    final v = video.value;
    if (completion.completeFromPlayback(
      isInitialized: v.isInitialized,
      duration: v.duration,
      isPlaying: v.isPlaying,
      position: v.position,
    )) {
      video.removeListener(_onTick);
    }
  }

  Future<void> _releaseAfterCompletion() async {
    // Remove the final texture immediately; coordinator disposal remains the
    // single native release path and is awaited before another owner creates.
    _onRevoked();
    final lease = _lease;
    _lease = null;
    if (lease != null) {
      await lease.release();
    }
  }

  @override
  void dispose() {
    _fallbackWatchdog?.cancel();
    _fallbackWatchdog = null;
    _completion?.dispose();
    _video?.removeListener(_onTick);
    _eligibility.disposeBinding();
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
    // 렌더 단계 잠금 — 테마가 라이트→다크로 바뀌는 프레임에 이미 승인된
    // 텍스처가 한 프레임 남아 크림 사각형이 번쩍이는 걸 막는다. 동시에 이
    // 호출이 Theme 의존성을 등록해 테마 전환 시 didChangeDependencies →
    // _syncEligibility 가 실제로 다시 돈다.
    final blocked = CharacterClipPlayer.videoUnavailable(context);
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: blocked || _failed || !_ready || video == null
            // `staticFallback:false` 는 "영상이 곧 뜬다"는 **가정**이다. 그
            // 가정이 깨지면(로드 실패·lease 미승인/회수·웹 디코더 지연)
            // 캐릭터 자리가 통째로 빈칸이 됐다 — Jin "호랑이가 안나와".
            // 실패했거나 워치독이 만료됐으면 폴백 설정과 무관하게 정적
            // 마스코트를 그리고, 영상이 뒤늦게 오면 크로스페이드로 넘긴다.
            ? (widget.staticFallback || _failed || _fallbackDue
                  ? Mascot(
                      kind: widget.fallbackKind ?? MascotPreference.kind.value,
                      emotion: widget.fallbackEmotion,
                      size: widget.size * 0.85,
                      animate: true,
                    )
                  // 정적 폴백 끔 → 투명. 흰 박스 대신 배경이 비친다.
                  : const SizedBox.shrink())
            : ClipRect(
                // Android(Skia + SurfaceTexture, Impeller off) 방어막 —
                // 모든 호출부가 이 한 곳에서 혜택을 본다.
                //
                // [ColorFiltered] 는 `alwaysNeedsCompositing` 이라 캔버스
                // saveLayer 가 아니라 **엔진 ColorFilterLayer** 를 만든다.
                // 그 결과 부모의 페인트가 [먼저 그린 형제 PictureLayer] →
                // [ColorFilterLayer(외부 텍스처)] → [나중 형제 PictureLayer]
                // 로 쪼개지고, Skia GL 경로에서는 그 레이어가 saveLayer 를
                // 열어 안드로이드 외부(OES) 텍스처를 그 안에 그린다.
                //
                // 실기기(M2101K6G/Android 12, 2026-08-06)에서 영상이 재생되는
                // 순간 **먼저 그려진 형제**(로고·스트릭/레벨 칩·설정 아이콘·
                // 인사말·말풍선)가 통째로 사라졌다. 나중에 그려지는 것은 멀쩡.
                // = saveLayer 해소가 자기 사각형 밖까지 덮어쓴 모양새다.
                // 홈은 paint 순서를 뒤집어(`verticalDirection: up`) 피했지만
                // 그건 홈에서만 가능한 회피라 나머지 호출부는 무방비였다.
                //
                // hardEdge ClipRect 는 saveLayer 를 열지 않는 **GPU scissor**
                // 라서 비용은 레이어 1개뿐이고, ColorFilterLayer 의 saveLayer
                // 보다 **먼저** 적용돼 그 파괴 반경을 영상 사각형 안으로
                // 묶어 둔다. 픽셀 변화는 0 — 자식은 이미 정확히 이 정사각
                // 크기이고, 가장자리는 흰 매트라 multiply 결과가 배경색과
                // 같은 `blendColor` 다.
                //
                // ⚠️ never-cage 규칙 위반 아님: 영상 자기 자신의 경계와
                //    정확히 일치하는 사각 클립이라 원형·둥근 모서리·테두리·
                //    여백을 전혀 만들지 않는다(ClipOval/ClipRRect 아님).
                // ⚠️ 근본 원인 미확정 상태의 **완화책**이다. 다음 실기기
                //    빌드에서도 헤더가 사라지면 원인은 Skia clip 바깥의 GL
                //    상태 오염이라는 뜻 → mp4 매트를 크림으로 재출력해
                //    [ColorFiltered] 자체를 없애는 게 확정 수순이다.
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    widget.blendColor,
                    BlendMode.multiply,
                  ),
                  child: VideoPlayer(video),
                ),
              ),
      ),
    );
  }
}
