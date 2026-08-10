import 'dart:convert';

import 'package:http/http.dart' as http;

import 'book_analysis_service.dart';

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
  }) async {
    final credentials =
        await (credentialsProvider ??
            BookAnalysisService.firebaseCredentials)();
    if (credentials == null) {
      return const KkeunmariDictionaryResult(
        KkeunmariDictionaryStatus.unavailable,
      );
    }

    final ownsClient = client == null;
    final effectiveClient = client ?? http.Client();
    try {
      final request = http.Request('POST', trustedEndpoint)
        ..followRedirects = false
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${credentials.idToken}',
          'X-Firebase-AppCheck': credentials.appCheckToken,
        })
        ..body = jsonEncode({'word': word});
      final response = await http.Response.fromStream(
        await effectiveClient.send(request).timeout(_timeout),
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
    } catch (_) {
      return const KkeunmariDictionaryResult(
        KkeunmariDictionaryStatus.unavailable,
      );
    } finally {
      if (ownsClient) {
        effectiveClient.close();
      }
    }
  }
}
