import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ko_lernen_app/models/ildu_construction_art.dart';

const _pngSourceCommit = '547a5c3981c8e0b508ee41ffbc4bfd9e0e584e0b';
const _losslessValidationPath =
    'docs/assets/ildu_ansarang_shrine_construction_20260914/'
    'lossless_validation.json';

const expected =
    <
      String,
      ({
        int count,
        String anchor,
        String approvedCanonicalPngAsset,
        String approvedCanonicalPngSha256,
      })
    >{
      'ansarangchae': (
        count: 14,
        anchor: 'ansarang',
        approvedCanonicalPngAsset:
            'assets_unused/pending_review/personal_hanok_v3/canonical/'
            'ansarangchae/ansarangchae-v3-canonical.png',
        approvedCanonicalPngSha256:
            'b5f58783f01005b6babac4ac5a85a7b8a86e3f06c90154e4cbc670fee1f47497',
      ),
      'sadangmun': (
        count: 8,
        anchor: 'sadang-gate',
        approvedCanonicalPngAsset:
            'assets_unused/pending_review/personal_hanok_v3/canonical/'
            'sadangmun/sadangmun-v3-canonical.png',
        approvedCanonicalPngSha256:
            '336dcc5251b2f3edfaaa57d0dbd2902b0034491f36c4eda8fdc01a5c0d52be4e',
      ),
      'sadang': (
        count: 12,
        anchor: 'sadang',
        approvedCanonicalPngAsset:
            'assets_unused/pending_review/personal_hanok_v3/canonical/'
            'sadang/sadang-v3-canonical.png',
        approvedCanonicalPngSha256:
            '8cfc8bb5ca7ce6ae652c9defd1eb0bb3b523ac29eef1cf3afc6e370223869069',
      ),
    };

Map<String, dynamic> _object(Object? value) =>
    (value as Map).cast<String, dynamic>();

List<Map<String, dynamic>> _objects(Object? value) => [
  for (final item in value as List) _object(item),
];

String _rgbaSha256(img.Image image) =>
    sha256.convert(image.getBytes(order: img.ChannelOrder.rgba)).toString();

