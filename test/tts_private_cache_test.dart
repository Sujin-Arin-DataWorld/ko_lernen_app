import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/tts_private_cache.dart';

void main() {
  late CloudWriteSessionController sessions;
  late TtsPrivateCache cache;
  var now = DateTime.utc(2026, 9, 3);
  var elapsed = Duration.zero;
  final bytes = Uint8List.fromList([0x49, 0x44, 0x33, ...List.filled(40, 7)]);
  setUp(() {
    now = DateTime.utc(2026, 9, 3);
    elapsed = Duration.zero;
    sessions = CloudWriteSessionController()..acquire('alice');
    cache = TtsPrivateCache(
      sessions: sessions,
      now: () => now,
      elapsed: () => elapsed,
    );
  });
  tearDown(() => cache.dispose());

  Future<Uint8List?> resolve(
    String key, {
    required Future<Uint8List?> Function() fetch,
    DateTime? Function()? serverExpiry,
  }) async => (await cache.resolve(
    key,
    fetch: fetch,
    serverTiming: () => (
      serverNowMillis: now.millisecondsSinceEpoch,
      expiresAtMillis:
          (serverExpiry?.call() ?? now.add(const Duration(hours: 24)))
              .millisecondsSinceEpoch,
    ),
  ))?.bytes;

  test(
    'server expiry is never extended by a fresh local cache entry',
    () async {
      final remoteExpiry = now.add(const Duration(seconds: 1));
      var calls = 0;
      Future<Uint8List?> fetch() async {
        calls++;
        return bytes;
      }

      expect(
        await resolve('key', fetch: fetch, serverExpiry: () => remoteExpiry),
        bytes,
      );
      now = now.add(const Duration(seconds: 1));
      expect(
        await resolve('key', fetch: fetch, serverExpiry: () => remoteExpiry),
        isNull,
      );
      expect(calls, 2);
    },
  );

  test(
    'same key cannot replay private bytes across UID or expired TTL',
    () async {
      var calls = 0;
      Future<Uint8List?> fetch() async {
        calls++;
        return bytes;
      }

      expect(await resolve('key', fetch: fetch), bytes);
      expect(await resolve('key', fetch: fetch), bytes);
      expect(calls, 1);
      sessions.acquire('bob');
      await resolve('key', fetch: fetch);
      expect(calls, 2);
      now = now.add(const Duration(hours: 24));
      await resolve('key', fetch: fetch);
      expect(calls, 3);
    },
  );

  test(
    'quiesce discards cached audio and fences in-flight completion',
    () async {
      final result = Completer<Uint8List?>();
      final pending = resolve('key', fetch: () => result.future);
      sessions.transition(CloudWriteMode.quiesced);
      result.complete(bytes);
      expect(await pending, isNull);
      var fetched = false;
      expect(
        await resolve(
          'key',
          fetch: () async {
            fetched = true;
            return bytes;
          },
        ),
        isNull,
      );
      expect(fetched, isFalse);
      sessions.acquire('alice');
      expect(await resolve('key', fetch: () async => bytes), bytes);
    },
  );

  test(
    'clear during account deletion prevents late cache resurrection',
    () async {
      final result = Completer<Uint8List?>();
      final pending = resolve('key', fetch: () => result.future);
      cache.clear();
      result.complete(bytes);
      expect(await pending, isNull);
    },
  );

  test('clock rollback is sticky for an already resolved lease', () async {
    final audio = await cache.resolve(
      'key',
      fetch: () async => bytes,
      serverTiming: () => (serverNowMillis: 1000, expiresAtMillis: 2000),
    );
    now = now.add(const Duration(milliseconds: 500));
    expect(audio!.isCurrent, isTrue);
    now = now.subtract(const Duration(milliseconds: 1));
    expect(audio.isCurrent, isFalse);
    now = now.add(const Duration(milliseconds: 1));
    expect(audio.isCurrent, isFalse);
  });

  test('monotonic expiry does not rely on a progressing wall clock', () async {
    final audio = await cache.resolve(
      'key',
      fetch: () async => bytes,
      serverTiming: () => (serverNowMillis: 1000, expiresAtMillis: 2000),
    );
    elapsed += const Duration(seconds: 1);
    expect(audio!.isCurrent, isFalse);
  });

  test(
    'resolved lease cannot survive explicit private clear or disposal',
    () async {
      final audio = await cache.resolve(
        'key',
        fetch: () async => bytes,
        serverTiming: () => (serverNowMillis: 1000, expiresAtMillis: 2000),
      );
      expect(audio!.isCurrent, isTrue);
      cache.clear();
      expect(audio.isCurrent, isFalse);
      final next = await cache.resolve(
        'key',
        fetch: () async => bytes,
        serverTiming: () => (serverNowMillis: 1000, expiresAtMillis: 2000),
      );
      cache.dispose();
      expect(next!.isCurrent, isFalse);
    },
  );
}
