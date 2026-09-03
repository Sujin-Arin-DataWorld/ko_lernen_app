import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'audio_policy.dart';

/// 경량 효과음(SFX) 재생기 — `gameFeedback` 채널.
///
/// `assets/sfx/{name}.wav` 를 재생한다. **에셋이 없거나 플랫폼이 지원하지 않으면
/// 조용히 무시(no-op)** — 앱은 정상 동작하고, Jin이 파일을 넣으면 자동으로 소리가
/// 난다. (errorBuilder 폴백과 같은 철학: 자산 누락이 크래시가 되지 않는다.)
///
/// 볼륨·on/off 는 전부 [AudioPolicy]가 결정한다 (ADR-002 §3) — 이 파일에 볼륨
/// 숫자를 다시 넣지 말 것 (`audio_policy_guard_test` 래칫).
///
/// 사운드는 "도파민 루프"의 한 레이어일 뿐이다 — 햅틱·콤보 카운터·XP 팝업·confetti는
/// 사운드와 무관하게 동작한다. 이 서비스는 청각 피드백만 담당한다.
class SoundService {
  SoundService._();

  /// 레거시 별칭 — 마스터 스위치. **읽기 전용** (대입 불가 — 컴파일러가 막는다).
  /// 신규 코드는 `AudioPolicy.instance.volumeFor(...)` 를 직접 쓸 것.
  static bool get enabled => AudioPolicy.instance.masterOn;

  /// 테스트 시임 — 설정되면 실제 AudioPlayer/에셋 없이 재생 요청을 기록만
  /// 한다(`SoriSpeech.speakImpl`과 같은 패턴). 프로덕션은 null.
  @visibleForTesting
  static void Function(String asset)? playImpl;
  @visibleForTesting
  static void resetForTesting() {
    playImpl = null;
  }

  /// 짧은 효과음 재생. fire-and-forget. 완료 시 player 자동 해제.
  static Future<void> _play(String asset) async {
    final hook = playImpl;
    if (hook != null) {
      hook(asset);
      return;
    }
    if (kIsWeb) {
      return;
    }
    final volume = AudioPolicy.instance.volumeFor(SoundChannel.gameFeedback);
    if (volume <= 0) {
      return;
    }
    AudioPlayer? player;
    try {
      player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.release);
      // 재생 완료 시 리소스 해제 (짧은 SFX라 누수 방지)
      player.onPlayerComplete.listen((_) {
        player?.dispose();
      });
      await player.play(AssetSource(asset), volume: volume);
    } catch (_) {
      // 에셋 없음 / 플랫폼 미지원 → 무음
      await player?.dispose();
    }
  }

  static void correct() => _play('sfx/correct.wav');
  static void wrong() => _play('sfx/wrong.wav');
  static void combo() => _play('sfx/combo.wav');
  static void levelUp() => _play('sfx/levelup.wav');
  static void complete() => _play('sfx/complete.wav');
}
