import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ko_lernen_app/services/hanok_assets/hanok_asset_delivery.dart';
import 'hanok_asset_delivery_test.dart'
    show catalog, document, entry, failure, original, pack;

class ControlledClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest) respond;
  bool closed = false;
  ControlledClient(this.respond);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      respond(request);
  @override
  void close() {
    closed = true;
  }
}

class ResponseWithUrl extends http.StreamedResponse
    implements http.BaseResponseWithUrl {
  @override
  final Uri url;
  ResponseWithUrl(this.url) : super(Stream.value(original), 200);
}

void main() {
  final asset = catalog().packs.first.assets.first;
  test('official URL has exactly one object path encoding', () {
    expect(
      asset.mediaUri.toString(),
      'https://firebasestorage.googleapis.com/v0/b/ko-lernen-app.firebasestorage.app/o/learning-art%2Fv1%2F${asset.filename}?alt=media',
    );
    expect(asset.mediaUri.pathSegments.last, asset.storagePath);
  });
  test(
    'token attached lazily; transport preserves exact bytes and closes client',
    () async {
      var tokens = 0;
      final client = ControlledClient((request) async {
        expect(request.url, asset.mediaUri);
        expect(request.followRedirects, false);
        expect(request.headers['X-Firebase-AppCheck'], 'test-token');
        return http.StreamedResponse(
          Stream.value(original),
          200,
          contentLength: original.length,
        );
      });
      final transport = HanokAssetTransport(
        clientFactory: () => client,
        tokenProvider: () async {
          tokens++;
          return 'test-token';
        },
      );
      expect(tokens, 0);
      expect(await transport.fetch(asset), original);
      expect(tokens, 1);
      expect(client.closed, true);
    },
  );
  test('unexpected final URL is rejected even for a 200 response', () async {
    final client = ControlledClient(
      (_) async => ResponseWithUrl(Uri.https('unexpected.example', '/art')),
    );
    await expectLater(
      HanokAssetTransport(
        clientFactory: () => client,
        tokenProvider: () async => null,
      ).fetch(asset),
      throwsA(failure(HanokAssetFailureKind.network)),
    );
    expect(client.closed, true);
  });
  for (final status in [302, 403, 404, 500]) {
    test('status $status rejected and request closed', () async {
      final client = ControlledClient(
        (_) async => http.StreamedResponse(const Stream.empty(), status),
      );
      await expectLater(
        HanokAssetTransport(
          clientFactory: () => client,
          tokenProvider: () async => null,
        ).fetch(asset),
        throwsA(failure(HanokAssetFailureKind.network)),
      );
      expect(client.closed, true);
    });
  }
  test('wrong response length rejected before stream consumption', () async {
    var listened = false;
    final stream = StreamController<List<int>>(
      onListen: () {
        listened = true;
      },
    );
    final client = ControlledClient(
      (_) async =>
          http.StreamedResponse(stream.stream, 200, contentLength: 100),
    );
    await expectLater(
      HanokAssetTransport(
        clientFactory: () => client,
        tokenProvider: () async => null,
      ).fetch(asset),
      throwsA(failure(HanokAssetFailureKind.network)),
    );
    expect(listened, false);
    expect(client.closed, true);
    unawaited(stream.close());
  });
  test(
    'oversized streaming response cancelled without exposing bytes',
    () async {
      var cancelled = false;
      final stream = StreamController<List<int>>(
        onCancel: () {
          cancelled = true;
        },
      );
      final client = ControlledClient(
        (_) async => http.StreamedResponse(stream.stream, 200),
      );
      final result = HanokAssetTransport(
        clientFactory: () => client,
        tokenProvider: () async => null,
      ).fetch(asset);
      stream.add([1, 2, 3, 4, 5]);
      await expectLater(
        result,
        throwsA(failure(HanokAssetFailureKind.corrupt)),
      );
      expect(cancelled, true);
      expect(client.closed, true);
      await stream.close();
    },
  );
  for (final payload in [
    [1, 2],
    [1, 2, 3, 9],
  ]) {
    test('truncated or wrong hash body is rejected: $payload', () async {
      final client = ControlledClient(
        (_) async => http.StreamedResponse(Stream.value(payload), 200),
      );
      await expectLater(
        HanokAssetTransport(
          clientFactory: () => client,
          tokenProvider: () async => null,
        ).fetch(asset),
        throwsA(failure(HanokAssetFailureKind.corrupt)),
      );
      expect(client.closed, true);
    });
  }
  test(
    'token timeout closes client and late token cannot start request',
    () async {
      final token = Completer<String?>();
      var sends = 0;
      final client = ControlledClient((_) async {
        sends++;
        return http.StreamedResponse(Stream.value(original), 200);
      });
      final transport = HanokAssetTransport(
        clientFactory: () => client,
        tokenProvider: () => token.future,
        tokenTimeout: const Duration(milliseconds: 10),
      );
      await expectLater(
        transport.fetch(asset),
        throwsA(failure(HanokAssetFailureKind.network)),
      );
      token.complete('late');
      await Future<void>.delayed(Duration.zero);
      expect(sends, 0);
      expect(client.closed, true);
    },
  );
  test(
    'total deadline interrupts trickle stream and cancels subscription',
    () async {
      var cancelled = false;
      final stream = StreamController<List<int>>(
        onCancel: () {
          cancelled = true;
        },
      );
      final client = ControlledClient(
        (_) async => http.StreamedResponse(stream.stream, 200),
      );
      final transport = HanokAssetTransport(
        clientFactory: () => client,
        tokenProvider: () async => null,
        timeout: const Duration(milliseconds: 25),
      );
      final result = transport.fetch(asset);
      final timer = Timer.periodic(const Duration(milliseconds: 3), (_) {
        stream.add([]);
      });
      await expectLater(
        result,
        throwsA(failure(HanokAssetFailureKind.network)),
      );
      timer.cancel();
      expect(cancelled, true);
      expect(client.closed, true);
      await stream.close();
    },
  );
  test(
    'strict manifest rejects traversal, duplicate paths, ids and hash conflicts',
    () {
      final mutations = <void Function(Map<String, Object>)>[
        (json) {
          json['storageBucket'] = 'attacker.example';
        },
        (json) {
          json['schemaVersion'] = 2;
        },
        (json) {
          (json['packs'] as List).clear();
        },
        (json) {
          (json['packs'] as List).add((json['packs'] as List).first);
        },
        (json) {
          final p = (json['packs'] as List).first;
          (p['assets'] as List).add((p['assets'] as List).first);
        },
        (json) {
          final a = ((json['packs'] as List).first['assets'] as List).first;
          a['asset'] = 'assets/../escape.png';
        },
        (json) {
          final a = ((json['packs'] as List).first['assets'] as List).first;
          a['bytes'] = 0;
        },
        (json) {
          final a = ((json['packs'] as List).first['assets'] as List).first;
          a['sha256'] = 'AA';
        },
        (json) {
          final a = ((json['packs'] as List).first['assets'] as List).first;
          a['storagePath'] = 'other/${asset.filename}';
        },
        (json) {
          final a = ((json['packs'] as List).first['assets'] as List).first;
          a['contentType'] = 'image/webp';
        },
      ];
      for (final mutate in mutations) {
        final json = document([
          pack('house', [entry('first', original)]),
        ]);
        mutate(json);
        expect(
          () => HanokAssetManifest.parse(jsonEncode(json)),
          throwsFormatException,
        );
      }
    },
  );
}
