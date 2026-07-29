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
  _FakePreferenceRemovalStore({required this.keys, required this.results});

  final Set<String> keys;
  final Map<String, bool> results;
  final List<String> removals = <String>[];

  @override
  Set<String> getKeys() => keys;

  @override
  Future<bool> remove(String key) async {
    removals.add(key);
    return results[key] ?? true;
  }
}
