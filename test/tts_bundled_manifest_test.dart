import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/tts_bundled_manifest.dart';
import 'package:ko_lernen_app/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TtsBundledManifest.resetForTesting();
  });

  test(
    'checked baseline manifest is valid, cache-hit-aware, and single-flight',
    () async {
      TtsBundledManifest.resetForTesting();
      final first = TtsBundledManifest.load();
      final second = TtsBundledManifest.load();

      expect(identical(first, second), isTrue);
      final manifest = await first;
      final key = TtsCacheKey.forRequest(voice: 'male', text: '안녕하세요');
      expect(manifest.assetFor(key), isNull);
      expect(await key.bundledAssetPath(), isNull);
    },
  );

  test('schema and cache revision drift fail closed', () async {
    final schema = _manifest(<Map<String, dynamic>>[])..['schemaVersion'] = 2;
    TtsBundledManifest.resetForTesting(bundle: _bundle(schema));
    await expectLater(
      TtsBundledManifest.load(),
      throwsA(isA<FormatException>()),
    );

    final revision = _manifest(<Map<String, dynamic>>[])
      ..['cacheRevision'] = 'v2';
    TtsBundledManifest.resetForTesting(bundle: _bundle(revision));
    await expectLater(
      TtsBundledManifest.load(),
      throwsA(isA<FormatException>()),
    );
  });

  test('invalid manifest lookup falls through instead of throwing', () async {
    final invalid = _manifest(<Map<String, dynamic>>[])..['schemaVersion'] = 99;
    TtsBundledManifest.resetForTesting(bundle: _bundle(invalid));
    final key = TtsCacheKey.forRequest(voice: 'male', text: '폴백');

    expect(await key.bundledAssetPath(), isNull);
  });

  test('conflicting duplicate cache key is rejected', () async {
    final bytes = _validMp3();
    final first = _item(
      scenarioId: 'first',
      text: '같은 문장',
      assetPath: 'assets/tts/v3/male/first.mp3',
      bytes: bytes,
    );
    final second = _item(
      scenarioId: 'second',
      text: '같은 문장',
      assetPath: 'assets/tts/v3/male/second.mp3',
      bytes: bytes,
    );
    final payload = _manifest(<Map<String, dynamic>>[first, second]);
    TtsBundledManifest.resetForTesting(
      bundle: _bundle(payload, <String, Uint8List>{
        first['bundledAssetPath']! as String: bytes,
        second['bundledAssetPath']! as String: bytes,
      }),
    );

    await expectLater(
      TtsBundledManifest.load(),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Conflicting duplicate'),
        ),
      ),
    );
  });

  test('missing declared asset is rejected', () async {
    final bytes = _validMp3();
    final item = _item(
      scenarioId: 'missing',
      text: '없는 파일',
      assetPath: 'assets/tts/v3/male/missing.mp3',
      bytes: bytes,
    );
    TtsBundledManifest.resetForTesting(
      bundle: _bundle(_manifest(<Map<String, dynamic>>[item])),
    );

    await expectLater(
      TtsBundledManifest.load(),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('missing asset'),
        ),
      ),
    );
  });

  test('bundled SHA mismatch is rejected', () async {
    final bytes = _validMp3();
    final item = _item(
      scenarioId: 'hash',
      text: '해시 불일치',
      assetPath: 'assets/tts/v3/male/hash.mp3',
      bytes: bytes,
    )..['bundledSha256'] = List<String>.filled(64, '0').join();
    TtsBundledManifest.resetForTesting(
      bundle: _bundle(
        _manifest(<Map<String, dynamic>>[item]),
        <String, Uint8List>{item['bundledAssetPath']! as String: bytes},
      ),
    );

    await expectLater(
      TtsBundledManifest.load(),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('SHA-256 mismatch'),
        ),
      ),
    );
  });

  test(
    'invalid MPEG bytes are rejected even when their hash matches',
    () async {
      final bytes = Uint8List.fromList(List<int>.filled(64, 7));
      final item = _item(
        scenarioId: 'mpeg',
        text: '잘못된 파일',
        assetPath: 'assets/tts/v3/male/mpeg.mp3',
        bytes: bytes,
      );
      TtsBundledManifest.resetForTesting(
        bundle: _bundle(
          _manifest(<Map<String, dynamic>>[item]),
          <String, Uint8List>{item['bundledAssetPath']! as String: bytes},
        ),
      );

      await expectLater(
        TtsBundledManifest.load(),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('invalid MPEG'),
          ),
        ),
      );
    },
  );

  test('valid bundled bytes resolve before disk or Firebase tiers', () async {
    final bytes = _validMp3();
    final item = _item(
      scenarioId: 'bundle',
      text: '번들 첫 문장',
      assetPath: 'assets/tts/v3/male/bundle.mp3',
      bytes: bytes,
    );
    final bundle = _bundle(
      _manifest(<Map<String, dynamic>>[item]),
      <String, Uint8List>{item['bundledAssetPath']! as String: bytes},
    );
    TtsBundledManifest.resetForTesting(bundle: bundle);

    final audio = await TtsService.resolveAudioForTesting('번들 첫 문장', 'male');

    expect(audio, isNotNull);
    expect(audio!.path, isNull);
    expect(audio.bytes, orderedEquals(bytes));
    expect(bundle.loadCount[TtsBundledManifest.assetPath], 1);
    expect(bundle.loadCount[item['bundledAssetPath']], 2);
  });

  test('resolver source preserves bundle, disk, Storage, callable order', () {
    final source = File('lib/services/tts_service.dart').readAsStringSync();
    final start = source.indexOf('static Future<TtsAudio?> _resolveAudio');
    final resolver = source.substring(start);

    final bundle = resolver.indexOf('bundledAssetPath()');
    final disk = resolver.indexOf('file.exists()');
    final storage = resolver.indexOf('.ref(key.storagePath)');
    final callable = resolver.indexOf('takeCallableAudio(');

    expect(bundle, greaterThanOrEqualTo(0));
    expect(disk, greaterThan(bundle));
    expect(storage, greaterThan(disk));
    expect(callable, greaterThan(storage));
  });
}

