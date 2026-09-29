import 'dart:convert';

import 'package:http/http.dart' as http;

import 'book_analysis_service.dart';
import 'korean_noun_lexicon.dart';

enum KkeunmariDictionaryStatus { valid, invalid, unavailable }

class KkeunmariDictionaryResult {
  const KkeunmariDictionaryResult(this.status);

  final KkeunmariDictionaryStatus status;

  bool get isValid => status == KkeunmariDictionaryStatus.valid;
}

/// Validates a word not present in the small offline game pool.
///
/// The API key for the Korean Basic Dictionary stays in the protected Cloud
/// Function. A connection or credential problem is deliberately reported as
/// [KkeunmariDictionaryStatus.unavailable], never as an invalid Korean word.
class KkeunmariDictionaryService {
  static const Duration _timeout = Duration(seconds: 6);
  static final Uri trustedEndpoint = Uri.parse(
    'https://europe-west3-ko-lernen-app.cloudfunctions.net/'
    'validate_kkeunmari_word',
  );

  static Future<KkeunmariDictionaryResult> validate({
    required String word,
    http.Client? client,
    BookAnalysisCredentialsProvider? credentialsProvider,
    Future<bool> Function(String)? offlineLookup,
    Duration timeout = _timeout,
  }) async {
    final normalized = word.trim();
    if (!RegExp(r'^[가-힣]{1,20}$').hasMatch(normalized)) {
      return const KkeunmariDictionaryResult(KkeunmariDictionaryStatus.invalid);
    }
    final ownsClient = client == null;
    final effectiveClient = client ?? http.Client();
    var retired = false;
    const unavailable = KkeunmariDictionaryResult(
      KkeunmariDictionaryStatus.unavailable,
    );
    try {
      // One deadline includes asset loading, Firebase credentials, headers and
      // the complete body. Late credentials must not start a ghost request.
      return await (() async {
        try {
          if (await (offlineLookup ?? KoreanNounLexicon.contains)(normalized)) {
            return const KkeunmariDictionaryResult(
              KkeunmariDictionaryStatus.valid,
            );
          }
        } catch (_) {
          // A damaged offline asset must not turn a valid word into an error.
        }
        if (retired) {
          return unavailable;
        }
        final credentials =
            await (credentialsProvider ??
                BookAnalysisService.firebaseCredentials)();
        if (retired ||
            credentials == null ||
            credentials.idToken.isEmpty ||
            credentials.appCheckToken.isEmpty) {
          return unavailable;
        }
        final request = http.Request('POST', trustedEndpoint)
          ..followRedirects = false
          ..headers.addAll({
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${credentials.idToken}',
            'X-Firebase-AppCheck': credentials.appCheckToken,
          })
          ..body = jsonEncode({'word': normalized});
        final streamed = await effectiveClient.send(request);
        var bytes = 0;
        final response = await http.Response.fromStream(
          http.StreamedResponse(
            streamed.stream.timeout(timeout).map((chunk) {
              bytes += chunk.length;
              if (bytes > 4096) {
                throw const FormatException('Oversized dictionary response');
              }
              return chunk;
            }),
            streamed.statusCode,
            headers: streamed.headers,
          ),
        );
        if (response.statusCode != 200) {
          return const KkeunmariDictionaryResult(
            KkeunmariDictionaryStatus.unavailable,
          );
        }
        final body = jsonDecode(response.body);
        if (body is! Map<String, dynamic> || body['valid'] is! bool) {
          return const KkeunmariDictionaryResult(
            KkeunmariDictionaryStatus.unavailable,
          );
        }
        return KkeunmariDictionaryResult(
          body['valid'] as bool
              ? KkeunmariDictionaryStatus.valid
              : KkeunmariDictionaryStatus.invalid,
        );
      })().timeout(timeout);
    } catch (_) {
      return const KkeunmariDictionaryResult(
        KkeunmariDictionaryStatus.unavailable,
      );
    } finally {
      retired = true;
      if (ownsClient) {
        effectiveClient.close();
      }
    }
  }
}
