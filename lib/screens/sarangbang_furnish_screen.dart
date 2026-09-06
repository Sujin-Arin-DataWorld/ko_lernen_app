import '../models/personal_room.dart';
import 'personal_room_furnish_screen.dart';

/// Compatibility entry point for P1's collectible 사랑방 surface.
///
/// All rooms share the same directly accessible placement rules and view.
class SarangbangFurnishScreen extends PersonalRoomFurnishScreen {
  const SarangbangFurnishScreen({super.key})
    : super(surface: PersonalRoomSurface.sarangbang);
}
