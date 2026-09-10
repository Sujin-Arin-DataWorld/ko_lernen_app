import 'dart:async';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/audio_policy.dart';
import 'package:ko_lernen_app/services/tts_bundled_manifest.dart';
import 'package:ko_lernen_app/services/tts_canonical_manifest.dart';
import 'package:ko_lernen_app/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  late Directory sandbox;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('tts_cache_recovery_');
    TtsBundledManifest.resetForTesting();
    TtsService.resetPrefetchMemoForTesting();
    TtsService.setPrefetchResolverForTesting(null);
    TtsService.setCanonicalDownloadForTesting(null);
    TtsService.setCacheDirForTesting(null);
    await AudioPolicy.instance.setMasterVolume(1);
    await AudioPolicy.instance.setChannelVolume(SoundChannel.speech, 1);
  });

  tearDown(() async {
    TtsService.setPrefetchResolverForTesting(null);
    TtsService.setCanonicalDownloadForTesting(null);
    await TtsService.clearCacheStrict(cacheDirectory: () async => sandbox);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, null);
    if (await sandbox.exists()) {
      await sandbox.delete(recursive: true);
    }
  });

  test('a null prefetch result is retried on the next request', () async {
    var resolutions = 0;
    TtsService.setPrefetchResolverForTesting((_, __) async {
      resolutions++;
      return resolutions == 1 ? null : TtsAudio.bytes(_validMp3());
    });

    await TtsService.prefetch('  다시 시도해요  ', voice: 'female');
    await TtsService.prefetch('다시 시도해요', voice: 'female');

    expect(resolutions, 2);
  });

  test('a successful prefetch suppresses later duplicate requests', () async {
    var resolutions = 0;
    TtsService.setPrefetchResolverForTesting((_, __) async {
      resolutions++;
      return TtsAudio.bytes(_validMp3());
    });

    await TtsService.prefetch('한 번만 받아요', voice: 'female');
    await TtsService.prefetch('한 번만 받아요', voice: 'female');

    expect(resolutions, 1);
  });

  test('concurrent duplicate prefetches share the in-flight attempt', () async {
    var resolutions = 0;
    final pending = Completer<TtsAudio?>();
    TtsService.setPrefetchResolverForTesting((_, __) {
      resolutions++;
      return pending.future;
    });

    final first = TtsService.prefetch('같이 받아요', voice: 'male');
    final duplicate = TtsService.prefetch('같이 받아요', voice: 'male');
    await Future<void>.delayed(Duration.zero);

    expect(resolutions, 1);
    pending.complete(TtsAudio.bytes(_validMp3()));
    await Future.wait([first, duplicate]);
  });

  test('a prefetch exception is retried on the next request', () async {
    var resolutions = 0;
    TtsService.setPrefetchResolverForTesting((_, __) async {
      resolutions++;
      if (resolutions == 1) {
        throw StateError('temporary failure');
      }
      return TtsAudio.bytes(_validMp3());
    });

    await TtsService.prefetch('예외 뒤 재시도', voice: 'male');
    await TtsService.prefetch('예외 뒤 재시도', voice: 'male');

    expect(resolutions, 2);
  });

  test(
    'canonical download bytes survive an atomic disk-write failure and are reused',
    () async {
      const text = '먹지 않아요.';
      const voice = 'female';
      final key = TtsCacheKey.forRequest(voice: voice, text: text);
      final target = File('${sandbox.path}/${key.localFileName}');
      final blockedPart = Directory('${target.path}.part');
      await blockedPart.create();
      var downloads = 0;
      final bytes = _validMp3(marker: 7);
      TtsService.setCacheDirForTesting(sandbox);
      TtsService.setCanonicalDownloadForTesting((requested) async {
        expect(requested.storagePath, key.storagePath);
        downloads++;
        return bytes;
      });

      final first = await TtsService.resolveAudioForTesting(
        text,
        voice,
        allowSynthesis: true,
      );
      final second = await TtsService.resolveAudioForTesting(
        text,
        voice,
        allowSynthesis: true,
      );

      expect(first?.path, isNull);
      expect(first?.bytes, orderedEquals(bytes));
      expect(second?.bytes, orderedEquals(bytes));
      expect(downloads, 1, reason: 'the second lookup must use memory');
      expect(await target.exists(), isFalse);
      expect(await blockedPart.exists(), isTrue);
    },
  );

  test(
    'a missing cache directory still returns canonical Storage bytes',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProvider, (_) async {
            throw PlatformException(code: 'cache-unavailable');
          });
      var downloads = 0;
      final bytes = _validMp3(marker: 11);
      TtsService.setCanonicalDownloadForTesting((_) async {
        downloads++;
        return bytes;
      });

      final audio = await TtsService.resolveAudioForTesting(
        '먹지 않아요.',
        'female',
      );

      expect(audio?.path, isNull);
      expect(audio?.bytes, orderedEquals(bytes));
      expect(downloads, 1);
    },
  );

  test('private text never enters canonical download or disk cache', () async {
    var downloads = 0;
    TtsService.setCacheDirForTesting(sandbox);
    TtsService.setCanonicalDownloadForTesting((_) async {
      downloads++;
      return _validMp3();
    });

    final audio = await TtsService.resolveAudioForTesting(
      '개인용 비공개 예문 7193',
      'female',
    );

    expect(audio, isNull);
    expect(downloads, 0);
    expect(await sandbox.list().toList(), isEmpty);
  });

  test(
    'cache-directory fallback keeps the canonical memory cache at 64 entries',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProvider, (_) async {
            throw PlatformException(code: 'cache-unavailable');
          });
      final requests = await _canonicalUnbundledRequests(65);
      var downloads = 0;
      TtsService.setCanonicalDownloadForTesting((_) async {
        downloads++;
        return _validMp3(marker: downloads);
      });

      for (final request in requests) {
        final audio = await TtsService.resolveAudioForTesting(
          request.text,
          request.voice,
        );
        expect(audio?.bytes, isNotNull, reason: request.text);
      }
      expect(downloads, 65);

      await TtsService.resolveAudioForTesting(
        requests.last.text,
        requests.last.voice,
      );
      expect(downloads, 65, reason: 'the newest entry remains cached');

      await TtsService.resolveAudioForTesting(
        requests.first.text,
        requests.first.voice,
      );
      expect(downloads, 66, reason: 'the 65th insert evicts the oldest entry');
    },
  );
}

