import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/tts_service.dart';
import 'package:ko_lernen_app/services/word_image_service.dart';

void main() {
  test(
    'strict word-image cleanup propagates directory lookup failure',
    () async {
      await expectLater(
        WordImageService.deleteAllStrict(
          documentsDirectory: () async =>
              throw StateError('documents unavailable'),
        ),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('ordinary word-image cleanup remains best effort', () async {
    await WordImageService.deleteAll(
      documentsDirectory: () async => throw StateError('documents unavailable'),
    );
  });

  test('cold TTS stop does not initialize a native audio player', () async {
    // Deliberately no Flutter binding or platform-channel mock: stopping an
    // unused service must not construct a plugin merely to release it.
    await TtsService.stop().timeout(const Duration(seconds: 2));
  });

  test('strict TTS cleanup propagates cache lookup failure', () async {
    await expectLater(
      TtsService.clearCacheStrict(
        cacheDirectory: () async => throw StateError('cache unavailable'),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('ordinary TTS cleanup remains best effort', () async {
    await TtsService.clearCache(
      cacheDirectory: () async => throw StateError('cache unavailable'),
    );
  });

  test(
    'strict preference reset attempts every app key and reports false',
    () async {
      final preferences = _FakePreferenceRemovalStore(
        keys: const {'kl_first', 'foreign_key', 'kl_second'},
        results: {'kl_first': false, 'kl_second': true},
      );

      await expectLater(
        Storage.resetAllStrict(preferences: preferences),
        throwsA(
          isA<PreferenceResetException>().having(
            (error) => error.failedKeys,
            'failedKeys',
            <String>['kl_first'],
          ),
        ),
      );

      expect(preferences.removals, <String>['kl_first', 'kl_second']);
    },
  );
}

class _FakePreferenceRemovalStore implements PreferenceRemovalStore {
  _FakePreferenceRemovalStore({
    required Set<String> keys,
    required this.results,
  }) : cache = {for (final key in keys) key: key},
       durable = {for (final key in keys) key: key};

  final Map<String, Object> cache;
  final Map<String, Object> durable;
  final Map<String, bool> results;
  final List<String> removals = <String>[];

  @override
  Set<String> getKeys() => cache.keys.toSet();

  @override
  bool containsKey(String key) => cache.containsKey(key);

  @override
  Object? getValue(String key) => cache[key];

  @override
  Future<void> reload() async {
    cache
      ..clear()
      ..addAll(durable);
  }

  @override
  Future<bool> remove(String key) async {
    removals.add(key);
    cache.remove(key);
    final result = results[key] ?? true;
    if (result) {
      durable.remove(key);
    }
    return result;
  }

  @override
  Future<bool> setString(String key, String value) async {
    cache[key] = value;
    durable[key] = value;
    return true;
  }
}
