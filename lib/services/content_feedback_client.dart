import 'package:cloud_functions/cloud_functions.dart';

import '../models/content_feedback.dart';

enum ContentFeedbackAcknowledgement { accepted, duplicateCompletion }

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
  Future<ContentFeedbackAcknowledgement> submit(
    ContentFeedbackSubmission submission,
  );
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
  Future<ContentFeedbackAcknowledgement> submit(
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
    if (accepted == true && duplicate == false) {
      return ContentFeedbackAcknowledgement.accepted;
    }
    if (accepted == false && duplicate == true) {
      return ContentFeedbackAcknowledgement.duplicateCompletion;
    }
    throw const ContentFeedbackClientFailure(
      ContentFeedbackFailureCategory.unknown,
      retryable: true,
    );
  }
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
