import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/korean_proofreading_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/korean_proofreading');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
  });

  group('KoreanProofreadingService availability', () {
    test('returns a structured fallback outside Android', () async {
      final service = KoreanProofreadingService(
        channel: channel,
        isAndroidOverride: false,
      );

      final availability = await service.check();
      final result = await service.proofread('안녕하세요.');

      expect(availability.status, KoreanProofreadingStatus.unsupportedPlatform);
      expect(result.status, KoreanProofreadingStatus.unsupportedPlatform);
      expect(result.originalText, '안녕하세요.');
      expect(result.suggestion, isNull);
    });

    test('parses downloadable state and byte counts', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'check');
        return <String, Object>{
          'status': 'downloadable',
          'error': 'none',
          'downloadedBytes': 10,
          'totalBytes': 100,
        };
      });
      final service = KoreanProofreadingService(
        channel: channel,
        isAndroidOverride: true,
      );

      final result = await service.check();

      expect(result.status, KoreanProofreadingStatus.downloadable);
      expect(result.canDownload, isTrue);
      expect(result.downloadedBytes, 10);
      expect(result.totalBytes, 100);
    });

    test('MissingPlugin is a non-throwing optional-feature state', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw MissingPluginException();
      });
      final service = KoreanProofreadingService(
        channel: channel,
        isAndroidOverride: true,
      );

      final result = await service.check();

      expect(result.status, KoreanProofreadingStatus.featureModuleMissing);
      expect(result.error, KoreanProofreadingError.missingPlugin);
    });

    test('rejects malformed availability maps', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => <String, Object>{'status': 'completed'},
      );
      final service = KoreanProofreadingService(
        channel: channel,
        isAndroidOverride: true,
      );

      final result = await service.check();

      expect(result.status, KoreanProofreadingStatus.failed);
      expect(result.error, KoreanProofreadingError.malformedResponse);
    });

    test('bounds an unresponsive native call with a stable timeout', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) => Completer<Object?>().future,
      );
      final service = KoreanProofreadingService(
        channel: channel,
        isAndroidOverride: true,
        operationTimeout: const Duration(milliseconds: 10),
      );

      final result = await service.check();

      expect(result.status, KoreanProofreadingStatus.failed);
      expect(result.error, KoreanProofreadingError.timeout);
    });
  });

  group('KoreanProofreadingService proofread', () {
    test(
      'preserves caller input while sending NFC trimmed Korean only',
      () async {
        MethodCall? captured;
        messenger.setMockMethodCallHandler(channel, (call) async {
          captured = call;
          return <String, Object>{
            'status': 'completed',
            'error': 'none',
            'sourceText': '안녕하세요.',
            'suggestions': <String>['안녕하세요.'],
            'isFinal': true,
          };
        });
        final service = KoreanProofreadingService(
          channel: channel,
          isAndroidOverride: true,
        );
        const original = '  안녕하세요.  ';

        final result = await service.proofread(original);

        expect(result.isSuccessful, isTrue);
        expect(result.originalText, original);
        expect(result.suggestion, '안녕하세요.');
        expect(captured?.method, 'proofread');
        expect(captured?.arguments, <String, Object>{'text': '안녕하세요.'});
        expect((captured?.arguments as Map).containsKey('language'), isFalse);
      },
    );

    test('returns token changes for a relevant correction', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => <String, Object>{
          'status': 'completed',
          'error': 'none',
          'sourceText': '저는 학쌩이에요.',
          'suggestions': <String>['저는 학생이에요.'],
          'isFinal': true,
        },
      );
      final service = KoreanProofreadingService(
        channel: channel,
        isAndroidOverride: true,
      );

      final result = await service.proofread('저는 학쌩이에요.');

      expect(result.isSuccessful, isTrue);
      expect(result.changes, hasLength(1));
      expect(result.changes.single.originalText, '학쌩이에요');
      expect(result.changes.single.replacementText, '학생이에요');
    });

    test(
      'rejects empty, non-Korean, unsupported and over-limit input',
      () async {
        var nativeCalls = 0;
        messenger.setMockMethodCallHandler(channel, (call) async {
          nativeCalls++;
          return null;
        });
        final service = KoreanProofreadingService(
          channel: channel,
          isAndroidOverride: true,
        );

        expect(
          (await service.proofread('   ')).error,
          KoreanProofreadingError.invalidInput,
        );
        expect(
          (await service.proofread('hello')).error,
          KoreanProofreadingError.invalidInput,
        );
        expect(
          (await service.proofread('안녕 \u202Eabc')).error,
          KoreanProofreadingError.invalidInput,
        );
        expect(
          (await service.proofread('안녕 Привет')).error,
          KoreanProofreadingError.invalidInput,
        );
        expect(
          (await service.proofread('안녕 नमस्ते')).error,
          KoreanProofreadingError.invalidInput,
        );
        expect(
          (await service.proofread('안녕 中文')).error,
          KoreanProofreadingError.invalidInput,
        );
        expect(
          (await service.proofread('가' * 241)).error,
          KoreanProofreadingError.inputTooLong,
        );
        expect(nativeCalls, 0);
      },
    );

    test('requires final response and exact normalized source echo', () async {
      final responses = <Map<String, Object>>[
        <String, Object>{
          'status': 'completed',
          'sourceText': '다른 원문',
          'suggestions': <String>['안녕하세요.'],
          'isFinal': true,
        },
        <String, Object>{
          'status': 'completed',
          'sourceText': '안녕하세여.',
          'suggestions': <String>['안녕하세요.'],
          'isFinal': false,
        },
      ];
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => responses.removeAt(0),
      );
      final service = KoreanProofreadingService(
        channel: channel,
        isAndroidOverride: true,
      );

      final wrongSource = await service.proofread('안녕하세여.');
      final partial = await service.proofread('안녕하세여.');

      expect(wrongSource.error, KoreanProofreadingError.responseRejected);
      expect(partial.error, KoreanProofreadingError.responseRejected);
    });

    test(
      'fails closed for empty, irrelevant and contaminated suggestions',
      () async {
        final responses = <Map<String, Object>>[
          <String, Object>{
            'status': 'completed',
            'sourceText': '안녕하세여.',
            'suggestions': <String>[],
            'isFinal': true,
          },
          <String, Object>{
            'status': 'completed',
            'sourceText': '안녕하세여.',
            'suggestions': <String>['오늘 비행기가 출발합니다.'],
            'isFinal': true,
          },
          <String, Object>{
            'status': 'completed',
            'sourceText': '안녕하세여.',
            'suggestions': <String>['안녕하세요. مرحبا'],
            'isFinal': true,
          },
        ];
        messenger.setMockMethodCallHandler(
          channel,
          (call) async => responses.removeAt(0),
        );
        final service = KoreanProofreadingService(
          channel: channel,
          isAndroidOverride: true,
        );

        expect(
          (await service.proofread('안녕하세여.')).error,
          KoreanProofreadingError.malformedResponse,
        );
        expect(
          (await service.proofread('안녕하세여.')).error,
          KoreanProofreadingError.irrelevantResponse,
        );
        expect(
          (await service.proofread('안녕하세여.')).error,
          KoreanProofreadingError.responseRejected,
        );
      },
    );

    test('maps foreground/quota retry errors without throwing', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(
          code: 'backgroundBlocked',
          details: <String, Object>{'retryAfterMs': 2500},
        );
      });
      final service = KoreanProofreadingService(
        channel: channel,
        isAndroidOverride: true,
      );

      final result = await service.proofread('안녕하세요.');

      expect(result.status, KoreanProofreadingStatus.backgroundBlocked);
      expect(result.error, KoreanProofreadingError.backgroundBlocked);
      expect(result.retryAfter, const Duration(milliseconds: 2500));
    });

    test(
      'accepts particle and conjugation corrections without treating them as a rewrite',
      () async {
        const original = '내일 친구 만나서 영화 봤어요.';
        const corrected = '내일 친구를 만나서 영화를 볼 거예요.';
        messenger.setMockMethodCallHandler(
          channel,
          (call) async => <String, Object>{
            'status': 'completed',
            'sourceText': original,
            'suggestions': <String>[corrected],
            'isFinal': true,
          },
        );
        final service = KoreanProofreadingService(
          channel: channel,
          isAndroidOverride: true,
        );

        final result = await service.proofread(original);

        expect(result.isSuccessful, isTrue);
        expect(result.suggestion, corrected);
        expect(result.originalText, original);
        expect(result.changes, isNotEmpty);
      },
    );

    test('still rejects lexical replacement and added negation', () async {
      const original = '내일 친구 만나서 영화 봤어요.';
      final responses = <String>['내일 친구 만나서 음악 들었어요.', '내일 친구 만나서 영화 안 봤어요.'];
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => <String, Object>{
          'status': 'completed',
          'sourceText': original,
          'suggestions': <String>[responses.removeAt(0)],
          'isFinal': true,
        },
      );
      final service = KoreanProofreadingService(
        channel: channel,
        isAndroidOverride: true,
      );

      final lexicalDrift = await service.proofread(original);
      final negated = await service.proofread(original);

      expect(lexicalDrift.error, KoreanProofreadingError.irrelevantResponse);
      expect(negated.error, KoreanProofreadingError.irrelevantResponse);
    });

    test(
      'rejects numeric polarity and lexical drift in short responses',
      () async {
        final responses = <String>['2개', '잘돼', '불 주세요.', '불', '두 개', '학원'];
        messenger.setMockMethodCallHandler(channel, (call) async {
          final arguments = (call.arguments as Map).cast<String, Object>();
          return <String, Object>{
            'status': 'completed',
            'sourceText': arguments['text']!,
            'suggestions': <String>[responses.removeAt(0)],
            'isFinal': true,
          };
        });
        final service = KoreanProofreadingService(
          channel: channel,
          isAndroidOverride: true,
        );

        final numericDrift = await service.proofread('1개');
        final polarityDrift = await service.proofread('안돼');
        final lexicalDrift = await service.proofread('물 주세요.');
        final oneSyllableDrift = await service.proofread('물');
        final koreanNumberDrift = await service.proofread('한 개');
        final shortWordDrift = await service.proofread('학교');

        expect(numericDrift.error, KoreanProofreadingError.irrelevantResponse);
        expect(polarityDrift.error, KoreanProofreadingError.irrelevantResponse);
        expect(lexicalDrift.error, KoreanProofreadingError.irrelevantResponse);
        expect(
          oneSyllableDrift.error,
          KoreanProofreadingError.irrelevantResponse,
        );
        expect(
          koreanNumberDrift.error,
          KoreanProofreadingError.irrelevantResponse,
        );
        expect(
          shortWordDrift.error,
          KoreanProofreadingError.irrelevantResponse,
        );
      },
    );

    test('keeps a short Korean spelling correction available', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => <String, Object>{
          'status': 'completed',
          'sourceText': '되요',
          'suggestions': <String>['돼요'],
          'isFinal': true,
        },
      );
      final service = KoreanProofreadingService(
        channel: channel,
        isAndroidOverride: true,
      );

      final result = await service.proofread('되요');

      expect(result.isSuccessful, isTrue);
      expect(result.suggestion, '돼요');
    });

    test('rejects a semantically different multi-token rewrite', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => <String, Object>{
          'status': 'completed',
          'sourceText': '저는 오늘 학교에 갑니다.',
          'suggestions': <String>['저는 내일 회사에 갑니다.'],
          'isFinal': true,
        },
      );
      final service = KoreanProofreadingService(
        channel: channel,
        isAndroidOverride: true,
      );

      final result = await service.proofread('저는 오늘 학교에 갑니다.');

      expect(result.error, KoreanProofreadingError.irrelevantResponse);
    });
  });

  group('diffKoreanProofreadingTokens', () {
    test('is deterministic for replacement, insertion and unchanged text', () {
      final replacement = diffKoreanProofreadingTokens(
        '저는 학쌩이에요.',
        '저는 학생이에요.',
      );
      final insertion = diffKoreanProofreadingTokens('정말 좋아요.', '정말 아주 좋아요.');

      expect(replacement, hasLength(1));
      expect(replacement.single.originalText, '학쌩이에요');
      expect(replacement.single.replacementText, '학생이에요');
      expect(insertion, hasLength(1));
      expect(insertion.single.originalText, '');
      expect(insertion.single.replacementText, '아주␠');
      expect(diffKoreanProofreadingTokens('같아요.', '같아요.'), isEmpty);
    });

    test('preserves spacing-only and punctuation-spacing changes', () {
      final repeatedSpace = diffKoreanProofreadingTokens('안녕  친구', '안녕 친구');
      final punctuationSpace = diffKoreanProofreadingTokens(
        '안녕 , 친구',
        '안녕, 친구',
      );

      expect(repeatedSpace, isNotEmpty);
      expect(
        repeatedSpace.any(
          (change) =>
              change.originalText.contains('␠') ||
              change.replacementText.contains('␠'),
        ),
        isTrue,
      );
      expect(punctuationSpace, isNotEmpty);
      expect(
        punctuationSpace.any(
          (change) =>
              change.originalText.contains('␠') ||
              change.replacementText.contains('␠'),
        ),
        isTrue,
      );
    });
  });
}
