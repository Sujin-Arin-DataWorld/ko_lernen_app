import 'dart:convert';

import 'package:flutter/foundation.dart'
    show debugPrint, listEquals, visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';

import 'storage_service.dart';

/// 로컬 데이터 마이그레이션 한 단계. 여러 번 실행돼도 안전해야 한다(멱등).
typedef DataMigrationStep = Future<void> Function(SharedPreferences prefs);

/// 앱 시작 시 로컬 스키마를 점검한 결과.
enum DataMigrationStatus {
  /// 저장된 학습 데이터가 없는 새 설치. 현재 버전으로 바로 도장을 찍었다.
  fresh,

  /// 이미 현재 버전. 할 일 없음.
  upToDate,

  /// 단계를 실행해 현재 버전으로 올렸다.
  migrated,

  /// 안전한 완료를 확인하지 못했다. 복구가 필요할 수 있어 쓰기를 잠갔다.
  failed,

  /// 저장된 버전이 앱보다 **새롭다**(다운그레이드). 옛 코드가 새 포맷을
  /// 망가뜨리지 않도록 학습 데이터 쓰기를 잠갔다.
  futureVersion,
}

/// 자유 텍스트나 사용자 데이터를 포함하지 않는 실패 분류.
enum DataMigrationFailureCode {
  alreadyRunning,
  invalidMetadata,
  invalidBackup,
  readFailed,
  writeRejected,
  writeFailed,
  stepFailed,
  recoveryFailed,
  outcomeUnknown,
}

enum DataMigrationPhase {
  acquire,
  read,
  prepare,
  steps,
  commit,
  restore,
  cleanup,
}

/// 마이그레이션 결과 스냅샷.
class DataMigrationResult {
  const DataMigrationResult({
    required this.status,
    required this.fromVersion,
    required this.toVersion,
    this.error,
    this.failureCode,
    this.failurePhase,
    this.cleanupPending = false,
  });

  final DataMigrationStatus status;
  final int? fromVersion;
  final int toVersion;
  final Object? error;
  final DataMigrationFailureCode? failureCode;
  final DataMigrationPhase? failurePhase;
  final bool cleanupPending;

  /// 학습 데이터 write 를 허용해도 되는 상태인지.
  bool get writesAllowed =>
      status != DataMigrationStatus.failed &&
      status != DataMigrationStatus.futureVersion;

  /// Crashlytics custom key 로 보내기 적합한 짧은 값. 자유 텍스트·PII 없음.
  String get diagnosticValue {
    final version = '${fromVersion ?? 'unknown'}→$toVersion';
    final failure = failureCode;
    if (failure != null) {
      return '${status.name}:$version:${failure.name}:${failurePhase?.name}';
    }
    return '${status.name}:$version';
  }

  @override
  String toString() => 'DataMigrationResult($diagnosticValue)';
}

/// 로컬 데이터 스키마 버전과 마이그레이션을 관리한다.
///
/// 출시 후 가장 위험한 문제 중 하나는 **기존 사용자의 로컬 데이터가 새 버전에서
/// 깨지는 것**이다. 그래서 원칙을 코드로 못 박는다:
///
/// - 마이그레이션은 여러 번 실행돼도 안전하다(각 단계가 멱등).
/// - 중간 실패 시 재시도 가능하다(journal + 백업 복원).
/// - 마이그레이션 **전에** 백업을 만든다.
/// - **완료된 뒤에만** 스키마 버전을 올린다.
/// - 복원은 원본 값을 먼저 쓰고, 그 뒤에만 새로 생긴 `kl_` 키를 지운다.
///
/// SharedPreferences는 원자적 트랜잭션/전원 손실 내구성을 보장하지 않는다.
/// 여기서는 native reload로 관측된 결과만 판단한다. Storage의 잠금 범위는
/// 기존 SRS/팩 학습 쓰기뿐이며, 다른 저장 경로의 전역 잠금은 아니다.
///
/// ## 지금 등록된 단계가 없는 이유
///
/// [_productionSteps] 는 의도적으로 비어 있다. 아직 포맷을 깨는 변경이 없었고,
/// **없는 마이그레이션을 지어내는 것이 진짜 마이그레이션보다 위험**하기 때문이다.
/// 이 서비스가 지금 하는 일은 세 가지다:
///
/// 1. 기존 설치에 baseline 버전 도장을 찍어, 다음 포맷 변경 때 "이 사용자가
///    어느 포맷에서 왔는지"를 알 수 있게 한다.
/// 2. **다운그레이드를 막는다** — 이건 지금 당장 실제로 데이터를 지킨다.
/// 3. 진단 키(`schemaVersion`)를 제공한다.
///
/// 러너 자체는 주입된 단계로 전수 테스트된다(`test/data_migration_test.dart`).
/// 실제 프로덕션 단계를 등록하기 전에는 별도의 startup/cloud 쓰기 정지
/// (quiescence) 검토가 필수다. 현재 잠금은 XP·전체 `kl_`·클라우드 복원을 막지
/// 않으므로, 버전 번호와 단계만 추가해 앱 시작 안전성이 확보되지는 않는다.
abstract final class DataMigrationService {
  /// 이 앱 빌드가 이해하는 로컬 스키마 버전.
  ///
  /// 포맷을 깨는 변경을 넣을 때만 올린다. 올릴 때는 [_productionSteps] 에 새
  /// 버전 번호를 키로 하는 단계를 반드시 함께 추가한다.
  static const int currentSchemaVersion = 1;

