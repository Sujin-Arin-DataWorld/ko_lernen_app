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
  test('A1 tasks retain their reviewed fingerprint and partial scope', () {
    expect(catalog.forPhase('KP01').length, 33);
    expect(catalog.forPhase('KP02').length, 32);
    expect(catalog.forPhase('KP03').length, 32);
    expect(catalog.forPhase('KP04').length, 31);
    expect(catalog.forPhase('KP05').length, 29);
    expect(catalog.forPhase('KP06').length, 38);
    expect(catalog.forPhase('KP07').length, 35);
    expect(catalog.forPhase('KP08').length, 38);
    expect(catalog.forPhase('KP09').length, 28);
    expect(catalog.forPhase('KP10').length, 40);
    expect(catalog.forPhase('KP11').length, 35);
    expect(catalog.forPhase('KP12').length, 32);
    expect(catalog.forPhase('KP13').length, 32);
    expect(catalog.forPhase('KP14').length, 25);
    expect(catalog.forPhase('KP15').length, 34);
    expect(catalog.forPhase('KP16').length, 28);
    expect(catalog.forPhase('KP17').length, 31);
    expect(catalog.forPhase('KP18').length, 42);
    expect(catalog.forPhase('KP19').length, 28);
    expect(catalog.forPhase('KP20').length, 22);
    expect(catalog.forPhase('KP21'), isEmpty);
  });
  test('a correct total never compensates for an unaffordable order', () {
    final menu = catalog.byId('KP03:reading:01');
    expect(
      menu.evaluate({
        'quantity': '0',
        'total': '0',
        'budget': '0',
      }, assessment: true).passed,
      isTrue,
    );
    expect(
      menu.evaluate({
        'quantity': '0',
        'total': '0',
        'budget': '1',
      }, assessment: true).passed,
      isFalse,
    );
  });
  test(
    'A1 and A2 production preserve polarity, order, roles and speech acts',
    () {
      var checked = 0;
      for (final phase in [
        'KP01',
        'KP02',
        'KP03',
        'KP04',
        'KP05',
        'KP06',
        'KP07',
        'KP08',
      ]) {
        for (final task in catalog.forPhase(phase)) {
          if (!task.id.contains(':production:')) {
            continue;
          }
          checked++;
          final question = task.assessment.questions.single;
          expect(
            task.evaluate({
              question.id: question.acceptedAnswers.single,
            }, assessment: true).passed,
            isTrue,
            reason: task.id,
          );
          final wrong = task.evaluate({
            question.id: question.rejectedAnswers.single,
          }, assessment: true);
          expect(wrong.passed, isFalse, reason: task.id);
          expect(wrong.score, 0, reason: task.id);
          for (final response in ['', '학생 도서관 내일', '다른 표현으로 작성한 답안입니다.']) {
            expect(
              task.evaluate({question.id: response}, assessment: true).passed,
              isFalse,
              reason: task.id,
            );
          }
          final unknown = task.evaluate({
            question.id: '다른 표현으로 작성한 답안입니다.',
          }, assessment: true);
          expect(unknown.score, isNull);
          expect(
            unknown.evidence('unknown', DateTime.utc(2026)).passedCriterionIds,
            isEmpty,
          );
          expect(
            task.evaluate({
              question.id:
                  task.practice.questions.single.acceptedAnswers.single,
            }, assessment: false).passed,
            isFalse,
          );
        }
      }
      expect(checked, 96);
    },
  );
  test(
    'class start and end cannot be swapped despite four correct route facts',
    () {
      final schedule = catalog.byId('KP02:listening:01');
      final response = {
        'start': '0',
        'end': '0',
        'place': '0',
        'transport': '0',
        'class_start': '0',
        'class_end': '0',
      };
      expect(schedule.evaluate(response, assessment: true).passed, isTrue);
      expect(
        schedule.evaluate({
          ...response,
          'class_start': '1',
          'class_end': '1',
        }, assessment: true).passed,
        isFalse,
      );
    },
  );
  test(
    'proposal alternatives preserve choice; invented agreement does not pass',
    () {
      final proposal = catalog.byId('KP03:writing:01');
      expect(
        proposal.evaluate({
          'proposal': '일요일 세 시에 도서관에서 공부할까요?',
        }, assessment: true).passed,
        isTrue,
      );
      expect(
        proposal.evaluate({'proposal': '약속이 확정됐어요.'}, assessment: true).passed,
        isFalse,
      );
      final free = proposal.evaluate({
        'proposal': '일요일 오후 세 시쯤 도서관에서 함께 공부하면 어때요?',
      }, assessment: true);
      expect(free.score, isNull);
      expect(free.passed, isFalse);
    },
  );
  test('a changed answer is rejected by the runtime hash check', () async {
    final raw =
        jsonDecode(await rootBundle.loadString(PhaseTaskCatalog.assetPath))
            as Map<String, dynamic>;
    raw['tasks'][0]['assessment']['questions'][0]['acceptedAnswers'] = ['0'];
    expect(() => PhaseTaskCatalog.parse(raw), throwsFormatException);
  });
  test('A2 actor and source errors cannot be offset by the other facts', () {
    for (final entry in {
      'KP06:reading:01': 'actor_past',
      'KP07:listening:01': 'promise',
      'KP08:listening:01': 'source',
    }.entries) {
      final task = catalog.byId(entry.key);
      final answers = {
        for (final q in task.assessment.questions)
          q.id: q.acceptedAnswers.single,
      };
      expect(task.evaluate(answers, assessment: true).passed, isTrue);
      final critical = task.assessment.questions.firstWhere(
        (q) => q.id == entry.value,
      );
      answers[critical.id] = critical.options.keys.firstWhere(
        (v) => !critical.accepts(v),
      );
      expect(task.evaluate(answers, assessment: true).passed, isFalse);
    }
  });
  test('A2 diary completion and certain inference are rejected', () {
    for (final entry in {
      'KP06:writing:01': 'interruption',
      'KP07:writing:01': 'inference',
      'KP08:writing:01': 'public',
    }.entries) {
      final task = catalog.byId(entry.key);
      final answers = {
        for (final q in task.assessment.questions)
          q.id: q.acceptedAnswers.first,
      };
      expect(task.evaluate(answers, assessment: true).passed, isTrue);
      final critical = task.assessment.questions.firstWhere(
        (q) => q.id == entry.value,
      );
      answers[critical.id] = critical.rejectedAnswers.first;
      final result = task.evaluate(answers, assessment: true);
      expect(result.score, isNotNull);
      expect(result.passed, isFalse);
      answers[critical.id] = '새로운 자유 표현';
      expect(task.evaluate(answers, assessment: true).score, isNull);
    }
  });
  test(
    'free writing never grants mastery, even for copied rubric text',
    () async {
      final bundle =
          jsonDecode(await rootBundle.loadString(PhaseTaskCatalog.assetPath))
              as Map<String, dynamic>;
      final raw = Map<String, dynamic>.from(
        (bundle['tasks'] as List).firstWhere(
          (t) => t['id'] == 'KP01:writing:01',
        ),
      )..remove('contentHash');
      for (final mode in ['practice', 'assessment']) {
        final q = Map<String, dynamic>.from(raw[mode]['questions'][0] as Map);
        q.addAll({
          'kind': 'freeText',
          'acceptedAnswers': <String>[],
          'options': <dynamic>[],
          'required': true,
        });
        raw[mode]['questions'] = [q];
      }
      raw['contentHash'] = phaseFingerprint(raw);
      final task = PhaseTask.fromJson(raw);
      final q = task.assessment.questions.single;
      for (final answer in [
        '키워드 이름 나라',
        q.explanation.pick('ko'),
        '안녕하세요. 제 이름은 민지예요.\n오늘 모임에 왔어요.',
      ]) {
        final result = task.evaluate({q.id: answer}, assessment: true);
        expect(result.score, isNull);
        expect(result.passed, isFalse);
        expect(result.passedCriterionIds, isEmpty);
        expect(
          task.passedBy(result.evidence('free-attempt', DateTime.utc(2026))),
          isFalse,
        );
      }
      final forged = task
          .evaluate({}, assessment: true)
          .evidence('forged', DateTime.utc(2026))
          .toJson();
      forged.addAll({
        'score': 1.0,
        'passedCriterionIds': [q.id],
      });
      expect(task.passedBy(PhaseAttemptEvidence.fromJson(forged)), isFalse);
      expect(task.evaluate({}, assessment: true).passed, isFalse);
    },
  );
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
