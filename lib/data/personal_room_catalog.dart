import '../models/personal_hanok.dart';
import '../models/personal_room.dart';
import '../widgets/sori/placed_decoration.dart';

/// Declarative contract for one private furnishing surface.
///
/// It owns no user data: the map projection decides whether a room is unlocked
/// and [RoomPlacementService] owns all placement validation and persistence.
class PersonalRoomDefinition {
  final PersonalRoomSurface surface;
  final String backgroundAsset;
  final List<SlotDef> slots;
  final PersonalHanokMilestone requires;
  final String studyRoute;

  const PersonalRoomDefinition({
    required this.surface,
    required this.backgroundAsset,
    required this.slots,
    required this.requires,
    required this.studyRoute,
  });
}

const kPersonalRoomDefinitions = <PersonalRoomDefinition>[
  PersonalRoomDefinition(
    surface: PersonalRoomSurface.sarangbang,
    backgroundAsset: 'assets/illustrations/hanok/sarangbang_empty.png',
    slots: kSarangbangSlots,
    requires: PersonalHanokMilestone.sarangchae,
    studyRoute: '/sarangbang',
  ),
  PersonalRoomDefinition(
    surface: PersonalRoomSurface.anbang,
    backgroundAsset:
        'assets/illustrations/personal_hanok_v2/interiors/anbang_empty.png',
    slots: kAnbangSlots,
    requires: PersonalHanokMilestone.anchae,
    studyRoute: '/bookshelf',
  ),
  PersonalRoomDefinition(
    surface: PersonalRoomSurface.daecheongmaru,
    backgroundAsset:
        'assets/illustrations/personal_hanok_v2/interiors/daecheong_empty.png',
    slots: kDaecheongmaruSlots,
    requires: PersonalHanokMilestone.daecheongmaru,
    studyRoute: '/path',
  ),
];

PersonalRoomDefinition personalRoomFor(PersonalRoomSurface surface) =>
    kPersonalRoomDefinitions.firstWhere((room) => room.surface == surface);
