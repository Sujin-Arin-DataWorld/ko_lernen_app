import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:ko_lernen_app/data/canonical_companion_art.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/character_clip.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';
import 'package:ko_lernen_app/widgets/sori/tiger_video.dart';
import 'package:ko_lernen_app/widgets/sori/video_lease.dart';

const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAQAAAACCAYAAAB/qH1jAAAAF0lEQVR4nGNgYGBg+A9GaOA/A0MDiAEAQWMDfqQkHvsAAAAASUVORK5CYII=';

class _Bundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage(
        <String, List<String>>{},
      )!;
    }
    if (!key.startsWith('assets/illustrations/companions/')) {
      throw StateError('Unexpected old companion image: $key');
    }
    return ByteData.sublistView(base64Decode(_png));
  }
}

class _Platform extends VideoPlayerPlatform {
  final assets = <String?>[];
  final events = StreamController<VideoEvent>.broadcast(sync: true);
  Completer<void>? heldPlay;
  int playCalls = 0;
  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    assets.add(options.dataSource.asset);
    return 1;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    scheduleMicrotask(
      () => events.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(seconds: 3),
          size: const Size(100, 100),
        ),
      ),
    );
    return events.stream;
  }

  @override
  Future<void> setVolume(int id, double volume) async {}
  @override
  Future<void> setLooping(int id, bool loop) async {}
  @override
  Future<void> setPlaybackSpeed(int id, double speed) async {}
  @override
  Future<void> play(int id) async {
    playCalls++;
    final held = heldPlay;
    if (held != null) await held.future;
  }

  @override
  Future<void> pause(int id) async {}
  @override
  Future<void> seekTo(int id, Duration position) async {}
  @override
  Future<Duration> getPosition(int id) async => Duration.zero;
  @override
  Future<void> dispose(int id) async {}
  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox();
}

Widget _host(Widget child, {bool visible = true}) => DefaultAssetBundle(
  bundle: _Bundle(),
  child: MaterialApp(
    home: Scaffold(
      body: TickerMode(
        enabled: visible,
        child: Center(child: child),
      ),
    ),
  ),
);

Finder _asset(String asset) => find.byWidgetPredicate(
  (widget) =>
      widget is Image &&
      widget.image is AssetImage &&
      (widget.image as AssetImage).assetName == asset,
);

