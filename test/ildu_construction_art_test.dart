import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/ildu_construction_art.dart';

Map<String, dynamic> source() =>
    jsonDecode(File(IlDuConstructionArtCatalog.assetPath).readAsStringSync())
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the bundled catalog resolves all 14 approved RGBA PNGs and final hashes',
    () async {
      final catalog = await IlDuConstructionArtCatalog.load();
      expect(catalog.series.map((s) => s.stages.length), [6, 8]);
      final seen = <String>{};
      for (final series in catalog.series) {
        for (final stage in series.stages) {
          final data = await rootBundle.load(stage.asset);
          final bytes = Uint8List.sublistView(data);
          expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
          expect(data.getUint32(16), stage.width);
          expect(data.getUint32(20), stage.height);
          expect(data.getUint8(25), 6, reason: 'PNG must contain RGBA');
          expect(sha256.convert(bytes).toString(), stage.sha256);
          seen.add(stage.sha256);
        }
      }
      expect(seen, hasLength(14));
      expect(
        catalog.series[0].stages.last.sha256,
        '3a6e3141f0f9c763067d40a867cf94082df04f119ba275c037b6e67645153884',
      );
      expect(
        catalog.series[1].stages.last.sha256,
        '867495181c3507a29bca0efc43778bf6a958018b05992caba3fa40a01a3d9488',
      );
    },
  );

  test('style authority, runtime catalog and provenance archive agree', () {
    final json = source();
    final documented = jsonDecode(
      File(
        'docs/assets/ildu_hyeopmun_changgo_construction_20260914/construction_catalog.json',
      ).readAsStringSync(),
    );
    expect(json, documented);
    final lock = jsonDecode(
      File('docs/assets/STYLE_LOCK.json').readAsStringSync(),
    );
    final family = (lock['families'] as Map).values.firstWhere(
      (v) => (v as Map).containsKey('approvedConstructionSeries'),
    );
    for (final series in json['series']) {
      final approved =
          family['approvedConstructionSeries'][series['buildingId']];
      expect(approved['canonicalAsset'], series['canonicalAsset']);
      expect(approved['canonicalSha256'], series['canonicalSha256']);
      expect(approved['stageCount'], series['stages'].length);
      for (final stage in series['stages']) {
        final archived = File(
          'assets_unused/pending_review/personal_hanok_v3/construction_hyeopmun_changgo_v1/'
          '${series['buildingId']}/stages/${(stage['asset'] as String).split('/').last}',
        ).readAsBytesSync();
        expect(sha256.convert(archived).toString(), stage['sha256']);
      }
    }
  });

  for (final defect in [
    'approval',
    'sequence',
    'path',
    'translation',
    'answer',
  ]) {
    test('rejects a catalog with invalid $defect', () {
      final json = source();
      final first = json['series'][0]['stages'][0] as Map<String, dynamic>;
      switch (defect) {
        case 'approval':
          json['status'] = 'candidate';
        case 'sequence':
          first['sequence'] = 2;
        case 'path':
          first['asset'] =
              'assets/illustrations/personal_hanok_v3/construction/hyeopmun/../other.png';
        case 'translation':
          first['line']['de'] = '';
        case 'answer':
          json['series'][0]['stages'][1]['exercise']['correctOptionId'] =
              'missing';
      }
      expect(
        () => IlDuConstructionArtCatalog.fromJson(json),
        throwsFormatException,
      );
    });
  }
}
