import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/tts_service.dart';

class _FakePlatform implements TtsPlaybackPlatform {
  final mutations = <String>[];
  final fileSessions = <String, Completer<bool>>{};
  final speechSessions = <String, Completer<bool>>{};
  bool failFileStart = false;

  @override
  Future<TtsPlaybackSession?> startFile(File file, double rate) async {
    mutations.add('file:${file.path}:$rate');
    if (failFileStart) return null;
    final completion = Completer<bool>();
    fileSessions[file.path] = completion;
    return TtsPlaybackSession(completion.future);
  }

  @override
  Future<TtsPlaybackSession?> startSpeech(String text, double rate) async {
    mutations.add('speech:$text:$rate');
    final completion = Completer<bool>();
    speechSessions[text] = completion;
    return TtsPlaybackSession(completion.future);
  }

  @override
  Future<void> stop() async => mutations.add('stop');
}

void main() {
  test('file playback starts before rate is applied', () async {
    final calls = <String>[];
    final session = await TtsFilePlayback.start(
      completion: Future.value(true),
      play: () async => calls.add('play'),
      setRate: (rate) async => calls.add('rate:$rate'),
      stop: () async => calls.add('stop'),
      rate: 1.25,
    );
    expect(session, isNotNull);
    expect(calls, ['play', 'rate:1.25']);
  });

  test('file rate failure stops playback and reports no session', () async {
    final calls = <String>[];
    final session = await TtsFilePlayback.start(
      completion: Future.value(true),
      play: () async => calls.add('play'),
      setRate: (rate) async {
        calls.add('rate');
        throw StateError('unsupported');
      },
      stop: () async => calls.add('stop'),
      rate: 1,
    );
    expect(session, isNull);
    expect(calls, ['play', 'rate', 'stop']);
  });

  test('rate pair preserves OS scale and normalizes cached audio to 1x', () {
    final normal = TtsPlaybackRates.compose(baseRate: 0.42, multiplier: 1);
    final slow = TtsPlaybackRates.compose(baseRate: 0.42, multiplier: 0.75);
    final fast = TtsPlaybackRates.compose(baseRate: 0.42, multiplier: 1.25);

    expect(normal.speechRate, closeTo(0.42, 0.000001));
    expect(normal.fileRate, closeTo(1, 0.000001));
    expect(slow.speechRate, closeTo(0.315, 0.000001));
    expect(slow.fileRate, closeTo(0.75, 0.000001));
    expect(fast.speechRate, closeTo(0.525, 0.000001));
    expect(fast.fileRate, closeTo(1.25, 0.000001));
  });

  test('rate pair clamps to platform-specific limits', () {
    final low = TtsPlaybackRates.compose(baseRate: 0.01, multiplier: 0.1);
    final high = TtsPlaybackRates.compose(baseRate: 1, multiplier: 10);
    expect(low.speechRate, 0.1);
    expect(low.fileRate, 0.5);
    expect(high.speechRate, 1);
    expect(high.fileRate, 2);
  });

  test('file rate failure falls back safely to OS speech', () async {
    final platform = _FakePlatform()..failFileStart = true;
    final engine = TtsPlaybackEngine(
      resolveFile: (text, voice) async => File('cached.mp3'),
      platform: platform,
    );

    final result = engine.speak(text: '안녕하세요', voice: 'female', baseRate: 0.42);
    await Future<void>.delayed(Duration.zero);
    platform.speechSessions['안녕하세요']!.complete(true);

    expect(await result, isTrue);
    expect(platform.mutations, [
      'stop',
      'file:cached.mp3:1.0',
      'speech:안녕하세요:0.42',
    ]);
  });

  test(
    'playback multiplier remains independent of cache resolution key',
    () async {
      final platform = _FakePlatform();
      final resolutions = <String>[];
      final engine = TtsPlaybackEngine(
        resolveFile: (text, voice) async {
          resolutions.add('$voice|$text');
          return null;
        },
        platform: platform,
      );

      for (final multiplier in [0.75, 1.25]) {
        final request = engine.speak(
          text: '같은 음성',
          voice: 'female',
          baseRate: 0.42,
          rateMultiplier: multiplier,
        );
        await Future<void>.delayed(Duration.zero);
        platform.speechSessions['같은 음성']!.complete(true);
        await request;
      }

      expect(resolutions, ['female|같은 음성', 'female|같은 음성']);
    },
  );

  test(
    'older slow resolution performs no mutations after newer starts',
    () async {
      final platform = _FakePlatform();
      final releaseOld = Completer<File?>();
      final engine = TtsPlaybackEngine(
        resolveFile: (text, voice) =>
            text == 'old' ? releaseOld.future : Future.value(File('new.mp3')),
        platform: platform,
      );

      final old = engine.speak(text: 'old', voice: 'female', baseRate: 0.42);
      final newer = engine.speak(text: 'new', voice: 'female', baseRate: 0.42);
      await Future<void>.delayed(Duration.zero);
      releaseOld.complete(File('old.mp3'));
      await Future<void>.delayed(Duration.zero);
      platform.fileSessions['new.mp3']!.complete(true);

      expect(await newer, isTrue);
      expect(await old, isFalse);
      expect(platform.mutations, ['stop', 'file:new.mp3:1.0']);
    },
  );

  test(
    'fallback and file starts cannot cross-contaminate request rates',
    () async {
      final platform = _FakePlatform();
      final speechResolution = Completer<File?>();
      final engine = TtsPlaybackEngine(
        resolveFile: (text, voice) => text == 'speech'
            ? speechResolution.future
            : Future.value(File('file.mp3')),
        platform: platform,
      );

      final speech = engine.speak(
        text: 'speech',
        voice: 'female',
        baseRate: 0.42,
        rateMultiplier: 0.75,
      );
      speechResolution.complete(null);
      await Future<void>.delayed(Duration.zero);
      final file = engine.speak(
        text: 'file',
        voice: 'female',
        baseRate: 0.42,
        rateMultiplier: 1.25,
      );
      await Future<void>.delayed(Duration.zero);
      platform.fileSessions['file.mp3']!.complete(true);

      expect(await file, isTrue);
      expect(await speech, isFalse);
      expect(
        platform.mutations,
        containsAllInOrder(['speech:speech:0.315', 'file:file.mp3:1.25']),
      );
    },
  );

  test('stop and dispose invalidate pending resolution', () async {
    for (final shouldDispose in [false, true]) {
      final platform = _FakePlatform();
      final resolution = Completer<File?>();
      final engine = TtsPlaybackEngine(
        resolveFile: (text, voice) => resolution.future,
        platform: platform,
      );
      final pending = engine.speak(
        text: 'pending',
        voice: 'female',
        baseRate: 0.42,
      );
      if (shouldDispose) {
        await engine.dispose();
      } else {
        await engine.stop();
      }
      resolution.complete(File('late.mp3'));
      expect(await pending, isFalse);
      expect(platform.mutations.where((m) => m.startsWith('file:')), isEmpty);
    }
  });
}