  static const String versionPreferenceKey = 'kl_schema_version';
  static const String journalPreferenceKey = 'kl_migration_journal_v1';
  static const String backupPreferenceKey = 'kl_migration_backup_v1';

  /// 프로덕션 마이그레이션 단계. 키 = 그 단계를 마치면 도달하는 버전.
  static const Map<int, DataMigrationStep> _productionSteps =
      <int, DataMigrationStep>{};

  /// 기존 설치를 "새 설치"와 구별하는 표식.
  ///
  /// 하나라도 있으면 이미 학습한 사용자다. 버전 키가 없다는 이유로 새 설치처럼
  /// 다루면 나중에 잘못된 baseline 에서 마이그레이션이 시작된다.
  static const List<String> _existingInstallMarkers = <String>[
    'kl_srs_v1',
    'kl_pack_progress_v1',
    'kl_course_mastery_v2',
    'kl_course_mastery_v1',
    'kl_onboarding_completed',
    'kl_xp',
    Storage.listeningRewardLedgerPreferenceKey,
  ];

  static DataMigrationResult? _lastResult;
  static bool _running = false;

  /// 이번 실행의 마이그레이션 결과. [run] 전에는 null.
  static DataMigrationResult? get lastResult => _lastResult;

  @visibleForTesting
  static void resetForTesting() {
    _lastResult = null;
  }

  /// 앱 시작 시 `Storage.init()` 직후·`runApp` 전에 호출한다.
  ///
  /// 로컬 전용이라 빠르다. 네트워크·Firebase 를 건드리지 않으므로 시작 지연이
  /// 없고, 실패해도 앱은 뜬다(쓰기만 잠근다).
  static Future<DataMigrationResult> run({
    @visibleForTesting Map<int, DataMigrationStep>? steps,
    @visibleForTesting SharedPreferences? preferences,
    @visibleForTesting int? targetVersion,
  }) {
    final target = targetVersion ?? currentSchemaVersion;
    // Admission precedes every await. Reentrant callers must not await the
    // active Future or change its lock, journal or lastResult.
    if (_running) {
      return Future.value(
        DataMigrationResult(
          status: DataMigrationStatus.failed,
          fromVersion: null,
          toVersion: target,
          failureCode: DataMigrationFailureCode.alreadyRunning,
          failurePhase: DataMigrationPhase.acquire,
        ),
      );
    }
    _running = true;
    Storage.lockLearningWrites('migration:acquire');
    return _runOwned(preferences, target, steps ?? _productionSteps);
  }

  static Future<DataMigrationResult> _runOwned(
    SharedPreferences? preferences,
    int target,
    Map<int, DataMigrationStep> registry,
  ) async {
    try {
      return _finish(
        await _MigrationRun(preferences, target, registry).execute(),
      );
    } finally {
      _running = false;
    }
  }

  static DataMigrationResult _finish(DataMigrationResult result) {
    _lastResult = result;
    debugPrint('DataMigration: $result');
    return result;
  }
}

const _versionKey = DataMigrationService.versionPreferenceKey;
const _backupKey = DataMigrationService.backupPreferenceKey;
const _journalKey = DataMigrationService.journalPreferenceKey;

