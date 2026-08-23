import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'storage_service.dart';

/// 소리 카테고리 — 실제 존재하는 소스에서만 뽑았다 (ADR-002 §3-1).
/// 없는 소리를 위한 카테고리는 만들지 않는다.
enum SoundChannel {
  /// correct/wrong/combo/levelup/complete.wav — 게임 피드백.
  gameFeedback,

  /// greet_*/celebrate_*.mp3 — 캐릭터(호랑이·까치) 원샷.
  companion,

  /// 루프 영상 8종의 내장 오디오. **기본 off** — 지금까지 한 번도 들린 적
  /// 없는 소리라, 업데이트 직후 갑자기 나오면 버그로 느껴진다.
  ambience,

  /// intro_gate_to_madang.mp4 — 실행당 1회 대문 인트로.
  cinematic,

  /// 한국어 발음 TTS — 장식이 아니라 학습 내용.
  speech,
}

/// 앱의 **유일한 볼륨 결정 지점** (ADR-002 §3).
///
/// 규칙: `lib/` 어디에도 볼륨 숫자 리터럴을 두지 않는다 — 전부 [volumeFor]를
/// 부른다. `test/audio_policy_guard_test.dart` 래칫이 이를 강제한다.
/// 예외가 필요한 줄은 `// audio-policy: exempt — <이유>` 주석을 단다.
///
/// 계산식 (ADR-002 §3-3):
/// ```
/// volumeFor(c, asset) =
///     (masterOn && isOn(c))
///         ? clamp01(masterVolume × sliderOf(c) × gainFor(asset)) × duckFactor(c)
///         : 0.0
/// ```
class AudioPolicy extends ChangeNotifier {
  AudioPolicy._();

  static final AudioPolicy instance = AudioPolicy._();

  // ── 채널 기본값 (ADR-002 §3-1 확정표) ────────────────────────────────
  // 기본값을 Storage getter 의 **인자로** 넘기는 게 핵심 — 저장값이 없을 때
  // false/0 으로 떨어지면 신규 사용자가 무음 앱을 받는다 (§3-4).
  static const Map<SoundChannel, bool> _defaultOn = {
    SoundChannel.gameFeedback: true,
    SoundChannel.companion: true,
    SoundChannel.ambience: false, // 유일한 기본 off
    SoundChannel.cinematic: true,
    SoundChannel.speech: true,
  };

  static const Map<SoundChannel, double> _defaultVol = {
    SoundChannel.gameFeedback: 0.55,
    SoundChannel.companion: 0.70,
    SoundChannel.ambience: 0.35,
    SoundChannel.cinematic: 0.80,
    SoundChannel.speech: 1.00,
  };

  /// Storage 키 조각 (`kl_snd_$id` / `kl_snd_${id}_vol`) — enum.name 그대로.
  static String idOf(SoundChannel c) => c.name;

  // ── 읽기 ─────────────────────────────────────────────────────────────
  bool get masterOn => Storage.sndMaster;
  double get masterVolume => Storage.sndMasterVol;
  bool isOn(SoundChannel c) => Storage.sndChannelOn(c.name, _defaultOn[c]!);
  double sliderOf(SoundChannel c) =>
      Storage.sndChannelVol(c.name, _defaultVol[c]!);
  bool get duckOnSpeech => Storage.sndDuck;
  bool get respectSilentMode => Storage.sndRespectSilent;

  /// 채널 기본 볼륨 (설정 UI 리셋·테스트용).
  static double defaultVolumeOf(SoundChannel c) => _defaultVol[c]!;

  /// 채널 기본 on/off (설정 UI·테스트용).
  static bool defaultOnOf(SoundChannel c) => _defaultOn[c]!;

  /// **호출부가 쓰는 유일한 함수.** 마스터·채널 on/off, 볼륨, 에셋 정규화
  /// 게인, 더킹을 전부 반영한 최종 0..1. 꺼져 있으면 정확히 0.0.
  double volumeFor(SoundChannel c, {String? asset}) {
    if (!masterOn || !isOn(c)) {
      return 0.0;
    }
    final v = _clamp01(masterVolume * sliderOf(c) * gainFor(asset));
    return v * _duckFactor(c);
  }

