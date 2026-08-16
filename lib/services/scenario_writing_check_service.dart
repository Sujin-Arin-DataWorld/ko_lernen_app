import '../models/scenario.dart';
import 'book_analysis_text.dart';
import 'korean_proofreading_service.dart';

/// One authored dialogue line that can be shown as grounded fallback evidence.
final class ScenarioWritingReference {
  const ScenarioWritingReference({
    required this.korean,
    required this.localizedMeaning,
  });

  final String korean;
  final String localizedMeaning;
}

/// A grammar explanation explicitly authored on the current scenario.
///
/// This deliberately does not resolve or infer patterns from the learner's
/// sentence. If a scenario has no complete inline grammar block, the writing
/// card has no grammar-based "why" answer.
final class ScenarioWritingDeclaredGrammar {
  const ScenarioWritingDeclaredGrammar({
    required this.title,
    required this.explanation,
  });

  final String title;
  final String explanation;
}

/// Stable, character-neutral evidence extracted from the scenario asset.
final class ScenarioWritingEvidence {
  ScenarioWritingEvidence({
    required Iterable<ScenarioWritingReference> references,
    required this.grammar,
  }) : references = List<ScenarioWritingReference>.unmodifiable(references);

  factory ScenarioWritingEvidence.fromScenario({
    required Scenario scenario,
    required String language,
  }) {
    final references = <ScenarioWritingReference>[];
    final seenKorean = <String>{};
    for (final line in scenario.dialog) {
      final korean = line.ko.trim();
      if (line.speaker != 'user' || korean.isEmpty || !seenKorean.add(korean)) {
        continue;
      }
      references.add(
        ScenarioWritingReference(
          korean: korean,
          localizedMeaning: line.pick(language).trim(),
        ),
      );
    }

    final grammarBlock = scenario.grammarBlock;
    ScenarioWritingDeclaredGrammar? grammar;
    if (grammarBlock != null) {
      final title = grammarBlock.title.pick(language).trim();
      final explanation = grammarBlock.explanation.pick(language).trim();
      if (title.isNotEmpty && explanation.isNotEmpty) {
        grammar = ScenarioWritingDeclaredGrammar(
          title: title,
          explanation: explanation,
        );
      }
    }
    return ScenarioWritingEvidence(references: references, grammar: grammar);
  }

  final List<ScenarioWritingReference> references;
  final ScenarioWritingDeclaredGrammar? grammar;

  bool get hasGroundedEvidence => references.isNotEmpty || grammar != null;
}

/// Facts rendered for Taego, Joy, and the no-companion fallback.
///
/// Character selection is intentionally absent. Both companions receive this
/// exact DTO; the widget may vary only its authored introductory tone.
final class ScenarioWritingFeedbackFacts {
  ScenarioWritingFeedbackFacts({
    required this.originalText,
    required this.suggestion,
    required this.evidence,
    required Iterable<KoreanProofreadingChange> changes,
  }) : changes = List<KoreanProofreadingChange>.unmodifiable(changes);

  final String originalText;
  final String? suggestion;
  final ScenarioWritingEvidence evidence;
  final List<KoreanProofreadingChange> changes;

  bool get hasSuggestion =>
      suggestion != null &&
      suggestion!.trim() !=
          BookAnalysisTextPreprocessor.normalizeNfc(originalText).trim();
}

enum ScenarioWritingCheckKind {
  suggestion,
  noChanges,
  downloadRequired,
  ready,
  fallback,
}

/// Closed result union for the optional post-role-play writing activity.
final class ScenarioWritingCheckOutcome {
  const ScenarioWritingCheckOutcome({
    required this.kind,
    required this.facts,
    required this.status,
    required this.error,
    this.retryAfter,
  });

  final ScenarioWritingCheckKind kind;
  final ScenarioWritingFeedbackFacts facts;
  final KoreanProofreadingStatus status;
  final KoreanProofreadingError error;
  final Duration? retryAfter;

  bool get hasFeedback =>
      kind == ScenarioWritingCheckKind.suggestion ||
      kind == ScenarioWritingCheckKind.noChanges;
}

/// Testable boundary around the platform-specific ML Kit implementation.
abstract interface class ScenarioProofreadingGateway {
  Future<KoreanProofreadingAvailability> check();
  Future<KoreanProofreadingAvailability> download();
  Future<KoreanProofreadingResult> proofread(String originalText);
  Future<void> close();
}

final class _KoreanProofreadingGateway implements ScenarioProofreadingGateway {
  _KoreanProofreadingGateway(this._service);

