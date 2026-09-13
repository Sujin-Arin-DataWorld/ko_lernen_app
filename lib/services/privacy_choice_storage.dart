part of 'storage_service.dart';

enum PrivacyPurpose { analytics, crash, pronunciation }

/// Reads the same legacy backend as SharedPreferences without replacing its
/// shared learner cache. This app retains the legacy `flutter.` key prefix.
Future<Map<String, Object>> _readNativePrivacySnapshot(
  SharedPreferencesStorePlatform backend,
) async {
  final native = await backend.getAll();
  return {
    for (final key in [
      ...PrivacyChoiceStorage.keys.values,
      PrivacyChoiceStorage.ageKey,
    ])
      if (native.containsKey('flutter.$key')) key: native['flutter.$key']!,
  };
}

/// Only privacy reconciliation uses this isolated read view. Strict writes
/// retain their existing native setters and rejected/unknown outcome handling.
final class _PrivacyPreferenceStore
    implements PreferenceBoolStore, PreferenceIntStore {
  _PrivacyPreferenceStore(this.preferences, this.backend)
    : _snapshot = {
        for (final key in [
          ...PrivacyChoiceStorage.keys.values,
          PrivacyChoiceStorage.ageKey,
        ])
          if (preferences.containsKey(key)) key: preferences.get(key)!,
      };

  final SharedPreferences preferences;
  final SharedPreferencesStorePlatform backend;
  Map<String, Object> _snapshot;

  @override
  bool containsKey(String key) => _snapshot.containsKey(key);
  @override
  bool? getBool(String key) => _snapshot[key] as bool?;
  @override
  int? getInt(String key) => _snapshot[key] as int?;
  @override
  Future<void> reload() async {
    _snapshot = await _readNativePrivacySnapshot(backend);
  }

  @override
  Future<bool> setBool(String key, bool value) =>
      preferences.setBool(key, value);
  @override
  Future<bool> setInt(String key, int value) => preferences.setInt(key, value);
}

/// Device-local native confirmation, separate from SDK application.
final class PrivacyStoredChoice {
  PrivacyStoredChoice(this._confirmed);
  Object? _confirmed;
  Object? _desired;
  bool _pending = false;
  bool _failed = false;
  bool _denied = false;
  int _revision = 0;
  Future<void>? _active;
  Object? get confirmed => _confirmed;
  Object? get desired => _desired;
  bool get pending => _pending;
  bool get failed => _failed;
  bool get denied => _denied;
  int get revision => _revision;
  Future<void>? get active => _active;
  bool get granted =>
      _confirmed == true &&
      _desired != false &&
      !_pending &&
      !_failed &&
      !_denied;
}

/// Only the four existing optional privacy/age preferences live here.
/// Actual native work remains owned after a caller stops waiting.
abstract final class PrivacyChoiceStorage {
  static const keys = <PrivacyPurpose, String>{
    PrivacyPurpose.analytics: 'kl_analytics_consent',
    PrivacyPurpose.crash: 'kl_crash_consent',
    PrivacyPurpose.pronunciation: 'kl_pronunciation_consent_v1',
  };
  static const ageKey = 'kl_birth_year';
  static final changes = ValueNotifier<int>(0);
  static final _states = <String, PrivacyStoredChoice>{};
  static final _native = <Future<void>>{};
  static final _tails = <String, Future<void>>{};
  static int epoch = 0;
  static bool _closed = false;
  static bool _initialized = false;
  static bool _refreshRequired = false;

  static void _notify() {
    changes.value++;
  }

  static PrivacyStoredChoice choice(PrivacyPurpose purpose) =>
      _states.putIfAbsent(keys[purpose]!, () => PrivacyStoredChoice(null));
  static PrivacyStoredChoice get age =>
      _states.putIfAbsent(ageKey, () => PrivacyStoredChoice(null));
  static bool admitted(PrivacyPurpose purpose) =>
      _initialized && !_closed && !_refreshRequired && choice(purpose).granted;
  static int get birthYear =>
      _initialized &&
          !_closed &&
          !_refreshRequired &&
          !age._pending &&
          !age._failed &&
          !age._denied &&
          age._confirmed is int
      ? age._confirmed! as int
      : 0;

  static void initialize() {
    if (_initialized || Storage._prefs == null) {
      return;
    }
    for (final key in [...keys.values, ageKey]) {
      final value = Storage._prefs!.get(key);
      _states[key] = PrivacyStoredChoice(
        key == ageKey
            ? (value is int ? value : null)
            : (value is bool ? value : null),
      );
    }
    _initialized = true;
    _refreshRequired = false;
    _closed = false;
    _notify();
  }

