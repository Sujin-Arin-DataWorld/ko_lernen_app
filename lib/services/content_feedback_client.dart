import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../data/beta_mission_catalog.dart';
import '../models/content_feedback.dart';

enum ContentFeedbackAcknowledgement { accepted, duplicateCompletion }

class ContentFeedbackDelivery {
  const ContentFeedbackDelivery({
    required this.acknowledgement,
    this.passportStateAuthoritative = false,
    this.stampAccepted = false,
    this.passportCompletedMissionIds = const <String>{},
    this.nextMissionId,
  });

  final ContentFeedbackAcknowledgement acknowledgement;
  final bool passportStateAuthoritative;
  final bool stampAccepted;
  final Set<String> passportCompletedMissionIds;
  final String? nextMissionId;
}

enum ContentFeedbackFailureCategory {
  invalidRequest,
  authenticationRequired,
  permissionDenied,
  rateLimited,
  unavailable,
  storageUnavailable,
  unknown,
}

class ContentFeedbackClientFailure implements Exception {
  const ContentFeedbackClientFailure(this.category, {required this.retryable});

  final ContentFeedbackFailureCategory category;
  final bool retryable;

  @override
  String toString() => 'Feedback submission failed (${category.name}).';
}

abstract interface class ContentFeedbackClient {
  Future<ContentFeedbackDelivery> submit(ContentFeedbackSubmission submission);
}

typedef ContentFeedbackPassportDocumentReader =
    Future<Object?> Function({
      required String ownerUid,
      required String collectionId,
      required String documentId,
    });

class ContentFeedbackPassportReader {
  const ContentFeedbackPassportReader({
    required this.currentUid,
    required this.readDocument,
  });

  factory ContentFeedbackPassportReader.firebase({
    required String? Function() currentUid,
  }) {
    return ContentFeedbackPassportReader(
      currentUid: currentUid,
      readDocument:
          ({
            required ownerUid,
            required collectionId,
            required documentId,
          }) async {
            final snapshot = await FirebaseFirestore.instance
                .collection('users')
                .doc(ownerUid)
                .collection(collectionId)
                .doc(documentId)
                .get();
            return snapshot.data();
          },
    );
  }

  final String? Function() currentUid;
  final ContentFeedbackPassportDocumentReader readDocument;

  Future<Set<String>> readCompletedMissionIds() async {
    final ownerUid = _safeCurrentUid();
    if (ownerUid == null) return const <String>{};

    Object? raw;
    try {
      raw = await readDocument(
        ownerUid: ownerUid,
        collectionId: 'tester_passport',
        documentId: 'state',
      );
    } catch (_) {
      return const <String>{};
    }
    if (_safeCurrentUid() != ownerUid || raw is! Map) {
      return const <String>{};
    }
    if (raw['catalogVersion'] != betaMissionCatalogVersion) {
      return const <String>{};
    }
    final completed = _parseCompletedMissionIds(raw['completedMissionIds']);
    return completed.isAuthoritative ? completed.missionIds : const <String>{};
  }

  String? _safeCurrentUid() {
    try {
      final raw = currentUid();
      final value = raw?.trim();
      if (raw == null ||
          value == null ||
          value.isEmpty ||
          value != raw ||
          value.length > 128 ||
          value.contains('/')) {
        return null;
      }
      return value;
    } catch (_) {
      return null;
    }
  }
}

typedef ContentFeedbackCallableInvoker =
    Future<Object?> Function({
      required String callableName,
      required Map<String, Object?> payload,
      required HttpsCallableOptions callableOptions,
    });

class ContentFeedbackCallableClient implements ContentFeedbackClient {
  ContentFeedbackCallableClient(this._invoke);

  factory ContentFeedbackCallableClient.firebase() {
    return ContentFeedbackCallableClient(({
      required callableName,
      required payload,
      required callableOptions,
    }) async {
      final functions = FirebaseFunctions.instanceFor(region: region);
      final result = await functions
          .httpsCallable(callableName, options: callableOptions)
          .call<Object?>(payload);
      return result.data;
    });
  }

  static const String region = 'europe-west3';
  static const String callableName = 'submitTesterFeedback';

  final ContentFeedbackCallableInvoker _invoke;

  @override
  Future<ContentFeedbackDelivery> submit(
    ContentFeedbackSubmission submission,
  ) async {
    final validation = submission.validate();
    if (!validation.isValid) {
      throw const ContentFeedbackClientFailure(
        ContentFeedbackFailureCategory.invalidRequest,
        retryable: false,
      );
    }

    Object? raw;
    try {
      raw = await _invoke(
        callableName: callableName,
        payload: submission.toWire(),
        callableOptions: HttpsCallableOptions(limitedUseAppCheckToken: true),
      );
    } on FirebaseFunctionsException catch (error) {
      throw _safeFailureForFirebaseCode(error.code);
    } on ContentFeedbackClientFailure {
      rethrow;
    } catch (_) {
      throw const ContentFeedbackClientFailure(
        ContentFeedbackFailureCategory.unknown,
        retryable: true,
      );
    }

    if (raw is! Map) {
      throw const ContentFeedbackClientFailure(
        ContentFeedbackFailureCategory.unknown,
        retryable: true,
      );
    }
    final accepted = raw['accepted'];
    final duplicate = raw['duplicate'];
    final ContentFeedbackAcknowledgement acknowledgement;
    if (accepted == true && duplicate == false) {
      acknowledgement = ContentFeedbackAcknowledgement.accepted;
    } else if (accepted == false && duplicate == true) {
      acknowledgement = ContentFeedbackAcknowledgement.duplicateCompletion;
    } else {
      throw const ContentFeedbackClientFailure(
        ContentFeedbackFailureCategory.unknown,
        retryable: true,
      );
    }

    final passport = _parsePassportResponse(
      raw: raw,
      acknowledgement: acknowledgement,
      submission: submission,
    );
    return ContentFeedbackDelivery(
      acknowledgement: acknowledgement,
      passportStateAuthoritative: passport.isAuthoritative,
      stampAccepted: passport.stampAccepted,
      passportCompletedMissionIds: passport.missionIds,
      nextMissionId: passport.nextMissionId,
    );
  }
}

