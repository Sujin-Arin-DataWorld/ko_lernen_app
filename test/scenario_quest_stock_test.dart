import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/scenarios/scenario_quest_stock.dart';
import 'package:ko_lernen_app/models/scenario.dart';

import 'support/scenario_stock_fixtures.dart';

void main() {
  for (final amount in [0, 4, 5]) {
    test('$amount distinct questions require five before assessment', () {
      final corpus = List.generate(amount, scene);
      final stock = ScenarioQuestStock.fromCorpus(corpus);
      expect(
        stock.count(LearnerLevel.a1, QuestType.satzBauen),
        amount == 5 ? 5 : 0,
      );
      expect(corpus.where(stock.allowsScenario).length, amount == 5 ? 5 : 0);
    });
  }
  test('levels and engines cannot lend stock to one another', () {
    final a1 = List.generate(5, scene);
    final a2 = List.generate(4, (i) => scene(i, level: LearnerLevel.a2));
    final rare = scene(9, quests: [question(9, type: QuestType.diktat)]);
    final stock = ScenarioQuestStock.fromCorpus([...a1, ...a2, rare]);
    expect(a1.every(stock.allowsScenario), isTrue);
    expect(a2.any(stock.allowsScenario), isFalse);
    expect(stock.allowsScenario(rare), isFalse);
  });
  test('duplicate payloads with different IDs do not manufacture five', () {
    final repeated = List.generate(5, (i) => scene(i, quests: [question(0)]));
    final stock = ScenarioQuestStock.fromCorpus(repeated);
    expect(repeated.any(stock.allowsScenario), isFalse);
  });
  test('duplicate scenario IDs and invalid inputs do not add stock', () {
    final four = List.generate(4, scene);
    final malformed = scene(
      5,
      quests: [
        const QuestSpec(type: QuestType.satzBauen, data: {'targetKo': '?'}),
      ],
    );
    final stock = ScenarioQuestStock.fromCorpus([
      ...four,
      four.first,
      malformed,
    ]);
    expect([...four, malformed].any(stock.allowsScenario), isFalse);
  });
  test('whole-lesson removal is propagated to other engine counts', () {
    final corpus = List.generate(
      5,
      (i) => scene(
        i,
        quests: [
          question(i),
          if (i == 4) question(9, type: QuestType.diktat),
        ],
      ),
    );
    final stock = ScenarioQuestStock.fromCorpus(corpus);
    expect(corpus.any(stock.allowsScenario), isFalse);
    expect(stock.count(LearnerLevel.a1, QuestType.satzBauen), 0);
    expect(
      corpus.last.quests.length,
      2,
      reason: 'Authored questions remain intact',
    );
  });
  test('snapshot does not authorize a mutated question or level', () {
    final corpus = List.generate(5, scene);
    final stock = ScenarioQuestStock.fromCorpus(corpus);
    corpus.first.quests.first.data['targetKo'] = '바뀐 문제';
    expect(stock.allowsScenario(corpus.first), isFalse);
    expect(stock.allowsScenario(scene(0, level: LearnerLevel.a2)), isFalse);
  });
  test('bundled assessments expose only sufficiently stocked engines', () {
    final corpus = <Scenario>[];
    for (final level in LearnerLevel.values) {
      final raw =
          jsonDecode(
                File(
                  'assets/data/scenarios_${level.code}.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      corpus.addAll(
        (raw['scenarios'] as List).map(
          (s) => Scenario.fromJson(s as Map<String, dynamic>),
        ),
      );
    }
    final stock = ScenarioQuestStock.fromCorpus(corpus);
    final exposed = corpus.where(stock.allowsScenario).toList();
    expect(corpus.length, 178);
    expect(exposed.length, 172);
    expect(
      corpus
          .where((s) => !stock.allowsScenario(s))
          .every((s) => s.id.contains('theme_park_date')),
      isTrue,
    );
    for (final scenario in exposed) {
      for (final quest in scenario.quests) {
        expect(
          stock.count(scenario.level, quest.type),
          greaterThanOrEqualTo(5),
        );
      }
    }
    expect(corpus.fold(0, (n, scenario) => n + scenario.quests.length), 547);
  });
}
