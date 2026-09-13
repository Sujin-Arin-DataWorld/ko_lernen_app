import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ko_lernen_app/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const text = '먹지 않아요.'; // Canonical, but not bundled.
  final mp3 = [0x49, 0x44, 0x33, ...List.filled(40, 7)];
  late Directory cache;

  setUp(() async {
    cache = await Directory.systemTemp.createTemp('tts_public_fallback_');
    TtsService.setCacheDirForTesting(cache);
  });
  tearDown(() async {
    TtsService.setCacheDirForTesting(null);
    await cache.delete(recursive: true);
  });

  test(
    'native SDK unavailable: canonical HTTP bytes resolve and persist',
    () async {
      // No Firebase app is initialized: the SDK tier cannot provide any bytes.
      // The public corpus endpoint must work without synthesis or credentials.
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        expect(request.headers.containsKey('authorization'), isFalse);
        expect(request.url.queryParameters, {'alt': 'media'});
        return http.Response.bytes(mp3, 200);
      });
      await http.runWithClient(() async {
        final first = await TtsService.resolveAudioForTesting(text, 'female');
        expect(first, isNotNull);
        expect(await File(first!.path!).readAsBytes(), mp3);
        final restored = await TtsService.resolveAudioForTesting(
          text,
          'female',
        );
        expect(restored!.path, first.path);
      }, () => client);
      expect(calls, 1, reason: 'The second lookup must use the durable cache.');
    },
  );

  test(
    'native public failure stays unavailable and does not cache junk',
    () async {
      for (final status in [403, 404, 500]) {
        final result = await http.runWithClient(
          () => TtsService.resolveAudioForTesting(text, 'female'),
          () => MockClient((_) async => http.Response.bytes(mp3, status)),
        );
        expect(result, isNull);
      }
      expect(await cache.list().toList(), isEmpty);
    },
  );

  test('native unknown text never reaches public HTTP', () async {
    var calls = 0;
    final result = await http.runWithClient(
      () => TtsService.resolveAudioForTesting(
        'Private learner draft 71395',
        'female',
      ),
      () => MockClient((_) async {
        calls++;
        return http.Response.bytes(mp3, 200);
      }),
    );
    expect(result, isNull);
    expect(calls, 0);
  });

  test(
    'valid public audio remains playable when its cache cannot be written',
    () async {
      final obstruction = File('${cache.path}/not-a-directory');
      await obstruction.writeAsString('preserve');
      TtsService.setCacheDirForTesting(Directory(obstruction.path));
      final result = await http.runWithClient(
        () => TtsService.resolveAudioForTesting(text, 'female'),
        () => MockClient((_) async => http.Response.bytes(mp3, 200)),
      );
      expect(result, isNotNull);
      expect(result!.path, isNull);
      expect(result.bytes, mp3);
      expect(await obstruction.readAsString(), 'preserve');
    },
  );

  test(
    'public audio still plays when the cache directory cannot be created',
    () async {
      // #303 review (P2): setCacheDirForTesting hands _ensureCacheDir a ready
      // Directory, so it never exercised the case where the directory itself
      // cannot be created. A regular file where the cache root should be makes
      // the real `Directory.create` fail (ENOTDIR); _resolveAudio must keep
      // going to the public transport instead of returning null there.
      final occupied = File('${cache.path}/occupied-root');
      await occupied.writeAsString('keep');
      TtsService.setCacheDirForTesting(null);
      TtsService.setApplicationCacheDirectoryForTesting(
        () async => Directory(occupied.path),
      );
      addTearDown(
        () => TtsService.setApplicationCacheDirectoryForTesting(null),
      );
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response.bytes(mp3, 200);
      });
      final result = await http.runWithClient(
        () => TtsService.resolveAudioForTesting(text, 'female'),
        () => client,
      );
      expect(result, isNotNull);
      expect(result!.path, isNull);
      expect(result.bytes, mp3);
      expect(calls, 1);
      expect(TtsService.lastError, contains('캐시 디렉토리 실패'));
      // Without a disk cache the verified bytes stay in the memory tier.
      final again = await http.runWithClient(
        () => TtsService.resolveAudioForTesting(text, 'female'),
        () => client,
      );
      expect(again!.bytes, mp3);
      expect(calls, 1, reason: 'The memory cache serves the repeat lookup.');
      expect(await occupied.readAsString(), 'keep');
      expect(Directory('${occupied.path}/tts_cache').existsSync(), isFalse);
    },
  );
}
