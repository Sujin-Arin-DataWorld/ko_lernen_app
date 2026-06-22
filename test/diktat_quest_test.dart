import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/quest_engines/diktat_quest.dart';

/// Tests für die produktive "Diktat"-Quest (Hör + Schreib):
/// - reine Vergleichslogik (normalize / isExact / isSpacingOnly)
/// - Daten-Integrität der geseedeten Szenarien
void main() {
  group('DiktatQuest.normalize', () {
    test('trimmt, kollabiert Leerraum, entfernt Endzeichen', () {
      expect(DiktatQuest.normalize('  강남역까지   가주세요.  '), '강남역까지 가주세요');
    });
  });

  group('DiktatQuest.isExact', () {
    const target = '강남역까지 가주세요.';

    test('identisch (mit/ohne Punkt) → true', () {
      expect(DiktatQuest.isExact('강남역까지 가주세요', target), isTrue);
      expect(DiktatQuest.isExact('강남역까지 가주세요.', target), isTrue);
    });

    test('falscher Inhalt → false', () {
      expect(DiktatQuest.isExact('강남역까지 가요', target), isFalse);
    });

    test('fehlendes Leerzeichen ist NICHT exakt', () {
      expect(DiktatQuest.isExact('강남역까지가주세요', target), isFalse);
    });
  });

  group('DiktatQuest.isSpacingOnly', () {
    const target = '강남역까지 가주세요.';

    test('nur Wortabstand falsch → true', () {
      expect(DiktatQuest.isSpacingOnly('강남역까지가주세요', target), isTrue);
      expect(DiktatQuest.isSpacingOnly('강남역 까지 가주세요', target), isTrue);
    });

    test('exakt → false (kein Spacing-Hinweis)', () {
      expect(DiktatQuest.isSpacingOnly('강남역까지 가주세요', target), isFalse);
    });

    test('inhaltlich falsch → false', () {
      expect(DiktatQuest.isSpacingOnly('강남역까지 가요', target), isFalse);
    });

    test('leere Eingabe → false', () {
      expect(DiktatQuest.isSpacingOnly('', target), isFalse);
    });
  });

  group('scenarios.json — geseedete diktat-Quests', () {
    late List<Map<String, dynamic>> diktatQuests;
    late List<Scenario> scenarios;

    setUpAll(() {
      final raw = File('assets/data/scenarios.json').readAsStringSync();
      final root = jsonDecode(raw) as Map<String, dynamic>;
      final list = (root['scenarios'] as List).cast<Map<String, dynamic>>();
      scenarios = list.map(Scenario.fromJson).toList();
      diktatQuests = [
        for (final sc in list)
          for (final q in (sc['quests'] as List? ?? const []))
            if ((q as Map<String, dynamic>)['type'] == 'diktat') q,
      ];
    });

    test('mindestens 8 diktat-Quests vorhanden', () {
      expect(diktatQuests.length, greaterThanOrEqualTo(8));
    });

    test('jede Quest hat targetKo + beide Prompts', () {
      for (final q in diktatQuests) {
        final data = q['data'] as Map<String, dynamic>;
        expect((data['targetKo'] as String? ?? '').trim(), isNotEmpty);
        expect((data['promptDe'] as String? ?? '').trim(), isNotEmpty);
        expect((data['promptEn'] as String? ?? '').trim(), isNotEmpty);
      }
    });

    test('QuestType.diktat wird geparst und liefert targetVocabKeys', () {
      var found = 0;
      for (final sc in scenarios) {
        for (final q in sc.quests) {
          if (q.type == QuestType.diktat) {
            found++;
            final keys = q.targetVocabKeys();
            expect(keys, hasLength(1));
            expect(keys.first.trim(), isNotEmpty);
          }
        }
      }
      expect(found, greaterThanOrEqualTo(8));
    });
  });
}
