import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/hanok_growth.dart';
import 'package:ko_lernen_app/widgets/sori/a1_hanok_construction_map.dart';

const _onePixelPng = <int>[
  0x89,
  0x50,
  0x4e,
  0x47,
  0x0d,
  0x0a,
  0x1a,
  0x0a,
  0x00,
  0x00,
  0x00,
  0x0d,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1f,
  0x15,
  0xc4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0d,
  0x49,
  0x44,
  0x41,
  0x54,
  0x08,
  0xd7,
  0x63,
  0xf8,
  0xcf,
  0xc0,
  0xf0,
  0x1f,
  0x00,
  0x05,
  0x00,
  0x01,
  0xff,
  0x89,
  0x99,
  0x3d,
  0x1d,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4e,
  0x44,
  0xae,
  0x42,
  0x60,
  0x82,
];

void main() {
  testWidgets('renders the exact projection step in a 4:3 viewport', (
    tester,
  ) async {
    await tester.pumpWidget(_host(step: 6));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('a1-hanok-construction-06_columns')),
      findsOneWidget,
    );
    expect(tester.getSize(find.byType(AspectRatio)), const Size(360, 270));
    expect(
      tester
          .widget<Semantics>(
            find.byKey(const ValueKey('a1-hanok-construction-semantics')),
          )
          .properties
          .label,
      'A1 Hanok construction, step 6 of 16',
    );
  });

  testWidgets('uses a zero-duration transition when motion is reduced', (
    tester,
  ) async {
    await tester.pumpWidget(_host(step: 1, disableAnimations: true));

    expect(
      tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
      Duration.zero,
    );
  });

  testWidgets('rebuilds decode hints when the viewport size changes', (
    tester,
  ) async {
    final width = ValueNotifier<double>(360);
    final dimensions = <(int, int)>{};
    addTearDown(width.dispose);
    await tester.pumpWidget(
      _hostWithSizeNotifier(
        width,
        imageProviderBuilder: (state, cacheWidth, cacheHeight) {
          dimensions.add((cacheWidth, cacheHeight));
          return _memoryImageProvider(state, cacheWidth, cacheHeight);
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(dimensions, contains((1080, 810)));

    width.value = 720;
    await tester.pump();
    await tester.pumpAndSettle();
    expect(dimensions, contains((1536, 1152)));
  });

  testWidgets('changes one state without retaining the full history', (
    tester,
  ) async {
    final step = ValueNotifier<int>(1);
    addTearDown(step.dispose);
    await tester.pumpWidget(_hostWithNotifier(step));

    step.value = 2;
    await tester.pump();
    expect(find.byType(Image), findsNWidgets(2));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(
      find.byKey(const ValueKey('a1-hanok-construction-02_plan_layout')),
      findsOneWidget,
    );
  });

  testWidgets('fails visibly when the active asset cannot decode', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        step: 4,
        imageProviderBuilder: (_, __, ___) =>
            MemoryImage(Uint8List.fromList(const [0, 1, 2, 3])),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('a1-hanok-construction-missing-asset')),
      findsOneWidget,
    );
  });
}

Widget _host({
  required int step,
  bool disableAnimations = false,
  A1HanokImageProviderBuilder? imageProviderBuilder,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            child: A1HanokConstructionMap(
              projection: _projection(step),
              semanticsLabel: 'A1 Hanok construction, step $step of 16',
              missingAssetLabel: 'Construction image unavailable',
              imageProviderBuilder:
                  imageProviderBuilder ??
                  (_, __, ___) => MemoryImage(Uint8List.fromList(_onePixelPng)),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _hostWithNotifier(ValueNotifier<int> step) {
  return _hostWithNotifierAndProvider(step, _memoryImageProvider);
}

Widget _hostWithNotifierAndProvider(
  ValueNotifier<int> step,
  A1HanokImageProviderBuilder imageProviderBuilder,
) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 360,
          child: ValueListenableBuilder<int>(
            valueListenable: step,
            builder: (context, value, _) => A1HanokConstructionMap(
              projection: _projection(value),
              semanticsLabel: 'step $value',
              missingAssetLabel: 'missing',
              imageProviderBuilder: imageProviderBuilder,
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _hostWithSizeNotifier(
  ValueNotifier<double> width, {
  required A1HanokImageProviderBuilder imageProviderBuilder,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: ValueListenableBuilder<double>(
          valueListenable: width,
          builder: (context, value, _) => SizedBox(
            width: value,
            child: A1HanokConstructionMap(
              projection: _projection(8),
              semanticsLabel: 'step 8',
              missingAssetLabel: 'missing',
              imageProviderBuilder: imageProviderBuilder,
            ),
          ),
        ),
      ),
    ),
  );
}

ImageProvider<Object> _memoryImageProvider(Object _, int __, int ___) {
  return MemoryImage(Uint8List.fromList(_onePixelPng));
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
