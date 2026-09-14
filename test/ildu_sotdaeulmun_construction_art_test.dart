import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

const _catalogPath =
    'docs/assets/ildu_sotdaeulmun_construction_20260914/construction_catalog.json';
const _approvedFinalSha =
    '85e660cb6628042ee6249cc849f390356a2c586bd7c056e183d6101617181d44';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'approved gate stages remain byte-identical in the canonical folder',
    () async {
      final catalog =
          jsonDecode(await File(_catalogPath).readAsString())
              as Map<String, dynamic>;
      expect(catalog['status'], 'approved_canonical');
      expect(catalog['buildingId'], 'sotdaeulmun');
      expect(catalog['canonicalSha256'], _approvedFinalSha);
      final stages = catalog['stages'] as List<dynamic>;
      expect(stages, hasLength(12));

      final hashes = <String>{};
      for (var i = 0; i < stages.length; i++) {
        final stage = stages[i] as Map<String, dynamic>;
        final path = stage['asset'] as String;
        expect(stage['sequence'], i + 1);
        expect(
          path,
          startsWith(
            'assets/illustrations/personal_hanok_v3/construction/sotdaeulmun/',
          ),
        );
        final data = await File(path).readAsBytes();
        final bytes = ByteData.sublistView(data);
        expect(data.take(8), [137, 80, 78, 71, 13, 10, 26, 10], reason: path);
        expect(bytes.getUint32(16), stage['width'], reason: path);
        expect(bytes.getUint32(20), stage['height'], reason: path);
        expect(bytes.lengthInBytes, stage['bytes'], reason: path);
        final hash = sha256.convert(data).toString();
        expect(hash, stage['sha256'], reason: path);
        hashes.add(hash);
      }
      expect(hashes, hasLength(12));
      expect(stages.last['asset'], catalog['canonicalAsset']);
      expect(stages.last['sha256'], _approvedFinalSha);
    },
  );

  test(
    'style authority points to the same approved construction art',
    () async {
      final catalog =
          jsonDecode(await File(_catalogPath).readAsString())
              as Map<String, dynamic>;
      final lock =
          jsonDecode(File('docs/assets/STYLE_LOCK.json').readAsStringSync())
              as Map<String, dynamic>;
      final families = lock['families'] as Map<String, dynamic>;
      final family = families.values.cast<Map<String, dynamic>>().singleWhere(
        (entry) => entry.containsKey('approvedConstructionSeries'),
      );
      final registration =
          family['approvedConstructionSeries']['sotdaeulmun']
              as Map<String, dynamic>;
      expect(registration['catalog'], _catalogPath);
      expect(registration['canonicalSha256'], _approvedFinalSha);
      expect(registration['stageCount'], 12);
      expect(registration['status'], 'approved_canonical');
      expect(family['canonSprites']['sotdaeulmun'], catalog['canonicalAsset']);
      expect(family['anchors'], contains(catalog['canonicalAsset']));
      expect(catalog['depthContract']['frontAndRearPostRows'], isTrue);
      expect(catalog['depthContract']['beamsConnectDepth'], isTrue);
      expect(catalog['depthContract']['centralThroughPassage'], isTrue);
    },
  );
}
