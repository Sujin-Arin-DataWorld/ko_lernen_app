import 'dart:convert';
import 'dart:io';

import 'package:ko_lernen_app/data/ildu_turntable_catalog.dart';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

const _catalogPath =
    'docs/assets/ildu_sotdaeulmun_construction_20260914/construction_catalog.json';
const _approvedFinalSha =
    '85e660cb6628042ee6249cc849f390356a2c586bd7c056e183d6101617181d44';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('retired gate approval metadata remains attributable', () async {
    final catalog = jsonDecode(await File(_catalogPath).readAsString());
    expect(catalog['status'], 'approved_canonical');
    expect(catalog['buildingId'], 'sotdaeulmun');
    expect(catalog['canonicalSha256'], _approvedFinalSha);
    final stages = catalog['stages'] as List;
    expect(stages, hasLength(12));
    for (var i = 0; i < stages.length; i++) {
      expect(stages[i]['sequence'], i + 1);
      expect(stages[i]['sha256'], matches(RegExp(r'^[a-f0-9]{64}$')));
    }
    final receipt = jsonDecode(
      File('docs/hanok_r16/RUNTIME_RETIREMENT_20261125.json')
          .readAsStringSync(),
    );
    for (final frame in kIlDuSotdaeulmunTurntable.frames) {
      expect(
        sha256.convert(File(frame.assetPath).readAsBytesSync()).toString(),
        receipt['runtimeFiles'][frame.assetPath]['sha256'],
      );
    }
  });

  test(
    'style authority points to the same approved construction art',
    () async {
      final catalog = jsonDecode(
        await File(_catalogPath).readAsString(),
      ) as Map<String, dynamic>;
      final lock = jsonDecode(
        File('docs/assets/STYLE_LOCK.json').readAsStringSync(),
      ) as Map<String, dynamic>;
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
      expect(
        family['historicalV3Art']['canonSprites']['sotdaeulmun'],
        catalog['canonicalAsset'],
      );
      expect(
        family['canonSprites']['sotdaeulmun'],
        kIlDuSotdaeulmunTurntable.frames.first.assetPath,
      );
      expect(
        family['historicalV3Art']['anchors'],
        contains(catalog['canonicalAsset']),
      );
      expect(catalog['depthContract']['frontAndRearPostRows'], isTrue);
      expect(catalog['depthContract']['beamsConnectDepth'], isTrue);
      expect(catalog['depthContract']['centralThroughPassage'], isTrue);
    },
  );
}
