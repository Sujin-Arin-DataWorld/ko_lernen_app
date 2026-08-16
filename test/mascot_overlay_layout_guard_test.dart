import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('remaining quest mascot overlays can extend above their content', () {
    const questFiles = <String>[
      'lib/screens/quest_engines/batchim_drop_quest.dart',
      'lib/screens/quest_engines/diktat_quest.dart',
      'lib/screens/quest_engines/luecken_quest.dart',
      'lib/screens/quest_engines/particle_pop_quest.dart',
      'lib/screens/quest_engines/satz_bauen_quest.dart',
      'lib/screens/quest_engines/uebersetzen_quest.dart',
    ];
    // Der Stack hängt inzwischen teils als `content:` an `QuestLayout`, statt
    // direkt zurückgegeben zu werden (Jin 2026-08-13: CTA unten festhalten).
    // Geprüft wird deshalb die Absicht statt der Rückgabestelle: der Stack mit
    // dem Maskottchen schneidet nicht ab, und das Maskottchen ragt nach oben
    // über seinen Inhalt hinaus.
    final mascotStack = RegExp(
      r'Stack\(\s*clipBehavior:\s*Clip\.none,',
      multiLine: true,
    );
    final overhangingMascot = RegExp(
      r'Positioned\(\s*top:\s*-\d+,',
      multiLine: true,
    );

    for (final path in questFiles) {
      final source = File(path).readAsStringSync();
      // The focused scenario redesign intentionally removed per-question
      // mascots from most engines. Only enforce overhang geometry where a
      // MascotPartner is still rendered (for example the standalone sentence
      // game); absence is now the expected scenario behavior.
      if (!source.contains('MascotPartner(')) continue;
      expect(
        mascotStack.hasMatch(source),
        isTrue,
        reason: '$path positions MascotPartner above the stack boundary.',
      );
      expect(
        overhangingMascot.hasMatch(source),
        isTrue,
        reason: '$path no longer lets the mascot overhang its content.',
      );
    }
  });
}