bool _isDataKey(String key) =>
    key.startsWith('kl_') && key != _backupKey && key != _journalKey;

class _MigrationFailure implements Exception {
  const _MigrationFailure(this.code, this.phase);
  final DataMigrationFailureCode code;
  final DataMigrationPhase phase;
}

/// State belongs to one admitted invocation, never to overlapping callers.
class _MigrationRun {
  _MigrationRun(this._preferences, this.target, this.registry);

  final SharedPreferences? _preferences;
  final int target;
  final Map<int, DataMigrationStep> registry;
  SharedPreferences? _loaded;
  SharedPreferences get prefs => _loaded!;
  DataMigrationPhase phase = DataMigrationPhase.acquire;
  int? from;
  int? originalMarker;
  bool stepsStarted = false;
  bool committed = false;

  Future<DataMigrationResult> execute() async {
    try {
      _loaded = _preferences ?? await SharedPreferences.getInstance();
      phase = DataMigrationPhase.read;
      await _reload();
      if (target <= 0) {
        throw _failure(DataMigrationFailureCode.invalidMetadata);
      }
      originalMarker = _readMarker();
      from = originalMarker ?? _inferBaseline(prefs.getKeys(), target);
      if (from! > target) {
        return DataMigrationResult(
          status: DataMigrationStatus.futureVersion,
          fromVersion: from,
          toVersion: target,
        );
      }

      var recovery = _readRecovery(originalMarker);
      if (recovery != null && originalMarker == recovery.journal.to) {
        // A marker at the journal destination is committed, even if the
        // previous setter threw after persistence. Never restore this backup.
        if (originalMarker == target) {
          committed = true;
          return _success(
            DataMigrationStatus.upToDate,
            cleanupFailure: await _cleanup(),
          );
        }
        // Finish an older committed transaction before starting a newer one.
        final cleanupFailure = await _cleanup();
        if (cleanupFailure != null) {
          throw cleanupFailure;
        }
        recovery = null;
      } else if (recovery != null) {
        // An interrupted unstamped migration may have removed all install
        // markers. Infer from the validated original, not the partial dataset.
        from = recovery.journal.from;
        await _restore();
      }

      if (originalMarker == target) {
        return _success(DataMigrationStatus.upToDate);
      }
      if (from == target) {
        // A new install only needs its first stamp, with the same native commit
        // reconciliation as a real migration. There are no steps to roll back.
        await _commit();
        return _success(DataMigrationStatus.fresh);
      }

      final pending =
          registry.keys
              .where((version) => version > from! && version <= target)
              .toList()
            ..sort();

      if (pending.isEmpty && recovery == null) {
        // A version bump with no registered steps needs only its stamp — the
        // same native commit reconciliation as a real migration, but without
        // capturing every `kl_` key into a second preference (double storage)
        // or risking `invalidBackup` on an unusual value type for a release
        // that never touches data. `stepsStarted` stays false: there is
        // nothing to restore, because nothing but the version marker moved.
        await _commit();
        return _success(
          DataMigrationStatus.migrated,
          cleanupFailure: await _cleanup(),
        );
      }

      phase = DataMigrationPhase.prepare;
      if (recovery == null) {
        final snapshot = _Snapshot.capture(prefs, phase);
        final raw = snapshot.encode();
        await _checked(() => prefs.setString(_backupKey, raw));
        await _reload();
        if (prefs.get(_backupKey) != raw) {
          throw _failure(DataMigrationFailureCode.writeRejected);
        }
      }
      await _writeJournal();
      // Check the complete persisted pair and original marker before steps.
      _readRecovery(_readMarker());

      stepsStarted = true;
      for (final version in pending) {
        phase = DataMigrationPhase.steps;
        try {
          await registry[version]!(prefs);
        } catch (_) {
          throw _failure(DataMigrationFailureCode.stepFailed);
        }
        await _writeJournal(step: version);
      }
      await _commit();
      return _success(
        DataMigrationStatus.migrated,
        cleanupFailure: await _cleanup(),
      );
    } catch (error) {
      var failure = error is _MigrationFailure
          ? error
          : _failure(DataMigrationFailureCode.readFailed);
      if (stepsStarted &&
          !committed &&
          failure.code != DataMigrationFailureCode.outcomeUnknown) {
        try {
          await _restore();
        } on _MigrationFailure catch (restoreFailure) {
          failure = restoreFailure;
        } catch (_) {
          failure = _failure(DataMigrationFailureCode.recoveryFailed);
        }
      }
      await _refreshAfterFailure();
      final result = DataMigrationResult(
        status: DataMigrationStatus.failed,
        fromVersion: from,
        toVersion: target,
        failureCode: failure.code,
        failurePhase: failure.phase,
      );
      Storage.lockLearningWrites(result.diagnosticValue);
      return result;
    } finally {
      // Also invalidate on partial writes and failed restores. SharedPreferences
      // itself can remain unverified after a reload failure; writes stay locked.
      // Runs on every execute() call, including the upToDate/fresh/no-step-bump
      // no-op paths — that per-startup cost is accepted so this stays one rule
      // ("any exit invalidates") instead of a path-dependent one that a future
      // added branch could silently fall outside of.
      Storage.resetCachesAfterExternalWrite();
    }
  }

