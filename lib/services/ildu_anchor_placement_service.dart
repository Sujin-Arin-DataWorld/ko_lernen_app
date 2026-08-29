import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ildu_world_manifest.dart';

class IlDuAnchorPlacement {
  final String anchorId;
  final double x;
  final double y;
  final int direction;

  const IlDuAnchorPlacement({
    required this.anchorId,
    required this.x,
    required this.y,
    required this.direction,
  });

  IlDuAnchorPlacement copyWith({double? x, double? y, int? direction}) =>
      IlDuAnchorPlacement(
        anchorId: anchorId,
        x: x ?? this.x,
        y: y ?? this.y,
        direction: direction ?? this.direction,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'anchorId': anchorId,
    'x': x,
    'y': y,
    'direction': direction,
  };

  static IlDuAnchorPlacement? tryFromJson(
    Object? value,
    IlDuWorldManifest manifest,
  ) {
    if (value is! Map) {
      return null;
    }
    final anchorId = value['anchorId'];
    final x = value['x'];
    final y = value['y'];
    final direction = value['direction'];
    if (anchorId is! String ||
        x is! num ||
        y is! num ||
        direction is! int ||
        direction < 0 ||
        direction > 7) {
      return null;
    }
    final knownAnchor = <IlDuWorldAnchor>[
      ...manifest.buildings,
      ...manifest.gates,
    ].any((anchor) => anchor.id == anchorId);
    final normalizedX = x.toDouble();
    final normalizedY = y.toDouble();
    if (!knownAnchor ||
        !normalizedX.isFinite ||
        !normalizedY.isFinite ||
        normalizedX < 0 ||
        normalizedX > 100 ||
        normalizedY < 0 ||
        normalizedY > 100) {
      return null;
    }
    return IlDuAnchorPlacement(
      anchorId: anchorId,
      x: normalizedX,
      y: normalizedY,
      direction: direction,
    );
  }
}

abstract interface class IlDuAnchorPlacementStore {
  Future<List<IlDuAnchorPlacement>> load(IlDuWorldManifest manifest);
  Future<void> save(List<IlDuAnchorPlacement> placements);
}

class SharedPreferencesIlDuAnchorPlacementStore
    implements IlDuAnchorPlacementStore {
  static const String key = 'kl_ildu_anchor_placements_v1';
  static const int maximumPlacements = 20;

  const SharedPreferencesIlDuAnchorPlacementStore();

  @override
  Future<List<IlDuAnchorPlacement>> load(IlDuWorldManifest manifest) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(key);
    if (encoded == null) {
      return const <IlDuAnchorPlacement>[];
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List || decoded.length > maximumPlacements) {
        return const <IlDuAnchorPlacement>[];
      }
      return List<IlDuAnchorPlacement>.unmodifiable(
        decoded
            .map((item) => IlDuAnchorPlacement.tryFromJson(item, manifest))
            .whereType<IlDuAnchorPlacement>(),
      );
    } catch (_) {
      return const <IlDuAnchorPlacement>[];
    }
  }

  @override
  Future<void> save(List<IlDuAnchorPlacement> placements) async {
    final bounded = placements.take(maximumPlacements).toList(growable: false);
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      key,
      jsonEncode(bounded.map((placement) => placement.toJson()).toList()),
    );
    if (!saved) {
      throw StateError('Ildu anchor placement could not be saved.');
    }
  }
}

IlDuAnchorPlacement moveIlDuAnchor({
  required IlDuAnchorPlacement placement,
  required double proposedX,
  required double proposedY,
  required double widthPercent,
  required double heightPercent,
}) {
  final halfWidth = (widthPercent / 2).clamp(0.0, 50.0);
  final halfHeight = (heightPercent / 2).clamp(0.0, 50.0);
  return placement.copyWith(
    x: proposedX.clamp(halfWidth, 100 - halfWidth).toDouble(),
    y: proposedY.clamp(halfHeight, 100 - halfHeight).toDouble(),
  );
}
