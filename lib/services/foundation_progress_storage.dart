part of 'storage_service.dart';

/// Strict native storage for the foundation path. Account reset closes its
/// admission synchronously and drains this queue before removing preferences.
abstract final class FoundationProgressStorage {
  static const preferenceKey = 'kl_foundation_progress_v1';
  static final changes = ValueNotifier(0);
  static Future<void>? _mutation;
  static String? _confirmedRaw;
  static int _generation = 0;

  static String readRawJson() {
    if (Storage._unknownStrictKeys.contains(preferenceKey)) {
      throw const PreferenceOutcomeUnknownException(preferenceKey);
    }
    if (_confirmedRaw case final confirmed?) {
      return confirmed;
    }
    final preferences = Storage._prefs;
    if (preferences == null) {
      throw const PreferenceWriteException(preferenceKey);
    }
    final raw = preferences.get(preferenceKey);
    if (raw != null && raw is! String) {
      throw const FormatException('Invalid native foundation progress type.');
    }
    return _confirmedRaw = raw as String? ?? '';
  }

  static Future<void> drain() => _mutation ?? Future<void>.value();

  /// External restore/reset invalidates confirmed views and retained writers.
  /// It never discards the pending queue that the reset owner must drain.
  static void invalidate() {
    _generation++;
    _confirmedRaw = null;
    changes.value++;
  }

  static Future<void> mutate(
    String Function(String before) update, {
    PreferenceStringStore? preferences,
    void Function()? assertCurrentWrite,
    bool restoring = false,
  }) {
    final lifetime = LocalDataLifetime.capture();
    final generation = _generation;
    void assertCurrent() {
      lifetime.assertCurrent();
      if (generation != _generation || Storage._learningResetCount > 0) {
        throw const StaleLocalDataLifetimeException();
      }
      assertCurrentWrite?.call();
      if (!restoring) {
        PackCompletionStorage.assertAdmission();
        if (Storage.learningWritesLockReason != null ||
            Storage._durableAccountJournalPreferenceKeys.any(
              (key) => Storage._prefs?.containsKey(key) ?? false,
            )) {
          throw const PackCompletionPendingException();
        }
      }
    }

    try {
      assertCurrent();
    } on Object catch (error, stack) {
      return Future<void>.error(error, stack);
    }
    final operation = (_mutation ?? Future<void>.value()).then((_) async {
      assertCurrent();
      final store = preferences ?? Storage._stringStore();
      if (Storage._unknownStrictKeys.contains(preferenceKey)) {
        // The update below is derived after this refresh, so it can safely
        // reconcile a lost native reply in the learner's explicit retry.
        await Storage._refreshUnknownStringKeys(store, [preferenceKey]);
        assertCurrent();
        _confirmedRaw = null;
      }
      final before = await Storage._prepareStringMutation(store, preferenceKey);
      assertCurrent();
      _confirmedRaw = before.value ?? '';
      final encoded = update(before.value ?? '');
      if (encoded == (before.value ?? '')) {
        return;
      }
      await Storage._ssStrict(
        preferenceKey,
        encoded,
        preferences: store,
        beforeState: before,
        assertCurrentWrite: assertCurrent,
      );
      // A successful transport reply is not itself durable evidence. Native
      // equality confirms success, including a false/lost reply after commit.
      final after = await Storage._reloadStringState(store, preferenceKey);
      // Native success from an old account must never reach a retained screen.
      assertCurrent();
      if (!after.isPresent || after.value != encoded) {
        if (after == before) {
          throw const PreferenceWriteException(preferenceKey);
        }
        Storage._unknownStrictKeys.add(preferenceKey);
        throw const PreferenceOutcomeUnknownException(preferenceKey);
      }
      _confirmedRaw = encoded;
      changes.value++;
    });
    final pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    _mutation = pending;
    unawaited(
      pending.then((_) {
        if (identical(_mutation, pending)) {
          _mutation = null;
        }
      }),
    );
    return operation;
  }
}
