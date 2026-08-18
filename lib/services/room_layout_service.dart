import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../data/sticker_catalog.dart';
import '../models/personal_room.dart';
import '../models/room_layout.dart';
import '../widgets/sori/dancheong_stamp.dart';
import '../widgets/sori/placed_decoration.dart';
import 'analytics_service.dart';
import 'room_placement_service.dart';
import 'storage_service.dart';

enum RoomLayoutLoadSource { v3, migratedV2, recoveredCorruptV3, futureVersion }

class RoomLayoutSnapshot {
  final RoomLayouts layouts;
  final RoomLayoutLoadSource source;
  final bool writable;

  const RoomLayoutSnapshot({
    required this.layouts,
    required this.source,
    required this.writable,
  });
}

enum RoomLayoutWriteResult {
  added,
  selectedExisting,
  updated,
  removed,
  reordered,
  notOwned,
  unknownAsset,
  limitReached,
  missingItem,
  futureVersion,
}

class RoomLayoutMutation {
  final RoomLayouts layouts;
  final RoomLayoutWriteResult result;
  final String? selectedId;

  const RoomLayoutMutation({
    required this.layouts,
    required this.result,
    this.selectedId,
  });
}

/// Single v3 authority for every private-room layout.
///
/// Reward ownership remains in [Storage.ownedDecor] and
/// [Storage.earnedStamps]. This service only owns local arrangement. It reads
/// v2 slots as a rollback/migration source but writes v3 exclusively.
class RoomLayoutService {
  RoomLayoutService._();

  static const int schemaVersion = 3;
  static const int maxItemsPerRoom = 40;
  static const int maxStickerCopiesPerCodePerRoom = 4;
  static const int maxItemsTotal = 90;
  static const double minWidth = .08;
  static const double maxWidth = .72;

  static Future<void> _writeTail = Future<void>.value();

  @visibleForTesting
  static void resetForTesting() {
    _writeTail = Future<void>.value();
  }

  static Future<T> _serialize<T>(Future<T> Function() action) {
    final next = _writeTail.then<T>((_) => action());
    _writeTail = next.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return next;
  }

  /// Reads v3 without writing. If it is absent, valid v2 slots are projected
  /// into normalized free-layout coordinates in memory and only become v3 on
  /// the user's first edit.
  /// Decoration slugs currently placed anywhere across every personal-room
  /// surface. Used by `reward_unused` analytics to find owned-but-idle décor
  /// — deliberately ignores stickers/stamps, which aren't reward-pool items.
  static Set<String> placedDecorSlugs() {
    final layouts = load().layouts;
    return {
      for (final items in layouts.values)
        for (final item in items)
          if (item.kind == RoomAssetKind.decoration) item.assetId,
    };
  }

