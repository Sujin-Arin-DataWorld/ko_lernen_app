import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../data/gye_dedication_catalog.dart';
import '../models/gye_dedication.dart';
import 'account/cloud_write_session.dart';
import 'auth_service.dart';
import 'gye_service.dart';

enum GyeDedicationMutationState { dedicated, withdrawn, unchanged }

class GyeDedicationMutation {
  const GyeDedicationMutation({
    required this.state,
    required this.revision,
    this.slotIndex,
    this.decorationSlug,
  });

  final GyeDedicationMutationState state;
  final int revision;
  final int? slotIndex;
  final String? decorationSlug;
}

/// The compare-and-set input derived from the public exhibit snapshot.
///
/// A withdrawn exhibit has no public document, so a later first dedication
/// always starts at revision zero. Active documents provide their own current
/// revision and are the only source used for replacements or withdrawal.
class GyeDedicationChange {
  const GyeDedicationChange({
    required this.decorationSlug,
    required this.expectedRevision,
  });

  factory GyeDedicationChange.fromCurrent({
    required GyeDedication? current,
    required String? decorationSlug,
  }) => GyeDedicationChange(
    decorationSlug: decorationSlug,
    expectedRevision: current?.revision ?? 0,
  );

  final String? decorationSlug;
  final int expectedRevision;

  @override
  bool operator ==(Object other) =>
      other is GyeDedicationChange &&
      other.decorationSlug == decorationSlug &&
      other.expectedRevision == expectedRevision;

  @override
  int get hashCode => Object.hash(decorationSlug, expectedRevision);
}

enum GyeDedicationFailureCategory {
  invalidRequest,
  authenticationRequired,
  permissionDenied,
  conflict,
  rateLimited,
  unavailable,
  unknown,
}

class GyeDedicationClientFailure implements Exception {
  const GyeDedicationClientFailure(this.category, {required this.retryable});

  final GyeDedicationFailureCategory category;
  final bool retryable;

  @override
  String toString() => 'Gye dedication failed (${category.name}).';
}

abstract interface class GyeDedicationGateway {
  Future<GyeDedicationMutation> setDedication({
    required String gyeId,
    required String? decorationSlug,
    required int expectedRevision,
    required String operationId,
  });
}

typedef GyeDedicationCallableInvoker =
    Future<Object?> Function({
      required String callableName,
      required Map<String, Object?> payload,
      required HttpsCallableOptions callableOptions,
    });

class FirebaseGyeDedicationGateway implements GyeDedicationGateway {
  FirebaseGyeDedicationGateway(this._invoke);

  factory FirebaseGyeDedicationGateway.production() {
    return FirebaseGyeDedicationGateway(({
      required callableName,
      required payload,
      required callableOptions,
    }) async {
      final functions = FirebaseFunctions.instanceFor(region: _functionRegion);
      final result = await functions
          .httpsCallable(callableName, options: callableOptions)
          .call<Object?>(payload);
      return result.data;
    });
  }

  static const String _functionRegion = 'europe-west3';
  static const String callableName = 'setGyeDecorationDedication';

  final GyeDedicationCallableInvoker _invoke;

  @override
  Future<GyeDedicationMutation> setDedication({
    required String gyeId,
    required String? decorationSlug,
    required int expectedRevision,
    required String operationId,
  }) async {
    Object? raw;
    try {
      raw = await _invoke(
        callableName: callableName,
        payload: <String, Object?>{
          'gyeId': gyeId,
          'decorationSlug': decorationSlug,
          'expectedRevision': expectedRevision,
          'operationId': operationId,
        },
        callableOptions: HttpsCallableOptions(limitedUseAppCheckToken: true),
      );
    } on FirebaseFunctionsException catch (error) {
      throw _firebaseFailure(error.code);
    } on GyeDedicationClientFailure {
      rethrow;
    } catch (_) {
      throw const GyeDedicationClientFailure(
        GyeDedicationFailureCategory.unknown,
        retryable: true,
      );
    }
    return _parseMutation(raw);
  }
}

class GyeDedicationService {
  GyeDedicationService(this._gateway);

  factory GyeDedicationService.production() =>
      GyeDedicationService(FirebaseGyeDedicationGateway.production());

  final GyeDedicationGateway _gateway;

  static final math.Random _random = math.Random.secure();

  Future<GyeDedicationMutation> setDedication({
    required String gyeId,
    required String? decorationSlug,
    required int expectedRevision,
    required String operationId,
  }) {
    if (!_validGyeId(gyeId) ||
        (decorationSlug != null &&
            !kGyeDedicationSlugs.contains(decorationSlug)) ||
        expectedRevision < 0 ||
        expectedRevision > 1000000000 ||
        !_validOperationId(operationId)) {
      return Future<GyeDedicationMutation>.error(
        const GyeDedicationClientFailure(
          GyeDedicationFailureCategory.invalidRequest,
          retryable: false,
        ),
      );
    }
    return _gateway.setDedication(
      gyeId: gyeId,
      decorationSlug: decorationSlug,
      expectedRevision: expectedRevision,
      operationId: operationId,
    );
  }

