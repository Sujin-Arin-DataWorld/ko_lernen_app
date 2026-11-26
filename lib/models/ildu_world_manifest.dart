import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

enum IlDuWorldEra {
  a1,
  a2,
  b1,
  b2,
  c1,
  c2;

  int get rank => index;

  String get code => name;

  static IlDuWorldEra parse(Object? value, String path) {
    if (value is! String) {
      throw FormatException('$path must be an era code.');
    }
    return values.firstWhere(
      (era) => era.code == value,
      orElse: () => throw FormatException('$path has an unknown era.'),
    );
  }
}

class IlDuWorldBounds {
  final double left;
  final double top;
  final double width;
  final double height;

  const IlDuWorldBounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  double get right => left + width;
  double get bottom => top + height;

  bool contains(double x, double y) =>
      x >= left && x <= right && y >= top && y <= bottom;

  factory IlDuWorldBounds.fromJson(Object? value, String path) {
    final json = _map(value, path);
    return IlDuWorldBounds(
      left: _number(json['left'], '$path.left'),
      top: _number(json['top'], '$path.top'),
      width: _positiveNumber(json['width'], '$path.width'),
      height: _positiveNumber(json['height'], '$path.height'),
    );
  }
}

abstract interface class IlDuWorldAnchor {
  String get id;
  String get ko;
  String get asset;
  double get x;
  double get y;
  double get width;
  double get rotation;
  IlDuWorldEra get unlockEra;
}

class IlDuWorldBuilding implements IlDuWorldAnchor {
  @override
  final String id;
  final String hubId;
  @override
  final String ko;
  final String de;
  @override
  final String asset;
  @override
  final double x;
  @override
  final double y;
  @override
  final double width;
  @override
  final double rotation;
  @override
  final IlDuWorldEra unlockEra;
  final String lessonIntent;

  const IlDuWorldBuilding({
    required this.id,
    required this.hubId,
    required this.ko,
    required this.de,
    required this.asset,
    required this.x,
    required this.y,
    required this.width,
    required this.rotation,
    required this.unlockEra,
    required this.lessonIntent,
  });

  factory IlDuWorldBuilding.fromJson(Object? value, String path) {
    final json = _map(value, path);
    return IlDuWorldBuilding(
      id: _id(json['id'], '$path.id'),
      hubId: _id(json['hubId'], '$path.hubId'),
      ko: _string(json['ko'], '$path.ko'),
      de: _string(json['de'], '$path.de'),
      asset: _asset(json['asset'], '$path.asset'),
      x: _percentage(json['x'], '$path.x'),
      y: _percentage(json['y'], '$path.y'),
      width: _percentage(json['width'], '$path.width'),
      rotation: _number(json['rotation'], '$path.rotation'),
      unlockEra: IlDuWorldEra.parse(json['unlockEra'], '$path.unlockEra'),
      lessonIntent: _string(json['lessonIntent'], '$path.lessonIntent'),
    );
  }
}

class IlDuWorldGate implements IlDuWorldAnchor {
  @override
  final String id;
  @override
  final String ko;
  @override
  final String asset;
  @override
  final double x;
  @override
  final double y;
  @override
  final double width;
  @override
  final double rotation;
  @override
  final IlDuWorldEra unlockEra;

  const IlDuWorldGate({
    required this.id,
    required this.ko,
    required this.asset,
    required this.x,
    required this.y,
    required this.width,
    required this.rotation,
    required this.unlockEra,
  });

  factory IlDuWorldGate.fromJson(Object? value, String path) {
    final json = _map(value, path);
    return IlDuWorldGate(
      id: _id(json['id'], '$path.id'),
      ko: _string(json['ko'], '$path.ko'),
      asset: _asset(json['asset'], '$path.asset'),
      x: _percentage(json['x'], '$path.x'),
      y: _percentage(json['y'], '$path.y'),
      width: _percentage(json['width'], '$path.width'),
      rotation: _number(json['rotation'], '$path.rotation'),
      unlockEra: IlDuWorldEra.parse(json['unlockEra'], '$path.unlockEra'),
    );
  }
}

