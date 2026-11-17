import 'dart:convert';

import 'package:flutter/services.dart';

/// Exact, presentation-only identities for the approved R16 rendering package.
/// Eligibility, ownership, purchases and course progress belong to their
/// existing services; loading or looking up this catalog never grants anything.
final class IlDuR16ArtCatalog {
  IlDuR16ArtCatalog._(this.buildings, this.estate)
    : stagesByProcessId = Map.unmodifiable({
        for (final building in buildings)
          for (final stage in building.stages) stage.processId: stage,
      });

  static const assetPath = 'assets/data/ildu_r16_art_v1.json';
  static const stageCounts = <String, int>{
    'sarangchae': 16,
    'changgo': 8,
    'jungmunganchae': 12,
    'araechae': 12,
    'toilet-south': 9,
    'anchae': 14,
    'anchae-store': 11,
    'toilet-north': 9,
    'gokgan': 11,
    'ansarang': 14,
    'sadang': 12,
  };

  final List<IlDuR16BuildingArt> buildings;
  final IlDuR16Image estate;
  final Map<String, IlDuR16StageArt> stagesByProcessId;

  static Future<IlDuR16ArtCatalog> load({AssetBundle? bundle}) async =>
      IlDuR16ArtCatalog.fromJson(
        jsonDecode(await (bundle ?? rootBundle).loadString(assetPath)),
      );

  factory IlDuR16ArtCatalog.fromJson(Object? value) {
    final json = _object(value);
    if (json['schemaVersion'] != 1 ||
        json['revision'] != 'ildu-r16' ||
        json['artworkCanonical'] != true ||
        json['presentationOnly'] != true ||
        json['processPolicyIncluded'] != false ||
        json['progressOrOwnershipMigrationIncluded'] != false ||
        json['buildingCount'] != 11 ||
        json['processCount'] != 128) {
      throw const FormatException('Unsupported R16 presentation catalog.');
    }
    final rows = json['buildings'];
    if (rows is! List || rows.length != stageCounts.length) {
      throw const FormatException('R16 requires all eleven buildings.');
    }
    final buildings = <IlDuR16BuildingArt>[];
    final processIds = <String>{};
    for (var i = 0; i < rows.length; i++) {
      final row = _object(rows[i]);
      final id = stageCounts.keys.elementAt(i);
      final stages = row['stages'];
      if (row['id'] != id ||
          stages is! List ||
          stages.length != stageCounts[id]) {
        throw const FormatException('R16 building identity/order changed.');
      }
      final parsed = <IlDuR16StageArt>[];
      for (var j = 0; j < stages.length; j++) {
        final stage = _object(stages[j]);
        final processId = stage['processId'];
        final expectedRoof = id == 'sarangchae' || id == 'jungmunganchae'
            ? 'standalone'
            : 'original';
        if (processId is! String ||
            !RegExp(r'^ildu\.[a-z0-9._-]+$').hasMatch(processId) ||
            !processIds.add(processId) ||
            stage['sequence'] != j + 1 ||
            stage['roofVariant'] != expectedRoof ||
            stage['labelKo'] is! String) {
          throw const FormatException('Invalid R16 process identity or roof.');
        }
        parsed.add(
          IlDuR16StageArt(
            processId: processId,
            sequence: j + 1,
            labelKo: stage['labelKo'] as String,
            image: IlDuR16Image.fromJson(stage),
          ),
        );
      }
      buildings.add(
        IlDuR16BuildingArt(
          id: id,
          nameKo: row['nameKo'] as String,
          full: IlDuR16Image.fromJson(row['full']),
          stages: List.unmodifiable(parsed),
        ),
      );
    }
    if (processIds.length != 128) {
      throw const FormatException('R16 must retain 128 distinct processes.');
    }
    return IlDuR16ArtCatalog._(
      List.unmodifiable(buildings),
      IlDuR16Image.fromJson(json['estate']),
    );
  }
}

final class IlDuR16BuildingArt {
  const IlDuR16BuildingArt({
    required this.id,
    required this.nameKo,
    required this.full,
    required this.stages,
  });
  final String id;
  final String nameKo;
  final IlDuR16Image full;
  final List<IlDuR16StageArt> stages;
}

final class IlDuR16StageArt {
  const IlDuR16StageArt({
    required this.processId,
    required this.sequence,
    required this.labelKo,
    required this.image,
  });
  final String processId;
  final int sequence;
  final String labelKo;
  final IlDuR16Image image;
}

final class IlDuR16Image {
  const IlDuR16Image({
    required this.asset,
    required this.sha256,
    required this.width,
    required this.height,
  });
  final String asset;
  final String sha256;
  final int width;
  final int height;

  factory IlDuR16Image.fromJson(Object? value) {
    final json = _object(value);
    final asset = json['asset'];
    final hash = json['sha256'];
    final width = json['width'];
    final height = json['height'];
    if (asset is! String ||
        hash is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash) ||
        asset != 'assets/illustrations/ildu_r16/$hash.webp' ||
        width is! int ||
        height is! int ||
        width <= 0 ||
        height <= 0) {
      throw const FormatException('Invalid R16 bundled image.');
    }
    return IlDuR16Image(
      asset: asset,
      sha256: hash,
      width: width,
      height: height,
    );
  }
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Expected an R16 object.');
  }
  return value;
}
