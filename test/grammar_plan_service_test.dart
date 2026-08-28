import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/grammar.dart';
import 'package:ko_lernen_app/models/grammar_study_plan.dart';
import 'package:ko_lernen_app/services/grammar_plan_service.dart';

Grammar _g(String id, String level) => Grammar(
      id: id,
      pattern: id,
      level: level,
      typeDe: '',
      explanationDe: '',
      exampleKorean: '',
      exampleGerman: '',
      note: '',
      typeEn: '',
      explanationEn: '',
      exampleEn: '',
      noteEn: '',
      exampleGermanFocus: '',
      exampleEnFocus: '',
      quizEnabled: false,
      quizDistractorIds: const [],
    );

void main() {
  final rows = [
    _g('a1_01', 'A1'),
    _g('a1_02', 'A1'),
    _g('a1_03', 'A1'),
    _g('b1_01', 'B1'),
  ];

  test('curatedRowsForLevel 은 CSV 등장 순서를 보존한 채 레벨만 거른다', () {
    final result = GrammarPlanService.curatedRowsForLevel(rows, 'A1');
    expect(result.map((g) => g.id), ['a1_01', 'a1_02', 'a1_03']);
    expect(rows.map((g) => g.id), ['a1_01', 'a1_02', 'a1_03', 'b1_01']);

    final lowerCase = GrammarPlanService.curatedRowsForLevel(rows, 'a1');
    expect(lowerCase.map((g) => g.id), ['a1_01', 'a1_02', 'a1_03']);
  });

  test('todaysSlice 는 completedDays 기반 결정적 윈도우다 (달력 아님)', () {
    const plan = GrammarStudyPlan(
      level: 'a1',
      itemsPerDay: 2,
      servedIdsByDate: {},
    );
    final slice0 = GrammarPlanService.todaysSlice(
      curatedRows: GrammarPlanService.curatedRowsForLevel(rows, 'A1'),
      plan: plan,
    );
    expect(slice0.map((g) => g.id), ['a1_01', 'a1_02']);

    final planDay1 = plan.copyWith(
      servedIdsByDate: {'2026-08-20': ['a1_01', 'a1_02']},
    );
    final slice1 = GrammarPlanService.todaysSlice(
      curatedRows: GrammarPlanService.curatedRowsForLevel(rows, 'A1'),
      plan: planDay1,
    );
    expect(slice1.map((g) => g.id), ['a1_03']);
  });

  test('todaysSlice 는 큐레이션 소진 시 빈 리스트를 반환한다', () {
    const plan = GrammarStudyPlan(
      level: 'a1',
      itemsPerDay: 2,
      servedIdsByDate: {
        '2026-08-20': ['a1_01', 'a1_02'],
        '2026-08-21': ['a1_03'],
      },
    );
    final slice = GrammarPlanService.todaysSlice(
      curatedRows: GrammarPlanService.curatedRowsForLevel(rows, 'A1'),
      plan: plan,
    );
    expect(slice, isEmpty);
  });

  test('totalDays 는 itemsPerDay 로 올림 나눗셈한다', () {
    expect(
      GrammarPlanService.totalDays(
        GrammarPlanService.curatedRowsForLevel(rows, 'A1'),
        2,
      ),
      2,
    );
  });

  test('비양수 itemsPerDay 는 빈 슬라이스와 0일을 반환한다', () {
    const plan = GrammarStudyPlan(
      level: 'a1',
      itemsPerDay: 0,
      servedIdsByDate: {},
    );
    final curatedRows = GrammarPlanService.curatedRowsForLevel(rows, 'A1');

    expect(
      GrammarPlanService.todaysSlice(curatedRows: curatedRows, plan: plan),
      isEmpty,
    );
    expect(GrammarPlanService.totalDays(curatedRows, 0), 0);
    expect(GrammarPlanService.totalDays(curatedRows, -1), 0);
  });

  test('recordServedDay 는 불변 카피를 반환하고 같은 날 재호출은 멱등하다', () {
    const plan = GrammarStudyPlan(
      level: 'a1',
      itemsPerDay: 2,
      servedIdsByDate: {},
    );
    final day1 = GrammarPlanService.recordServedDay(
      plan,
      dateIso: '2026-08-20',
      servedIds: ['a1_01', 'a1_02'],
    );
    expect(plan.servedIdsByDate, isEmpty);
    expect(day1.completedDays, 1);
    final again = GrammarPlanService.recordServedDay(
      day1,
      dateIso: '2026-08-20',
      servedIds: ['a1_03'],
    );
    expect(again.completedDays, 1);
    expect(again.servedIdsByDate['2026-08-20'], ['a1_03']);
    expect(day1.servedIdsByDate['2026-08-20'], ['a1_01', 'a1_02']);
  });

  test('recordServedDay 는 호출측 servedIds 목록을 별칭으로 보관하지 않는다', () {
    const plan = GrammarStudyPlan(
      level: 'a1',
      itemsPerDay: 2,
      servedIdsByDate: {},
    );
    final servedIds = ['a1_01'];
    final recorded = GrammarPlanService.recordServedDay(
      plan,
      dateIso: '2026-08-20',
      servedIds: servedIds,
    );

    servedIds.add('a1_02');
    expect(recorded.servedIdsByDate['2026-08-20'], ['a1_01']);
  });

  test('encodePlans/decodePlans 는 레벨별 맵으로 라운드트립한다', () {
    const plans = {
      'a1': GrammarStudyPlan(
        level: 'a1',
        itemsPerDay: 5,
        servedIdsByDate: {'2026-08-20': ['a1_01']},
      ),
    };
    final raw = GrammarPlanService.encodePlans(plans);
    final decoded = GrammarPlanService.decodePlans(raw);
    expect(decoded['a1']?.itemsPerDay, 5);
    expect(decoded['a1']?.servedIdsByDate, {
      '2026-08-20': ['a1_01'],
    });
  });

  test('decodePlans 는 빈/손상 원본에 빈 맵을 반환한다', () {
    expect(GrammarPlanService.decodePlans(''), isEmpty);
    expect(GrammarPlanService.decodePlans('{not json'), isEmpty);
    expect(GrammarPlanService.decodePlans('[]'), isEmpty);
    expect(GrammarPlanService.decodePlans('{"a1": []}'), isEmpty);
  });
}
