import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/ildu_construction_plan.dart';
import 'package:ko_lernen_app/services/ildu_learning_response_evaluator.dart';

/// 평가기 계약 테스트: 3종 기준만 지원하고, 학습자의 입장·도덕·가치관은
/// 어떤 경로로도 채점하지 않는다.
void main() {
  const evaluator = IlDuLearningResponseEvaluator();
  final module = _signboardModule();

  const acceptedShareNow =
      '그냥 넘기기에는 나중에 더 커질 수도 있을 것 같아요. 지금 공유하는 게 낫지 않을까요?';
  const acceptedSoftDefer = '일을 키우자는 뜻은 아니고요. 더 늦기 전에 먼저 말씀드리는 게 좋을 것 같아요.';

  group('IlDuLearningResponseEvaluator', () {
    test('opposite stances pass when both satisfy the same communication task',
        () {
      final first = evaluator.evaluate(
        module,
        input: acceptedShareNow,
        stanceId: 'report-now',
      );
      final second = evaluator.evaluate(
        module,
        input: acceptedSoftDefer,
        stanceId: 'ask-first',
      );
      expect(first.taskComplete, isTrue);
      expect(second.taskComplete, isTrue);
      expect(first.stanceId, 'report-now');
      expect(second.stanceId, 'ask-first');
    });

    test('a stance choice without Korean action does not complete the module',
        () {
      final result = evaluator.evaluate(
        module,
        input: '',
        stanceId: 'report-now',
      );
      expect(result.taskComplete, isFalse);
      expect(result.matchedCriterionIds, isEmpty);
    });

    test('the stance never changes the evaluation outcome', () {
      final withStance = evaluator.evaluate(
        module,
        input: acceptedShareNow,
        stanceId: 'hide-it',
      );
      final withoutStance = evaluator.evaluate(module, input: acceptedShareNow);
      expect(withStance.taskComplete, withoutStance.taskComplete);
      expect(withStance.matchedCriterionIds, withoutStance.matchedCriterionIds);
      expect(withStance.missingCriterionIds, withoutStance.missingCriterionIds);
    });

    test('reports missing required criteria without inventing a score', () {
      final result = evaluator.evaluate(
        module,
        // 공유 제안은 있으나 부담 완화·종결어미 기준이 빠진 응답.
        input: '지금 공유하는 게 낫지 않을까요?',
      );
      expect(result.taskComplete, isFalse);
      expect(result.matchedCriterionIds, contains('share-now'));
      expect(result.missingCriterionIds, contains('lower-pressure'));
    });

    test('normalizes surface whitespace before matching', () {
      final result = evaluator.evaluate(
        module,
        input: '  그냥   넘기기에는 나중에 더 커질 수도 있을 것 같아요.\n'
            '지금 공유하는   게 낫지 않을까요?  ',
      );
      expect(result.taskComplete, isTrue);
      expect(result.normalizedInput.contains('  '), isFalse);
    });

    test('tokenSequence tolerates extra words between authored tokens', () {
      final module = _moduleWithCriterion(
        id: 'defer',
        kind: 'tokenSequence',
        variants: ['올리기 전에 다 괜찮은지'],
      );
      final result = evaluator.evaluate(
        module,
        input: '올리기 전에 혹시 다 괜찮은지 한 번 물어보자.',
      );
      expect(result.taskComplete, isTrue);
    });

    test('tokenSequence rejects tokens out of order', () {
      final module = _moduleWithCriterion(
        id: 'defer',
        kind: 'tokenSequence',
        variants: ['올리기 전에 다 괜찮은지'],
      );
      final result = evaluator.evaluate(
        module,
        input: '다 괜찮은지 올리기 전에 확인했어.',
      );
      expect(result.taskComplete, isFalse);
    });

    test('sentenceEnding matches only at the end of a sentence', () {
      final module = _moduleWithCriterion(
        id: 'polite-ending',
        kind: 'sentenceEnding',
        variants: ['않을까요'],
      );
      expect(
        evaluator
            .evaluate(module, input: '지금 공유하는 게 낫지 않을까요?')
            .taskComplete,
        isTrue,
      );
      expect(
        evaluator
            .evaluate(module, input: '않을까요 라는 말은 부드러워요.')
            .taskComplete,
        isFalse,
      );
    });

    test('optional criteria never block completion', () {
      final module = _moduleWithCriteria([
        {
          'id': 'required-slot',
          'kind': 'meaningSlot',
          'acceptedVariants': ['먼저 말씀드리는 게'],
          'requiredForCompletion': true,
        },
        {
          'id': 'optional-slot',
          'kind': 'meaningSlot',
          'acceptedVariants': ['전혀 다른 표현'],
          'requiredForCompletion': false,
        },
      ]);
      final result = evaluator.evaluate(
        module,
        input: '더 늦기 전에 먼저 말씀드리는 게 좋을 것 같아요.',
      );
      expect(result.taskComplete, isTrue);
      expect(result.missingCriterionIds, isEmpty);
      expect(result.matchedCriterionIds, isNot(contains('optional-slot')));
    });
  });
}

