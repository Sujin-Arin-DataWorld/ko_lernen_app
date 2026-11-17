import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/services/course_mastery_service.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

Future<void> _seed(Map<String, Object> preferences) async {
  Storage.resetForTesting();
  Storage.resetCourseMasteryForTesting();
  SharedPreferences.setMockInitialValues(preferences);
  await Storage.init();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CurriculumCatalog catalog;
  setUpAll(() async => catalog = await CurriculumCatalog.load());
  setUp(() => _seed({}));

  test(
    'refresh from completely fresh preferences has no course placement',
    () async {
      final service = CourseMasteryService(catalog);
      final snapshot = await service.refresh();

      expect(snapshot.placementLevel, isNull);
      expect(snapshot.currentCourseUnitId, isNull);
      expect(Storage.dedicatedCoursePlacementLevelCode, isNull);
      expect(
        jsonDecode(Storage.courseMasterySnapshotRawJson),
        isNot(contains('placementLevel')),
      );
    },
  );

  for (final genericLevel in ['a1', 'a2']) {
    test(
      'refresh does not promote generic $genericLevel library choice into a course',
      () async {
        await Storage.setUserLevelCode(genericLevel);
        await Storage.setBrowseLevelCode('b1');
        final service = CourseMasteryService(catalog);
        final snapshot = await service.refresh();

        expect(snapshot.placementLevel, isNull);
        expect(snapshot.currentCourseUnitId, isNull);
        expect(Storage.dedicatedCoursePlacementLevelCode, isNull);
        expect(Storage.userLevelCode, genericLevel);
        expect(Storage.browseLevelCode, 'b1');
        expect(
          jsonDecode(Storage.courseMasterySnapshotRawJson),
          isNot(contains('placementLevel')),
        );
        final cloud = await service.migrateForCloudCapture();
        expect(cloud?.placementLevel, isNull);
        expect(cloud?.completedUnitIds, isEmpty);
      },
    );
  }

  test(
    'refresh after local reset does not recreate placement from the new library choice',
    () async {
      final progress = CourseProgressService(
        () async => CourseMasteryService(catalog),
      );
      await progress.initializeForPlacement('a1');
      await progress.runLocalStorageWipeBarrier(Storage.resetAll);
      expect(Storage.courseMasterySnapshotRawJson, isEmpty);
      expect(Storage.dedicatedCoursePlacementLevelCode, isNull);
      await Storage.setUserLevelCode('a2');
      await Storage.setBrowseLevelCode('a2');

      final snapshot = await progress.refresh();
      expect(snapshot.placementLevel, isNull);
      expect(snapshot.currentCourseUnitId, isNull);
      expect(Storage.dedicatedCoursePlacementLevelCode, isNull);
      expect(Storage.userLevelCode, 'a2');
      expect(Storage.browseLevelCode, 'a2');
      expect(
        jsonDecode(Storage.courseMasterySnapshotRawJson),
        isNot(contains('placementLevel')),
      );
    },
  );

  test(
    'refresh still restores explicit dedicated placement and current unit',
    () async {
      final firstUnit = catalog.courseUnits.firstWhere(
        (unit) => unit.level == 'a1' && unit.prerequisiteUnitIds.isEmpty,
      );
      await _seed({
        Storage.placementLevelPreferenceKey: 'a1',
        Storage.courseUnitPreferenceKey: firstUnit.id,
        'kl_user_level': 'b2',
      });

      final snapshot = await CourseMasteryService(catalog).refresh();
      expect(snapshot.placementLevel, 'a1');
      expect(snapshot.currentCourseUnitId, firstUnit.id);
      expect(Storage.dedicatedCoursePlacementLevelCode, 'a1');
      expect(Storage.courseUnitId, firstUnit.id);
    },
  );

  test(
    'refresh leaves an existing explicit canonical placement unchanged',
    () async {
      final original = await CourseMasteryService(
        catalog,
      ).initializeForPlacement('a2');
      final originalBytes = Storage.courseMasterySnapshotRawJson;
      await Storage.setUserLevelCode('c1');
      await Storage.setBrowseLevelCode('b2');

      final snapshot = await CourseMasteryService(catalog).refresh();
      expect(snapshot.toJson(), original.toJson());
      expect(Storage.courseMasterySnapshotRawJson, originalBytes);
      expect(Storage.dedicatedCoursePlacementLevelCode, 'a2');
      expect(Storage.userLevelCode, 'c1');
      expect(Storage.browseLevelCode, 'b2');
    },
  );

  test(
    'refresh preserves retained legacy placement and actual attempt evidence',
    () async {
      final originalService = CourseMasteryService(catalog);
      final initial = await originalService.initializeForPlacement('a1');
      final link = catalog
          .linksForCourseUnit(initial.currentCourseUnitId!)
          .firstWhere(
            (link) => link.contentKind == CurriculumContentKind.vocab,
          );
      final update = await originalService.recordContentAttempt(
        link.contentKind,
        link.contentId,
        false,
        courseContext: CoursePracticeContext.fromLink(link),
        score: .2,
        occurredAt: DateTime.utc(2026, 10, 1),
      );
      expect(update.snapshot.evidence, isNotEmpty);
      final legacyJson = {...update.snapshot.toJson(), 'version': 1};
      final legacyBytes = jsonEncode(legacyJson);
      await _seed({Storage.legacyCourseMasteryPreferenceKey: legacyBytes});

      final restored = await CourseMasteryService(catalog).refresh();
      expect(restored.placementLevel, initial.placementLevel);
      expect(restored.currentCourseUnitId, initial.currentCourseUnitId);
      expect(
        restored.evidence.map((e) => e.toJson()).toList(),
        update.snapshot.evidence.map((e) => e.toJson()).toList(),
      );
      expect(Storage.legacyCourseMasteryRawJson, legacyBytes);
      expect(Storage.dedicatedCoursePlacementLevelCode, 'a1');
    },
  );
}
