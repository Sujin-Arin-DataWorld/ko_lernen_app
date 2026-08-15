import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/services/course_mastery_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    CurriculumCatalog.reset();
    Storage.resetForTesting();
    Storage.resetCourseMasteryForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  tearDown(CurriculumCatalog.reset);

  test(
    'declared grammar and smalltalk checkpoints advance every C1/C2 mission',
    () async {
      final catalog = await CurriculumCatalog.load();
      final service = CourseMasteryService(catalog);
      await service.initializeForPlacement('c1');

      final c1Smalltalk = await _recordDeclaredCheckpoint(
        service,
        isCorrect: true,
        occurredAt: DateTime.utc(2026, 8, 16, 12),
      );
      expect(
        c1Smalltalk.newlyUnlockedUnit?.id,
        'c1_02_inclusive_sustainable_systems',
      );

      final c1Grammar = await _recordDeclaredCheckpoint(
        service,
        isCorrect: true,
        occurredAt: DateTime.utc(2026, 8, 16, 12, 1),
      );
      expect(
        c1Grammar.newlyUnlockedUnit?.id,
        'c2_01_interpretation_institutions',
      );

      final c2Smalltalk = await _recordDeclaredCheckpoint(
        service,
        isCorrect: true,
        occurredAt: DateTime.utc(2026, 8, 16, 12, 2),
      );
      expect(
        c2Smalltalk.newlyUnlockedUnit?.id,
        'c2_02_technology_public_ethics',
      );

      final c2Grammar = await _recordDeclaredCheckpoint(
        service,
        isCorrect: true,
        occurredAt: DateTime.utc(2026, 8, 16, 12, 3),
      );
      expect(c2Grammar.newlyUnlockedUnit, isNull);
      expect(c2Grammar.currentUnit, isNull);
      expect(
        c2Grammar.snapshot.completedUnitIds,
        containsAll(const <String>[
          'c1_01_evidence_public_reasoning',
          'c1_02_inclusive_sustainable_systems',
          'c2_01_interpretation_institutions',
          'c2_02_technology_public_ethics',
        ]),
      );
    },
  );

  test(
    'an incorrect advanced answer checkpoint keeps its mission locked',
    () async {
      final catalog = await CurriculumCatalog.load();
      final service = CourseMasteryService(catalog);
      await service.initializeForPlacement('c1');

      final update = await _recordDeclaredCheckpoint(
        service,
        isCorrect: false,
        occurredAt: DateTime.utc(2026, 8, 16, 13),
      );

      expect(update.newlyUnlockedUnit, isNull);
      expect(update.currentUnit?.id, 'c1_01_evidence_public_reasoning');
      expect(
        update.snapshot.completedUnitIds,
        isNot(contains('c1_01_evidence_public_reasoning')),
      );
    },
  );
}

Future<CourseUpdate> _recordDeclaredCheckpoint(
  CourseMasteryService service, {
  required bool isCorrect,
  required DateTime occurredAt,
}) {
  final unit = service.currentUnit;
  if (unit == null || unit.checkpointContentIds.length != 1) {
    throw StateError('Expected one active declared checkpoint.');
  }
  final pieces = unit.checkpointContentIds.single.split(':');
  final kind = pieces.length == 2
      ? CurriculumContentKindX.tryFromCode(pieces.first)
      : null;
  if (kind == null || pieces.last.trim().isEmpty) {
    throw StateError('Invalid declared checkpoint content key.');
  }
  final contentId = pieces.last.trim();
  final links = service.catalog
      .linksForContent(kind, contentId)
      .where(
        (link) =>
            link.courseUnitId == unit.id &&
            link.contentKey == unit.checkpointContentIds.single &&
            link.exactlyAssesses(unit),
      )
      .toList(growable: false);
  if (links.length != 1 || links.single.conceptIds.length != 1) {
    throw StateError('Expected one exact single-concept checkpoint link.');
  }
  final link = links.single;
  return service.recordContentAttempt(
    kind,
    contentId,
    isCorrect,
    courseContext: CoursePracticeContext.fromLink(link),
    conceptId: link.conceptIds.single,
    occurredAt: occurredAt,
  );
}
