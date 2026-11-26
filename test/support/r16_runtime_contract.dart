import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ko_lernen_app/models/ildu_construction_art.dart';

import 'hanok_asset_delivery_test_support.dart';

Map<String, dynamic> readR16Json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

Future<void> verifyR16Series(Set<String> ids) async {
  final assets = await HanokAssetDeliveryTestSupport.create();
  addTearDown(assets.dispose);
  final raw = readR16Json(IlDuConstructionArtCatalog.assetPath);
  final catalog = await IlDuConstructionArtCatalog.load();
  final native = readR16Json('assets/data/ildu_r16_art_v1.json');
  final processes = <String, dynamic>{
    for (final building in native['buildings'])
      for (final stage in building['stages'])
        (stage['processId'] as String).replaceFirst('ildu.', ''): stage,
  };
  expect(raw['runtimeRevision'], 'r16-native-20261125');
  final selected = catalog.series.where((series) => ids.contains(series.id));
  expect(selected.map((series) => series.id).toSet(), ids);
  for (final series in selected) {
    final rawSeries = (raw['series'] as List).singleWhere(
      (s) => s['buildingId'] == series.id,
    );
    for (final stage in series.stages) {
      expect(stage.asset, isNot(contains('personal_hanok_v3')));
      expect(assets.isBundled(stage.asset), isTrue);
      final bytes = await assets.load(stage.asset);
      expect(sha256.convert(bytes).toString(), stage.sha256, reason: stage.id);
      final image = img.decodeImage(bytes)!;
      expect(image.width, stage.width);
      expect(image.height, stage.height);
      expect(image.any((pixel) => pixel.a > 0), isTrue);
      final process = processes[stage.id];
      if (process != null) {
        expect(stage.asset, process['asset']);
        expect(stage.sha256, process['sha256']);
      } else {
        expect(
          stage.asset,
          startsWith('assets/illustrations/ildu_r16_support/construction/'),
        );
      }
      final row = (rawSeries['stages'] as List).singleWhere(
        (s) => s['stageId'] == stage.id,
      );
      expect(row['bytes'], bytes.length);
    }
    expect(series.stages.last.asset, rawSeries['canonicalAsset']);
    expect(series.stages.last.sha256, rawSeries['canonicalSha256']);
  }
}