typedef _ParsedPassport = ({
  bool isAuthoritative,
  bool stampAccepted,
  Set<String> missionIds,
  String? nextMissionId,
});

const _emptyPassport = (
  isAuthoritative: false,
  stampAccepted: false,
  missionIds: <String>{},
  nextMissionId: null,
);

_ParsedPassport _parsePassportResponse({
  required Map<dynamic, dynamic> raw,
  required ContentFeedbackAcknowledgement acknowledgement,
  required ContentFeedbackSubmission submission,
}) {
  final rawStampAccepted = raw['stampAccepted'];
  if (rawStampAccepted is! bool) return _emptyPassport;

  final completed = _parseCompletedMissionIds(
    raw['passportCompletedMissionIds'],
  );
  if (!completed.isAuthoritative) return _emptyPassport;

  final next = _firstIncompleteMission(completed.missionIds);
  if (raw['nextMissionId'] != next?.id ||
      raw['nextMissionLabelKey'] != next?.labelKey) {
    return _emptyPassport;
  }

  if (acknowledgement == ContentFeedbackAcknowledgement.duplicateCompletion) {
    if (rawStampAccepted) return _emptyPassport;
  } else if (!_stampMatchesSubmission(
    stampAccepted: rawStampAccepted,
    completedMissionIds: completed.missionIds,
    submission: submission,
  )) {
    return _emptyPassport;
  }

  return (
    isAuthoritative: true,
    stampAccepted: rawStampAccepted,
    missionIds: completed.missionIds,
    nextMissionId: next?.id,
  );
}

bool _stampMatchesSubmission({
  required bool stampAccepted,
  required Set<String> completedMissionIds,
  required ContentFeedbackSubmission submission,
}) {
  final submittedMissionId = submission.betaMissionId;
  final matchingMission = missionFor(submission.context);
  final submissionMatchesMission =
      submittedMissionId != null && matchingMission?.id == submittedMissionId;
  if (stampAccepted) {
    return submissionMatchesMission &&
        completedMissionIds.contains(submittedMissionId);
  }
  return !submissionMatchesMission ||
      completedMissionIds.contains(submittedMissionId);
}

({Set<String> missionIds, bool isAuthoritative}) _parseCompletedMissionIds(
  Object? raw,
) {
  if (raw is! List) {
    return (missionIds: const <String>{}, isAuthoritative: false);
  }
  final result = <String>{};
  var previousCatalogIndex = -1;
  for (final value in raw) {
    if (value is! String) {
      return (missionIds: const <String>{}, isAuthoritative: false);
    }
    final catalogIndex = betaMissionCatalog.indexWhere(
      (mission) => mission.id == value,
    );
    if (catalogIndex <= previousCatalogIndex) {
      return (missionIds: const <String>{}, isAuthoritative: false);
    }
    previousCatalogIndex = catalogIndex;
    result.add(value);
  }
  return (missionIds: Set.unmodifiable(result), isAuthoritative: true);
}

BetaMission? _firstIncompleteMission(Set<String> completedMissionIds) {
  for (final mission in betaMissionCatalog) {
    if (!completedMissionIds.contains(mission.id)) return mission;
  }
  return null;
}

ContentFeedbackClientFailure _safeFailureForFirebaseCode(String code) {
  return switch (code) {
    'invalid-argument' ||
    'failed-precondition' => const ContentFeedbackClientFailure(
      ContentFeedbackFailureCategory.invalidRequest,
      retryable: false,
    ),
    'unauthenticated' => const ContentFeedbackClientFailure(
      ContentFeedbackFailureCategory.authenticationRequired,
      retryable: false,
    ),
    'permission-denied' => const ContentFeedbackClientFailure(
      ContentFeedbackFailureCategory.permissionDenied,
      retryable: false,
    ),
    'resource-exhausted' => const ContentFeedbackClientFailure(
      ContentFeedbackFailureCategory.rateLimited,
      retryable: true,
    ),
    'unavailable' ||
    'deadline-exceeded' ||
    'internal' => const ContentFeedbackClientFailure(
      ContentFeedbackFailureCategory.unavailable,
      retryable: true,
    ),
    _ => const ContentFeedbackClientFailure(
      ContentFeedbackFailureCategory.unknown,
      retryable: true,
    ),
  };
}
