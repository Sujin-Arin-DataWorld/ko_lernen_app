import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/hanok_stage.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/hanok_structure_projection_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'projects an estate gate from catalog-validated completed units',
    () async {
      final catalog = await CurriculumCatalog.load();
      expect(catalog.courseUnits, isNotEmpty);
      final projection = await HanokStructureProjectionService.loadForRatios(
        const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
        catalogLoader: () async => catalog,
        snapshotReader: (catalog) {
          final a1 = catalog.courseUnits
              .where((unit) => unit.level == 'a1')
              .map((unit) => unit.id);
          final a2 = catalog.courseUnits
              .where((unit) => unit.level == 'a2')
              .map((unit) => unit.id);
          final b1 = catalog.courseUnits
              .where((unit) => unit.level == 'b1')
              .take(2)
              .map((unit) => unit.id);
          return CourseMasterySnapshot(completedUnitIds: [...a1, ...a2, ...b1]);
        },
      );

      expect(projection.legacyStage, HanokStage.empty);
      expect(projection.competenceStage, HanokStage.gate);
      expect(projection.structureStage, HanokStage.gate);
      expect(projection.usesCompoundMap, isTrue);
    },
  );

  test(
    'keeps the full legacy projection if course evidence cannot load',
    () async {
      final projection = await HanokStructureProjectionService.loadForRatios(
        const LevelRatios(a1: 1, a2: .5, b1: 0, b2: 0),
        catalogLoader: () async => throw StateError('catalog unavailable'),
      );

      expect(projection.competence, isNull);
      expect(projection.structureStage, projection.legacyStage);
      expect(projection.structureStage, HanokStage.tileRoofPartial);
    },
  );
}
