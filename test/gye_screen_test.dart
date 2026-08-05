import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/gye_dedication.dart';
import 'package:ko_lernen_app/screens/gye_screen.dart';

GyeDedication _dedication(String uid, int slot) => GyeDedication.tryParse(uid, {
  'schemaVersion': 1,
  'uid': uid,
  'membershipId': 'membership-$uid',
  'decorationSlug': 'decoration_soban',
  'slotIndex': slot,
  'revision': 1,
  'lastOperationId': 'dedication-$uid-1',
})!;

void main() {
  test(
    'uses only the signed-in member exhibit for compare-and-set changes',
    () {
      final mine = _dedication('member-me', 2);
      expect(
        currentGyeDedicationFor([
          _dedication('member-other', 1),
          mine,
        ], 'member-me'),
        mine,
      );
      expect(currentGyeDedicationFor([mine], null), isNull);
    },
  );
}
