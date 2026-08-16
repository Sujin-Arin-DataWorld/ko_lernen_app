import 'personal_room.dart';

/// Asset families that can be freely arranged in a private Hanok room.
enum RoomAssetKind {
  decoration,
  sticker,
  stamp;

  static RoomAssetKind? fromStorage(String value) {
    for (final kind in values) {
      if (kind.name == value) {
        return kind;
      }
    }
    return null;
  }
}

/// One item on the shared 3:4 logical room canvas.
///
/// [x] and [y] are normalized center coordinates. [width] is a normalized
/// canvas-width fraction, so the same layout survives different device sizes.
/// List order inside a [RoomLayout] is the stable back-to-front z-order.
class RoomLayoutItem {
  final String instanceId;
  final RoomAssetKind kind;
  final String assetId;
  final double x;
  final double y;
  final double width;
  final double rotation;

  const RoomLayoutItem({
    required this.instanceId,
    required this.kind,
    required this.assetId,
    required this.x,
    required this.y,
    required this.width,
    this.rotation = 0,
  });

  RoomLayoutItem copyWith({
    String? instanceId,
    RoomAssetKind? kind,
    String? assetId,
    double? x,
    double? y,
    double? width,
    double? rotation,
  }) => RoomLayoutItem(
    instanceId: instanceId ?? this.instanceId,
    kind: kind ?? this.kind,
    assetId: assetId ?? this.assetId,
    x: x ?? this.x,
    y: y ?? this.y,
    width: width ?? this.width,
    rotation: rotation ?? this.rotation,
  );

  Map<String, Object> toJson({required int z}) => <String, Object>{
    'instanceId': instanceId,
    'kind': kind.name,
    'assetId': assetId,
    'x': x,
    'y': y,
    'width': width,
    'rotation': rotation,
    'z': z,
  };

  @override
  bool operator ==(Object other) =>
      other is RoomLayoutItem &&
      other.instanceId == instanceId &&
      other.kind == kind &&
      other.assetId == assetId &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.rotation == rotation;

  @override
  int get hashCode =>
      Object.hash(instanceId, kind, assetId, x, y, width, rotation);
}

typedef RoomLayout = List<RoomLayoutItem>;
typedef RoomLayouts = Map<PersonalRoomSurface, RoomLayout>;

RoomLayouts copyRoomLayouts(RoomLayouts source) =>
    <PersonalRoomSurface, RoomLayout>{
      for (final entry in source.entries)
        entry.key: List<RoomLayoutItem>.from(entry.value),
    };
