import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/ildu_construction_art.dart';

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
    '49 adopted PNGs retain their approved bytes in the app and web',
    () async {
      final catalog = await IlDuConstructionArtCatalog.load();
      expect(catalog.series.take(6).map((s) => s.stages.length), [
        6,
        8,
        12,
        12,
        14,
        11,
      ]);
      final approved = readJson('$provenanceRoot/construction_catalog.json');
      final receipt = readJson('$provenanceRoot/promotion_manifest.json');
      final runtime = readJson(IlDuConstructionArtCatalog.assetPath);
      expect(
        (runtime['series'] as List).skip(2).take(4).toList(),
        approved['series'],
      );
      expect(approved['status'], 'approved_canonical');
      expect(approved['stageCount'], 49);
      expect(approved['approval'], contains('메인에 병합'));
      final records = {
        for (final row in receipt['files']) row['runtimeAsset']: row,
      };
      final hashes = <String>{};
      final expectedFiles = <String>{};
      var totalBytes = 0;
      for (final series in catalog.series.skip(2).take(4)) {
        expect(series.stages, hasLength(approvedCounts[series.id]!));
        for (final stage in series.stages) {
          final record = records[stage.asset];
          final bundled = Uint8List.sublistView(
            await rootBundle.load(stage.asset),
          );
          final original = File(
            record['approvedSource'] as String,
          ).readAsBytesSync();
          final public = File(
            record['publicAsset'] as String,
          ).readAsBytesSync();
          expect(bundled, original, reason: stage.id);
          expect(public, original, reason: stage.id);
          expect(bundled.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
          final header = ByteData.sublistView(bundled);
          expect(header.getUint32(16), 1536);
          expect(header.getUint32(20), 1024);
          final hash = sha256.convert(bundled).toString();
          expect(hash, record['sha256']);
          expect(hash, stage.sha256);
          expect(bundled.length, record['bytes']);
          hashes.add(hash);
          expectedFiles.add(stage.asset);
          totalBytes += bundled.length;
        }
      }
      expect(hashes, hasLength(49));
      // Approved PNGs are intentionally unchanged (94.12 MiB measured at adoption).
      expect(totalBytes, lessThanOrEqualTo(96 * 1024 * 1024));
      final actualFiles = <String>{
        for (final id in approvedCounts.keys)
          for (final file in Directory(
            'assets/illustrations/personal_hanok_v3/construction/$id',
          ).listSync().whereType<File>())
            file.path.replaceAll('\\', '/'),
      };
      expect(actualFiles, expectedFiles);
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
