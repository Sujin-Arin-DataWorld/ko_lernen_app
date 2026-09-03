import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/tts_canonical_manifest.dart';
import 'package:ko_lernen_app/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'real resolver ignores personal legacy disk bytes but keeps canonical disk hits',
    () async {
      final base = await Directory.systemTemp.createTemp('tts-privacy-test-');
      final cache = await Directory('${base.path}/tts_cache').create();
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => base.path);
      final personal = TtsCacheKey.forRequest(
        voice: 'female',
        text: '개인용 비공개 예문 7193',
      );
      final canonical = TtsCacheKey.forRequest(voice: 'female', text: '아');
      final bytes = [0x49, 0x44, 0x33, ...List.filled(40, 7)];
      await File('${cache.path}/${personal.localFileName}').writeAsBytes(bytes);
      await File(
        '${cache.path}/${canonical.localFileName}',
      ).writeAsBytes(bytes);
      try {
        expect(
          await TtsService.resolveAudioForTesting('개인용 비공개 예문 7193', 'female'),
          isNull,
        );
        final audio = await TtsService.resolveAudioForTesting('아', 'female');
        expect(audio?.path, '${cache.path}/${canonical.localFileName}');
      } finally {
        await TtsService.clearCacheStrict(cacheDirectory: () async => cache);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        await base.delete();
      }
    },
  );

  test('approved corpus manifest recognizes compatible v3 hash only', () async {
    final canonical = TtsCacheKey.forRequest(voice: 'female', text: '아');
    final personal = TtsCacheKey.forRequest(
      voice: 'female',
      text: '개인용 비공개 예문 7193',
    );
    expect(
      canonical.storagePath,
      'tts/v3/female/cad639c2539393f15c209d28e6fafca1a5b2f1fa.mp3',
    );
    expect(await TtsCanonicalManifest.contains(canonical), isTrue);
    expect(await TtsCanonicalManifest.contains(personal), isFalse);
  });
}
