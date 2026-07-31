import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('quest mascot overlays are allowed to extend above their content', () {
    const questFiles = <String>[
      'lib/screens/quest_engines/batchim_drop_quest.dart',
      'lib/screens/quest_engines/diktat_quest.dart',
      'lib/screens/quest_engines/luecken_quest.dart',
      'lib/screens/quest_engines/particle_pop_quest.dart',
      'lib/screens/quest_engines/satz_bauen_quest.dart',
      'lib/screens/quest_engines/uebersetzen_quest.dart',
    ];
    final mascotStack = RegExp(
      r'return\s+Stack\(\s*clipBehavior:\s*Clip\.none,',
      multiLine: true,
    );

    for (final path in questFiles) {
      final source = File(path).readAsStringSync();
      expect(
        mascotStack.hasMatch(source),
        isTrue,
        reason: '$path positions MascotPartner above the stack boundary.',
      );
    }
  });
}
