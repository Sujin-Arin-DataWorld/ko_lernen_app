import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/data_migration_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

/// 로컬 데이터 마이그레이션 러너 계약.
///
/// 프로덕션 단계는 아직 없지만(포맷을 깨는 변경이 없었다), 러너는 **다음 포맷
/// 변경이 오기 전에** 검증돼 있어야 한다. 첫 마이그레이션에서 처음 돌려 보는
/// 마이그레이션 코드가 가장 위험하다.
///
/// 고정하는 원칙:
/// - 여러 번 실행돼도 안전(멱등)
/// - 중간 실패 → 백업 복원 + 버전 유지 → 재시도 가능
/// - 완료된 뒤에만 버전 상승
/// - 다운그레이드는 fail-closed (읽기 허용, 쓰기 잠금)
void main() {
  late SharedPreferences prefs;

  Future<void> bootWith(Map<String, Object> values) async {
    Storage.resetForTesting();
    DataMigrationService.resetForTesting();
    SharedPreferences.setMockInitialValues(values);
    await Storage.init();
    prefs = await SharedPreferences.getInstance();
  }

  int? storedVersion() =>
      prefs.getInt(DataMigrationService.versionPreferenceKey);

  tearDown(Storage.unlockLearningWrites);

  group('baseline 도장', () {
    test('학습 흔적이 없는 새 설치는 현재 버전으로 시작한다', () async {
      await bootWith({});
      final result = await DataMigrationService.run(preferences: prefs);

      expect(result.status, DataMigrationStatus.fresh);
      expect(result.fromVersion, DataMigrationService.currentSchemaVersion);
      expect(storedVersion(), DataMigrationService.currentSchemaVersion);
      expect(result.writesAllowed, isTrue);
    });

    test('학습 흔적이 있는 기존 설치는 baseline 1 로 도장 찍힌다', () async {
      // 버전 키 없이 SRS 덱만 있는, 이 기능 이전에 설치된 사용자.
      await bootWith({'kl_srs_v1': '{"사과":{"e":2.5,"i":3,"n":"","r":1}}'});
      final result = await DataMigrationService.run(
        preferences: prefs,
        targetVersion: 3,
        steps: const {},
      );

      expect(
        result.fromVersion,
        1,
        reason: '기존 사용자를 새 설치로 오인하면 마이그레이션 출발점이 틀어진다',
      );
    });

    test('두 번째 실행은 upToDate 다', () async {
      await bootWith({});
      await DataMigrationService.run(preferences: prefs);
      final second = await DataMigrationService.run(preferences: prefs);
      expect(second.status, DataMigrationStatus.upToDate);
    });
  });

  group('단계 실행', () {
    test('필요한 단계만, 오름차순으로 실행한다', () async {
      await bootWith({DataMigrationService.versionPreferenceKey: 1});
      final ran = <int>[];

      final result = await DataMigrationService.run(
        preferences: prefs,
        targetVersion: 4,
        steps: {
          2: (p) async => ran.add(2),
          3: (p) async => ran.add(3),
          4: (p) async => ran.add(4),
        },
      );

      expect(ran, <int>[2, 3, 4]);
      expect(result.status, DataMigrationStatus.migrated);
      expect(storedVersion(), 4);
    });

    test('이미 지난 단계는 건너뛴다', () async {
      await bootWith({DataMigrationService.versionPreferenceKey: 3});
      final ran = <int>[];

      await DataMigrationService.run(
        preferences: prefs,
        targetVersion: 4,
        steps: {
          2: (p) async => ran.add(2),
          3: (p) async => ran.add(3),
          4: (p) async => ran.add(4),
        },
      );

      expect(ran, <int>[4]);
    });

    test('같은 마이그레이션을 두 번 돌려도 단계가 다시 실행되지 않는다 (멱등)', () async {
      await bootWith({DataMigrationService.versionPreferenceKey: 1});
      var runs = 0;
      final steps = {2: (SharedPreferences p) async => runs++};

      await DataMigrationService.run(
        preferences: prefs,
        targetVersion: 2,
        steps: steps,
      );
      await DataMigrationService.run(
        preferences: prefs,
        targetVersion: 2,
        steps: steps,
      );

      expect(runs, 1);
      expect(storedVersion(), 2);
    });

    test('단계가 실제로 데이터를 바꿀 수 있다', () async {
      await bootWith({
        DataMigrationService.versionPreferenceKey: 1,
        'kl_legacy_flag': 'old',
      });

      await DataMigrationService.run(
        preferences: prefs,
        targetVersion: 2,
        steps: {
          2: (p) async {
            await p.setString('kl_legacy_flag', 'new');
          },
        },
      );

      expect(prefs.getString('kl_legacy_flag'), 'new');
      expect(storedVersion(), 2);
    });

    test('등록된 단계가 없는 버전 상승은 도장만 옮긴다', () async {
      await bootWith({DataMigrationService.versionPreferenceKey: 1});
      final result = await DataMigrationService.run(
        preferences: prefs,
        targetVersion: 2,
        steps: const {},
      );

      expect(result.status, DataMigrationStatus.migrated);
      expect(storedVersion(), 2);
      expect(result.writesAllowed, isTrue);
    });
  });

  group('실패와 복구', () {
    test('중간 실패는 버전을 올리지 않는다 → 다음 실행이 재시도한다', () async {
      await bootWith({DataMigrationService.versionPreferenceKey: 1});
      var attempt = 0;

      Map<int, DataMigrationStep> steps() => {
        2: (p) async {
          attempt++;
          if (attempt == 1) {
            throw StateError('첫 시도 실패');
          }
          await p.setString('kl_migrated_marker', 'ok');
        },
      };

      final first = await DataMigrationService.run(
        preferences: prefs,
        targetVersion: 2,
        steps: steps(),
      );
      expect(first.status, DataMigrationStatus.failed);
      expect(storedVersion(), 1, reason: '실패했는데 버전이 올라가면 단계가 영영 건너뛰어진다');
      expect(first.writesAllowed, isFalse);

      final second = await DataMigrationService.run(
        preferences: prefs,
        targetVersion: 2,
        steps: steps(),
      );
      expect(second.status, DataMigrationStatus.migrated);
      expect(storedVersion(), 2);
      expect(prefs.getString('kl_migrated_marker'), 'ok');
      expect(second.writesAllowed, isTrue);
    });

    test('실패하면 부분 변경이 백업으로 되돌아간다', () async {
      await bootWith({
        DataMigrationService.versionPreferenceKey: 1,
        'kl_keep': 'original',
        'kl_count': 7,
        'kl_flag': true,
      });

      final result = await DataMigrationService.run(
        preferences: prefs,
        targetVersion: 3,
        steps: {
          2: (p) async {
            await p.setString('kl_keep', 'mangled');
            await p.setString('kl_half_written', 'garbage');
          },
          3: (p) async => throw StateError('두 번째 단계 실패'),
        },
      );

      expect(result.status, DataMigrationStatus.failed);
      expect(prefs.getString('kl_keep'), 'original', reason: '변형된 값이 되돌아오지 않았다');
      expect(
        prefs.getString('kl_half_written'),
        isNull,
        reason: '반쯤 마이그레이션된 잔재가 남으면 재시도가 깨끗한 상태에서 시작하지 못한다',
      );
      expect(prefs.getInt('kl_count'), 7);
      expect(prefs.getBool('kl_flag'), isTrue);
    });

    test('재시도 중 두 번째 실패도 원본 백업을 유지한다', () async {
      await bootWith({
        DataMigrationService.versionPreferenceKey: 1,
        'kl_keep': 'original',
      });

      Map<int, DataMigrationStep> failing() => {
        2: (p) async {
          await p.setString('kl_keep', 'mangled');
          throw StateError('항상 실패');
        },
      };

      await DataMigrationService.run(
        preferences: prefs,
        targetVersion: 2,
        steps: failing(),
      );
      await DataMigrationService.run(
        preferences: prefs,
        targetVersion: 2,
        steps: failing(),
      );

      expect(
        prefs.getString('kl_keep'),
        'original',
        reason: '두 번째 백업이 이미 변형된 상태를 덮어 쓰면 원본으로 못 돌아간다',
      );
    });

    test('성공하면 journal 과 백업이 정리된다', () async {
      await bootWith({DataMigrationService.versionPreferenceKey: 1});
      await DataMigrationService.run(
        preferences: prefs,
        targetVersion: 2,
        steps: {2: (p) async {}},
      );

      expect(prefs.getString(DataMigrationService.journalPreferenceKey), isNull);
      expect(prefs.getString(DataMigrationService.backupPreferenceKey), isNull);
    });

    test('실패 뒤에는 journal 이 남아 중단 지점을 알려준다', () async {
      await bootWith({DataMigrationService.versionPreferenceKey: 1});
      await DataMigrationService.run(
        preferences: prefs,
        targetVersion: 3,
        steps: {
          2: (p) async {},
          3: (p) async => throw StateError('실패'),
        },
      );

      final journal = prefs.getString(DataMigrationService.journalPreferenceKey);
      expect(journal, isNotNull);
      final decoded = jsonDecode(journal!) as Map<String, dynamic>;
      expect(decoded['step'], 2, reason: '2단계까지는 끝났다는 기록이 남아야 한다');
    });
  });

  group('다운그레이드 (미래 버전) fail-closed', () {
    test('저장된 버전이 더 새로우면 학습 쓰기를 잠근다', () async {
      await bootWith({DataMigrationService.versionPreferenceKey: 99});
      final result = await DataMigrationService.run(
        preferences: prefs,
        targetVersion: 1,
      );

      expect(result.status, DataMigrationStatus.futureVersion);
      expect(result.writesAllowed, isFalse);
      expect(Storage.learningWritesLockReason, isNotNull);
    });

    test('잠긴 동안 SRS 복습이 저장되지 않는다', () async {
      await bootWith({
        DataMigrationService.versionPreferenceKey: 99,
        'kl_srs_v1': '{"사과":{"e":2.5,"i":3,"n":"2026-01-01","r":2}}',
      });
      await DataMigrationService.run(preferences: prefs, targetVersion: 1);

      final before = Storage.srsRawJson;
      await Storage.srsReview('바다', gotIt: true);

      expect(
        Storage.srsRawJson,
        before,
        reason: '옛 코드가 새 포맷 위에 옛 포맷을 쓰면 데이터가 망가진다',
      );
    });

    test('잠긴 동안 팩 진행도가 저장되지 않는다', () async {
      await bootWith({
        DataMigrationService.versionPreferenceKey: 99,
        'kl_pack_progress_v1': '{"pack_a1_01":{"stage":"boss"}}',
      });
      await DataMigrationService.run(preferences: prefs, targetVersion: 1);

      final before = Storage.packProgressJsonRaw;
      await Storage.setPackProgressJson('pack_a1_02', {'stage': 'learn'});

      expect(Storage.packProgressJsonRaw, before);
    });

    test('버전 도장은 낮춰 쓰지 않는다', () async {
      await bootWith({DataMigrationService.versionPreferenceKey: 99});
      await DataMigrationService.run(preferences: prefs, targetVersion: 1);

      expect(
        storedVersion(),
        99,
        reason: '도장을 낮추면 다음 신버전 실행이 마이그레이션을 다시 돌린다',
      );
    });

    test('정상 상태로 돌아오면 잠금이 풀린다', () async {
      await bootWith({DataMigrationService.versionPreferenceKey: 99});
      await DataMigrationService.run(preferences: prefs, targetVersion: 1);
      expect(Storage.learningWritesLockReason, isNotNull);

      // 신버전 앱을 다시 설치한 상황.
      await DataMigrationService.run(preferences: prefs, targetVersion: 99);
      expect(Storage.learningWritesLockReason, isNull);
    });
  });

  group('진단 값', () {
    test('PII 없이 짧은 상태 문자열을 낸다', () async {
      await bootWith({DataMigrationService.versionPreferenceKey: 1});
      final result = await DataMigrationService.run(
        preferences: prefs,
        targetVersion: 2,
        steps: const {},
      );

      expect(result.diagnosticValue, 'migrated:1→2');
      expect(result.diagnosticValue.length, lessThan(40));
    });

    test('lastResult 가 마지막 실행을 기억한다', () async {
      await bootWith({});
      expect(DataMigrationService.lastResult, isNull);
      final result = await DataMigrationService.run(preferences: prefs);
      expect(DataMigrationService.lastResult, same(result));
    });
  });

  group('삭제·초기화와 섞이지 않는다', () {
    test('마이그레이션은 kl_ 키를 지우지 않는다', () async {
      await bootWith({
        DataMigrationService.versionPreferenceKey: 1,
        'kl_srs_v1': '{"사과":{"e":2.5,"i":3,"n":"","r":1}}',
        'kl_xp': 120,
        'kl_daily_streak': 5,
      });

      await DataMigrationService.run(
        preferences: prefs,
        targetVersion: 2,
        steps: {2: (p) async {}},
      );

      expect(prefs.getString('kl_srs_v1'), isNotNull);
      expect(prefs.getInt('kl_xp'), 120);
      expect(prefs.getInt('kl_daily_streak'), 5);
    });
  });
}
