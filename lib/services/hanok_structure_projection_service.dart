import '../models/course_mastery.dart';
import '../models/hanok_competence.dart';
import '../models/personal_hanok.dart';
import 'course_mastery_service.dart';
import 'curriculum_catalog.dart';
import 'hanok_stage_service.dart';

typedef HanokStructureCatalogLoader = Future<CurriculumCatalog> Function();
typedef HanokStructureSnapshotReader =
    CourseMasterySnapshot? Function(CurriculumCatalog catalog);

/// Builds the non-writing, non-regressing personal Hanok projection.
///
/// The legacy pack stage is always retained. When the current validated course
/// snapshot is readable, its independent unit completion can raise the visible
/// structure, but never lower an existing learner's Hanok or alter rewards.
class HanokStructureProjectionService {
  const HanokStructureProjectionService._();

  static Future<PersonalHanokProjection> loadForRatios(
    LevelRatios legacyRatios, {
    HanokStructureCatalogLoader? catalogLoader,
    HanokStructureSnapshotReader? snapshotReader,
  }) async {
    try {
      final catalog = await (catalogLoader ?? CurriculumCatalog.load)();
      final snapshot =
          (snapshotReader ?? _readStoredSnapshot)(catalog) ??
          const CourseMasterySnapshot.empty();
      final competence = HanokCompetenceProjection.fromSnapshot(
        snapshot: snapshot,
        courseUnits: catalog.courseUnits,
      );
      return PersonalHanokProjection.from(legacyRatios, competence: competence);
    } catch (_) {
      // A broken/missing local course snapshot must never hide a legacy home,
      // map, room, reward, or route. The legacy projection remains complete.
      return PersonalHanokProjection.from(legacyRatios);
    }
  }

  static Future<PersonalHanokProjection> loadCurrent() async {
    try {
      return await loadForRatios(await HanokStageService.levelRatios());
    } catch (_) {
      // Keep the personal-Hanok entry point available even when the legacy
      // pack store itself is temporarily unreadable.
      return PersonalHanokProjection.from(
        const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
      );
    }
  }

  static CourseMasterySnapshot? _readStoredSnapshot(
    CurriculumCatalog catalog,
  ) => CourseMasteryService(catalog).readForReconciliation();
}