  final KoreanProofreadingService _service;

  @override
  Future<KoreanProofreadingAvailability> check() => _service.check();

  @override
  Future<KoreanProofreadingAvailability> download() => _service.download();

  @override
  Future<KoreanProofreadingResult> proofread(String originalText) =>
      _service.proofread(originalText);

  @override
  Future<void> close() => _service.close();
}

/// Optional sentence check used after role-play completion.
///
/// It never mutates the learner's input, never produces a score, and never
/// downloads a model from [check]. A failed or unsupported platform call
/// returns only the scenario-authored reference facts supplied by the caller.
final class ScenarioWritingCheckService {
  ScenarioWritingCheckService({ScenarioProofreadingGateway? gateway})
    : _gateway =
          gateway ?? _KoreanProofreadingGateway(KoreanProofreadingService());

  final ScenarioProofreadingGateway _gateway;
  bool _usedGateway = false;

  Future<ScenarioWritingCheckOutcome> check({
    required String input,
    required ScenarioWritingEvidence evidence,
  }) async {
    final rawOriginal = input;
    final requestText = BookAnalysisTextPreprocessor.normalizeNfc(input).trim();
    final baseFacts = _facts(original: rawOriginal, evidence: evidence);
    final inspection = BookAnalysisTextPreprocessor.inspect(requestText);
    if (requestText.runes.length >
        KoreanProofreadingService.maxInputCodePoints) {
      return ScenarioWritingCheckOutcome(
        kind: ScenarioWritingCheckKind.fallback,
        facts: baseFacts,
        status: KoreanProofreadingStatus.failed,
        error: KoreanProofreadingError.inputTooLong,
      );
    }
    if (!inspection.isSafeEditedText) {
      return ScenarioWritingCheckOutcome(
        kind: ScenarioWritingCheckKind.fallback,
        facts: baseFacts,
        status: KoreanProofreadingStatus.failed,
        error: KoreanProofreadingError.invalidInput,
      );
    }

    try {
      _usedGateway = true;
      final availability = await _gateway.check();
      switch (availability.status) {
        case KoreanProofreadingStatus.downloadable:
        case KoreanProofreadingStatus.downloading:
          if (availability.error != KoreanProofreadingError.none) {
            return _availabilityFallback(baseFacts, availability);
          }
          return ScenarioWritingCheckOutcome(
            kind: ScenarioWritingCheckKind.downloadRequired,
            facts: baseFacts,
            status: availability.status,
            error: availability.error,
            retryAfter: availability.retryAfter,
          );
        case KoreanProofreadingStatus.available:
        case KoreanProofreadingStatus.completed:
          if (availability.error != KoreanProofreadingError.none) {
            return _availabilityFallback(baseFacts, availability);
          }
          return await _proofread(
            requestText: requestText,
            evidence: evidence,
            baseFacts: baseFacts,
          );
        case KoreanProofreadingStatus.unsupportedPlatform:
        case KoreanProofreadingStatus.unsupportedAndroidVersion:
        case KoreanProofreadingStatus.featureModuleMissing:
        case KoreanProofreadingStatus.unavailable:
        case KoreanProofreadingStatus.checking:
        case KoreanProofreadingStatus.busy:
        case KoreanProofreadingStatus.quotaExceeded:
        case KoreanProofreadingStatus.backgroundBlocked:
        case KoreanProofreadingStatus.failed:
          return _availabilityFallback(baseFacts, availability);
      }
    } on Object {
      return ScenarioWritingCheckOutcome(
        kind: ScenarioWritingCheckKind.fallback,
        facts: baseFacts,
        status: KoreanProofreadingStatus.failed,
        error: KoreanProofreadingError.unknown,
      );
    }
  }

