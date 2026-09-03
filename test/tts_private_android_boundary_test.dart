import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'production Android source preparation cannot resume expired private audio',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const player = MethodChannel('xyz.luan/audioplayers');
      const global = MethodChannel('xyz.luan/audioplayers.global');
      const globalEvents = MethodChannel('xyz.luan/audioplayers.global/events');
      MethodChannel? playerEvents;
      final calls = <String>[];
      final sessions = CloudWriteSessionController()..acquire('alice');
      var now = DateTime.utc(2026, 9, 3);
      var elapsed = Duration.zero;
      final serverNow = now.millisecondsSinceEpoch;
      final bytes = Uint8List.fromList([
        0x49,
        0x44,
        0x33,
        ...List.filled(40, 7),
      ]);
      final base = await Directory.systemTemp.createTemp(
        'tts-android-boundary-',
      );
      messenger.setMockMethodCallHandler(global, (_) async => null);
      messenger.setMockMethodCallHandler(globalEvents, (_) async => null);
      messenger.setMockMethodCallHandler(player, (call) async {
        calls.add(call.method);
        if (call.method == 'create') {
          playerEvents = MethodChannel(
            'xyz.luan/audioplayers/events/${call.arguments['playerId']}',
          );
          messenger.setMockMethodCallHandler(playerEvents!, (_) async => null);
        }
        if (call.method == 'setSourceBytes') {
          expect(call.arguments['bytes'], bytes);
          now = now.add(const Duration(seconds: 1));
          elapsed += const Duration(seconds: 1);
          await messenger.handlePlatformMessage(
            playerEvents!.name,
            const StandardMethodCodec().encodeSuccessEnvelope({
              'event': 'audio.onPrepared',
              'value': true,
            }),
            (_) {},
          );
        }
        return call.method == 'getCurrentPosition' ? 0 : null;
      });
      TtsService.configurePrivateForTesting(
        sessions: sessions,
        authenticatedUid: () => 'alice',
        now: () => now,
        elapsed: () => elapsed,
        preparePlayback: () async {},
        invoke: (_) async => {
          'audioBase64': base64Encode(bytes),
          'cacheScope': 'private',
          'serverNowMillis': serverNow,
          'expiresAtMillis': serverNow + 1000,
        },
      );
      try {
        final audio = await TtsService.resolveAudioForTesting(
          '개인용 비공개 예문 7193',
          'female',
          allowSynthesis: true,
        );
        expect(audio, isNotNull);
        expect(await TtsService.startAudioForTesting(audio!, 1), isNull);
        expect(calls, contains('setSourceBytes'));
        expect(calls, isNot(contains('resume')));
        await TtsService.clearCacheStrict(cacheDirectory: () async => base);
        expect(calls, contains('release'));
      } finally {
        TtsService.configurePrivateForTesting();
        if (await base.exists()) {
          await base.delete(recursive: true);
        }
        messenger.setMockMethodCallHandler(player, null);
        messenger.setMockMethodCallHandler(global, null);
        messenger.setMockMethodCallHandler(globalEvents, null);
        if (playerEvents != null) {
          messenger.setMockMethodCallHandler(playerEvents!, null);
        }
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
