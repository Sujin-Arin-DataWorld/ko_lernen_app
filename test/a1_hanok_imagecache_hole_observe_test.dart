import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/a1_hanok_construction_catalog.dart';
import 'package:ko_lernen_app/models/hanok_growth.dart';
import 'package:ko_lernen_app/widgets/sori/a1_hanok_construction_map.dart';

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

Widget _host(
  Widget child, {
  required double width,
  double devicePixelRatio = 1,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: Size(width + 80, width + 80),
      devicePixelRatio: devicePixelRatio,
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

void main() {
  testWidgets('evicts non-resident catalog paths and stale cacheWidths', (
    tester,
  ) async {
    final catalog = [
      for (final state in kA1HanokConstructionStates) state.assetPath,
    ];
    final key = GlobalKey<A1HanokConstructionMapState>();

    await tester.pumpWidget(
      _host(
        A1HanokConstructionMap(key: key, projection: _projection(8)),
        width: 600,
      ),
    );
    await tester.pump();
    await tester.pump();

    final residentsAt8 = List<String>.from(key.currentState!.residentAssetPaths);
    expect(residentsAt8, hasLength(3));
    expect(key.currentState!.debugTrackedProviderCount, 3);
    expect(key.currentState!.debugSeenCacheWidths, contains(600));
    expect(
      key.currentState!.debugEvictedPaths.toSet(),
      containsAll(catalog.where((path) => !residentsAt8.contains(path))),
    );

    await tester.pumpWidget(
      _host(
        A1HanokConstructionMap(key: key, projection: _projection(16)),
        width: 600,
      ),
    );
    await tester.pump();
    await tester.pump();

    final residentsAt16 = List<String>.from(key.currentState!.residentAssetPaths);
    final evictedOnJump = key.currentState!.debugEvictedPaths.toSet();
    expect(residentsAt16, hasLength(2));
    expect(key.currentState!.debugTrackedProviderCount, 2);
    expect(
      evictedOnJump,
      containsAll(catalog.where((path) => !residentsAt16.contains(path))),
    );
    expect(evictedOnJump, containsAll(residentsAt8));

    await tester.pumpWidget(
      _host(
        A1HanokConstructionMap(key: key, projection: _projection(16)),
        width: 390,
        devicePixelRatio: 2,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(key.currentState!.decodeCacheWidth, 780);
    expect(key.currentState!.debugSeenCacheWidths, containsAll({600, 780}));
    expect(key.currentState!.debugTrackedProviderCount, 2);
    expect(key.currentState!.debugEvictedCacheWidths, contains(600));
    expect(
      key.currentState!.debugEvictedPaths.toSet(),
      containsAll(catalog.where((path) => !residentsAt16.contains(path))),
    );
  });
}
