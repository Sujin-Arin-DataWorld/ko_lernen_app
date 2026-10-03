import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/features/scenarios/scenario_quest_stock.dart';
import 'package:ko_lernen_app/screens/quest_engines/quest_content.dart';
import 'support/scenario_json.dart';

void main() {
  test('diagnose corpus eligibility for named interlocutors', () {
    final corpus = allScenarioJson().map(Scenario.fromJson).toList();
    final stock = ScenarioQuestStock.fromCorpus(corpus);
    for (final id in [
      'sujin',
      'christian',
      'maya',
      'hyuna',
      'andrea',
      'lena',
      'daniel',
      'dongsun',
    ]) {
      final scenes = corpus
          .where((s) => s.dialog.any((d) => d.speaker == id))
          .toList();
      print(
        '$id: ${scenes.where(stock.allowsScenario).length}/${scenes.length}',
      );
      if (id == 'christian') {
        for (final s in scenes) {
          print(
            '${s.id}: ${s.quests.map((q) => "${q.type.name}:${hasPlayableQuestContent(q.type, q.data)}:${stock.count(s.level, q.type)}").join(",")}',
          );
        }
      }
    }
  });
}
