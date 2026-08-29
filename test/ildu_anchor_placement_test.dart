import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/ildu_world_manifest.dart';
import 'package:ko_lernen_app/services/ildu_anchor_placement_service.dart';

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
  });

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
}
