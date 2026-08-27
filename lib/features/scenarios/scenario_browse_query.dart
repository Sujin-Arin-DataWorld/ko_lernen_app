import '../../data/chaekgado_shelf.dart';
import '../../models/guide_contract.dart';
import '../../models/scenario.dart';

/// Outcome of resolving one exact guide destination against scenario stock.
enum ScenarioBrowseQueryStatus { ready, unknownShelf, unstocked }

/// Immutable, route-independent result for a scenario browse destination.
final class ScenarioBrowseQueryResult {
  ScenarioBrowseQueryResult._({
    required this.status,
    required this.destination,
    required Iterable<Scenario> scenarios,
  }) : scenarios = List.unmodifiable(scenarios);

  final ScenarioBrowseQueryStatus status;
  final ScenarioBrowseDestination destination;
  final List<Scenario> scenarios;

  String get shelfId => destination.shelfId;
}

/// Resolves the W4 `level + shelf` contract without navigation or fallback.
///
/// Shelf authority comes from [kChaekgadoSlots]. A corpus entry is returned
/// only when both its declared level and its full `{level}_{slug}` shelf ID
/// exactly match the destination. Iteration order is retained.
abstract final class ScenarioBrowseQuery {
  static ScenarioBrowseQueryResult resolve({
    required ScenarioBrowseDestination destination,
    required Iterable<Scenario> corpus,
  }) {
    if (!_isKnownShelf(destination)) {
      return ScenarioBrowseQueryResult._(
        status: ScenarioBrowseQueryStatus.unknownShelf,
        destination: destination,
        scenarios: const [],
      );
    }

    final matching = <Scenario>[
      for (final scenario in corpus)
        if (scenario.level == destination.level &&
            scenario.shelf == destination.shelfId)
          scenario,
    ];

    return ScenarioBrowseQueryResult._(
      status: matching.isEmpty
          ? ScenarioBrowseQueryStatus.unstocked
          : ScenarioBrowseQueryStatus.ready,
      destination: destination,
      scenarios: matching,
    );
  }

  static bool _isKnownShelf(ScenarioBrowseDestination destination) {
    final slots = kChaekgadoSlots[destination.level];
    if (slots == null) {
      return false;
    }
    return slots.any(
      (slot) =>
          chaekgadoShelfId(destination.level, slot.slug) == destination.shelfId,
    );
  }
}
