import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/tts_private_playback.dart';
import 'package:ko_lernen_app/services/tts_private_cache.dart';
import 'package:ko_lernen_app/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('hangul_sori/private_tts');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final bytes = Uint8List.fromList([0x49, 0x44, 0x33, ...List.filled(40, 7)]);
  late List<MethodCall> calls;
  late Completer<bool> completed;
  late TtsPrivatePlayback playback;

  setUp(() {
    calls = [];
    completed = Completer<bool>();
    playback = TtsPrivatePlayback(channel);
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'play' ? completed.future : null;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'private payload preserves identity while canonical bytes stay public',
    () async {
      final sessions = CloudWriteSessionController();
      final session = sessions.acquire('alice');
      final cache = TtsPrivateCache(sessions: sessions);
      final lease = await cache.resolve(
        'key',
        fetch: () async => bytes,
        serverTiming: () => (serverNowMillis: 1000, expiresAtMillis: 60000),
      );
      final audio = TtsAudio.privateBytes(lease!);
      expect(audio.privateSession, session);
      expect(audio.privateAudio, same(lease));
      cache.clear();
      expect(audio.privateAudio!.isCurrent, isFalse);
      cache.dispose();
      expect(TtsAudio.bytes(bytes).privateSession, isNull);
    },
  );

  test('only verified memory-backed platforms may play private audio', () {
    expect(
      TtsPrivatePlayback.routeFor(TargetPlatform.iOS),
      PrivateTtsRoute.iosMemory,
    );
    expect(
      TtsPrivatePlayback.routeFor(TargetPlatform.android),
      PrivateTtsRoute.bytes,
    );
    for (final platform in [
      TargetPlatform.macOS,
      TargetPlatform.linux,
      TargetPlatform.windows,
      TargetPlatform.fuchsia,
    ]) {
      expect(TtsPrivatePlayback.routeFor(platform), PrivateTtsRoute.denied);
      expect(
        TtsPrivatePlayback.routeFor(platform, isWeb: true),
        PrivateTtsRoute.bytes,
      );
    }
  });

  test(
    'iOS sends bytes, never a path, and reports real native completion',
    () async {
      final result = playback.play(
        bytes,
        rate: 0.8,
        volume: 0.6,
        isCurrent: () => true,
      );
      await Future<void>.delayed(Duration.zero);
      expect(calls.single.method, 'play');
      expect(
        (calls.single.arguments as Map).keys,
        unorderedEquals(['id', 'bytes', 'rate', 'volume']),
      );
      expect(calls.single.arguments['bytes'], bytes);
      completed.complete(true);
      expect(await result, isTrue);
    },
  );

  test(
    'identity invalidation stops native audio and rejects late completion',
    () async {
      var current = true;
      final result = playback.play(
        bytes,
        rate: 1,
        volume: 1,
        isCurrent: () => current,
      );
      await Future<void>.delayed(Duration.zero);
      current = false;
      await playback.stop();
      expect(calls.map((call) => call.method), ['play', 'stop']);
      expect(calls[1].arguments['id'], calls[0].arguments['id']);
      completed.complete(true);
      expect(await result, isFalse);
    },
  );

  test('stale identity never reaches native playback', () async {
    expect(
      await playback.play(bytes, rate: 1, volume: 1, isCurrent: () => false),
      isFalse,
    );
    expect(calls, isEmpty);
  });

  test(
    'delayed stop rechecks private validity before starting replacement',
    () async {
      var current = true;
      final stopped = Completer<void>();
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return call.method == 'play' ? completed.future : stopped.future;
      });
      final first = playback.play(
        bytes,
        rate: 1,
        volume: 1,
        isCurrent: () => current,
      );
      await Future<void>.delayed(Duration.zero);
      final stopping = playback.stop();
      final next = playback.play(
        bytes,
        rate: 1,
        volume: 1,
        isCurrent: () => current,
      );
      await Future<void>.delayed(Duration.zero);
      current = false;
      stopped.complete();
      await stopping;
      expect(await next, isFalse);
      completed.complete(true);
      expect(await first, isFalse);
      expect(calls.where((call) => call.method == 'play').length, 1);
    },
  );

  test(
    'failed native release is retried and blocks new private playback',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'stop') {
          throw PlatformException(code: 'unavailable');
        }
        return completed.future;
      });
      final first = playback.play(
        bytes,
        rate: 1,
        volume: 1,
        isCurrent: () => true,
      );
      await Future<void>.delayed(Duration.zero);
      await expectLater(playback.stop(), throwsA(isA<PlatformException>()));
      expect(
        await playback.play(bytes, rate: 1, volume: 1, isCurrent: () => true),
        isFalse,
      );
      expect(calls.map((call) => call.method), ['play', 'stop', 'stop']);
      completed.complete(true);
      expect(await first, isFalse);
    },
  );

  test('native rejection never falls back to a file-backed player', () async {
    final result = playback.play(
      bytes,
      rate: 1,
      volume: 1,
      isCurrent: () => true,
    );
    await Future<void>.delayed(Duration.zero);
    completed.complete(false);
    expect(await result, isFalse);
    expect(calls.map((call) => call.method), ['play']);
  });

  test(
    'iOS plugin is implicit-engine registered and uses no file-backed audio',
    () {
      final source = File('ios/Runner/AppDelegate.swift').readAsStringSync();
      expect(source, contains('PrivateTtsPlayerPlugin.register(with:'));
      final registration = source
          .split(
            'static func register(with registrar: FlutterPluginRegistrar) {',
          )
          .last
          .split('\n  }')
          .first;
      expect(registration, contains('let instance = PrivateTtsPlayerPlugin()'));
      expect(
        registration,
        contains('registrar.addMethodCallDelegate(instance, channel: channel)'),
      );
      expect(registration, contains('registrar.publish(instance)'));
      expect(source, contains('AVAudioPlayer(data:'));
      expect(source, isNot(contains('contentsOf:')));
      expect(source, isNot(contains('FileManager')));
      expect(source, isNot(contains('temporaryDirectory')));
    },
  );
}
