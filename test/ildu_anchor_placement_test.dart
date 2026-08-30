import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/ildu_world_manifest.dart';
import 'package:ko_lernen_app/services/ildu_anchor_placement_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late IlDuWorldManifest manifest;

  setUpAll(() async {
    manifest = IlDuWorldManifest.fromJson(
      jsonDecode(await File(IlDuWorldManifest.assetPath).readAsString()),
    );
  });

  test('restores a valid persisted building placement', () {
    final placement = IlDuAnchorPlacement.tryFromJson(const <String, Object>{
      'anchorId': 'ansarang',
      'x': 62.5,
      'y': 41.25,
      'direction': 6,
    }, manifest);

    expect(placement, isNotNull);
    expect(placement!.anchorId, 'ansarang');
    expect(placement.direction, 6);
    expect(placement.scale, 1);
  });

  test('round-trips a valid per-building scale', () {
    const placement = IlDuAnchorPlacement(
      anchorId: 'sarangchae',
      x: 48.2,
      y: 55.8,
      direction: 3,
      scale: 1.35,
    );

    final restored = IlDuAnchorPlacement.tryFromJson(
      placement.toJson(),
      manifest,
    );

    expect(restored, isNotNull);
    expect(restored!.scale, 1.35);
  });

  test(
    'persists position, direction, and scale through the runtime store',
    () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      const store = SharedPreferencesIlDuAnchorPlacementStore();
      const placements = <IlDuAnchorPlacement>[
        IlDuAnchorPlacement(
          anchorId: 'sadang',
          x: 71.25,
          y: 32.5,
          direction: 5,
          scale: 1.25,
        ),
        IlDuAnchorPlacement(
          anchorId: 'sadang-gate',
          x: 64,
          y: 38,
          direction: 7,
          scale: .8,
        ),
        IlDuAnchorPlacement(
          anchorId: 'hyeopmun-west',
          x: 36,
          y: 53,
          direction: 3,
          scale: 1.1,
        ),
      ];

      await store.save(placements);
      final restored = await store.load(manifest);

      expect(restored, hasLength(3));
      for (var index = 0; index < placements.length; index++) {
        expect(restored[index].anchorId, placements[index].anchorId);
        expect(restored[index].x, placements[index].x);
        expect(restored[index].y, placements[index].y);
        expect(restored[index].direction, placements[index].direction);
        expect(restored[index].scale, placements[index].scale);
      }
    },
  );

  test('rejects unknown anchors and invalid directions', () {
    expect(
      IlDuAnchorPlacement.tryFromJson(const <String, Object>{
        'anchorId': 'unknown-building',
        'x': 50,
        'y': 50,
        'direction': 0,
      }, manifest),
      isNull,
    );
    expect(
      IlDuAnchorPlacement.tryFromJson(const <String, Object>{
        'anchorId': 'sarangchae',
        'x': 50,
        'y': 50,
        'direction': 0,
        'scale': 2,
      }, manifest),
      isNull,
    );
    expect(
      IlDuAnchorPlacement.tryFromJson(const <String, Object>{
        'anchorId': 'main-gate',
        'x': 50,
        'y': 50,
        'direction': 8,
      }, manifest),
      isNull,
    );
  });

  test('keeps the complete sprite inside the map canvas', () {
    const placement = IlDuAnchorPlacement(
      anchorId: 'sarangchae',
      x: 48.2,
      y: 55.8,
      direction: 0,
    );

    final moved = moveIlDuAnchor(
      placement: placement,
      proposedX: -30,
      proposedY: 140,
      widthPercent: 29,
      heightPercent: 20,
    );

    expect(moved.x, 14.5);
    expect(moved.y, 90);
  });

  test('resizing clamps scale and keeps the sprite inside the map', () {
    const placement = IlDuAnchorPlacement(
      anchorId: 'sarangchae',
      x: 8,
      y: 8,
      direction: 0,
    );

    final resized = resizeIlDuAnchor(
      placement: placement,
      proposedScale: 2,
      baseWidthPercent: 29,
      baseHeightPercent: 20,
    );

    expect(resized.scale, IlDuAnchorPlacement.maximumScale);
    expect(resized.x, closeTo(23.2, .0001));
    expect(resized.y, 16);
  });

  test('a direct gesture transforms position and scale together', () {
    const placement = IlDuAnchorPlacement(
      anchorId: 'sarangchae',
      x: 48.2,
      y: 55.8,
      direction: 4,
    );

    final transformed = transformIlDuAnchor(
      placement: placement,
      proposedX: 54,
      proposedY: 60,
      proposedScale: 1.25,
      baseWidthPercent: 29,
      baseHeightPercent: 20,
    );

    expect(transformed.x, 54);
    expect(transformed.y, 60);
    expect(transformed.direction, 4);
    expect(transformed.scale, 1.25);
  });
}
