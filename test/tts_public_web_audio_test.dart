import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ko_lernen_app/services/tts_cache_key.dart';
import 'package:ko_lernen_app/services/tts_public_web_audio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TtsCacheKey canonical;
  final mp3 = [0x49, 0x44, 0x33, ...List.filled(40, 7)];
  setUpAll(() async {
    final catalog = jsonDecode(
      await rootBundle.loadString('assets/data/phase_tasks.json'),
    );
    final task = (catalog['tasks'] as List).firstWhere(
      (t) => t['id'] == 'KP14:listening:01',
    );
    canonical = TtsCacheKey.forRequest(
      voice: 'female',
      text: task['practice']['sourceKo'],
    );
  });
  Future<List<int>?> read(
    TtsCacheKey key,
    http.Client client, {
    int max = 100,
  }) => TtsPublicWebAudio.read(
    key,
    maxBytes: max,
    timeout: const Duration(seconds: 1),
    client: client,
  );

  test('personal text never creates a public request', () async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return http.Response.bytes(mp3, 200);
    });
    expect(
      await read(
        TtsCacheKey.forRequest(voice: 'female', text: 'private draft 829234'),
        client,
      ),
      isNull,
    );
    expect(calls, 0);
  });
  test(
    'canonical request has one object segment and no credentials or redirects',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.host, 'firebasestorage.googleapis.com');
        expect(request.url.pathSegments.last, canonical.storagePath);
        expect(request.url.queryParameters, {'alt': 'media'});
        expect(request.headers.containsKey('authorization'), isFalse);
        expect(request.followRedirects, isFalse);
        return http.Response.bytes(mp3, 200);
      });
      expect(await read(canonical, client), mp3);
    },
  );
  test('denied, missing, redirect and invalid audio never succeed', () async {
    for (final status in [302, 403, 404, 500]) {
      expect(
        await read(
          canonical,
          MockClient((_) async => http.Response.bytes(mp3, status)),
        ),
        isNull,
      );
    }
    expect(
      await read(
        canonical,
        MockClient((_) async => http.Response('not an mp3', 200)),
      ),
      isNull,
    );
  });
  test('oversized declared and chunked bodies never succeed', () async {
    expect(
      await read(
        canonical,
        MockClient((_) async => http.Response.bytes(mp3, 200)),
        max: 40,
      ),
      isNull,
    );
    final streamed = MockClient.streaming(
      (_, _) async => http.StreamedResponse(
        Stream.fromIterable([mp3.take(30).toList(), mp3.skip(30).toList()]),
        200,
      ),
    );
    expect(await read(canonical, streamed, max: 40), isNull);
  });
  test('transport failure and stalled response return unavailable', () async {
    expect(
      await read(
        canonical,
        MockClient((_) async => throw http.ClientException('offline')),
      ),
      isNull,
    );
    expect(
      await TtsPublicWebAudio.read(
        canonical,
        maxBytes: 100,
        timeout: const Duration(milliseconds: 5),
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return http.Response.bytes(mp3, 200);
        }),
      ),
      isNull,
    );
  });
}
