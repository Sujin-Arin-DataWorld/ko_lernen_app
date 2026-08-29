import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/grammar_study_plan.dart';

void main() {
  test('completedDays 는 servedIdsByDate 의 날짜 수다 (일차 카운트 아님)', () {
    const plan = GrammarStudyPlan(
      level: 'a1',
      itemsPerDay: 5,
      servedIdsByDate: {
        '2026-08-20': ['g1', 'g2'],
        '2026-08-21': ['g3'],
      },
    );
    expect(plan.completedDays, 2);
  });

  test('completedDays 는 비연속 날짜도 저장된 키 수만 센다', () {
    const plan = GrammarStudyPlan(
      level: 'a1',
      itemsPerDay: 5,
      servedIdsByDate: {
        '2026-08-01': ['g1'],
        '2026-08-28': ['g2'],
      },
    );

    expect(plan.completedDays, 2);
  });

  test('toJson/fromJson 라운드트립', () {
    const plan = GrammarStudyPlan(
      level: 'a1',
      itemsPerDay: 7,
      servedIdsByDate: {
        '2026-08-20': ['g1', 'g2'],
        '2026-08-21': ['g3', 'g4', 'g5'],
      },
    );
    final decoded = GrammarStudyPlan.fromJson(plan.toJson());
    expect(decoded.level, plan.level);
    expect(decoded.itemsPerDay, plan.itemsPerDay);
    expect(decoded.servedIdsByDate, plan.servedIdsByDate);
    expect(decoded.servedIdsByDate.keys, ['2026-08-20', '2026-08-21']);
    expect(decoded.servedIdsByDate['2026-08-20'], ['g1', 'g2']);
    expect(decoded.servedIdsByDate['2026-08-21'], ['g3', 'g4', 'g5']);
  });

  test('fromJson 은 결측 필드에 안전한 기본값을 쓴다', () {
    final decoded = GrammarStudyPlan.fromJson(const {});
    expect(decoded.level, '');
    expect(decoded.itemsPerDay, 5);
    expect(decoded.servedIdsByDate, isEmpty);
  });
}
