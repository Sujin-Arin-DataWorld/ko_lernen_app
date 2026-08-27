import '../../data/chaekgado_shelf.dart';
import '../../models/guide_contract.dart';
import '../../models/scenario.dart';
import '../../services/scenario_loader.dart';
import '../scenarios/scenario_browse_query.dart';

typedef GuideScenarioLevelLoader =
    Future<List<Scenario>> Function(LearnerLevel level);

/// One stocked scenario shelf that the Learn guide may expose.
///
/// The shelf remains a typed destination rather than a route string. Counts
/// are calculated from the loaded scenario shard and never stored in copy.
final class GuideScenarioCategoryStock {
  const GuideScenarioCategoryStock({
    required this.imageKey,
    required this.destination,
    required this.scenarioCount,
  });

  final String imageKey;
  final ScenarioBrowseDestination destination;
  final int scenarioCount;
}

/// Resolves the library-only level used by passive guide browsing.
///
/// This mirrors the browse-level display contract in Settings: an explicit
/// browse level wins, then the legacy learner level, then A1. It never reads or
/// changes course mastery.
LearnerLevel resolveGuideScenarioBrowseLevel({
  required String? browseLevelCode,
  required String? userLevelCode,
}) =>
    LearnerLevel.fromCode(browseLevelCode) ??
    LearnerLevel.fromCode(userLevelCode) ??
    LearnerLevel.a1;

/// Projects canonical Chaekgado slots against actual scenario stock.
///
/// Slot order and authority come from [kChaekgadoSlots]. Exact level+shelf
/// filtering is delegated to [ScenarioBrowseQuery], so unknown shelves,
/// mismatched levels, and zero-stock slots fail closed instead of producing a
/// guessed guide action.
abstract final class GuideScenarioCategoryStockLoader {
  static Future<List<GuideScenarioCategoryStock>> loadLevel(
    LearnerLevel level, {
    GuideScenarioLevelLoader? loadScenarios,
  }) async {
    final usesBundledLoader = loadScenarios == null;
    final corpus = await (loadScenarios ?? ScenarioLoader.loadLevel)(level);
    if (usesBundledLoader &&
        corpus.isEmpty &&
        ScenarioLoader.lastError != null) {
      throw StateError(ScenarioLoader.lastError!);
    }
    return project(level: level, corpus: corpus);
  }

  static List<GuideScenarioCategoryStock> project({
    required LearnerLevel level,
    required Iterable<Scenario> corpus,
  }) {
    final scenarios = List<Scenario>.unmodifiable(corpus);
    final slots = kChaekgadoSlots[level] ?? const <ChaekgadoSlot>[];
    final stocked = <GuideScenarioCategoryStock>[];

    for (final slot in slots) {
      final destination = ScenarioBrowseDestination(
        level: level,
        shelfId: chaekgadoShelfId(level, slot.slug),
      );
      final result = ScenarioBrowseQuery.resolve(
        destination: destination,
        corpus: scenarios,
      );
      if (result.status != ScenarioBrowseQueryStatus.ready) {
        continue;
      }
      stocked.add(
        GuideScenarioCategoryStock(
          imageKey: slot.imageKey,
          destination: destination,
          scenarioCount: result.scenarios.length,
        ),
      );
    }

    return List.unmodifiable(stocked);
  }
}
