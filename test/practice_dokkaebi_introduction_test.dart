import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/practice_history_store.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/practice_dokkaebi_help.dart';
import 'package:ko_lernen_app/widgets/practice_dokkaebi_introduction.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_materials.dart';
import 'package:ko_lernen_app/widgets/sori/dokkaebi_flame_frame.dart';
import 'package:ko_lernen_app/widgets/sori/dokkaebi_intro.dart';
import 'package:ko_lernen_app/widgets/sori/route_observer.dart';

import 'support/c_fonts.dart';
import 'support/real_fonts.dart';

const _frameKey = Key('dokkaebi-test-frame');
const _evidenceOutput = String.fromEnvironment(
  'DOKKAEBI_INTRO_EVIDENCE_OUTPUT',
);

class _VideoPlatform extends VideoPlayerPlatform {
  final assets = <String?>[];
  final volumes = <double>[];
  final loops = <bool>[];
  final speeds = <double>[];
  final plays = <int>[];
  final volumesAtPlay = <double>[];
  final disposals = <int>[];
  final _events = <int, StreamController<VideoEvent>>{};
  final _positions = <int, Duration>{};

  @override
  Future<void> init() async {}

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    assets.add(options.dataSource.asset);
    final id = assets.length;
    _events[id] = StreamController<VideoEvent>.broadcast(sync: true);
    _positions[id] = Duration.zero;
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int id) {
    scheduleMicrotask(
      () => _events[id]!.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(seconds: 2),
          size: const Size(720, 1080),
        ),
      ),
    );
    return _events[id]!.stream;
  }

  @override
  Future<void> setVolume(int id, double volume) async => volumes.add(volume);

  @override
  Future<void> setLooping(int id, bool looping) async => loops.add(looping);

  @override
  Future<void> setPlaybackSpeed(int id, double speed) async =>
      speeds.add(speed);

  @override
  Future<void> play(int id) async {
    plays.add(id);
    volumesAtPlay.add(volumes.last);
  }

  @override
  Future<void> pause(int id) async {}

  @override
  Future<void> seekTo(int id, Duration position) async {
    _positions[id] = position;
  }

  @override
  Future<Duration> getPosition(int id) async => _positions[id]!;

  @override
  Future<void> dispose(int id) async {
    disposals.add(id);
    await _events[id]!.close();
  }

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const ColoredBox(color: Colors.black);

  void finish(int id) {
    _positions[id] = const Duration(seconds: 2);
    _events[id]!.add(VideoEvent(eventType: VideoEventType.completed));
  }
}

Future<void> _frames(WidgetTester tester, {int count = 8}) async {
  await tester.pump();
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _nativeFutures(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump();
  }
  await _frames(tester);
}

Future<void> _mount(
  WidgetTester tester, {
  String language = 'en',
  Size size = const Size(390, 844),
  double textScale = 1,
  bool reduceMotion = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: Locale(language),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      navigatorObservers: [soriRouteObserver],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: RepaintBoundary(key: _frameKey, child: child!),
      ),
      home: const Scaffold(body: Center(child: PracticeDokkaebiFireAction())),
    ),
  );
  await _frames(tester);
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('dokkaebi-introduction')));
  await _frames(tester);
  expect(find.byType(PracticeDokkaebiIntroduction), findsOneWidget);
}

Finder _action(String label) => find.byWidgetPredicate(
  (widget) => widget is CMaterialAction && widget.label == label,
);

