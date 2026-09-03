import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/tts_service.dart';

class _FakePlatform implements TtsPlaybackPlatform {
  final mutations = <String>[];
  final fileSessions = <String, Completer<bool>>{};
  bool failFileStart = false;
  int throwFileStarts = 0;
  int throwStops = 0;

  @override
  Future<TtsPlaybackSession?> startAudio(TtsAudio audio, double rate) async {
    final id = audio.path ?? 'bytes:${audio.bytes!.length}';
    mutations.add('file:$id:$rate');
    if (throwFileStarts > 0) {
      throwFileStarts--;
      await Future<void>.delayed(Duration.zero);
      throw StateError('async file start failure');
    }
    if (failFileStart) return null;
    final completion = Completer<bool>();
    fileSessions[id] = completion;
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
  for (final stage in ['stop', 'start', 'completion', 'timeout']) {
    test('device $stage failure has a distinct playback diagnosis', () async {
      final platform = _FakePlatform()
        ..throwStops = stage == 'stop' ? 1 : 0
        ..failFileStart = stage == 'start';
      final playbackFailures = <String>[];
      final resolutionFailures = <String>[];
      final engine = TtsPlaybackEngine(
        resolveAudio: (text, voice) async => const TtsAudio.path('test.mp3'),
        platform: platform,
        completionTimeout: const Duration(milliseconds: 20),
        onPlaybackFailed: playbackFailures.add,
        onResolutionFailed: resolutionFailures.add,
      );
      final result = engine.speak(
        text: '안녕하세요',
        voice: 'female',
        baseRate: 0.42,
      );
      if (stage == 'completion') {
        await Future<void>.delayed(Duration.zero);
        platform.fileSessions['test.mp3']!.complete(false);
      }

      expect(await result, isFalse);
      expect(playbackFailures, hasLength(1));
      expect(resolutionFailures, isEmpty);
      await engine.dispose();
    });
  }

  test('explicitly stopped playback does not show a device failure', () async {
    final platform = _FakePlatform();
    final failures = <String>[];
    final engine = TtsPlaybackEngine(
      resolveAudio: (text, voice) async => const TtsAudio.path('test.mp3'),
      platform: platform,
      onPlaybackFailed: failures.add,
    );
    final result = engine.speak(text: '안녕하세요', voice: 'female', baseRate: 0.42);
    await Future<void>.delayed(Duration.zero);
    await engine.stop();
    expect(await result, isFalse);
    expect(failures, isEmpty);
    platform.fileSessions['test.mp3']!.complete(false);
    await engine.dispose();
  });

  test('speech context bypasses iOS silent mode and ducks other audio', () {
    final context = TtsSpeechAudioContext.build();

    expect(context.android.usageType, AndroidUsageType.media);
    expect(context.android.audioFocus, AndroidAudioFocus.gainTransientMayDuck);
    expect(context.iOS.category, AVAudioSessionCategory.playback);
    expect(context.iOS.options, contains(AVAudioSessionOptions.duckOthers));
  });

  test('speech context is reapplied before every utterance', () async {
    final contexts = <AudioContext>[];
    Future<void> record(AudioContext context) async => contexts.add(context);

    await TtsSpeechAudioContext.reapply(record, isWeb: false);
    await TtsSpeechAudioContext.reapply(record, isWeb: false);

    expect(contexts, hasLength(2));
    expect(contexts[0], contexts[1]);
  });

  test('speech context failure is retried by the next utterance', () async {
    var attempts = 0;
    Future<void> failOnce(AudioContext context) async {
      attempts++;
      if (attempts == 1) {
        throw StateError('audio session was temporarily unavailable');
      }
    }

    await TtsSpeechAudioContext.reapply(failOnce, isWeb: false);
    await TtsSpeechAudioContext.reapply(failOnce, isWeb: false);

    expect(attempts, 2);
  });

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

  test('async file play failure stays contained without throwing', () async {
    final platform = _CallbackPlatform((audio, rate) async {
      // Mirrors production _startAudio: await the helper so its asynchronous
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
    });
    final engine = TtsPlaybackEngine(
      resolveAudio: (text, voice) async => TtsAudio.path('broken.mp3'),
      platform: platform,
    );

    expect(
      await engine.speak(text: 'broken audio', voice: 'female', baseRate: 0.42),
      isFalse,
    );
  });

  test(
    'async rate cleanup failure is contained without unsafe fallback',
    () async {
      final platform = _CallbackPlatform(
        (audio, rate) => TtsFilePlayback.start(
          completion: Future.value(true),
          play: () async {},
          setRate: (rate) async => throw StateError('rate failure'),
          stop: () async => throw StateError('cleanup failure'),
          rate: rate,
        ),
      );
      final engine = TtsPlaybackEngine(
        resolveAudio: (text, voice) async => TtsAudio.path('rate.mp3'),
        platform: platform,
      );

      final result = engine.speak(
        text: 'rate fallback',
        voice: 'female',
        baseRate: 0.42,
      );
      expect(await result, isFalse);
    },
  );

  test('missing completed audio does not fall back to OS speech', () async {
    final platform = _FakePlatform();
    final errors = <String>[];
    final engine = TtsPlaybackEngine(
      resolveAudio: (text, voice) async => throw const TtsSynthesisBlocked(
        TtsCallableFailure.audioUnavailableMessage,
      ),
      platform: platform,
      errorReporter: errors.add,
    );

    expect(
      await engine.speak(
        text: 'missing audio',
        voice: 'female',
        baseRate: 0.42,
      ),
      isFalse,
    );
    expect(platform.fileSessions, isEmpty);
    expect(errors, contains(TtsCallableFailure.audioUnavailableMessage));
  });

  test('quota blocks do not fall back to OS speech', () async {
    final platform = _FakePlatform();
    final errors = <String>[];
    final engine = TtsPlaybackEngine(
      resolveAudio: (text, voice) async =>
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
    expect(platform.fileSessions, isEmpty);
    expect(errors, contains('Daily synthesis limit reached.'));
  });

  test('resolver errors settle false and never start playback', () async {
    final platform = _FakePlatform();
    final engine = TtsPlaybackEngine(
      resolveAudio: (text, voice) async =>
          throw StateError('cache unavailable'),
      platform: platform,
    );

    expect(
      await engine.speak(
        text: 'resolver error',
        voice: 'female',
        baseRate: 0.42,
      ),
      isFalse,
    );
    expect(platform.fileSessions, isEmpty);
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
      resolveAudio: (text, voice) async => TtsAudio.path('cached.mp3'),
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
      platform.mutations.any(
        (m) => m.startsWith('file:') && m.endsWith(':1.5'),
      ),
      isTrue,
      reason: 'mutations: ${platform.mutations}',
    );
  });

  test('a refused file start stays silent instead of speaking', () async {
    final platform = _FakePlatform()..failFileStart = true;
    final engine = TtsPlaybackEngine(
      resolveAudio: (text, voice) async => TtsAudio.path('cached.mp3'),
      platform: platform,
    );

    expect(
      await engine.speak(text: '안녕하세요', voice: 'female', baseRate: 0.42),
      isFalse,
    );
    expect(platform.mutations, ['stop', 'file:cached.mp3:1.0']);
  });

  test(
    'playback multiplier remains independent of cache resolution key',
    () async {
      final platform = _FakePlatform();
      final resolutions = <String>[];
      final engine = TtsPlaybackEngine(
        resolveAudio: (text, voice) async {
          resolutions.add('$voice|$text');
          return null;
        },
        platform: platform,
      );

      for (final multiplier in [0.75, 1.25]) {
        await engine.speak(
          text: '같은 음성',
          voice: 'female',
          baseRate: 0.42,
          rateMultiplier: multiplier,
        );
      }

      expect(resolutions, ['female|같은 음성', 'female|같은 음성']);
    },
  );

  test(
    'older slow resolution performs no mutations after newer starts',
    () async {
      final platform = _FakePlatform();
      final releaseOld = Completer<TtsAudio?>();
      final engine = TtsPlaybackEngine(
        resolveAudio: (text, voice) => text == 'old'
            ? releaseOld.future
            : Future.value(TtsAudio.path('new.mp3')),
        platform: platform,
      );

      final old = engine.speak(text: 'old', voice: 'female', baseRate: 0.42);
      final newer = engine.speak(text: 'new', voice: 'female', baseRate: 0.42);
      await Future<void>.delayed(Duration.zero);
      releaseOld.complete(TtsAudio.path('old.mp3'));
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
      final blockedResolution = Completer<TtsAudio?>();
      final engine = TtsPlaybackEngine(
        resolveAudio: (text, voice) => text == 'first'
            ? Future.value(TtsAudio.path('first.mp3'))
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
      expect(await second, isFalse);
    },
  );

  test('an unresolved request never taints the next request rate', () async {
    final platform = _FakePlatform();
    final missResolution = Completer<TtsAudio?>();
    final engine = TtsPlaybackEngine(
      resolveAudio: (text, voice) => text == 'miss'
          ? missResolution.future
          : Future.value(TtsAudio.path('file.mp3')),
      platform: platform,
    );

    final miss = engine.speak(
      text: 'miss',
      voice: 'female',
      baseRate: 0.42,
      rateMultiplier: 0.75,
    );
    missResolution.complete(null);
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
    expect(await miss, isFalse);
    expect(platform.mutations, contains('file:file.mp3:1.25'));
    expect(
      platform.mutations.where((m) => m.startsWith('file:')),
      hasLength(1),
      reason: '해결 못 한 요청은 재생을 시작하지 않는다',
    );
  });

  test('stop and dispose invalidate pending resolution', () async {
    for (final shouldDispose in [false, true]) {
      final platform = _FakePlatform();
      final resolution = Completer<TtsAudio?>();
      final engine = TtsPlaybackEngine(
        resolveAudio: (text, voice) => resolution.future,
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
      resolution.complete(TtsAudio.path('late.mp3'));
      expect(await pending, isFalse);
      expect(platform.mutations.where((m) => m.startsWith('file:')), isEmpty);
    }
  });

  test(
    'stop and dispose settle blocked resolvers without releasing them',
    () async {
      for (final shouldDispose in [false, true]) {
        final platform = _FakePlatform();
        final resolution = Completer<TtsAudio?>();
        final engine = TtsPlaybackEngine(
          resolveAudio: (text, voice) => resolution.future,
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
      final resolution = Completer<TtsAudio?>();
      final engine = TtsPlaybackEngine(
        resolveAudio: (text, voice) => resolution.future,
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
      resolveAudio: (text, voice) async => TtsAudio.path('completion.mp3'),
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

  test('a resolved miss resolves false without starting playback', () async {
    final platform = _FakePlatform();
    final engine = TtsPlaybackEngine(
      resolveAudio: (text, voice) async => null,
      platform: platform,
    );

    expect(
      await engine.speak(
        text: 'no premium audio',
        voice: 'female',
        baseRate: 0.42,
      ),
      isFalse,
    );
    expect(platform.fileSessions, isEmpty);
    expect(platform.mutations.where((m) => m.startsWith('file:')), isEmpty);
  });

  test('completion timeouts return false and stop the current audio', () async {
    final platform = _FakePlatform();
    final errors = <String>[];
    final engine = TtsPlaybackEngine(
      resolveAudio: (text, voice) async => TtsAudio.path('timeout.mp3'),
      platform: platform,
      completionTimeout: const Duration(milliseconds: 10),
      errorReporter: errors.add,
    );

    expect(
      await engine.speak(text: 'file timeout', voice: 'female', baseRate: 0.42),
      isFalse,
    );
    expect(platform.mutations.last, 'stop');
    expect(errors.single, contains('timed out'));
  });

  test('stale timed-out completion cannot stop newer audio', () async {
    final platform = _FakePlatform();
    final engine = TtsPlaybackEngine(
      resolveAudio: (text, voice) async => TtsAudio.path('$text.mp3'),
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
      ..throwFileStarts = 1;
    final engine = TtsPlaybackEngine(
      resolveAudio: (text, voice) async => TtsAudio.path('$text.mp3'),
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
    platform.fileSessions['healthy.mp3']!.complete(true);

    expect(await healthy, isTrue);
  });
}

typedef _StartAudio =
    Future<TtsPlaybackSession?> Function(TtsAudio audio, double rate);

class _CallbackPlatform implements TtsPlaybackPlatform {
  _CallbackPlatform(this._startAudio);

  final _StartAudio _startAudio;

  @override
  Future<TtsPlaybackSession?> startAudio(TtsAudio audio, double rate) =>
      _startAudio(audio, rate);

  @override
  Future<void> stop() async {}
}
