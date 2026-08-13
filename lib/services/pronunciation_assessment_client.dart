import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';

import 'pronunciation_progress_service.dart';

enum PronunciationAssessmentFailureCategory {
  invalidRequest,
  authenticationRequired,
  unavailable,
  rateLimited,
  unknown,
}

class PronunciationAssessmentFailure implements Exception {
  const PronunciationAssessmentFailure(
    this.category, {
    required this.retryable,
  });

  final PronunciationAssessmentFailureCategory category;
  final bool retryable;

  @override
  String toString() => 'Pronunciation assessment failed (${category.name}).';
}

class PronunciationAssessmentResult {
  const PronunciationAssessmentResult({
    required this.assessmentId,
    required this.pronunciationScore,
    required this.accuracyScore,
    required this.fluencyScore,
    required this.completenessScore,
  });

  final String assessmentId;
  final double pronunciationScore;
  final double accuracyScore;
  final double fluencyScore;
  final double completenessScore;

  bool get passed => pronunciationScorePasses(pronunciationScore);
}

abstract interface class PronunciationAssessmentGateway {
  Future<PronunciationAssessmentResult> assess({
    required Uint8List pcm16,
    required String referenceText,
    required String assessmentId,
  });
}

typedef PronunciationCallableInvoker =
    Future<Object?> Function({
      required String callableName,
      required Map<String, Object?> request,
      required HttpsCallableOptions callableOptions,
    });

class FirebasePronunciationAssessmentGateway
    implements PronunciationAssessmentGateway {
  FirebasePronunciationAssessmentGateway(this._invoke);

  factory FirebasePronunciationAssessmentGateway.production({
    PronunciationCallableInvoker Function(String region)? invokerForRegion,
  }) => FirebasePronunciationAssessmentGateway(
    (invokerForRegion ?? _firebaseInvokerForRegion)(_functionRegion),
  );

  static const String _functionRegion = 'europe-west3';
  static const String callableName = 'assessPronunciation';
  static const int maxPcmBytes = 320000;
  static final RegExp _assessmentIdPattern = RegExp(r'^[A-Za-z0-9_-]{8,128}$');

  final PronunciationCallableInvoker _invoke;

  static PronunciationCallableInvoker _firebaseInvokerForRegion(String region) {
    return ({
      required callableName,
      required request,
      required callableOptions,
    }) async {
      final result = await FirebaseFunctions.instanceFor(region: region)
          .httpsCallable(callableName, options: callableOptions)
          .call<Object?>(request);
      return result.data;
    };
  }

  @override
  Future<PronunciationAssessmentResult> assess({
    required Uint8List pcm16,
    required String referenceText,
    required String assessmentId,
  }) async {
    final normalizedReference = referenceText.trim();
    if (pcm16.isEmpty ||
        pcm16.length > maxPcmBytes ||
        pcm16.length.isOdd ||
        normalizedReference.isEmpty ||
        normalizedReference.runes.length > 200 ||
        !_assessmentIdPattern.hasMatch(assessmentId)) {
      throw const PronunciationAssessmentFailure(
        PronunciationAssessmentFailureCategory.invalidRequest,
        retryable: false,
      );
    }

    Object? raw;
    try {
      raw = await _invoke(
        callableName: callableName,
        request: <String, Object?>{
          'audioBase64': base64Encode(pcm16),
          'referenceText': normalizedReference,
          'assessmentId': assessmentId,
        },
        callableOptions: HttpsCallableOptions(limitedUseAppCheckToken: true),
      );
    } on FirebaseFunctionsException catch (error) {
      throw _firebaseFailure(error.code);
    } on PronunciationAssessmentFailure {
      rethrow;
    } catch (_) {
      throw const PronunciationAssessmentFailure(
        PronunciationAssessmentFailureCategory.unknown,
        retryable: true,
      );
    }
    return _parseResult(raw, expectedAssessmentId: assessmentId);
  }
}

PronunciationAssessmentResult _parseResult(
  Object? raw, {
  required String expectedAssessmentId,
}) {
  if (raw is! Map) {
    return _malformedResponse();
  }
  final map = raw.map((key, value) => MapEntry(key.toString(), value));
  final id = map['assessmentId'];
  final pronunciation = _score(map['pronunciationScore']);
  final accuracy = _score(map['accuracyScore']);
  final fluency = _score(map['fluencyScore']);
  final completeness = _score(map['completenessScore']);
  if (id != expectedAssessmentId ||
      pronunciation == null ||
      accuracy == null ||
      fluency == null ||
      completeness == null) {
    return _malformedResponse();
  }
  return PronunciationAssessmentResult(
    assessmentId: id as String,
    pronunciationScore: pronunciation,
    accuracyScore: accuracy,
    fluencyScore: fluency,
    completenessScore: completeness,
  );
}

double? _score(Object? value) {
  if (value is! num || !value.isFinite) {
    return null;
  }
  final score = value.toDouble();
  return score >= 0 && score <= 100 ? score : null;
}

Never _malformedResponse() => throw const PronunciationAssessmentFailure(
  PronunciationAssessmentFailureCategory.unavailable,
  retryable: true,
);

PronunciationAssessmentFailure _firebaseFailure(String code) => switch (code) {
  'invalid-argument' => const PronunciationAssessmentFailure(
    PronunciationAssessmentFailureCategory.invalidRequest,
    retryable: false,
  ),
  'unauthenticated' ||
  'permission-denied' ||
  'failed-precondition' => const PronunciationAssessmentFailure(
    PronunciationAssessmentFailureCategory.authenticationRequired,
    retryable: false,
  ),
  'resource-exhausted' => const PronunciationAssessmentFailure(
    PronunciationAssessmentFailureCategory.rateLimited,
    retryable: true,
  ),
  'unavailable' ||
  'deadline-exceeded' ||
  'internal' => const PronunciationAssessmentFailure(
    PronunciationAssessmentFailureCategory.unavailable,
    retryable: true,
  ),
  _ => const PronunciationAssessmentFailure(
    PronunciationAssessmentFailureCategory.unknown,
    retryable: true,
  ),
};