  // ── 쓰기 (Storage 저장 + notifyListeners) ────────────────────────────
  Future<void> setMasterOn(bool v) async {
    await Storage.setSndMaster(v);
    notifyListeners();
  }

  Future<void> setMasterVolume(double v) async {
    await Storage.setSndMasterVol(_clamp01(v));
    notifyListeners();
  }

  Future<void> setChannelOn(SoundChannel c, bool v) async {
    await Storage.setSndChannelOn(c.name, v);
    notifyListeners();
  }

  Future<void> setChannelVolume(SoundChannel c, double v) async {
    await Storage.setSndChannelVol(c.name, _clamp01(v));
    notifyListeners();
  }

  Future<void> setDuckOnSpeech(bool v) async {
    await Storage.setSndDuck(v);
    notifyListeners();
  }

  Future<void> setRespectSilentMode(bool v) async {
    await Storage.setSndRespectSilent(v);
    await applyPlatformAudioContext();
    notifyListeners();
  }

  // ── TTS 더킹 (ADR-002 §5) ────────────────────────────────────────────
  // TtsService 가 발화 시작/종료 시 아래 훅을 부른다 (audio_policy 는
  // tts_service 를 import 하지 않는다 — 순환 의존 회피).
  // 낮추는 건 ambience 뿐 — gameFeedback/companion 은 200~800ms 원샷이라
  // 정답음 직후 발음이 이어지는 흐름이 오히려 자연스럽다 (§5-1).
  bool _duckActive = false;
  Timer? _duckRestore;

  @visibleForTesting
  bool get duckActive => _duckActive;

  void noteSpeechStarted() {
    _duckRestore?.cancel();
    _duckRestore = null;
    if (!_duckActive) {
      _duckActive = true;
      notifyListeners();
    }
  }

  /// 복원은 200ms 지연 — 문장을 연달아 읽을 때 사이사이 볼륨이 출렁이는 걸
  /// 막는다 (§5-2).
  /// 지연 없이 즉시 복원한다. **명시적 정지**(`TtsService.stop`)용.
  ///
  /// [noteSpeechEnded] 의 200ms 지연은 문장을 연달아 읽을 때 사이사이 볼륨이
  /// 출렁이는 걸 막으려는 것이다. 사용자가·화면이 재생을 끊은 경우엔 이어질
  /// 다음 문장이 없으니 기다릴 이유가 없고, 오히려 주인 없는 타이머만 남는다
  /// (화면이 dispose 된 뒤에도 타이머가 살아 있는 걸 flutter_test 가 잡아냈다).
  void restoreDuckNow() {
    _duckRestore?.cancel();
    _duckRestore = null;
    if (_duckActive) {
      _duckActive = false;
      notifyListeners();
    }
  }

  void noteSpeechEnded() {
    _duckRestore?.cancel();
    _duckRestore = Timer(const Duration(milliseconds: 200), () {
      _duckActive = false;
      notifyListeners();
    });
  }

  double _duckFactor(SoundChannel c) {
    if (_duckActive && duckOnSpeech && c == SoundChannel.ambience) {
      return 0.25; // −12 dB (§5-2)
    }
    return 1.0;
  }

  // ── 에셋 정규화 게인 (ADR-002 §4, ambience 기준 −40 dB) ──────────────
  // gain = min(1, 10^((−40 − mean_dB) / 20)). 표에 없으면 1.0.
  // 값은 ADR-002 §4 의 ffmpeg 실측표. ⚠️ §4-1 의 자동화(tool/measure_audio_gain.py
  // → audio_gain_report.json → 계약 테스트)는 ambience 화면 배선(§9-6)과 함께
  // 도입 예정 — 새 루프 영상을 추가하면 이 표도 갱신해야 한다.
  static const Map<String, double> _ambienceGain = {
    'assets/video/loops/hanok_construction.mp4': 0.095,
    'assets/video/loops/kkeunmari_hero.mp4': 0.226,
    'assets/video/loops/hanok_jongga.mp4': 0.575,
    'assets/video/loops/welcome-hero.mp4': 0.596,
    // study_scholar(−40.0)·study_classroom(−45.8)·porch(−48.6) → 1.0 클램프
    // (video_player 는 감쇠만 가능, 증폭 불가 — 기준 이하 원본은 그대로).
  };

