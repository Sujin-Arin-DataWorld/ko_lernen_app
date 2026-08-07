import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

/// 학습 데이터 **무음 소실 회귀** — SRS 덱과 단어팩 진행도.
///
/// 예전 `_loadSrs()` 는 JSON 파싱 실패를 `catch (_) → return {}` 로 삼켰고,
/// 그 뒤 복습 한 번이 `_persistSrs()` 를 통해 그 빈 맵을 `kl_srs_v1` 에 써
/// 버렸다. 즉 **깨진 blob 하나로 학습 이력 전체가 조용히 사라졌다.**
/// 사용자에게는 아무 메시지도 뜨지 않고 복구 수단도 없었다.
///
/// `kl_pack_progress_v1`(61팩 진행도)에도 **글자 그대로 같은 버그**가 있었다.
///
/// 이 스위트는 두 경로를 함께 고정한다: 손상은 격리하고, 원본은 절대 덮어쓰지
/// 않고, 부분 손상에서는 살아있는 항목을 지킨다.
void main() {
  Future<void> bootWith(Map<String, Object> values) async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(values);
    await Storage.init();
  }

  String validDeck() => jsonEncode({
    '사과': {'e': 2.5, 'i': 3, 'n': '2026-01-01', 'r': 2},
    '학교': {'e': 2.6, 'i': 7, 'n': '2026-01-05', 'r': 4},
  });

  group('정상 덱', () {
    setUp(() async {
      await bootWith({'kl_srs_v1': validDeck()});
    });

    test('격리되지 않고 그대로 읽힌다', () {
      expect(Storage.srsIsQuarantined, isFalse);
      expect(Storage.srsDroppedEntryCount, 0);
      expect(Storage.vocabMastery('사과'), isNot(MasteryState.fresh));
      expect(Storage.vocabMastery('학교'), isNot(MasteryState.fresh));
    });

    test('복습이 정상적으로 저장된다', () async {
      await Storage.srsReview('사과', gotIt: true);
      final raw = jsonDecode(Storage.srsRawJson) as Map<String, dynamic>;
      expect(raw.keys, containsAll(<String>['사과', '학교']));
    });
  });

  group('전체 손상 (JSON 자체가 깨짐)', () {
    const broken = '{"사과": {"e": 2.5, "i": 3,';

    setUp(() async {
      await bootWith({'kl_srs_v1': broken});
    });

    test('격리 플래그가 서고 격리본에 원본이 보존된다', () {
      // 읽기 한 번으로 판정이 일어난다.
      expect(Storage.vocabMastery('사과'), MasteryState.fresh);
      expect(Storage.srsIsQuarantined, isTrue);
      expect(Storage.srsQuarantinedRawJson, broken);
    });

    test('🔴 복습을 해도 손상된 원본을 덮어쓰지 않는다', () async {
      expect(Storage.vocabMastery('사과'), MasteryState.fresh);

      // 예전 동작: 이 한 번의 복습이 kl_srs_v1 을 `{"사과":{...}}` 로 덮어써
      // 나머지 학습 이력을 영구히 날렸다.
      await Storage.srsReview('사과', gotIt: true);

      expect(
        Storage.srsRawJson,
        broken,
        reason: '손상된 원본이 덮어써졌다 — 복구 불가 데이터 손실',
      );
      expect(Storage.srsIsQuarantined, isTrue);
    });

    test('여러 번 읽어도 격리본은 최초 관측본을 유지한다', () async {
      expect(Storage.vocabMastery('사과'), MasteryState.fresh);
      expect(Storage.srsQuarantinedRawJson, broken);

      // 두 번째 실행을 흉내 낸다 — 격리본이 이미 있으면 덮어쓰지 않는다.
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'kl_srs_v1': '{"다른": "쓰레기"',
        Storage.srsQuarantinePreferenceKey: broken,
      });
      await Storage.init();

      expect(Storage.vocabMastery('사과'), MasteryState.fresh);
      expect(
        Storage.srsQuarantinedRawJson,
        broken,
        reason: '최초 손상본이 원인 진단에 가장 가깝다 — 밀어내면 안 된다',
      );
    });

    test('명시적 초기화 뒤에만 다시 쓰기가 열린다', () async {
      expect(Storage.vocabMastery('사과'), MasteryState.fresh);
      expect(Storage.srsIsQuarantined, isTrue);

      await Storage.resetQuarantinedSrs();

      expect(Storage.srsIsQuarantined, isFalse);
      expect(Storage.srsRawJson, '{}');
      // 격리본은 남는다.
      expect(Storage.srsQuarantinedRawJson, broken);

      await Storage.srsReview('사과', gotIt: true);
      final raw = jsonDecode(Storage.srsRawJson) as Map<String, dynamic>;
      expect(raw.keys, contains('사과'));
    });

    test('CloudSync 복원이 유효한 덱을 넣으면 잠금이 풀린다', () async {
      expect(Storage.vocabMastery('사과'), MasteryState.fresh);
      expect(Storage.srsIsQuarantined, isTrue);

      await Storage.setSrsRawJson(validDeck());

      expect(Storage.srsIsQuarantined, isFalse);
      expect(Storage.vocabMastery('학교'), isNot(MasteryState.fresh));

      await Storage.srsReview('사과', gotIt: true);
      final raw = jsonDecode(Storage.srsRawJson) as Map<String, dynamic>;
      expect(raw.keys, containsAll(<String>['사과', '학교']));
    });
  });

  group('최상위 타입이 틀린 경우', () {
    test('배열이면 전체 손상으로 격리한다', () async {
      await bootWith({'kl_srs_v1': '[1,2,3]'});
      expect(Storage.vocabMastery('사과'), MasteryState.fresh);
      expect(Storage.srsIsQuarantined, isTrue);
      expect(Storage.srsRawJson, '[1,2,3]');
    });

    test('빈 문자열은 손상이 아니라 "덱 없음" 이다', () async {
      await bootWith({'kl_srs_v1': ''});
      expect(Storage.srsIsQuarantined, isFalse);
      await Storage.srsReview('사과', gotIt: true);
      expect(Storage.srsRawJson, isNot(isEmpty));
    });

    test('빈 객체도 손상이 아니다', () async {
      await bootWith({'kl_srs_v1': '{}'});
      expect(Storage.srsIsQuarantined, isFalse);
      await Storage.srsReview('사과', gotIt: true);
      final raw = jsonDecode(Storage.srsRawJson) as Map<String, dynamic>;
      expect(raw.keys, contains('사과'));
    });
  });

  group('부분 손상 (일부 항목만 깨짐)', () {
    setUp(() async {
      await bootWith({
        'kl_srs_v1': jsonEncode({
          '사과': {'e': 2.5, 'i': 3, 'n': '2026-01-01', 'r': 2},
          '깨진것': '문자열이라 카드가 아님',
          '학교': {'e': 2.6, 'i': 7, 'n': '2026-01-05', 'r': 4},
          '또깨짐': 42,
        }),
      });
    });

    test('유효 항목은 보존하고 깨진 항목만 버린다', () {
      expect(Storage.vocabMastery('사과'), isNot(MasteryState.fresh));
      expect(Storage.vocabMastery('학교'), isNot(MasteryState.fresh));
      expect(Storage.srsIsQuarantined, isFalse);
      expect(Storage.srsDroppedEntryCount, 2);
    });

    test('부분 손상에서는 write 가 계속 허용된다', () async {
      expect(Storage.vocabMastery('사과'), isNot(MasteryState.fresh));
      await Storage.srsReview('바다', gotIt: true);

      final raw = jsonDecode(Storage.srsRawJson) as Map<String, dynamic>;
      expect(
        raw.keys,
        containsAll(<String>['사과', '학교', '바다']),
        reason: '살아남은 항목이 유실됐다',
      );
      expect(raw.keys, isNot(contains('깨진것')));
    });

    test('유효 항목이 하나도 없으면 전체 손상으로 취급한다', () async {
      final allBroken = jsonEncode({'a': 'x', 'b': 1});
      await bootWith({'kl_srs_v1': allBroken});

      expect(Storage.vocabMastery('a'), MasteryState.fresh);
      expect(Storage.srsIsQuarantined, isTrue);

      await Storage.srsReview('a', gotIt: true);
      expect(Storage.srsRawJson, allBroken);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // 단어팩 진행도 — SRS 와 같은 정책
  // ────────────────────────────────────────────────────────────────────────

  String validPacks() => jsonEncode({
    'pack_a1_01': {'stage': 'quiz', 'best': 8},
    'pack_a1_02': {'stage': 'boss', 'best': 10},
  });

  group('단어팩 진행도 — 정상', () {
    setUp(() async {
      await bootWith({'kl_pack_progress_v1': validPacks()});
    });

    test('격리되지 않고 그대로 읽힌다', () {
      expect(Storage.packProgressIsQuarantined, isFalse);
      expect(Storage.allPackProgressJson().keys, hasLength(2));
    });

    test('새 팩 저장이 기존 팩을 보존한다', () async {
      await Storage.setPackProgressJson('pack_a1_03', {'stage': 'learn'});
      expect(
        Storage.allPackProgressJson().keys,
        containsAll(<String>['pack_a1_01', 'pack_a1_02', 'pack_a1_03']),
      );
    });
  });

  group('단어팩 진행도 — 전체 손상', () {
    const broken = '{"pack_a1_01": {"stage": "quiz",';

    setUp(() async {
      await bootWith({'kl_pack_progress_v1': broken});
    });

    test('격리 플래그가 서고 격리본에 원본이 보존된다', () {
      expect(Storage.allPackProgressJson(), isEmpty);
      expect(Storage.packProgressIsQuarantined, isTrue);
      expect(Storage.packProgressQuarantinedRawJson, broken);
    });

    test('🔴 팩 하나를 저장해도 손상된 원본을 덮어쓰지 않는다', () async {
      expect(Storage.allPackProgressJson(), isEmpty);

      // 예전 동작: 이 저장 한 번이 61팩 진행도를 통째로 날렸다.
      await Storage.setPackProgressJson('pack_a1_03', {'stage': 'learn'});

      expect(
        Storage.packProgressJsonRaw,
        broken,
        reason: '손상된 원본이 덮어써졌다 — 복구 불가 진행도 손실',
      );
    });

    test('bulk 저장도 막힌다', () async {
      expect(Storage.allPackProgressJson(), isEmpty);
      await Storage.setManyPackProgressJson({
        'pack_a1_03': {'stage': 'learn'},
      });
      expect(Storage.packProgressJsonRaw, broken);
    });

    test('명시적 초기화 뒤에만 다시 쓰기가 열린다', () async {
      expect(Storage.allPackProgressJson(), isEmpty);
      await Storage.resetQuarantinedPackProgress();

      expect(Storage.packProgressIsQuarantined, isFalse);
      await Storage.setPackProgressJson('pack_a1_03', {'stage': 'learn'});
      expect(Storage.allPackProgressJson().keys, contains('pack_a1_03'));
      // 격리본은 남는다.
      expect(Storage.packProgressQuarantinedRawJson, broken);
    });
  });

  group('단어팩 진행도 — 부분 손상', () {
    setUp(() async {
      await bootWith({
        'kl_pack_progress_v1': jsonEncode({
          'pack_a1_01': {'stage': 'quiz', 'best': 8},
          'pack_broken': '문자열이라 진행도가 아님',
          'pack_a1_02': {'stage': 'boss', 'best': 10},
        }),
      });
    });

    test('유효 팩은 보존하고 깨진 항목만 버린다', () {
      final packs = Storage.allPackProgressJson();
      expect(packs.keys, containsAll(<String>['pack_a1_01', 'pack_a1_02']));
      expect(packs.keys, isNot(contains('pack_broken')));
      expect(Storage.packProgressIsQuarantined, isFalse);
    });

    test('부분 손상에서는 write 가 계속 허용된다', () async {
      expect(Storage.allPackProgressJson(), isNotEmpty);
      await Storage.setPackProgressJson('pack_a1_03', {'stage': 'learn'});

      final packs = Storage.allPackProgressJson();
      expect(
        packs.keys,
        containsAll(<String>['pack_a1_01', 'pack_a1_02', 'pack_a1_03']),
        reason: '살아남은 팩이 유실됐다',
      );
    });
  });

  group('클라우드 백업이 손상본을 퍼뜨리지 않는다', () {
    test('정상 덱은 백업 payload 에 포함된다', () async {
      await bootWith({'kl_srs_v1': validDeck()});
      final payload = await CloudSync.buildBackupPayload();
      expect(payload['srs_json'], validDeck());
    });

    test('🔴 격리된 손상 덱은 백업 payload 에서 빠진다', () async {
      const broken = '{"사과": {"e": 2.5,';
      await bootWith({'kl_srs_v1': broken});
      // 손상 판정을 일으킨다.
      expect(Storage.vocabMastery('사과'), MasteryState.fresh);
      expect(Storage.srsIsQuarantined, isTrue);

      final payload = await CloudSync.buildBackupPayload();

      expect(
        payload.containsKey('srs_json'),
        isFalse,
        reason: '손상본을 올리면 기기 한 대의 손상이 클라우드의 멀쩡한 백업을 덮어써 '
            '모든 기기로 번진다. write 는 merge:true 라 키를 빼면 서버 값이 남는다.',
      );
      // 나머지 진행도는 계속 백업된다 — 전체 동기화를 멈추는 게 아니다.
      expect(payload.containsKey('progress'), isTrue);
    });
  });
}