class IlDuWorldYard {
  final String id;
  final String ko;
  final IlDuWorldBounds bounds;

  const IlDuWorldYard({
    required this.id,
    required this.ko,
    required this.bounds,
  });

  factory IlDuWorldYard.fromJson(Object? value, String path) {
    final json = _map(value, path);
    return IlDuWorldYard(
      id: _id(json['id'], '$path.id'),
      ko: _string(json['ko'], '$path.ko'),
      bounds: IlDuWorldBounds.fromJson(json['bounds'], '$path.bounds'),
    );
  }
}

class IlDuWorldDecoration {
  final String id;
  final String ko;
  final String asset;
  final double width;
  final double rotation;
  final IlDuWorldEra unlockEra;
  final List<String> allowedYards;

  const IlDuWorldDecoration({
    required this.id,
    required this.ko,
    required this.asset,
    required this.width,
    required this.rotation,
    required this.unlockEra,
    required this.allowedYards,
  });

  factory IlDuWorldDecoration.fromJson(Object? value, String path) {
    final json = _map(value, path);
    return IlDuWorldDecoration(
      id: _id(json['id'], '$path.id'),
      ko: _string(json['ko'], '$path.ko'),
      asset: _asset(json['asset'], '$path.asset'),
      width: _percentage(json['width'], '$path.width'),
      rotation: _number(json['rotation'], '$path.rotation'),
      unlockEra: IlDuWorldEra.parse(json['unlockEra'], '$path.unlockEra'),
      allowedYards: _idList(json['allowedYards'], '$path.allowedYards'),
    );
  }
}

class IlDuWorldHub {
  final String id;
  final String ko;
  final String de;
  final List<String> buildingIds;
  final String primaryRoute;
  final List<String> secondaryRoutes;

  const IlDuWorldHub({
    required this.id,
    required this.ko,
    required this.de,
    required this.buildingIds,
    required this.primaryRoute,
    required this.secondaryRoutes,
  });

  factory IlDuWorldHub.fromJson(Object? value, String path) {
    final json = _map(value, path);
    return IlDuWorldHub(
      id: _id(json['id'], '$path.id'),
      ko: _string(json['ko'], '$path.ko'),
      de: _string(json['de'], '$path.de'),
      buildingIds: _idList(json['buildingIds'], '$path.buildingIds'),
      primaryRoute: _route(json['primaryRoute'], '$path.primaryRoute'),
      secondaryRoutes: _stringList(
        json['secondaryRoutes'],
        '$path.secondaryRoutes',
      ),
    );
  }
}

class IlDuWorldEraDefinition {
  final IlDuWorldEra id;
  final String ko;
  final String de;

  const IlDuWorldEraDefinition({
    required this.id,
    required this.ko,
    required this.de,
  });

  factory IlDuWorldEraDefinition.fromJson(Object? value, String path) {
    final json = _map(value, path);
    return IlDuWorldEraDefinition(
      id: IlDuWorldEra.parse(json['id'], '$path.id'),
      ko: _string(json['ko'], '$path.ko'),
      de: _string(json['de'], '$path.de'),
    );
  }
}

class IlDuWorldCanvas {
  final int width;
  final int height;
  final String asset;
  final int mobileContentWidth;

  const IlDuWorldCanvas({
    required this.width,
    required this.height,
    required this.asset,
    required this.mobileContentWidth,
  });

  factory IlDuWorldCanvas.fromJson(Object? value, String path) {
    final json = _map(value, path);
    final camera = _map(json['camera'], '$path.camera');
    return IlDuWorldCanvas(
      width: _positiveInt(json['width'], '$path.width'),
      height: _positiveInt(json['height'], '$path.height'),
      asset: _asset(json['asset'], '$path.asset'),
      mobileContentWidth: _positiveInt(
        camera['mobileContentWidth'],
        '$path.camera.mobileContentWidth',
      ),
    );
  }
}

