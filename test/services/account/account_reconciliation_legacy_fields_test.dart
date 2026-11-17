import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/account_reconciliation.dart';

AccountReconciliationSnapshot _snapshot(Map<String, Object?> fields) =>
    AccountReconciliationSnapshot(
      fields: fields,
      srsCards: const {},
      customPacks: const {},
      packProgress: const {},
    );

void main() {
  for (final newerIsLocal in [true, false]) {
    test(
      'calendar-date backup merge keeps the newer date and its current streak '
      'when newerIsLocal=$newerIsLocal',
      () {
        final newer = _snapshot({
          'app': {
            'last_open': '2026-10-30',
            'streak_days': 2,
            'best_streak': 2,
          },
        });
        final older = _snapshot({
          'app': {
            'last_open': '2026-09-20',
            'streak_days': 10,
            'best_streak': 14,
          },
        });

        final result = AccountReconciliationMerger.merge(
          local: newerIsLocal ? newer : older,
          remote: newerIsLocal ? older : newer,
          catalog: const {},
        );

        expect(result.conflicts, isEmpty);
        expect(result.merged!.fields['app'], {
          'last_open': '2026-10-30',
          'streak_days': 2,
          'best_streak': 14,
        });
        for (final original in [newer, older]) {
          final repeated = AccountReconciliationMerger.merge(
            local: result.merged!,
            remote: original,
            catalog: const {},
          );
          expect(repeated.conflicts, isEmpty);
          expect(repeated.merged, result.merged);
        }
      },
    );
  }

  test('same-day current streak and best streak remain monotonic', () {
    final result = AccountReconciliationMerger.merge(
      local: _snapshot({
        'app': {'last_open': '2026-10-30', 'streak_days': 2, 'best_streak': 8},
      }),
      remote: _snapshot({
        'app': {'last_open': '2026-10-30', 'streak_days': 3, 'best_streak': 4},
      }),
      catalog: const {},
    );

    expect(result.conflicts, isEmpty);
    expect(result.merged!.fields['app'], {
      'last_open': '2026-10-30',
      'streak_days': 3,
      'best_streak': 8,
    });
  });

  test('empty local-reset wrong counts preserve all remote observations', () {
    // buildBackupPayload always emits the raw string, including '' after reset.
    final remoteCounts = jsonEncode({'word-one': 3, 'word-two': 1});
    final result = AccountReconciliationMerger.merge(
      local: _snapshot({'wrong_count_json': ''}),
      remote: _snapshot({'wrong_count_json': remoteCounts}),
      catalog: const {},
    );

    expect(result.conflicts, isEmpty);
    expect(jsonDecode(result.merged!.fields['wrong_count_json']! as String), {
      'word-one': 3,
      'word-two': 1,
    });
  });

  test(
    'wrong counts merge by item maximum in either direction and on retry',
    () {
      final first = _snapshot({'wrong_count_json': '{"shared":2,"first":4}'});
      final second = _snapshot({'wrong_count_json': '{"shared":5,"second":1}'});
      for (final (local, remote) in [(first, second), (second, first)]) {
        final result = AccountReconciliationMerger.merge(
          local: local,
          remote: remote,
          catalog: const {},
        );
        expect(result.conflicts, isEmpty);
        expect(
          jsonDecode(result.merged!.fields['wrong_count_json']! as String),
          {'first': 4, 'second': 1, 'shared': 5},
        );
        for (final original in [
          local,
          remote,
          _snapshot({'wrong_count_json': ''}),
        ]) {
          final repeated = AccountReconciliationMerger.merge(
            local: result.merged!,
            remote: original,
            catalog: const {},
          );
          expect(repeated.conflicts, isEmpty);
          expect(repeated.merged, result.merged);
        }
      }
    },
  );

  test(
    'empty reset app history adopts dated history without erasing other fields',
    () {
      final first = _snapshot({
        'app': {
          'last_open': '',
          'streak_days': 0,
          'best_streak': 0,
          'local_extension': ['local-proof'],
        },
      });
      final second = _snapshot({
        'app': {
          'last_open': '2026-09-20',
          'streak_days': 3,
          'best_streak': 8,
          'remote_extension': ['remote-proof'],
        },
      });
      for (final (local, remote) in [(first, second), (second, first)]) {
        final result = AccountReconciliationMerger.merge(
          local: local,
          remote: remote,
          catalog: const {},
        );
        expect(result.conflicts, isEmpty);
        expect(result.merged!.fields['app'], {
          'last_open': '2026-09-20',
          'streak_days': 3,
          'best_streak': 8,
          'local_extension': ['local-proof'],
          'remote_extension': ['remote-proof'],
        });
      }
    },
  );

  for (final invalid in <Object?>[
    null,
    'not-json',
    '[]',
    '{"word":-1}',
    '{"word":1.5}',
    '{"word":"3"}',
    '{"":3}',
  ]) {
    test('invalid wrong-count payload remains blocked: $invalid', () {
      final result = AccountReconciliationMerger.merge(
        local: _snapshot({'wrong_count_json': ''}),
        remote: _snapshot({'wrong_count_json': invalid}),
        catalog: const {},
      );
      expect(result.merged, isNull);
      expect(
        result.conflicts.single.kind,
        AccountReconciliationConflictKind.documentField,
      );
    });
  }

  for (final invalid in <Map<String, Object?>>[
    {'last_open': '2026-02-30', 'streak_days': 1},
    {'last_open': '2026-2-01', 'streak_days': 1},
    {'last_open': null, 'streak_days': 0},
    {'last_open': '', 'streak_days': 3},
    {'last_open': '2026-10-30', 'streak_days': -1},
    {'last_open': '2026-10-30', 'streak_days': 1.5},
    {'last_open': '2026-10-30', 'streak_days': 1, 'best_streak': -1},
  ]) {
    test('invalid app date or streak remains blocked: $invalid', () {
      final result = AccountReconciliationMerger.merge(
        local: _snapshot({
          'app': {'last_open': '', 'streak_days': 0, 'best_streak': 0},
        }),
        remote: _snapshot({'app': invalid}),
        catalog: const {},
      );
      expect(result.merged, isNull);
      expect(
        result.conflicts.single.kind,
        AccountReconciliationConflictKind.documentField,
      );
    });
  }

  test(
    'known field names inside an unrelated map receive no compatibility override',
    () {
      final result = AccountReconciliationMerger.merge(
        local: _snapshot({
          'extension': {'wrong_count_json': ''},
        }),
        remote: _snapshot({
          'extension': {'wrong_count_json': '{"word":3}'},
        }),
        catalog: const {},
      );
      expect(result.merged, isNull);
      expect(
        result.conflicts.single.kind,
        AccountReconciliationConflictKind.documentField,
      );
    },
  );

  test(
    'unrecognized opaque JSON remains a conflict without discarding either side',
    () {
      final local = _snapshot({'unrecognized_json': '{"proof":"local"}'});
      final remote = _snapshot({'unrecognized_json': '{"proof":"remote"}'});

      final result = AccountReconciliationMerger.merge(
        local: local,
        remote: remote,
        catalog: const {},
      );

      expect(result.merged, isNull);
      expect(result.conflicts, const [
        AccountReconciliationConflict(
          kind: AccountReconciliationConflictKind.documentField,
          id: 'unrecognized_json',
        ),
      ]);
      expect(local.fields['unrecognized_json'], '{"proof":"local"}');
      expect(remote.fields['unrecognized_json'], '{"proof":"remote"}');
    },
  );
}
