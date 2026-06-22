import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/quest_engines/satz_bauen_quest.dart';

/// Tests für die produktive "Satz bauen"-Quest:
/// - reine Scoring-Logik (tokenize / isCorrectOrder / firstMismatch)
/// - Daten-Integrität der geseedeten Szenarien (scenarios.json)
void main() {
  group('SatzBauenQuest.tokenize', () {
    test('zerlegt nach Leerraum und entfernt Satzzeichen', () {
      expect(SatzBauenQuest.tokenize('아이스 아메리카노 톨 사이즈로 주세요.'), [
        '아이스',
        '아메리카노',
        '톨',
        '사이즈로',
        '주세요',
      ]);
    });

    test('normalisiert Komma/Fragezeichen und Mehrfach-Leerraum', () {
      expect(SatzBauenQuest.tokenize('  저기요,  우유 어디 있어요? '), [
        '저기요',
        '우유',
        '어디',
        '있어요',
      ]);
    });
  });

  group('SatzBauenQuest.isCorrectOrder', () {
    const target = '저기요, 우유 어디 있어요?';

    test('korrekte Reihenfolge → true (Satzzeichen egal)', () {
      expect(
        SatzBauenQuest.isCorrectOrder(['저기요', '우유', '어디', '있어요'], target),
        isTrue,
      );
    });

    test('falsche Reihenfolge → false', () {
      expect(
        SatzBauenQuest.isCorrectOrder(['우유', '저기요', '어디', '있어요'], target),
        isFalse,
      );
    });

    test('unvollständig → false', () {
      expect(
        SatzBauenQuest.isCorrectOrder(['저기요', '우유', '어디'], target),
        isFalse,
      );
    });

    test('zu viele Tokens → false', () {
      expect(
        SatzBauenQuest.isCorrectOrder([
          '저기요',
          '우유',
          '어디',
          '있어요',
          '주세요',
        ], target),
        isFalse,
      );
    });
  });

  group('SatzBauenQuest.firstMismatch', () {
    const target = '여기 앉아도 돼요?';

    test('-1 wenn alles korrekt', () {
      expect(SatzBauenQuest.firstMismatch(['여기', '앉아도', '돼요'], target), -1);
    });

    test('Index der ersten falschen Position', () {
      expect(SatzBauenQuest.firstMismatch(['여기', '돼요', '앉아도'], target), 1);
    });

    test('fehlende Tokens → Index der ersten Lücke', () {
      expect(SatzBauenQuest.firstMismatch(['여기'], target), 1);
    });
  });

  group('scenarios.json — geseedete satzBauen-Quests', () {
    late List<Map<String, dynamic>> satzQuests;
    late List<Scenario> scenarios;

    setUpAll(() {
      final raw = File('assets/data/scenarios.json').readAsStringSync();
      final root = jsonDecode(raw) as Map<String, dynamic>;
      final list = (root['scenarios'] as List).cast<Map<String, dynamic>>();
      scenarios = list.map(Scenario.fromJson).toList();
      satzQuests = [
        for (final sc in list)
          for (final q in (sc['quests'] as List? ?? const []))
            if ((q as Map<String, dynamic>)['type'] == 'satzBauen') q,
      ];
    });

    test('mindestens 8 satzBauen-Quests vorhanden', () {
      expect(satzQuests.length, greaterThanOrEqualTo(8));
    });

    test('jede Quest hat targetKo + beide Prompts + saubere Distraktoren', () {
      for (final q in satzQuests) {
        final data = q['data'] as Map<String, dynamic>;
        final targetKo = data['targetKo'] as String? ?? '';
        expect(targetKo.trim(), isNotEmpty);
        expect((data['promptDe'] as String? ?? '').trim(), isNotEmpty);
        expect((data['promptEn'] as String? ?? '').trim(), isNotEmpty);

        final targetTokens = SatzBauenQuest.tokenize(targetKo).toSet();
        final distractors = ((data['distractors'] as List?) ?? const [])
            .map((e) => SatzBauenQuest.normalizeToken(e.toString()))
            .toList();
        // Distraktoren dürfen nicht im Zielsatz vorkommen (sonst mehrdeutig).
        for (final d in distractors) {
          expect(
            targetTokens.contains(d),
            isFalse,
            reason: 'Distraktor "$d" ist im Ziel enthalten',
          );
        }
      }
    });

    test('QuestType.satzBauen wird geparst und liefert targetVocabKeys', () {
      var found = 0;
      for (final sc in scenarios) {
        for (final q in sc.quests) {
          if (q.type == QuestType.satzBauen) {
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
