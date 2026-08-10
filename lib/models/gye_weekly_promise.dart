/// Server-recognised, beginner-safe weekly Gye promises.
///
/// The wire ids are intentionally small and stable: the Cloud Function uses
/// the same ids to decide which course checkpoint can light a shared lantern.
/// A client must never invent an arbitrary scenario or target for a group.
class GyeWeeklyPromiseDefinition {
  const GyeWeeklyPromiseDefinition({
    required this.id,
    required this.courseUnitId,
    required this.scenarioId,
    required this.target,
  });

  final String id;
  final String courseUnitId;
  final String scenarioId;
  final int target;
}

abstract final class GyeWeeklyPromises {
  static const String cafeOrder = 'cafe_order';
  static const String directions = 'directions';
  static const String selfIntroduction = 'self_introduction';

  static const GyeWeeklyPromiseDefinition cafeOrderDefinition =
      GyeWeeklyPromiseDefinition(
        id: cafeOrder,
        courseUnitId: 'a1_04_order_request_object',
        scenarioId: 'bunshik_tteokbokki',
        target: 3,
      );

  static const GyeWeeklyPromiseDefinition directionsDefinition =
      GyeWeeklyPromiseDefinition(
        id: directions,
        courseUnitId: 'a1_06_transport_directions',
        scenarioId: 'taxi_kakao',
        target: 3,
      );

  static const GyeWeeklyPromiseDefinition selfIntroductionDefinition =
      GyeWeeklyPromiseDefinition(
        id: selfIntroduction,
        courseUnitId: 'a1_02_self_intro_identity',
        scenarioId: 'introduce_yourself',
        target: 3,
      );

  static const List<GyeWeeklyPromiseDefinition> all = [
    cafeOrderDefinition,
    directionsDefinition,
    selfIntroductionDefinition,
  ];

  static const String defaultId = cafeOrder;

  static GyeWeeklyPromiseDefinition? byId(String id) {
    for (final definition in all) {
      if (definition.id == id) return definition;
    }
    return null;
  }

  /// A scenario can request a cloud projection only when it is one of the
  /// fixed life promises. The Cloud Function still performs the authoritative
  /// structural eligibility check before it changes a shared aggregate.
  static GyeWeeklyPromiseDefinition? byScenarioId(String scenarioId) {
    for (final definition in all) {
      if (definition.scenarioId == scenarioId) return definition;
    }
    return null;
  }
}
