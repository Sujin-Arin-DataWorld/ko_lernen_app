import '../models/ildu_construction_plan.dart';

/// 한 번의 평가 결과. 점수는 없다 — 저작된 기준의 충족 여부만 있다.
final class IlDuLearningResponseResult {
  IlDuLearningResponseResult({
    required this.taskComplete,
    required Set<String> matchedCriterionIds,
    required Set<String> missingCriterionIds,
    required this.normalizedInput,
    required this.stanceId,
  }) : matchedCriterionIds = Set.unmodifiable(matchedCriterionIds),
       missingCriterionIds = Set.unmodifiable(missingCriterionIds);

  final bool taskComplete;
  final Set<String> matchedCriterionIds;

  /// 완료를 막고 있는 **필수** 기준들. 힌트 표시에 쓴다.
  final Set<String> missingCriterionIds;
  final String normalizedInput;

  /// 학습자가 고른 입장. 성찰 기록용으로 그대로 되돌려줄 뿐, 평가에는 어떤
  /// 영향도 주지 않는다.
  final String? stanceId;
}

/// 저작된 언어 증거만 보는 평가기.
///
/// 계약 (설계 §7·§14, 감독 확정):
/// - 지원 기준은 `meaningSlot`·`tokenSequence`·`sentenceEnding` 3종뿐이다.
/// - 학습자의 입장·도덕·가치관은 **절대 채점하지 않는다**. `stanceId` 는
///   결과에 그대로 실려 나갈 뿐 어떤 분기에도 쓰이지 않는다. 서로 반대인
///   입장이라도 같은 의사소통 과제를 수행하면 똑같이 통과한다.
/// - 점수를 만들어내지 않는다. 충족/미충족 기준 ID 만 보고한다.
final class IlDuLearningResponseEvaluator {
  const IlDuLearningResponseEvaluator();

  IlDuLearningResponseResult evaluate(
    IlDuLearningModule module, {
    required String input,
    String? stanceId,
  }) {
    final normalized = _normalize(input);
    final matched = <String>{};
    final missing = <String>{};
    for (final criterion in module.criteria) {
      final satisfied =
          normalized.isNotEmpty && _matches(criterion, normalized);
      if (satisfied) {
        matched.add(criterion.id);
      } else if (criterion.requiredForCompletion) {
        missing.add(criterion.id);
      }
    }
    return IlDuLearningResponseResult(
      taskComplete: normalized.isNotEmpty && missing.isEmpty,
      matchedCriterionIds: matched,
      missingCriterionIds: missing,
      normalizedInput: normalized,
      stanceId: stanceId,
    );
  }

  bool _matches(IlDuLearningCriterion criterion, String normalized) =>
      switch (criterion.kind) {
        IlDuLearningCriterionKind.meaningSlot => criterion.acceptedVariants.any(
          (variant) => normalized.contains(_normalize(variant)),
        ),
        IlDuLearningCriterionKind.tokenSequence => criterion.acceptedVariants
            .any((variant) => _containsTokenSequence(normalized, variant)),
        IlDuLearningCriterionKind.sentenceEnding => criterion.acceptedVariants
            .any((variant) => _hasSentenceEnding(normalized, variant)),
      };

  /// 완화된 어절 순서 매칭: 변형의 어절들이 입력 어절열에 같은 순서로
  /// 나타나면 통과한다. 입력 어절이 변형 어절을 포함하면(조사·어미가 더
  /// 붙어도) 같은 어절로 본다.
  bool _containsTokenSequence(String normalized, String variant) {
    final inputTokens = normalized.split(' ');
    final variantTokens = _normalize(variant).split(' ');
    if (variantTokens.isEmpty) {
      return false;
    }
    var cursor = 0;
    for (final token in inputTokens) {
      if (token.contains(variantTokens[cursor])) {
        cursor++;
        if (cursor == variantTokens.length) {
          return true;
        }
      }
    }
    return false;
  }

  /// 문장 종결 매칭: 입력을 문장 단위로 나눈 뒤, 어느 한 문장이 변형으로
  /// 끝나면 통과한다. 문장부호는 종결 판정에서 제외한다.
  bool _hasSentenceEnding(String normalized, String variant) {
    final ending = _normalize(variant);
    if (ending.isEmpty) {
      return false;
    }
    return normalized
        .split(_sentenceBreak)
        .map((sentence) => sentence.trim())
        .any((sentence) => sentence.isNotEmpty && sentence.endsWith(ending));
  }

  static final _sentenceBreak = RegExp(r'[.?!…~\n]+');
  static final _whitespaceRun = RegExp(r'\s+');

  /// 표면 정규화: 앞뒤 공백 제거, 연속 공백을 한 칸으로. 의미·표기는
  /// 바꾸지 않는다 (모바일 한글 입력은 NFC 로 들어온다).
  String _normalize(String raw) =>
      raw.trim().replaceAll(_whitespaceRun, ' ');
}
