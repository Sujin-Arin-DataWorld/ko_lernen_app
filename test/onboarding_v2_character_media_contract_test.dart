import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/character_clip.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';

void main() {
  group('onboarding V2 companion confirmation media contract', () {
    test('uses the dedicated choose clip for each companion', () {
      expect(
        CharacterClips.chooseFor(MascotKind.tiger),
        'assets/video/character/tiger_choose.mp4',
      );
      expect(
        CharacterClips.chooseFor(MascotKind.magpie),
        'assets/video/character/magpie_choose.mp4',
      );
    });

    test('choose clips do not derive a separate companion SFX', () {
      expect(
        CharacterClips.sfxFor(CharacterClips.chooseFor(MascotKind.tiger)),
        isNull,
      );
      expect(
        CharacterClips.sfxFor(CharacterClips.chooseFor(MascotKind.magpie)),
        isNull,
      );
    });
  });
}
