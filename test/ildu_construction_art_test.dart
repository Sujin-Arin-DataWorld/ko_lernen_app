import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/ildu_construction_art.dart';

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

  test(
    'the bundled catalog decodes all 14 transparent stages and exact finals',
    () async {
      final catalog = await IlDuConstructionArtCatalog.load();
      final approvedRows = {
        for (final series in source()['series'])
          for (final stage in series['stages']) stage['stageId']: stage,
      };
      expect(catalog.series.map((s) => s.stages.length), [6, 8]);
      final seen = <String>{};
      for (final series in catalog.series) {
        for (final stage in series.stages) {
          final data = await rootBundle.load(stage.asset);
          final bytes = Uint8List.sublistView(data);
          final facts = await imageFacts(bytes);
          expect(facts.width, stage.width);
          expect(facts.height, stage.height);
          expect(facts.transparent && facts.opaque, isTrue);
          final original = File(
            approvedRows[stage.id]['approvedPngAsset'] as String,
          ).readAsBytesSync();
          expect(facts, await imageFacts(original));
          if (stage == series.stages.last) {
            expect(stage.asset, endsWith('.png'));
            expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
          } else {
            expect(stage.asset, endsWith('.webp'));
          }
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
          stage['approvedPngAsset'] as String,
        ).readAsBytesSync();
        expect(sha256.convert(archived).toString(), stage['approvedPngSha256']);
        expect(archived.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
        if (stage['sequence'] == approved['stageCount']) {
          expect(stage['sha256'], stage['approvedPngSha256']);
        }
      }
    }
  });

  test('only referenced runtime images are bundled within 24 MiB', () {
    final json = source();
    final expected = <String>{};
    final actual = <String>{};
    var bytes = 0;
    for (final series in json['series']) {
      for (final stage in series['stages']) {
        expected.add(stage['asset'] as String);
        if (stage['lessonIllustration'] != null) {
          expected.add(stage['lessonIllustration']['asset'] as String);
        }
      }
    }
    for (final name in ['hyeopmun', 'changgo', 'lessons']) {
      final directory = Directory(
        'assets/illustrations/personal_hanok_v3/construction/$name',
      );
      for (final file in directory.listSync().whereType<File>()) {
        actual.add(file.path.replaceAll('\\', '/'));
        bytes += file.lengthSync();
      }
    }
    expect(actual, expected);
    // The exact two final PNGs account for 8.06 MiB of this ceiling.
    expect(bytes, lessThanOrEqualTo(24 * 1024 * 1024));
  });

  test(
    'modern example objects are separately bundled with their own provenance',
    () async {
      final json = source();
      final stages = (json['series'][1]['stages'] as List)
          .where((s) => s['lessonIllustration'] != null)
          .toList();
      expect(stages, hasLength(4));
      for (final stage in stages) {
        final lesson = stage['lessonIllustration'];
        final data = await rootBundle.load(lesson['asset'] as String);
        expect(
          sha256.convert(Uint8List.sublistView(data)).toString(),
          lesson['sha256'],
        );
        expect(lesson['asset'], isNot(stage['asset']));
        final original = File(
          lesson['approvedPngAsset'] as String,
        ).readAsBytesSync();
        expect(
          sha256.convert(original).toString(),
          lesson['approvedPngSha256'],
        );
        expect(
          await imageFacts(Uint8List.sublistView(data)),
          await imageFacts(original),
        );
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
