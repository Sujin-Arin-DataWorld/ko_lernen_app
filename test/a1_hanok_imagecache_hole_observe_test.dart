import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/a1_hanok_construction_catalog.dart';
import 'package:ko_lernen_app/models/hanok_growth.dart';
import 'package:ko_lernen_app/widgets/sori/a1_hanok_construction_map.dart';

void _agentLog(Map<String, Object?> data) {
  File('/opt/cursor/logs/debug.log').writeAsStringSync(
    '${jsonEncode(<String, Object?>{
      'hypothesisId': 'C',
      'location': 'a1_hanok_imagecache_hole_observe_test.dart',
      'message': 'widget evicts only tracked residents',
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'runId': 'pre-fix-repro',
    })}\n',
    mode: FileMode.append,
  );
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
  testWidgets('evicts only the 2-3 tracked residents, not the catalog', (
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
    final trackedAt8 = key.currentState!.debugTrackedProviderCount;
    final cacheWidthAt8 = key.currentState!.decodeCacheWidth;
    final neverTrackedAt8 = catalog
        .where((path) => !residentsAt8.contains(path))
        .toList();

    await tester.pumpWidget(
      _host(
        A1HanokConstructionMap(key: key, projection: _projection(16)),
        width: 600,
      ),
    );
    await tester.pump();
    await tester.pump();

    final residentsAt16 = List<String>.from(key.currentState!.residentAssetPaths);
    final trackedAt16 = key.currentState!.debugTrackedProviderCount;
    final evictedOnJump = List<String>.from(key.currentState!.debugEvictedPaths);
    final stillNeverEvicted = catalog
        .where(
          (path) =>
              !residentsAt8.contains(path) &&
              !residentsAt16.contains(path) &&
              !evictedOnJump.contains(path),
        )
        .toList();

    await tester.pumpWidget(
      _host(
        A1HanokConstructionMap(key: key, projection: _projection(16)),
        width: 390,
        devicePixelRatio: 2,
      ),
    );
    await tester.pump();
    await tester.pump();

    final cacheWidthAfterResize = key.currentState!.decodeCacheWidth;
    final evictedWidths = List<int>.from(
      key.currentState!.debugEvictedCacheWidths,
    );
    final trackedAfterResize = key.currentState!.debugTrackedProviderCount;

    _agentLog({
      'catalogCount': catalog.length,
      'residentsAt8': residentsAt8,
      'trackedAt8': trackedAt8,
      'cacheWidthAt8': cacheWidthAt8,
      'neverTrackedAt8Count': neverTrackedAt8.length,
      'neverTrackedAt8': neverTrackedAt8,
      'residentsAt16': residentsAt16,
      'trackedAt16': trackedAt16,
      'evictedOnJump': evictedOnJump,
      'stillNeverEvictedCount': stillNeverEvicted.length,
      'stillNeverEvicted': stillNeverEvicted,
      'cacheWidthAfterResize': cacheWidthAfterResize,
      'evictedWidths': evictedWidths,
      'trackedAfterResize': trackedAfterResize,
      'hole': 'evict loops only _providers, not the other catalog A1 paths',
    });

    expect(catalog, hasLength(17));
    expect(residentsAt8, hasLength(3));
    expect(trackedAt8, 3);
    expect(neverTrackedAt8, hasLength(14));
    expect(stillNeverEvicted, hasLength(greaterThanOrEqualTo(12)));
    expect(trackedAfterResize, lessThanOrEqualTo(3));
  });
}
