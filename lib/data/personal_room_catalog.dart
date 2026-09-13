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
  final String studyRoute;

  const PersonalRoomDefinition({
    required this.surface,
    required this.backgroundAsset,
    required this.slots,
    required this.studyRoute,
  });
}

const kPersonalRoomDefinitions = <PersonalRoomDefinition>[
  PersonalRoomDefinition(
    surface: PersonalRoomSurface.sarangbang,
    backgroundAsset: 'assets/illustrations/hanok/sarangbang_empty.png',
    slots: kSarangbangSlots,
    studyRoute: '/sarangbang',
  ),
];

PersonalRoomDefinition personalRoomFor(PersonalRoomSurface surface) =>
    kPersonalRoomDefinitions.firstWhere((room) => room.surface == surface);
