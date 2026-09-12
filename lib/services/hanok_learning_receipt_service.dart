import '../models/course_mastery.dart';
import '../models/curriculum.dart';
import '../models/hanok_learning_receipt.dart';
import '../models/scenario.dart';
import 'course_mastery_service.dart';
import 'curriculum_catalog.dart';
import 'scenario_loader.dart';

typedef HanokReceiptCatalogLoader = Future<CurriculumCatalog> Function();
typedef HanokReceiptSnapshotReader =
    CourseMasterySnapshot? Function(CurriculumCatalog catalog);
typedef HanokReceiptScenarioLoader = Future<List<Scenario>> Function();

/// Reads established course evidence for the Sarangbang without writing or
/// migrating it.
class HanokLearningReceiptService {
  const HanokLearningReceiptService._();

  static Future<HanokLearningReceipt> loadReceipt({
    HanokReceiptCatalogLoader? catalogLoader,
    HanokReceiptSnapshotReader? snapshotReader,
    HanokReceiptScenarioLoader? scenarioLoader,
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
