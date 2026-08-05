import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/data/gye_dedication_catalog.dart';
import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/models/gye_dedication.dart';
import 'package:ko_lernen_app/services/decoration_reward_service.dart';

const _membershipA = 'membership-a-0123456789';
const _membershipZ = 'membership-z-0123456789';

void main() {
  test('parses only a complete current-generation dedication', () {
    final dedication = GyeDedication.tryParse('member-a', {
      'schemaVersion': 1,
      'uid': 'member-a',
      'membershipId': _membershipA,
      'decorationSlug': 'decoration_soban',
      'slotIndex': 2,
      'revision': 4,
      'lastOperationId': 'dedication-a-4',
    });

    expect(dedication, isNotNull);
    expect(dedication!.slotIndex, 2);
    expect(dedication.revision, 4);
    expect(
      GyeDedication.tryParse('member-a', {
        'schemaVersion': 1,
        'uid': 'member-b',
        'membershipId': _membershipA,
        'decorationSlug': 'decoration_soban',
        'slotIndex': 2,
        'revision': 4,
        'lastOperationId': 'dedication-a-4',
      }),
      isNull,
    );
    expect(
      GyeDedication.tryParse('member-a', {
        'schemaVersion': 1,
        'uid': 'member-a',
        'membershipId': _membershipA,
        'decorationSlug': 'decoration_pond',
        'slotIndex': 2,
        'revision': 4,
        'lastOperationId': 'dedication-a-4',
      }),
      isNull,
    );
    expect(
      GyeDedication.tryParse('member-a', {
        'schemaVersion': 1,
        'uid': 'member-a',
        'membershipId': _membershipA,
        'decorationSlug': 'decoration_soban',
        'slotIndex': 2,
        // Revision zero means no active exhibit; it must never render as one.
        'revision': 0,
        'lastOperationId': 'dedication-a-0',
      }),
      isNull,
    );
    expect(
      GyeDedication.tryParse('member-a', {
        'schemaVersion': 1,
        'uid': 'member-a',
        'membershipId': 'legacy',
        'decorationSlug': 'decoration_soban',
        'slotIndex': 2,
        'revision': 4,
        'lastOperationId': 'dedication-a-4',
      }),
      isNull,
    );
  });

  test('parses a withdrawn tombstone without fabricating an exhibit', () {
    final tombstone = GyeDedication.tryParse('member-a', {
      'schemaVersion': 1,
      'uid': 'member-a',
      'membershipId': _membershipA,
      'state': 'withdrawn',
      'joinedAtSeconds': 1754355200,
      'joinedAtNanos': 123000000,
      'decorationSlug': null,
      'slotIndex': null,
      'revision': 4,
      'lastOperationId': 'dedication-a-4',
    });

    expect(tombstone, isNotNull);
    expect(tombstone!.isWithdrawn, isTrue);
    expect(tombstone.isActive, isFalse);
    expect(tombstone.decorationSlug, isNull);
    expect(tombstone.slotIndex, isNull);
    expect(tombstone.revision, 4);
    expect(
      GyeDedication.tryParse('member-a', {
        'schemaVersion': 1,
        'uid': 'member-a',
        'membershipId': _membershipA,
        'state': 'withdrawn',
        'decorationSlug': null,
        'slotIndex': null,
        // Revision one was the first active exhibit and cannot be a
        // monotonic withdrawal tombstone.
        'revision': 1,
        'lastOperationId': 'dedication-a-1',
      }),
      isNull,
    );
  });

  test(
    'requires an exact join epoch for explicit records but keeps legacy art renderable',
    () {
      final explicit = GyeDedication.tryParse('member-a', {
        'schemaVersion': 1,
        'uid': 'member-a',
        'membershipId': _membershipA,
        'state': 'active',
        'joinedAtSeconds': 1754355200,
        'joinedAtNanos': 123000000,
        'decorationSlug': 'decoration_soban',
        'slotIndex': 2,
        'revision': 4,
        'lastOperationId': 'dedication-a-4',
      });
      final legacy = GyeDedication.tryParse('member-a', {
        'schemaVersion': 1,
        'uid': 'member-a',
        'membershipId': _membershipA,
        'decorationSlug': 'decoration_soban',
        'slotIndex': 2,
        'revision': 4,
        'lastOperationId': 'dedication-a-4',
      });

      expect(
        explicit!.joinedAtEpoch,
        equals(GyeMembershipEpoch(seconds: 1754355200, nanoseconds: 123000000)),
      );
      expect(legacy!.joinedAtEpoch, isNull);
      expect(
        GyeDedication.tryParse('member-a', {
          'schemaVersion': 1,
          'uid': 'member-a',
          'membershipId': _membershipA,
          'state': 'active',
          'decorationSlug': 'decoration_soban',
          'slotIndex': 2,
          'revision': 4,
          'lastOperationId': 'dedication-a-4',
        }),
        isNull,
      );
      expect(
        GyeDedication.tryParse('member-a', {
          'schemaVersion': 1,
          'uid': 'member-a',
          'membershipId': _membershipA,
          'state': 'withdrawn',
          'joinedAtSeconds': 1754355200,
          'joinedAtNanos': 1000000000,
          'decorationSlug': null,
          'slotIndex': null,
          'revision': 4,
          'lastOperationId': 'dedication-a-4',
        }),
        isNull,
      );
    },
  );

  test('keeps the shared-exhibition allowlist equal to reward decorations', () {
    expect(kGyeDedicationSlugs, equals(kDecorationRewardPool.toSet()));
    expect(
      eligibleGyeDedicationSlugs({
        'decoration_soban',
        'decoration_pond',
        'unknown',
      }),
      equals({'decoration_soban'}),
    );
  });

  test('normalizes malformed duplicate slots deterministically', () {
    final laterUid = GyeDedication.tryParse('member-z', {
      'schemaVersion': 1,
      'uid': 'member-z',
      'membershipId': _membershipZ,
      'decorationSlug': 'decoration_soban',
      'slotIndex': 3,
      'revision': 1,
      'lastOperationId': 'z-1',
    })!;
    final earlierUid = GyeDedication.tryParse('member-a', {
      'schemaVersion': 1,
      'uid': 'member-a',
      'membershipId': _membershipA,
      'decorationSlug': 'decoration_seoan',
      'slotIndex': 3,
      'revision': 1,
      'lastOperationId': 'a-1',
    })!;

    expect(
      normalizeGyeDedications([laterUid, earlierUid]),
      equals([earlierUid]),
    );
  });
}
