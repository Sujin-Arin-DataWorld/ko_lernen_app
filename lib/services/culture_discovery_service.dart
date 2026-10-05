import '../models/cultural_glossary.dart';
import '../models/culture_story_arc.dart';
import '../models/scenario_culture_link.dart';
import 'course_progress_service.dart';
import 'cultural_glossary_repository.dart';
import 'culture_story_arc_repository.dart';
import 'scenario_culture_link_repository.dart';
import 'storage_service.dart';

typedef CultureCompletedScenarioIdsLoader = Future<Set<String>> Function();
typedef CultureLinkCatalogLoader =
    Future<ScenarioCultureLinkCatalog?> Function();
typedef CultureGlossaryLoader = Future<CulturalGlossary?> Function();
typedef CultureStoryArcCatalogLoader =
    Future<CultureStoryArcCatalog?> Function();

class CultureStoryArcProjection {
  const CultureStoryArcProjection({
    required this.arc,
    required this.completedStepCount,
  });

  final CultureStoryArc arc;
  final int completedStepCount;

  int get stepCount => arc.steps.length;
  bool get isComplete => completedStepCount == stepCount;
}

class CultureDiscoverySnapshot {
  CultureDiscoverySnapshot({
    required List<CulturalGlossaryEntry> entries,
    required this.availableTermCount,
    required Set<String> completionScenarioIds,
    required this.catalogAvailable,
    List<CultureStoryArcProjection> storyArcs = const [],
  }) : entries = List.unmodifiable(entries),
       completionScenarioIds = Set.unmodifiable(completionScenarioIds),
       storyArcs = List.unmodifiable(storyArcs);

  final List<CulturalGlossaryEntry> entries;
  final int availableTermCount;
  final Set<String> completionScenarioIds;
  final bool catalogAvailable;
  final List<CultureStoryArcProjection> storyArcs;

  int get discoveredCount => entries.length;
  bool get isEmpty => entries.isEmpty;
}

/// Read-only projection of culture discovery from existing learning evidence.
///
/// No discovered-term list or story-arc progress is persisted. Culture discovery
/// is derived from the existing current-generation scenario-completion owner.
/// That completion list is cloud-backed together with its corpus generation;
/// course-mastery checkpoints remain supplementary evidence only. The resulting
/// scenario IDs are then intersected with the live scenario-culture registry.
///
/// Story arcs are optional grouping metadata only. An arc is projected only when
/// every referenced scenario and cultural term already exists in the live
/// scenario-culture registry/glossary, so review-only authoring data cannot leak
/// into learner UI before promotion.
///
/// Course checkpoints are bounded attempt history and can still evict older
/// scenario IDs, but they no longer carry the cross-device durability burden:
/// CloudSync backs up Storage.completedScenarios with the matching scenario
/// corpus generation and restores it by union only when generations match.
/// This projection remains presentation-only and must never be interpreted as
/// mastery or reward authority.
class CultureDiscoveryService {
  CultureDiscoveryService({
    CultureCompletedScenarioIdsLoader? completionScenarioIdsLoader,
    CultureLinkCatalogLoader? linkCatalogLoader,
    CultureGlossaryLoader? glossaryLoader,
    CultureStoryArcCatalogLoader? storyArcCatalogLoader,
  }) : _completionScenarioIdsLoader =
           completionScenarioIdsLoader ?? _loadCurrentCompletionEvidence,
       _linkCatalogLoader =
           linkCatalogLoader ?? ScenarioCultureLinkRepository.load,
       _glossaryLoader = glossaryLoader ?? CulturalGlossaryRepository.load,
       _storyArcCatalogLoader =
           storyArcCatalogLoader ?? CultureStoryArcRepository.load;

  final CultureCompletedScenarioIdsLoader _completionScenarioIdsLoader;
  final CultureLinkCatalogLoader _linkCatalogLoader;
  final CultureGlossaryLoader _glossaryLoader;
  final CultureStoryArcCatalogLoader _storyArcCatalogLoader;

  static Future<Set<String>> _loadCurrentCompletionEvidence() async {
    final completed = Storage.completedScenarios.toSet();
    try {
      final snapshot = await CourseProgressService.shared.readForDisplay();
      if (snapshot != null) {
        completed.addAll(
          snapshot.scenarioCheckpoints.map((entry) => entry.scenarioId),
        );
      }
    } on Object {
      // Local completion remains valid. Culture discovery is supplementary
      // UI and must never turn a course-read failure into a Hanok failure.
    }
    return completed;
  }

  Future<CultureDiscoverySnapshot> load() async {
    final completed = await _completionScenarioIdsLoader();
    final links = await _linkCatalogLoader();
    final glossary = await _glossaryLoader();
    if (links == null || glossary == null) {
      return CultureDiscoverySnapshot(
        entries: const [],
        availableTermCount: 0,
        completionScenarioIds: completed,
        catalogAvailable: false,
      );
    }

    CultureStoryArcCatalog? storyArcs;
    try {
      storyArcs = await _storyArcCatalogLoader();
    } on Object {
      storyArcs = null;
    }

    return project(
      completedScenarioIds: completed,
      links: links,
      glossary: glossary,
      storyArcs: storyArcs,
    );
  }

  static CultureDiscoverySnapshot project({
    required Set<String> completedScenarioIds,
    required ScenarioCultureLinkCatalog links,
    required CulturalGlossary glossary,
    CultureStoryArcCatalog? storyArcs,
  }) {
    final availableTermIds = <String>{};
    final discoveredTermIds = <String>{};

    for (final link in links.links) {
      for (final termId in link.termIds) {
        if (glossary.entry(termId) == null) {
          continue;
        }
        availableTermIds.add(termId);
        if (completedScenarioIds.contains(link.scenarioId)) {
          discoveredTermIds.add(termId);
        }
      }
    }

    // Preserve glossary order for a stable collection even when several
    // scenarios discover the same term in a different order.
    final entries = [
      for (final entry in glossary.entries)
        if (discoveredTermIds.contains(entry.termId)) entry,
    ];

    final projectedArcs = <CultureStoryArcProjection>[];
    for (final arc in storyArcs?.arcs ?? const <CultureStoryArc>[]) {
      var validForLiveCatalog = true;
      for (final step in arc.steps) {
        final liveLink = links.linkForScenario(step.scenarioId);
        if (liveLink == null ||
            step.termIds.any(
              (termId) =>
                  glossary.entry(termId) == null ||
                  !liveLink.termIds.contains(termId),
            )) {
          validForLiveCatalog = false;
          break;
        }
      }
      if (!validForLiveCatalog) {
        continue;
      }

      projectedArcs.add(
        CultureStoryArcProjection(
          arc: arc,
          completedStepCount: arc.steps
              .where((step) => completedScenarioIds.contains(step.scenarioId))
              .length,
        ),
      );
    }

    return CultureDiscoverySnapshot(
      entries: entries,
      availableTermCount: availableTermIds.length,
      completionScenarioIds: completedScenarioIds,
      catalogAvailable: true,
      storyArcs: projectedArcs,
    );
  }
}