  /// Performs the mutation only while the current authenticated cloud-write
  /// session remains valid. The UI itself still waits for the Firestore stream
  /// before showing a new exhibit.
  Future<GyeDedicationMutation> setForCurrentSession({
    required String gyeId,
    required String? decorationSlug,
    required int expectedRevision,
    required String operationId,
  }) async {
    final uid = AuthService.current?.uid;
    if (uid == null || uid.isEmpty) {
      throw const GyeDedicationClientFailure(
        GyeDedicationFailureCategory.authenticationRequired,
        retryable: false,
      );
    }
    final session = CloudWriteFence(
      cloudWriteSessionController,
    ).readySnapshot(uid);
    if (session == null) {
      throw const GyeDedicationClientFailure(
        GyeDedicationFailureCategory.unavailable,
        retryable: true,
      );
    }
    late GyeDedicationMutation mutation;
    final write = await GyeService.writeWithSession(
      sessions: cloudWriteSessionController,
      uid: uid,
      snapshot: session,
      write: () async {
        mutation = await setDedication(
          gyeId: gyeId,
          decorationSlug: decorationSlug,
          expectedRevision: expectedRevision,
          operationId: operationId,
        );
      },
    );
    if (write != CloudWriteResult.completed) {
      throw const GyeDedicationClientFailure(
        GyeDedicationFailureCategory.unavailable,
        retryable: true,
      );
    }
    return mutation;
  }

  static String newOperationId() {
    final suffix = List<int>.generate(
      10,
      (_) => _random.nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return 'dedication-${DateTime.now().microsecondsSinceEpoch}-$suffix';
  }

  static Stream<List<GyeDedication>> streamForGye(String gyeId) {
    final uid = AuthService.current?.uid;
    FirebaseFirestore? firestore;
    try {
      firestore = FirebaseFirestore.instance;
    } catch (_) {
      firestore = null;
    }
    if (uid == null ||
        uid.isEmpty ||
        firestore == null ||
        !_validGyeId(gyeId)) {
      return Stream<List<GyeDedication>>.value(const <GyeDedication>[]);
    }
    return GyeService.streamWithSession(
      sessions: cloudWriteSessionController,
      uid: uid,
      source: firestore
          .collection('gye')
          .doc(gyeId)
          .collection('decor_dedications')
          .snapshots()
          .map(
            (snapshot) => normalizeGyeDedications(
              snapshot.docs
                  .map(
                    (document) =>
                        GyeDedication.tryParse(document.id, document.data()),
                  )
                  .whereType<GyeDedication>(),
            ),
          ),
    );
  }
}

GyeDedicationMutation _parseMutation(Object? raw) {
  if (raw is! Map) {
    throw const GyeDedicationClientFailure(
      GyeDedicationFailureCategory.unknown,
      retryable: true,
    );
  }
  final state = raw['state'];
  final revision = raw['revision'];
  final slotIndex = raw['slotIndex'];
  final decorationSlug = raw['decorationSlug'];
  if (state is! String || revision is! int || revision < 0) {
    throw const GyeDedicationClientFailure(
      GyeDedicationFailureCategory.unknown,
      retryable: true,
    );
  }
  final activeExhibit =
      slotIndex is int &&
      slotIndex >= 0 &&
      slotIndex < GyeDedication.maxSlots &&
      decorationSlug is String &&
      kGyeDedicationSlugs.contains(decorationSlug) &&
      revision >= 1;
  final noExhibit =
      slotIndex == null && decorationSlug == null && revision == 0;
  return switch (state) {
    'dedicated' when activeExhibit => GyeDedicationMutation(
      state: GyeDedicationMutationState.dedicated,
      revision: revision,
      slotIndex: slotIndex,
      decorationSlug: decorationSlug,
    ),
    'withdrawn' when noExhibit => GyeDedicationMutation(
      state: GyeDedicationMutationState.withdrawn,
      revision: revision,
    ),
    'unchanged' when activeExhibit || noExhibit => GyeDedicationMutation(
      state: GyeDedicationMutationState.unchanged,
      revision: revision,
      slotIndex: activeExhibit ? slotIndex : null,
      decorationSlug: activeExhibit ? decorationSlug : null,
    ),
    _ => throw const GyeDedicationClientFailure(
      GyeDedicationFailureCategory.unknown,
      retryable: true,
    ),
  };
}

GyeDedicationClientFailure _firebaseFailure(String code) => switch (code) {
  'invalid-argument' => const GyeDedicationClientFailure(
    GyeDedicationFailureCategory.invalidRequest,
    retryable: false,
  ),
  'unauthenticated' => const GyeDedicationClientFailure(
    GyeDedicationFailureCategory.authenticationRequired,
    retryable: false,
  ),
  'permission-denied' => const GyeDedicationClientFailure(
    GyeDedicationFailureCategory.permissionDenied,
    retryable: false,
  ),
  'aborted' => const GyeDedicationClientFailure(
    GyeDedicationFailureCategory.conflict,
    retryable: true,
  ),
  'resource-exhausted' => const GyeDedicationClientFailure(
    GyeDedicationFailureCategory.rateLimited,
    retryable: true,
  ),
  'unavailable' => const GyeDedicationClientFailure(
    GyeDedicationFailureCategory.unavailable,
    retryable: true,
  ),
  _ => const GyeDedicationClientFailure(
    GyeDedicationFailureCategory.unknown,
    retryable: true,
  ),
};

bool _validGyeId(String value) => GyeService.isValidCodeFormat(value);

bool _validOperationId(String value) =>
    RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{7,127}$').hasMatch(value);
