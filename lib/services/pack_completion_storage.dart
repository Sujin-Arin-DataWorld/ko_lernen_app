part of 'storage_service.dart';

/// One fixed terminal transaction, not a general preference transaction API.
/// Admissions close synchronously, previously admitted owners drain, then the
/// immutable native plan is captured. Recovery never calls an additive writer.
abstract final class PackCompletionStorage {
  static final status = ValueNotifier(PackCompletionStatus.ready);

  /// Retires route-local acknowledged presentation without recreating a record.
  static final presentationGeneration = ValueNotifier(0);
  static PackCompletionRecord? _record;
  static PackCompletionRecord? _acknowledgement;
  static int? _acknowledgementGeneration;
  static bool _acknowledgementConfirmed = false;
  static bool _initialized = false;
  static bool _invalid = false;
  static bool _authorityConfirmed = false;
  static bool _preparing = false;
  static bool _retiring = false;
  static bool _snapshotting = false;
  static final Set<Future<void>> _nativeWrites = {};
  static Future<void>? _active;
  static Future<void> Function()? validateContent;
  static void Function()? onSettled;
  static final Object _writeZoneKey = Object();

  static PackCompletionRecord? get result =>
      _record?.settled == true && _authorityConfirmed ? _record : null;
  static PackCompletionRecord? get record => _record;
  static PackCompletionRecord? get acknowledgedResult =>
      _acknowledgementConfirmed &&
          !_retiring &&
          Storage._learningResetCount == 0 &&
          _acknowledgementGeneration == presentationGeneration.value
      ? _acknowledgement
      : null;
  static bool get invalid => _invalid;
  static bool get pending =>
      _invalid ||
      (_record != null && (!_record!.settled || !_authorityConfirmed));
  static bool get admissionClosed => _preparing || pending || _retiring;
  static bool get writesClosed => pending || _retiring || _snapshotting;

  static void initialize() {
    if (_initialized) {
      return;
    }
    _initialized = true;
    final raw = Storage._prefs?.get(PackCompletionRecord.key);
    if (raw == null) {
      return;
    }
    try {
      if (raw is! String) {
        throw const FormatException('Invalid native pack completion type.');
      }
      _record = PackCompletionRecord.decode(raw);
      status.value = PackCompletionStatus.retryRequired;
    } on Object {
      _invalid = true;
      status.value = PackCompletionStatus.blocked;
    }
  }

  static void resetForTesting() {
    _record = null;
    _acknowledgement = null;
    _acknowledgementGeneration = null;
    _acknowledgementConfirmed = false;
    _initialized = false;
    _authorityConfirmed = false;
    _invalid = false;
    _preparing = false;
    _retiring = false;
    _snapshotting = false;
    _nativeWrites.clear();
    _active = null;
    validateContent = null;
    onSettled = null;
    status.value = PackCompletionStatus.ready;
  }

  static void assertAdmission() {
    if (admissionClosed || Storage._learningResetCount > 0) {
      throw const PackCompletionPendingException();
    }
  }

  static void assertSnapshotReady() {
    if (admissionClosed) {
      throw const PackCompletionPendingException();
    }
  }

  static void assertWritableKey(String key) {
    if (writesClosed && PackCompletionRecord.stateKeys.contains(key)) {
      throw const PackCompletionPendingException();
    }
  }

  // Existing owner queues may enter these adapters while preparation drains.
  // Freeze new native entries only once those owners have finished, then drain
  // every already issued affected adapter before capturing the exact plan.
  static Future<T> trackWrite<T>(String key, Future<T> Function() work) {
    if (!PackCompletionRecord.stateKeys.contains(key) ||
        Zone.current[_writeZoneKey] == true) {
      return work();
    }
    assertWritableKey(key);
    final result = runZoned(work, zoneValues: {_writeZoneKey: true});
    final drain = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    _nativeWrites.add(drain);
    drain.then((_) => _nativeWrites.remove(drain));
    return result;
  }

  static bool get hasNativeWrites => _nativeWrites.isNotEmpty;

  static Future<void> drainNative() async {
    await Future.wait(_nativeWrites.toList());
  }

  /// A valid pending plan provides a coherent before-view. Invalid data does
  /// not authorize invented defaults: presentation gates intercept its readers.
  static Object? read(String key) {
    final current = _record;
    if (current != null &&
        !current.settled &&
        current.before.containsKey(key)) {
      return current.before[key];
    }
    return Storage._prefs?.get(key);
  }