  /// Starts a model download only after an explicit UI action.
  ///
  /// A successful download does not automatically proofread the sentence. The
  /// caller receives [ScenarioWritingCheckKind.ready] and must wait for a new
  /// explicit check action.
  Future<ScenarioWritingCheckOutcome> download({
    required String input,
    required ScenarioWritingEvidence evidence,
  }) async {
    final requestText = BookAnalysisTextPreprocessor.normalizeNfc(input).trim();
    final facts = _facts(original: input, evidence: evidence);
    if (requestText.runes.length >
        KoreanProofreadingService.maxInputCodePoints) {
      return ScenarioWritingCheckOutcome(
        kind: ScenarioWritingCheckKind.fallback,
        facts: facts,
        status: KoreanProofreadingStatus.failed,
        error: KoreanProofreadingError.inputTooLong,
      );
    }
    if (!BookAnalysisTextPreprocessor.inspect(requestText).isSafeEditedText) {
      return ScenarioWritingCheckOutcome(
        kind: ScenarioWritingCheckKind.fallback,
        facts: facts,
        status: KoreanProofreadingStatus.failed,
        error: KoreanProofreadingError.invalidInput,
      );
    }
    try {
      _usedGateway = true;
      final availability = await _gateway.download();
      if (availability.error == KoreanProofreadingError.none &&
          (availability.status == KoreanProofreadingStatus.available ||
              availability.status == KoreanProofreadingStatus.completed)) {
        return ScenarioWritingCheckOutcome(
          kind: ScenarioWritingCheckKind.ready,
          facts: facts,
          status: availability.status,
          error: availability.error,
          retryAfter: availability.retryAfter,
        );
      }
      if (availability.error == KoreanProofreadingError.none &&
          (availability.status == KoreanProofreadingStatus.downloadable ||
              availability.status == KoreanProofreadingStatus.downloading)) {
        return ScenarioWritingCheckOutcome(
          kind: ScenarioWritingCheckKind.downloadRequired,
          facts: facts,
          status: availability.status,
          error: availability.error,
          retryAfter: availability.retryAfter,
        );
      }
      return ScenarioWritingCheckOutcome(
        kind: ScenarioWritingCheckKind.fallback,
        facts: facts,
        status: availability.status,
        error: availability.error,
        retryAfter: availability.retryAfter,
      );
    } on Object {
      return ScenarioWritingCheckOutcome(
        kind: ScenarioWritingCheckKind.fallback,
        facts: facts,
        status: KoreanProofreadingStatus.failed,
        error: KoreanProofreadingError.unknown,
      );
    }
  }

  Future<ScenarioWritingCheckOutcome> _proofread({
    required String requestText,
    required ScenarioWritingEvidence evidence,
    required ScenarioWritingFeedbackFacts baseFacts,
  }) async {
    final result = await _gateway.proofread(requestText);
    final suggestion = result.suggestion == null
        ? null
        : BookAnalysisTextPreprocessor.normalizeNfc(result.suggestion!).trim();
    final isValid =
        result.status == KoreanProofreadingStatus.completed &&
        result.error == KoreanProofreadingError.none &&
        suggestion != null &&
        suggestion.isNotEmpty &&
        result.originalText == requestText &&
        BookAnalysisTextPreprocessor.inspect(suggestion).isSafeEditedText;
    if (!isValid) {
      return ScenarioWritingCheckOutcome(
        kind: ScenarioWritingCheckKind.fallback,
        facts: baseFacts,
        status: result.status,
        error: result.error == KoreanProofreadingError.none
            ? KoreanProofreadingError.responseRejected
            : result.error,
        retryAfter: result.retryAfter,
      );
    }

    final facts = ScenarioWritingFeedbackFacts(
      originalText: baseFacts.originalText,
      suggestion: suggestion,
      evidence: evidence,
      // Recompute the diff from validated strings. Platform-provided change
      // ranges are untrusted and are never used to rewrite the input field.
      changes: diffKoreanProofreadingTokens(requestText, suggestion),
    );
    return ScenarioWritingCheckOutcome(
      kind: facts.hasSuggestion
          ? ScenarioWritingCheckKind.suggestion
          : ScenarioWritingCheckKind.noChanges,
      facts: facts,
      status: result.status,
      error: result.error,
      retryAfter: result.retryAfter,
    );
  }

  ScenarioWritingFeedbackFacts _facts({
    required String original,
    required ScenarioWritingEvidence evidence,
  }) => ScenarioWritingFeedbackFacts(
    originalText: original,
    suggestion: null,
    evidence: evidence,
    changes: const <KoreanProofreadingChange>[],
  );

  ScenarioWritingCheckOutcome _availabilityFallback(
    ScenarioWritingFeedbackFacts facts,
    KoreanProofreadingAvailability availability,
  ) => ScenarioWritingCheckOutcome(
    kind: ScenarioWritingCheckKind.fallback,
    facts: facts,
    status: availability.status,
    error: availability.error,
    retryAfter: availability.retryAfter,
  );

  Future<void> close() async {
    if (!_usedGateway) {
      return;
    }
    try {
      await _gateway.close();
    } on Object {
      // Closing an optional on-device feature must not affect scenario flow.
    }
  }
}
