import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/widgets/sori/dokkaebi_reward_movie.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_haptics_enabled': false});
    await Storage.init();
  });
  testWidgets('Flutter decodes all 121 full square alpha movie frames', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final data = await File(
        'assets/animations/rewards/making_money.webp',
      ).readAsBytes();
      final codec = await ui.instantiateImageCodec(data);
      try {
        expect(codec.frameCount, 121);
        var duration = Duration.zero;
        for (var i = 0; i < codec.frameCount; i++) {
          final frame = await codec.getNextFrame();
          try {
            expect(frame.image.width, 960);
            expect(frame.image.height, 960);
            duration += frame.duration;
            if (i == 0 || i == 89 || i == 120) {
              final pixels = (await frame.image.toByteData())!;
              for (final index in [
                3,
                959 * 4 + 3,
                959 * 960 * 4 + 3,
                (960 * 960 - 1) * 4 + 3,
              ]) {
                expect(pixels.getUint8(index), 0);
              }
            }
          } finally {
            frame.image.dispose();
          }
        }
        expect(duration.inMilliseconds, 5041);
      } finally {
        codec.dispose();
      }
    });
  });
  testWidgets(
    'actual movie cue occurs once; replay and skip only settle presentation',
    (tester) async {
      final key = GlobalKey<DokkaebiRewardMovieState>();
      var cues = 0, settled = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: DokkaebiRewardMovie(
            key: key,
            size: 220,
            onCreditCue: () => cues++,
            onSettled: () => settled++,
            onPlaybackChanged: () {},
          ),
        ),
      );
      for (var i = 0; i < 210 && settled == 0; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 12)),
        );
        await tester.pump(const Duration(milliseconds: 43));
      }
      expect(cues, 1);
      expect(settled, 1);
      expect(key.currentState!.playing, isFalse);
      key.currentState!.replay();
      await tester.pump();
      expect(key.currentState!.playing, isTrue);
      key.currentState!.settle();
      await tester.pump();
      expect(cues, 1);
      expect(settled, 2);
      expect(key.currentState!.soundEnabled, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'missing media settles once and exposes an uncropped static frame',
    (tester) async {
      var settled = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: DokkaebiRewardMovie(
            size: 220,
            asset: 'missing-review-movie.webp',
            onCreditCue: () {},
            onSettled: () => settled++,
            onPlaybackChanged: () {},
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      await tester.pump();
      expect(settled, 1);
      expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.contain);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'an invalidated lifetime releases playback without an old receipt callback',
    (tester) async {
      final key = GlobalKey<DokkaebiRewardMovieState>();
      var cues = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: DokkaebiRewardMovie(
            key: key,
            size: 220,
            onCreditCue: () => cues++,
            onSettled: () {},
            onPlaybackChanged: () {},
          ),
        ),
      );
      LocalDataLifetime.invalidate();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(key.currentState!.playing, isFalse);
      expect(cues, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );
}
