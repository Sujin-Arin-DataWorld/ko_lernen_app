import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/character_clip.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';

void main() {
  test('tiger profile picker is fixed to tiger_sitting2 (Jin 2026-08-06)', () {
    expect(CharacterClips.profileClipCountFor(MascotKind.tiger), 1);
    expect(
      CharacterClips.profileClipFor(MascotKind.tiger, 0),
      CharacterClips.tigerSitting2,
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
