import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ko_lernen_app/services/book_analysis_service.dart';
import 'package:ko_lernen_app/services/kkeunmari_dictionary_service.dart';

class _DictionaryClient extends http.BaseClient {
  _DictionaryClient(this.statusCode, this.responseBody);

  final int statusCode;
  final Object responseBody;
  http.BaseRequest? request;
  String? body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    this.request = request;
    body = await request.finalize().transform(utf8.decoder).join();
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(responseBody))),
      statusCode,
      headers: const {'content-type': 'application/json'},
    );
  }
}

void main() {
  const credentials = BookAnalysisCredentials(
    idToken: 'test-id-token',
    appCheckToken: 'test-app-check-token',
  );

  test('sends protected validation only to the fixed endpoint', () async {
    final client = _DictionaryClient(200, {'valid': true});

    final result = await KkeunmariDictionaryService.validate(
      word: '\uC81C\uC0AC',
      client: client,
      credentialsProvider: () async => credentials,
    );

    expect(result.status, KkeunmariDictionaryStatus.valid);
    expect(client.request?.url, KkeunmariDictionaryService.trustedEndpoint);
    expect(client.request?.headers['authorization'], 'Bearer test-id-token');
    expect(
      client.request?.headers['x-firebase-appcheck'],
      'test-app-check-token',
    );
    expect(jsonDecode(client.body!), {'word': '\uC81C\uC0AC'});
  });

  test('distinguishes an invalid dictionary response from an outage', () async {
    final invalid = await KkeunmariDictionaryService.validate(
      word: '\uC81C\uC0AC',
      client: _DictionaryClient(200, {'valid': false}),
      credentialsProvider: () async => credentials,
    );
    final unavailable = await KkeunmariDictionaryService.validate(
      word: '\uC81C\uC0AC',
      client: _DictionaryClient(503, {'error': 'unavailable'}),
      credentialsProvider: () async => credentials,
    );

    expect(invalid.status, KkeunmariDictionaryStatus.invalid);
    expect(unavailable.status, KkeunmariDictionaryStatus.unavailable);
  });

  test(
    'does not make a network request without protected credentials',
    () async {
      final client = _DictionaryClient(200, {'valid': true});

      final result = await KkeunmariDictionaryService.validate(
        word: '\uC81C\uC0AC',
        client: client,
        credentialsProvider: () async => null,
      );

      expect(result.status, KkeunmariDictionaryStatus.unavailable);
      expect(client.request, isNull);
    },
  );
}
