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
}
