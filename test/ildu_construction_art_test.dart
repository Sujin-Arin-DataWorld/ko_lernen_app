import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/ildu_construction_art.dart';
import 'package:ko_lernen_app/models/sarangchae_construction.dart';

import 'support/hanok_asset_delivery_test_support.dart';
import 'support/r16_runtime_contract.dart';

Map<String, dynamic> source() =>
    jsonDecode(File(IlDuConstructionArtCatalog.assetPath).readAsStringSync())
        as Map<String, dynamic>;

Future<
  ({int width, int height, String alphaHash, bool transparent, bool opaque})
>
imageFacts(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final pixels = (await frame.image.toByteData())!;
  final alpha = Uint8List(pixels.lengthInBytes ~/ 4);
  for (var i = 0; i < alpha.length; i++) {
    alpha[i] = pixels.getUint8(i * 4 + 3);
  }
  final result = (
    width: frame.image.width,
    height: frame.image.height,
    alphaHash: sha256.convert(alpha).toString(),
    transparent: alpha.contains(0),
    opaque: alpha.contains(255),
  );
  frame.image.dispose();
  codec.dispose();
  return result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('R16 gate and Changgo stages decode through bundled delivery', () async {
    await verifyR16Series({'hyeopmun', 'changgo'});
    final sarang = await SarangchaeConstruction.load();
    expect(sarang.stages, hasLength(SarangchaeConstruction.stageCount));
    for (final stage in sarang.stages) {
      expect(stage.assetPath, startsWith('assets/illustrations/ildu_r16/'));
    }
  });

  test(
    'runtime registration changes without rewriting historical approval',
    () {
      final catalog = source();
      final family = readR16Json(
        'docs/assets/STYLE_LOCK.json',
      )['families']['F-D-ildoo'];
      final historical = readR16Json(
        'docs/assets/ildu_hyeopmun_changgo_construction_20260914/construction_catalog.json',
      );
      for (final series in historical['series']) {
        final old = family['approvedConstructionSeries'][series['buildingId']];
        expect(old['canonicalSha256'], series['canonicalSha256']);
      }
      for (final series in catalog['series']) {
        final current =
            family['runtimeConstructionSeries'][series['buildingId']];
        expect(current['canonicalAsset'], series['canonicalAsset']);
        expect(current['canonicalSha256'], series['canonicalSha256']);
        expect(current['stageCount'], series['stages'].length);
      }
    },
  );

  test(
    'modern example objects are separately bundled with their own provenance',
    () async {
      final assets = await HanokAssetDeliveryTestSupport.create();
      addTearDown(assets.dispose);
      final json = source();
      final stages = (json['series'][1]['stages'] as List)
          .where((s) => s['lessonIllustration'] != null)
          .toList();
      expect(stages, hasLength(4));
      for (final stage in stages) {
        final lesson = stage['lessonIllustration'];
        final assetPath = lesson['asset'] as String;
        expect(assets.isBundled(assetPath), isTrue, reason: assetPath);
        final data = await assets.load(assetPath);
        expect(sha256.convert(data).toString(), lesson['sha256']);
        expect(lesson['asset'], isNot(stage['asset']));
        final facts = await imageFacts(data);
        expect(facts.width, lesson['width']);
        expect(facts.height, lesson['height']);
        expect((lesson['caption']['ko'] as String), contains('현대 생활 예시'));
      }
    },
  );

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
          first['asset'] = 'assets/illustrations/personal_hanok_v3/construction/hyeopmun/../other.png';
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
