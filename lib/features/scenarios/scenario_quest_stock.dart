import 'dart:convert';

import '../../models/scenario.dart';
import '../../screens/quest_engines/quest_content.dart';

/// Assessment availability for one complete corpus (or a complete level shard).
/// Keeps authored lessons intact; it never drops questions to grant completion.
final class ScenarioQuestStock {
  ScenarioQuestStock._(this._allowed, this._counts);

  static const minimumPerEngineAndLevel = 5;
  final Map<String, String> _allowed;
  final Map<(LearnerLevel, QuestType), int> _counts;

  factory ScenarioQuestStock.fromCorpus(Iterable<Scenario> corpus) {
    final entries = corpus.toList(growable: false);
    final frequencies = <String, int>{};
    for (final scenario in entries) {
      frequencies.update(scenario.id, (count) => count + 1, ifAbsent: () => 1);
    }
    var candidates = <Scenario>[
      for (final scenario in entries)
        if (scenario.hasExplicitId &&
            frequencies[scenario.id] == 1 &&
            scenario.quests.isNotEmpty &&
            scenario.quests.every(
              (quest) => hasPlayableQuestContent(quest.type, quest.data),
            ) &&
            _signature(scenario) != null)
          scenario,
    ];
    // Removing a lesson with a sparse engine may reduce another engine below
    // the threshold. Resolve the fixed point, rather than expose four items
    // using an unavailable fifth lesson as stock.
    while (true) {
      final identities = <(LearnerLevel, QuestType), Set<String>>{};
      for (final scenario in candidates) {
        for (final quest in scenario.quests) {
          identities
              .putIfAbsent((scenario.level, quest.type), () => <String>{})
              .add(_payload(quest)!);
        }
      }
      final counts = identities.map(
        (key, value) => MapEntry(key, value.length),
      );
      final available = candidates
          .where(
            (scenario) => scenario.quests.every(
              (quest) =>
                  (counts[(scenario.level, quest.type)] ?? 0) >=
                  minimumPerEngineAndLevel,
            ),
          )
          .toList(growable: false);
      if (available.length == candidates.length) {
        return ScenarioQuestStock._(
          Map.unmodifiable({
            for (final scenario in available)
              scenario.id: _signature(scenario)!,
          }),
          Map.unmodifiable(counts),
        );
      }
      candidates = available;
    }
  }

  int count(LearnerLevel level, QuestType type) => _counts[(level, type)] ?? 0;

  bool allowsScenario(Scenario scenario) {
    final expected = _allowed[scenario.id];
    return expected != null && expected == _signature(scenario);
  }

  static String? _signature(Scenario scenario) {
    final questions = <String>[];
    for (final quest in scenario.quests) {
      final payload = _payload(quest);
      if (payload == null) {
        return null;
      }
      questions.add(jsonEncode([quest.id, quest.type.name, payload]));
    }
    return jsonEncode([scenario.level.name, questions]);
  }

  static String? _payload(QuestSpec quest) {
    try {
      return jsonEncode(_canonical(quest.data));
    } on Object {
      return null;
    }
  }

  static Object? _canonical(Object? value) {
    if (value is Map<String, dynamic>) {
      return {
        for (final key in value.keys.toList()..sort())
          key: _canonical(value[key]),
      };
    }
    if (value is List) {
      return value.map(_canonical).toList(growable: false);
    }
    return value;
  }
}
