import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/gye_service.dart';

void main() {
  test(
    'current member stream exposes only an active current membership epoch',
    () async {
      final sessions = CloudWriteSessionController();
      sessions.acquire('member-a');
      final active = GyeMember(
        uid: 'member-a',
        nickname: 'Mina',
        membershipId: 'membership-a-0123456789',
        joinedAtEpoch: GyeMembershipEpoch(
          seconds: 1754355200,
          nanoseconds: 123000000,
        ),
      );

      final values = await GyeService.currentMemberStreamForSession(
        sessions: sessions,
        uid: 'member-a',
        source: Stream<GyeMember?>.fromIterable([
          active,
          const GyeMember(
            uid: 'member-a',
            nickname: 'Mina',
            membershipId: 'membership-a-0123456789',
          ),
          const GyeMember(
            uid: 'member-a',
            nickname: 'Mina',
            membershipId: 'legacy',
          ),
        ]),
      ).toList();

      expect(values, [active, null, null]);
    },
  );
}