  DataMigrationResult _success(
    DataMigrationStatus status, {
    _MigrationFailure? cleanupFailure,
  }) {
    Storage.unlockLearningWrites();
    return DataMigrationResult(
      status: status,
      fromVersion: from,
      toVersion: target,
      cleanupPending: cleanupFailure != null,
      failureCode: cleanupFailure?.code,
      failurePhase: cleanupFailure?.phase,
    );
  }

  _MigrationFailure _failure(DataMigrationFailureCode code) =>
      _MigrationFailure(code, phase);

  Future<void> _checked(Future<bool> Function() mutation) async {
    final bool accepted;
    try {
      accepted = await mutation();
    } catch (_) {
      throw _failure(DataMigrationFailureCode.writeFailed);
    }
    if (!accepted) {
      throw _failure(DataMigrationFailureCode.writeRejected);
    }
  }

  Future<void> _reload({
    DataMigrationFailureCode code = DataMigrationFailureCode.readFailed,
  }) async {
    try {
      await prefs.reload();
    } catch (_) {
      throw _failure(code);
    }
  }

  Future<void> _refreshAfterFailure() async {
    if (_loaded != null) {
      try {
        await prefs.reload();
      } catch (_) {
        // The typed failure remains the only diagnostic. Never print data or
        // exceptions from the persistence platform.
      }
    }
  }

  int? _readMarker() {
    if (!prefs.containsKey(_versionKey)) {
      return null;
    }
    final marker = prefs.get(_versionKey);
    if (marker is! int || marker <= 0) {
      throw _failure(DataMigrationFailureCode.invalidMetadata);
    }
    return marker;
  }

  _Recovery? _readRecovery(int? marker) {
    final hasJournal = prefs.containsKey(_journalKey);
    final hasBackup = prefs.containsKey(_backupKey);
    if (!hasJournal) {
      if (hasBackup) {
        // Without a journal there is no trusted destination/commit relation.
        throw _failure(DataMigrationFailureCode.invalidBackup);
      }
      return null;
    }
    final journal = _Journal.parse(prefs.get(_journalKey), phase);
    if (journal.to > target) {
      throw _failure(DataMigrationFailureCode.invalidMetadata);
    }
    final snapshot = hasBackup
        ? _Snapshot.parse(prefs.get(_backupKey), phase)
        : null;
    if (snapshot != null) {
      final original = snapshot.values[_versionKey];
      final baseline =
          original ?? _inferBaseline(snapshot.values.keys, journal.to);
      if (baseline != journal.from) {
        throw _failure(DataMigrationFailureCode.invalidBackup);
      }
      if (marker != original && marker != journal.to) {
        throw _failure(DataMigrationFailureCode.invalidMetadata);
      }
    } else if (marker != journal.to) {
      // Backup-first cleanup may legitimately leave only a committed journal.
      throw _failure(DataMigrationFailureCode.invalidBackup);
    }
    return _Recovery(journal, snapshot);
  }

  Future<void> _writeJournal({int? step}) async {
    final raw = jsonEncode({
      'from': from,
      'to': target,
      'phase': step == null ? 'started' : 'step_done',
      if (step != null) 'step': step,
    });
    await _checked(() => prefs.setString(_journalKey, raw));
    await _reload();
    if (prefs.get(_journalKey) != raw) {
      throw _failure(DataMigrationFailureCode.writeRejected);
    }
  }

