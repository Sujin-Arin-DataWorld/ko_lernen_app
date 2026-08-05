import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/data/gye_dedication_catalog.dart';
import 'package:ko_lernen_app/models/gye_dedication.dart';
import 'package:ko_lernen_app/services/gye_dedication_service.dart';

const _membershipId = 'membership-a-0123456789';
const _joinedAtSeconds = 1754355200;
const _joinedAtNanos = 123000000;

void main() {
  test('forwards only a valid compare-and-set dedication request', () async {
    final gateway = _RecordingGateway();
    final service = GyeDedicationService(gateway);

    await service.setDedication(
      gyeId: 'ABC234',
      decorationSlug: 'decoration_soban',
      expectedRevision: 0,
      expectedMembershipId: _membershipId,
      expectedJoinedAtSeconds: _joinedAtSeconds,
      expectedJoinedAtNanos: _joinedAtNanos,
      operationId: 'dedication-abc234-0001',
    );

    expect(gateway.gyeId, 'ABC234');
    expect(gateway.decorationSlug, 'decoration_soban');
    expect(gateway.expectedRevision, 0);
    expect(gateway.expectedMembershipId, _membershipId);
    expect(gateway.expectedJoinedAtSeconds, _joinedAtSeconds);
    expect(gateway.expectedJoinedAtNanos, _joinedAtNanos);
    expect(gateway.operationId, 'dedication-abc234-0001');
  });

  test('rejects a non-reward decoration before calling the gateway', () async {
    final gateway = _RecordingGateway();
    final service = GyeDedicationService(gateway);

    await expectLater(
      service.setDedication(
        gyeId: 'ABC234',
        decorationSlug: 'decoration_pond',
        expectedRevision: 0,
        expectedMembershipId: _membershipId,
        expectedJoinedAtSeconds: _joinedAtSeconds,
        expectedJoinedAtNanos: _joinedAtNanos,
        operationId: 'dedication-abc234-0002',
      ),
      throwsA(isA<GyeDedicationClientFailure>()),
    );
    expect(gateway.calls, 0);
  });

  test('rejects an id outside the six-character Gye code alphabet', () async {
    final gateway = _RecordingGateway();
    final service = GyeDedicationService(gateway);

    await expectLater(
      service.setDedication(
        gyeId: 'ABC_23',
        decorationSlug: 'decoration_soban',
        expectedRevision: 0,
        expectedMembershipId: _membershipId,
        expectedJoinedAtSeconds: _joinedAtSeconds,
        expectedJoinedAtNanos: _joinedAtNanos,
        operationId: 'dedication-abc234-0003',
      ),
      throwsA(isA<GyeDedicationClientFailure>()),
    );
    expect(gateway.calls, 0);
  });

  test(
    'rejects an invalid membership epoch before calling the gateway',
    () async {
      final gateway = _RecordingGateway();
      final service = GyeDedicationService(gateway);

      await expectLater(
        service.setDedication(
          gyeId: 'ABC234',
          decorationSlug: 'decoration_soban',
          expectedRevision: 0,
          expectedMembershipId: _membershipId,
          expectedJoinedAtSeconds: _joinedAtSeconds,
          expectedJoinedAtNanos: 1000000000,
          operationId: 'dedication-abc234-epoch',
        ),
        throwsA(isA<GyeDedicationClientFailure>()),
      );
      expect(gateway.calls, 0);
    },
  );

  test('uses the active document revision for replacement and withdrawal', () {
    final current = GyeDedication.tryParse('member-a', {
      'schemaVersion': 1,
      'uid': 'member-a',
      'membershipId': _membershipId,
      'decorationSlug': 'decoration_soban',
      'slotIndex': 2,
      'revision': 7,
      'lastOperationId': 'dedication-a-7',
    })!;

    expect(
      GyeDedicationChange.fromCurrent(
        current: current,
        decorationSlug: 'decoration_seoan',
      ),
      const GyeDedicationChange(
        decorationSlug: 'decoration_seoan',
        expectedRevision: 7,
      ),
    );
    expect(
      GyeDedicationChange.fromCurrent(current: current, decorationSlug: null),
      const GyeDedicationChange(decorationSlug: null, expectedRevision: 7),
    );
    expect(
      GyeDedicationChange.fromCurrent(
        current: null,
        decorationSlug: 'decoration_soban',
      ),
      const GyeDedicationChange(
        decorationSlug: 'decoration_soban',
        expectedRevision: 0,
      ),
    );
    final tombstone = GyeDedication.tryParse('member-a', {
      'schemaVersion': 1,
      'uid': 'member-a',
      'membershipId': _membershipId,
      'state': 'withdrawn',
      'joinedAtSeconds': _joinedAtSeconds,
      'joinedAtNanos': _joinedAtNanos,
      'decorationSlug': null,
      'slotIndex': null,
      'revision': 8,
      'lastOperationId': 'dedication-a-8',
    })!;
    expect(
      GyeDedicationChange.fromCurrent(
        current: tombstone,
        decorationSlug: 'decoration_seoan',
      ),
      const GyeDedicationChange(
        decorationSlug: 'decoration_seoan',
        expectedRevision: 8,
      ),
    );
  });

  test(
    'keeps a withdrawn public record available for its next CAS revision',
    () {
      final records = parseGyeDedicationRecords([
        (
          documentId: 'member-active',
          source: <String, dynamic>{
            'schemaVersion': 1,
            'uid': 'member-active',
            'membershipId': 'membership-active-012345',
            'state': 'active',
            'joinedAtSeconds': _joinedAtSeconds,
            'joinedAtNanos': _joinedAtNanos,
            'decorationSlug': 'decoration_soban',
            'slotIndex': 2,
            'revision': 3,
            'lastOperationId': 'dedication-active-3',
          },
        ),
        (
          documentId: 'member-a',
          source: <String, dynamic>{
            'schemaVersion': 1,
            'uid': 'member-a',
            'membershipId': _membershipId,
            'state': 'withdrawn',
            'joinedAtSeconds': _joinedAtSeconds,
            'joinedAtNanos': _joinedAtNanos,
            'decorationSlug': null,
            'slotIndex': null,
            'revision': 4,
            'lastOperationId': 'dedication-a-4',
          },
        ),
      ]);

      final tombstone = records.singleWhere(
        (record) => record.uid == 'member-a',
      );
      expect(tombstone.isWithdrawn, isTrue);
      expect(normalizeGyeDedications(records), hasLength(1));
      expect(
        GyeDedicationChange.fromCurrent(
          current: tombstone,
          decorationSlug: 'decoration_seoan',
        ).expectedRevision,
        4,
      );
    },
  );

  test('rejects a malformed withdrawal response from the callable', () async {
    final gateway = FirebaseGyeDedicationGateway(
      ({
        required callableName,
        required payload,
        required callableOptions,
      }) async => <String, Object?>{
        'state': 'withdrawn',
        'revision': 0,
        // An active slot/slug conflicts with a withdrawal wire shape.
        'slotIndex': 2,
        'decorationSlug': 'decoration_soban',
      },
    );

    await expectLater(
      gateway.setDedication(
        gyeId: 'ABC234',
        decorationSlug: null,
        expectedRevision: 1,
        expectedMembershipId: _membershipId,
        expectedJoinedAtSeconds: _joinedAtSeconds,
        expectedJoinedAtNanos: _joinedAtNanos,
        operationId: 'dedication-abc234-0004',
      ),
      throwsA(isA<GyeDedicationClientFailure>()),
    );
  });

  test('accepts a monotonic withdrawn callable response', () async {
    final gateway = FirebaseGyeDedicationGateway(
      ({
        required callableName,
        required payload,
        required callableOptions,
      }) async => <String, Object?>{
        'state': 'withdrawn',
        'revision': 4,
        'slotIndex': null,
        'decorationSlug': null,
      },
    );

    final result = await gateway.setDedication(
      gyeId: 'ABC234',
      decorationSlug: null,
      expectedRevision: 3,
      expectedMembershipId: _membershipId,
      expectedJoinedAtSeconds: _joinedAtSeconds,
      expectedJoinedAtNanos: _joinedAtNanos,
      operationId: 'dedication-abc234-0004b',
    );

    expect(result.state, GyeDedicationMutationState.withdrawn);
    expect(result.revision, 4);
    expect(result.slotIndex, isNull);
    expect(result.decorationSlug, isNull);
  });

  test('rejects a zero-revision withdrawn callable response', () async {
    final gateway = FirebaseGyeDedicationGateway(
      ({
        required callableName,
        required payload,
        required callableOptions,
      }) async => <String, Object?>{
        'state': 'withdrawn',
        'revision': 0,
        'slotIndex': null,
        'decorationSlug': null,
      },
    );

    await expectLater(
      gateway.setDedication(
        gyeId: 'ABC234',
        decorationSlug: null,
        expectedRevision: 3,
        expectedMembershipId: _membershipId,
        expectedJoinedAtSeconds: _joinedAtSeconds,
        expectedJoinedAtNanos: _joinedAtNanos,
        operationId: 'dedication-abc234-0004c',
      ),
      throwsA(isA<GyeDedicationClientFailure>()),
    );
  });

  test(
    'production gateway targets the regional dedication callable with a limited-use App Check token',
    () async {
      String? selectedRegion;
      String? invokedCallable;
      Map<String, Object?>? invokedPayload;
      HttpsCallableOptions? invokedOptions;

      final gateway = FirebaseGyeDedicationGateway.production(
        invokerForRegion: (region) {
          selectedRegion = region;
          return ({
            required callableName,
            required payload,
            required callableOptions,
          }) async {
            invokedCallable = callableName;
            invokedPayload = payload;
            invokedOptions = callableOptions;
            return <String, Object?>{
              'state': 'dedicated',
              'revision': 1,
              'slotIndex': 2,
              'decorationSlug': 'decoration_soban',
            };
          };
        },
      );

      await gateway.setDedication(
        gyeId: 'ABC234',
        decorationSlug: 'decoration_soban',
        expectedRevision: 0,
        expectedMembershipId: _membershipId,
        expectedJoinedAtSeconds: _joinedAtSeconds,
        expectedJoinedAtNanos: _joinedAtNanos,
        operationId: 'dedication-abc234-0005',
      );

      expect(selectedRegion, 'europe-west3');
      expect(invokedCallable, 'setGyeDecorationDedication');
      expect(invokedPayload, <String, Object?>{
        'gyeId': 'ABC234',
        'decorationSlug': 'decoration_soban',
        'expectedRevision': 0,
        'expectedMembershipId': _membershipId,
        'expectedJoinedAtSeconds': _joinedAtSeconds,
        'expectedJoinedAtNanos': _joinedAtNanos,
        'operationId': 'dedication-abc234-0005',
      });
      expect(invokedOptions?.limitedUseAppCheckToken, isTrue);
    },
  );
}

class _RecordingGateway implements GyeDedicationGateway {
  int calls = 0;
  String? gyeId;
  String? decorationSlug;
  int? expectedRevision;
  String? expectedMembershipId;
  int? expectedJoinedAtSeconds;
  int? expectedJoinedAtNanos;
  String? operationId;

  @override
  Future<GyeDedicationMutation> setDedication({
    required String gyeId,
    required String? decorationSlug,
    required int expectedRevision,
    required String expectedMembershipId,
    required int expectedJoinedAtSeconds,
    required int expectedJoinedAtNanos,
    required String operationId,
  }) async {
    calls += 1;
    this.gyeId = gyeId;
    this.decorationSlug = decorationSlug;
    this.expectedRevision = expectedRevision;
    this.expectedMembershipId = expectedMembershipId;
    this.expectedJoinedAtSeconds = expectedJoinedAtSeconds;
    this.expectedJoinedAtNanos = expectedJoinedAtNanos;
    this.operationId = operationId;
    return const GyeDedicationMutation(
      state: GyeDedicationMutationState.dedicated,
      revision: 1,
      slotIndex: 0,
      decorationSlug: 'decoration_soban',
    );
  }
}
