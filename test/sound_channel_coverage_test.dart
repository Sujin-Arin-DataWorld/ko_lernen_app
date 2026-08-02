import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/audio_policy.dart';

// ADR-002 §6-3 — 채널 누락 방지. SoundChannel 값마다 설정 UI 라벨(de/en)과
// 기본값이 전부 있어야 한다. 새 채널을 추가하고 라벨을 잊으면 여기서 잡힌다.
void main() {
  const labelKeyOf = {
    SoundChannel.gameFeedback: 'settingsSoundGame',
    SoundChannel.companion: 'settingsSoundCompanion',
    SoundChannel.ambience: 'settingsSoundAmbience',
    SoundChannel.cinematic: 'settingsSoundCinematic',
    SoundChannel.speech: 'settingsSoundSpeech',
  };

  test('모든 채널: de/en 라벨 + 설명 키 존재', () {
    final de =
        jsonDecode(File('lib/l10n/app_de.arb').readAsStringSync())
            as Map<String, dynamic>;
    final en =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>;
    for (final c in SoundChannel.values) {
      final key = labelKeyOf[c];
      expect(key, isNotNull, reason: '새 채널 ${c.name} 의 라벨 키를 등록할 것');
      for (final arb in [de, en]) {
        expect(arb.containsKey(key), isTrue, reason: '$key 누락');
        expect(arb.containsKey('${key}Desc'), isTrue, reason: '${key}Desc 누락');
      }
    }
  });

  test('모든 채널: 기본 on/off + 기본 볼륨 정의 (ADR §3-1 표)', () {
    for (final c in SoundChannel.values) {
      final vol = AudioPolicy.defaultVolumeOf(c);
      expect(vol, inInclusiveRange(0.0, 1.0), reason: c.name);
      // ambience 만 기본 off — 나머지가 off 면 신규 사용자 무음 앱.
      expect(
        AudioPolicy.defaultOnOf(c),
        c != SoundChannel.ambience,
        reason: c.name,
      );
    }
  });
}