/// Converts saved map coordinates into the current artwork's camera space.
/// Stored placements and learning identities keep their existing coordinate system.
class IlDuMapPresentation {
  const IlDuMapPresentation.identity()
    : a = 1,
      b = 0,
      c = 0,
      d = 0,
      e = 1,
      f = 0,
      anchors = const {},
      yardOffsets = const {};

  const IlDuMapPresentation._(
    this.a,
    this.b,
    this.c,
    this.d,
    this.e,
    this.f,
    this.anchors,
    this.yardOffsets,
  );

  final double a;
  final double b;
  final double c;
  final double d;
  final double e;
  final double f;
  final Map<String, ({double x, double y, double width})> anchors;
  final Map<String, ({double dx, double dy})> yardOffsets;

  double get determinant => a * e - b * d;
  double get widthScale => math.sqrt(determinant.abs());

  double projectX(double x, double y) => a * x + b * y + c;
  double projectY(double x, double y) => d * x + e * y + f;
  double logicalDeltaX(double dx, double dy) => (e * dx - b * dy) / determinant;
  double logicalDeltaY(double dx, double dy) =>
      (-d * dx + a * dy) / determinant;
  double decorationX(String yardId, double x, double y) =>
      projectX(x, y) + (yardOffsets[yardId]?.dx ?? 0);
  double decorationY(String yardId, double x, double y) =>
      projectY(x, y) + (yardOffsets[yardId]?.dy ?? 0);

  double anchorX(IlDuWorldAnchor anchor, double x, double y) =>
      (anchors[anchor.id]?.x ?? projectX(anchor.x, anchor.y)) +
      a * (x - anchor.x) +
      b * (y - anchor.y);

  double anchorY(IlDuWorldAnchor anchor, double x, double y) =>
      (anchors[anchor.id]?.y ?? projectY(anchor.x, anchor.y)) +
      d * (x - anchor.x) +
      e * (y - anchor.y);

  double anchorWidth(IlDuWorldAnchor anchor) =>
      anchors[anchor.id]?.width ?? anchor.width * widthScale;

  factory IlDuMapPresentation.fromJson(Object? value) {
    if (value == null) {
      return const IlDuMapPresentation.identity();
    }
    final json = _map(value, r'$.mapPresentation');
    final coefficients = _list(json['matrix'], r'$.mapPresentation.matrix');
    if (coefficients.length != 6) {
      throw const FormatException(
        'Map presentation requires six coefficients.',
      );
    }
    final matrix = [
      for (var i = 0; i < coefficients.length; i++)
        _number(
          coefficients[i],
          r'$.mapPresentation.matrix'
          '[$i]',
        ),
    ];
    final determinant = matrix[0] * matrix[4] - matrix[1] * matrix[3];
    if (determinant.abs() < .000001) {
      throw const FormatException('Map presentation must be invertible.');
    }
    final rows = _map(json['anchors'], r'$.mapPresentation.anchors');
    final anchors = <String, ({double x, double y, double width})>{};
    for (final entry in rows.entries) {
      final path = r'$.mapPresentation.anchors.' + entry.key;
      final row = _map(entry.value, path);
      anchors[_id(entry.key, path)] = (
        x: _percentage(row['x'], '$path.x'),
        y: _percentage(row['y'], '$path.y'),
        width: _percentage(row['width'], '$path.width'),
      );
    }
    final offsetRows = _map(
      json['yardOffsets'] ?? const <String, dynamic>{},
      r'$.mapPresentation.yardOffsets',
    );
    final yardOffsets = <String, ({double dx, double dy})>{};
    for (final entry in offsetRows.entries) {
      final path = r'$.mapPresentation.yardOffsets.' + entry.key;
      final row = _map(entry.value, path);
      yardOffsets[_id(entry.key, path)] = (
        dx: _number(row['dx'], '$path.dx'),
        dy: _number(row['dy'], '$path.dy'),
      );
    }
    return IlDuMapPresentation._(
      matrix[0],
      matrix[1],
      matrix[2],
      matrix[3],
      matrix[4],
      matrix[5],
      Map.unmodifiable(anchors),
      Map.unmodifiable(yardOffsets),
    );
  }
}

