import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/quest_abandon_tracker.dart';

void main() {
  group('QuestAbandonTracker', () {
    test('reports abandon on dispose when never marked completed', () {
      String? reportedType;
      String? reportedQuestId;
      String? reportedStep;

      final tracker = QuestAbandonTracker(
        questType: 'chosung',
        questId: 'q1',
        lastStepReached: () => 'question_3',
        onAbandon: ({required questType, questId, required lastStepReached}) {
          reportedType = questType;
          reportedQuestId = questId;
          reportedStep = lastStepReached;
          return Future<void>.value();
        },
      );

      tracker.dispose();

      expect(reportedType, 'chosung');
      expect(reportedQuestId, 'q1');
      expect(reportedStep, 'question_3');
    });

    test('does not report abandon when marked completed before dispose', () {
      var reported = false;

      final tracker = QuestAbandonTracker(
        questType: 'vocab_pack',
        lastStepReached: () => 'boss_5',
        onAbandon: ({required questType, questId, required lastStepReached}) {
          reported = true;
          return Future<void>.value();
        },
      );

      tracker.markCompleted();
      tracker.dispose();

      expect(reported, isFalse);
    });

    test('reads lastStepReached lazily at dispose time, not construction', () {
      var currentStep = 'stage_0';
      String? reportedStep;

      final tracker = QuestAbandonTracker(
        questType: 'scenario',
        lastStepReached: () => currentStep,
        onAbandon: ({required questType, questId, required lastStepReached}) {
          reportedStep = lastStepReached;
          return Future<void>.value();
        },
      );

      currentStep = 'stage_2';
      tracker.dispose();

      expect(reportedStep, 'stage_2');
    });

    test('omits questId when not provided', () {
      String? reportedQuestId = 'unset';
      var sawQuestId = true;

      final tracker = QuestAbandonTracker(
        questType: 'hangul',
        lastStepReached: () => 'cards',
        onAbandon: ({required questType, questId, required lastStepReached}) {
          reportedQuestId = questId;
          sawQuestId = questId != null;
          return Future<void>.value();
        },
      );

      tracker.dispose();

      expect(sawQuestId, isFalse);
      expect(reportedQuestId, isNull);
    });
  });
}
