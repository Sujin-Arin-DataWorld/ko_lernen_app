import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/pronunciation_assessment_client.dart';

void main() {
  test(
    'default beta blocks all assessment transport at the gateway boundary',
    () async {
      var calls = 0;
      Future<Object?> invoke({
        required String callableName,
        required Map<String, Object?> request,
        required HttpsCallableOptions callableOptions,
      }) async {
        calls++;
        return null;
      }

      expect(freePronunciationAssessmentEnabled, isFalse);
      for (final gateway in [
        FirebasePronunciationAssessmentGateway(invoke),
        FirebasePronunciationAssessmentGateway.production(
          invokerForRegion: (_) => invoke,
        ),
      ]) {
        for (var retry = 0; retry < 2; retry++) {
          await expectLater(
            gateway.assess(
              pcm16: Uint8List(20),
              referenceText: '안녕하세요',
              assessmentId: 'p-123456-abcdef12',
            ),
            throwsA(
              isA<PronunciationAssessmentFailure>().having(
                (e) => e.retryable,
                'retryable',
                isFalse,
              ),
            ),
          );
        }
      }
      expect(calls, 0);
    },
  );

  test(
    'a missing deployed callable is diagnosed as service unavailable',
    () async {
      final gateway = FirebasePronunciationAssessmentGateway(
        ({
          required callableName,
          required request,
          required callableOptions,
        }) async => throw FirebaseFunctionsException(
          code: 'not-found',
          message: 'The requested function was not found.',
        ),
        enabled: true,
      );

      await expectLater(
        gateway.assess(
          pcm16: Uint8List(20),
          referenceText: '안녕하세요',
          assessmentId: 'p-123456-abcdef12',
        ),
        throwsA(
          isA<PronunciationAssessmentFailure>().having(
            (failure) => failure.category,
            'category',
            PronunciationAssessmentFailureCategory.unavailable,
          ),
        ),
      );
    },
  );

  test(
    'production gateway uses regional callable and limited App Check token',
    () async {
      String? region;
      String? callable;
      Map<String, Object?>? payload;
      HttpsCallableOptions? options;
      final gateway = FirebasePronunciationAssessmentGateway.production(
        enabled: true,
        invokerForRegion: (selectedRegion) {
          region = selectedRegion;
          return ({
            required callableName,
            required request,
            required callableOptions,
          }) async {
            callable = callableName;
            payload = request;
            options = callableOptions;
            return <String, Object?>{
              'assessmentId': 'p-123456-abcdef12',
              'pronunciationScore': 82.5,
              'accuracyScore': 84,
              'fluencyScore': 79,
              'completenessScore': 100,
            };
          };
        },
      );

      final result = await gateway.assess(
        pcm16: Uint8List.fromList(<int>[0, 1, 2, 3]),
        referenceText: '안녕하세요',
        assessmentId: 'p-123456-abcdef12',
      );

      expect(region, 'europe-west3');
      expect(callable, 'assessPronunciation');
      expect(options?.limitedUseAppCheckToken, isTrue);
      expect(payload, <String, Object?>{
        'audioBase64': 'AAECAw==',
        'referenceText': '안녕하세요',
        'assessmentId': 'p-123456-abcdef12',
      });
      expect(result.pronunciationScore, 82.5);
      expect(result.passed, isTrue);
    },
  );

  test(
    'client rejects invalid audio, reference text and assessment ids',
    () async {
      final gateway = FirebasePronunciationAssessmentGateway(
        ({
          required callableName,
          required request,
          required callableOptions,
        }) async => throw StateError('transport must not run'),
        enabled: true,
      );

      Future<void> expectInvalid({
        required Uint8List pcm16,
        String referenceText = '감사합니다',
        String assessmentId = 'p-123456-abcdef12',
      }) async {
        await expectLater(
          gateway.assess(
            pcm16: pcm16,
            referenceText: referenceText,
            assessmentId: assessmentId,
          ),
          throwsA(
            isA<PronunciationAssessmentFailure>().having(
              (failure) => failure.category,
              'category',
              PronunciationAssessmentFailureCategory.invalidRequest,
            ),
          ),
        );
      }

      await expectInvalid(pcm16: Uint8List(0));
      await expectInvalid(pcm16: Uint8List(320001));
      await expectInvalid(pcm16: Uint8List(20), referenceText: '');
      await expectInvalid(
        pcm16: Uint8List(20),
        referenceText: List.filled(201, '가').join(),
      );
      await expectInvalid(pcm16: Uint8List(20), assessmentId: '../../unsafe');
    },
  );

  test(
    'malformed callable response fails closed without exposing server data',
    () async {
      final gateway = FirebasePronunciationAssessmentGateway(
        ({
          required callableName,
          required request,
          required callableOptions,
        }) async => <String, Object?>{
          'assessmentId': 'p-123456-abcdef12',
          'pronunciationScore': 101,
          'accuracyScore': 84,
          'fluencyScore': 79,
          'completenessScore': 100,
          'rawProviderResponse': 'must never be accepted',
        },
        enabled: true,
      );

      await expectLater(
        gateway.assess(
          pcm16: Uint8List(20),
          referenceText: '안녕하세요',
          assessmentId: 'p-123456-abcdef12',
        ),
        throwsA(
          isA<PronunciationAssessmentFailure>().having(
            (failure) => failure.category,
            'category',
            PronunciationAssessmentFailureCategory.unavailable,
          ),
        ),
      );
    },
  );
}
