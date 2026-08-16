import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ko_lernen_app/services/book_analysis_service.dart';
import 'package:ko_lernen_app/services/book_ocr_document.dart';

class _RecordingClient extends http.BaseClient {
  _RecordingClient(this.statusCode, {this.responseBody});

  final int statusCode;
  final Map<String, dynamic>? responseBody;
  http.BaseRequest? request;
  String? body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    this.request = request;
    body = await request.finalize().transform(utf8.decoder).join();
    final requestedLanguage =
        (jsonDecode(body!) as Map<String, dynamic>)['lang'] == 'en'
        ? 'en'
        : 'de';
    return http.StreamedResponse(
      Stream.value(
        utf8.encode(
          jsonEncode(
            responseBody ??
                {
                  'words': const [],
                  'expressions': const [],
                  'grammar': const [],
                  'sentences': const [],
                  'warnings': const [],
                  'analysisLanguage': requestedLanguage,
                },
          ),
        ),
      ),
      statusCode,
      headers: const {'content-type': 'application/json'},
    );
  }
}

class _FailIfCalledClient extends http.BaseClient {
  bool wasCalled = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    wasCalled = true;
    throw StateError(
      'A request must not be sent without verified credentials.',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'book analysis sends credentials only to its trusted endpoint',
    () async {
      final client = _RecordingClient(200);

      await BookAnalysisService.analyze(
        text: '학생이에요.',
        targetLang: 'en-US',
        client: client,
        credentialsProvider: () async => const BookAnalysisCredentials(
          idToken: 'test-id-token',
          appCheckToken: 'test-app-check-token',
        ),
      );

      final request = client.request;
      expect(request, isNotNull);
      expect(request!.url, BookAnalysisService.trustedEndpoint);
      expect(request.method, 'POST');
      expect(request.followRedirects, isFalse);
      expect(request.headers['authorization'], 'Bearer test-id-token');
      expect(request.headers['x-firebase-appcheck'], 'test-app-check-token');
      expect(jsonDecode(client.body!), {
        'text': '학생이에요.',
        'lang': 'en',
        'analysisLanguage': 'en',
      });
    },
  );

  test('structured request omits printed foreign glosses', () async {
    final client = _RecordingClient(200);
    final document = BookOcrDocumentBuilder.build(<BookOcrLine>[
      const BookOcrLine(
        text: '학생 student',
        bounds: Rect.fromLTWH(10, 20, 180, 24),
        sourceLineId: 'block:0:line:0',
        blockIndex: 0,
        lineIndex: 0,
        confidence: 0.92,
        recognizedLanguages: <String>['ko', 'en'],
      ),
    ]);

    await BookAnalysisService.analyze(
      text: document.analysisText,
      targetLang: 'en',
      document: document,
      client: client,
      credentialsProvider: () async => const BookAnalysisCredentials(
        idToken: 'test-id-token',
        appCheckToken: 'test-app-check-token',
      ),
    );

    final body = jsonDecode(client.body!) as Map<String, dynamic>;
    expect(body['schemaVersion'], 2);
    expect(body['analysisLanguage'], 'en');
    final units = (body['units'] as List<dynamic>).cast<Map<String, dynamic>>();
    expect(units, hasLength(1));
    expect(units.single['kind'], 'headword');
    expect(units.single['korean'], '학생');
    expect(units.single.containsKey('foreignHints'), isFalse);
    expect(jsonEncode(body), isNot(contains('student')));
  });

  test(
    'book analysis keeps text local when credentials are unavailable',
    () async {
      final client = _FailIfCalledClient();

      final result = await BookAnalysisService.analyze(
        text: '학생이에요.',
        client: client,
        credentialsProvider: () async => null,
      );

      expect(client.wasCalled, isFalse);
      expect(result.warnings, contains('offline_stub'));
    },
  );

  test('book analysis sends only Korean-bearing supported text', () async {
    final client = _RecordingClient(200);

    final result = await BookAnalysisService.analyze(
      text:
          'Lesson 1: 저는 학생이에요.\n'
          'Ich bin Schüler.\n'
          'مرحبا',
      targetLang: 'de',
      client: client,
      credentialsProvider: () async => const BookAnalysisCredentials(
        idToken: 'test-id-token',
        appCheckToken: 'test-app-check-token',
      ),
    );

    expect(jsonDecode(client.body!)['text'], '저는 학생이에요.');
    expect(result.warnings, contains('non_korean_segments_ignored'));
    expect(result.warnings, contains('unexpected_script_filtered'));
  });

