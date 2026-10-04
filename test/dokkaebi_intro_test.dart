import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/practice_dokkaebi_help.dart';
import 'package:ko_lernen_app/widgets/sori/dokkaebi_flame_frame.dart';
import 'package:ko_lernen_app/widgets/sori/dokkaebi_intro.dart';
import 'package:ko_lernen_app/widgets/sori/tiger_video.dart';
// Exercise the real video controller and lease against a deterministic decoder.
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'support/real_fonts.dart';

class FakeIntroVideo extends VideoPlayerPlatform {
  late final StreamController<VideoEvent> events = StreamController<VideoEvent>(
    sync: true,
    // Create the cancellation future in the widget test's fake-async zone.
    onCancel: () async {},
    onListen: () {
      scheduleMicrotask(() {
        if (pending) {
          return;
        } else if (fail) {
          events.addError(
            PlatformException(code: 'decode', message: 'decoder unavailable'),
          );
        } else {
          events.add(
            VideoEvent(
              eventType: VideoEventType.initialized,
              duration: const Duration(seconds: 8),
              size: const Size(1244, 1660),
            ),
          );
        }
      });
    },
  );
  bool fail = false;
  bool pending = false;
  int allocations = 0, releases = 0;
  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    allocations++;
    return 1;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => events.stream;
  @override
  Future<void> dispose(int playerId) async {
    releases++;
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> play(int playerId) async {}
  @override
  Future<void> pause(int playerId) async {}
  @override
  Future<void> seekTo(int playerId, Duration position) async {}
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox();
}

Widget host(Widget child, {bool reduced = false}) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppL10n.localizationsDelegates,
  supportedLocales: AppL10n.supportedLocales,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(body: SizedBox(width: 342, child: child)),
  ),
);

