import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/ildu_world_manifest.dart';

void main() {
  late IlDuWorldManifest manifest;

  setUpAll(() async {
    final raw = await File(IlDuWorldManifest.assetPath).readAsString();
    manifest = IlDuWorldManifest.fromJson(jsonDecode(raw));
  });

  test('keeps the approved spacious Ildu geometry contract', () {
    expect(manifest.canvas.width, 2412);
    expect(manifest.canvas.height, 2622);
    expect(manifest.canvas.mobileContentWidth, 620);
    expect(manifest.eras.map((era) => era.id), IlDuWorldEra.values);
    expect(manifest.hubs, hasLength(5));
    expect(manifest.yards, hasLength(5));
    expect(manifest.buildings, hasLength(11));
    expect(manifest.gates, hasLength(5));
    expect(manifest.decorations, hasLength(5));
  });

  test('ships every referenced image and the approved canvas bytes', () async {
    final canvas = File(manifest.worldAsset(manifest.canvas.asset));
    expect(await canvas.exists(), isTrue);
    expect(
      sha256.convert(await canvas.readAsBytes()).toString().toUpperCase(),
      '6C9438312ED828E8D2AFAC9BEE9AF728AD22933DE0639DABF30DEF82BB165B7E',
    );

    for (final anchor in <IlDuWorldAnchor>[
      ...manifest.buildings,
      ...manifest.gates,
    ]) {
      expect(
        await File(manifest.worldAsset(anchor.asset)).exists(),
        isTrue,
        reason: '${anchor.id} must reference a bundled world asset',
      );
    }
    for (final decoration in manifest.decorations) {
      expect(
        await File(manifest.decorationAsset(decoration.asset)).exists(),
        isTrue,
        reason: '${decoration.id} must reference a bundled decoration asset',
      );
    }
  });

  test('covers each building exactly once across learning hubs', () {
    final hubBuildingIds = manifest.hubs
        .expand((hub) => hub.buildingIds)
        .toList(growable: false);
    expect(hubBuildingIds, hasLength(manifest.buildings.length));
    expect(hubBuildingIds.toSet(), {
      for (final building in manifest.buildings) building.id,
    });
  });

  test('maps the former rear-wing anchor to the measured Jungmunganchae', () {
    final jungmunganchae = manifest.buildings.firstWhere(
      (building) => building.id == 'jungmunganchae',
    );

    expect(jungmunganchae.ko, '중문채');
    expect(jungmunganchae.asset, 'rear-wing.png');
    expect(jungmunganchae.x, 40.3);
    expect(jungmunganchae.y, 43.6);
    expect(jungmunganchae.width, 18);
    expect(jungmunganchae.rotation, 90);
    expect(
      manifest.buildings.where((building) => building.id == 'rear-wing'),
      isEmpty,
    );
  });
}
