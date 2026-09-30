import 'dart:convert';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ko_lernen_app/services/book_analysis_service.dart';
import 'package:ko_lernen_app/services/kkeunmari_dictionary_service.dart';
import 'package:ko_lernen_app/services/kkeunmari_engine.dart';

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

class _StalledClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(StreamController<List<int>>().stream, 200);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const credentials = BookAnalysisCredentials(
    idToken: 'test-id-token',
    appCheckToken: 'test-app-check-token',
  );

  test('credential failures are recoverable instead of escaping', () async {
    final result = await KkeunmariDictionaryService.validate(
      word: '뢔뷁',
      offlineLookup: (_) async => false,
      credentialsProvider: () async => throw StateError('unavailable'),
    );
    expect(result.status, KkeunmariDictionaryStatus.unavailable);
  });

  test('previously accepted remote words cannot be reused', () {
    final result = KkeunmariEngine.validateUserWord('러너', '러', {
      '러너',
    }, source: const []);
    expect(result.$2, 'already_used');
  });

  test('sends protected validation only to the fixed endpoint', () async {
    final client = _DictionaryClient(200, {'valid': true});

    final result = await KkeunmariDictionaryService.validate(
      word: '\uC81C\uC0AC',
      offlineLookup: (_) async => false,
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
      offlineLookup: (_) async => false,
      word: '\uC81C\uC0AC',
      client: _DictionaryClient(200, {'valid': false}),
      credentialsProvider: () async => credentials,
    );
    final unavailable = await KkeunmariDictionaryService.validate(
      offlineLookup: (_) async => false,
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
        offlineLookup: (_) async => false,
        word: '\uC81C\uC0AC',
        client: client,
        credentialsProvider: () async => null,
      );

      expect(result.status, KkeunmariDictionaryStatus.unavailable);
      expect(client.request, isNull);
    },
  );

  test('bundled nouns survive missing auth and network', () async {
    for (final word in ['막내', '러닝', '러너']) {
      final client = _DictionaryClient(503, {});
      final result = await KkeunmariDictionaryService.validate(
        word: word,
        client: client,
        credentialsProvider: () async => throw StateError('no Firebase'),
      );
      expect(result.isValid, isTrue, reason: word);
      expect(client.request, isNull);
    }
  });

  test(
    'late credentials never initiate a request after the deadline',
    () async {
      final late = Completer<BookAnalysisCredentials?>();
      final client = _DictionaryClient(200, {'valid': true});
      final result = await KkeunmariDictionaryService.validate(
        word: '러너',
        client: client,
        offlineLookup: (_) async => false,
        credentialsProvider: () => late.future,
        timeout: const Duration(milliseconds: 20),
      );
      expect(result.status, KkeunmariDictionaryStatus.unavailable);
      late.complete(credentials);
      await Future<void>.delayed(Duration.zero);
      expect(client.request, isNull);
    },
  );

  test('a body that never completes cannot hang validation', () async {
    final result = await KkeunmariDictionaryService.validate(
      word: '러너',
      client: _StalledClient(),
      offlineLookup: (_) async => false,
      credentialsProvider: () async => credentials,
      timeout: const Duration(milliseconds: 20),
    );
    expect(result.status, KkeunmariDictionaryStatus.unavailable);
  });

  test(
    'bad and oversized responses remain outages, not invalid words',
    () async {
      for (final body in [
        {'valid': 'true'},
        {'valid': true, 'padding': 'x' * 5000},
        [],
      ]) {
        final result = await KkeunmariDictionaryService.validate(
          word: '러너',
          client: _DictionaryClient(200, body),
          offlineLookup: (_) async => false,
          credentialsProvider: () async => credentials,
        );
        expect(result.status, KkeunmariDictionaryStatus.unavailable);
      }
    },
  );
}