class IlDuWorldManifest {
  static const String assetPath = 'assets/data/ildu_world_manifest_v1.json';
  static const String worldAssetRoot =
      'assets/illustrations/ildu_r16_support/world/';

  final IlDuWorldCanvas canvas;
  final List<IlDuWorldEraDefinition> eras;
  final List<IlDuWorldHub> hubs;
  final List<IlDuWorldYard> yards;
  final List<IlDuWorldGate> gates;
  final List<IlDuWorldBuilding> buildings;
  final List<IlDuWorldDecoration> decorations;
  final IlDuMapPresentation mapPresentation;

  const IlDuWorldManifest({
    required this.canvas,
    required this.eras,
    required this.hubs,
    required this.yards,
    required this.gates,
    required this.buildings,
    required this.decorations,
    this.mapPresentation = const IlDuMapPresentation.identity(),
  });

  static Future<IlDuWorldManifest> load({AssetBundle? bundle}) async {
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    return IlDuWorldManifest.fromJson(jsonDecode(raw));
  }

  factory IlDuWorldManifest.fromJson(Object? value) {
    final json = _map(value, r'$');
    if (json['schemaVersion'] != 1 || json['worldId'] != 'ildu_gotaek_v3') {
      throw const FormatException('Unsupported Ildu world manifest.');
    }
    final eraOrder = _stringList(json['eraOrder'], r'$.eraOrder');
    if (eraOrder.join(',') != 'a1,a2,b1,b2,c1,c2') {
      throw const FormatException('Ildu era order is not canonical.');
    }
    final result = IlDuWorldManifest(
      canvas: IlDuWorldCanvas.fromJson(json['canvas'], r'$.canvas'),
      eras: _decodeList(
        json['eras'],
        r'$.eras',
        IlDuWorldEraDefinition.fromJson,
      ),
      hubs: _decodeList(json['hubs'], r'$.hubs', IlDuWorldHub.fromJson),
      yards: _decodeList(json['yards'], r'$.yards', IlDuWorldYard.fromJson),
      gates: _decodeList(json['gates'], r'$.gates', IlDuWorldGate.fromJson),
      buildings: _decodeList(
        json['buildings'],
        r'$.buildings',
        IlDuWorldBuilding.fromJson,
      ),
      decorations: _decodeList(
        json['decorations'],
        r'$.decorations',
        IlDuWorldDecoration.fromJson,
      ),
      mapPresentation: IlDuMapPresentation.fromJson(json['mapPresentation']),
    );
    result._validateReferences();
    return result;
  }

  String worldAsset(String filename) => '$worldAssetRoot$filename';

  String decorationAsset(String filename) =>
      'assets/illustrations/decorations/$filename';

  IlDuWorldHub hubFor(String id) => hubs.firstWhere((hub) => hub.id == id);
  IlDuWorldYard yardFor(String id) => yards.firstWhere((yard) => yard.id == id);
  IlDuWorldDecoration decorationFor(String id) =>
      decorations.firstWhere((decoration) => decoration.id == id);