  test('book analysis does not call the server without Korean text', () async {
    final client = _FailIfCalledClient();

    final result = await BookAnalysisService.analyze(
      text: 'Nur eine deutsche Erklärung.\nمرحبا',
      client: client,
      credentialsProvider: () async => const BookAnalysisCredentials(
        idToken: 'test-id-token',
        appCheckToken: 'test-app-check-token',
      ),
    );

    expect(client.wasCalled, isFalse);
    expect(result.warnings, contains('no_korean_text'));
  });

  test('book analysis filters invalid-script cloud response fields', () async {
    final client = _RecordingClient(
      200,
      responseBody: {
        'words': [
          {
            'korean': '학생',
            'translation': 'Schüler',
            'romanization': '',
            'pos': 'Nomen',
            'example': '저는 학생이에요.',
            'exampleTranslation': 'Ich bin Schüler.',
          },
          {'korean': '책', 'translation': 'مرحبا'},
          {'korean': 'مرحبا', 'translation': 'falsch'},
        ],
        'expressions': const [],
        'grammar': const [],
        'sentences': [
          {'korean': '저는 학생이에요.', 'translation': 'Ich bin Schüler.'},
          {'korean': 'مرحبا', 'translation': 'falsch'},
        ],
        'warnings': const [],
        'analysisLanguage': 'de',
      },
    );

    final result = await BookAnalysisService.analyze(
      text: '저는 학생이에요.',
      client: client,
      credentialsProvider: () async => const BookAnalysisCredentials(
        idToken: 'test-id-token',
        appCheckToken: 'test-app-check-token',
      ),
    );

    expect(result.words.map((word) => word.korean), ['학생']);
    expect(result.sentences.map((sentence) => sentence.korean), ['저는 학생이에요.']);
    expect(result.warnings, contains('invalid_response_filtered'));
    expect(result.isSaveable, isFalse);
  });

  test(
    'format-control removal marks an otherwise valid response unsafe',
    () async {
      final result = await BookAnalysisService.analyze(
        text: '저는 학생이에요.',
        client: _RecordingClient(
          200,
          responseBody: const {
            'words': [
              {
                'korean': '학생',
                'translation': 'Sch\u202Eüler',
                'example': '저는 학생이에요.',
              },
            ],
            'expressions': [],
            'grammar': [],
            'sentences': [
              {'korean': '저는 학생이에요.', 'translation': 'Ich bin Schüler.'},
            ],
            'warnings': [],
            'analysisLanguage': 'de',
          },
        ),
        credentialsProvider: () async => const BookAnalysisCredentials(
          idToken: 'test-id-token',
          appCheckToken: 'test-app-check-token',
        ),
      );

      expect(result.words.single.translationDe, 'Schüler');
      expect(result.warnings, contains('invalid_response_filtered'));
      expect(result.isSaveable, isFalse);
    },
  );

  test('English cloud results retain their translation language', () async {
    final client = _RecordingClient(
      200,
      responseBody: {
        'words': [
          {
            'korean': '학생',
            'translation': 'student',
            'romanization': 'haksaeng',
            'pos': 'noun',
            'example': '저는 학생이에요.',
            'exampleTranslation': 'I am a student.',
            'sourceUnitId': 'unit:0',
          },
        ],
        'expressions': const [],
        'grammar': const [],
        'sentences': [
          {
            'korean': '저는 학생이에요.',
            'translation': 'I am a student.',
            'sourceUnitId': 'unit:0',
          },
        ],
        'warnings': const [],
        'analysisLanguage': 'en',
      },
    );

    final result = await BookAnalysisService.analyze(
      text: '저는 학생이에요.',
      targetLang: 'en-US',
      client: client,
      credentialsProvider: () async => const BookAnalysisCredentials(
        idToken: 'test-id-token',
        appCheckToken: 'test-app-check-token',
      ),
    );

    expect(result.analysisLanguage, 'en');
    expect(result.words.single.translationEn, 'student');
    expect(result.words.single.translationLanguage, 'en');
    expect(result.words.single.sourceUnitId, 'unit:0');
    expect(result.sentences.single.translationLanguage, 'en');
    expect(result.sentences.single.sourceUnitId, 'unit:0');
  });