  Future<void> _commit() async {
    if (stepsStarted) {
      // A step may have damaged the recovery metadata. Verify the full pair
      // again before committing; malformed recovery evidence is not disposable.
      if (_readRecovery(_readMarker()) == null) {
        throw _failure(DataMigrationFailureCode.invalidBackup);
      }
    }
    phase = DataMigrationPhase.commit;
    _MigrationFailure? writeFailure;
    try {
      await _checked(() => prefs.setInt(_versionKey, target));
    } on _MigrationFailure catch (failure) {
      writeFailure = failure;
    }
    // shared_preferences 2.5.5 changes its cache before the native result. Both
    // false and thrown writes may require reconciliation, never cached reads.
    await _reload(code: DataMigrationFailureCode.outcomeUnknown);
    final marker = prefs.get(_versionKey);
    if (marker is int && marker == target) {
      committed = true;
      return;
    }
    if ((marker is int || marker == null) &&
        marker == originalMarker &&
        (marker != null || !prefs.containsKey(_versionKey))) {
      throw writeFailure ?? _failure(DataMigrationFailureCode.writeRejected);
    }
    throw _failure(DataMigrationFailureCode.outcomeUnknown);
  }

  Future<void> _restore() async {
    phase = DataMigrationPhase.restore;
    try {
      await _reload(code: DataMigrationFailureCode.recoveryFailed);
      final marker = _readMarker();
      final recovery = _readRecovery(marker);
      final snapshot = recovery?.snapshot;
      if (recovery == null || snapshot == null) {
        throw _failure(DataMigrationFailureCode.invalidBackup);
      }
      if (marker == recovery.journal.to) {
        // Only _commit is allowed to establish commitment in this invocation.
        // An unexpected marker changed by a step must not trigger a rollback.
        throw _failure(DataMigrationFailureCode.outcomeUnknown);
      }
      // Validate everything above before the first write or removal below.
      for (final entry in snapshot.values.entries) {
        await _checked(() => _setValue(entry.key, entry.value));
      }
      for (final key in prefs.getKeys().where(_isDataKey).toList()) {
        if (!snapshot.values.containsKey(key)) {
          await _checked(() => prefs.remove(key));
        }
      }
      await _reload(code: DataMigrationFailureCode.recoveryFailed);
      if (!snapshot.matches(prefs)) {
        throw _failure(DataMigrationFailureCode.recoveryFailed);
      }
    } on _MigrationFailure catch (failure) {
      if (failure.code == DataMigrationFailureCode.writeFailed ||
          failure.code == DataMigrationFailureCode.writeRejected) {
        throw _failure(DataMigrationFailureCode.recoveryFailed);
      }
      rethrow;
    } finally {
      Storage.resetCachesAfterExternalWrite();
    }
  }

  Future<bool> _setValue(String key, Object value) => switch (value) {
    String v => prefs.setString(key, v),
    int v => prefs.setInt(key, v),
    double v => prefs.setDouble(key, v),
    bool v => prefs.setBool(key, v),
    List<String> v => prefs.setStringList(key, v),
    _ => throw _failure(DataMigrationFailureCode.invalidBackup),
  };

  Future<_MigrationFailure?> _cleanup() async {
    phase = DataMigrationPhase.cleanup;
    try {
      await _reload();
      final marker = _readMarker();
      final recovery = _readRecovery(marker);
      if (recovery != null && marker != recovery.journal.to) {
        throw _failure(DataMigrationFailureCode.invalidMetadata);
      }
      // Leave the journal until backup removal is confirmed, so a restart can
      // distinguish committed cleanup from an orphan original snapshot.
      for (final key in [_backupKey, _journalKey]) {
        if (prefs.containsKey(key)) {
          await _checked(() => prefs.remove(key));
          await _reload();
          if (prefs.containsKey(key)) {
            throw _failure(DataMigrationFailureCode.writeRejected);
          }
        }
      }
      return null;
    } on _MigrationFailure catch (failure) {
      if (failure.code == DataMigrationFailureCode.invalidBackup ||
          failure.code == DataMigrationFailureCode.invalidMetadata) {
        rethrow;
      }
      await _refreshAfterFailure();
      return failure;
    }
  }
}

int _inferBaseline(Iterable<String> keys, int target) =>
    DataMigrationService._existingInstallMarkers.any(keys.contains)
    ? 1
    : target;