  static Map<String, Object?> nativeState() => {
    for (final key in PackCompletionRecord.stateKeys)
      key: Storage._prefs!.get(key),
  };

  static bool _equal(Object? left, Object? right) =>
      jsonEncode(left) == jsonEncode(right);

  /// Owner generation is supplied by the local account authority boundary.
  /// The validator checks the live account and durable operation journals.
  static Future<String> Function()? confirmOwner;

  static Future<void> _assertAuthority(PackCompletionRecord record) async {
    if (_retiring ||
        Storage._learningResetCount > 0 ||
        Storage.learningWritesLockReason != null) {
      throw const PackCompletionPendingException();
    }
    try {
      final owner = await confirmOwner?.call();
      if (owner == null || owner != record.owner) {
        throw const PackCompletionPendingException();
      }
    } on Object {
      _authorityConfirmed = false;
      rethrow;
    }
  }

  static Future<void> admit(
    Future<PackCompletionRecord> Function(String owner) prepare, {
    required List<Future<void>> drains,
  }) {
    assertAdmission();
    if (_record != null || _active != null) {
      return Future.error(const PackCompletionPendingException());
    }
    _preparing = true;
    return _run(() async {
      await Future.wait(drains);
      _snapshotting = true;
      await drainNative();
      if (!await Storage.retrySrsRecovery()) {
        throw const SrsRecoveryPendingException();
      }
      final owner = await confirmOwner?.call();
      if (owner == null) {
        throw const PackCompletionPendingException();
      }
      await Storage.reloadForPackCompletion(Storage._prefs!);
      Storage.refreshPackCompletionCaches();
      final candidate = await prepare(owner);
      final raw = candidate.encode();
      // Validate the actual encoded boundary before the first durable effect.
      final checked = PackCompletionRecord.decode(raw);
      await _assertAuthority(checked);
      await Storage.reloadForPackCompletion(Storage._prefs!);
      if (Storage._prefs!.containsKey(PackCompletionRecord.key) ||
          !_equal(nativeState(), checked.before)) {
        throw const PackCompletionPendingException();
      }
      // Once the native admission call is issued, even a lost reply closes
      // conflicting writers until fresh native state determines its outcome.
      _record = checked;
      await _writeConfirmed(PackCompletionRecord.key, raw);
      await _recover();
    }, admission: true);
  }

  static Future<bool> retry() async {
    final running = _active;
    try {
      if (running != null) {
        await running.timeout(const Duration(seconds: 3));
      } else {
        await _run(_recover).timeout(const Duration(seconds: 3));
      }
      return result != null || !pending;
    } on Object {
      if (status.value != PackCompletionStatus.blocked) {
        status.value = PackCompletionStatus.retryRequired;
      }
      return false;
    }
  }

  static Future<void> _run(
    Future<void> Function() work, {
    bool admission = false,
  }) {
    late final Future<void> future;
    future = work()
        .catchError((Object error, StackTrace stack) async {
          // A rejected admission can reopen only after native absence is freshly
          // confirmed. Unknown native reads retain the pending candidate.
          if (admission) {
            try {
              await Storage.reloadForPackCompletion(Storage._prefs!);
              if (!Storage._prefs!.containsKey(PackCompletionRecord.key)) {
                _record = null;
              }
            } on Object {
              // Keep the issued admission and its fence for explicit retry.
            }
          }
          status.value = error is FormatException
              ? PackCompletionStatus.blocked
              : PackCompletionStatus.retryRequired;
          Error.throwWithStackTrace(error, stack);
        })
        .whenComplete(() {
          _preparing = false;
          _snapshotting = false;
          if (identical(_active, future)) {
            _active = null;
          }
        });
    _active = future;
    return future;
  }