  test('structured expression keeps language and source provenance', () async {
    final result = await BookAnalysisService.analyze(
      text: '마음이 와닿다',
      targetLang: 'en',
      client: _RecordingClient(
        200,
        responseBody: const <String, dynamic>{
          'words': <dynamic>[],
          'expressions': <Map<String, String>>[
            <String, String>{
              'korean': '마음이 와닿다',
              'translation': 'to resonate emotionally',
              'sourceUnitId': 'unit:1',
            },
          ],
          'grammar': <dynamic>[],
          'sentences': <dynamic>[],
          'warnings': <dynamic>[],
          'analysisLanguage': 'en',
        },
      ),
      credentialsProvider: () async => const BookAnalysisCredentials(
        idToken: 'test-id-token',
        appCheckToken: 'test-app-check-token',
      ),
    );

    expect(result.expressions.single.korean, '마음이 와닿다');
    expect(result.expressions.single.translationEn, 'to resonate emotionally');
    expect(result.expressions.single.translationLanguage, 'en');
    expect(result.expressions.single.sourceUnitId, 'unit:1');
  });

  test('missing required cloud fields fail closed', () async {
    final result = await BookAnalysisService.analyze(
      text: '저는 학생이에요.',
      client: _RecordingClient(200, responseBody: const {}),
      credentialsProvider: () async => const BookAnalysisCredentials(
        idToken: 'test-id-token',
        appCheckToken: 'test-app-check-token',
      ),
    );

    expect(result.warnings, contains('invalid_response_schema'));
    expect(result.hasMeaningfulResult, isFalse);
    expect(result.isSaveable, isFalse);
  });

  test('wrong required field type fails closed', () async {
    final result = await BookAnalysisService.analyze(
      text: '저는 학생이에요.',
      client: _RecordingClient(
        200,
        responseBody: const {
          'words': {},
          'expressions': [],
          'grammar': [],
          'sentences': [],
          'warnings': [],
          'analysisLanguage': 'de',
        },
      ),
      credentialsProvider: () async => const BookAnalysisCredentials(
        idToken: 'test-id-token',
        appCheckToken: 'test-app-check-token',
      ),
    );

    expect(result.warnings, contains('invalid_response_schema'));
    expect(result.isSaveable, isFalse);
  });

  test('wrong response analysis language fails closed', () async {
    final result = await BookAnalysisService.analyze(
      text: '저는 학생이에요.',
      targetLang: 'en',
      client: _RecordingClient(
        200,
        responseBody: const {
          'words': [],
          'expressions': [],
          'grammar': [],
          'sentences': [],
          'warnings': [],
          'analysisLanguage': 'de',
        },
      ),
      credentialsProvider: () async => const BookAnalysisCredentials(
        idToken: 'test-id-token',
        appCheckToken: 'test-app-check-token',
      ),
    );

    expect(result.warnings, contains('wrong_analysis_language'));
    expect(result.isSaveable, isFalse);
  });

  test('all-empty cloud analysis is not saveable', () async {
    final result = await BookAnalysisService.analyze(
      text: '저는 학생이에요.',
      client: _RecordingClient(
        200,
        responseBody: const {
          'words': [],
          'expressions': [],
          'grammar': [],
          'sentences': [],
          'warnings': [],
          'analysisLanguage': 'de',
        },
      ),
      credentialsProvider: () async => const BookAnalysisCredentials(
        idToken: 'test-id-token',
        appCheckToken: 'test-app-check-token',
      ),
    );

    expect(result.warnings, contains('empty_analysis_result'));
    expect(result.isSaveable, isFalse);
  });

