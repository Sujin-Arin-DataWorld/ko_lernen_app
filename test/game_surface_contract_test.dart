import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/quest_engines/quest_content.dart';
import 'package:ko_lernen_app/services/satz_loader.dart';

import 'support/scenario_json.dart';

void main() {
  test('every shipped scenario question passes the playable input guard', () {
    for (final raw in allScenarioJson()) {
      final scenario = Scenario.fromJson(raw);
      expect(scenario.quests, isNotEmpty, reason: scenario.id);
      for (final quest in scenario.quests) {
        expect(
          hasPlayableQuestContent(quest.type, quest.data),
          isTrue,
          reason: '${scenario.id}: ${quest.id} (${quest.type})',
        );
      }
    }
  });

  test(
    'standalone Satz has at least five playable items per displayed level',
    () {
      final root =
          jsonDecode(File('assets/data/satz_sentences.json').readAsStringSync())
              as Map<String, dynamic>;
      final items = (root['items'] as List)
          .map((row) => SatzSentence.fromJson(row as Map<String, dynamic>))
          .toList();
      for (final level in LearnerLevel.values) {
        final playable = SatzLoader.filter(items, level.code).where(
          (item) =>
              hasPlayableQuestContent(QuestType.satzBauen, item.toQuestData()),
        );
        expect(playable.length, greaterThanOrEqualTo(5), reason: level.code);
      }
    },
  );

  test(
    'every standalone Phase 2C game owns Sori chrome, not a raw Scaffold',
    () {
      const screens = <String>[
        'lib/screens/chosung_quiz_screen.dart',
        'lib/screens/silben_kreuz_screen.dart',
        'lib/screens/kkeunmari_screen.dart',
        'lib/screens/cloze_game_screen.dart',
        'lib/screens/daily_challenge_screen.dart',
        'lib/screens/speed_match_screen.dart',
        'lib/screens/satz_arcade_screen.dart',
      ];

      for (final path in screens) {
        final source = File(path).readAsStringSync();
        expect(source, contains('SoriStudyFrame('), reason: path);
        expect(
          RegExp(r'\bScaffold\s*\(').hasMatch(source),
          isFalse,
          reason: '$path must keep the shared SafeArea and responsive frame',
        );
      }
    },
  );

  test('embedded sentence quest remains chrome-free and host-owned', () {
    final source = File(
      'lib/screens/quest_engines/satz_bauen_quest.dart',
    ).readAsStringSync();
    expect(RegExp(r'\bScaffold\s*\(').hasMatch(source), isFalse);
    expect(RegExp(r'\bAppBar\s*\(').hasMatch(source), isFalse);
  });

  test('direct game motion and timers keep accessibility owners', () {
    final stroke = File('lib/widgets/stroke_canvas.dart').readAsStringSync();
    expect(stroke, contains('SoriMotion.reduceMotion(context)'));
    expect(stroke, contains('return Semantics('));

    final choices = File(
      'lib/widgets/sori/quiz_choice.dart',
    ).readAsStringSync();
    expect(choices, contains('SoriMotion.respect(context'));
    expect(choices, contains('selected: widget.isSelected'));

    final syllables = File(
      'lib/screens/silben_kreuz_screen.dart',
    ).readAsStringSync();
    expect(syllables, contains('SoriMotion.respect(context'));
    expect(syllables, contains('Icons.close_rounded'));
    expect(syllables, contains('excludeSemantics: true'));

    final chosung = File(
      'lib/screens/chosung_quiz_screen.dart',
    ).readAsStringSync();
    expect(chosung, contains('WidgetsBindingObserver'));
    expect(chosung, contains('didChangeAppLifecycleState'));

    for (final path in const [
      'lib/screens/kkeunmari_screen.dart',
      'lib/screens/speed_match_screen.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('WidgetsBindingObserver'), reason: path);
      expect(source, contains('didChangeAppLifecycleState'), reason: path);
      expect(source, contains('liveRegion:'), reason: path);
    }
  });
}
