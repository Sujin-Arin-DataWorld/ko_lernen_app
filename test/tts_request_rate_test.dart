import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/tts_service.dart';

class _FakePlatform implements TtsPlaybackPlatform {
  final mutations = <String>[];
  final fileSessions = <String, Completer<bool>>{};
  final speechSessions = <String, Completer<bool>>{};
  bool failFileStart = false;
  int throwFileStarts = 0;
  int throwSpeechStarts = 0;
  int throwStops = 0;

  @override
  Future<TtsPlaybackSession?> startFile(File file, double rate) async {
    mutations.add('file:${file.path}:$rate');
    if (throwFileStarts > 0) {
      throwFileStarts--;
      await Future<void>.delayed(Duration.zero);
      throw StateError('async file start failure');
    }
    if (failFileStart) return null;
    final completion = Completer<bool>();
    fileSessions[file.path] = completion;
    return TtsPlaybackSession(completion.future);
  }

  @override
  Future<TtsPlaybackSession?> startSpeech(String text, double rate) async {
    mutations.add('speech:$text:$rate');
    if (throwSpeechStarts > 0) {
      throwSpeechStarts--;
      await Future<void>.delayed(Duration.zero);
      throw StateError('async speech start failure');
    }
    final completion = Completer<bool>();
    speechSessions[text] = completion;
    return TtsPlaybackSession(completion.future);
  }

