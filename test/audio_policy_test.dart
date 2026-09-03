import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/audio_policy.dart';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ADR-002 §6-1 — AudioPolicy 순수 로직 + 기본값 회귀 + 더킹.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final policy = AudioPolicy.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test('기본값 회귀 — 저장값 없을 때 신규 사용자가 무음 앱을 받지 않는다', () {
    expect(policy.masterOn, isTrue);
    expect(
      policy.isOn(SoundChannel.speech),
      isTrue,
      reason: 'speech 기본 off 면 발음이 안 나온다 (ADR §6-1)',
    );
    expect(policy.isOn(SoundChannel.gameFeedback), isTrue);
    expect(policy.isOn(SoundChannel.companion), isTrue);
    expect(policy.isOn(SoundChannel.cinematic), isTrue);
    expect(
      policy.isOn(SoundChannel.ambience),
      isFalse,
      reason: 'ambience 만 기본 off (ADR §3-1)',
    );
    expect(policy.volumeFor(SoundChannel.speech), 1.0);
    expect(policy.volumeFor(SoundChannel.gameFeedback), closeTo(0.55, 1e-9));
    expect(policy.volumeFor(SoundChannel.companion), closeTo(0.70, 1e-9));
    expect(policy.volumeFor(SoundChannel.cinematic), closeTo(0.80, 1e-9));
    expect(policy.volumeFor(SoundChannel.ambience), 0.0);
  });

  test('마스터 off → 모든 채널 volumeFor == 0.0', () async {
    await policy.setMasterOn(false);
    for (final c in SoundChannel.values) {
      expect(policy.volumeFor(c), 0.0, reason: c.name);
    }
    await policy.setMasterOn(true);
    expect(policy.volumeFor(SoundChannel.speech), 1.0);
  });

  test('채널 off → 그 채널만 0.0, 나머지 불변', () async {
    await policy.setChannelOn(SoundChannel.gameFeedback, false);
    expect(policy.volumeFor(SoundChannel.gameFeedback), 0.0);
    expect(policy.volumeFor(SoundChannel.companion), closeTo(0.70, 1e-9));
    expect(policy.volumeFor(SoundChannel.speech), 1.0);
  });

  test('gameFeedback 채널이 음소거면 SoundService가 playImpl을 부르지 않는다 (M4)', () async {
    // 테스트 시임이 볼륨 게이트보다 먼저 있으면 음소거 채널이 관측 불가능
    // 해진다 — 시임이 실제 AudioPlayer 호출 대신 훅을 부르는 코드이므로,
    // 게이트 자체를 우회해버린다.
    final played = <String>[];
    SoundService.playImpl = played.add;
    addTearDown(SoundService.resetForTesting);

    await policy.setChannelOn(SoundChannel.gameFeedback, false);
    SoundService.correct();

    expect(
      played,
      isEmpty,
      reason: 'volumeFor(gameFeedback) <= 0 이면 playImpl도 호출되면 안 된다',
    );
  });

  test('슬라이더 0 → on 이어도 0.0', () async {
    await policy.setChannelVolume(SoundChannel.companion, 0);
    expect(policy.isOn(SoundChannel.companion), isTrue);
    expect(policy.volumeFor(SoundChannel.companion), 0.0);
  });

  test('볼륨 1.5 / −0.2 입력 → 1.0 / 0.0 클램프', () async {
    await policy.setChannelVolume(SoundChannel.speech, 1.5);
    expect(policy.sliderOf(SoundChannel.speech), 1.0);
    await policy.setChannelVolume(SoundChannel.speech, -0.2);
    expect(policy.sliderOf(SoundChannel.speech), 0.0);
    await policy.setMasterVolume(2.0);
    expect(policy.masterVolume, 1.0);
  });

  test('asset 미지정·미등록 → 게인 1.0 (크래시 아님)', () {
    expect(AudioPolicy.gainFor(null), 1.0);
    expect(AudioPolicy.gainFor('assets/video/loops/unknown.mp4'), 1.0);
    expect(
      AudioPolicy.gainFor('assets/video/loops/hanok_construction.mp4'),
      closeTo(0.095, 1e-9),
    );
  });

  test('ambience 게인 — volumeFor 가 마스터×슬라이더×게인을 곱한다', () async {
    await policy.setChannelOn(SoundChannel.ambience, true);
    await policy.setChannelVolume(SoundChannel.ambience, 1.0);
    expect(
      policy.volumeFor(
        SoundChannel.ambience,
        asset: 'assets/video/loops/hanok_construction.mp4',
      ),
      closeTo(0.095, 1e-9),
    );
    await policy.setChannelOn(SoundChannel.ambience, false);
  });

  test('Storage 왕복 — set 후 재읽기 일치 + kl_snd_* 키 스킴', () async {
    await policy.setChannelOn(SoundChannel.ambience, true);
    await policy.setChannelVolume(SoundChannel.ambience, 0.5);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('kl_snd_ambience'), isTrue);
    expect(prefs.getDouble('kl_snd_ambience_vol'), 0.5);
    expect(policy.isOn(SoundChannel.ambience), isTrue);
    expect(policy.sliderOf(SoundChannel.ambience), 0.5);
    await policy.setChannelOn(SoundChannel.ambience, false);
  });

  test('더킹 — speech 중 ambience 만 ×0.25, 종료 200ms 뒤 복원 (ADR §5)', () async {
    await policy.setChannelOn(SoundChannel.ambience, true);
    await policy.setChannelVolume(SoundChannel.ambience, 1.0);
    final base = policy.volumeFor(SoundChannel.ambience);
    final game = policy.volumeFor(SoundChannel.gameFeedback);

    policy.noteSpeechStarted();
    expect(policy.duckActive, isTrue);
    expect(policy.volumeFor(SoundChannel.ambience), closeTo(base * 0.25, 1e-9));
    expect(
      policy.volumeFor(SoundChannel.gameFeedback),
      game,
      reason: '원샷 SFX 는 더킹하지 않는다 (ADR §5-1)',
    );

    policy.noteSpeechEnded();
    expect(policy.duckActive, isTrue, reason: '복원은 200ms 지연');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(policy.duckActive, isFalse);
    expect(policy.volumeFor(SoundChannel.ambience), base);
    await policy.setChannelOn(SoundChannel.ambience, false);
  });

  // ── Android 라우팅 래칫 (2026-08-19 실기기 무음 회귀) ──────────────────
  //
  // audioplayers 의 `respectSilence` 는 Android 에서 "무음 스위치 존중"이
  // 아니라 `USAGE_NOTIFICATION_RINGTONE` 으로 번역된다 → 앱의 모든 소리가
  // 벨소리 스트림으로 나가고, 폰이 진동/무음이면 효과음·발음이 전부 안 들린다.
  // (Jin Android 실기기, 2026-08-19: 효과음·TTS 모두 무음.)
  test('Android 전역 컨텍스트는 respectSilent 와 무관하게 USAGE_MEDIA', () async {
    final ringtone = AudioContextConfig(
      respectSilence: true,
    ).buildAndroid().usageType;

    for (final respectSilent in [true, false]) {
      await AudioPolicy.instance.setRespectSilentMode(respectSilent);
      final android = AudioPolicy.buildAndroidContext();
      expect(
        android.usageType,
        isNot(ringtone),
        reason:
            'respectSilent=$respectSilent 에서 벨소리 스트림으로 라우팅되면 '
            '진동 모드의 Android 기기가 앱 전체 무음이 된다',
      );
      expect(
        android.usageType,
        AudioContextConfig().buildAndroid().usageType,
        reason: 'Android 는 항상 미디어 스트림(USAGE_MEDIA)',
      );
    }
    await AudioPolicy.instance.setRespectSilentMode(true);
  });

  test('Android 컨텍스트는 타 앱 음악을 끊지 않는다 (mixWithOthers 유지)', () {
    expect(
      AudioPolicy.buildAndroidContext().audioFocus,
      AudioContextConfig(
        focus: AudioContextConfigFocus.mixWithOthers,
      ).buildAndroid().audioFocus,
    );
  });
}
