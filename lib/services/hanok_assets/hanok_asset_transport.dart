import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'hanok_asset_failure.dart';
import 'hanok_asset_manifest.dart';
import 'hanok_asset_store.dart';

typedef HanokAssetFetch = Future<Uint8List> Function(HanokAsset asset);
typedef HanokAppCheckToken = Future<String?> Function();

class HanokAssetTransport {
  final http.Client Function() clientFactory;
  final HanokAppCheckToken tokenProvider;
  final Duration timeout;
  final Duration tokenTimeout;
  HanokAssetTransport({
    http.Client Function()? clientFactory,
    HanokAppCheckToken? tokenProvider,
    this.timeout = const Duration(seconds: 45),
    this.tokenTimeout = const Duration(seconds: 8),
  }) : clientFactory = clientFactory ?? http.Client.new,
       tokenProvider = tokenProvider ?? _appCheck;

  static Future<String?> _appCheck() async {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    return FirebaseAppCheck.instance.getToken();
  }

  Future<Uint8List> fetch(HanokAsset asset) async {
    final client = clientFactory();
    StreamSubscription<List<int>>? subscription;
    var ended = false;
    Future<Uint8List> perform() async {
      final token = await tokenProvider().timeout(tokenTimeout);
      if (ended) {
        throw const HanokAssetFailure(HanokAssetFailureKind.network);
      }
      final request = http.Request('GET', asset.mediaUri)
        ..followRedirects = false;
      if (token != null && token.isNotEmpty) {
        request.headers['X-Firebase-AppCheck'] = token;
      }
      final response = await client.send(request);
      final unexpectedUrl =
          response is http.BaseResponseWithUrl &&
          (response as http.BaseResponseWithUrl).url != asset.mediaUri;
      if (ended ||
          unexpectedUrl ||
          response.statusCode != 200 ||
          response.isRedirect ||
          (response.contentLength != null &&
              response.contentLength != asset.bytes)) {
        throw const HanokAssetFailure(HanokAssetFailureKind.network);
      }
      final completer = Completer<Uint8List>();
      final bytes = BytesBuilder(copy: false);
      subscription = response.stream.listen(
        (chunk) {
          if (completer.isCompleted) {
            return;
          }
          if (bytes.length + chunk.length > asset.bytes) {
            completer.completeError(
              const HanokAssetFailure(HanokAssetFailureKind.corrupt),
            );
            return;
          }
          bytes.add(chunk);
        },
        onError: (Object _, StackTrace __) {
          if (!completer.isCompleted) {
            completer.completeError(
              const HanokAssetFailure(HanokAssetFailureKind.network),
            );
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete(bytes.takeBytes());
          }
        },
        cancelOnError: true,
      );
      final result = await completer.future;
      if (!verifiesHanokAsset(asset, result)) {
        throw const HanokAssetFailure(HanokAssetFailureKind.corrupt);
      }
      return result;
    }

    try {
      return await perform().timeout(timeout);
    } on HanokAssetFailure {
      rethrow;
    } catch (_) {
      throw const HanokAssetFailure(HanokAssetFailureKind.network);
    } finally {
      ended = true;
      client.close();
      // Do not let a broken stream's cancellation extend the request deadline.
      unawaited(subscription?.cancel().catchError((Object _) {}));
    }
  }
}