  @override
  Future<void> stop() async {
    mutations.add('stop');
    if (throwStops > 0) {
      throwStops--;
      await Future<void>.delayed(Duration.zero);
      throw StateError('async stop failure');
    }
  }
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
    final errors = <Object>[];
    final session = await TtsFilePlayback.start(
      completion: Future.value(true),
      play: () async => calls.add('play'),
      setRate: (rate) async {
        calls.add('rate');
        throw StateError('unsupported');
      },
      stop: () async => calls.add('stop'),
      onError: errors.add,
      rate: 1,
    );
    expect(session, isNull);
    expect(calls, ['play', 'rate', 'stop']);
    expect(errors.single, isA<StateError>());
  });

  test('file play failure returns null only when cleanup succeeds', () async {
    final safe = await TtsFilePlayback.start(
      completion: Future.value(true),
      play: () async => throw StateError('play failed'),
      setRate: (rate) async {},
      stop: () async {},
      rate: 1,
    );
    final unsafe = await TtsFilePlayback.start(
      completion: Future.value(true),
      play: () async => throw StateError('play failed'),
      setRate: (rate) async {},
      stop: () async => throw StateError('stop failed'),
      rate: 1,
    );

    expect(safe, isNull);
    expect(await unsafe!.completion, isFalse);
  });

  test(
    'async file play failure falls back to OS speech without throwing',
    () async {
      final fallbackCompletion = Completer<bool>();
      final platform = _CallbackPlatform((file, rate) async {
        // Mirrors production _startFile: await the helper so its asynchronous
        // play error is caught, then return null only after cleanup succeeds.
        try {
          return await TtsFilePlayback.start(
            completion: Future.value(true),
            play: () async => throw StateError('async play failure'),
            setRate: (rate) async {},
            stop: () async {},
            rate: rate,
          );
        } catch (_) {
          await Future<void>.delayed(Duration.zero);
          return null;
        }
      }, (text, rate) async => TtsPlaybackSession(fallbackCompletion.future));
      final engine = TtsPlaybackEngine(
        resolveFile: (text, voice) async => File('broken.mp3'),
        platform: platform,
      );

      final result = engine.speak(
        text: 'fallback',
        voice: 'female',
        baseRate: 0.42,
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      fallbackCompletion.complete(true);

      expect(await result, isTrue);
    },
  );

  test(
    'async rate cleanup failure is contained without unsafe fallback',
    () async {
      var speechStarts = 0;
      final platform = _CallbackPlatform(
        (file, rate) => TtsFilePlayback.start(
          completion: Future.value(true),
          play: () async {},
          setRate: (rate) async => throw StateError('rate failure'),
          stop: () async => throw StateError('cleanup failure'),
          rate: rate,
        ),
        (text, rate) async {
          speechStarts++;
          return TtsPlaybackSession(Future.value(true));
        },
      );
      final engine = TtsPlaybackEngine(
        resolveFile: (text, voice) async => File('rate.mp3'),
        platform: platform,
      );

      final result = engine.speak(
        text: 'rate fallback',
        voice: 'female',
        baseRate: 0.42,
      );
      expect(await result, isFalse);
      expect(speechStarts, 0);
    },
  );

  test('quota blocks do not fall back to OS speech', () async {
    final platform = _FakePlatform();
    final errors = <String>[];
    final engine = TtsPlaybackEngine(
      resolveFile: (text, voice) async =>
          throw const TtsSynthesisBlocked('Daily synthesis limit reached.'),
      platform: platform,
      errorReporter: errors.add,
    );

    expect(
      await engine.speak(
        text: 'quota blocked',
        voice: 'female',
        baseRate: 0.42,
      ),
      isFalse,
    );
    expect(platform.speechSessions, isEmpty);
    expect(platform.fileSessions, isEmpty);
    expect(errors, contains('Daily synthesis limit reached.'));
  });

  test('resolver errors safely fall back to OS speech', () async {
    final platform = _FakePlatform();
    final engine = TtsPlaybackEngine(
      resolveFile: (text, voice) async => throw StateError('cache unavailable'),
      platform: platform,
    );

    final result = engine.speak(
      text: 'resolver fallback',
      voice: 'female',
      baseRate: 0.42,
    );
    await Future<void>.delayed(Duration.zero);
    platform.speechSessions['resolver fallback']!.complete(true);

    expect(await result, isTrue);
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

  // 전역 사용자 배수 (2026-08-13 속도 바) — compose 의 세 번째 축.
  test('userMultiplier default is identity', () {
    final a = TtsPlaybackRates.compose(baseRate: 0.42, multiplier: 0.75);
    final b = TtsPlaybackRates.compose(
      baseRate: 0.42,
      multiplier: 0.75,
      userMultiplier: 1.0,
    );
    expect(a.speechRate, b.speechRate);
    expect(a.fileRate, b.fileRate);
  });

  test('userMultiplier folds into both speech and file rates', () {
    final slowUser = TtsPlaybackRates.compose(
      baseRate: 0.42,
      multiplier: 1,
      userMultiplier: 0.5,
    );
    final fastUser = TtsPlaybackRates.compose(
      baseRate: 0.42,
      multiplier: 1,
      userMultiplier: 1.5,
    );
    expect(slowUser.speechRate, closeTo(0.21, 0.000001));
    expect(slowUser.fileRate, closeTo(0.5, 0.000001));
    expect(fastUser.speechRate, closeTo(0.63, 0.000001));
    expect(fastUser.fileRate, closeTo(1.5, 0.000001));
  });

  test('speakSlow 0.65 × global 0.5 hits the 0.5 file-rate floor', () {
    final r = TtsPlaybackRates.compose(
      baseRate: 0.42,
      multiplier: 0.65,
      userMultiplier: 0.5,
    );
    expect(r.fileRate, 0.5); // clamp 바닥 — 정직한 최저 배속
    expect(r.speechRate, closeTo(0.42 * 0.325, 0.000001));
  });

  test('non-finite userMultiplier is neutralized', () {
    final r = TtsPlaybackRates.compose(
      baseRate: 0.42,
      multiplier: 1,
      userMultiplier: double.nan,
    );
    expect(r.fileRate, closeTo(1, 0.000001));
  });

  test('engine forwards userMultiplier to the file rate', () async {
    final platform = _FakePlatform();
    final engine = TtsPlaybackEngine(
      resolveFile: (text, voice) async => File('cached.mp3'),
      platform: platform,
    );
    final result = engine.speak(
      text: '안녕하세요',
      voice: 'female',
      baseRate: 0.42,
      userMultiplier: 1.5,
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    platform.fileSessions['cached.mp3']?.complete(true);
    await result;
    expect(
      platform.mutations.any((m) => m.startsWith('file:') && m.endsWith(':1.5')),
      isTrue,
      reason: 'mutations: ${platform.mutations}',
    );
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
    'new request promptly stops current audio before blocked resolution',
    () async {
      final platform = _FakePlatform();
      final blockedResolution = Completer<File?>();
      final engine = TtsPlaybackEngine(
        resolveFile: (text, voice) => text == 'first'
            ? Future.value(File('first.mp3'))
            : blockedResolution.future,
        platform: platform,
      );

      final first = engine.speak(
        text: 'first',
        voice: 'female',
        baseRate: 0.42,
      );
      await Future<void>.delayed(Duration.zero);
      final second = engine.speak(
        text: 'second',
        voice: 'female',
        baseRate: 0.42,
      );
      await Future<void>.delayed(Duration.zero);

      expect(await first, isFalse);
      expect(platform.mutations.where((m) => m == 'stop').length, 2);

      blockedResolution.complete(null);
      await Future<void>.delayed(Duration.zero);
      platform.speechSessions['second']!.complete(true);
      expect(await second, isTrue);
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

  test(
    'stop and dispose settle blocked resolvers without releasing them',
    () async {
      for (final shouldDispose in [false, true]) {
        final platform = _FakePlatform();
        final resolution = Completer<File?>();
        final engine = TtsPlaybackEngine(
          resolveFile: (text, voice) => resolution.future,
          platform: platform,
        );
        final pending = engine.speak(
          text: 'blocked',
          voice: 'female',
          baseRate: 0.42,
        );
        await Future<void>.delayed(Duration.zero);

        if (shouldDispose) {
          await engine.dispose();
        } else {
          await engine.stop();
        }
        expect(
          await pending.timeout(const Duration(milliseconds: 100)),
          isFalse,
        );

        resolution.completeError(StateError('late resolver error'));
        await Future<void>.delayed(Duration.zero);
      }
    },
  );

  test('early stop errors stay handled while resolver is blocked', () async {
    final uncaught = <Object>[];
    await runZonedGuarded(() async {
      final platform = _FakePlatform()..throwStops = 2;
      final resolution = Completer<File?>();
      final engine = TtsPlaybackEngine(
        resolveFile: (text, voice) => resolution.future,
        platform: platform,
      );
      final pending = engine.speak(
        text: 'blocked stop error',
        voice: 'female',
        baseRate: 0.42,
      );
      await Future<void>.delayed(Duration.zero);
      await engine.stop();
      expect(await pending.timeout(const Duration(milliseconds: 100)), isFalse);
      resolution.completeError(StateError('late resolver failure'));
      await Future<void>.delayed(Duration.zero);
    }, (error, stack) => uncaught.add(error));

    expect(uncaught, isEmpty);
  });

  test('file completion errors resolve false instead of throwing', () async {
    final platform = _FakePlatform();
    final engine = TtsPlaybackEngine(
      resolveFile: (text, voice) async => File('completion.mp3'),
      platform: platform,
    );

    final result = engine.speak(
      text: 'file error',
      voice: 'female',
      baseRate: 0.42,
    );
    await Future<void>.delayed(Duration.zero);
    platform.fileSessions['completion.mp3']!.completeError(
      StateError('decoder failed'),
    );

    expect(await result, isFalse);
  });

  test('speech completion errors resolve false instead of throwing', () async {
    final platform = _FakePlatform();
    final engine = TtsPlaybackEngine(
      resolveFile: (text, voice) async => null,
      platform: platform,
    );

    final result = engine.speak(
      text: 'speech error',
      voice: 'female',
      baseRate: 0.42,
    );
    await Future<void>.delayed(Duration.zero);
    platform.speechSessions['speech error']!.completeError(
      StateError('TTS completion failed'),
    );

    expect(await result, isFalse);
  });

  test(
    'file and speech completion timeouts return false and stop current audio',
    () async {
      for (final hasFile in [true, false]) {
        final platform = _FakePlatform();
        final errors = <String>[];
        final engine = TtsPlaybackEngine(
          resolveFile: (text, voice) async =>
              hasFile ? File('timeout.mp3') : null,
          platform: platform,
          completionTimeout: const Duration(milliseconds: 10),
          errorReporter: errors.add,
        );

        expect(
          await engine.speak(
            text: hasFile ? 'file timeout' : 'speech timeout',
            voice: 'female',
            baseRate: 0.42,
          ),
          isFalse,
        );
        expect(platform.mutations.last, 'stop');
        expect(errors.single, contains('timed out'));
      }
    },
  );

  test('stale timed-out completion cannot stop newer audio', () async {
    final platform = _FakePlatform();
    final engine = TtsPlaybackEngine(
      resolveFile: (text, voice) async => File('$text.mp3'),
      platform: platform,
      completionTimeout: const Duration(milliseconds: 15),
    );
    final first = engine.speak(text: 'old', voice: 'female', baseRate: 0.42);
    await Future<void>.delayed(Duration.zero);
    final second = engine.speak(text: 'new', voice: 'female', baseRate: 0.42);
    await Future<void>.delayed(Duration.zero);
    platform.fileSessions['new.mp3']!.complete(true);

    expect(await first, isFalse);
    expect(await second, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(platform.mutations, [
      'stop',
      'file:old.mp3:1.0',
      'stop',
      'file:new.mp3:1.0',
    ]);
  });

  test('platform stop and start errors do not poison later requests', () async {
    final platform = _FakePlatform()
      ..throwStops = 1
      ..throwSpeechStarts = 1;
    final engine = TtsPlaybackEngine(
      resolveFile: (text, voice) async => null,
      platform: platform,
    );

    expect(
      await engine.speak(text: 'stop fails', voice: 'female', baseRate: 0.42),
      isFalse,
    );
    expect(
      await engine.speak(text: 'start fails', voice: 'female', baseRate: 0.42),
      isFalse,
    );
    final healthy = engine.speak(
      text: 'healthy',
      voice: 'female',
      baseRate: 0.42,
    );
    await Future<void>.delayed(Duration.zero);
    platform.speechSessions['healthy']!.complete(true);

    expect(await healthy, isTrue);
  });
}

typedef _StartFile =
    Future<TtsPlaybackSession?> Function(File file, double rate);
typedef _StartSpeech =
    Future<TtsPlaybackSession?> Function(String text, double rate);

class _CallbackPlatform implements TtsPlaybackPlatform {
  _CallbackPlatform(this._startFile, this._startSpeech);

  final _StartFile _startFile;
  final _StartSpeech _startSpeech;

  @override
  Future<TtsPlaybackSession?> startFile(File file, double rate) =>
      _startFile(file, rate);

  @override
  Future<TtsPlaybackSession?> startSpeech(String text, double rate) =>
      _startSpeech(text, rate);

  @override
  Future<void> stop() async {}
}