  static RoomLayoutSnapshot load() {
    final raw = Storage.roomLayoutsV3Raw;
    if (raw == null) {
      return RoomLayoutSnapshot(
        layouts: migrateLegacy(Storage.roomPlacements),
        source: RoomLayoutLoadSource.migratedV2,
        writable: true,
      );
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('layout root');
      }
      final version = decoded['version'];
      if (version is int && version > schemaVersion) {
        return RoomLayoutSnapshot(
          layouts: migrateLegacy(Storage.roomPlacements),
          source: RoomLayoutLoadSource.futureVersion,
          writable: false,
        );
      }
      if (version != schemaVersion || decoded['surfaces'] is! Map) {
        throw const FormatException('layout version');
      }
      return RoomLayoutSnapshot(
        layouts: _decodeSurfaces(decoded['surfaces'] as Map),
        source: RoomLayoutLoadSource.v3,
        writable: true,
      );
    } on Object {
      return RoomLayoutSnapshot(
        layouts: migrateLegacy(Storage.roomPlacements),
        source: RoomLayoutLoadSource.recoveredCorruptV3,
        writable: true,
      );
    }
  }

  /// Deterministic v2 slot adapter used by production recovery and previews.
  static RoomLayouts migrateLegacy(RoomPlacements placements) {
    final normalized = RoomPlacementService.sanitizeAll(placements);
    final layouts = <PersonalRoomSurface, RoomLayout>{};
    for (final surface in PersonalRoomSurface.values) {
      final placement = normalized[surface];
      if (placement == null) {
        continue;
      }
      final items = <RoomLayoutItem>[];
      for (final slot in slotsForPersonalRoom(surface)) {
        final slug = placement[slot.id];
        if (slug == null) {
          continue;
        }
        final width = (slot.widthFrac * decorScale(slug)).clamp(
          minWidth,
          maxWidth,
        );
        final normalizedHeight = slot.anchor == DecorAnchor.center
            ? slot.heightFrac
            : width * .75;
        items.add(
          RoomLayoutItem(
            instanceId: 'decor:$slug',
            kind: RoomAssetKind.decoration,
            assetId: slug,
            x: (slot.leftFrac + slot.widthFrac / 2).clamp(.04, .96),
            y: (1 - slot.bottomFrac - normalizedHeight / 2).clamp(.04, .96),
            width: width,
          ),
        );
      }
      if (items.isNotEmpty) {
        layouts[surface] = items;
      }
    }
    return sanitize(layouts);
  }

  static RoomLayouts sanitize(RoomLayouts layouts) {
    final result = <PersonalRoomSurface, RoomLayout>{};
    final instanceIds = <String>{};
    final singleAssets = <String>{};
    var total = 0;
    for (final surface in PersonalRoomSurface.values) {
      final kept = <RoomLayoutItem>[];
      final stickersPerCode = <String, int>{};
      for (final item in layouts[surface] ?? const <RoomLayoutItem>[]) {
        if (total >= maxItemsTotal || kept.length >= maxItemsPerRoom) {
          break;
        }
        final normalized = _normalizeItem(item);
        if (normalized == null || !instanceIds.add(normalized.instanceId)) {
          continue;
        }
        if (normalized.kind != RoomAssetKind.sticker) {
          final key = '${normalized.kind.name}:${normalized.assetId}';
          if (!singleAssets.add(key)) {
            continue;
          }
        } else {
          final count = stickersPerCode[normalized.assetId] ?? 0;
          if (count >= maxStickerCopiesPerCodePerRoom) {
            continue;
          }
          stickersPerCode[normalized.assetId] = count + 1;
        }
        kept.add(normalized);
        total++;
      }
      if (kept.isNotEmpty) {
        result[surface] = kept;
      }
    }
    return result;
  }

  static Future<RoomLayoutMutation> addItem(
    PersonalRoomSurface surface,
    RoomAssetKind kind,
    String assetId,
  ) => _serialize(() async {
    final snapshot = load();
    if (!snapshot.writable) {
      return RoomLayoutMutation(
        layouts: snapshot.layouts,
        result: RoomLayoutWriteResult.futureVersion,
      );
    }
    if (!_knownAsset(kind, assetId)) {
      return RoomLayoutMutation(
        layouts: snapshot.layouts,
        result: RoomLayoutWriteResult.unknownAsset,
      );
    }
    if (kind == RoomAssetKind.decoration &&
        !furnishedDecorSlugs(Storage.ownedDecor).contains(assetId)) {
      return RoomLayoutMutation(
        layouts: snapshot.layouts,
        result: RoomLayoutWriteResult.notOwned,
      );
    }
    if (kind == RoomAssetKind.stamp &&
        !Storage.earnedStamps.contains(assetId)) {
      return RoomLayoutMutation(
        layouts: snapshot.layouts,
        result: RoomLayoutWriteResult.notOwned,
      );
    }

    final layouts = copyRoomLayouts(snapshot.layouts);
    if (kind != RoomAssetKind.sticker) {
      final instanceId =
          '${kind == RoomAssetKind.decoration ? 'decor' : 'stamp'}:$assetId';
      for (final entry in layouts.entries.toList()) {
        final index = entry.value.indexWhere((i) => i.instanceId == instanceId);
        if (index < 0) {
          continue;
        }
        if (entry.key == surface) {
          return RoomLayoutMutation(
            layouts: layouts,
            result: RoomLayoutWriteResult.selectedExisting,
            selectedId: instanceId,
          );
        }
        entry.value.removeAt(index);
        if (entry.value.isEmpty) {
          layouts.remove(entry.key);
        }
        break;
      }
      final target = layouts.putIfAbsent(surface, () => <RoomLayoutItem>[]);
      if (!_hasRoomCapacity(layouts, target)) {
        return RoomLayoutMutation(
          layouts: snapshot.layouts,
          result: RoomLayoutWriteResult.limitReached,
        );
      }
      final item = _newItem(kind, assetId, instanceId, target.length);
      target.add(item);
      await _persist(layouts);
      Analytics.itemPlaced(itemType: kind.name, itemId: assetId);
      return RoomLayoutMutation(
        layouts: layouts,
        result: RoomLayoutWriteResult.added,
        selectedId: item.instanceId,
      );
    }

    final target = layouts.putIfAbsent(surface, () => <RoomLayoutItem>[]);
    final sameCode = target.where(
      (item) => item.kind == RoomAssetKind.sticker && item.assetId == assetId,
    );
    if (!_hasRoomCapacity(layouts, target) ||
        sameCode.length >= maxStickerCopiesPerCodePerRoom) {
      return RoomLayoutMutation(
        layouts: snapshot.layouts,
        result: RoomLayoutWriteResult.limitReached,
      );
    }
    final counter = _nextStickerCounter(layouts);
    final item = _newItem(
      kind,
      assetId,
      'sticker:$assetId:$counter',
      target.length,
    );
    target.add(item);
    await _persist(layouts);
    Analytics.itemPlaced(itemType: kind.name, itemId: assetId);
    return RoomLayoutMutation(
      layouts: layouts,
      result: RoomLayoutWriteResult.added,
      selectedId: item.instanceId,
    );
  });

  static Future<RoomLayoutMutation> updateItem(
    PersonalRoomSurface surface,
    RoomLayoutItem updated,
  ) => _serialize(() async {
    final snapshot = load();
    if (!snapshot.writable) {
      return RoomLayoutMutation(
        layouts: snapshot.layouts,
        result: RoomLayoutWriteResult.futureVersion,
      );
    }
    final layouts = copyRoomLayouts(snapshot.layouts);
    final items = layouts[surface];
    final index =
        items?.indexWhere((i) => i.instanceId == updated.instanceId) ?? -1;
    if (items == null || index < 0) {
      return RoomLayoutMutation(
        layouts: snapshot.layouts,
        result: RoomLayoutWriteResult.missingItem,
      );
    }
    final existing = items[index];
    if (existing.kind != updated.kind || existing.assetId != updated.assetId) {
      return RoomLayoutMutation(
        layouts: snapshot.layouts,
        result: RoomLayoutWriteResult.unknownAsset,
      );
    }
    items[index] = _normalizeItem(updated) ?? existing;
    await _persist(layouts);
    return RoomLayoutMutation(
      layouts: layouts,
      result: RoomLayoutWriteResult.updated,
      selectedId: updated.instanceId,
    );
  });

  static Future<RoomLayoutMutation> removeItem(
    PersonalRoomSurface surface,
    String instanceId,
  ) => _serialize(() async {
    final snapshot = load();
    if (!snapshot.writable) {
      return RoomLayoutMutation(
        layouts: snapshot.layouts,
        result: RoomLayoutWriteResult.futureVersion,
      );
    }
    final layouts = copyRoomLayouts(snapshot.layouts);
    final items = layouts[surface];
    final before = items?.length ?? 0;
    items?.removeWhere((item) => item.instanceId == instanceId);
    if (items == null || items.length == before) {
      return RoomLayoutMutation(
        layouts: snapshot.layouts,
        result: RoomLayoutWriteResult.missingItem,
      );
    }
    if (items.isEmpty) {
      layouts.remove(surface);
    }
    await _persist(layouts);
    return RoomLayoutMutation(
      layouts: layouts,
      result: RoomLayoutWriteResult.removed,
    );
  });

  static Future<RoomLayoutMutation> reorderItem(
    PersonalRoomSurface surface,
    String instanceId,
    int delta,
  ) => _serialize(() async {
    final snapshot = load();
    if (!snapshot.writable) {
      return RoomLayoutMutation(
        layouts: snapshot.layouts,
        result: RoomLayoutWriteResult.futureVersion,
      );
    }
    final layouts = copyRoomLayouts(snapshot.layouts);
    final items = layouts[surface];
    final index =
        items?.indexWhere((item) => item.instanceId == instanceId) ?? -1;
    if (items == null || index < 0) {
      return RoomLayoutMutation(
        layouts: snapshot.layouts,
        result: RoomLayoutWriteResult.missingItem,
      );
    }
    final next = (index + delta).clamp(0, items.length - 1);
    if (next != index) {
      final item = items.removeAt(index);
      items.insert(next, item);
      await _persist(layouts);
    }
    return RoomLayoutMutation(
      layouts: layouts,
      result: RoomLayoutWriteResult.reordered,
      selectedId: instanceId,
    );
  });

  static RoomLayouts _decodeSurfaces(Map source) {
    final layouts = <PersonalRoomSurface, RoomLayout>{};
    for (final surface in PersonalRoomSurface.values) {
      final rawItems = source[surface.storageKey];
      if (rawItems is! List) {
        continue;
      }
      final decoded = <({int z, int index, RoomLayoutItem item})>[];
      for (var index = 0; index < rawItems.length; index++) {
        final raw = rawItems[index];
        if (raw is! Map) {
          continue;
        }
        final item = _itemFromJson(raw);
        if (item == null) {
          continue;
        }
        decoded.add((
          z: raw['z'] is int ? raw['z'] as int : index,
          index: index,
          item: item,
        ));
      }
      decoded.sort((a, b) {
        final byZ = a.z.compareTo(b.z);
        return byZ != 0 ? byZ : a.index.compareTo(b.index);
      });
      if (decoded.isNotEmpty) {
        layouts[surface] = [for (final entry in decoded) entry.item];
      }
    }
    return sanitize(layouts);
  }

  static RoomLayoutItem? _itemFromJson(Map raw) {
    final instanceId = raw['instanceId'];
    final kindValue = raw['kind'];
    final assetId = raw['assetId'];
    final x = raw['x'];
    final y = raw['y'];
    final width = raw['width'];
    final rotation = raw['rotation'] ?? 0;
    if (instanceId is! String ||
        kindValue is! String ||
        assetId is! String ||
        x is! num ||
        y is! num ||
        width is! num ||
        rotation is! num) {
      return null;
    }
    final kind = RoomAssetKind.fromStorage(kindValue);
    if (kind == null) {
      return null;
    }
    return _normalizeItem(
      RoomLayoutItem(
        instanceId: instanceId,
        kind: kind,
        assetId: assetId,
        x: x.toDouble(),
        y: y.toDouble(),
        width: width.toDouble(),
        rotation: rotation.toDouble(),
      ),
    );
  }

  static RoomLayoutItem? _normalizeItem(RoomLayoutItem item) {
    if (item.instanceId.isEmpty ||
        !_knownAsset(item.kind, item.assetId) ||
        !item.x.isFinite ||
        !item.y.isFinite ||
        !item.width.isFinite ||
        !item.rotation.isFinite) {
      return null;
    }
    final validIdentity = switch (item.kind) {
      RoomAssetKind.decoration => item.instanceId == 'decor:${item.assetId}',
      RoomAssetKind.stamp => item.instanceId == 'stamp:${item.assetId}',
      RoomAssetKind.sticker => item.instanceId.startsWith(
        'sticker:${item.assetId}:',
      ),
    };
    if (!validIdentity) {
      return null;
    }
    return item.copyWith(
      x: item.x.clamp(0.0, 1.0),
      y: item.y.clamp(0.0, 1.0),
      width: item.width.clamp(minWidth, maxWidth),
      rotation: _normalizeRotation(item.rotation),
    );
  }

  static bool _knownAsset(RoomAssetKind kind, String assetId) {
    return switch (kind) {
      RoomAssetKind.decoration => kAvailableDecorations.contains(assetId),
      RoomAssetKind.sticker =>
        stickerByCode(int.tryParse(assetId) ?? -1) != null,
      RoomAssetKind.stamp => DancheongMotif.values.any(
        (motif) => motif.name == assetId,
      ),
    };
  }

  static bool _hasRoomCapacity(RoomLayouts layouts, RoomLayout target) {
    final total = layouts.values.fold<int>(
      0,
      (sum, items) => sum + items.length,
    );
    return target.length < maxItemsPerRoom && total < maxItemsTotal;
  }

  static RoomLayoutItem _newItem(
    RoomAssetKind kind,
    String assetId,
    String instanceId,
    int index,
  ) {
    final offset = (index % 5) * .025;
    return RoomLayoutItem(
      instanceId: instanceId,
      kind: kind,
      assetId: assetId,
      x: (.44 + offset).clamp(.12, .88),
      y: (.47 + offset).clamp(.12, .88),
      width: defaultWidth(kind, assetId),
    );
  }

  static double defaultWidth(RoomAssetKind kind, String assetId) {
    if (kind == RoomAssetKind.sticker) {
      return .19;
    }
    if (kind == RoomAssetKind.stamp) {
      return .18;
    }
    final factor = decorScale(assetId);
    return switch (decorCategoryOf(assetId)) {
      DecorCategory.wall => (.38 * factor).clamp(.14, .58),
      DecorCategory.floor => (.34 * factor).clamp(.14, .52),
      DecorCategory.shelf ||
      DecorCategory.peg => (.20 * factor).clamp(.12, .34),
      DecorCategory.outdoor => (.28 * factor).clamp(.14, .46),
    };
  }

  static int _nextStickerCounter(RoomLayouts layouts) {
    var max = 0;
    for (final item in layouts.values.expand((items) => items)) {
      if (item.kind != RoomAssetKind.sticker) {
        continue;
      }
      final value = int.tryParse(item.instanceId.split(':').last);
      if (value != null) {
        max = math.max(max, value);
      }
    }
    return max + 1;
  }

  static double _normalizeRotation(double value) {
    var result = value % (math.pi * 2);
    if (result > math.pi) {
      result -= math.pi * 2;
    }
    if (result < -math.pi) {
      result += math.pi * 2;
    }
    return result;
  }

  static Future<void> _persist(RoomLayouts layouts) async {
    final clean = sanitize(layouts);
    final surfaces = <String, Object>{};
    for (final surface in PersonalRoomSurface.values) {
      final items = clean[surface];
      if (items == null || items.isEmpty) {
        continue;
      }
      surfaces[surface.storageKey] = <Object>[
        for (var z = 0; z < items.length; z++) items[z].toJson(z: z),
      ];
    }
    await Storage.setRoomLayoutsV3Raw(
      jsonEncode(<String, Object>{
        'version': schemaVersion,
        'surfaces': surfaces,
      }),
    );
  }
}
