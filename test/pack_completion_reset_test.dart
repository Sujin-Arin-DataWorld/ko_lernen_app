import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/pack_completion_record.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(Storage.resetForTesting);

  test(
    'cold direct retirement does not initialize native preferences',
    () async {
      final generation = PackCompletionStorage.presentationGeneration.value;
      await PackCompletionStorage.retire();
      expect(
        PackCompletionStorage.presentationGeneration.value,
        generation + 1,
      );
      expect(PackCompletionStorage.pending, isFalse);
      SharedPreferences.setMockInitialValues({
        PackCompletionRecord.key: 'broken',
      });
      await Storage.init();
      expect(PackCompletionStorage.invalid, isTrue);
    },
  );

  for (final strict in [false, true]) {
    for (final initialized in [false, true]) {
      test(
        'selected reset store owns retirement strict=$strict initialized=$initialized',
        () async {
          SharedPreferences? global;
          if (initialized) {
            SharedPreferences.setMockInitialValues({
              PackCompletionRecord.ownerKey: 'unrelated-global-owner',
            });
            await Storage.init();
            global = await SharedPreferences.getInstance();
          }
          final store = _RemovalStore();
          if (strict) {
            await Storage.resetAllStrict(preferences: store);
          } else {
            await Storage.resetAll(preferences: store);
          }
          expect(store.removals.take(2), [
            PackCompletionRecord.key,
            PackCompletionRecord.ownerKey,
          ]);
          expect(store.native, {'foreign': 'retained'});
          expect(
            global?.get(PackCompletionRecord.ownerKey),
            initialized ? 'unrelated-global-owner' : null,
          );
        },
      );
    }
  }

  for (final failure in [
    'false',
    'unknown-unapplied',
    'unknown-applied',
    'readback',
  ]) {
    test(
      'strict metadata retirement precedes learner deletion: $failure',
      () async {
        final store = _RemovalStore()..failure = failure;
        if (failure == 'unknown-applied') {
          await Storage.resetAllStrict(preferences: store);
          expect(store.native, {'foreign': 'retained'});
        } else {
          await expectLater(
            Storage.resetAllStrict(preferences: store),
            throwsA(
              anyOf(
                isA<PreferenceWriteException>(),
                isA<PreferenceOutcomeUnknownException>(),
              ),
            ),
          );
          expect(store.native['kl_learner'], 'kept-until-authority-gone');
          expect(store.native[PackCompletionRecord.ownerKey], 'old-owner');
          expect(store.removals, [PackCompletionRecord.key]);
        }
      },
    );
  }
}

class _RemovalStore implements PreferenceRemovalStore {
  final native = <String, Object>{
    PackCompletionRecord.key: 'old-completion',
    PackCompletionRecord.ownerKey: 'old-owner',
    'kl_learner': 'kept-until-authority-gone',
    'foreign': 'retained',
  };
  final removals = <String>[];
  Map<String, Object> cache = {};
  String? failure;
  bool unavailable = false;
  @override
  Set<String> getKeys() => cache.keys.toSet();
  @override
  bool containsKey(String key) => cache.containsKey(key);
  @override
  Object? getValue(String key) => cache[key];
  @override
  Future<void> reload() async {
    if (unavailable) {
      throw StateError('Native read unavailable');
    }
    cache = Map.of(native);
  }

  @override
  Future<bool> remove(String key) async {
    removals.add(key);
    cache.remove(key);
    if (key == PackCompletionRecord.key && failure != null) {
      if (failure == 'unknown-applied' || failure == 'readback') {
        native.remove(key);
      }
      if (failure == 'readback') {
        unavailable = true;
        return true;
      }
      if (failure == 'false') {
        return false;
      }
      throw StateError('Native removal reply unavailable');
    }
    native.remove(key);
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    native[key] = cache[key] = value;
    return true;
  }
}