String _rgbSha256(img.Image image) =>
    sha256.convert(image.getBytes(order: img.ChannelOrder.rgb)).toString();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'all 34 lossless WebPs preserve frozen runtime PNG pixels',
    () async {
      final rawCatalog = _object(
        jsonDecode(
          await rootBundle.loadString(IlDuConstructionArtCatalog.assetPath),
        ),
      );
      final rawSeriesById = {
        for (final series in _objects(rawCatalog['series']))
          series['buildingId'] as String: series,
      };
      final losslessValidation = _object(
        jsonDecode(File(_losslessValidationPath).readAsStringSync()),
      );
      expect(losslessValidation['sourceCommit'], _pngSourceCommit);
      final sourceFiles = _objects(losslessValidation['sourceFiles']);
      expect(sourceFiles, hasLength(34));
      final sourceFilesByStage = {
        for (final source in sourceFiles)
          '${source['building']}:${source['number']}': source,
      };
      expect(sourceFilesByStage, hasLength(34));
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final declaredAssets = RegExp(
        r'^\s*-\s+(assets/\S+)\s*$',
        multiLine: true,
      ).allMatches(pubspec).map((match) => match.group(1)!).toSet();
      final catalog = IlDuConstructionArtCatalog.fromJson(rawCatalog);
      final selected = {
        for (final series in catalog.series)
          if (expected.containsKey(series.id)) series.id: series,
      };
      expect(selected.keys, expected.keys);

      for (final entry in expected.entries) {
        final series = selected[entry.key]!;
        final rawSeries = rawSeriesById[entry.key]!;
        final rawStages = _objects(rawSeries['stages']);
        expect(series.mapAnchorId, entry.value.anchor);
        expect(series.stages, hasLength(entry.value.count));
        expect(rawStages, hasLength(entry.value.count));
        expect(
          rawSeries['approvedCanonicalPngAsset'],
          entry.value.approvedCanonicalPngAsset,
        );
        expect(
          rawSeries['approvedCanonicalPngSha256'],
          entry.value.approvedCanonicalPngSha256,
        );

        for (var index = 0; index < series.stages.length; index++) {
          final stage = series.stages[index];
          final rawStage = rawStages[index];
          final runtimePrefix =
              'assets/illustrations/personal_hanok_v3/construction/'
              '${entry.key}/';
          final runtimeName = stage.asset.substring(runtimePrefix.length);
          final expectedPngSource =
              '$runtimePrefix${runtimeName.substring(0, runtimeName.length - 5)}.png';
          final frozenSource =
              sourceFilesByStage['${entry.key}:${stage.sequence}']!;

          expect(stage.sequence, index + 1);
          expect(stage.asset, startsWith(runtimePrefix));
          expect(stage.asset, endsWith('.webp'));
          expect(declaredAssets, contains(stage.asset));
          expect(rawStage['sourcePathAtCommit'], expectedPngSource);
          expect(rawStage['sourceCommit'], _pngSourceCommit);
          expect(frozenSource['pathAtCommit'], expectedPngSource);
          expect(frozenSource['sha256'], rawStage['sourcePngSha256']);
          expect(frozenSource['bytes'], rawStage['sourcePngBytes']);
          expect(frozenSource['rgbaSha256'], rawStage['rgbaSha256']);
          expect(
            rawStage['sourcePngSha256'],
            matches(RegExp(r'^[a-f0-9]{64}$')),
          );
          expect(rawStage['rgbaSha256'], matches(RegExp(r'^[a-f0-9]{64}$')));

          final data = await rootBundle.load(stage.asset);
          final runtimeBytes = Uint8List.sublistView(data);
          expect(runtimeBytes.length, rawStage['bytes']);
          expect(sha256.convert(runtimeBytes).toString(), stage.sha256);
          final runtimeImage = img.decodeWebP(runtimeBytes);
          expect(runtimeImage, isNotNull);
          expect(runtimeImage!.width, stage.width);
          expect(runtimeImage.height, stage.height);

          final approvedPngBytes = File(
            rawStage['approvedPngAsset'] as String,
          ).readAsBytesSync();
          expect(
            sha256.convert(approvedPngBytes).toString(),
            rawStage['approvedPngSha256'],
          );
          final approvedPngImage = img.decodePng(approvedPngBytes);
          expect(approvedPngImage, isNotNull);
          expect(approvedPngImage!.width, stage.width);
          expect(approvedPngImage.height, stage.height);

          final runtimeRgbaSha256 = _rgbaSha256(runtimeImage);
          expect(runtimeRgbaSha256, rawStage['rgbaSha256']);
          expect(_rgbSha256(runtimeImage), _rgbSha256(approvedPngImage));
          expect(
            stage.task,
            stage.observe,
            reason:
                '${entry.key} stage ${stage.sequence} must stay learner-facing',
          );
        }

        expect(series.stages.last.asset, rawSeries['canonicalAsset']);
        expect(series.stages.last.sha256, rawSeries['canonicalSha256']);
        expect(
          declaredAssets.where(
            (asset) => asset.startsWith(
              'assets/illustrations/personal_hanok_v3/construction/'
              '${entry.key}/',
            ),
          ),
          hasLength(entry.value.count),
        );
        expect(
          RegExp(
            '^\\s*-\\s+${RegExp.escape('assets/illustrations/personal_hanok_v3/construction/${entry.key}/')}\\s*\$',
            multiLine: true,
          ).hasMatch(pubspec),
          isFalse,
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );

  test('final runtime WebPs preserve approved canonical PNG pixels', () async {
    final rawCatalog = _object(
      jsonDecode(
        await rootBundle.loadString(IlDuConstructionArtCatalog.assetPath),
      ),
    );
    final rawSeriesById = {
      for (final series in _objects(rawCatalog['series']))
        series['buildingId'] as String: series,
    };

    for (final entry in expected.entries) {
      final rawSeries = rawSeriesById[entry.key]!;
      final rawFinalStage = _objects(rawSeries['stages']).last;
      final runtimeBytes = await File(
        rawSeries['canonicalAsset'] as String,
      ).readAsBytes();
      final canonicalBytes = await File(
        rawSeries['approvedCanonicalPngAsset'] as String,
      ).readAsBytes();

      expect(
        sha256.convert(runtimeBytes).toString(),
        rawSeries['canonicalSha256'],
      );
      expect(
        sha256.convert(canonicalBytes).toString(),
        entry.value.approvedCanonicalPngSha256,
      );
      final runtimeImage = img.decodeWebP(runtimeBytes);
      final canonicalImage = img.decodePng(canonicalBytes);
      expect(runtimeImage, isNotNull);
      expect(canonicalImage, isNotNull);
      expect(_rgbaSha256(runtimeImage!), rawFinalStage['rgbaSha256']);
      expect(_rgbaSha256(canonicalImage!), rawFinalStage['rgbaSha256']);
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
