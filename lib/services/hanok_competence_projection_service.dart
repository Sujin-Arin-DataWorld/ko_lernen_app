import '../models/course_mastery.dart';
import '../models/hanok_competence.dart';
import 'course_mastery_service.dart';
import 'curriculum_catalog.dart';

typedef HanokCompetenceCatalogLoader = Future<CurriculumCatalog> Function();
typedef HanokCompetenceSnapshotReader =
    CourseMasterySnapshot? Function(CurriculumCatalog catalog);

/// Reads the Hanok progress indicator from durable course competence only.
///
/// Pack completion and placement bypasses are deliberately outside this
/// projection, so neither can reveal an unearned construction stage.
abstract final class HanokCompetenceProjectionService {
  static Future<HanokCompetenceProjection> loadCurrent({
    HanokCompetenceCatalogLoader? catalogLoader,
    HanokCompetenceSnapshotReader? snapshotReader,
  }) async {
    try {
      final catalog = await (catalogLoader ?? CurriculumCatalog.load)();
      final snapshot =
          (snapshotReader ?? _readStoredSnapshot)(catalog) ??
          const CourseMasterySnapshot.empty();
      return HanokCompetenceProjection.fromSnapshot(
        snapshot: snapshot,
        courseUnits: catalog.courseUnits,
      );
    } catch (_) {
      return const HanokCompetenceProjection.empty();
    }
  }

  static CourseMasterySnapshot? _readStoredSnapshot(
    CurriculumCatalog catalog,
  ) => CourseMasteryService(catalog).readForReconciliation();
}
