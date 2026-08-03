import '../models/course_practice_context.dart';
import '../models/curriculum.dart';
import '../models/grammar.dart';
import '../models/smalltalk.dart';
import 'curriculum_catalog.dart';

/// The exact content IDs that may be practised after opening a library from a
/// course mission. A null result means unrestricted browse mode; an empty set
/// means the supplied route provenance was invalid and must not leak content.
Set<String>? courseContentIdsForContext({
  required CurriculumCatalog catalog,
  required CoursePracticeContext? courseContext,
  required CurriculumContentKind kind,
}) {
  if (courseContext == null) return null;
  final entry = _courseContextEntry(
    catalog: catalog,
    courseContext: courseContext,
    kind: kind,
  );
  if (entry == null) return const <String>{};

  return catalog
      .linksForCourseUnit(entry.courseUnitId)
      .where((link) => link.contentKind == kind)
      .map((link) => link.contentId)
      .toSet();
}

/// Returns one exact, assess-only graph edge per content item for the route
/// that opened this course practice screen. A category-level practice edge is
/// deliberately not enough: a relationship-choice answer must never credit a
/// topical grammar or situation concept merely because the phrase was visible
/// in that mission.
Map<String, ContentLink> courseAssessmentLinksForContext({
  required CurriculumCatalog catalog,
  required CoursePracticeContext? courseContext,
  required CurriculumContentKind kind,
}) {
  if (courseContext == null) return const <String, ContentLink>{};
  final entry = _courseContextEntry(
    catalog: catalog,
    courseContext: courseContext,
    kind: kind,
  );
  if (entry == null || entry.role != ContentLinkRole.assess) {
    return const <String, ContentLink>{};
  }
  if (kind == CurriculumContentKind.smalltalk &&
      (entry.conceptIds.length != 1 ||
          catalog.conceptFor(entry.conceptIds.single)?.kind !=
              ConceptKind.speechStyle)) {
    return const <String, ContentLink>{};
  }

  final links = catalog
      .linksForCourseUnit(entry.courseUnitId)
      .where(
        (link) =>
            link.contentKind == kind &&
            link.role == ContentLinkRole.assess &&
            link.conceptIds.length == 1 &&
            (kind != CurriculumContentKind.smalltalk ||
                catalog.conceptFor(link.conceptIds.single)?.kind ==
                    ConceptKind.speechStyle),
      )
      .toList(growable: false);
  final byContentId = <String, ContentLink>{};
  for (final link in links) {
    // Ambiguous assess edges are not safe to score from a generic card UI.
    if (byContentId.containsKey(link.contentId)) {
      return const <String, ContentLink>{};
    }
    byContentId[link.contentId] = link;
  }
  return Map.unmodifiable(byContentId);
}

ContentLink? _courseContextEntry({
  required CurriculumCatalog catalog,
  required CoursePracticeContext courseContext,
  required CurriculumContentKind kind,
}) {
  if (!courseContext.isFor(kind)) return null;
  final matchingEntries = catalog.contentLinks
      .where((link) => link.id == courseContext.contentLinkId)
      .toList(growable: false);
  if (matchingEntries.length != 1) return null;
  final entry = matchingEntries.single;
  if (entry.courseUnitId != courseContext.courseUnitId ||
      entry.contentKind != kind ||
      entry.contentId != courseContext.initialContentId) {
    return null;
  }
  return entry;
}

/// A short recognition check for a grammar card. It only asks about the card
/// currently shown, so a correct answer becomes evidence for that exact graph
/// node rather than a visit or a card flip.
class GrammarCheckpointQuestion {
  const GrammarCheckpointQuestion({
    required this.contentId,
    required this.optionIds,
  });

  factory GrammarCheckpointQuestion.forGrammar({
    required Grammar target,
    required Iterable<Grammar> candidates,
  }) {
    final distractors =
        candidates
            .map((candidate) => candidate.id)
            .where((id) => id != target.id)
            .toSet()
            .toList()
          ..sort();
    final selectedDistractors = _deterministicDistractors(
      seed: target.id,
      candidates: distractors,
      count: 2,
    );
    return GrammarCheckpointQuestion(
      contentId: target.id,
      optionIds: _rotate(<String>[
        target.id,
        ...selectedDistractors,
      ], target.id),
    );
  }

  final String contentId;
  final List<String> optionIds;

  /// A one-option card is still useful as a study card, but it cannot produce
  /// meaningful mastery evidence. Content authors can add scoped distractors
  /// later without weakening the course lock today.
  bool get canRecordEvidence => optionIds.length >= 2;

  bool isCorrect(String selectedContentId) => selectedContentId == contentId;
}

/// A relationship-and-situation check which is available for every small-talk
/// source line. It deliberately does not score opening a reply, listening, or
/// showing the answer; only choosing the safe relationship is evidence.
class SmalltalkRelationshipCheckpoint {
  const SmalltalkRelationshipCheckpoint({
    required this.contentId,
    required this.correctContext,
    required this.options,
  });

  factory SmalltalkRelationshipCheckpoint.forPhrase(SmalltalkPhrase phrase) {
    final distractors = SmalltalkRelationshipContext.values
        .where((context) => context != phrase.relationshipContext)
        .toList(growable: false);
    final selectedDistractors = _deterministicDistractors(
      seed: phrase.id,
      candidates: distractors,
      count: 2,
    );
    return SmalltalkRelationshipCheckpoint(
      contentId: phrase.id,
      correctContext: phrase.relationshipContext,
      options: _rotate(<SmalltalkRelationshipContext>[
        phrase.relationshipContext,
        ...selectedDistractors,
      ], phrase.id),
    );
  }

  final String contentId;
  final SmalltalkRelationshipContext correctContext;
  final List<SmalltalkRelationshipContext> options;

  bool isCorrect(SmalltalkRelationshipContext selectedContext) =>
      selectedContext == correctContext;
}

List<T> _deterministicDistractors<T>({
  required String seed,
  required List<T> candidates,
  required int count,
}) {
  if (candidates.isEmpty || count <= 0) return List<T>.empty();
  final start = _stableIndex(seed, candidates.length);
  return List<T>.generate(
    count.clamp(0, candidates.length),
    (index) => candidates[(start + index) % candidates.length],
    growable: false,
  );
}

List<T> _rotate<T>(List<T> values, String seed) {
  if (values.length < 2) return values;
  final start = _stableIndex(seed, values.length);
  return <T>[...values.skip(start), ...values.take(start)];
}

int _stableIndex(String seed, int length) {
  if (length <= 0) return 0;
  final value = seed.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  return value % length;
}
