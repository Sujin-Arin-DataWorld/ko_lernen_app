import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/tts_private_cache.dart';

void main() {
  late CloudWriteSessionController sessions;
  late TtsPrivateCache cache;
  var now = DateTime.utc(2026, 9, 3);
  final bytes = Uint8List.fromList([0x49, 0x44, 0x33, ...List.filled(40, 7)]);
  setUp(() {
    sessions = CloudWriteSessionController()..acquire('alice');
    cache = TtsPrivateCache(sessions: sessions, now: () => now);
  });
  tearDown(() => cache.dispose());

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
        await cache.resolve(
          'key',
          fetch: fetch,
          serverExpiry: () => remoteExpiry,
        ),
        bytes,
      );
      now = now.add(const Duration(seconds: 1));
      expect(
        await cache.resolve(
          'key',
          fetch: fetch,
          serverExpiry: () => remoteExpiry,
        ),
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

      expect(await cache.resolve('key', fetch: fetch), bytes);
      expect(await cache.resolve('key', fetch: fetch), bytes);
      expect(calls, 1);
      sessions.acquire('bob');
      await cache.resolve('key', fetch: fetch);
      expect(calls, 2);
      now = now.add(const Duration(hours: 24));
      await cache.resolve('key', fetch: fetch);
      expect(calls, 3);
    },
  );

  test(
    'quiesce discards cached audio and fences in-flight completion',
    () async {
      final result = Completer<Uint8List?>();
      final pending = cache.resolve('key', fetch: () => result.future);
      sessions.transition(CloudWriteMode.quiesced);
      result.complete(bytes);
      expect(await pending, isNull);
      var fetched = false;
      expect(
        await cache.resolve(
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
      expect(await cache.resolve('key', fetch: () async => bytes), bytes);
    },
  );

  test(
    'clear during account deletion prevents late cache resurrection',
    () async {
      final result = Completer<Uint8List?>();
      final pending = cache.resolve('key', fetch: () => result.future);
      cache.clear();
      result.complete(bytes);
      expect(await pending, isNull);
    },
  );
}