Future<List<({String text, String voice})>> _canonicalUnbundledRequests(
  int count,
) async {
  final raw = await rootBundle.loadString('assets/data/korean_vocab.csv');
  final rows = const CsvToListConverter(eol: '\n').convert(raw);
  final headers = rows.first.cast<String>();
  final korean = headers.indexOf('korean');
  final example = headers.indexOf('example_korean');
  final requests = <({String text, String voice})>[];
  final seenKeys = <String>{};

  for (final row in rows.skip(1)) {
    for (final column in [korean, example]) {
      final text = row[column].toString().trim();
      if (text.isEmpty) {
        continue;
      }
      final voice = TtsVoicePolicy.resolve(text: text, voice: 'auto');
      final key = TtsCacheKey.forRequest(voice: voice, text: text);
      if (await TtsCanonicalManifest.contains(key) &&
          await key.bundledAssetPath() == null &&
          seenKeys.add(key.localFileName)) {
        requests.add((text: text, voice: voice));
        if (requests.length == count) {
          return requests;
        }
      }
    }
  }
  fail(
    'Expected $count canonical unbundled requests, found ${requests.length}',
  );
}

Uint8List _validMp3({int marker = 1}) => Uint8List.fromList(
  List<int>.filled(64, marker)
    ..[0] = 0xFF
    ..[1] = 0xFB,
);