String? _asset(Image image) {
  var provider = image.image;
  if (provider is ResizeImage) {
    provider = provider.imageProvider;
  }
  return provider is AssetImage ? provider.assetName : null;
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
  await _frames(tester);
  expect(finder.hitTestable(), findsOneWidget);
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_evidenceOutput.isEmpty) {
    return;
  }
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_frameKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await Directory(_evidenceOutput).create(recursive: true);
    await File(
      '$_evidenceOutput/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadCFonts();
    await loadSoriRealFonts(materialIcons: true);
    await CImageCache.load('assets/illustrations/concept_c/material_atlas.png');
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'kl_snd_master': false,
      'kl_haptics_enabled': false,
    });
    Storage.resetForTesting();
    await Storage.init();
  });

  test('approved flame sequence contains sixteen unique phases and closes', () {
    expect(DokkaebiFlameFrame.assets, hasLength(16));
    expect(DokkaebiFlameFrame.assets.toSet(), hasLength(16));
    expect(
      DokkaebiFlameFrame.durations.reduce((a, b) => a + b),
      closeTo(DokkaebiFlameFrame.cycle, .000001),
    );
    expect(DokkaebiFlameFrame.sample(0), DokkaebiFlameFrame.sample(1.8));
    expect(
      DokkaebiFlameFrame.sample(.8).first,
      isNot(DokkaebiFlameFrame.sample(0).first),
    );
  });

  testWidgets('fire exposes one 48dp action and the intro closes voluntarily', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _mount(tester);
      final t = AppL10n.of(
        tester.element(find.byType(PracticeDokkaebiFireAction)),
      );
      final opener = find.byKey(const ValueKey('dokkaebi-introduction'));
      expect(tester.getSize(opener), const Size(48, 48));
      expect(find.bySemanticsLabel(t.practiceDokkaebiMeet), findsOneWidget);
      await _open(tester);
      final introScaffold = tester.widget<Scaffold>(
        find.descendant(
          of: find.byType(PracticeDokkaebiIntroduction),
          matching: find.byType(Scaffold),
        ),
      );
      expect(introScaffold.backgroundColor, const Color(0xff101827));
      final title = tester.renderObject<RenderParagraph>(
        find.text(t.cultureDokkaebiName),
      );
      expect((title.text as TextSpan).style!.color, Colors.white);
      expect(find.byType(DokkaebiIntro), findsOneWidget);
      final close = find.byTooltip(t.btnClose);
      expect(tester.getSize(close).shortestSide, greaterThanOrEqualTo(48));
      await tester.tap(close);
      await _frames(tester);
      expect(find.byType(PracticeDokkaebiIntroduction), findsNothing);
      expect(Storage.xp, 0);
      expect(PracticeHistoryStore.load().items, isEmpty);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  for (final language in ['de', 'en']) {
    for (final size in [
      const Size(320, 640),
      const Size(390, 844),
      const Size(844, 390),
    ]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'culture and sources remain accessible $language ${size.width}x${size.height} ${scale}x',
          (tester) async {
            final openedUrls = <String>[];
            const launcher = MethodChannel('plugins.flutter.io/url_launcher');
            tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
              launcher,
              (call) async {
                if (call.method == 'launch') {
                  openedUrls.add((call.arguments as Map)['url'] as String);
                }
                return true;
              },
            );
            addTearDown(
              () => tester.binding.defaultBinaryMessenger
                  .setMockMethodCallHandler(launcher, null),
            );
            await _mount(
              tester,
              language: language,
              size: size,
              textScale: scale,
            );
            final preferences = await SharedPreferences.getInstance();
            Map<String, Object?> persisted() => {
              for (final key in preferences.getKeys())
                key: preferences.get(key),
            };
            final before = persisted();
            await _open(tester);
            final t = AppL10n.of(
              tester.element(find.byType(PracticeDokkaebiIntroduction)),
            );
            final frame = find.byType(DokkaebiFlameFrame);
            final frameSize = tester.getSize(frame);
            expect(
              frameSize.width,
              closeTo(math.min(size.width - 48, 342), .01),
            );
            expect(frameSize.height, closeTo(frameSize.width * 1.5, .01));
            final image = tester.widget<Image>(
              find.descendant(
                of: find.byType(DokkaebiIntro),
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is Image &&
                      _asset(widget) == DokkaebiIntro.finalAsset,
                ),
              ),
            );
            expect(image.fit, BoxFit.contain);
            expect(tester.widget<DokkaebiFlameFrame>(frame).animate, isFalse);
            await _frames(tester, count: 10);
            expect(tester.getSize(frame), frameSize);
            if (size.width == 390 && scale == 1) {
              await _capture(tester, 'dokkaebi-intro-$language-390');
            }

            final scroll = find.byKey(const ValueKey('dokkaebi-intro-scroll'));
            for (final body in [
              t.practiceDokkaebiTalesBody,
              t.practiceDokkaebiFormNote,
              t.practiceDokkaebiAbout,
              t.practiceDokkaebiFireWord,
              t.practiceDokkaebiHomeBody,
              t.practiceDokkaebiRoofBody,
              t.practiceDokkaebiLearningBody,
              t.practiceDokkaebiLearningNote,
              t.practiceDokkaebiAppStory,
            ]) {
              final paragraph = find.text(body);
              expect(paragraph, findsOneWidget);
              expect(
                find.descendant(of: scroll, matching: paragraph),
                findsOneWidget,
              );
              await _reveal(tester, paragraph);
              final rendered = tester.renderObject<RenderParagraph>(paragraph);
              expect(rendered.didExceedMaxLines, isFalse);
              expect(rendered.size.width, lessThanOrEqualTo(size.width - 48));
              expect(tester.takeException(), isNull);
            }

            final sources = find.byWidgetPredicate(
              (widget) =>
                  widget is SoriButton &&
                  (widget.label == t.practiceDokkaebiFolkloreSource ||
                      widget.label == t.practiceDokkaebiMuseumSource),
            );
            expect(sources, findsNWidgets(3));
            for (var i = 0; i < 3; i++) {
              final source = sources.at(i);
              await _reveal(tester, source);
              expect(tester.getSize(source).height, greaterThanOrEqualTo(48));
              await tester.tap(source);
              await _frames(tester);
            }
            expect(openedUrls, [
              'https://encykorea.aks.ac.kr/Article/E0015531',
              'https://encykorea.aks.ac.kr/Article/E0015527',
              'https://www.museum.go.kr/site/main/relic/search/view?relicId=1478',
            ]);

            final replay = _action(t.practiceDokkaebiGesture);
            await _reveal(tester, replay);
            expect(tester.getSize(replay).height, greaterThanOrEqualTo(48));
            await tester.tap(replay);
            await _frames(tester);
            expect(
              find.byKey(const ValueKey('approved-dokkaebi-intro-1')),
              findsOneWidget,
            );
            expect(tester.getSize(frame), frameSize);
            final returnAction = _action(t.practiceDokkaebiReturn);
            await _reveal(tester, returnAction);
            expect(
              tester.getSize(returnAction).height,
              greaterThanOrEqualTo(48),
            );
            await tester.tap(returnAction);
            expect(
              Navigator.of(tester.element(returnAction)).canPop(),
              isFalse,
              reason: 'The return action must pop the introduction route.',
            );
            await _frames(tester);
            expect(find.byType(PracticeDokkaebiIntroduction), findsNothing);
            expect(find.byType(PracticeDokkaebiFireAction), findsOneWidget);
            expect(Storage.xp, 0);
            expect(PracticeHistoryStore.load().items, isEmpty);
            expect(persisted(), before);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets(
    'one shot settles on final artwork and a replay retains the fixed frame',
    (tester) async {
      final originalPlatform = VideoPlayerPlatform.instance;
      final platform = _VideoPlatform();
      VideoPlayerPlatform.instance = platform;
      addTearDown(() => VideoPlayerPlatform.instance = originalPlatform);
      await _mount(tester, reduceMotion: false);
      await _open(tester);
      await _nativeFutures(tester);
      final frame = find.byType(DokkaebiFlameFrame);
      final extent = tester.getSize(frame);
      final t = AppL10n.of(tester.element(find.byType(DokkaebiIntro)));
      expect(tester.widget<DokkaebiFlameFrame>(frame).animate, isTrue);
      expect(Storage.reducedMotion, isFalse);
      expect(MediaQuery.disableAnimationsOf(tester.element(frame)), isFalse);
      expect(ModalRoute.of(tester.element(frame))!.isCurrent, isTrue);
      expect(platform.assets, [DokkaebiIntro.videoAsset]);
      expect(platform.loops.every((loop) => !loop), isTrue);
      expect(platform.volumesAtPlay, [0]);
      expect(platform.speeds, contains(1.04));
      expect(platform.plays, [1]);
      expect(_action(t.practiceDokkaebiGesture), findsNothing);
      expect(tester.widget<DokkaebiFlameFrame>(frame).animate, isTrue);
      platform.finish(1);
      await _nativeFutures(tester);
      expect(platform.disposals, [1]);
      expect(_action(t.practiceDokkaebiGesture), findsOneWidget);
      expect(tester.getSize(frame), extent);
      await _frames(tester, count: 10);
      expect(platform.assets, [DokkaebiIntro.videoAsset]);
      final replay = _action(t.practiceDokkaebiGesture);
      await _reveal(tester, replay);
      await tester.tap(replay);
      await _nativeFutures(tester);
      expect(platform.assets, [
        DokkaebiIntro.videoAsset,
        DokkaebiIntro.videoAsset,
      ]);
      expect(platform.plays, [1, 2]);
      expect(platform.volumesAtPlay, [0, 0]);
      expect(tester.getSize(frame), extent);
      expect(Storage.xp, 0);
      expect(PracticeHistoryStore.load().items, isEmpty);
      await tester.tap(find.byTooltip(t.btnClose));
      await _frames(tester);
      await _nativeFutures(tester);
      expect(platform.disposals, [1, 2]);
      expect(tester.takeException(), isNull);
    },
  );
}
