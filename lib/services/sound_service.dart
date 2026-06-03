import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// 경량 효과음(SFX) 재생기.
///
/// `assets/sfx/{name}.mp3` 를 재생한다. **에셋이 없거나 플랫폼이 지원하지 않으면
/// 조용히 무시(no-op)** — 앱은 정상 동작하고, Jin이 mp3를 넣으면 자동으로 소리가 난다.
/// (errorBuilder 폴백과 같은 철학: 자산 누락이 크래시가 되지 않는다.)
///
/// 사운드는 "도파민 루프"의 한 레이어일 뿐이다 — 햅틱·콤보 카운터·XP 팝업·confetti는
/// 사운드와 무관하게 동작한다. 이 서비스는 청각 피드백만 담당한다.
class SoundService {
  SoundService._();

  /// 사용자 설정(설정 화면 토글)에서 켜고 끌 수 있게 노출. 기본 on.
  static bool enabled = true;

  /// 짧은 효과음 재생. fire-and-forget. 완료 시 player 자동 해제.
  static Future<void> _play(String asset, {double volume = 0.55}) async {
    if (!enabled || kIsWeb) {
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
  static void combo() => _play('sfx/combo.wav', volume: 0.6);
  static void levelUp() => _play('sfx/levelup.wav', volume: 0.65);
  static void complete() => _play('sfx/complete.wav', volume: 0.65);
}
