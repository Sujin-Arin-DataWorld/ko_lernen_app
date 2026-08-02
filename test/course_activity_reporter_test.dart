import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/services/course_activity_reporter.dart';

void main() {
  test('scenario quest types retain their specific correction reason', () {
    expect(
      masteryErrorForQuestType(QuestType.particlePop),
      MasteryErrorReason.particleRole,
    );
    expect(
      masteryErrorForQuestType(QuestType.batchimDrop),
      MasteryErrorReason.batchim,
    );
    expect(
      masteryErrorForQuestType(QuestType.satzBauen),
      MasteryErrorReason.wordOrder,
    );
    expect(
      masteryErrorForQuestType(QuestType.diktat),
      MasteryErrorReason.spellingSpacing,
    );
    expect(
      masteryErrorForQuestType(QuestType.hoerverstehen),
      MasteryErrorReason.listening,
    );
    expect(
      masteryErrorForQuestType(QuestType.luecken),
      MasteryErrorReason.vocabularyRecall,
    );
  });

  test(
    'scenario checkpoint score is a bounded fraction of passed activities',
    () {
      expect(scenarioCheckpointScore(passed: 7, total: 10), .7);
      expect(scenarioCheckpointScore(passed: 0, total: 0), 0);
      expect(scenarioCheckpointScore(passed: 12, total: 10), 1);
      expect(scenarioCheckpointScore(passed: -1, total: 10), 0);
    },
  );
}