  static Future<void> set(PrivacyPurpose purpose, bool value) =>
      _set(keys[purpose]!, value);
  static Future<void> setAge(int value) => _set(ageKey, value);

  static Future<void> _set(String key, Object value) {
    final prefs = Storage._prefs;
    final backend = SharedPreferencesStorePlatform.instance;
    if (!_initialized ||
        _closed ||
        prefs == null ||
        Storage._learningResetCount > 0) {
      return Future<void>.error(PreferenceWriteException(key));
    }
    final state = _states[key]!;
    if (state._pending && state._desired == value && state._active != null) {
      return state._active!;
    }
    final revision = ++state._revision;
    final ownerEpoch = epoch;
    final preceding = _tails[key];
    state
      .._desired = value
      .._pending = true
      .._failed = false
      .._denied = true;
    _notify();
    void assertOwner() {
      if (ownerEpoch != epoch ||
          revision != state._revision ||
          !identical(prefs, Storage._prefs) ||
          !identical(backend, SharedPreferencesStorePlatform.instance) ||
          _closed) {
        throw const StaleLocalDataLifetimeException();
      }
    }

    late final Future<void> work;
    work = () async {
      try {
        if (preceding != null) {
          await preceding;
        }
        assertOwner();
        final store = _PrivacyPreferenceStore(prefs, backend);
        if (key == ageKey) {
          await Storage._siStrict(
            key,
            value as int,
            preferences: store,
            assertCurrentWrite: assertOwner,
          );
        } else {
          await Storage._sbStrict(
            key,
            value as bool,
            preferences: store,
            assertCurrentWrite: assertOwner,
          );
        }
        assertOwner();
        state
          .._confirmed = value
          .._denied = false
          .._failed = false;
      } on Object {
        if (ownerEpoch == epoch && revision == state._revision) {
          state
            .._failed = true
            .._denied = true;
        }
        rethrow;
      } finally {
        if (ownerEpoch == epoch && revision == state._revision) {
          state
            .._pending = false
            .._active = null;
          _notify();
        }
      }
    }();
    state._active = work;
    final drain = work.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    _tails[key] = drain;
    _native.add(drain);
    drain.then((_) {
      _native.remove(drain);
      if (identical(_tails[key], drain)) {
        _tails.remove(key);
      }
    });
    return work;
  }

  static Future<void> drain() => Future.wait(_native.toList());

  /// Retire callbacks without laundering a failed off or late grant through a
  /// fresh cache. Rebind preserves only already confirmed local authority.
  static void retire({bool close = false}) {
    epoch++;
    _closed = close;
    _refreshRequired = true;
    for (final state in _states.values) {
      if (state._pending) {
        state
          .._denied = true
          .._failed = true;
      }
      state._revision++;
      state
        .._pending = false
        .._active = null;
    }
    _notify();
  }

  static Future<void> refresh() async {
    final ownerEpoch = epoch;
    final prefs = Storage._prefs;
    final backend = SharedPreferencesStorePlatform.instance;
    if (prefs == null) {
      return;
    }
    await drain();
    if (ownerEpoch != epoch || !identical(prefs, Storage._prefs)) {
      return;
    }
    final revisions = {
      for (final entry in _states.entries) entry.key: entry.value._revision,
    };
    try {
      final snapshot = await _readNativePrivacySnapshot(backend);
      if (ownerEpoch != epoch ||
          !identical(prefs, Storage._prefs) ||
          !identical(backend, SharedPreferencesStorePlatform.instance)) {
        return;
      }
      for (final entry in _states.entries) {
        final state = entry.value;
        if (state._revision != revisions[entry.key] ||
            state._pending ||
            state._denied) {
          continue;
        }
        final value = snapshot[entry.key];
        state._confirmed = entry.key == ageKey
            ? (value is int ? value : null)
            : (value is bool ? value : null);
      }
      _refreshRequired = false;
      _notify();
    } on Object {
      if (ownerEpoch == epoch) {
        for (final state in _states.values) {
          state._denied = true;
        }
        _notify();
      }
      debugPrint('Privacy: local authority refresh unavailable');
    }
  }

  static void reset() {
    retire(close: true);
    _states.clear();
    _initialized = false;
    // Never clear actual futures or per-key queues while native work exists.
  }
}
