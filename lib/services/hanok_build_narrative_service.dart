import '../models/course_mastery.dart';
import '../models/hanok_build_narrative.dart';
import '../models/personal_hanok.dart';
import 'course_mastery_service.dart';
import 'curriculum_catalog.dart';

typedef HanokNarrativeCatalogLoader = Future<CurriculumCatalog> Function();
typedef HanokNarrativeSnapshotReader =
    CourseMasterySnapshot? Function(CurriculumCatalog catalog);

/// Reads established course state for Hanok copy without writing or migrating
/// it. The visual projection remains the caller's existing legacy projection.
class HanokBuildNarrativeService {
  const HanokBuildNarrativeService._();

  static Future<HanokBuildNarrative> loadForProjection(
    PersonalHanokProjection projection, {
    HanokNarrativeCatalogLoader? catalogLoader,
    HanokNarrativeSnapshotReader? snapshotReader,
  }) async {
    try {
      final catalog = await (catalogLoader ?? CurriculumCatalog.load)();
      final snapshot =
          (snapshotReader ?? _readStoredSnapshot)(catalog) ??
          const CourseMasterySnapshot.empty();
      return HanokBuildNarrative.fromSnapshot(
        projection: projection,
        snapshot: snapshot,
        courseUnits: catalog.courseUnits,
      );
    } catch (_) {
      // A Hanok explanation must never block the existing map when a local
      // course snapshot or catalog cannot be read. It also must not recover by
      // writing a replacement snapshot.
      return HanokBuildNarrative.empty(projection);
    }
  }

  static CourseMasterySnapshot? _readStoredSnapshot(
    CurriculumCatalog catalog,
  ) => CourseMasteryService(catalog).readForReconciliation();
}