  void _validateReferences() {
    if (canvas.width != 2412 ||
        canvas.height != 2622 ||
        buildings.length != 11 ||
        gates.length != 5) {
      throw const FormatException('Ildu V1 geometry contract changed.');
    }
    final hubIds = hubs.map((hub) => hub.id).toSet();
    final buildingIds = buildings.map((building) => building.id).toSet();
    final yardIds = yards.map((yard) => yard.id).toSet();
    final anchorIds = {...buildingIds, ...gates.map((gate) => gate.id)};
    if (!mapPresentation.anchors.keys.every(anchorIds.contains)) {
      throw const FormatException(
        'Map presentation contains an unknown anchor.',
      );
    }
    if (!mapPresentation.yardOffsets.keys.every(yardIds.contains)) {
      throw const FormatException('Map presentation contains an unknown yard.');
    }
    if (hubIds.length != hubs.length ||
        buildingIds.length != buildings.length ||
        yardIds.length != yards.length) {
      throw const FormatException('Ildu manifest contains duplicate IDs.');
    }
    for (final building in buildings) {
      if (!hubIds.contains(building.hubId)) {
        throw FormatException('Unknown hub for ${building.id}.');
      }
    }
    for (final hub in hubs) {
      if (!hub.buildingIds.every(buildingIds.contains)) {
        throw FormatException('Unknown building in hub ${hub.id}.');
      }
    }
    for (final decoration in decorations) {
      if (decoration.allowedYards.isEmpty ||
          !decoration.allowedYards.every(yardIds.contains)) {
        throw FormatException('Unknown yard for ${decoration.id}.');
      }
    }
  }
}

typedef _Decoder<T> = T Function(Object? value, String path);

List<T> _decodeList<T>(Object? value, String path, _Decoder<T> decoder) {
  final items = _list(value, path);
  return List<T>.unmodifiable([
    for (var index = 0; index < items.length; index++)
      decoder(items[index], '$path[$index]'),
  ]);
}

Map<String, dynamic> _map(Object? value, String path) {
  if (value is! Map) {
    throw FormatException('$path must be an object.');
  }
  return value.map((key, item) {
    if (key is! String) {
      throw FormatException('$path keys must be strings.');
    }
    return MapEntry(key, item);
  });
}

List<Object?> _list(Object? value, String path) {
  if (value is! List) {
    throw FormatException('$path must be a list.');
  }
  return List<Object?>.from(value);
}

String _string(Object? value, String path) {
  if (value is! String || value.trim().isEmpty || value.trim() != value) {
    throw FormatException('$path must be a non-empty string.');
  }
  return value;
}

String _id(Object? value, String path) {
  final result = _string(value, path);
  if (!RegExp(r'^[a-z0-9-]+$').hasMatch(result)) {
    throw FormatException('$path must be a stable ID.');
  }
  return result;
}

String _asset(Object? value, String path) {
  final result = _string(value, path);
  if (result.contains('/') || !result.endsWith('.png')) {
    throw FormatException('$path must be a local PNG filename.');
  }
  return result;
}

String _route(Object? value, String path) {
  final result = _string(value, path);
  if (!result.startsWith('/')) {
    throw FormatException('$path must be an app route.');
  }
  return result;
}

double _number(Object? value, String path) {
  if (value is! num || !value.toDouble().isFinite) {
    throw FormatException('$path must be finite.');
  }
  return value.toDouble();
}

double _positiveNumber(Object? value, String path) {
  final result = _number(value, path);
  if (result <= 0) {
    throw FormatException('$path must be positive.');
  }
  return result;
}

double _percentage(Object? value, String path) {
  final result = _number(value, path);
  if (result < 0 || result > 100) {
    throw FormatException('$path must be a percentage.');
  }
  return result;
}

int _positiveInt(Object? value, String path) {
  if (value is! int || value <= 0) {
    throw FormatException('$path must be a positive integer.');
  }
  return value;
}

List<String> _idList(Object? value, String path) {
  final values = _list(value, path);
  return List<String>.unmodifiable([
    for (var index = 0; index < values.length; index++)
      _id(values[index], '$path[$index]'),
  ]);
}

List<String> _stringList(Object? value, String path) {
  final values = _list(value, path);
  return List<String>.unmodifiable([
    for (var index = 0; index < values.length; index++)
      _string(values[index], '$path[$index]'),
  ]);
}
