import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/ildu_r16_art.dart';
import 'package:ko_lernen_app/models/ildu_r16_layers.dart';

void main() {
  test(
    'every R16 layer belongs to its unchanged canonical stage and exact file set',
    () {
      final originalBytes = File(IlDuR16ArtCatalog.assetPath).readAsBytesSync();
      expect(
        sha256.convert(originalBytes).toString(),
        IlDuR16LayerCatalog.sourceCatalogSha256,
      );
      final original = IlDuR16ArtCatalog.fromJson(
        jsonDecode(utf8.decode(originalBytes)),
      );
      final catalogBytes = File(
        IlDuR16LayerCatalog.assetPath,
      ).readAsBytesSync();
      final catalog = IlDuR16LayerCatalog.fromJson(
        jsonDecode(utf8.decode(catalogBytes)),
        original: original,
      );
      final receipt =
          jsonDecode(
                File('docs/assets/R16_LAYERS_20261031.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(
        receipt['runtimeCatalog']['sha256'],
        sha256.convert(catalogBytes).toString(),
      );
      expect(
        receipt['canonicalPromotionSha256'],
        IlDuR16LayerCatalog.canonicalPromotionSha256,
      );
      expect(receipt['runtimeStageCount'], 16);
      expect(receipt['unusedFull17thPairIncluded'], false);
      final files = <String, IlDuR16LayerImage>{};
      for (final stage in catalog.stagesByProcessId.values) {
        for (final image in [stage.foreground, stage.shadow]) {
          files[image.asset] = image;
          final bytes = File(image.asset).readAsBytesSync();
          expect(bytes.length, image.bytes, reason: image.asset);
          expect(
            sha256.convert(bytes).toString(),
            image.sha256,
            reason: image.asset,
          );
        }
      }
      final actual = Directory('assets/illustrations/ildu_r16_layers')
          .listSync()
          .whereType<File>()
          .map((f) => f.path.replaceAll(r'\', '/'))
          .toSet();
      expect(actual, files.keys.toSet());
      expect(files.length, receipt['runtimeUniqueAssetCount']);
      expect(
        files.values.fold<int>(0, (sum, image) => sum + image.bytes),
        receipt['runtimeUniqueAssetBytes'],
      );
    },
  );
}
