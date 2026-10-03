import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_connections.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';

void main() {
  RewardReceipt receipt(List<String?> ids) => RewardReceipt(
    activityId: 'test',
    receiptId: 'id',
    items: [
      for (final id in ids)
        RewardReceiptItem(
          kind: SoriRewardKind.stamp,
          amount: 1,
          identity: id,
          label: const SoriLocalizedCopy(de: 'Dojang', en: 'Dojang'),
        ),
    ],
  );
  test('receipt uses exactly one confirmed owned known identity', () {
    expect(confirmedOwnedReceiptMotif(receipt([null]), {'lotus'}), isNull);
    expect(
      confirmedOwnedReceiptMotif(receipt(['unknown']), {'unknown'}),
      isNull,
    );
    expect(confirmedOwnedReceiptMotif(receipt(['lotus']), {}), isNull);
    expect(confirmedOwnedReceiptMotif(receipt(['lotus']), {'lotus'}), 'lotus');
    expect(
      confirmedOwnedReceiptMotif(receipt(['lotus', 'moran']), {
        'lotus',
        'moran',
      }),
      isNull,
    );
  });
}
