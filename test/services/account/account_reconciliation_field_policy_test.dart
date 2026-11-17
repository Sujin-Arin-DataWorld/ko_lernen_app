import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/grammar.dart';
import 'package:ko_lernen_app/models/grammar_study_plan.dart';
import 'package:ko_lernen_app/models/yeopjeon_wallet.dart';
import 'package:ko_lernen_app/services/account/account_reconciliation_field_policy.dart';
import 'package:ko_lernen_app/services/grammar_plan_service.dart';

String _grammar({
  int itemsPerDay = 3,
  Map<String, List<String>> served = const {},
}) => GrammarPlanService.encodePlans({
  'a2': GrammarStudyPlan(
    level: 'a2',
    itemsPerDay: itemsPerDay,
    servedIdsByDate: served,
  ),
});

void main() {
  group('study history', () {
    test('retains disjoint dates and deduplicates every overlapping date', () {
      const local = '{"2026-10-29":["device","shared","shared"]}';
      const remote = '{"2026-10-29":["shared","cloud"],"2026-10-30":["next"]}';
      for (final (left, right) in [(local, remote), (remote, local)]) {
        final merged = AccountReconciliationFieldPolicy.mergeStudyLog(
          left,
          right,
        );
        final decoded = jsonDecode(merged) as Map;
        expect(decoded.keys, unorderedEquals(['2026-10-29', '2026-10-30']));
        expect(
          decoded['2026-10-29'],
          unorderedEquals(['device', 'shared', 'cloud']),
        );
        expect(decoded['2026-10-30'], ['next']);
        expect(
          AccountReconciliationFieldPolicy.mergeStudyLog(merged, right),
          merged,
        );
      }
    });

    test(
      'absent and empty reset history cannot discard remote observations',
      () {
        for (final empty in [null, '']) {
          expect(
            jsonDecode(
              AccountReconciliationFieldPolicy.mergeStudyLog(
                empty,
                '{"2026-10-30":["cloud"]}',
              ),
            ),
            {
              '2026-10-30': ['cloud'],
            },
          );
        }
      },
    );

    test('accepts exactly 500 unique IDs but rejects a 501-ID union', () {
      final first = List.generate(250, (index) => 'first-$index');
      final second = List.generate(250, (index) => 'second-$index');
      final merged = AccountReconciliationFieldPolicy.mergeStudyLog(
        jsonEncode({'2026-10-30': first}),
        jsonEncode({'2026-10-30': second}),
      );
      expect((jsonDecode(merged)['2026-10-30'] as List), hasLength(500));
      expect(
        () => AccountReconciliationFieldPolicy.mergeStudyLog(
          merged,
          '{"2026-10-30":["overflow"]}',
        ),
        throwsFormatException,
      );
    });

    for (final invalid in [
      'not-json',
      '[]',
      '{"2026-02-30":["id"]}',
      '{"2026-10-3":["id"]}',
      '{"2026-10-30":"id"}',
      '{"2026-10-30":[1]}',
      '{"2026-10-30":[""]}',
    ]) {
      test('rejects invalid history $invalid', () {
        expect(
          () => AccountReconciliationFieldPolicy.mergeStudyLog('', invalid),
          throwsFormatException,
        );
      });
    }
  });

  group('grammar plan', () {
    test(
      'retains device pace and compatible same-pace ordered-history extensions',
      () {
        final local = _grammar(
          served: {
            '2026-10-29': ['g1', 'g2'],
          },
        );
        final remote = _grammar(
          itemsPerDay: 3,
          served: {
            '2026-10-29': ['g1', 'g2', 'g3'],
            '2026-10-30': ['g4'],
          },
        );
        final merged = AccountReconciliationFieldPolicy.mergeGrammarPlan(
          local,
          remote,
        );
        expect(jsonDecode(merged), {
          'a2': {
            'level': 'a2',
            'itemsPerDay': 3,
            'servedIdsByDate': {
              '2026-10-29': ['g1', 'g2', 'g3'],
              '2026-10-30': ['g4'],
            },
          },
        });
        expect(
          AccountReconciliationFieldPolicy.mergeGrammarPlan(merged, remote),
          merged,
        );
      },
    );

    test(
      'retains conservative mixed-pace account policy after planner repair',
      () {
        final local = _grammar(itemsPerDay: 10);
        final remote = _grammar(
          itemsPerDay: 3,
          served: {
            '2026-10-29': ['g1', 'g2', 'g3'],
          },
        );
        final rows = List.generate(
          20,
          (index) => Grammar(
            id: 'g${index + 1}',
            pattern: 'pattern-$index',
            level: 'a2',
            typeDe: '',
            explanationDe: '',
            exampleKorean: '',
            exampleGerman: '',
            note: '',
          ),
        );
        final cloudPlan = GrammarPlanService.decodePlans(remote)['a2']!;
        expect(
          GrammarPlanService.todaysSlice(
            curatedRows: rows,
            plan: cloudPlan,
          ).first.id,
          'g4',
        );
        expect(
          GrammarPlanService.todaysSlice(
            curatedRows: rows,
            plan: cloudPlan.copyWith(itemsPerDay: 10),
          ).first.id,
          'g4',
        );
        expect(
          () =>
              AccountReconciliationFieldPolicy.mergeGrammarPlan(local, remote),
          throwsFormatException,
        );
      },
    );

    test(
      'rejects a mixed-pace prefix extension not represented by the local plan',
      () {
        final local = _grammar(
          itemsPerDay: 10,
          served: {
            '2026-10-29': ['g1', 'g2'],
          },
        );
        final remote = _grammar(
          itemsPerDay: 3,
          served: {
            '2026-10-29': ['g1', 'g2', 'g3'],
          },
        );
        expect(
          () =>
              AccountReconciliationFieldPolicy.mergeGrammarPlan(local, remote),
          throwsFormatException,
        );
      },
    );

    test(
      'mixed pace retains identical local history without adopting a new slice',
      () {
        final local = _grammar(
          itemsPerDay: 10,
          served: {
            '2026-10-29': ['g1', 'g2', 'g3'],
          },
        );
        final remote = _grammar(
          itemsPerDay: 3,
          served: {
            '2026-10-29': ['g1', 'g2', 'g3'],
          },
        );
        final merged = AccountReconciliationFieldPolicy.mergeGrammarPlan(
          local,
          remote,
        );
        expect(jsonDecode(merged), jsonDecode(local));
        expect(
          AccountReconciliationFieldPolicy.mergeGrammarPlan(merged, remote),
          merged,
        );
      },
    );

    test(
      'mixed pace retains local-dominant history without replacing its progress',
      () {
        final local = _grammar(
          itemsPerDay: 10,
          served: {
            '2026-10-29': List.generate(10, (index) => 'g${index + 1}'),
            '2026-10-30': ['g11'],
          },
        );
        final remote = _grammar(
          itemsPerDay: 3,
          served: {
            '2026-10-29': ['g1', 'g2', 'g3'],
          },
        );
        expect(
          jsonDecode(
            AccountReconciliationFieldPolicy.mergeGrammarPlan(local, remote),
          ),
          jsonDecode(local),
        );
      },
    );

    test('retains disjoint dates and supported levels from either device', () {
      final local = _grammar(
        served: {
          '2026-10-29': ['g1'],
        },
      );
      final remote = GrammarPlanService.encodePlans({
        'a2': const GrammarStudyPlan(
          level: 'a2',
          itemsPerDay: 3,
          servedIdsByDate: {
            '2026-10-30': ['g2'],
          },
        ),
        'b1': const GrammarStudyPlan(
          level: 'b1',
          itemsPerDay: 7,
          servedIdsByDate: {
            '2026-10-28': ['b1-g1'],
          },
        ),
      });
      final merged = jsonDecode(
        AccountReconciliationFieldPolicy.mergeGrammarPlan(local, remote),
      );
      expect(merged['a2']['servedIdsByDate'], {
        '2026-10-29': ['g1'],
        '2026-10-30': ['g2'],
      });
      expect(merged['b1']['servedIdsByDate'], {
        '2026-10-28': ['b1-g1'],
      });
    });

    test('a reset-empty plan adopts validated served history', () {
      final remote = _grammar(
        served: {
          '2026-10-29': ['g1'],
        },
      );
      expect(
        jsonDecode(
          AccountReconciliationFieldPolicy.mergeGrammarPlan('', remote),
        ),
        jsonDecode(remote),
      );
    });

    test(
      'rejects forked ordered histories instead of skipping unseen work',
      () {
        expect(
          () => AccountReconciliationFieldPolicy.mergeGrammarPlan(
            _grammar(
              served: {
                '2026-10-29': ['g1', 'g2'],
              },
            ),
            _grammar(
              served: {
                '2026-10-29': ['g1', 'different'],
              },
            ),
          ),
          throwsFormatException,
        );
      },
    );

    test(
      'same served IDs on different dates cannot count as two new slices',
      () {
        expect(
          () => AccountReconciliationFieldPolicy.mergeGrammarPlan(
            _grammar(
              served: {
                '2026-10-29': ['g1'],
              },
            ),
            _grammar(
              served: {
                '2026-10-30': ['g1'],
              },
            ),
          ),
          throwsFormatException,
        );
      },
    );

    for (final invalid in [
      'not-json',
      '[]',
      '{"z9":{"level":"z9","itemsPerDay":3,"servedIdsByDate":{}}}',
      '{"a2":{"level":"a2","itemsPerDay":4,"servedIdsByDate":{}}}',
      '{"a2":{"level":"b1","itemsPerDay":3,"servedIdsByDate":{}}}',
      '{"a2":{"level":"a2","itemsPerDay":3,"servedIdsByDate":{},"future":true}}',
      '{"a2":{"level":"a2","itemsPerDay":3,"servedIdsByDate":{"2026-02-30":["g1"]}}}',
      '{"a2":{"level":"a2","itemsPerDay":3,"servedIdsByDate":{"2026-10-30":[1]}}}',
    ]) {
      test('rejects unsupported grammar data $invalid', () {
        expect(
          () => AccountReconciliationFieldPolicy.mergeGrammarPlan('', invalid),
          throwsFormatException,
        );
      });
    }
  });

  group('learning goal', () {
    test('valid device preference wins independently of course placement', () {
      expect(
        AccountReconciliationFieldPolicy.mergeLearnerGoal(' A2 ', 'b1'),
        'a2',
      );
      expect(
        AccountReconciliationFieldPolicy.mergeLearnerGoal('c2', 'a1'),
        'c2',
      );
    });
    test('a missing preference adopts the valid cloud goal', () {
      expect(
        AccountReconciliationFieldPolicy.mergeLearnerGoal(null, 'B2'),
        'b2',
      );
      expect(AccountReconciliationFieldPolicy.mergeLearnerGoal('', 'a1'), 'a1');
      expect(
        AccountReconciliationFieldPolicy.mergeLearnerGoal(null, null),
        isNull,
      );
    });
    for (final invalid in [
      'z9',
      3,
      <String, Object>{'level': 'a2'},
    ]) {
      test('unsupported learning-goal data stays blocked: $invalid', () {
        expect(
          () =>
              AccountReconciliationFieldPolicy.mergeLearnerGoal('a2', invalid),
          throwsFormatException,
        );
        expect(
          () =>
              AccountReconciliationFieldPolicy.mergeLearnerGoal(invalid, 'a2'),
          throwsFormatException,
        );
      });
    }
  });

  group('wallet', () {
    final zero = YeopjeonWallet.grandfather(sarangchaeStage: 0, b2Stage: 0);

    test(
      'whole-document dominance retains spending instead of balance maximum',
      () {
        final earned = zero.copyWith(
          balance: 40,
          sarangchaeEligibleStage: 1,
          claims: {'milestone:s:1': 40},
        );
        final spent = earned.copyWith(balance: 0, sarangchaeOwnedStage: 1);
        for (final (local, remote) in [(earned, spent), (spent, earned)]) {
          final merged = YeopjeonWallet.decode(
            AccountReconciliationFieldPolicy.mergeWallet(
              local.encode(),
              remote.encode(),
            ),
          );
          expect(merged.balance, 0);
          expect(merged.sarangchaeOwnedStage, 1);
          expect(merged.claims, {'milestone:s:1': 40});
        }
      },
    );

    test(
      'pristine device zero adopts history and retains existing source markers',
      () {
        final local = zero.copyWith(completedSourceIds: {'unit:local-proof'});
        final remote = YeopjeonWallet.grandfather(
          sarangchaeStage: 1,
          b2Stage: 0,
        ).copyWith(completedSourceIds: {'unit:cloud-proof'});
        final merged = YeopjeonWallet.decode(
          AccountReconciliationFieldPolicy.mergeWallet(
            local.encode(),
            remote.encode(),
          ),
        );
        expect(merged.balance, 0);
        expect(merged.claims, isEmpty);
        expect(merged.sarangchaeOwnedStage, 1);
        expect(merged.completedSourceIds, {
          'unit:local-proof',
          'unit:cloud-proof',
        });
      },
    );

    test(
      'divergent earned ledgers remain blocked instead of unioning claims',
      () {
        final local = zero.copyWith(
          balance: 20,
          claims: {'daily:2026-10-29:first': 20},
          completedSourceIds: {'unit:one'},
        );
        final remote = zero.copyWith(
          balance: 20,
          claims: {'daily:2026-10-30:first': 20},
          completedSourceIds: {'unit:two'},
        );
        expect(
          () => AccountReconciliationFieldPolicy.mergeWallet(
            local.encode(),
            remote.encode(),
          ),
          throwsFormatException,
        );
      },
    );

    test(
      'unknown wallet schema cannot be dropped through model regeneration',
      () {
        final unknown = jsonEncode({
          ...zero.toJson(),
          'futureLedger': ['proof'],
        });
        expect(
          () => AccountReconciliationFieldPolicy.mergeWallet(
            zero.encode(),
            unknown,
          ),
          throwsFormatException,
        );
      },
    );

    test(
      'absent remote ledger preserves local ledger without creating claims',
      () {
        final result = AccountReconciliationFieldPolicy.mergeWallet(
          zero.encode(),
          null,
        );
        expect(YeopjeonWallet.decode(result).encode(), zero.encode());
        expect(
          () => AccountReconciliationFieldPolicy.mergeWallet(null, null),
          throwsFormatException,
        );
      },
    );
  });
}
