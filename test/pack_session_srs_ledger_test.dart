import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/services/pack_session_srs_ledger.dart';

void main() {
  group('PackSessionSrsLedger', () {
    test('records one initial positive SRS write', () {
      final ledger = PackSessionSrsLedger();

      expect(ledger.stateFor('학교'), PackSessionSrsState.unrated);
      expect(ledger.recordPositive('학교'), PackSessionSrsAction.positive);
      expect(ledger.stateFor('학교'), PackSessionSrsState.positive);
      expect(ledger.recordPositive('학교'), PackSessionSrsAction.none);
      expect(ledger.stateFor('학교'), PackSessionSrsState.positive);
    });

    test('a first negative overrides an earlier positive exactly once', () {
      final ledger = PackSessionSrsLedger();

      expect(ledger.recordPositive('학교'), PackSessionSrsAction.positive);
      expect(ledger.recordNegative('학교'), PackSessionSrsAction.negative);
      expect(ledger.stateFor('학교'), PackSessionSrsState.negative);
      expect(ledger.recordNegative('학교'), PackSessionSrsAction.none);
    });

    test('a later positive is neutral after a negative outcome', () {
      final ledger = PackSessionSrsLedger();

      expect(ledger.recordNegative('학교'), PackSessionSrsAction.negative);
      expect(ledger.recordPositive('학교'), PackSessionSrsAction.none);
      expect(ledger.stateFor('학교'), PackSessionSrsState.negative);
    });

    test('keeps evidence independent for each word and ignores empty IDs', () {
      final ledger = PackSessionSrsLedger();

      expect(ledger.recordPositive('학교'), PackSessionSrsAction.positive);
      expect(ledger.recordNegative('사과'), PackSessionSrsAction.negative);
      expect(ledger.stateFor('학교'), PackSessionSrsState.positive);
      expect(ledger.stateFor('사과'), PackSessionSrsState.negative);
      expect(ledger.recordPositive('  '), PackSessionSrsAction.none);
      expect(ledger.recordNegative(''), PackSessionSrsAction.none);
    });

    test('exposes SRS write metadata for callers', () {
      expect(PackSessionSrsAction.none.writesSrs, isFalse);
      expect(PackSessionSrsAction.none.gotIt, isNull);
      expect(PackSessionSrsAction.positive.writesSrs, isTrue);
      expect(PackSessionSrsAction.positive.gotIt, isTrue);
      expect(PackSessionSrsAction.negative.writesSrs, isTrue);
      expect(PackSessionSrsAction.negative.gotIt, isFalse);
    });
  });

  group('PackRecallSession', () {
    test(
      'shares the ledger when typed recall is reopened for the same pack',
      () {
        final session = PackRecallSession.forPack(packId: 'a1_food_1');

        expect(session.isPracticeOnly, isFalse);
        expect(session.isValidForPack('a1_food_1'), isTrue);
        expect(
          session.recordPositiveFor(expectedPackId: 'a1_food_1', wordId: '사과'),
          PackSessionSrsAction.positive,
        );

        final reopened = PackRecallSession.fromRouteArgument(
          session,
          expectedPackId: 'a1_food_1',
        );
        expect(identical(reopened, session), isTrue);
        expect(
          reopened.recordPositiveFor(expectedPackId: 'a1_food_1', wordId: '사과'),
          PackSessionSrsAction.none,
        );
        expect(
          reopened.recordNegativeFor(expectedPackId: 'a1_food_1', wordId: '사과'),
          PackSessionSrsAction.negative,
        );
        expect(
          reopened.recordPositiveFor(expectedPackId: 'a1_food_1', wordId: '사과'),
          PackSessionSrsAction.none,
        );
      },
    );

    test(
      'missing, malformed, and mismatched route payloads are practice only',
      () {
        final valid = PackRecallSession.forPack(packId: 'a1_food_1');
        final sessions = <PackRecallSession>[
          PackRecallSession.fromRouteArgument(
            null,
            expectedPackId: 'a1_food_1',
          ),
          PackRecallSession.fromRouteArgument(<String, Object>{
            'packId': 'a1_food_1',
          }, expectedPackId: 'a1_food_1'),
          PackRecallSession.fromRouteArgument(
            valid,
            expectedPackId: 'a1_food_2',
          ),
        ];

        for (final session in sessions) {
          expect(session.isPracticeOnly, isTrue);
          expect(session.isValidForPack('a1_food_1'), isFalse);
          expect(
            session.recordPositiveFor(
              expectedPackId: 'a1_food_1',
              wordId: '사과',
            ),
            PackSessionSrsAction.none,
          );
          expect(
            session.recordNegativeFor(
              expectedPackId: 'a1_food_1',
              wordId: '사과',
            ),
            PackSessionSrsAction.none,
          );
          expect(session.ledger.stateFor('사과'), PackSessionSrsState.unrated);
        }
      },
    );
  });
}