  static Future<void> _recover() async {
    _authorityConfirmed = false;
    status.value = PackCompletionStatus.recovering;
    final preferences = Storage._prefs!;
    await Storage.reloadForPackCompletion(preferences);
    final raw = preferences.get(PackCompletionRecord.key);
    if (raw == null) {
      final acknowledgement = _acknowledgement;
      if (acknowledgement != null) {
        await _confirmAcknowledgement(
          acknowledgement,
          _acknowledgementGeneration!,
        );
      }
      _record = null;
      _invalid = false;
      status.value = PackCompletionStatus.ready;
      return;
    }
    if (raw is! String) {
      _invalid = true;
      throw const FormatException('Invalid pack completion native type.');
    }
    PackCompletionRecord current;
    try {
      current = PackCompletionRecord.decode(raw);
    } on FormatException {
      _invalid = true;
      rethrow;
    }
    _record = current;
    _invalid = false;
    await _assertAuthority(current);
    _authorityConfirmed = true;
    if (current.settled) {
      onSettled?.call();
      status.value = PackCompletionStatus.result;
      return;
    }
    var state = nativeState();
    final allAfter = _equal(state, current.after);
    if (!allAfter) {
      if (validateContent == null) {
        throw const PackCompletionPendingException();
      }
      await validateContent!();
      await _assertAuthority(current);
      await Storage.reloadForPackCompletion(preferences);
      state = nativeState();
      for (final key in PackCompletionRecord.stateKeys) {
        final value = state[key];
        if (!_equal(value, current.before[key]) &&
            !_equal(value, current.after[key]) &&
            !(key == PackCompletionRecord.packKey && value == current.boss)) {
          throw const PackCompletionPendingException();
        }
      }
      // Boss and next-pack are two persisted cuts in one native map.
      final packKey = PackCompletionRecord.packKey;
      if (!_equal(state[packKey], current.after[packKey])) {
        if (!_equal(state[packKey], current.boss)) {
          await _writeEffect(current, packKey, current.boss);
        }
        await _writeEffect(current, packKey, current.after[packKey]);
      }
      for (final key in PackCompletionRecord.writeOrder.skip(1)) {
        await _writeEffect(current, key, current.after[key]);
      }
    }
    await _assertAuthority(current);
    await Storage.reloadForPackCompletion(preferences);
    if (!_equal(nativeState(), current.after)) {
      throw const PackCompletionPendingException();
    }
    final settled = current.encode(settled: true);
    await _writeConfirmed(PackCompletionRecord.key, settled);
    _record = PackCompletionRecord.decode(settled);
    Storage.refreshPackCompletionCaches();
    onSettled?.call();
    status.value = PackCompletionStatus.result;
  }

  static Future<void> _writeEffect(
    PackCompletionRecord record,
    String key,
    Object? value,
  ) async {
    await _assertAuthority(record);
    await Storage.reloadForPackCompletion(Storage._prefs!);
    final native = Storage._prefs!.get(key);
    if (_equal(native, value)) {
      return;
    }
    if (!_equal(native, record.before[key]) &&
        !(key == PackCompletionRecord.packKey && native == record.boss)) {
      throw const PackCompletionPendingException();
    }
    if (_retiring || Storage._learningResetCount > 0) {
      throw const PackCompletionPendingException();
    }
    await _writeConfirmed(key, value);
  }

  /// Every return requires a fresh native read, including a `true` reply.
  static Future<void> _writeConfirmed(String key, Object? value) async {
    final preferences = Storage._prefs!;
    Object? failure;
    try {
      if (value == null) {
        await preferences.remove(key);
      } else if (value is String) {
        await preferences.setString(key, value);
      } else if (value is List) {
        await preferences.setStringList(key, value.cast<String>());
      } else {
        throw const FormatException('Unsupported terminal native value.');
      }
    } on Object catch (error) {
      failure = error;
    }
    try {
      await Storage.reloadForPackCompletion(preferences);
    } on Object catch (error) {
      throw PreferenceOutcomeUnknownException(key, cause: error);
    }
    if (!_equal(preferences.get(key), value)) {
      throw PreferenceWriteException(key, cause: failure);
    }
  }

  /// Owns a retained route's account check through any native association write.
  /// Retirement drains it exactly as it drains completion acknowledgement.
  static Future<bool> confirmAcknowledgedOwner(
    String owner,
    int generation,
  ) async {
    if (_active != null ||
        admissionClosed ||
        Storage._learningResetCount > 0 ||
        Storage.learningWritesLockReason != null ||
        generation != presentationGeneration.value) {
      return false;
    }
    late final Future<void> work;
    work = PackCompletionOwner.confirm(acceptedOwner: owner)
        .then<void>((_) {
          if (_retiring || generation != presentationGeneration.value) {
            throw const PackCompletionPendingException();
          }
        })
        .whenComplete(() {
          if (identical(_active, work)) {
            _active = null;
          }
        });
    _active = work;
    try {
      await work.timeout(const Duration(seconds: 3));
      return true;
    } on Object {
      return false;
    }
  }

