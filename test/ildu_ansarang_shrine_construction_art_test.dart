import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/ildu_construction_art.dart';

const expected = <String, ({int count, String anchor, String finalHash})>{
  'ansarangchae': (
    count: 14,
    anchor: 'ansarang',
    finalHash:
        'b5f58783f01005b6babac4ac5a85a7b8a86e3f06c90154e4cbc670fee1f47497',
  ),
  'sadangmun': (
    count: 8,
    anchor: 'sadang-gate',
    finalHash:
        '336dcc5251b2f3edfaaa57d0dbd2902b0034491f36c4eda8fdc01a5c0d52be4e',
  ),
  'sadang': (
    count: 12,
    anchor: 'sadang',
    finalHash:
        '8cfc8bb5ca7ce6ae652c9defd1eb0bb3b523ac29eef1cf3afc6e370223869069',
  ),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'all 34 measured PNGs are bundled in order with live map anchors',
    () async {
      final catalog = await IlDuConstructionArtCatalog.load();
      final selected = {
        for (final series in catalog.series)
          if (expected.containsKey(series.id)) series.id: series,
      };
      expect(selected.keys, expected.keys);

      for (final entry in expected.entries) {
        final series = selected[entry.key]!;
        expect(series.mapAnchorId, entry.value.anchor);
        expect(series.stages, hasLength(entry.value.count));
        for (var index = 0; index < series.stages.length; index++) {
          final stage = series.stages[index];
          expect(stage.sequence, index + 1);
          expect(
            stage.asset,
            startsWith(
              'assets/illustrations/personal_hanok_v3/construction/${entry.key}/',
            ),
          );
          final data = await rootBundle.load(stage.asset);
          final bytes = Uint8List.sublistView(data);
          final header = ByteData.sublistView(bytes);
          expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
          expect(header.getUint32(16), stage.width);
          expect(header.getUint32(20), stage.height);
          expect(sha256.convert(bytes).toString(), stage.sha256);
          expect(
            stage.task,
            stage.observe,
            reason:
                '${entry.key} stage ${stage.sequence} must stay learner-facing',
          );
        }
        expect(series.stages.last.sha256, entry.value.finalHash);
      }
    },
  );

  test('final runtime assets remain byte-identical to canonical sources', () {
    const canonical = <String, String>{
      'ansarangchae':
          'assets_unused/pending_review/personal_hanok_v3/canonical/ansarangchae/ansarangchae-v3-canonical.png',
      'sadangmun':
          'assets_unused/pending_review/personal_hanok_v3/canonical/sadangmun/sadangmun-v3-canonical.png',
      'sadang':
          'assets_unused/pending_review/personal_hanok_v3/canonical/sadang/sadang-v3-canonical.png',
    };
    for (final entry in expected.entries) {
      final runtime = File(
        'assets/illustrations/personal_hanok_v3/construction/${entry.key}/'
        'stage_${entry.value.count.toString().padLeft(2, '0')}_complete.png',
      ).readAsBytesSync();
      final source = File(canonical[entry.key]!).readAsBytesSync();
      expect(runtime, source);
      expect(sha256.convert(runtime).toString(), entry.value.finalHash);
    }
  });

  test('global B2 boundaries split crossing receipts by building', () async {
    final catalog = await IlDuConstructionArtCatalog.load();

    final atAnsarangBoundary = catalog.b2RevealsBetween(before: 14, after: 15);
    expect(atAnsarangBoundary.single.series.id, 'sadangmun');
    expect(atAnsarangBoundary.single.beforeSequence, 0);
    expect(atAnsarangBoundary.single.afterSequence, 1);

    final atGateBoundary = catalog.b2RevealsBetween(before: 22, after: 23);
    expect(atGateBoundary.single.series.id, 'sadang');
    expect(atGateBoundary.single.beforeSequence, 0);
    expect(atGateBoundary.single.afterSequence, 1);

    final firstCrossing = catalog.b2RevealsBetween(before: 11, after: 17);
    expect(firstCrossing.map((item) => item.series.id), [
      'ansarangchae',
      'sadangmun',
    ]);
    expect(
      firstCrossing.map((item) => (item.beforeSequence, item.afterSequence)),
      [(11, 14), (0, 3)],
    );

    final secondCrossing = catalog.b2RevealsBetween(before: 22, after: 28);
    expect(secondCrossing.map((item) => item.series.id), ['sadang']);
    expect(secondCrossing.single.beforeSequence, 0);
    expect(secondCrossing.single.afterSequence, 6);
    expect(catalog.b2RevealsBetween(before: 34, after: 34), isEmpty);
  });
}
