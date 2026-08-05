import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/models/gye_dedication.dart';
import 'package:ko_lernen_app/screens/gye_screen.dart';

final _epochOne = GyeMembershipEpoch(
  seconds: 1754355200,
  nanoseconds: 123000000,
);
final _epochTwo = GyeMembershipEpoch(
  seconds: 1754355260,
  nanoseconds: 456000000,
);

GyeDedication _dedication(
  String uid,
  int slot, {
  String? membershipId,
  GyeMembershipEpoch? joinedAtEpoch,
}) => GyeDedication.tryParse(uid, {
  'schemaVersion': 1,
  'uid': uid,
  'membershipId': membershipId ?? 'membership-$uid-0123456789',
  'state': 'active',
  'joinedAtSeconds': (joinedAtEpoch ?? _epochOne).seconds,
  'joinedAtNanos': (joinedAtEpoch ?? _epochOne).nanoseconds,
  'decorationSlug': 'decoration_soban',
  'slotIndex': slot,
  'revision': 1,
  'lastOperationId': 'dedication-$uid-1',
})!;

GyeDedication _tombstone(
  String uid,
  String membershipId, {
  GyeMembershipEpoch? joinedAtEpoch,
}) => GyeDedication.tryParse(uid, {
  'schemaVersion': 1,
  'uid': uid,
  'membershipId': membershipId,
  'state': 'withdrawn',
  'joinedAtSeconds': (joinedAtEpoch ?? _epochOne).seconds,
  'joinedAtNanos': (joinedAtEpoch ?? _epochOne).nanoseconds,
  'decorationSlug': null,
  'slotIndex': null,
  'revision': 4,
  'lastOperationId': 'dedication-$uid-4',
})!;

void main() {
  test(
    'uses only the signed-in member exhibit for compare-and-set changes',
    () {
      final mine = _dedication('member-me', 2);
      expect(
        currentGyeDedicationFor(
          [_dedication('member-other', 1), mine],
          'member-me',
          mine.membershipId,
          _epochOne,
        ),
        mine,
      );
      expect(
        currentGyeDedicationFor([mine], null, mine.membershipId, _epochOne),
        isNull,
      );
    },
  );

  test('retains only the current membership epoch tombstone for CAS', () {
    const oldMembership = 'membership-me-old-012345';
    const currentMembership = 'membership-me-new-012345';
    final oldTombstone = _tombstone('member-me', oldMembership);
    final currentTombstone = _tombstone('member-me', currentMembership);

    expect(
      currentGyeDedicationFor(
        [oldTombstone, currentTombstone],
        'member-me',
        currentMembership,
        _epochOne,
      ),
      currentTombstone,
    );
    expect(
      currentGyeDedicationFor(
        [oldTombstone],
        'member-me',
        currentMembership,
        _epochOne,
      ),
      isNull,
    );
  });

  test('same membership id cannot revive a prior joined-at generation', () {
    const membershipId = 'membership-me-reused-012345';
    final stale = _dedication(
      'member-me',
      1,
      membershipId: membershipId,
      joinedAtEpoch: _epochOne,
    );
    final current = _dedication(
      'member-me',
      2,
      membershipId: membershipId,
      joinedAtEpoch: _epochTwo,
    );
    final legacy = GyeDedication.tryParse('member-me', {
      'schemaVersion': 1,
      'uid': 'member-me',
      'membershipId': membershipId,
      'decorationSlug': 'decoration_seoan',
      'slotIndex': 3,
      'revision': 1,
      'lastOperationId': 'dedication-me-legacy',
    })!;

    expect(
      currentGyeDedicationFor(
        [stale, current],
        'member-me',
        membershipId,
        _epochTwo,
      ),
      current,
    );
    expect(
      currentGyeDedicationFor(
        [stale, legacy],
        'member-me',
        membershipId,
        _epochTwo,
      ),
      isNull,
    );
  });
}
