import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'mascot.dart';
import 'tiger_video.dart';
import 'tokens.dart';

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
  static const String tigerBob = '$_base/tiger_bob.mp4'; // 게임 대기 바운스
  static const String tigerStretch = '$_base/tiger_stretch.mp4'; // 세션 완료
  static const String tigerThinking = '$_base/tiger_thinking.mp4'; // 퀴즈 생각
  static const String tigerChoose = '$_base/tiger_choose.mp4'; // 선택 확정 목례
  static const String tigerGreetPawflash =
      '$_base/tiger_greet_pawflash.mp4'; // 첫 인사 — 앞발 번쩍
  static const String tigerRoarSeatedBonus =
      '$_base/tiger_roar_seated_bonus.mp4';

  // ── 까치 ────────────────────────────────────────────────
  static const String magpieFlight = '$_base/magpie_flight.mp4'; // 인트로 비행
  static const String magpieCelebrate =
      '$_base/magpie_celebrate.mp4'; // 정답 축하
  static const String magpieWorry = '$_base/magpie_worry.mp4'; // 오답 위로
  static const String magpiePerched = '$_base/magpie_perched.mp4'; // 듣기 대기
  static const String magpieMoon = '$_base/magpie_moon.mp4'; // 프로필 초상(달)
  static const String magpieChoose = '$_base/magpie_choose.mp4'; // 선택 확정 착지
  static const String magpieGreetChirp =
      '$_base/magpie_greet_chirp.mp4'; // 첫 인사 — 신나는 짹짹

  /// 첫 인사 클립 (말 없이 — 동물 몸짓만; 소리는 별도 SFX 훅).
  static String greetFor(MascotKind kind) => kind == MascotKind.magpie
      ? magpieGreetChirp
      : tigerGreetPawflash;

  /// 선택 확정 클립.
  static String chooseFor(MascotKind kind) =>
      kind == MascotKind.magpie ? magpieChoose : tigerChoose;

  /// 게임 종료 피드백 클립 — [GameOverCard] 등 결과 카드용.
  ///
  /// 감정에 맞는 클립이 없는 조합(예: 호랑이 worry)은 null → 호출측이
  /// 기존 정적 [Mascot]을 그대로 쓴다. [newBest]면 호랑이는 하이파이브
  /// 대신 앉은 포효(신기록 보너스 연출).
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
/// - [sfxAsset]: 클립 시작과 동시에 best-effort로 재생할 효과음
///   (예: 'sfx/greet_tiger.mp3'). 파일이 없거나 실패해도 조용히 무시.
class CharacterClipPlayer extends StatefulWidget {
  final String asset;
  final double size;
  final bool loop;
  final Color blendColor;
  final MascotKind fallbackKind;
  final MascotEmotion fallbackEmotion;
  final VoidCallback? onCompleted;
  final Duration fallbackCompleteAfter;
  final String? sfxAsset;

  const CharacterClipPlayer({
    super.key,
    required this.asset,
    this.size = 180,
    this.loop = false,
    this.blendColor = SoriColors.lightBg,
    this.fallbackKind = MascotKind.tiger,
    this.fallbackEmotion = MascotEmotion.smile,
    this.onCompleted,
    this.fallbackCompleteAfter = const Duration(milliseconds: 1200),
    this.sfxAsset,
  });

  @override
  State<CharacterClipPlayer> createState() => _CharacterClipPlayerState();
}

class _CharacterClipPlayerState extends State<CharacterClipPlayer> {
  VideoPlayerController? _video;
  AudioPlayer? _audio;
  bool _initStarted = false;
  bool _ready = false;
  bool _failed = false;
  bool _completedFired = false;
  Timer? _fallbackTimer;

  bool _live(BuildContext context) =>
      TigerStageVideo.videoReady && !SoriMotion.reduceMotion(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initStarted) return;
    _initStarted = true;
    if (_live(context)) {
      _init();
    } else {
      _armFallbackCompletion();
    }
  }

  /// 폴백(정적 이미지) 경로에서도 원샷 시맨틱 보장.
  void _armFallbackCompletion() {
    if (widget.loop || widget.onCompleted == null) return;
    _fallbackTimer = Timer(widget.fallbackCompleteAfter, _fireCompleted);
  }

  void _fireCompleted() {
    if (_completedFired) return;
    _completedFired = true;
    widget.onCompleted?.call();
  }

  Future<void> _init() async {
    final video = VideoPlayerController.asset(widget.asset);
    _video = video;
    try {
      await video.initialize();
      await video.setVolume(0);
      await video.setLooping(widget.loop);
    } catch (_) {
      if (mounted) {
        setState(() => _failed = true);
      } else {
        _failed = true;
      }
      _armFallbackCompletion();
      return;
    }
    if (!mounted) return;
    if (!widget.loop) {
      video.addListener(_onTick);
    }
    setState(() => _ready = true);
    await video.play();
    final sfx = widget.sfxAsset;
    if (sfx != null) {
      try {
        final audio = AudioPlayer();
        _audio = audio;
        await audio.play(AssetSource(sfx));
      } catch (_) {
        // 효과음은 항상 best-effort.
      }
    }
  }

  void _onTick() {
    final video = _video;
    if (video == null || _completedFired) return;
    final v = video.value;
    final done = v.isInitialized &&
        v.duration > Duration.zero &&
        !v.isPlaying &&
        v.position >= v.duration - const Duration(milliseconds: 80);
    if (done) {
      video.removeListener(_onTick);
      _fireCompleted();
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _video?.removeListener(_onTick);
    _video?.dispose();
    _audio?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    final live = _live(context) && !_failed;
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: !live
            ? Mascot(
                kind: widget.fallbackKind,
                emotion: widget.fallbackEmotion,
                size: widget.size * 0.85,
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
