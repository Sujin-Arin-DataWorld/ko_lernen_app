import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
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

  /// 단계가 실패했다. 백업으로 되돌렸고 버전은 올리지 않았다.
  failed,

  /// 저장된 버전이 앱보다 **새롭다**(다운그레이드). 옛 코드가 새 포맷을
  /// 망가뜨리지 않도록 학습 데이터 쓰기를 잠갔다.
  futureVersion,
}

/// 마이그레이션 결과 스냅샷.
class DataMigrationResult {
  const DataMigrationResult({
    required this.status,
    required this.fromVersion,
    required this.toVersion,
    this.error,
  });

  final DataMigrationStatus status;
  final int fromVersion;
  final int toVersion;
  final Object? error;

  /// 학습 데이터 write 를 허용해도 되는 상태인지.
  bool get writesAllowed =>
      status != DataMigrationStatus.failed &&
      status != DataMigrationStatus.futureVersion;

  /// Crashlytics custom key 로 보내기 적합한 짧은 값. 자유 텍스트·PII 없음.
  String get diagnosticValue => '${status.name}:$fromVersion→$toVersion';

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
/// - 삭제·초기화와 같은 흐름에 섞지 않는다(이 서비스는 `kl_` 키를 지우지 않는다).
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
/// 다음 포맷 변경 때는 [currentSchemaVersion] 을 올리고 [_productionSteps] 에
/// 그 버전 키로 단계를 추가하면 된다.
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
  ];

  static DataMigrationResult? _lastResult;

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
  }) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final target = targetVersion ?? currentSchemaVersion;
    final registry = steps ?? _productionSteps;

    final stored = prefs.getInt(versionPreferenceKey);
    final from = stored ?? _inferBaseline(prefs, target);

    if (stored == null) {
      // 새 설치든 baseline 추정이든, 도장을 먼저 찍어야 다음 실행이 안정적이다.
      await prefs.setInt(versionPreferenceKey, from);
    }

    if (from > target) {
      Storage.lockLearningWrites(
        'schema downgrade: stored=$from app=$target',
      );
      return _finish(
        DataMigrationResult(
          status: DataMigrationStatus.futureVersion,
          fromVersion: from,
          toVersion: target,
        ),
      );
    }

    if (from == target) {
      // 앞선 실행이 중간에 죽어 journal 이 남아 있을 수 있다. 정리하고 끝낸다.
      await _clearJournalAndBackup(prefs);
      Storage.unlockLearningWrites();
      return _finish(
        DataMigrationResult(
          status: stored == null
              ? DataMigrationStatus.fresh
              : DataMigrationStatus.upToDate,
          fromVersion: from,
          toVersion: target,
        ),
      );
    }

    final pending = registry.keys.where((v) => v > from && v <= target).toList()
      ..sort();
    if (pending.isEmpty) {
      // 실행할 단계가 없는 버전 상승(예: 버전만 올린 릴리스). 도장만 옮긴다.
      await prefs.setInt(versionPreferenceKey, target);
      await _clearJournalAndBackup(prefs);
      Storage.unlockLearningWrites();
      return _finish(
        DataMigrationResult(
          status: DataMigrationStatus.migrated,
          fromVersion: from,
          toVersion: target,
        ),
      );
    }

    // 백업 먼저. 앞선 실행이 남긴 백업이 있으면 **그걸 유지**한다 — 중간까지
    // 변형된 현재 상태로 덮어쓰면 원본으로 되돌릴 수 없다.
    if ((prefs.getString(backupPreferenceKey) ?? '').isEmpty) {
      await prefs.setString(backupPreferenceKey, _snapshot(prefs));
    }
    await prefs.setString(
      journalPreferenceKey,
      jsonEncode({'from': from, 'to': target, 'phase': 'started'}),
    );

    try {
      for (final version in pending) {
        await registry[version]!(prefs);
        await prefs.setString(
          journalPreferenceKey,
          jsonEncode({
            'from': from,
            'to': target,
            'phase': 'step_done',
            'step': version,
          }),
        );
      }
    } catch (error) {
      debugPrint('DataMigration: 단계 실패 — 백업으로 되돌린다: $error');
      await _restoreBackup(prefs);
      // 버전은 올리지 않는다 → 다음 실행이 처음부터 다시 시도한다.
      Storage.lockLearningWrites('migration failed at $from→$target');
      return _finish(
        DataMigrationResult(
          status: DataMigrationStatus.failed,
          fromVersion: from,
          toVersion: target,
          error: error,
        ),
      );
    }

    // **완료된 뒤에만** 버전을 올린다.
    await prefs.setInt(versionPreferenceKey, target);
    await _clearJournalAndBackup(prefs);
    Storage.unlockLearningWrites();
    return _finish(
      DataMigrationResult(
        status: DataMigrationStatus.migrated,
        fromVersion: from,
        toVersion: target,
      ),
    );
  }

  /// 버전 키가 없는 설치의 출발점을 추정한다.
  ///
  /// 학습 흔적이 있으면 **1**(모든 기존 설치의 baseline), 없으면 현재 버전.
  static int _inferBaseline(SharedPreferences prefs, int target) {
    final existing = _existingInstallMarkers.any(prefs.containsKey);
    return existing ? 1 : target;
  }

  /// `kl_` 키 전체의 타입 보존 스냅샷.
  ///
  /// 단계가 어떤 키를 건드릴지 모르므로 넓게 뜬다. 스냅샷은 실제 마이그레이션이
  /// 있을 때만 만들어지므로(위 `pending.isEmpty` 분기) 상시 비용이 아니다.
  /// 백업 키·journal 키 자신은 제외한다(자기 참조 방지).
  static String _snapshot(SharedPreferences prefs) {
    final data = <String, Object?>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith('kl_') ||
          key == backupPreferenceKey ||
          key == journalPreferenceKey) {
        continue;
      }
      final value = prefs.get(key);
      if (value is List<String>) {
        data[key] = {'t': 'sl', 'v': value};
      } else if (value is String) {
        data[key] = {'t': 's', 'v': value};
      } else if (value is int) {
        data[key] = {'t': 'i', 'v': value};
      } else if (value is double) {
        data[key] = {'t': 'd', 'v': value};
      } else if (value is bool) {
        data[key] = {'t': 'b', 'v': value};
      }
    }
    return jsonEncode(data);
  }

  /// 백업으로 되돌린다. 백업 이후 **생긴** `kl_` 키는 지운다 — 반쯤 마이그레이션된
  /// 잔재가 남으면 다음 시도가 깨끗한 상태에서 시작하지 못한다.
  static Future<void> _restoreBackup(SharedPreferences prefs) async {
    final raw = prefs.getString(backupPreferenceKey) ?? '';
    if (raw.isEmpty) {
      return;
    }
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      debugPrint('DataMigration: 백업이 손상돼 복원을 건너뛴다');
      return;
    }
    if (decoded is! Map<String, dynamic>) {
      return;
    }

    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith('kl_') &&
          key != backupPreferenceKey &&
          key != journalPreferenceKey &&
          !decoded.containsKey(key)) {
        await prefs.remove(key);
      }
    }

    for (final entry in decoded.entries) {
      final wrapped = entry.value;
      if (wrapped is! Map<String, dynamic>) {
        continue;
      }
      final value = wrapped['v'];
      switch (wrapped['t']) {
        case 's':
          await prefs.setString(entry.key, value as String);
        case 'i':
          await prefs.setInt(entry.key, value as int);
        case 'd':
          await prefs.setDouble(entry.key, (value as num).toDouble());
        case 'b':
          await prefs.setBool(entry.key, value as bool);
        case 'sl':
          await prefs.setStringList(
            entry.key,
            (value as List).cast<String>(),
          );
      }
    }
    // 복원된 값은 캐시와 어긋나 있다.
    Storage.resetCachesAfterExternalWrite();
  }

  static Future<void> _clearJournalAndBackup(SharedPreferences prefs) async {
    await prefs.remove(journalPreferenceKey);
    await prefs.remove(backupPreferenceKey);
  }

  static DataMigrationResult _finish(DataMigrationResult result) {
    _lastResult = result;
    debugPrint('DataMigration: $result');
    return result;
  }
}
