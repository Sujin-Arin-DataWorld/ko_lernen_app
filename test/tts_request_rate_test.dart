import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
  });

  test('effective rate composes base preference and request multiplier', () {
    final cases = <({double base, double multiplier, double expected})>[
      (base: 0.4, multiplier: 0.75, expected: 0.3),
      (base: 0.4, multiplier: 1.0, expected: 0.4),
      (base: 0.4, multiplier: 1.25, expected: 0.5),
      (base: 0.1, multiplier: 0.5, expected: 0.1),
      (base: 0.9, multiplier: 2.0, expected: 1.0),
    ];

    for (final testCase in cases) {
      expect(
        TtsPlaybackEngine.composePlaybackRate(
          baseRate: testCase.base,
          multiplier: testCase.multiplier,
        ),
        closeTo(testCase.expected, 0.000001),
      );
    }
  });

  test(
    'cached audio and OS fallback receive the same effective rate',
    () async {
      final cachedRates = <double>[];
      final fallbackRates = <double>[];
      final cachedFile = File('cached.mp3');

      final cachedEngine = TtsPlaybackEngine(
        resolveFile: (text, voice) async => cachedFile,
        playFile: (file, rate) async {
          cachedRates.add(rate);
          return true;
        },
        playFallback: (text, rate) async {
          fail('fallback must not run when cached audio exists');
        },
      );
      final fallbackEngine = TtsPlaybackEngine(
        resolveFile: (text, voice) async => null,
        playFile: (file, rate) async {
          fail('file playback must not run without audio');
        },
        playFallback: (text, rate) async {
          fallbackRates.add(rate);
          return true;
        },
      );

      await cachedEngine.speak(
        text: '안녕하세요',
        voice: 'female',
        baseRate: 0.4,
        rateMultiplier: 1.25,
      );
      await fallbackEngine.speak(
        text: '안녕하세요',
        voice: 'female',
        baseRate: 0.4,
        rateMultiplier: 1.25,
      );

      expect(cachedRates, [closeTo(0.5, 0.000001)]);
      expect(fallbackRates, [closeTo(0.5, 0.000001)]);
    },
  );

  test(
    'playback multiplier does not enter audio cache resolution semantics',
    () async {
      final resolutions = <String>[];
      final engine = TtsPlaybackEngine(
        resolveFile: (text, voice) async {
          resolutions.add('$voice|$text');
          return null;
        },
        playFile: (file, rate) async => true,
        playFallback: (text, rate) async => true,
      );

      await engine.speak(
        text: '같은 음성',
        voice: 'female',
        baseRate: 0.4,
        rateMultiplier: 0.75,
      );
      await engine.speak(
        text: '같은 음성',
        voice: 'female',
        baseRate: 0.4,
        rateMultiplier: 1.25,
      );

      expect(resolutions, ['female|같은 음성', 'female|같은 음성']);
    },
  );

  test(
    'overlapping requests keep independent rates without mutating preference',
    () async {
      await Storage.setTtsRate(0.4);
      final firstEntered = Completer<void>();
      final secondEntered = Completer<void>();
      final releaseFirst = Completer<void>();
      final releaseSecond = Completer<void>();
      final fallbackRates = <String, double>{};

      final engine = TtsPlaybackEngine(
        resolveFile: (text, voice) async {
          if (text == 'first') {
            firstEntered.complete();
            await releaseFirst.future;
          } else {
            secondEntered.complete();
            await releaseSecond.future;
          }
          return null;
        },
        playFile: (file, rate) async => true,
        playFallback: (text, rate) async {
          fallbackRates[text] = rate;
          return true;
        },
      );

      final first = engine.speak(
        text: 'first',
        voice: 'female',
        baseRate: Storage.ttsRate,
        rateMultiplier: 0.75,
      );
      await firstEntered.future;
      final second = engine.speak(
        text: 'second',
        voice: 'female',
        baseRate: Storage.ttsRate,
        rateMultiplier: 1.25,
      );
      await secondEntered.future;

      releaseSecond.complete();
      await second;
      releaseFirst.complete();
      await first;

      expect(fallbackRates['first'], closeTo(0.3, 0.000001));
      expect(fallbackRates['second'], closeTo(0.5, 0.000001));
      expect(Storage.ttsRate, 0.4);
    },
  );
}
