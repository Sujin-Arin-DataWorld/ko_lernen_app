import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/decoration_reward_receipt.dart';

DecorationRewardReceipt _receipt(String id, {int xp = 123, bool ack = false}) =>
    DecorationRewardReceipt(
      id: id,
      sourceQuestId: 'pack:food_a1',
      decorationSlug: 'decoration_seoan',
      claimedAtUtc: DateTime.utc(2026, 10, 5),
      totalXp: xp,
      xpLevel: xp ~/ 100 + 1,
      xpToNext: 100 - xp % 100,
      yeopjeonBalance: 40,
      acknowledged: ack,
    );

void main() {
  group('DecorationRewardReceiptHistory', () {
    test('round-trips a frozen reward without financial mutation', () {
      final receipt = _receipt('one');
      final decoded = DecorationRewardReceiptHistory.decode(
        DecorationRewardReceiptHistory([receipt]).encode(),
      ).find('one')!;
      expect(decoded.hasSameReward(receipt), isTrue);
      expect(decoded.acknowledged, isFalse);
    });

    test('union retains pending receipts and durable acknowledgments', () {
      final local = DecorationRewardReceiptHistory([_receipt('local')]);
      final remote = DecorationRewardReceiptHistory([
        _receipt('local', ack: true),
        _receipt('remote'),
      ]);
      final once = DecorationRewardReceiptHistory.mergeJson(
        local.encode(),
        remote.encode(),
      );
      final twice = DecorationRewardReceiptHistory.mergeJson(
        once,
        local.encode(),
      );
      final merged = DecorationRewardReceiptHistory.decode(twice);
      expect(merged.receipts, hasLength(2));
      expect(merged.find('local')!.acknowledged, isTrue);
      expect(merged.pending!.id, 'remote');
      expect(twice, once);
    });

    test('same receipt ID with a different frozen reward is a conflict', () {
      expect(
        () => DecorationRewardReceiptHistory.mergeJson(
          DecorationRewardReceiptHistory([_receipt('same')]).encode(),
          DecorationRewardReceiptHistory([_receipt('same', xp: 124)]).encode(),
        ),
        throwsFormatException,
      );
    });

    test('rejects malformed snapshots and duplicate IDs', () {
      for (final replacement in <Map<String, Object?>>[
        {'totalXp': -1},
        {'xpLevel': 99},
        {'xpLevel': 2.0},
        {'xpToNext': 0},
        {'xpToNext': 77.0},
        {'yeopjeonBalance': -1},
        {'acknowledged': 'yes'},
        {'claimedAtUtc': '2026-10-05T00:00:00'},
      ]) {
        final value = {..._receipt('one').toJson(), ...replacement};
        expect(
          () => DecorationRewardReceiptHistory.decode(
            jsonEncode({
              'version': 1,
              'receipts': [value],
            }),
          ),
          throwsFormatException,
        );
      }
      expect(
        () =>
            DecorationRewardReceiptHistory([_receipt('one'), _receipt('one')]),
        throwsFormatException,
      );
    });

    test('preserves existing opaque source IDs', () {
      final json = {..._receipt('one').toJson(), 'sourceQuestId': 'pack:한글'};
      expect(DecorationRewardReceipt.fromJson(json).sourceQuestId, 'pack:한글');
    });
  });
}
