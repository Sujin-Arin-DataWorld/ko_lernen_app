import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/character_clip.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';

void main() {
  test('tiger profile picker uses every requested portrait clip', () {
    expect(CharacterClips.profileClipCountFor(MascotKind.tiger), 5);
    expect(
      [
        CharacterClips.profileClipFor(MascotKind.tiger, 0),
        CharacterClips.profileClipFor(MascotKind.tiger, 1),
        CharacterClips.profileClipFor(MascotKind.tiger, 2),
        CharacterClips.profileClipFor(MascotKind.tiger, 3),
        CharacterClips.profileClipFor(MascotKind.tiger, 4),
      ],
      [
        CharacterClips.tigerStretch,
        CharacterClips.tigerSitting2,
        CharacterClips.tigerRest,
        CharacterClips.tigerBob,
        CharacterClips.tigerChoose,
      ],
    );
  });

  test('magpie profile picker uses every requested portrait clip', () {
    expect(CharacterClips.profileClipCountFor(MascotKind.magpie), 3);
    expect(
      [
        CharacterClips.profileClipFor(MascotKind.magpie, 0),
        CharacterClips.profileClipFor(MascotKind.magpie, 1),
        CharacterClips.profileClipFor(MascotKind.magpie, 2),
      ],
      [
        CharacterClips.magpiePerched,
        CharacterClips.magpieChoose,
        CharacterClips.magpieFlight,
      ],
    );
  });
}