Map<String, dynamic> _manifest(List<Map<String, dynamic>> items) =>
    <String, dynamic>{
      'schemaVersion': 1,
      'kind': 'tts_first_line_manifest',
      'cacheRevision': 'v3',
      'scenarioCount': items.length,
      'bundledCount': items.where((item) => item['bundled'] == true).length,
      'items': items,
    };

Map<String, dynamic> _item({
  required String scenarioId,
  required String text,
  required String assetPath,
  required Uint8List bytes,
}) {
  final key = TtsCacheKey.forRequest(voice: 'male', text: text);
  return <String, dynamic>{
    'scenarioId': scenarioId,
    'voice': 'male',
    'normalizedText': text,
    'cacheHashSha1': key.hash,
    'storagePath': key.storagePath,
    'bundledAssetPath': assetPath,
    'bundled': true,
    'bundledSha256': sha256.convert(bytes).toString(),
  };
}

Uint8List _validMp3() => Uint8List.fromList(
  List<int>.filled(64, 0)
    ..[0] = 0xFF
    ..[1] = 0xFB,
);

_MemoryAssetBundle _bundle(
  Map<String, dynamic> manifest, [
  Map<String, Uint8List> assets = const <String, Uint8List>{},
]) {
  return _MemoryAssetBundle(<String, Uint8List>{
    TtsBundledManifest.assetPath: Uint8List.fromList(
      utf8.encode(jsonEncode(manifest)),
    ),
    ...assets,
  });
}

final class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(this.files);

  final Map<String, Uint8List> files;
  final Map<String, int> loadCount = <String, int>{};

  @override
  Future<ByteData> load(String key) async {
    loadCount.update(key, (value) => value + 1, ifAbsent: () => 1);
    final bytes = files[key];
    if (bytes == null) {
      throw StateError('Missing fake asset: $key');
    }
    return ByteData.sublistView(bytes);
  }
}