void main() {
  late _Platform platform;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
    platform = _Platform();
    VideoPlayerPlatform.instance = platform;
    TigerStageVideo.videoReady = true;
  });
  tearDown(() async {
    await soriVideoLease.settle();
    await platform.events.close();
    TigerStageVideo.videoReady = false;
  });

  for (final disposeBeforeFailure in [false, true]) {
    testWidgets(
      'late old play failure cannot affect ${disposeBeforeFailure ? 'disposed' : 'replacement'} companion',
      (tester) async {
        final held = Completer<void>();
        platform.heldPlay = held;
        final failures = <CharacterClipFailureReason>[];
        var completions = 0;
        await tester.pumpWidget(
          _host(
            CharacterClipPlayer(
              asset: 'assets/video/practice/hahoe_scholar_fan_hanji.mp4',
              loop: true,
              fallbackKind: MascotKind.tiger,
              onFailure: failures.add,
            ),
          ),
        );
        for (var i = 0; i < 8 && platform.playCalls == 0; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          await tester.pump();
        }
        expect(platform.playCalls, greaterThan(0));
        await tester.pumpWidget(
          disposeBeforeFailure
              ? const SizedBox()
              : _host(
                  CharacterClipPlayer(
                    asset: CharacterClips.magpieChoose,
                    fallbackKind: MascotKind.magpie,
                    onFailure: failures.add,
                    onCompleted: () => completions++,
                  ),
                ),
        );
        held.completeError(StateError('late old native play failure'));
        await tester.pump();
        expect(failures, isEmpty);
        expect(completions, 0);
        await tester.pump(const Duration(milliseconds: 1200));
        expect(completions, disposeBeforeFailure ? 0 : 1);
        await tester.pump(const Duration(seconds: 3));
        expect(completions, disposeBeforeFailure ? 0 : 1);
        await tester.pumpWidget(const SizedBox());
        for (var i = 0; i < 4; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          await tester.pump();
        }
      },
    );
  }

  testWidgets(
    'every retired catalogue movie renders a new still with zero native allocation',
    (tester) async {
      const clips = [
        CharacterClips.tigerRise,
        CharacterClips.tigerRoar,
        CharacterClips.tigerCelebrateHifive,
        CharacterClips.tigerRest,
        CharacterClips.tigerSitting2,
        CharacterClips.tigerBob,
        CharacterClips.tigerStretch,
        CharacterClips.tigerThinking,
        CharacterClips.tigerChoose,
        CharacterClips.tigerGreetPawflash,
        CharacterClips.magpieFlight,
        CharacterClips.magpieCelebrate,
        CharacterClips.magpieWorry,
        CharacterClips.magpiePerched,
        CharacterClips.magpieChoose,
        CharacterClips.magpieBob,
        CharacterClips.magpieBob2,
        CharacterClips.magpieWalkingFront,
        HomeHeroClips.tigerThinking,
        HomeHeroClips.tigerSitting2,
        HomeHeroClips.magpieWalkingFront,
      ];
      for (final clip in clips) {
        await tester.pumpWidget(
          _host(
            CharacterClipPlayer(
              key: ValueKey(clip),
              asset: clip,
              loop: true,
              staticFallback: false,
              fallbackKind: MascotKind.tiger,
            ),
          ),
        );
        await tester.pump();
        expect(_asset(CharacterClips.retiredStillFor(clip)!), findsOneWidget);
        expect(platform.assets, isEmpty);
      }
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'retired one-shot waits while hidden and completes once after visibility returns',
    (tester) async {
      var completions = 0;
      Widget player() => CharacterClipPlayer(
        asset: CharacterClips.tigerChoose,
        fallbackKind: MascotKind.tiger,
        onCompleted: () => completions++,
      );
      await tester.pumpWidget(_host(player(), visible: false));
      await tester.pump(const Duration(seconds: 3));
      expect(completions, 0);
      await tester.pumpWidget(_host(player()));
      await tester.pump(const Duration(milliseconds: 1200));
      expect(completions, 1);
      await tester.pump(const Duration(seconds: 3));
      expect(completions, 1);
      expect(platform.assets, isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'same-key replay cancels the previous completion and disposal cancels the next',
    (tester) async {
      var oldCompletions = 0, newCompletions = 0;
      await tester.pumpWidget(
        _host(
          CharacterClipPlayer(
            asset: CharacterClips.tigerChoose,
            fallbackKind: MascotKind.tiger,
            onCompleted: () => oldCompletions++,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpWidget(
        _host(
          CharacterClipPlayer(
            asset: CharacterClips.magpieChoose,
            fallbackKind: MascotKind.magpie,
            onCompleted: () => newCompletions++,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(oldCompletions, 0);
      expect(newCompletions, 0);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
      expect(newCompletions, 0);
      expect(platform.assets, isEmpty);
    },
  );

  testWidgets('a background app pauses canonical one-shot completion', (
    tester,
  ) async {
    var completions = 0;
    await tester.pumpWidget(
      _host(
        CharacterClipPlayer(
          asset: CharacterClips.tigerChoose,
          fallbackKind: MascotKind.tiger,
          onCompleted: () => completions++,
        ),
      ),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 3));
    expect(completions, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 1200));
    expect(completions, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'custom practice media still acquires native video after same-key companion update',
    (tester) async {
      const custom = 'assets/video/practice/hahoe_scholar_fan_hanji.mp4';
      await tester.pumpWidget(
        _host(
          const CharacterClipPlayer(
            asset: CharacterClips.tigerChoose,
            loop: true,
            fallbackKind: MascotKind.tiger,
          ),
        ),
      );
      expect(platform.assets, isEmpty);
      await tester.pumpWidget(
        _host(
          const CharacterClipPlayer(
            asset: custom,
            loop: true,
            fallbackKind: MascotKind.tiger,
          ),
        ),
      );
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)),
        );
        await tester.pump();
      }
      expect(platform.assets, [custom]);
      await tester.pumpWidget(
        _host(
          const CharacterClipPlayer(
            asset: CharacterClips.magpieChoose,
            loop: true,
            fallbackKind: MascotKind.magpie,
          ),
        ),
      );
      await tester.pump();
      expect(_asset(CanonicalCompanionArt.magpieStanding), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      // Native subscription cancellation crosses the widget fake-timer zone.
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)),
        );
        await tester.pump();
      }
    },
  );

  testWidgets(
    'legacy stage and greet clients never allocate old movies even when video is ready',
    (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              TigerStageVideo(kind: MascotKind.tiger, height: 100),
              TigerGreetClip(kind: MascotKind.magpie, size: 100),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(platform.assets, isEmpty);
      expect(_asset(CanonicalCompanionArt.baekhoStanding), findsOneWidget);
      expect(_asset(CanonicalCompanionArt.magpieStanding), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('mascot states select canonical guide and celebration artwork', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            Mascot.tiger(emotion: MascotEmotion.thinking),
            Mascot.magpie(emotion: MascotEmotion.celebrate),
          ],
        ),
      ),
    );
    expect(_asset(CanonicalCompanionArt.baekhoGuide), findsOneWidget);
    expect(_asset(CanonicalCompanionArt.magpieCelebrate), findsOneWidget);
    expect(platform.assets, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
}
