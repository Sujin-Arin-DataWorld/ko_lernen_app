import '../models/personal_room.dart';
import 'personal_room_furnish_screen.dart';

/// Compatibility entry point for P1's collectible 사랑방 surface.
///
/// 사랑방 was reachable before the outer estate milestone existed, so it keeps
/// that established accessibility while sharing every placement rule and view
/// with the later 안채·대청마루 interiors.
class SarangbangFurnishScreen extends PersonalRoomFurnishScreen {
  const SarangbangFurnishScreen({super.key})
    : super(surface: PersonalRoomSurface.sarangbang, enforceUnlock: false);
}
