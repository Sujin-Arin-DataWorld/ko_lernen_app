// Pure service regressions. Device/UI completion gating is outside this suite.
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/grammar.dart';
import 'package:ko_lernen_app/models/grammar_study_plan.dart';
import 'package:ko_lernen_app/services/grammar_plan_service.dart';

Grammar _row(String id) => Grammar(
  id: id,
  pattern: id,
  level: 'a2',
  typeDe: '',
  explanationDe: '',
  exampleKorean: '',
  exampleGerman: '',
  note: '',
);

List<Grammar> _rows(int count) =>
    List.generate(count, (i) => _row('g${i + 1}'));

List<String> _ids(List<Grammar> rows, GrammarStudyPlan plan) =>
    GrammarPlanService.todaysSlice(
      curatedRows: rows,
      plan: plan,
    ).map((row) => row.id).toList();

void main() {
  group('history-aware day denominator', () {
    test(
      'a 3 to 10 pace change counts the completed day plus all remaining days',
      () {
        const plan = GrammarStudyPlan(
          level: 'a2',
          itemsPerDay: 10,
          servedIdsByDate: {
            '2026-10-29': ['g1', 'g2', 'g3'],
          },
        );
        expect(
          GrammarPlanService.totalDaysForPlan(
            curatedRows: _rows(24),
            plan: plan,
          ),
          4,
        );
      },
    );

    test(
      'a 10 to 3 pace change does not recount already served IDs as future days',
      () {
        final plan = GrammarStudyPlan(
          level: 'a2',
          itemsPerDay: 3,
          servedIdsByDate: {
            '2026-10-29': List.generate(10, (i) => 'g${i + 1}'),
          },
        );
        expect(
          GrammarPlanService.totalDaysForPlan(
            curatedRows: _rows(24),
            plan: plan,
          ),
          6,
        );
      },
    );

    test('an unchanged pace retains the ordinary day denominator', () {
      const plan = GrammarStudyPlan(
        level: 'a2',
        itemsPerDay: 3,
        servedIdsByDate: {
          '2026-10-29': ['g1', 'g2', 'g3'],
        },
      );
      expect(
        GrammarPlanService.totalDaysForPlan(curatedRows: _rows(24), plan: plan),
        8,
      );
    });

    test(
      'repeated historical IDs preserve actual days without hiding remaining rows',
      () {
        const plan = GrammarStudyPlan(
          level: 'a2',
          itemsPerDay: 3,
          servedIdsByDate: {
            '2026-10-28': ['g1', 'g2', 'g2'],
            '2026-10-29': ['g2', 'g3'],
          },
        );
        expect(
          GrammarPlanService.totalDaysForPlan(
            curatedRows: _rows(15),
            plan: plan,
          ),
          6,
        );
      },
    );

    test(
      'a removed past ID cannot subtract an unserved current row from the estimate',
      () {
        const plan = GrammarStudyPlan(
          level: 'a2',
          itemsPerDay: 3,
          servedIdsByDate: {
            '2026-10-29': ['removed-old-id', 'g1', 'g2'],
          },
        );
        expect(
          GrammarPlanService.totalDaysForPlan(
            curatedRows: _rows(15),
            plan: plan,
          ),
          6,
        );
      },
    );

    test(
      'exhaustion retains the actual historical day count after a pace change',
      () {
        const plan = GrammarStudyPlan(
          level: 'a2',
          itemsPerDay: 10,
          servedIdsByDate: {
            '2026-10-28': ['g1', 'g2'],
            '2026-10-29': ['g3'],
          },
        );
        expect(
          GrammarPlanService.totalDaysForPlan(
            curatedRows: _rows(3),
            plan: plan,
          ),
          2,
        );
      },
    );

    for (final invalidPace in [0, -1]) {
      test(
        'nonpositive pace preserves the existing zero estimate: $invalidPace',
        () {
          final plan = GrammarStudyPlan(
            level: 'a2',
            itemsPerDay: invalidPace,
            servedIdsByDate: {
              '2026-10-29': ['g1'],
            },
          );
          expect(
            GrammarPlanService.totalDaysForPlan(
              curatedRows: _rows(15),
              plan: plan,
            ),
            0,
          );
        },
      );
    }
  });

  test('pace 3 to 10 resumes at the first actual unserved ID', () {
    final rows = _rows(24);
    const old = GrammarStudyPlan(
      level: 'a2',
      itemsPerDay: 3,
      servedIdsByDate: {
        '2026-10-29': ['g1', 'g2', 'g3'],
      },
    );
    expect(
      _ids(rows, old.copyWith(itemsPerDay: 10)),
      List.generate(10, (i) => 'g${i + 4}'),
    );
  });

  test('pace 10 to 3 never replays IDs already served at the old pace', () {
    final old = GrammarStudyPlan(
      level: 'a2',
      itemsPerDay: 10,
      servedIdsByDate: {'2026-10-29': List.generate(10, (i) => 'g${i + 1}')},
    );
    expect(_ids(_rows(24), old.copyWith(itemsPerDay: 3)), [
      'g11',
      'g12',
      'g13',
    ]);
  });

  test(
    'duplicate IDs within and across historical dates do not consume unseen rows',
    () {
      const plan = GrammarStudyPlan(
        level: 'a2',
        itemsPerDay: 3,
        servedIdsByDate: {
          '2026-10-28': ['g1', 'g2', 'g2'],
          '2026-10-29': ['g2', 'g3'],
        },
      );
      expect(_ids(_rows(15), plan), ['g4', 'g5', 'g6']);
    },
  );

  test(
    'a historical ID removed from the catalog cannot advance the current cursor',
    () {
      const plan = GrammarStudyPlan(
        level: 'a2',
        itemsPerDay: 3,
        servedIdsByDate: {
          '2026-10-29': ['removed-old-id', 'g1', 'g2'],
        },
      );
      expect(_ids(_rows(15), plan), ['g3', 'g4', 'g5']);
    },
  );

  test(
    'a newly inserted unserved catalog row remains available in CSV order',
    () {
      final rows = [_row('g1'), _row('new-row'), ..._rows(15).skip(1)];
      const plan = GrammarStudyPlan(
        level: 'a2',
        itemsPerDay: 3,
        servedIdsByDate: {
          '2026-10-29': ['g1', 'g2', 'g3'],
        },
      );
      expect(_ids(rows, plan), ['new-row', 'g4', 'g5']);
    },
  );

  test(
    'selection retains current CSV order rather than sorting IDs or counting dates',
    () {
      final rows = ['g7', 'g1', 'g4', 'g2', 'g8'].map(_row).toList();
      const plan = GrammarStudyPlan(
        level: 'a2',
        itemsPerDay: 3,
        servedIdsByDate: {
          '2026-10-29': ['g1', 'g2'],
        },
      );
      expect(_ids(rows, plan), ['g7', 'g4', 'g8']);
    },
  );

  test(
    'selection is repeatable and cannot mutate rows or the caller-owned today cache',
    () {
      final rows = _rows(12);
      final originalOrder = rows.map((row) => row.id).toList();
      const plan = GrammarStudyPlan(
        level: 'a2',
        itemsPerDay: 3,
        servedIdsByDate: {
          '2026-10-30': ['g1', 'g2', 'g3'],
        },
      );
      final before = GrammarPlanService.encodePlans({'a2': plan});
      final first = _ids(rows, plan);
      final second = _ids(rows, plan);
      expect(first, ['g4', 'g5', 'g6']);
      expect(second, first);
      expect(GrammarPlanService.encodePlans({'a2': plan}), before);
      expect(plan.servedIdsByDate['2026-10-30'], ['g1', 'g2', 'g3']);
      expect(plan.completedDays, 1);
      expect(rows.map((row) => row.id), originalOrder);
      // The service has no clock/IO. GrammarScreen owns the existing
      // containsKey(Storage.todayIso()) gate and must not call this to open
      // another plan day after today's completion. Device/UI proof is separate.
    },
  );

  test(
    'same-day replay of an existing cached slice does not add a completed day',
    () {
      const plan = GrammarStudyPlan(
        level: 'a2',
        itemsPerDay: 3,
        servedIdsByDate: {
          '2026-10-30': ['g1', 'g2', 'g3'],
        },
      );
      final replay = GrammarPlanService.recordServedDay(
        plan,
        dateIso: '2026-10-30',
        servedIds: plan.servedIdsByDate['2026-10-30']!,
      );
      expect(
        GrammarPlanService.encodePlans({'a2': replay}),
        GrammarPlanService.encodePlans({'a2': plan}),
      );
      expect(replay.completedDays, 1);
      expect(_ids(_rows(12), replay), ['g4', 'g5', 'g6']);
    },
  );

  test(
    'exhaustion depends on served IDs and leaves the plan history unchanged',
    () {
      const plan = GrammarStudyPlan(
        level: 'a2',
        itemsPerDay: 10,
        servedIdsByDate: {
          '2026-10-29': ['g1', 'g2', 'g3'],
        },
      );
      expect(_ids(_rows(3), plan), isEmpty);
      expect(plan.servedIdsByDate, {
        '2026-10-29': ['g1', 'g2', 'g3'],
      });
    },
  );
}
