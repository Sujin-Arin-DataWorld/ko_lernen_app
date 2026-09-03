import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const playbackChannel = MethodChannel('hangul_sori/private_tts');
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  const personal = '개인용 비공개 예문 7193';
  final bytes = Uint8List.fromList([0x49, 0x44, 0x33, ...List.filled(40, 7)]);
  late CloudWriteSessionController sessions;
  late DateTime wall;
  late Duration elapsed;
  late int serverNow;
  late int calls;
  late List<MethodCall> nativeCalls;
  late Future<Map<String, dynamic>> Function() response;
  late Future<void> Function() prepare;
  late Directory base;

  Map<String, dynamic> payload({int remainingMillis = 1000}) => {
    'audioBase64': base64Encode(bytes),
    'cacheScope': 'private',
    'serverNowMillis': serverNow,
    'expiresAtMillis': serverNow + remainingMillis,
  };
  Future<TtsAudio?> resolve() => TtsService.resolveAudioForTesting(
    personal,
    'female',
    allowSynthesis: true,
  );
  void advance(Duration delta) {
    wall = wall.add(delta);
    elapsed += delta;
  }

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    sessions = CloudWriteSessionController()..acquire('alice');
    serverNow = DateTime.utc(2026, 9, 3).millisecondsSinceEpoch;
    wall = DateTime.fromMillisecondsSinceEpoch(serverNow);
    elapsed = Duration.zero;
    calls = 0;
    nativeCalls = [];
    response = () async => payload();
    prepare = () async {};
    base = await Directory.systemTemp.createTemp('tts-private-boundary-');
    messenger.setMockMethodCallHandler(pathChannel, (_) async => base.path);
    messenger.setMockMethodCallHandler(playbackChannel, (call) async {
      nativeCalls.add(call);
      return call.method == 'play' ? true : null;
    });
    TtsService.configurePrivateForTesting(
      sessions: sessions,
      authenticatedUid: () => sessions.current?.uid,
      invoke: (_) async {
        calls++;
        return response();
      },
      now: () => wall,
      elapsed: () => elapsed,
      preparePlayback: () => prepare(),
    );
  });
  tearDown(() async {
    await TtsService.clearCacheStrict(
      cacheDirectory: () async => Directory('${base.path}/tts_cache'),
    );
    TtsService.configurePrivateForTesting();
    messenger.setMockMethodCallHandler(playbackChannel, null);
    messenger.setMockMethodCallHandler(pathChannel, null);
    await base.delete(recursive: true);
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'slow wall clock cannot extend a server remaining-TTL cache hit',
    () async {
      wall = wall.subtract(const Duration(hours: 1));
      expect(await resolve(), isNotNull);
      advance(const Duration(seconds: 1));
      response = () async => throw StateError('offline');
      expect(await resolve(), isNull);
      expect(calls, 2);
    },
  );

  test(
    'backward wall clock invalidates downloaded audio through production start',
    () async {
      final audio = await resolve();
      wall = wall.subtract(const Duration(seconds: 1));
      elapsed += const Duration(milliseconds: 10);
      expect(await TtsService.startAudioForTesting(audio!, 1), isNull);
      expect(nativeCalls, isEmpty);
    },
  );

  test(
    'response transit consumes all remaining lifetime even with slow wall clock',
    () async {
      wall = wall.subtract(const Duration(hours: 1));
      response = () async {
        advance(const Duration(seconds: 1));
        return payload();
      };
      expect(await resolve(), isNull);
    },
  );

  test(
    'monotonic time expires the production cache even if wall clock stalls',
    () async {
      expect(await resolve(), isNotNull);
      elapsed += const Duration(seconds: 1);
      response = () async => throw StateError('offline');
      expect(await resolve(), isNull);
      expect(calls, 2);
    },
  );

  test(
    'a fast but stable device clock can use the server remaining lifetime',
    () async {
      wall = wall.add(const Duration(hours: 1));
      final audio = await resolve();
      expect(audio, isNotNull);
      final started = await TtsService.startAudioForTesting(audio!, 1);
      expect(await started?.completion, isTrue);
      expect(nativeCalls.single.method, 'play');
    },
  );

  for (final remaining in [0, -1, 86400001]) {
    test('rejects invalid server remaining lifetime $remaining', () async {
      response = () async => payload(remainingMillis: remaining);
      expect(await resolve(), isNull);
    });
  }

  test(
    'delayed platform preparation cannot start expired downloaded audio',
    () async {
      final audio = await resolve();
      prepare = () async {
        advance(const Duration(seconds: 1));
      };
      expect(await TtsService.startAudioForTesting(audio!, 1), isNull);
      expect(nativeCalls, isEmpty);
    },
  );

  test('private responses without server timing fail closed', () async {
    response = () async => payload()..remove('serverNowMillis');
    expect(await resolve(), isNull);
  });

  for (final transition in ['uid', 'epoch', 'mode']) {
    test(
      'private $transition invalidation preserves real canonical offline cache',
      () async {
        final key = TtsCacheKey.forRequest(voice: 'female', text: '아');
        final cache = await Directory('${base.path}/tts_cache').create();
        final canonicalFile = await File(
          '${cache.path}/${key.localFileName}',
        ).writeAsBytes(bytes);
        expect(
          (await TtsService.resolveAudioForTesting('아', 'female'))?.path,
          canonicalFile.path,
        );
        final privateAudio = await resolve();
        expect(privateAudio, isNotNull);
        expect(await resolve(), isNotNull);
        expect(calls, 1);
        if (transition == 'uid') {
          sessions.acquire('bob');
        } else if (transition == 'epoch') {
          sessions.acquire('alice');
        } else {
          sessions.transition(CloudWriteMode.quiesced);
        }
        await TtsService.stop();
        // Let any asynchronous invalidation cleanup finish before checking disk.
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(await canonicalFile.exists(), isTrue);
        expect(
          (await TtsService.resolveAudioForTesting('아', 'female'))?.path,
          canonicalFile.path,
        );
        expect(await TtsService.startAudioForTesting(privateAudio!, 1), isNull);
        response = () async => throw StateError('offline');
        expect(await resolve(), isNull);
        expect(calls, transition == 'mode' ? 1 : 2);
        expect(nativeCalls, isEmpty);
      },
    );
  }
}
