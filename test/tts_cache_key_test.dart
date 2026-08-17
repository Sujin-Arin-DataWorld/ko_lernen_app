import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/tts_service.dart';

void main() {
  test('v3 cache keys isolate newly synthesized audio from old objects', () {
    final key = TtsCacheKey.forRequest(voice: 'female', text: '안녕하세요');

    expect(key.revision, 'v3');
    expect(key.hash, 'd84734f7d89bbd707dc52168c47309aed72b7f80');
    expect(
      key.storagePath,
      'tts/v3/female/d84734f7d89bbd707dc52168c47309aed72b7f80.mp3',
    );
    expect(
      key.localFileName,
      'tts_v3_female_d84734f7d89bbd707dc52168c47309aed72b7f80.mp3',
    );
  });

  test('unknown voices normalize to the supported female cache namespace', () {
    final key = TtsCacheKey.forRequest(voice: 'unknown', text: '테스트');

    expect(key.voice, 'female');
    expect(key.storagePath, startsWith('tts/v3/female/'));
  });

  test('usable audio requires a real MP3 header, not just non-empty bytes', () {
    final mp3 = List<int>.filled(32, 0);
    mp3[0] = 0xFF;
    mp3[1] = 0xFB;
    final tagged = List<int>.filled(32, 0);
    tagged[0] = 0x49;
    tagged[1] = 0x44;
    tagged[2] = 0x33;

    expect(TtsCacheKey.isUsableAudio(<int>[]), isFalse);
    expect(TtsCacheKey.isUsableAudio(<int>[0xFF, 0xFB]), isFalse);
    expect(TtsCacheKey.isUsableAudio(List<int>.filled(32, 1)), isFalse);
    expect(TtsCacheKey.isUsableAudio(mp3), isTrue);
    expect(TtsCacheKey.isUsableAudio(tagged), isTrue);
  });

  test('dynamic synthesis uses the authenticated callable transport', () {
    final source = File('lib/services/tts_service.dart').readAsStringSync();

    expect(source, contains('FirebaseFunctions.instanceFor'));
    expect(source, contains('limitedUseAppCheckToken: true'));
    expect(source, contains('installationId: installationId'));
    expect(
      source,
      contains('static const Duration _netTimeout = Duration(seconds: 12)'),
    );
    expect(source, contains('TtsCacheKey.isUsableAudio(localBytes)'));
    expect(source, contains('TtsSynthesisBlocked'));
    expect(source, contains('already in progress'));
    expect(source, contains('resource-exhausted'));
    expect(source, contains('TTS audio is not available.'));
    expect(source, isNot(contains('http.post(')));
  });

  test('takeCallableAudio blocks quota and does not retry a completed miss', () async {
    TtsService.lastError = null;
    var quotaCalls = 0;
    await expectLater(
      TtsService.takeCallableAudio(
        invoke: () async {
          quotaCalls += 1;
          throw const TtsCallableProbe(
            code: 'resource-exhausted',
            message: TtsCallableFailure.quotaMessage,
          );
        },
      ),
      throwsA(isA<TtsSynthesisBlocked>()),
    );
    expect(quotaCalls, 1);
    expect(TtsService.lastError, TtsCallableFailure.quotaMessage);

    TtsService.lastError = null;
    var missCalls = 0;
    await expectLater(
      TtsService.takeCallableAudio(
        invoke: () async {
          missCalls += 1;
          throw const TtsCallableProbe(
            code: 'unavailable',
            message: TtsCallableFailure.audioUnavailableMessage,
          );
        },
      ),
      throwsA(isA<TtsSynthesisBlocked>()),
    );
    expect(missCalls, 1);
    expect(TtsService.lastError, TtsCallableFailure.audioUnavailableMessage);
  });

  test('takeCallableAudio retries inflight then returns usable audio', () async {
    var calls = 0;
    final mp3 = Uint8List.fromList(List<int>.filled(32, 0)..[0] = 0xFF..[1] = 0xFB);
    final bytes = await TtsService.takeCallableAudio(
      invoke: () async {
        calls += 1;
        if (calls < 2) {
          throw const TtsCallableProbe(
            code: 'unavailable',
            message: TtsCallableFailure.alreadyInProgressMessage,
          );
        }
        return mp3;
      },
    );
    expect(calls, 2);
    expect(bytes, mp3);
  });

  test('callable failures retry only inflight and block empty completed audio', () {
    expect(
      TtsCallableFailure.classify(
        code: 'unavailable',
        message: TtsCallableFailure.alreadyInProgressMessage,
      ),
      TtsCallableKind.retryInflight,
    );
    expect(
      TtsCallableFailure.classify(
        code: 'unavailable',
        message: TtsCallableFailure.audioUnavailableMessage,
      ),
      TtsCallableKind.blockUnavailable,
    );
    expect(
      TtsCallableFailure.classify(
        code: 'resource-exhausted',
        message: TtsCallableFailure.quotaMessage,
      ),
      TtsCallableKind.blockQuota,
    );
    expect(
      TtsCallableFailure.classify(
        code: 'unavailable',
        message: 'TTS synthesis is temporarily unavailable.',
      ),
      TtsCallableKind.fallback,
    );
  });
}
