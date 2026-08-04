/// Collectible interior surfaces inside the user's private Hanok estate.
///
/// These values only describe local furnishing surfaces. They do not carry
/// course progress, reward ownership, cloud state, or Gye/community data.
enum PersonalRoomSurface {
  sarangbang,
  anbang,
  daecheongmaru;

  String get storageKey => name;

  static PersonalRoomSurface? fromStorageKey(String key) {
    for (final surface in values) {
      if (surface.storageKey == key) {
        return surface;
      }
    }
    return null;
  }
}

/// One room's slot id → decoration slug placement.
typedef RoomPlacement = Map<String, String>;

/// Every local private-room placement, grouped by its surface.
typedef RoomPlacements = Map<PersonalRoomSurface, RoomPlacement>;
