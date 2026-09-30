import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/hangul_data.dart';
import 'package:ko_lernen_app/services/tts_recorded_jamo.dart';
import 'package:ko_lernen_app/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('each recorded letter has a valid bundled MP3', () async {
    expect(TtsRecordedJamo.letters.length, 3);
    expect(TtsRecordedJamo.hasLetter('ㄷ'), isTrue);
    expect(TtsRecordedJamo.hasLetter('ㅇ'), isFalse);
    expect(TtsRecordedJamo.hasLetter('ㅡ'), isTrue);
    expect(TtsRecordedJamo.hasLetter('ㅢ'), isTrue);
    expect(TtsRecordedJamo.hasCarrier('드'), isTrue);
    expect(TtsRecordedJamo.hasCarrier('으'), isTrue);
    expect(TtsRecordedJamo.hasCarrier('의'), isTrue);
    expect(TtsRecordedJamo.hasCarrier('가'), isFalse);
    for (final letter in TtsRecordedJamo.letters) {
      final carrier = speakableJamo(letter);
      final bytes = await TtsRecordedJamo.bytesForCarrier(carrier);
      expect(bytes, isNotNull, reason: '$letter -> $carrier');
      expect(TtsCacheKey.isUsableAudio(bytes!), isTrue);
    }
  });

  test('other unreviewed vowels are never selected as recordings', () async {
    expect(await TtsRecordedJamo.bytesForCarrier('아'), isNull);
  });

  test('a missing recording never falls back to rejected TTS', () async {
    final audio = await TtsService.resolveAudioForTesting(
      '아',
      TtsRecordedJamo.voiceTag,
    );
    expect(audio, isNull);
  });

  test(
    'explicit recorded voice resolves locally before the TTS cache',
    () async {
      expect(
        TtsVoicePolicy.resolve(text: '드', voice: TtsRecordedJamo.voiceTag),
        TtsRecordedJamo.voiceTag,
      );
      for (final carrier in ['드', '으', '의']) {
        final audio = await TtsService.resolveAudioForTesting(
          carrier,
          TtsRecordedJamo.voiceTag,
        );
        expect(audio?.bytes, isNotNull, reason: carrier);
        expect(audio?.path, isNull, reason: carrier);
      }
    },
  );
}
