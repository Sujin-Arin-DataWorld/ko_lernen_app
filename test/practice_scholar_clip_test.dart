import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/practice_history_store.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/practice_guide.dart';
import 'package:ko_lernen_app/widgets/practice_dokkaebi_help.dart';
import 'package:ko_lernen_app/widgets/practice_character_clip.dart';
import 'package:ko_lernen_app/widgets/practice_dokkaebi_clip.dart';
import 'package:ko_lernen_app/widgets/practice_dokkaebi_art.dart';
import 'package:ko_lernen_app/widgets/practice_scholar_clip.dart';
import 'package:ko_lernen_app/widgets/practice_scholar_explanation.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/widgets/sori/route_observer.dart';
import 'package:ko_lernen_app/widgets/sori/tiger_video.dart';
import 'package:ko_lernen_app/widgets/sori/video_lease.dart';
import 'package:ko_lernen_app/widgets/sori/dokkaebi_intro.dart';
import 'package:ko_lernen_app/widgets/sori/dokkaebi_flame_frame.dart';

class _DelayedArtworkBundle extends CachingAssetBundle {
  final helping = Completer<ByteData>();
  @override
  Future<ByteData> load(String key) => key == PracticeDokkaebiPose.helping.asset
      ? helping.future
      : rootBundle.load(key);
}

class _VideoPlatform extends VideoPlayerPlatform {
  final events = StreamController<VideoEvent>.broadcast(sync: true);
  final volumes = <double>[];
  final volumesAtPlay = <double>[];
  final looping = <bool>[];
  final assets = <String?>[];
  int creates = 0, plays = 0, disposes = 0;
  bool fail = false;
  Duration position = Duration.zero;
  @override
  Future<void> init() async {}

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    creates++;
    assets.add(options.dataSource.asset);
    if (fail) {
      throw StateError('decoder failure');
    }
    return 1;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int id) {
    scheduleMicrotask(
      () => events.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(seconds: 2),
          size: const Size(1080, 1920),
        ),
      ),
    );
    return events.stream;
  }

  @override
  Future<void> setVolume(int id, double volume) async => volumes.add(volume);
  @override
  Future<void> setLooping(int id, bool loop) async => looping.add(loop);
  @override
  Future<void> setPlaybackSpeed(int id, double speed) async {}
  @override
  Future<void> play(int id) async {
    plays++;
    volumesAtPlay.add(volumes.last);
  }

  @override
  Future<void> pause(int id) async {}
  @override
  Future<void> seekTo(int id, Duration position) async {}
  @override
  Future<Duration> getPosition(int id) async => position;
  @override
  Future<void> dispose(int id) async {
    disposes++;
  }

  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox();
}

