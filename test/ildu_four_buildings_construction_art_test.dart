import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/ildu_construction_art.dart';

import 'support/r16_runtime_contract.dart';

const approvedCounts = {
  'jungmunganchae': 12,
  'araechae': 12,
  'anchae': 14,
  'anchae-store': 11,
};
const provenanceRoot = 'docs/assets/ildu_four_buildings_construction_20260914';

Map<String, dynamic> readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    '49 R16 building stages retain their learning order and delivery hashes',
    () async {
      await verifyR16Series(approvedCounts.keys.toSet());
    },
  );

  test('style registrations select the same four completed frames', () {
    final approved = readJson('$provenanceRoot/construction_catalog.json');
    final family = readJson(
      'docs/assets/STYLE_LOCK.json',
    )['families']['F-D-ildoo'];
    for (final series in approved['series']) {
      final registration =
          family['approvedConstructionSeries'][series['buildingId']];
      expect(registration['status'], 'approved_canonical');
      expect(registration['stageCount'], approvedCounts[series['buildingId']]);
      expect(registration['canonicalAsset'], series['canonicalAsset']);
      expect(registration['canonicalSha256'], series['canonicalSha256']);
    }
  });

  for (final defect in [
    'missing building',
    'duplicate building',
    'missing stage',
  ]) {
    test('rejects $defect from the adopted nine-building catalog', () {
      final json = readJson(IlDuConstructionArtCatalog.assetPath);
      final series = json['series'] as List;
      switch (defect) {
        case 'missing building':
          series.removeLast();
        case 'duplicate building':
          series[8] = series[7];
        case 'missing stage':
          (series[2]['stages'] as List).removeLast();
      }
      expect(
        () => IlDuConstructionArtCatalog.fromJson(json),
        throwsFormatException,
      );
    });
  }
}
