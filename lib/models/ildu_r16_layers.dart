import 'dart:convert';

import 'package:flutter/services.dart';

import 'ildu_r16_art.dart';

/// Presentation derivatives of the approved standalone Sarangchae scene.
/// The original catalog and all construction/ownership policies remain separate.
final class IlDuR16LayerCatalog {
  IlDuR16LayerCatalog._(this.stagesByProcessId);

  static const assetPath = 'assets/data/ildu_r16_sarang_layers_v1.json';
  static const sourceCatalogSha256 =
      'f0dfbb6fd210e32fe4b5771f58c2dbeebfb3d0e27aa5c85158cc531f98152859';
  static const canonicalPromotionSha256 =
      '384b07d14464a86dc02bc274d6a50336f356ad7b4b7ecc7027e8825021480865';

  final Map<String, IlDuR16LayerStage> stagesByProcessId;

  static Future<IlDuR16LayerCatalog> load({AssetBundle? bundle}) async {
    final source = bundle ?? rootBundle;
    final original = await IlDuR16ArtCatalog.load(bundle: source);
    return IlDuR16LayerCatalog.fromJson(
      jsonDecode(await source.loadString(assetPath)),
      original: original,
    );
  }

  factory IlDuR16LayerCatalog.fromJson(
    Object? value, {
    required IlDuR16ArtCatalog original,
  }) {
    if (value is! Map<String, dynamic> ||
        value['schemaVersion'] != 1 ||
        value['presentationOnly'] != true ||
        value['sourceCatalogSha256'] != sourceCatalogSha256 ||
        value['canonicalPromotionSha256'] != canonicalPromotionSha256 ||
        value['shadowOperation'] != 'multiply-then-foreground-source-over' ||
        value['progressOrOwnershipMigrationIncluded'] != false) {
      throw const FormatException('Unsupported R16 layer provenance.');
    }
    final rows = value['stages'];
    final sourceStages = original.buildings.first.stages;
    if (rows is! List || rows.length != sourceStages.length) {
      throw const FormatException(
        'All sixteen Sarangchae stages are required.',
      );
    }
    final stages = <String, IlDuR16LayerStage>{};
    for (var i = 0; i < sourceStages.length; i++) {
      final row = rows[i];
      final source = sourceStages[i];
      if (row is! Map<String, dynamic> ||
          row['sequence'] != source.sequence ||
          row['processId'] != source.processId ||
          row['sourceImageSha256'] != source.image.sha256) {
        throw const FormatException('R16 stage identity changed.');
      }
      final foreground = IlDuR16LayerImage.fromJson(row['foreground']);
      final shadow = IlDuR16LayerImage.fromJson(row['shadow']);
      if (foreground.width != shadow.width ||
          foreground.height != shadow.height) {
        throw const FormatException('R16 layers must share the entire canvas.');
      }
      stages[source.processId] = IlDuR16LayerStage(
        processId: source.processId,
        foreground: foreground,
        shadow: shadow,
      );
    }
    return IlDuR16LayerCatalog._(Map.unmodifiable(stages));
  }
}

final class IlDuR16LayerStage {
  const IlDuR16LayerStage({
    required this.processId,
    required this.foreground,
    required this.shadow,
  });

  final String processId;
  final IlDuR16LayerImage foreground;
  final IlDuR16LayerImage shadow;
}

final class IlDuR16LayerImage {
  const IlDuR16LayerImage._({
    required this.asset,
    required this.sha256,
    required this.bytes,
    required this.width,
    required this.height,
  });

  final String asset;
  final String sha256;
  final int bytes;
  final int width;
  final int height;

  factory IlDuR16LayerImage.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Expected R16 layer image.');
    }
    final asset = value['asset'];
    final hash = value['sha256'];
    final bytes = value['bytes'];
    if (hash is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash) ||
        (asset != 'assets/illustrations/ildu_r16_layers/$hash.png' &&
            asset != 'assets/illustrations/ildu_r16_layers/$hash.webp') ||
        bytes is! int ||
        bytes <= 0 ||
        value['width'] != 1800 ||
        value['height'] != 1200) {
      throw const FormatException('Invalid R16 layer identity or canvas.');
    }
    return IlDuR16LayerImage._(
      asset: asset as String,
      sha256: hash,
      bytes: bytes,
      width: 1800,
      height: 1200,
    );
  }
}
