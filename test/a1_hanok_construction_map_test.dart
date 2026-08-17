import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/a1_hanok_construction_catalog.dart';
import 'package:ko_lernen_app/models/hanok_growth.dart';
import 'package:ko_lernen_app/widgets/sori/a1_hanok_construction_map.dart';

void main() {
  testWidgets('renders the empty site at step 0 in a 4:3 viewport', (
    tester,
  ) async {
    final key = GlobalKey<A1HanokConstructionMapState>();
    await tester.pumpWidget(
      _host(
        A1HanokConstructionMap(
          key: key,
          projection: _projection(0),
          semanticsLabel: 'empty-site',
        ),
        width: 390,
      ),
    );
    await tester.pump();

    expect(find.byType(A1HanokConstructionMap), findsOneWidget);
    expect(tester.getSize(find.byType(A1HanokConstructionMap)), const Size(390, 292.5));
    expect(find.bySemanticsLabel('empty-site'), findsOneWidget);
    expect(key.currentState!.residentAssetPaths, [
      kA1HanokEmptySiteAsset,
      '${kA1HanokRuntimeStateRoot}01_site_setout.webp',
    ]);
    expect(find.byType(Image, skipOffstage: false), findsNWidgets(2));
    await tester.pump();
    expect(key.currentState!.residentProviders, hasLength(2));
    expect(key.currentState!.residentProviders, everyElement(isA<ResizeImage>()));
    expect(
      key.currentState!.residentProviders.map(
        (provider) => (provider as ResizeImage).width,
      ),
      everyElement(key.currentState!.decodeCacheWidth),
    );
  });

  testWidgets('keeps a three-frame window and evicts stale neighbors', (
    tester,
  ) async {
    final key = GlobalKey<A1HanokConstructionMapState>();
    await tester.pumpWidget(
      _host(
        A1HanokConstructionMap(key: key, projection: _projection(8)),
        width: 600,
      ),
    );
    await tester.pump();
    expect(key.currentState!.residentAssetPaths, [
      '${kA1HanokRuntimeStateRoot}07_beams_changbang.webp',
      '${kA1HanokRuntimeStateRoot}08_purlins_sangnyang.webp',
      '${kA1HanokRuntimeStateRoot}09_rafters_roof_frame.webp',
    ]);
    expect(find.byType(Image, skipOffstage: false), findsNWidgets(3));
    await tester.pump();
    expect(key.currentState!.residentProviders, hasLength(3));
    expect(key.currentState!.residentProviders, everyElement(isA<ResizeImage>()));
    expect(
      key.currentState!.residentProviders.map(
        (provider) => (provider as ResizeImage).width,
      ),
      everyElement(600),
    );

    await tester.pumpWidget(
      _host(
        A1HanokConstructionMap(key: key, projection: _projection(16)),
        width: 600,
      ),
    );
    await tester.pumpAndSettle();
    expect(key.currentState!.residentAssetPaths, [
      '${kA1HanokRuntimeStateRoot}15_changho_finish.webp',
      '${kA1HanokRuntimeStateRoot}16_landscape_move_in.webp',
    ]);
    expect(find.byType(Image, skipOffstage: false), findsNWidgets(2));
    expect(key.currentState!.residentProviders, hasLength(2));
  });

  testWidgets('rebuilds the decode hint when width or DPR changes', (
    tester,
  ) async {
    final key = GlobalKey<A1HanokConstructionMapState>();
    await tester.pumpWidget(
      _host(
        A1HanokConstructionMap(key: key, projection: _projection(0)),
        width: 390,
        devicePixelRatio: 2,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(key.currentState!.decodeCacheWidth, 780);
    expect(
      key.currentState!.residentProviders.map(
        (provider) => (provider as ResizeImage).width,
      ),
      everyElement(780),
    );

    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _host(
        A1HanokConstructionMap(key: key, projection: _projection(0)),
        width: 1024,
        devicePixelRatio: 3,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(key.currentState!.decodeCacheWidth, kA1HanokCanvasWidth);
  });

  testWidgets('uses a fail-visible fallback for missing and out-of-range states', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        A1HanokConstructionMap(projection: _projection(8)),
        width: 390,
      ),
    );
    await tester.pump();
    expect(find.byType(Image, skipOffstage: false), findsNWidgets(3));
    expect(find.byIcon(Icons.landscape_outlined), findsOneWidget);

    await tester.pumpWidget(
      _host(
        A1HanokConstructionMap(projection: _projection(99)),
        width: 390,
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.landscape_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('uses an injected provider and shows a missing-asset label', (
    tester,
  ) async {
    final key = GlobalKey<A1HanokConstructionMapState>();
    await tester.pumpWidget(
      _host(
        A1HanokConstructionMap(
          key: key,
          projection: _projection(0),
          missingAssetLabel: 'missing-plate',
          imageProviderBuilder: (path, width) => _FailingImageProvider(path),
        ),
        width: 390,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(key.currentState!.residentProviders, hasLength(2));
    expect(
      key.currentState!.residentProviders,
      everyElement(isA<_FailingImageProvider>()),
    );
    expect(find.text('missing-plate'), findsOneWidget);
    expect(find.byIcon(Icons.landscape_outlined), findsNothing);
  });

  testWidgets('skips cross-fade when reduce-motion is requested', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        A1HanokConstructionMap(projection: _projection(0)),
        width: 390,
        reduceMotion: true,
      ),
    );
    await tester.pump();
    final switcher = tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher));
    expect(switcher.duration, Duration.zero);
  });

  testWidgets('holds 390/600/1024, 200% text, and high contrast without overflow', (
    tester,
  ) async {
    for (final width in const [390.0, 600.0, 1024.0]) {
      tester.view.physicalSize = Size(width + 80, width);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _host(
          A1HanokConstructionMap(projection: _projection(0)),
          width: width,
          textScale: 2,
          highContrast: true,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(A1HanokConstructionMap), findsOneWidget);
      final size = tester.getSize(find.byType(A1HanokConstructionMap));
      expect(size.width, width);
      expect(size.height, closeTo(width * 3 / 4, 0.01));
    }
  });
}

HanokExperienceProjection _projection(int step) => HanokExperienceProjection(
  verifiedCanDoSegmentIds: const {},
  reassessmentEligibleSegmentIds: const {},
  earnedGrants: const [],
  a1ConstructionStep: step,
  currentEra: HanokGrowthEra.build,
  openedVenues: const {},
  availableDesignOptions: const {},
  activeLoadout: const {},
  weatheringTier: HanokWeatheringTier.fresh,
  nextGrant: null,
  trackProgress: const [],
  roomLayouts: HanokRoomLayoutProjection(active: const {}, dormant: const {}),
);

class _FailingImageProvider extends ImageProvider<_FailingImageProvider> {
  const _FailingImageProvider(this.path);

  final String path;

  @override
  Future<_FailingImageProvider> obtainKey(ImageConfiguration configuration) {
    return Future<_FailingImageProvider>.value(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _FailingImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(
      Future<ImageInfo>.error(StateError('missing $path')),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _FailingImageProvider && other.path == path;

  @override
  int get hashCode => path.hashCode;
}

Widget _host(
  Widget child, {
  required double width,
  bool reduceMotion = false,
  double textScale = 1,
  bool highContrast = false,
  double devicePixelRatio = 1,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: Size(width + 80, width + 80),
      devicePixelRatio: devicePixelRatio,
      disableAnimations: reduceMotion,
      textScaler: TextScaler.linear(textScale),
      highContrast: highContrast,
    ),
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}
