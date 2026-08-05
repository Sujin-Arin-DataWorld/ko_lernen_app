import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/data/gye_dedication_catalog.dart';
import 'package:ko_lernen_app/models/gye_dedication.dart';
import 'package:ko_lernen_app/services/decoration_reward_service.dart';

void main() {
  test('parses only a complete current-generation dedication', () {
    final dedication = GyeDedication.tryParse('member-a', {
      'schemaVersion': 1,
      'uid': 'member-a',
      'membershipId': 'membership-a',
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
        'membershipId': 'membership-a',
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
        'membershipId': 'membership-a',
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
        'membershipId': 'membership-a',
        'decorationSlug': 'decoration_soban',
        'slotIndex': 2,
        // Revision zero means no active exhibit; it must never render as one.
        'revision': 0,
        'lastOperationId': 'dedication-a-0',
      }),
      isNull,
    );
  });

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
      'membershipId': 'membership-z',
      'decorationSlug': 'decoration_soban',
      'slotIndex': 3,
      'revision': 1,
      'lastOperationId': 'z-1',
    })!;
    final earlierUid = GyeDedication.tryParse('member-a', {
      'schemaVersion': 1,
      'uid': 'member-a',
      'membershipId': 'membership-a',
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