// ---------------------------------------------------------------------------

/// 백세청풍 모듈을 본뜬 3기준 픽스처 (실 데이터와 같은 구조, 내용은 축약).
IlDuLearningModule _signboardModule() => _moduleWithCriteria([
  {
    'id': 'share-now',
    'kind': 'meaningSlot',
    'acceptedVariants': ['지금 공유하는 게 낫지 않을까요', '먼저 말씀드리는 게 좋을 것 같아요'],
    'requiredForCompletion': true,
  },
  {
    'id': 'lower-pressure',
    'kind': 'meaningSlot',
    'acceptedVariants': ['일을 키우자는 뜻은 아니고요', '그냥 넘기기에는'],
    'requiredForCompletion': true,
  },
  {
    'id': 'polite-ending',
    'kind': 'sentenceEnding',
    'acceptedVariants': ['않을까요', '것 같아요'],
    'requiredForCompletion': true,
  },
]);

IlDuLearningModule _moduleWithCriterion({
  required String id,
  required String kind,
  required List<String> variants,
}) => _moduleWithCriteria([
  {
    'id': id,
    'kind': kind,
    'acceptedVariants': variants,
    'requiredForCompletion': true,
  },
]);

IlDuLearningModule _moduleWithCriteria(
  List<Map<String, Object?>> criteria,
) => IlDuLearningModule.fromJson(<String, Object?>{
  'moduleId': 'test-module',
  'sourceRefs': [
    'https://www.heritage.go.kr/heri/cul/culSelectDetail.do?ccbaCpno=1483801860000&pageNo=1_1_1_1',
  ],
  'levelBand': ['b1', 'b2'],
  'knowledgeLenses': ['communication'],
  'copy': {
    for (final language in ['ko', 'de', 'en'])
      language: {
        'title': '제목 $language',
        'history': '역사 $language',
        'criticalLens': '비판 $language',
        'modernScene': '장면 $language',
        'sceneLine': '대사 $language',
        'actionPrompt': '행동 $language',
      },
  },
  'speechBrief': {
    'scene': '보고서 실수 공유 여부',
    'channel': '직장 대면 대화',
    'purpose': '부담을 낮춘 반대와 즉시 공유 제안',
    'speaker': '학습자',
    'addressee': '동료',
    'relationship': '대등한 직장 동료',
    'speechStyle': '해요체',
    'speechAct': '완곡한 반대와 제안',
    'knownFacts': ['보고서에 실수가 있다'],
    'unresolvedFacts': ['수정 담당은 정해지지 않았다'],
    'forbiddenInvention': ['동료가 고의로 숨긴다고 단정하지 않는다'],
  },
  'targetExpressions': ['그냥 넘기기에는'],
  'acceptedVariants': ['그냥 넘기기에는 나중에 더 커질 수도 있을 것 같아요.'],
  'criteria': criteria,
  'scoredDimensions': [
    'communicativeFunction',
    'relationshipRegister',
    'targetLanguage',
  ],
  'completionEvidence': {'type': 'inApp'},
}, 'testModule');
