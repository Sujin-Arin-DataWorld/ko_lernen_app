import 'package:cloud_functions/cloud_functions.dart';

import '../data/beta_mission_catalog.dart';
import '../models/content_feedback.dart';

enum ContentFeedbackAcknowledgement { accepted, duplicateCompletion }

class ContentFeedbackDelivery {
  const ContentFeedbackDelivery({
    required this.acknowledgement,
    this.stampAccepted = false,
    this.passportCompletedMissionIds = const <String>{},
    this.nextMissionId,
  });

  final ContentFeedbackAcknowledgement acknowledgement;
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

    final passport = _parseCompletedMissionIds(
      raw['passportCompletedMissionIds'],
    );
    final submittedMissionId = submission.betaMissionId;
    return ContentFeedbackDelivery(
      acknowledgement: acknowledgement,
      stampAccepted:
          acknowledgement == ContentFeedbackAcknowledgement.accepted &&
          raw['stampAccepted'] == true &&
          passport.isAuthoritative &&
          submittedMissionId != null &&
          passport.missionIds.contains(submittedMissionId),
      passportCompletedMissionIds: passport.missionIds,
      nextMissionId: passport.isAuthoritative
          ? _parseNextMissionId(raw['nextMissionId'], passport.missionIds)
          : null,
    );
  }
}

final Set<String> _knownMissionIds = Set.unmodifiable(
  betaMissionCatalog.map((mission) => mission.id),
);

({Set<String> missionIds, bool isAuthoritative}) _parseCompletedMissionIds(
  Object? raw,
) {
  if (raw is! List) {
    return (missionIds: const <String>{}, isAuthoritative: false);
  }
  final result = <String>{};
  for (final value in raw) {
    if (value is! String || !_knownMissionIds.contains(value)) {
      return (missionIds: const <String>{}, isAuthoritative: false);
    }
    result.add(value);
  }
  return (missionIds: Set.unmodifiable(result), isAuthoritative: true);
}

String? _parseNextMissionId(Object? raw, Set<String> completedMissionIds) {
  if (raw is! String ||
      !_knownMissionIds.contains(raw) ||
      completedMissionIds.contains(raw)) {
    return null;
  }
  return raw;
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