void main() {
  setUpAll(
    () => loadSoriRealFonts(
      materialIcons: const String.fromEnvironment(
        'DOKKAEBI_REVIEW_DIR',
      ).isNotEmpty,
    ),
  );
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
  });
  for (final variant in [
    (const Size(390, 844), 1.0, false),
    (const Size(812, 375), 1.0, false),
    (const Size(812, 375), 2.0, true),
  ]) {
    testWidgets('app introduction plays when visible: $variant', (
      tester,
    ) async {
      final previous = VideoPlayerPlatform.instance;
      final ready = TigerStageVideo.videoReady;
      final decoder = FakeIntroVideo();
      VideoPlayerPlatform.instance = decoder;
      TigerStageVideo.videoReady = true;
      tester.view.physicalSize = variant.$1;
      tester.view.devicePixelRatio = 1;
      addTearDown(() async {
        VideoPlayerPlatform.instance = previous;
        TigerStageVideo.videoReady = ready;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        unawaited(decoder.events.close());
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: variant.$3 ? AppTheme.dark : AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(variant.$2)),
            child: RepaintBoundary(
              key: const ValueKey('dokkaebi-app-review'),
              child: child!,
            ),
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showPracticeDokkaebiIntroduction(context),
                child: const Text('Meet'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Meet'));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final frame = find.byType(DokkaebiFlameFrame);
      if (variant.$1.height < 600) {
        await tester.ensureVisible(frame);
      }
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(TickerMode.valuesOf(tester.element(frame)).enabled, isTrue);
      expect(decoder.allocations, 1);
      expect(
        tester.widget<DokkaebiIntro>(find.byType(DokkaebiIntro)).staticOnly,
        isFalse,
      );
      final dimensions = tester.getSize(frame);
      expect(dimensions.width / dimensions.height, closeTo(2 / 3, .001));
      expect(tester.takeException(), isNull);
      const reviewDir = String.fromEnvironment('DOKKAEBI_REVIEW_DIR');
      if (reviewDir.isNotEmpty) {
        decoder.events.add(VideoEvent(eventType: VideoEventType.completed));
        await tester.pump();
        // Drain asset decoding before capturing the actual app sheet.
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        });
        await tester.pump();
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('dokkaebi-app-review')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '$reviewDir/app-${variant.$1.width.toInt()}-${variant.$2}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox.shrink());
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(decoder.releases, 1);
    });
  }
  testWidgets('one-shot completion releases decoder and calls back once', (
    tester,
  ) async {
    final previous = VideoPlayerPlatform.instance;
    final decoder = FakeIntroVideo();
    VideoPlayerPlatform.instance = decoder;
    addTearDown(() async {
      VideoPlayerPlatform.instance = previous;
      unawaited(decoder.events.close());
    });
    var completed = 0;
    await tester.pumpWidget(host(DokkaebiIntro(onFinished: () => completed++)));
    await tester.pump();
    for (var drain = 0; drain < 5; drain++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(decoder.allocations, 1);
    decoder.events.add(VideoEvent(eventType: VideoEventType.completed));
    await tester.pump();
    for (var drain = 0; drain < 5; drain++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(completed, 1);
    expect(decoder.releases, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    for (var drain = 0; drain < 5; drain++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(decoder.releases, 1);
    expect(completed, 1);
  });
  testWidgets(
    'decoder failure keeps final artwork and does not hang introduction',
    (tester) async {
      final previous = VideoPlayerPlatform.instance;
      final decoder = FakeIntroVideo()..fail = true;
      VideoPlayerPlatform.instance = decoder;
      addTearDown(() async {
        VideoPlayerPlatform.instance = previous;
        unawaited(decoder.events.close());
      });
      var completed = 0;
      await tester.pumpWidget(
        host(DokkaebiIntro(onFinished: () => completed++)),
      );
      await tester.pump();
      for (var drain = 0; drain < 5; drain++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump();
      expect(completed, 1);
      expect(
        find.image(
          const ResizeImage(AssetImage(DokkaebiIntro.finalAsset), width: 768),
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      for (var drain = 0; drain < 5; drain++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('interrupted introduction completes without replay on return', (
    tester,
  ) async {
    final previous = VideoPlayerPlatform.instance;
    final decoder = FakeIntroVideo();
    VideoPlayerPlatform.instance = decoder;
    addTearDown(() {
      VideoPlayerPlatform.instance = previous;
      unawaited(decoder.events.close());
    });
    var completed = 0;
    final intro = DokkaebiIntro(onFinished: () => completed++);
    await tester.pumpWidget(host(TickerMode(enabled: true, child: intro)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(decoder.allocations, 1);
    await tester.pumpWidget(host(TickerMode(enabled: false, child: intro)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(completed, 1);
    expect(decoder.releases, 1);
    await tester.pumpWidget(host(TickerMode(enabled: true, child: intro)));
    await tester.pump(const Duration(seconds: 10));
    expect(decoder.allocations, 1);
    expect(completed, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
  testWidgets('visible pending decoder reaches bounded final fallback', (
    tester,
  ) async {
    final previous = VideoPlayerPlatform.instance;
    final decoder = FakeIntroVideo()..pending = true;
    VideoPlayerPlatform.instance = decoder;
    addTearDown(() {
      VideoPlayerPlatform.instance = previous;
      unawaited(decoder.events.close());
    });
    var completed = 0;
    await tester.pumpWidget(host(DokkaebiIntro(onFinished: () => completed++)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(completed, 0);
    await tester.pump(const Duration(seconds: 8));
    expect(completed, 1);
    // A late decoder result is released instead of publishing stale playback.
    decoder.events.add(
      VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(seconds: 8),
        size: const Size(1244, 1660),
      ),
    );
    await tester.pump();
    expect(decoder.releases, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(completed, 1);
    expect(tester.takeException(), isNull);
  });
  test(
    'actual Flutter shader changes flames but leaves carved rim pixel-identical',
    () async {
      final data = await rootBundle.load(DokkaebiFlameFrame.assets.first);
      final other = await rootBundle.load(DokkaebiFlameFrame.assets[10]);
      Future<ui.Image> decode(ByteData data) async {
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
          targetWidth: 342,
        );
        final frame = await codec.getNextFrame();
        codec.dispose();
        return frame.image;
      }

      final a = await decode(data), b = await decode(other);
      final shader = (await ui.FragmentProgram.fromAsset(
        DokkaebiFlameFrame.shaderAsset,
      )).fragmentShader();
      Future<ByteData> render(ui.Image phase, double time) async {
        shader
          ..setFloat(0, 342)
          ..setFloat(1, 513)
          ..setFloat(2, time)
          ..setFloat(3, 0)
          ..setFloat(4, 1)
          ..setImageSampler(0, a)
          ..setImageSampler(1, phase)
          ..setImageSampler(2, phase);
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawRect(
          const Rect.fromLTWH(0, 0, 342, 513),
          Paint()..shader = shader,
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(342, 513);
        final bytes = await image.toByteData();
        image.dispose();
        picture.dispose();
        return bytes!;
      }

      try {
        final first = await render(a, 0), next = await render(b, 1.23);
        var changes = 0;
        for (var y = 0; y < 513; y++) {
          for (var x = 0; x < 342; x++) {
            final u = (x + .5) / 342, v = (y + .5) / 513;
            final k = (y * 342 + x) * 4;
            final same = first.getUint32(k) == next.getUint32(k);
            final rim =
                u > .069 &&
                u < .936 &&
                v > .105 &&
                v < .898 &&
                !(u > .170 && u < .831 && v > .157 && v < .823);
            if (rim) {
              expect(same, true, reason: 'carved frame moved at $x,$y');
            } else if (!same) {
              changes++;
            }
          }
        }
        expect(changes, greaterThan(1000));
      } finally {
        shader.dispose();
        a.dispose();
        b.dispose();
      }
    },
  );
  test(
    'sixteen phases cover the whole cycle and join the final phase to A',
    () {
      expect(
        DokkaebiFlameFrame.durations.reduce((a, b) => a + b),
        closeTo(1.8, 1e-10),
      );
      var t = 0.0;
      for (var i = 0; i < 16; i++) {
        final d = DokkaebiFlameFrame.durations[i];
        expect(DokkaebiFlameFrame.sample(t + d / 2).first, i);
        expect(DokkaebiFlameFrame.sample(t + d / 2).blend, closeTo(.5, 1e-9));
        t += d;
      }
      expect(DokkaebiFlameFrame.sample(1.799).second, 0);
      expect(DokkaebiFlameFrame.sample(1.8).first, 0);
      expect(
        DokkaebiFlameFrame.sample(2.73).blend,
        closeTo(DokkaebiFlameFrame.sample(.93).blend, 1e-10),
      );
    },
  );
  testWidgets('reduced motion shows final artwork and completes exactly once', (
    tester,
  ) async {
    var completed = 0;
    final intro = DokkaebiIntro(onFinished: () => completed++);
    await tester.pumpWidget(host(intro, reduced: true));
    await tester.pump();
    expect(completed, 1);
    expect(
      tester
          .widget<DokkaebiFlameFrame>(find.byType(DokkaebiFlameFrame))
          .animate,
      false,
    );
    expect(
      find.image(
        const ResizeImage(AssetImage(DokkaebiIntro.finalAsset), width: 768),
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 10));
    expect(completed, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    for (var drain = 0; drain < 5; drain++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets('static introduction leaves no pending completion after exit', (
    tester,
  ) async {
    var completed = 0;
    await tester.pumpWidget(
      host(DokkaebiIntro(staticOnly: true, onFinished: () => completed++)),
    );
    await tester.pump();
    expect(completed, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 10));
    for (var drain = 0; drain < 5; drain++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(completed, 1);
    expect(tester.takeException(), isNull);
  });
}
