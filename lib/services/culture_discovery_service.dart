import '../models/cultural_glossary.dart';
import '../models/scenario_culture_link.dart';
import 'course_progress_service.dart';
import 'cultural_glossary_repository.dart';
import 'scenario_culture_link_repository.dart';
import 'storage_service.dart';

typedef CultureCompletedScenarioIdsLoader = Future<Set<String>> Function();
typedef CultureLinkCatalogLoader =
    Future<ScenarioCultureLinkCatalog?> Function();
typedef CultureGlossaryLoader = Future<CulturalGlossary?> Function();

class CultureDiscoverySnapshot {
  CultureDiscoverySnapshot({
    required List<CulturalGlossaryEntry> entries,
    required this.availableTermCount,
    required Set<String> completionScenarioIds,
    required this.catalogAvailable,
  }) : entries = List.unmodifiable(entries),
       completionScenarioIds = Set.unmodifiable(completionScenarioIds);

  final List<CulturalGlossaryEntry> entries;
  final int availableTermCount;
  final Set<String> completionScenarioIds;
  final bool catalogAvailable;

  int get discoveredCount => entries.length;
  bool get isEmpty => entries.isEmpty;
}

/// Read-only projection of culture discovery from existing learning evidence.
///
/// No discovered-term list is persisted. Current-generation scenario
/// completion is reconstructed from the local completion mirror plus
/// course-mastery checkpoints (the cloud-restorable source), then intersected
/// with the live scenario-culture registry.
///
/// Course checkpoints are bounded attempt history, not a permanent set of
/// unique completed scenario IDs. They improve account-restore coverage, but a
/// long replay history can evict an older scenario even while today's catalog
/// contains fewer than the 300 retained checkpoints. The local completion
/// mirror therefore remains the strongest on-device source; this projection is
/// deliberately supplementary and must not be presented as permanent mastery
/// or as a complete cross-device archive.
class CultureDiscoveryService {
  CultureDiscoveryService({
    CultureCompletedScenarioIdsLoader? completionScenarioIdsLoader,
    CultureLinkCatalogLoader? linkCatalogLoader,
    CultureGlossaryLoader? glossaryLoader,
  }) : _completionScenarioIdsLoader =
           completionScenarioIdsLoader ?? _loadCurrentCompletionEvidence,
       _linkCatalogLoader =
           linkCatalogLoader ?? ScenarioCultureLinkRepository.load,
       _glossaryLoader = glossaryLoader ?? CulturalGlossaryRepository.load;

  final CultureCompletedScenarioIdsLoader _completionScenarioIdsLoader;
  final CultureLinkCatalogLoader _linkCatalogLoader;
  final CultureGlossaryLoader _glossaryLoader;

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
    return project(
      completedScenarioIds: completed,
      links: links,
      glossary: glossary,
    );
  }

  static CultureDiscoverySnapshot project({
    required Set<String> completedScenarioIds,
    required ScenarioCultureLinkCatalog links,
    required CulturalGlossary glossary,
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

    return CultureDiscoverySnapshot(
      entries: entries,
      availableTermCount: availableTermIds.length,
      completionScenarioIds: completedScenarioIds,
      catalogAvailable: true,
    );
  }
}