  test('fully filtered cloud analysis is not saveable', () async {
    final result = await BookAnalysisService.analyze(
      text: '저는 학생이에요.',
      client: _RecordingClient(
        200,
        responseBody: const {
          'words': [
            {'korean': 'مرحبا', 'translation': 'wrong'},
          ],
          'expressions': [],
          'grammar': [],
          'sentences': [
            {'korean': 'مرحبا', 'translation': 'wrong'},
          ],
          'warnings': [],
          'analysisLanguage': 'de',
        },
      ),
      credentialsProvider: () async => const BookAnalysisCredentials(
        idToken: 'test-id-token',
        appCheckToken: 'test-app-check-token',
      ),
    );

    expect(
      result.warnings,
      containsAll(['invalid_response_filtered', 'empty_analysis_result']),
    );
    expect(result.hasMeaningfulResult, isFalse);
    expect(result.isSaveable, isFalse);
  });

  test(
    'custom-pack auto-fill refuses a partially contaminated response',
    () async {
      final result = await BookAnalysisService.autoFill(
        '학생',
        client: _RecordingClient(
          200,
          responseBody: const {
            'words': [
              {'korean': '학생', 'translation': 'Schüler'},
              {'korean': 'مرحبا', 'translation': 'wrong'},
            ],
            'expressions': [],
            'grammar': [],
            'sentences': [],
            'warnings': [],
            'analysisLanguage': 'de',
          },
        ),
        credentialsProvider: () async => const BookAnalysisCredentials(
          idToken: 'test-id-token',
          appCheckToken: 'test-app-check-token',
        ),
      );

      expect(result, isNull);
    },
  );

  test(
    'translation outage preserves Korean sentences but omits empty words',
    () async {
      final result = await BookAnalysisService.analyze(
        text: '저는 학생이에요.',
        client: _RecordingClient(
          200,
          responseBody: const {
            'words': [
              {'korean': '학생', 'translation': ''},
            ],
            'expressions': [],
            'grammar': [],
            'sentences': [
              {'korean': '저는 학생이에요.', 'translation': ''},
            ],
            'warnings': ['translation_unavailable'],
            'analysisLanguage': 'de',
          },
        ),
        credentialsProvider: () async => const BookAnalysisCredentials(
          idToken: 'test-id-token',
          appCheckToken: 'test-app-check-token',
        ),
      );

      expect(result.words, isEmpty);
      expect(result.sentences.single.korean, '저는 학생이에요.');
      expect(result.sentences.single.translationDe, isEmpty);
      expect(result.warnings, isNot(contains('invalid_response_filtered')));
      expect(result.isSaveable, isTrue);
    },
  );

  test(
    'book analysis exposes a safe local fallback when rate limited',
    () async {
      final client = _RecordingClient(429);

      final result = await BookAnalysisService.analyze(
        text: '학생이에요.',
        client: client,
        credentialsProvider: () async => const BookAnalysisCredentials(
          idToken: 'test-id-token',
          appCheckToken: 'test-app-check-token',
        ),
      );

      expect(
        result.warnings,
        containsAll(['offline_stub', 'server_rate_limited']),
      );
    },
  );

  test(
    'structured local fallback never merges neighboring card units',
    () async {
      final document = BookOcrDocumentBuilder.build(const <BookOcrLine>[
        BookOcrLine(
          text: '오늘은 학교에 가요',
          bounds: Rect.fromLTWH(10, 20, 220, 24),
          sourceLineId: 'block:0:line:0',
          blockIndex: 0,
          lineIndex: 0,
        ),
        BookOcrLine(
          text: '내일 친구를 만나요',
          bounds: Rect.fromLTWH(300, 20, 220, 24),
          sourceLineId: 'block:1:line:0',
          blockIndex: 1,
          lineIndex: 0,
        ),
      ]);

      final result = await BookAnalysisService.analyze(
        text: document.analysisText,
        document: document,
        client: _RecordingClient(429),
        credentialsProvider: () async => const BookAnalysisCredentials(
          idToken: 'test-id-token',
          appCheckToken: 'test-app-check-token',
        ),
      );

      expect(result.sentences.map((sentence) => sentence.korean), <String>[
        '오늘은 학교에 가요',
        '내일 친구를 만나요',
      ]);
      expect(
        result.sentences.map((sentence) => sentence.sourceUnitId),
        <String>['unit:0', 'unit:1'],
      );
    },
  );
}
