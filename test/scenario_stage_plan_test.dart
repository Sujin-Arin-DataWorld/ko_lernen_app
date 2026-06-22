import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';

/// Sichert die Stage-Index-Mathematik des Szenario-Players ab — besonders
/// nach Einführung der neuen `rollenspiel`-Stage (Phase 3), die alle
/// nachfolgenden Quest-Indizes verschiebt.
void main() {
  group('buildScenarioStagePlan', () {
    test('ohne Rollenspiel/Grammatik: intro,vocab,dialog,quests,result', () {
      final plan = buildScenarioStagePlan(
        hasRollenspiel: false,
        hasGrammar: false,
        questCount: 3,
      );
      expect(plan, [
        ScenarioStage.intro,
        ScenarioStage.vocab,
        ScenarioStage.dialog,
        ScenarioStage.quest,
        ScenarioStage.quest,
        ScenarioStage.quest,
        ScenarioStage.result,
      ]);
      // erster Quest-Stage-Index = 3 → Quest-Index-Mapping korrekt.
      expect(plan.indexOf(ScenarioStage.quest), 3);
    });

    test('mit Grammatik + Rollenspiel: korrekte Reihenfolge', () {
      final plan = buildScenarioStagePlan(
        hasRollenspiel: true,
        hasGrammar: true,
        questCount: 2,
      );
      expect(plan, [
        ScenarioStage.intro,
        ScenarioStage.vocab,
        ScenarioStage.dialog,
        ScenarioStage.grammar,
        ScenarioStage.rollenspiel,
        ScenarioStage.quest,
        ScenarioStage.quest,
        ScenarioStage.result,
      ]);
      // erster Quest-Stage nach grammar+rollenspiel = Index 5.
      final firstQuest = plan.indexOf(ScenarioStage.quest);
      expect(firstQuest, 5);
      // Quest-Index aus Stage zurückrechnen (wie _currentQuestIndex).
      expect(5 - firstQuest, 0);
      expect(6 - firstQuest, 1);
    });

    test('Rollenspiel ohne Grammatik', () {
      final plan = buildScenarioStagePlan(
        hasRollenspiel: true,
        hasGrammar: false,
        questCount: 1,
      );
      expect(plan, [
        ScenarioStage.intro,
        ScenarioStage.vocab,
        ScenarioStage.dialog,
        ScenarioStage.rollenspiel,
        ScenarioStage.quest,
        ScenarioStage.result,
      ]);
      expect(plan.last, ScenarioStage.result);
    });

    test('letzte Stage ist immer result; Länge = fix + quests', () {
      final plan = buildScenarioStagePlan(
        hasRollenspiel: true,
        hasGrammar: true,
        questCount: 4,
      );
      expect(plan.last, ScenarioStage.result);
      // intro+vocab+dialog+grammar+rollenspiel+result = 6 feste + 4 quests
      expect(plan.length, 10);
    });
  });

  group('scenarios.json — Rollenspiel-Abdeckung', () {
    test('jedes Szenario hat mindestens eine user-Dialogzeile', () {
      final raw = File('assets/data/scenarios.json').readAsStringSync();
      final root = jsonDecode(raw) as Map<String, dynamic>;
      final list = (root['scenarios'] as List).cast<Map<String, dynamic>>();
      for (final sc in list) {
        final dialog = (sc['dialog'] as List).cast<Map<String, dynamic>>();
        final userLines = dialog.where((l) => l['speaker'] == 'user');
        expect(
          userLines,
          isNotEmpty,
          reason: '${sc['id']} braucht >=1 user-Zeile für Rollenspiel',
        );
      }
    });
  });
}
