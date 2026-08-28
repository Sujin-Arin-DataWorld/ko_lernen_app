import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ildu_world_manifest.dart';

class IlDuDecorationPlacement {
  final String instanceId;
  final String definitionId;
  final String yardId;
  final double x;
  final double y;

  const IlDuDecorationPlacement({
    required this.instanceId,
    required this.definitionId,
    required this.yardId,
    required this.x,
    required this.y,
  });

  IlDuDecorationPlacement copyWith({String? yardId, double? x, double? y}) {
    return IlDuDecorationPlacement(
      instanceId: instanceId,
      definitionId: definitionId,
      yardId: yardId ?? this.yardId,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'instanceId': instanceId,
    'definitionId': definitionId,
    'yardId': yardId,
    'x': x,
    'y': y,
  };

  static IlDuDecorationPlacement? tryFromJson(
    Object? value,
    IlDuWorldManifest manifest,
  ) {
    if (value is! Map) {
      return null;
    }
    final instanceId = value['instanceId'];
    final definitionId = value['definitionId'];
    final yardId = value['yardId'];
    final x = value['x'];
    final y = value['y'];
    if (instanceId is! String ||
        instanceId.isEmpty ||
        definitionId is! String ||
        yardId is! String ||
        x is! num ||
        y is! num) {
      return null;
    }
    IlDuWorldDecoration definition;
    IlDuWorldYard yard;
    try {
      definition = manifest.decorationFor(definitionId);
      yard = manifest.yardFor(yardId);
    } catch (_) {
      return null;
    }
    if (!definition.allowedYards.contains(yard.id) ||
        !yard.bounds.contains(x.toDouble(), y.toDouble())) {
      return null;
    }
    return IlDuDecorationPlacement(
      instanceId: instanceId,
      definitionId: definitionId,
      yardId: yardId,
      x: x.toDouble(),
      y: y.toDouble(),
    );
  }
}

abstract interface class IlDuDecorationPlacementStore {
  Future<List<IlDuDecorationPlacement>> load(IlDuWorldManifest manifest);
  Future<void> save(List<IlDuDecorationPlacement> placements);
}

class SharedPreferencesIlDuDecorationPlacementStore
    implements IlDuDecorationPlacementStore {
  static const String key = 'kl_ildu_decoration_placements_v1';
  static const int maximumPlacements = 40;

  const SharedPreferencesIlDuDecorationPlacementStore();

  @override
  Future<List<IlDuDecorationPlacement>> load(IlDuWorldManifest manifest) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(key);
    if (encoded == null) {
      return const <IlDuDecorationPlacement>[];
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List || decoded.length > maximumPlacements) {
        return const <IlDuDecorationPlacement>[];
      }
      return List<IlDuDecorationPlacement>.unmodifiable(
        decoded
            .map((item) => IlDuDecorationPlacement.tryFromJson(item, manifest))
            .whereType<IlDuDecorationPlacement>(),
      );
    } catch (_) {
      return const <IlDuDecorationPlacement>[];
    }
  }

  @override
  Future<void> save(List<IlDuDecorationPlacement> placements) async {
    final bounded = placements.take(maximumPlacements).toList(growable: false);
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      key,
      jsonEncode(bounded.map((placement) => placement.toJson()).toList()),
    );
    if (!saved) {
      throw StateError('Ildu decoration placement could not be saved.');
    }
  }
}

IlDuDecorationPlacement moveIlDuDecoration({
  required IlDuDecorationPlacement placement,
  required IlDuWorldDecoration definition,
  required IlDuWorldManifest manifest,
  required double proposedX,
  required double proposedY,
}) {
  for (final yardId in definition.allowedYards) {
    final yard = manifest.yardFor(yardId);
    if (yard.bounds.contains(proposedX, proposedY)) {
      return placement.copyWith(yardId: yard.id, x: proposedX, y: proposedY);
    }
  }
  final yard = manifest.yardFor(placement.yardId);
  return placement.copyWith(
    x: proposedX.clamp(yard.bounds.left, yard.bounds.right).toDouble(),
    y: proposedY.clamp(yard.bounds.top, yard.bounds.bottom).toDouble(),
  );
}