void main() {
  Future<void> flushNativeFutures(WidgetTester tester) async {
    // The platform stream is created outside the widget's fake timer zone.
    // Yield the real cancellation future, then flush the widget microtasks.
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump();
    }
  }

  late _VideoPlatform platform;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
    platform = _VideoPlatform();
    VideoPlayerPlatform.instance = platform;
    TigerStageVideo.videoReady = true;
  });
  tearDown(() async {
    await soriVideoLease.settle();
    await platform.events.close();
    TigerStageVideo.videoReady = false;
  });

  Widget app({
    bool reduce = false,
    bool dark = false,
    bool accessible = false,
    VoidCallback? onRequested,
  }) => MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    navigatorObservers: [soriRouteObserver],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(disableAnimations: reduce, accessibleNavigation: accessible),
      child: child!,
    ),
    home: Scaffold(
      body: SizedBox(
        width: 90,
        height: 160,
        child: PracticeScholarClip(
          play: true,
          explaining: true,
          onRequested: onRequested,
        ),
      ),
    ),
  );

  testWidgets('a cold helping pose keeps the decoded idle character visible', (
    tester,
  ) async {
    final bundle = _DelayedArtworkBundle();
    Widget art(PracticeDokkaebiPose pose) => DefaultAssetBundle(
      bundle: bundle,
      child: MaterialApp(
        home: SizedBox.square(
          dimension: 176,
          child: PracticeDokkaebiArt(pose: pose),
        ),
      ),
    );
    await tester.pumpWidget(art(PracticeDokkaebiPose.ready));
    final initialArtwork = find.byType(Image).first;
    await tester.runAsync(
      () => precacheImage(
        tester.widget<Image>(initialArtwork).image,
        tester.element(initialArtwork),
      ),
    );
    await tester.pump();
    final idle = tester.widget<RawImage>(find.byType(RawImage)).image;
    expect(idle, isNotNull);
    await tester.pumpWidget(art(PracticeDokkaebiPose.helping));
    // The replacement deliberately cannot decode yet. The old pixels must stay.
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, same(idle));
    final helping = await tester.runAsync(
      () => rootBundle.load(PracticeDokkaebiPose.helping.asset),
    );
    bundle.helping.complete(helping!);
    await flushNativeFutures(tester);
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'dokkaebi fires move and one floor impact never places a tile or grants XP',
    (tester) async {
      var impacts = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          navigatorObservers: [soriRouteObserver],
          home: Scaffold(
            body: PracticeDokkaebiStage(
              requestId: 1,
              play: true,
              helping: true,
              onImpact: () => impacts++,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      await flushNativeFutures(tester);
      final fire = find.byKey(const ValueKey('dokkaebi-fire-0'));
      final transform = find
          .ancestor(of: fire, matching: find.byType(Transform))
          .first;
      final before = tester.widget<Transform>(transform).transform.clone();
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.widget<Transform>(transform).transform, isNot(before));
      expect(impacts, 0);
      // Buffered/startup time is not playback time. Resuming before the old
      // wall-clock deadline still cannot strike before the native contact frame.
      platform.events.add(VideoEvent(eventType: VideoEventType.bufferingStart));
      await tester.pump(const Duration(milliseconds: 400));
      platform.position = const Duration(milliseconds: 100);
      platform.events.add(VideoEvent(eventType: VideoEventType.bufferingEnd));
      await tester.pump(const Duration(milliseconds: 750));
      expect(impacts, 0);
      platform.position = const Duration(milliseconds: 1299);
      await tester.pump(const Duration(milliseconds: 50));
      await flushNativeFutures(tester);
      expect(impacts, 0);
      platform.position = const Duration(milliseconds: 1300);
      await tester.pump(const Duration(milliseconds: 50));
      await flushNativeFutures(tester);
      expect(impacts, 1);
      await tester.pump(const Duration(milliseconds: 500));
      expect(impacts, 1);
      expect(platform.plays, 1);
      expect(platform.volumesAtPlay, [0]);
      expect(Storage.xp, 0);
      expect(Storage.gameBest('skz_a1'), 0);
      platform.events.add(VideoEvent(eventType: VideoEventType.completed));
      await tester.pump();
      await flushNativeFutures(tester);
      final endPoster = find.descendant(
        of: find.byType(PracticeCharacterClip),
        matching: find.byType(Image),
      );
      expect(
        (tester.widget<Image>(endPoster).image as AssetImage).assetName,
        'assets/video/practice/dokkaebi_hint_end.png',
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is PracticeDokkaebiArt &&
              w.pose == PracticeDokkaebiPose.helping,
        ),
        findsNothing,
      );
      await tester.pump(const Duration(seconds: 3));
      expect(platform.plays, 1);
      expect(impacts, 1);
      await tester.pumpWidget(const SizedBox());
      await flushNativeFutures(tester);
      expect(platform.disposes, 1);
    },
  );

  testWidgets('decoder startup keeps the matching poster until time advances', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pump();
    await flushNativeFutures(tester);
    await tester.pump(const Duration(milliseconds: 300));
    // The native surface stays mounted so it can decode under an opaque poster.
    expect(find.byType(VideoPlayer), findsOneWidget);
    final cover = find.descendant(
      of: find.byType(PracticeCharacterClip),
      matching: find.byType(AnimatedOpacity),
    );
    expect(tester.widget<AnimatedOpacity>(cover).opacity, 1);
    final stack = tester.widget<Stack>(
      find.descendant(
        of: find.byType(PracticeCharacterClip),
        matching: find.byType(Stack),
      ),
    );
    expect(stack.children.last, isA<AnimatedOpacity>());
    final poster = find.descendant(
      of: find.byType(PracticeCharacterClip),
      matching: find.byType(Image),
    );
    expect(poster, findsOneWidget);
    expect(tester.widget<Image>(poster).gaplessPlayback, isTrue);
    platform.position = const Duration(milliseconds: 100);
    await tester.pump(const Duration(milliseconds: 50));
    await flushNativeFutures(tester);
    expect(tester.widget<AnimatedOpacity>(cover).opacity, 0);
    platform.events.add(VideoEvent(eventType: VideoEventType.completed));
    await tester.pump();
    await flushNativeFutures(tester);
    expect(tester.widget<AnimatedOpacity>(cover).opacity, 1);
    expect(tester.widget<AnimatedOpacity>(cover).duration, Duration.zero);
    await tester.pumpWidget(const SizedBox());
    await flushNativeFutures(tester);
    expect(platform.disposes, 1);
  });

  testWidgets(
    'requested hints alternate MP4s with their own contact and final poster',
    (tester) async {
      var impacts = 0;
      for (var request = 1; request <= 4; request++) {
        platform.position = Duration.zero;
        final clip = request.isOdd
            ? PracticeDokkaebiClip.strike
            : PracticeDokkaebiClip.swing;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            navigatorObservers: [soriRouteObserver],
            home: Scaffold(
              body: PracticeDokkaebiStage(
                requestId: request,
                play: true,
                helping: true,
                onImpact: () => impacts++,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        await flushNativeFutures(tester);
        expect(platform.assets.last, clip.videoAsset);
        expect(platform.plays, request);
        final image = find.descendant(
          of: find.byType(PracticeCharacterClip),
          matching: find.byType(Image),
        );
        expect(
          (tester.widget<Image>(image).image as AssetImage).assetName,
          clip.startAsset,
        );
        // Each clip has a different contact time. Only the visual response
        // changes: the actual hint remains immediately usable throughout.
        platform.position = clip.impactAt;
        await tester.pump(clip.impactAt);
        expect(impacts, request);
        platform.events.add(VideoEvent(eventType: VideoEventType.completed));
        await tester.pump();
        await flushNativeFutures(tester);
        expect(
          (tester.widget<Image>(image).image as AssetImage).assetName,
          clip.endAsset,
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(platform.plays, request);
        expect(impacts, request);
      }
      expect(platform.assets, [
        PracticeDokkaebiClip.strike.videoAsset,
        PracticeDokkaebiClip.swing.videoAsset,
        PracticeDokkaebiClip.strike.videoAsset,
        PracticeDokkaebiClip.swing.videoAsset,
      ]);
      expect(platform.volumesAtPlay, [0, 0, 0, 0]);
      expect(platform.looping.where((value) => value), isEmpty);
      expect(Storage.xp, 0);
      expect(Storage.gameBest('skz_a1'), 0);
      await tester.pumpWidget(const SizedBox());
      await flushNativeFutures(tester);
      expect(platform.disposes, 4);
    },
  );

  testWidgets(
    'introduction opens the approved frame and preserves voluntary culture reading',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          navigatorObservers: [soriRouteObserver],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(platform.plays, 0);
      expect(find.byType(DokkaebiIntro), findsOneWidget);
      final frame = find.byType(DokkaebiFlameFrame);
      expect(tester.getSize(frame), const Size(342, 513));
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is ResizeImage &&
              ((w.image as ResizeImage).imageProvider as AssetImage)
                      .assetName ==
                  DokkaebiIntro.finalAsset,
        ),
        findsOneWidget,
      );
      final t = AppL10n.of(tester.element(find.byType(DokkaebiIntro)));
      for (final body in [
        t.practiceDokkaebiTalesBody,
        t.practiceDokkaebiHomeBody,
        t.practiceDokkaebiRoofBody,
        t.practiceDokkaebiLearningBody,
      ]) {
        final paragraph = find.text(body);
        expect(paragraph, findsOneWidget);
        await Scrollable.ensureVisible(
          tester.element(paragraph),
          alignment: .5,
        );
        await tester.pump();
        expect(paragraph.hitTestable(), findsOneWidget);
      }
      expect(Storage.xp, 0);
      expect(PracticeHistoryStore.load().items, isEmpty);
      expect(platform.assets, isEmpty);
      await tester.tap(find.byTooltip(t.btnClose));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await flushNativeFutures(tester);
      expect(find.byType(DokkaebiIntro), findsNothing);
      expect(find.text('Meet'), findsOneWidget);
      expect(platform.disposes, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('leaving the dokkaebi stage cancels its pending impact', (
    tester,
  ) async {
    var impacts = 0;
    final scroll = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Scaffold(
          body: ListView(
            controller: scroll,
            children: [
              PracticeDokkaebiStage(
                requestId: 1,
                play: true,
                helping: true,
                onImpact: () => impacts++,
              ),
              const SizedBox(height: 2000),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(platform.plays, 1);
    scroll.jumpTo(700);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(impacts, 0);
    await tester.pumpWidget(const SizedBox());
    await flushNativeFutures(tester);
    scroll.dispose();
  });

  testWidgets(
    'one silent play retires to the end poster without allocating again',
    (tester) async {
      var requests = 0;
      await tester.pumpWidget(
        app(accessible: true, onRequested: () => requests++),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(requests, 1);
      expect(platform.plays, 1);
      expect(platform.volumes.last, 0);
      expect(platform.looping.every((v) => !v), isTrue);
      platform.events.add(VideoEvent(eventType: VideoEventType.completed));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      await flushNativeFutures(tester);
      expect(platform.disposes, 1);
      expect(
        (tester.widget<Image>(find.byType(Image)).image as AssetImage)
            .assetName,
        PracticeScholarClip.endAsset,
      );
      await tester.pumpWidget(app());
      await tester.pump(const Duration(seconds: 3));
      expect(platform.creates, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final mode in ['reduce', 'dark']) {
    testWidgets(
      '$mode shows the end pose without creating a video controller',
      (tester) async {
        await tester.pumpWidget(
          app(reduce: mode == 'reduce', dark: mode == 'dark'),
        );
        await tester.pump();
        expect(platform.creates, 0);
        expect(
          (tester.widget<Image>(find.byType(Image)).image as AssetImage)
              .assetName,
          PracticeScholarClip.endAsset,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('route exit and resume never replay the gesture', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    final context = tester.element(find.byType(PracticeScholarClip));
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const Scaffold()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await flushNativeFutures(tester);
    expect(platform.disposes, 1);
    Navigator.of(context).pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(platform.creates, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('fan replay creates exactly one new silent play on request', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: AppTheme.light,
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: PracticeScholarExplanation(
              requestId: 1,
              play: true,
              child: Text('You say you are free and let your friend continue.'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(platform.plays, 1);
    platform.events.add(VideoEvent(eventType: VideoEventType.completed));
    await tester.pump();
    await flushNativeFutures(tester);
    await tester.tap(find.byKey(const ValueKey('scholar-replay')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(platform.plays, 2);
    expect(platform.creates, 2);
    expect(platform.volumesAtPlay, [0, 0]);
    expect(platform.looping.every((v) => !v), isTrue);
    expect(Storage.xp, 0);
    platform.events.add(VideoEvent(eventType: VideoEventType.completed));
    await tester.pump();
    await flushNativeFutures(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(platform.creates, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'large type in narrow portrait and landscape keeps explanation readable',
    (tester) async {
      for (final size in [
        const Size(375, 812),
        const Size(812, 375),
        const Size(800, 1280),
      ]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            locale: const Locale('de'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    PracticeScholarExplanation(
                      requestId: 1,
                      play: true,
                      child: Text(
                        'Du sagst ungezwungen, dass du Zeit hast. Du fragst nicht nach dem Anlass und lässt deinen Freund weitererzählen.',
                      ),
                    ),
                    PracticeGuide(dokkaebi: false, child: Text('Kontext')),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byKey(const ValueKey('scholar-replay')), findsNothing);
        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(const SizedBox());
    },
  );
}
