import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/tts_bundled_introduction.dart';
import 'package:ko_lernen_app/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(TtsBundledIntroduction.resetForTesting);
  tearDown(() {
    TtsBundledIntroduction.resetForTesting();
    TtsService.setApplicationCacheDirectoryForTesting(null);
    TtsService.setCanonicalDownloadForTesting(null);
  });

  test(
    'the default introduction voice resolves exact bundled 가 offline',
    () async {
      final voice = TtsVoicePolicy.resolve(text: '가');
      expect(voice, 'female');
      TtsService.setApplicationCacheDirectoryForTesting(() {
        fail('Bundled 가 must resolve before a disk cache is requested.');
      });
      TtsService.setCanonicalDownloadForTesting((_) {
        fail('Bundled 가 must resolve without Firebase or network.');
      });

      final audio = await TtsService.resolveAudioForTesting('가', voice);

      expect(audio?.bytes, isNotNull);
      expect(audio?.path, isNull);
      expect(
        sha256.convert(audio!.bytes!).toString(),
        TtsBundledIntroduction.audioSha256,
      );
    },
  );

  test('other voices and text never read the introduction asset', () async {
    final bundle = _ControlledBundle();
    TtsBundledIntroduction.resetForTesting(bundle: bundle);
    for (final request in [('male', '가'), ('female', '나')]) {
      expect(
        await TtsBundledIntroduction.bytesFor(
          TtsCacheKey.forRequest(voice: request.$1, text: request.$2),
        ),
        isNull,
      );
    }
    expect(bundle.requests, isEmpty);
  });

  test(
    'missing or changed bytes preserve existing resolution fallbacks',
    () async {
      final key = TtsCacheKey.forRequest(voice: 'female', text: '가');
      final missing = _ControlledBundle();
      TtsBundledIntroduction.resetForTesting(bundle: missing);
      missing.read.completeError(StateError('Asset missing'));
      expect(await TtsBundledIntroduction.bytesFor(key), isNull);

      final changed = _ControlledBundle();
      TtsBundledIntroduction.resetForTesting(bundle: changed);
      final bytes = Uint8List.fromList([
        0x49,
        0x44,
        0x33,
        ...List.filled(100, 0),
      ]);
      changed.read.complete(ByteData.sublistView(bytes));
      expect(await TtsBundledIntroduction.bytesFor(key), isNull);
    },
  );

  test(
    'navigation stop prevents a late bundled read from starting playback',
    () async {
      final data = await rootBundle.load(TtsBundledIntroduction.assetPath);
      final bundle = _ControlledBundle();
      TtsBundledIntroduction.resetForTesting(bundle: bundle);
      final platform = _PlaybackPlatform();
      final engine = TtsPlaybackEngine(
        resolveAudio: (text, voice) =>
            TtsService.resolveAudioForTesting(text, voice),
        platform: platform,
      );
      addTearDown(engine.dispose);

      final speech = engine.speak(text: '가', voice: 'female', baseRate: 0.42);
      await bundle.requested.future;
      await engine.stop();
      expect(await speech, isFalse);
      bundle.read.complete(data);
      await TtsBundledIntroduction.bytesFor(
        TtsCacheKey.forRequest(voice: 'female', text: '가'),
      );
      expect(platform.started, isEmpty);

      // The next owned request still uses those bytes and can complete normally.
      expect(
        await engine.speak(text: '가', voice: 'female', baseRate: 0.42),
        isTrue,
      );
      expect(platform.started, hasLength(1));
      expect(platform.started.single.bytes, isNotNull);
      expect(bundle.requests, [TtsBundledIntroduction.assetPath]);
    },
  );
}

class _ControlledBundle extends CachingAssetBundle {
  final read = Completer<ByteData>();
  final requested = Completer<void>();
  final requests = <String>[];

  @override
  Future<ByteData> load(String key) {
    requests.add(key);
    if (!requested.isCompleted) {
      requested.complete();
    }
    return read.future;
  }
}

class _PlaybackPlatform implements TtsPlaybackPlatform {
  final started = <TtsAudio>[];

  @override
  Future<TtsPlaybackSession> startAudio(TtsAudio audio, double rate) async {
    started.add(audio);
    return TtsPlaybackSession(Future.value(true));
  }

  @override
  Future<void> stop() async {}
}
