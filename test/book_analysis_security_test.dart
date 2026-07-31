import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ko_lernen_app/services/book_analysis_service.dart';

class _RecordingClient extends http.BaseClient {
  _RecordingClient(this.statusCode);

  final int statusCode;
  http.BaseRequest? request;
  String? body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    this.request = request;
    body = await request.finalize().transform(utf8.decoder).join();
    return http.StreamedResponse(
      Stream.value(
        utf8.encode(
          jsonEncode({
            'words': const [],
            'grammar': const [],
            'sentences': const [],
            'warnings': const [],
          }),
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
      expect(jsonDecode(client.body!), {'text': '학생이에요.', 'lang': 'en'});
    },
  );

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
}
