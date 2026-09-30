import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/services/book_analysis_service.dart';

const _credentials = BookAnalysisCredentials(
  idToken: 'test-token',
  appCheckToken: 'test-app-check',
);
final _validBody = utf8.encode(
  jsonEncode({
    'words': [
      {'korean': '학생', 'translation': 'student'},
    ],
    'expressions': [],
    'grammar': [],
    'sentences': [],
    'warnings': [],
    'analysisLanguage': 'en',
  }),
);

class _ControlledClient extends http.BaseClient {
  final headers = Completer<http.StreamedResponse>();
  final body = StreamController<List<int>>();
  int sends = 0;
  bool closed = false;
  bool aborted = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    sends++;
    if (request is http.Abortable) {
      request.abortTrigger?.then((_) => aborted = true);
    }
    return headers.future;
  }

  void respond() => headers.complete(
    http.StreamedResponse(
      body.stream,
      200,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    ),
  );

  @override
  void close() {
    closed = true;
  }
}

Future<BookAnalysisResult> _analyze(_ControlledClient client) =>
    BookAnalysisService.analyze(
      text: '학생이에요.',
      targetLang: 'en',
      client: client,
      credentialsProvider: () async => _credentials,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Warm the bundled grammar/dictionary independently of the fake clock.
    await BookAnalysisService.analyze(
      text: '학생이에요.',
      targetLang: 'en',
      credentialsProvider: () async => null,
    );
  });

  test(
    'hung credentials fall back at eight seconds; late tokens never send',
    () {
      fakeAsync((clock) {
        final client = _ControlledClient();
        final tokens = Completer<BookAnalysisCredentials?>();
        BookAnalysisResult? result;
        BookAnalysisService.analyze(
          text: '학생이에요.',
          targetLang: 'en',
          client: client,
          credentialsProvider: () => tokens.future,
        ).then((value) => result = value);
        clock.elapse(const Duration(milliseconds: 7999));
        expect(result, isNull);
        clock.elapse(const Duration(milliseconds: 1));
        expect(result?.warnings, contains('remote_credentials_unavailable'));
        expect(result?.analysisLanguage, 'en');
        tokens.complete(_credentials);
        clock.flushMicrotasks();
        expect(client.sends, 0);
      });
    },
  );

  test(
    'credential exceptions keep the local fallback and send nothing',
    () async {
      final client = _ControlledClient();
      final result = await BookAnalysisService.analyze(
        text: '학생이에요.',
        client: client,
        credentialsProvider: () => throw Exception('unavailable'),
      );
      expect(result.warnings, contains('remote_credentials_unavailable'));
      expect(client.sends, 0);
    },
  );

  test('response body shares the twelve second deadline with headers', () {
    fakeAsync((clock) {
      final client = _ControlledClient();
      BookAnalysisResult? result;
      _analyze(client).then((value) => result = value);
      clock.elapse(const Duration(seconds: 10));
      client.respond();
      clock.flushMicrotasks();
      client.body.add(_validBody.sublist(0, 1));
      clock.elapse(const Duration(milliseconds: 1999));
      expect(result, isNull);
      clock.elapse(const Duration(milliseconds: 1));
      expect(result?.warnings, contains('remote_analysis_failed'));
      expect(client.aborted, isTrue);
      expect(client.closed, isFalse); // Injected clients remain caller-owned.
      final fallback = result;
      client.body.add(_validBody.sublist(1));
      unawaited(client.body.close());
      clock.flushMicrotasks();
      expect(identical(result, fallback), isTrue);
      expect(client.sends, 1);
    });
  });

  test('hung headers abort once without closing a caller-owned client', () {
    fakeAsync((clock) {
      final client = _ControlledClient();
      BookAnalysisResult? result;
      _analyze(client).then((value) => result = value);
      clock.elapse(const Duration(seconds: 12));
      expect(result?.warnings, contains('remote_analysis_failed'));
      expect(client.aborted, isTrue);
      expect(client.closed, isFalse);
      expect(client.sends, 1);
    });
  });

  test('owned client stays open until the full body has been read', () {
    fakeAsync((clock) {
      final client = _ControlledClient();
      BookAnalysisResult? result;
      http.runWithClient(
        () => BookAnalysisService.analyze(
          text: '학생이에요.',
          targetLang: 'en',
          credentialsProvider: () async => _credentials,
        ).then((value) => result = value),
        () => client,
      );
      clock.flushMicrotasks();
      client.respond();
      clock.flushMicrotasks();
      expect(client.closed, isFalse);
      client.body.add(_validBody);
      unawaited(client.body.close());
      clock.flushMicrotasks();
      expect(result?.warnings, isEmpty);
      expect(result?.analysisLanguage, 'en');
      expect(result?.words.single.translationEn, 'student');
      expect(client.closed, isTrue);
    });
  });

  test('a response completed just before the deadline retains remote data', () {
    fakeAsync((clock) {
      final client = _ControlledClient();
      BookAnalysisResult? result;
      _analyze(client).then((value) => result = value);
      clock.flushMicrotasks();
      client.respond();
      clock.elapse(const Duration(milliseconds: 11999));
      client.body.add(_validBody);
      unawaited(client.body.close());
      clock.flushMicrotasks();
      clock.elapse(const Duration(seconds: 1));
      expect(result?.warnings, isEmpty);
      expect(result?.words.single.translationEn, 'student');
      expect(client.closed, isFalse);
      expect(client.sends, 1);
    });
  });

  test('owned client closes and aborts a stalled body at the deadline', () {
    fakeAsync((clock) {
      final client = _ControlledClient();
      BookAnalysisResult? result;
      http.runWithClient(
        () => BookAnalysisService.analyze(
          text: '학생이에요.',
          credentialsProvider: () async => _credentials,
        ).then((value) => result = value),
        () => client,
      );
      clock.flushMicrotasks();
      client.respond();
      clock.elapse(const Duration(seconds: 12));
      expect(result?.warnings, contains('remote_analysis_failed'));
      expect(client.closed, isTrue);
      expect(client.aborted, isTrue);
      expect(client.sends, 1);
      unawaited(client.body.close());
      clock.flushMicrotasks();
    });
  });
}
