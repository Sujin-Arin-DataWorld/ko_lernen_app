import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/ildu_world_manifest.dart';
import 'package:ko_lernen_app/services/ildu_decoration_placement_service.dart';

void main() {
  late IlDuWorldManifest manifest;

  setUpAll(() async {
    manifest = IlDuWorldManifest.fromJson(
      jsonDecode(await File(IlDuWorldManifest.assetPath).readAsString()),
    );
  });

  test('moves decoration between explicitly allowed yards', () {
    const placement = IlDuDecorationPlacement(
      instanceId: 'jangdokdae-1',
      definitionId: 'jangdokdae',
      yardId: 'an-yard',
      x: 45,
      y: 35,
    );

    final moved = moveIlDuDecoration(
      placement: placement,
      definition: manifest.decorationFor('jangdokdae'),
      manifest: manifest,
      proposedX: 20,
      proposedY: 40,
    );

    expect(moved.yardId, 'service-yard');
    expect(moved.x, 20);
    expect(moved.y, 40);
  });

  test('clamps an invalid drag to the current allowed yard', () {
    const placement = IlDuDecorationPlacement(
      instanceId: 'jangdokdae-1',
      definitionId: 'jangdokdae',
      yardId: 'an-yard',
      x: 45,
      y: 35,
    );

    final moved = moveIlDuDecoration(
      placement: placement,
      definition: manifest.decorationFor('jangdokdae'),
      manifest: manifest,
      proposedX: 99,
      proposedY: 99,
    );

    expect(moved.yardId, 'an-yard');
    expect(moved.x, 64);
    expect(moved.y, 51);
  });

  test('rejects persisted placements outside allowed yards', () {
    final placement =
        IlDuDecorationPlacement.tryFromJson(const <String, Object>{
          'instanceId': 'pond-1',
          'definitionId': 'pond',
          'yardId': 'service-yard',
          'x': 20,
          'y': 40,
        }, manifest);

    expect(placement, isNull);
  });
}
