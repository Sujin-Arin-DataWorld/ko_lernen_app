import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/gye.dart';

void main() {
  test('preserves an authoritative Firestore join timestamp exactly', () {
    final epoch = GyeMembershipEpoch.tryParse(Timestamp(1754355200, 123000001));

    expect(epoch, isNotNull);
    expect(epoch!.seconds, 1754355200);
    expect(epoch.nanoseconds, 123000001);
    expect(
      epoch,
      equals(GyeMembershipEpoch(seconds: 1754355200, nanoseconds: 123000001)),
    );
    expect(
      epoch,
      isNot(
        equals(GyeMembershipEpoch(seconds: 1754355200, nanoseconds: 123000002)),
      ),
    );
  });

  test('accepts only strict server-compatible timestamp parts', () {
    expect(GyeMembershipEpoch.isValidParts(0, 0), isTrue);
    expect(GyeMembershipEpoch.isValidParts(1754355200, 999999999), isTrue);
    expect(GyeMembershipEpoch.isValidParts(-1, 0), isFalse);
    expect(GyeMembershipEpoch.isValidParts(1754355200, -1), isFalse);
    expect(GyeMembershipEpoch.isValidParts(1754355200, 1000000000), isFalse);
    expect(GyeMembershipEpoch.isValidParts(9007199254740992, 0), isFalse);
    expect(
      () => GyeMembershipEpoch(seconds: -1, nanoseconds: 0),
      throwsArgumentError,
    );
  });

  test('member parsing exposes only an exact Firestore join epoch', () {
    final joinedAt = Timestamp(1754355200, 987654321);
    final member = GyeMember.fromDoc('member-a', {
      'membershipId': 'membership-a-0123456789',
      'nickname': 'Mina',
      'joinedAt': joinedAt,
      'status': 'active',
    });
    final legacy = GyeMember.fromDoc('member-a', {
      'membershipId': 'membership-a-0123456789',
      'nickname': 'Mina',
      'joinedAt': '2025-08-05T00:00:00.000Z',
      'status': 'active',
    });

    expect(
      member.joinedAtEpoch,
      equals(GyeMembershipEpoch(seconds: 1754355200, nanoseconds: 987654321)),
    );
    expect(legacy.joinedAtEpoch, isNull);
  });
}
