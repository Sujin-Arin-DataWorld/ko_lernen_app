import '../models/course_mastery.dart';
import '../models/curriculum.dart';
import '../models/hanok_build_narrative.dart';
import '../models/personal_hanok.dart';
import '../models/scenario.dart';
import 'course_mastery_service.dart';
import 'curriculum_catalog.dart';
import 'scenario_loader.dart';

typedef HanokNarrativeCatalogLoader = Future<CurriculumCatalog> Function();
typedef HanokNarrativeSnapshotReader =
    CourseMasterySnapshot? Function(CurriculumCatalog catalog);
typedef HanokNarrativeScenarioLoader = Future<List<Scenario>> Function();

/// Reads established course state for Hanok copy without writing or migrating
/// it. The visual projection remains the caller's existing legacy projection.
class HanokBuildNarrativeService {
  const HanokBuildNarrativeService._();

  static Future<HanokBuildNarrative> loadForProjection(
    PersonalHanokProjection projection, {
    HanokNarrativeCatalogLoader? catalogLoader,
    HanokNarrativeSnapshotReader? snapshotReader,
    HanokNarrativeScenarioLoader? scenarioLoader,
  }) async {
    try {
      final catalog = await (catalogLoader ?? CurriculumCatalog.load)();
      final scenarios = await (scenarioLoader ?? ScenarioLoader.load)();
      final snapshot =
          (snapshotReader ?? _readStoredSnapshot)(catalog) ??
          const CourseMasterySnapshot.empty();
      return HanokBuildNarrative.fromSnapshot(
        projection: projection,
        snapshot: snapshot,
        courseUnits: catalog.courseUnits,
        contentLinks: catalog.contentLinks,
        scenarios: scenarios,
      );
    } catch (_) {
      // A Hanok explanation must never block the existing map when a local
      // course snapshot or catalog cannot be read. It also must not recover by
      // writing a replacement snapshot.
      return HanokBuildNarrative.empty(projection);
    }
  }

  /// Loads the same proof without requiring a visual Hanok projection. The
  /// Sarangbang uses this read-only seam, and previews can inject it directly.
  static Future<HanokLearningReceipt> loadReceipt({
    HanokNarrativeCatalogLoader? catalogLoader,
    HanokNarrativeSnapshotReader? snapshotReader,
    HanokNarrativeScenarioLoader? scenarioLoader,
  }) async {
    try {
      final catalog = await (catalogLoader ?? CurriculumCatalog.load)();
      final scenarios = await (scenarioLoader ?? ScenarioLoader.load)();
      final snapshot =
          (snapshotReader ?? _readStoredSnapshot)(catalog) ??
          const CourseMasterySnapshot.empty();
      final units = catalog.courseUnits;
      final completedIds = snapshot.completedUnitIds.toSet();
      final bypassedIds = snapshot.bypassedPrerequisiteUnitIds.toSet();
      final currentId = snapshot.currentCourseUnitId;
      final nextUnit =
          currentId == null ||
              completedIds.contains(currentId) ||
              bypassedIds.contains(currentId)
          ? null
          : units.cast<CourseUnit?>().firstWhere(
              (unit) => unit?.id == currentId,
              orElse: () => null,
            );
      return HanokLearningReceipt.fromSnapshot(
        snapshot: snapshot,
        courseUnits: units,
        contentLinks: catalog.contentLinks,
        scenarios: scenarios,
        nextUnit: nextUnit,
      );
    } catch (_) {
      return const HanokLearningReceipt.empty();
    }
  }

  static CourseMasterySnapshot? _readStoredSnapshot(
    CurriculumCatalog catalog,
  ) => CourseMasteryService(catalog).readForReconciliation();
}