class _Recovery {
  const _Recovery(this.journal, this.snapshot);
  final _Journal journal;
  final _Snapshot? snapshot;
}

class _Journal {
  const _Journal(this.from, this.to);
  final int from;
  final int to;

  static _Journal parse(Object? raw, DataMigrationPhase phase) {
    final failure = _MigrationFailure(
      DataMigrationFailureCode.invalidMetadata,
      phase,
    );
    try {
      if (raw is! String) {
        throw failure;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw failure;
      }
      final from = decoded['from'];
      final to = decoded['to'];
      final state = decoded['phase'];
      if (from is! int || to is! int || from <= 0 || to <= from) {
        throw failure;
      }
      if (state == 'started' && decoded.length == 3) {
        return _Journal(from, to);
      }
      final step = decoded['step'];
      if (state == 'step_done' &&
          decoded.length == 4 &&
          step is int &&
          step > from &&
          step <= to) {
        return _Journal(from, to);
      }
      throw failure;
    } catch (_) {
      throw failure;
    }
  }
}

class _Snapshot {
  const _Snapshot(this.values);
  final Map<String, Object> values;

  static _Snapshot capture(SharedPreferences prefs, DataMigrationPhase phase) {
    final values = <String, Object>{};
    for (final key in prefs.getKeys().where(_isDataKey)) {
      final value = prefs.get(key);
      if (value is String ||
          value is bool ||
          value is int ||
          (value is double && value.isFinite) ||
          (value is List && value.every((item) => item is String))) {
        // Native codecs may return List<Object?> for a string array. Validate
        // all elements before normalizing the snapshot's in-memory type.
        values[key] = value is List ? List<String>.from(value) : value!;
      } else {
        throw _MigrationFailure(DataMigrationFailureCode.invalidBackup, phase);
      }
    }
    return _Snapshot(values);
  }

  String encode() => jsonEncode(
    values.map(
      (key, value) => MapEntry(key, {
        't': switch (value) {
          String() => 's',
          int() => 'i',
          double() => 'd',
          bool() => 'b',
          List<String>() => 'sl',
          _ => throw StateError('invalid snapshot type'),
        },
        'v': value,
      }),
    ),
  );

  static _Snapshot parse(Object? raw, DataMigrationPhase phase) {
    final failure = _MigrationFailure(
      DataMigrationFailureCode.invalidBackup,
      phase,
    );
    try {
      if (raw is! String) {
        throw failure;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw failure;
      }
      final values = <String, Object>{};
      for (final entry in decoded.entries) {
        final wrapped = entry.value;
        if (!_isDataKey(entry.key) ||
            wrapped is! Map<String, dynamic> ||
            wrapped.length != 2 ||
            !wrapped.containsKey('v')) {
          throw failure;
        }
        final value = wrapped['v'];
        final Object validated = switch (wrapped['t']) {
          's' when value is String => value,
          'i' when value is int => value,
          'd' when value is num && value.isFinite => value.toDouble(),
          'b' when value is bool => value,
          'sl' when value is List && value.every((item) => item is String) =>
            List<String>.from(value),
          _ => throw failure,
        };
        if (entry.key == _versionKey && (validated is! int || validated <= 0)) {
          throw failure;
        }
        values[entry.key] = validated;
      }
      return _Snapshot(values);
    } catch (_) {
      throw failure;
    }
  }

  bool matches(SharedPreferences prefs) {
    // runtimeType comparison assumes native int/double stay distinct on
    // reload, which native platforms preserve; web (dart2js) can blur a
    // stored 2.0 back into an int and read as a false mismatch here. Web is
    // smoke-only for this service, so that gap is accepted rather than
    // widened into a numeric `==` that would also blur real type drift.
    final keys = prefs.getKeys().where(_isDataKey).toSet();
    if (keys.length != values.length || !keys.containsAll(values.keys)) {
      return false;
    }
    for (final entry in values.entries) {
      final actual = prefs.get(entry.key);
      final expected = entry.value;
      if (expected is List<String>) {
        if (actual is! List ||
            !actual.every((item) => item is String) ||
            !listEquals(List<String>.from(actual), expected)) {
          return false;
        }
      } else if (actual.runtimeType != expected.runtimeType ||
          actual != expected) {
        return false;
      }
    }
    return true;
  }
}