  @visibleForTesting
  static double gainFor(String? asset) =>
      asset == null ? 1.0 : (_ambienceGain[asset] ?? 1.0);

  // ── 플랫폼 오디오 세션 (ADR-002 §5-3) ────────────────────────────────
  /// Android 전역 컨텍스트. **항상 `USAGE_MEDIA`** 다.
  ///
  /// ⛔ `AudioContextConfig(respectSilence: true).buildAndroid()` 를 쓰면 안 된다.
  /// 그 플래그는 Android 에서 "무음 스위치 존중"이 아니라
  /// `usageType: USAGE_NOTIFICATION_RINGTONE` 으로 번역된다
  /// (audioplayers `audio_context_config.dart` → `AudioContextAndroid`
  /// → `AudioAttributes.setUsage`). 즉 앱의 **모든 소리가 벨소리 스트림**으로
  /// 나간다 — 폰이 진동/무음이거나 벨 볼륨만 낮아도 효과음·발음이 전부 안
  /// 들리고, 사용자가 볼륨 키를 눌러 조절하는 미디어 볼륨은 아무 효과가 없다.
  /// ADR-002 §10 이 "Android 는 respectSilence 가 기기마다 다름 — 실기기 미검증"
  /// 으로 남겨 뒀던 항목이며, 2026-08-19 Jin 의 Android 실기기에서
  /// **효과음·발음 전부 무음**으로 재현됐다.
  ///
  /// Android 에서 무음/방해금지 존중은 시스템(미디어 볼륨·DND)이 이미 한다.
  /// [respectSilentMode] 는 **iOS 무음 스위치 전용 설정**으로 남긴다.
  @visibleForTesting
  static AudioContextAndroid buildAndroidContext() => AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
    // ⛔ respectSilence 를 여기에 넣지 말 것 (위 주석 참조).
  ).buildAndroid();

  /// 전역 audioplayers 컨텍스트: SFX 가 사용자의 음악(Spotify 등)을 끊지
  /// 않게 mixWithOthers + (iOS 만) 무음 스위치 존중. main.dart 초기화와
  /// [setRespectSilentMode] 변경 시 호출.
  ///
  /// TTS(speech)는 duckOthers 가 맞지만 iOS 에서 respectSilence 와 병용이
  /// 금지라(playAndRecord 강제) TtsService 쪽 플레이어에 별도 컨텍스트로 건다.
  Future<void> applyPlatformAudioContext() async {
    if (kIsWeb) {
      return;
    }
    try {
      // ⚠️ iOS 는 mixWithOthers 옵션 + respectSilence 조합을 라이브러리가
      // 금지(validateIOS assert — playAndRecord 강제 문제)하므로
      // AudioContextConfig.build() 를 통째로 쓰지 않고 iOS 쪽만 직접 구성한다:
      // ambient 카테고리 자체가 "타 앱과 mix + 무음 스위치 존중"이다.
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: buildAndroidContext(),
          iOS: respectSilentMode
              ? AudioContextIOS(
                  category: AVAudioSessionCategory.ambient,
                  options: const {},
                )
              : AudioContextIOS(
                  category: AVAudioSessionCategory.playback,
                  options: const {AVAudioSessionOptions.mixWithOthers},
                ),
        ),
      );
    } catch (_) {
      // best-effort — 플랫폼 미지원 시 기존 기본값으로 동작.
    }
  }

  static double _clamp01(double v) => v < 0.0 ? 0.0 : (v > 1.0 ? 1.0 : v);

  @override
  void dispose() {
    _duckRestore?.cancel();
    super.dispose();
  }
}
