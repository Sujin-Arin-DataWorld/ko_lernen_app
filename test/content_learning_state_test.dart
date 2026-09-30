import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_state.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_service.dart';
import 'package:ko_lernen_app/services/account/account_reconciliation.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

const stamp = '2026-09-22T12:00:00.000Z';
const dayKey = '2026-09-22.smalltalk.a1';
Map<String, dynamic> valid() => {
  'version': 1,
  'goals': {
    'smalltalk.a1': {
      'kind': 'smalltalk',
      'level': 'a1',
      'target': 1,
      'updatedAt': stamp,
    },
  },
  'lessons': {
    'a': {
      'kind': 'smalltalk',
      'level': 'a1',
      'topicId': 'mood',
      'phase': 'practice',
      'position': 1,
      'cursorId': null,
      'seenIds': ['source'],
      'answers': {'q': false},
      'answerTimes': {'q': stamp},
      'attemptAnswers': {'q': false},
      'attemptId': stamp,
      'missedQuestionIds': ['q'],
      'completedAt': null,
      'completionDate': null,
      'reviewMode': false,
      'practiceQuestionIds': ['q'],
      'updatedAt': stamp,
    },
  },
  'days': {
    dayKey: {
      'kind': 'smalltalk',
      'level': 'a1',
      'date': '2026-09-22',
      'target': 1,
      'lessonIds': ['a'],
      'reserveIds': ['a', 'b', 'c'],
      'createdAt': stamp,
      'updatedAt': stamp,
    },
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });
  test('malformed remote state never replaces valid local bytes', () async {
    final before = jsonEncode(valid());
    await Storage.mutateContentLearning((_) => before);
    final corruptions = <void Function(Map<String, dynamic>)>[
      (s) => s['days'][dayKey]['lessonIds'] = [7],
      (s) => s['days'][dayKey]['reserveIds'] = 'bad',
      (s) => s['days'][dayKey]['date'] = '2026-02-31',
      (s) => s['lessons']['a']['answerTimes'] = {},
      (s) => s['lessons']['a']['attemptAnswers'] = {'q': 'wrong type'},
      (s) => s['lessons']['a']['attemptId'] = null,
      (s) => s['lessons']['a']['resumeBeforeReview'] = {'phase': 'learn'},
      (s) => s['lessons']['a']['completionDate'] = '2026-09-22',
      (s) => s['lessons']['a']['missedQuestionIds'] = [],
      (s) => s['goals']['smalltalk.a1']['level'] = 'b1',
    ];
    for (final corrupt in corruptions) {
      final state = valid();
      corrupt(state);
      final remote = jsonEncode(state);
      expect(() => ContentLearningState.decode(remote), throwsFormatException);
      expect(
        AccountReconciliationSnapshot.decodeCloudDocument({
          'content_learning_json': remote,
        }).isPresent,
        isFalse,
      );
      await expectLater(
        ContentLearningService.mergeCloudJson(remote),
        throwsFormatException,
      );
      expect(Storage.contentLearningRawJson, before);
    }
  });
  test(
    'equal-created daily plans merge identically in both operand orders',
    () {
      final a = valid(), b = valid();
      b['days'][dayKey]['lessonIds'] = ['b'];
      b['days'][dayKey]['reserveIds'] = ['b', 'a', 'c'];
      final left = jsonEncode(a), right = jsonEncode(b);
      expect(
        ContentLearningState.mergeJson(left, right),
        ContentLearningState.mergeJson(right, left),
      );
      a['days'][dayKey]['updatedAt'] = '2026-09-22T12:01:00.000Z';
      a['days'][dayKey]['target'] = 3;
      a['days'][dayKey]['lessonIds'] = ['a', 'b', 'c'];
      expect(
        ContentLearningState.mergeJson(jsonEncode(a), right),
        ContentLearningState.mergeJson(right, jsonEncode(a)),
      );
    },
  );
  test(
    'same-origin target reduction never forgets previously selected IDs',
    () {
      final a = valid(), b = valid();
      b['days'][dayKey]['lessonIds'] = ['a', 'b', 'c'];
      b['days'][dayKey]['updatedAt'] = '2026-09-22T12:01:00.000Z';
      final merged = ContentLearningState.mergeJson(
        jsonEncode(a),
        jsonEncode(b),
      );
      expect(
        ContentLearningState.mergeJson(jsonEncode(b), jsonEncode(a)),
        merged,
      );
      expect(ContentLearningState.decode(merged)['days'][dayKey]['lessonIds'], [
        'a',
        'b',
        'c',
      ]);
    },
  );
}
