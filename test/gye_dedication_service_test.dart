import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/gye_dedication.dart';
import 'package:ko_lernen_app/services/gye_dedication_service.dart';

void main() {
  test('forwards only a valid compare-and-set dedication request', () async {
    final gateway = _RecordingGateway();
    final service = GyeDedicationService(gateway);

    await service.setDedication(
      gyeId: 'ABC234',
      decorationSlug: 'decoration_soban',
      expectedRevision: 0,
      operationId: 'dedication-abc234-0001',
    );

    expect(gateway.gyeId, 'ABC234');
    expect(gateway.decorationSlug, 'decoration_soban');
    expect(gateway.expectedRevision, 0);
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
        operationId: 'dedication-abc234-0003',
      ),
      throwsA(isA<GyeDedicationClientFailure>()),
    );
    expect(gateway.calls, 0);
  });

  test('uses the active document revision for replacement and withdrawal', () {
    final current = GyeDedication.tryParse('member-a', {
      'schemaVersion': 1,
      'uid': 'member-a',
      'membershipId': 'membership-a',
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
  });
}

class _RecordingGateway implements GyeDedicationGateway {
  int calls = 0;
  String? gyeId;
  String? decorationSlug;
  int? expectedRevision;
  String? operationId;

  @override
  Future<GyeDedicationMutation> setDedication({
    required String gyeId,
    required String? decorationSlug,
    required int expectedRevision,
    required String operationId,
  }) async {
    calls += 1;
    this.gyeId = gyeId;
    this.decorationSlug = decorationSlug;
    this.expectedRevision = expectedRevision;
    this.operationId = operationId;
    return const GyeDedicationMutation(
      state: GyeDedicationMutationState.dedicated,
      revision: 1,
      slotIndex: 0,
      decorationSlug: 'decoration_soban',
    );
  }
}
