import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_models.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_service.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/account/account_reconciliation.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_state.dart';

const text = LocalizedText(ko: '상황', de: 'Situation', en: 'Situation');
ContentLesson lesson(String id, {String level = 'a1'}) => ContentLesson(
  id: id,
  kind: LearningContentKind.smalltalk,
  level: level,
  topicId: 'mood',
  title: text,
  intro: text,
  contentIds: ['$id.1', '$id.2'],
  questions: [
    for (var n = 0; n < 3; n++)
      ContentLessonQuestion(
        id: '$id.q$n',
        type: 'choice',
        skill: n == 2 ? 'situation' : 'meaning',
        prompt: text,
        explanation: text,
        options: const [text, text],
        correctIndex: 0,
        sourceIds: n == 2 ? ['$id.1', '$id.2'] : ['$id.${n + 1}'],
      ),
  ],
);

Future<void> complete(ContentLesson item, {bool correct = false}) async {
  await ContentLearningService.savePosition(
    item,
    ContentLessonPhase.practice,
    0,
  );
  for (final q in item.questions) {
    await ContentLearningService.answer(item, q.id, correct);
  }
  await ContentLearningService.finish(item);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var now = DateTime(2026, 9, 22, 12);
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
    now = DateTime(2026, 9, 22, 12);
    ContentLearningService.clock = () => now;
  });
  tearDown(() => ContentLearningService.clock = DateTime.now);

  test('read-only queries do not activate goals or write progress', () async {
    await ContentLearningService.setGoal(
      LearningContentKind.smalltalk,
      'a1',
      2,
    );
    final before = Storage.contentLearningRawJson;
    expect(ContentLearningService.activeDaily(), isEmpty);
    expect(ContentLearningService.progress('absent').completed, isFalse);
    expect(
      ContentLearningService.daily(
        LearningContentKind.smalltalk,
        'a1',
      ).lessonIds,
      isEmpty,
    );
    expect(Storage.contentLearningRawJson, before);
  });

  test(
    'finite two-expression lesson resumes, attempts complete despite mistakes',
    () async {
      final a = lesson('a');
      await ContentLearningService.setGoal(a.kind, 'a1', 1);
      await ContentLearningService.startLesson(a, [a]);
      await ContentLearningService.savePosition(a, ContentLessonPhase.learn, 1);
      expect(ContentLearningService.progress(a.id).position, 1);
      await ContentLearningService.startLesson(a, [a]);
      expect(ContentLearningService.progress(a.id).position, 1);
      await ContentLearningService.savePosition(
        a,
        ContentLessonPhase.practice,
        0,
      );
      await ContentLearningService.answer(a, a.questions.first.id, false);
      expect(ContentLearningService.progress(a.id).position, 1);
      await expectLater(ContentLearningService.finish(a), throwsStateError);
      for (final q in a.questions.skip(1)) {
        await ContentLearningService.answer(a, q.id, true);
      }
      await ContentLearningService.finish(a);
      final progress = ContentLearningService.progress(a.id);
      expect(progress.completed, isTrue);
      expect(progress.missedQuestionIds, {a.questions.first.id});
      expect(ContentLearningService.daily(a.kind, 'a1').isComplete, isTrue);
      expect(Storage.xp, 0);
    },
  );

  test(
    'daily IDs freeze, goals stay per level, review cannot double count',
    () async {
      final a = lesson('a'), b = lesson('b'), c = lesson('c');
      await ContentLearningService.setGoal(a.kind, 'a1', 2);
      await ContentLearningService.setGoal(a.kind, 'b1', 3);
      await ContentLearningService.startLesson(a, [a, b]);
      final ids = ContentLearningService.daily(a.kind, 'a1').lessonIds;
      await ContentLearningService.startLesson(a, [c, b, a]);
      expect(ContentLearningService.daily(a.kind, 'a1').lessonIds, ids);
      await complete(a);
      await ContentLearningService.beginReview(a, mistakesOnly: true);
      expect(
        ContentLearningService.progress(a.id).practiceQuestionIds,
        hasLength(3),
      );
      for (final q in a.questions) {
        await ContentLearningService.answer(a, q.id, true);
      }
      await ContentLearningService.finish(a);
      expect(ContentLearningService.progress(a.id).missedQuestionIds, isEmpty);
      expect(ContentLearningService.daily(a.kind, 'a1').completedCount, 1);
      await ContentLearningService.setGoal(a.kind, 'a1', 1);
      expect(ContentLearningService.daily(a.kind, 'a1').isComplete, isTrue);
      expect(ContentLearningService.daily(a.kind, 'a1').lessonIds, ids);
      expect(ContentLearningService.goal(a.kind, 'b1'), 3);
      now = DateTime(2026, 9, 23);
      expect(ContentLearningService.activeDaily(), isEmpty);
      await ContentLearningService.startLesson(b, [a, b, c]);
      expect(ContentLearningService.daily(a.kind, 'a1').lessonIds, ['b']);
      expect(ContentLearningService.daily(a.kind, 'a1').completedCount, 0);
    },
  );

  test(
    'cloud union preserves completion and newest review, reset clears it',
    () async {
      final a = lesson('a');
      await ContentLearningService.startLesson(a, [a]);
      await complete(a);
      final cloud = Storage.contentLearningRawJson;
      now = now.add(const Duration(minutes: 1));
      await ContentLearningService.beginReview(a, mistakesOnly: true);
      for (final q in a.questions) {
        await ContentLearningService.answer(a, q.id, true);
      }
      await ContentLearningService.finish(a);
      await ContentLearningService.mergeCloudJson(cloud);
      expect(ContentLearningService.progress('a').completed, isTrue);
      expect(ContentLearningService.progress('a').missedQuestionIds, isEmpty);
      expect(jsonDecode(Storage.contentLearningRawJson)['version'], 1);
      await Storage.resetAll();
      expect(ContentLearningService.progress('a').completed, isFalse);
      await ContentLearningService.mergeCloudJson(cloud);
      expect(ContentLearningService.progress('a').completed, isTrue);
    },
  );

  test(
    'goal increase extends only frozen reserve, preserves completed lesson',
    () async {
      final a = lesson('a'), b = lesson('b'), c = lesson('c');
      await ContentLearningService.setGoal(a.kind, 'a1', 1);
      await ContentLearningService.startLesson(a, [a, b, c]);
      await complete(a);
      await ContentLearningService.setGoal(a.kind, 'a1', 3);
      expect(ContentLearningService.daily(a.kind, 'a1').lessonIds, [
        'a',
        'b',
        'c',
      ]);
      expect(ContentLearningService.daily(a.kind, 'a1').completedCount, 1);
      expect(ContentLearningService.daily(a.kind, 'a1').target, 3);
    },
  );

  test(
    'review of seen part does not lose unfinished learning cursor',
    () async {
      final a = lesson('a');
      await ContentLearningService.startLesson(a, [a]);
      await ContentLearningService.savePosition(a, ContentLessonPhase.learn, 1);
      await ContentLearningService.beginReview(a);
      expect(ContentLearningService.progress('a').practiceQuestionIds, [
        'a.q0',
      ]);
      await ContentLearningService.answer(a, 'a.q0', false);
      await ContentLearningService.finish(a);
      expect(ContentLearningService.progress('a').completed, isFalse);
      await ContentLearningService.startLesson(a, [a]);
      expect(
        ContentLearningService.progress('a').phase,
        ContentLessonPhase.learn,
      );
      expect(ContentLearningService.progress('a').position, 1);
      expect(ContentLearningService.progress('a').cursorId, 'a.2');
      await complete(a, correct: true);
      expect(ContentLearningService.progress('a').completed, isTrue);
    },
  );

  test(
    'backup restore and account reconciliation merge independent levels',
    () async {
      final a = lesson('a');
      await ContentLearningService.setGoal(a.kind, 'a1', 2);
      await ContentLearningService.startLesson(a, [a]);
      await complete(a);
      final raw = Storage.contentLearningRawJson;
      final backup = await CloudSync.buildBackupPayload();
      expect(backup['content_learning_json'], raw);
      await Storage.resetAll();
      await ContentLearningService.setGoal(a.kind, 'b1', 3);
      final local = AccountReconciliationSnapshot.decodeCloudDocument({
        'content_learning_json': Storage.contentLearningRawJson,
      }).value!;
      final remote = AccountReconciliationSnapshot.decodeCloudDocument({
        'content_learning_json': raw,
      }).value!;
      final merged = AccountReconciliationMerger.merge(
        local: local,
        remote: remote,
        catalog: {},
      );
      expect(merged.conflicts, isEmpty);
      await CloudSync.applyRestorePayload(merged.merged!.toCloudDocument());
      expect(ContentLearningService.goal(a.kind, 'a1'), 2);
      expect(ContentLearningService.goal(a.kind, 'b1'), 3);
      expect(ContentLearningService.progress('a').completed, isTrue);
      await expectLater(
        CloudSync.applyRestorePayload({'content_learning_json': 'broken'}),
        throwsFormatException,
      );
      expect(ContentLearningService.progress('a').completed, isTrue);
    },
  );

  test(
    'same-clock latest answer survives merge and cannot become wrong again',
    () async {
      final a = lesson('a');
      await ContentLearningService.startLesson(a, [a]);
      await complete(a);
      final old = Storage.contentLearningRawJson;
      await ContentLearningService.beginReview(a, mistakesOnly: true);
      for (final q in a.questions) {
        await ContentLearningService.answer(a, q.id, true);
      }
      await ContentLearningService.finish(a);
      final fresh = Storage.contentLearningRawJson;
      final merged = ContentLearningState.mergeJson(old, fresh);
      expect(
        (ContentLearningState.decode(
              merged,
            )['lessons']['a']['missedQuestionIds']
            as List),
        isEmpty,
      );
      expect(ContentLearningState.mergeJson(fresh, old), merged);
    },
  );

  test(
    'midnight completion starts today without carrying yesterday backlog',
    () async {
      final a = lesson('a'), b = lesson('b'), c = lesson('c');
      await ContentLearningService.setGoal(a.kind, 'a1', 2);
      now = DateTime(2026, 9, 22, 23, 59);
      await ContentLearningService.startLesson(a, [a, b, c]);
      await ContentLearningService.savePosition(a, ContentLessonPhase.learn, 1);
      now = DateTime(2026, 9, 23, 0, 1);
      await ContentLearningService.startLesson(a, [a, b, c]);
      await complete(a);
      final daily = ContentLearningService.daily(a.kind, 'a1');
      expect(daily.target, 2);
      expect(daily.completedCount, 1);
      expect(daily.lessonIds, ['a', 'b']);
      expect(ContentLearningService.activeDaily(), hasLength(1));
    },
  );

  test(
    'goal extension survives older backup and extra learning never increases target',
    () async {
      final a = lesson('a'), b = lesson('b'), c = lesson('c'), d = lesson('d');
      await ContentLearningService.setGoal(a.kind, 'a1', 1);
      await ContentLearningService.startLesson(a, [a, b, c, d]);
      final old = Storage.contentLearningRawJson;
      await ContentLearningService.setGoal(a.kind, 'a1', 3);
      await ContentLearningService.mergeCloudJson(old);
      expect(ContentLearningService.daily(a.kind, 'a1').lessonIds, [
        'a',
        'b',
        'c',
      ]);
      await ContentLearningService.startLesson(d, [a, b, c, d]);
      await complete(d);
      expect(ContentLearningService.daily(a.kind, 'a1').target, 3);
      expect(ContentLearningService.daily(a.kind, 'a1').lessonIds, [
        'a',
        'b',
        'c',
      ]);
    },
  );

  test(
    'simultaneous independent writes are serialized, legacy flags stay unassessed',
    () async {
      await Future.wait([
        ContentLearningService.setGoal(LearningContentKind.smalltalk, 'a1', 1),
        ContentLearningService.setGoal(LearningContentKind.listening, 'b2', 3),
      ]);
      expect(
        ContentLearningService.goal(LearningContentKind.smalltalk, 'a1'),
        1,
      );
      expect(
        ContentLearningService.goal(LearningContentKind.listening, 'b2'),
        3,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('kl_completed_scenarios', ['old-story']);
      Storage.resetCachesAfterExternalWrite();
      expect(
        ContentLearningService.progress('listening.old-story').completed,
        isFalse,
      );
      expect(Storage.completedScenarios, contains('old-story'));
    },
  );

  test(
    'selected lesson is retained even when the caller scope omits it',
    () async {
      final a = lesson('a'), b = lesson('b');
      await ContentLearningService.setGoal(a.kind, 'a1', 2);
      await ContentLearningService.startLesson(a, [b, b]);
      expect(ContentLearningService.daily(a.kind, 'a1').lessonIds, ['a', 'b']);
      await ContentLearningService.setGoal(a.kind, 'a1', 3);
      expect(ContentLearningService.daily(a.kind, 'a1').target, 2);
    },
  );
}
