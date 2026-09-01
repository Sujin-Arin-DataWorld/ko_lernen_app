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

  test('declared scenario checkpoints advance every C1/C2 mission', () async {
    final catalog = await CurriculumCatalog.load();
    final service = CourseMasteryService(catalog);
    await service.initializeForPlacement('c1');

    // C1/C2 유닛은 고정 4개가 아니다 (2026-08-18 Batch 12 로 12개). 단계를
    // 이름으로 박아 두면 유닛이 늘 때마다 이 센서가 의미 없이 깨진다 —
    // 카탈로그가 세운 순서를 그대로 걸어가며 "선언된 체크포인트가 다음 미션을
    // 연다"는 계약만 지킨다. 그게 이 테스트 제목이 말하는 every 다.
    // 적재 순서가 아니라 (레벨, order) 가 진행 순서다 — 신규 유닛은 뒤에
    // 붙어 들어오므로 courseUnits 의 나열 순서와 어긋난다.
    final advancedUnits =
        catalog.courseUnits
            .where((unit) => const {'c1', 'c2'}.contains(unit.level))
            .toList()
          ..sort((a, b) {
            final byLevel = a.level.compareTo(b.level);
            return byLevel != 0 ? byLevel : a.order.compareTo(b.order);
          });
    expect(advancedUnits, isNotEmpty);
    expect(service.currentUnit?.id, advancedUnits.first.id);

    final walked = <String>[];
    for (var i = 0; i < advancedUnits.length; i++) {
      final update = await _recordDeclaredCheckpoint(
        service,
        isCorrect: true,
        occurredAt: DateTime.utc(2026, 8, 16, 12, i),
      );
      walked.add(advancedUnits[i].id);
      final isLast = i == advancedUnits.length - 1;
      expect(
        update.newlyUnlockedUnit?.id,
        isLast ? isNull : advancedUnits[i + 1].id,
        reason: '${advancedUnits[i].id} 다음 미션',
      );
    }

    expect(service.currentUnit, isNull);
    expect(service.snapshot.completedUnitIds, containsAll(walked));
  });

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
}) async {
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
  if (links.length != 1 || links.single.conceptIds.isEmpty) {
    throw StateError('Expected one exact concept-bearing checkpoint link.');
  }
  final link = links.single;
  final context = CoursePracticeContext.fromLink(link);
  CourseUpdate? update;
  for (final conceptId in link.conceptIds) {
    update = await service.recordContentAttempt(
      kind,
      contentId,
      isCorrect,
      courseContext: context,
      conceptId: conceptId,
      occurredAt: occurredAt,
    );
  }
  if (kind == CurriculumContentKind.scenario) {
    return service.recordScenarioCheckpoint(
      contentId,
      isCorrect ? 1 : 0,
      courseContext: context,
      occurredAt: occurredAt,
    );
  }
  return update!;
}