  static Future<bool> acknowledge(String id) async {
    if (_active != null) {
      return false;
    }
    final confirmed = acknowledgedResult;
    if (confirmed?.id == id) {
      return confirmAcknowledgedOwner(
        confirmed!.owner,
        presentationGeneration.value,
      );
    }
    final current = result;
    if (current?.id != id) {
      return false;
    }
    final generation = presentationGeneration.value;
    try {
      await _run(() async {
        await _assertAuthority(current!);
        await Storage.reloadForPackCompletion(Storage._prefs!);
        final native = Storage._prefs!.get(PackCompletionRecord.key);
        final admitted =
            _acknowledgement?.id == id &&
            _acknowledgementGeneration == generation;
        if (_retiring ||
            Storage._learningResetCount > 0 ||
            Storage.learningWritesLockReason != null ||
            generation != presentationGeneration.value ||
            (native != current.encode() && !(admitted && native == null))) {
          throw const PackCompletionPendingException();
        }
        // Only this exact, currently owned result authorizes the first remove.
        _acknowledgement = current;
        _acknowledgementGeneration = generation;
        _acknowledgementConfirmed = false;
        await _writeConfirmed(PackCompletionRecord.key, null);
        await _confirmAcknowledgement(current, generation);
        _record = null;
        status.value = PackCompletionStatus.ready;
      }).timeout(const Duration(seconds: 3));
      return true;
    } on Object {
      return false;
    }
  }

  static Future<void> _confirmAcknowledgement(
    PackCompletionRecord original,
    int generation,
  ) async {
    _acknowledgementConfirmed = false;
    if (_retiring ||
        Storage._learningResetCount > 0 ||
        Storage.learningWritesLockReason != null ||
        generation != presentationGeneration.value ||
        !identical(_acknowledgement, original)) {
      throw const PackCompletionPendingException();
    }
    await PackCompletionOwner.confirm(acceptedOwner: original.owner);
    if (_retiring ||
        generation != presentationGeneration.value ||
        !identical(_acknowledgement, original) ||
        Storage._prefs!.get(PackCompletionRecord.key) != null) {
      throw const PackCompletionPendingException();
    }
    _acknowledgementConfirmed = true;
  }

  /// Called by the existing destructive owner before any learner replacement.
  /// It drains issued native calls; timeout wrappers never release this drain.
  static Future<void> retire({
    PreferenceRemovalStore? preferences,
    void Function()? beforeRetire,
  }) async {
    _retiring = true;
    presentationGeneration.value += 1;
    _acknowledgement = null;
    _acknowledgementGeneration = null;
    _acknowledgementConfirmed = false;
    try {
      try {
        await _active;
      } on Object {
        // Retirement preserves already committed effects, not stale callbacks.
      }
      if (hasNativeWrites) {
        await drainNative();
      }
      final store =
          preferences ??
          (Storage._prefs == null
              ? null
              : _SharedPreferenceRemovalStore(Storage._prefs!));
      if (store != null) {
        await _reloadRetirementStore(store);
        if (store.containsKey(PackCompletionRecord.key) ||
            store.containsKey(PackCompletionRecord.ownerKey)) {
          beforeRetire?.call();
          // Authority must be gone before any learner-data wipe may proceed.
          await _removeRetirementKey(store, PackCompletionRecord.key);
          await _removeRetirementKey(store, PackCompletionRecord.ownerKey);
        }
      }
      _record = null;
      _invalid = false;
      status.value = PackCompletionStatus.ready;
    } finally {
      _retiring = false;
    }
  }

  static Future<void> _reloadRetirementStore(PreferenceRemovalStore store) =>
      store is _SharedPreferenceRemovalStore
      ? Storage.reloadForPackCompletion(store.preferences)
      : store.reload();

  static Future<void> _removeRetirementKey(
    PreferenceRemovalStore store,
    String key,
  ) async {
    Object? failure;
    try {
      await store.remove(key);
    } on Object catch (error) {
      failure = error;
    }
    try {
      await _reloadRetirementStore(store);
    } on Object catch (error) {
      throw PreferenceOutcomeUnknownException(key, cause: error);
    }
    if (store.containsKey(key)) {
      throw PreferenceWriteException(key, cause: failure);
    }
  }
}
