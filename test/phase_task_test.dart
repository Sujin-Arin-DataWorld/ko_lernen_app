import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/phase_task_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PhaseTaskCatalog catalog;
  setUpAll(() async {
    catalog = await PhaseTaskCatalog.load();
  });
  test('all sixteen tasks retain their reviewed fingerprint', () {
    expect(catalog.tasks.length, 16);
    expect(catalog.forPhase('KP02'), isEmpty);
  });
  test('a changed answer is rejected by the runtime hash check', () async {
    final raw =
        jsonDecode(await rootBundle.loadString(PhaseTaskCatalog.assetPath))
            as Map<String, dynamic>;
    raw['tasks'][0]['assessment']['questions'][0]['acceptedAnswers'] = ['0'];
    expect(() => PhaseTaskCatalog.parse(raw), throwsFormatException);
  });
  test('essential name and role cannot be offset by the other answers', () {
    final task = catalog.byId('KP01:listening:01');
    final bad = task.evaluate({
      'name': '1',
      'role': '1',
      'relation': '0',
    }, assessment: true);
    expect(bad.score, closeTo(2 / 3, .001));
    expect(bad.passed, isFalse);
    final good = task.evaluate({
      'name': '0',
      'role': '1',
      'relation': '1',
    }, assessment: true);
    expect(good.passed, isTrue);
  });
  test(
    'form fields accept exact information and reject negation or keywords',
    () {
      final task = catalog.byId('KP01:writing:01');
      expect(
        task.evaluate({
          'name': ' 유나 ',
          'country': '한국',
          'occupation': '선생님',
          'introduction': '저는 선생님입니다.',
          'contrast': '저는 학생이 아닙니다.',
        }, assessment: true).passed,
        isTrue,
      );
      for (final answer in ['유나가 아니에요', '유나 미나', '']) {
        expect(
          task.evaluate({
            'name': answer,
            'country': '한국',
            'occupation': '선생님',
            'introduction': '저는 선생님입니다.',
            'contrast': '저는 학생이 아닙니다.',
          }, assessment: true).passed,
          isFalse,
        );
      }
    },
  );
  test(
    'alternative free sentence stays unscored while an explicit polarity reversal fails',
    () {
      final task = catalog.byId('KP01:writing:01');
      final response = {
        'name': '유나',
        'country': '한국',
        'occupation': '선생님',
        'introduction': '저는 선생님이에요.',
        'contrast': '저는 학생이 아니에요.',
      };
      final unknown = task.evaluate({
        ...response,
        'introduction': '저는 아이들을 가르치는 사람이에요.',
      }, assessment: true);
      expect(unknown.score, isNull);
      expect(unknown.passed, isFalse);
      expect(
        unknown.evidence('unknown', DateTime.utc(2026)).passedCriterionIds,
        isEmpty,
      );
      final reversed = task.evaluate({
        ...response,
        'contrast': '저는 학생이에요.',
      }, assessment: true);
      expect(reversed.score, .8);
      expect(reversed.passed, isFalse);
    },
  );
  test('speech and practice never become mastery', () {
    expect(
      catalog.byId('KP01:speaking:01').evaluate({}, assessment: true).score,
      isNull,
    );
    final task = catalog.byId('KP01:writing:01');
    expect(
      task.evaluate({'name': '미나', 'country': '독일'}, assessment: false).passed,
      isFalse,
    );
  });
}
