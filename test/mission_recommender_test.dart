import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';

/// 추천 엔진 단위 테스트 (계획 §6.1·§10.1 — 2026-08-04 감사 #5).
/// 우선순위·R-REC 가드·폴백 체인·미리보기 슬라이스 경계를 고정한다.
CourseUnit _unit(String id, int order, {String level = 'a1'}) => CourseUnit(
  id: id,
  level: level,
  order: order,
  title: const CurriculumText(ko: '제목', de: 'Titel', en: 'Title'),
  canDo: const CurriculumText(ko: '', de: '', en: ''),
);

PackProgress _progress(
  String id, {
  required PackStatus status,
  int learned = 0,
  int total = 10,
}) => PackProgress(
  packId: id,
  level: 'A1',
  status: status,
  wordsLearned: learned,
  wordsTotal: total,
  bossAccuracy: 0,
  attempts: 0,
  clearedAtIso: '',
);

({VocabPack pack, PackProgress progress}) _node(
  String id, {
  required PackStatus status,
  int learned = 0,
}) => (
  pack: VocabPack(id: id, level: 'A1', words: const []),
  progress: _progress(id, status: status, learned: learned),
);

MissionPick? _run({
  List<CourseUnit> units = const [],
  String? currentId,
  Set<String> completed = const {},
  ({VocabPack pack, PackProgress progress})? nowNode,
  int due = 0,
  ({String id, LearnerLevel level})? scenario,
  bool scenarioCompleted = false,
  LearnerLevel userLevel = LearnerLevel.a1,
}) => recommendMission(
  courseUnits: units,
  currentCourseUnitId: currentId,
  completedUnitIds: completed,
  nowNode: nowNode,
  dueCount: due,
  scenario: scenario,
  scenarioCompleted: scenarioCompleted,
  userLevel: userLevel,
);

void main() {
  final units = [_unit('u1', 1), _unit('u2', 2), _unit('u3', 3)];

  group('① 코스 미션', () {
    test('currentCourseUnitId 가 있으면 그 유닛을 고른다', () {
      final pick = _run(units: units, currentId: 'u2', completed: {'u1'});
      expect(pick, isA<CoursePick>());
      final c = pick as CoursePick;
      expect(c.unit.id, 'u2');
      expect(c.missionNumber, 2);
      expect(c.totalMissions, 3);
      expect(c.started, isTrue);
      expect(c.fraction, closeTo(1 / 3, 1e-9));
    });

    test('진단 전(currentId null·완료 0)이면 order 순 첫 미완 미션', () {
      final pick = _run(units: [_unit('b', 2), _unit('a', 1)]);
      expect((pick as CoursePick).unit.id, 'a');
      expect(pick.started, isFalse);
      expect(pick.missionNumber, 1);
    });

    test('전 미션 완료면 코스를 건너뛴다(다음 소스로)', () {
      final pick = _run(
        units: units,
        completed: {'u1', 'u2', 'u3'},
        due: 99,
      );
      expect(pick, isA<ReviewPick>());
    });

    test('missionNumber 는 total 을 넘지 않는다', () {
      final pick = _run(
        units: units,
        currentId: 'u3',
        completed: {'u1', 'u2', 'u3'},
      );
      expect((pick as CoursePick).missionNumber, 3);
    });
  });

  group('② 진행 중 팩', () {
    test('시작한(fraction>0) 미완 팩이면 PackPick', () {
      final pick = _run(nowNode: _node('p1', status: PackStatus.inProgress, learned: 4));
      expect(pick, isA<PackPick>());
      expect((pick as PackPick).fraction, greaterThan(0));
    });

    test('미시작 팩(fraction 0)은 팩으로 추천하지 않는다', () {
      final pick = _run(nowNode: _node('p1', status: PackStatus.available));
      expect(pick, isNull);
    });
  });

  group('③ 복습 임계', () {
    test('due 10 이상이면 ReviewPick', () {
      expect(_run(due: 10), isA<ReviewPick>());
    });
    test('due 9 는 미달 — 다음 소스로', () {
      expect(_run(due: 9), isNull);
    });
  });

  group('④ 시나리오 + R-REC(H-6)', () {
    test('사용자 레벨 이하 미완료 시나리오는 추천', () {
      final pick = _run(
        scenario: (id: 's1', level: LearnerLevel.a1),
        userLevel: LearnerLevel.a2,
      );
      expect((pick as ScenarioPick).scenarioId, 's1');
    });

    test('레벨 초과 시나리오는 절대 추천하지 않는다 (R-REC)', () {
      final pick = _run(
        scenario: (id: 's1', level: LearnerLevel.a2),
        userLevel: LearnerLevel.a1,
      );
      expect(pick, isNull);
    });

    test('완료한 시나리오는 추천하지 않는다', () {
      final pick = _run(
        scenario: (id: 's1', level: LearnerLevel.a1),
        scenarioCompleted: true,
      );
      expect(pick, isNull);
    });
  });

  test('우선순위: 코스 > 팩 > 복습 > 시나리오', () {
    final pick = _run(
      units: units,
      currentId: 'u1',
      nowNode: _node('p1', status: PackStatus.inProgress, learned: 5),
      due: 50,
      scenario: (id: 's1', level: LearnerLevel.a1),
    );
    expect(pick, isA<CoursePick>());
  });

  group('previewWindow — §10.2 ±1 슬라이스', () {
    final xs = ['a', 'b', 'c', 'd', 'e'];
    test('중간: 현재 ±1', () {
      expect(previewWindow(xs, 2), ['b', 'c', 'd']);
    });
    test('첫 노드: 앞 3개', () {
      expect(previewWindow(xs, 0), ['a', 'b', 'c']);
    });
    test('끝 노드: 뒤 3개', () {
      expect(previewWindow(xs, 4), ['c', 'd', 'e']);
    });
    test('now 없음(-1): 뒤 3개', () {
      expect(previewWindow(xs, -1), ['c', 'd', 'e']);
    });
    test('3개 미만이면 전부', () {
      expect(previewWindow(['a', 'b'], 0), ['a', 'b']);
    });
    test('빈 리스트는 빈 결과', () {
      expect(previewWindow(<String>[], 0), isEmpty);
    });
  });
}
