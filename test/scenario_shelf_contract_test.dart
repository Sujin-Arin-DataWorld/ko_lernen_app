import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/scenario.dart';

import 'support/scenario_json.dart';

/// 마이그레이션 전/후 264개의 backdrop 이 완전히 동일함을 고정한다 (스펙 §11).
/// `_categoryById` 는 Task 6 에서 사라지므로, 이 기준선 파일이 그 값의 유일한
/// 사후 증인이다.
///
/// 기준선은 **264개에서 자라지 않는다** — 마이그레이션 당시 코퍼스의 동결
/// 사본이기 때문이다. 이후 승격된 시나리오(2026-08-18 Batch 11 36편)는 여기
/// 없는 게 정상이고, 그 backdrop 은 배치 매니페스트가 증인이다. 그래서 이
/// 그룹은 "코퍼스 크기 == 기준선 크기"가 아니라 "기준선에 있는 것은 안 변했다"를
/// 검사한다.
void main() {
  group('backdrop 무회귀 기준선', () {
    late Map<String, String> baseline;

    setUpAll(() {
      final raw =
          jsonDecode(
                File('test/fixtures/backdrop_baseline.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      baseline = (raw['entries'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as String),
      );
    });

    test('기준선은 264개다', () {
      expect(baseline.length, 264);
    });

    test('기준선의 264개는 backdropKey 가 그대로다', () {
      final scenarios = allScenarioJson();
      final curriculum =
          jsonDecode(
                File('assets/data/curriculum_manifest.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final generation = curriculum['scenarioCorpusGeneration'];
      if (generation == 'legacy_413_v1') {
        expect(scenarios.length, greaterThanOrEqualTo(baseline.length));
      } else {
        expect(generation, 'canonical_120_v1');
        expect(scenarios, hasLength(120));
        // The canonical corpus is a full redesign, so reused IDs are governed
        // by the new locked scene inventory rather than the legacy backdrop.
        return;
      }
      var checked = 0;
      for (final raw in scenarios) {
        final scenario = Scenario.fromJson(raw);
        final expected = baseline[scenario.id];
        if (expected == null) {
          continue;
        }
        checked++;
        expect(
          scenario.backdropKey,
          expected,
          reason: '${scenario.id} 의 배경이 바뀌었습니다',
        );
      }
      if (generation == 'legacy_413_v1') {
        expect(checked, baseline.length);
      }
    });
  });

  group('샤드 무결성과 shelf/backdrop 계약', () {
    const backdropKeys = <String>{
      'airport',
      'bank',
      'cafe',
      'convenience',
      'directions',
      'home',
      'hotel',
      'market',
      'office',
      'pharmacy',
      'restaurant',
      'salon',
      'station',
      'taxi',
      'theme_park',
    };
    // canonical_120_v1은 레벨마다 검수된 정본 20편만 런타임에 둔다.
    const expectedCounts = <String, int>{
      'a1': 20,
      'a2': 20,
      'b1': 20,
      'b2': 20,
      'c1': 20,
      'c2': 20,
    };

    test('레거시 단일 파일은 사라졌다', () {
      expect(File('assets/data/scenarios.json').existsSync(), isFalse);
    });

    test('샤드별 개수가 고정값과 같다', () {
      for (final level in scenarioShardLevels) {
        final items = scenarioShardRoot(level)['scenarios'] as List;
        expect(items.length, expectedCounts[level], reason: level);
      }
      expect(allScenarioJson().length, 120);
    });

    test('샤드에는 자기 레벨만 들어 있다', () {
      for (final level in scenarioShardLevels) {
        for (final raw in scenarioShardRoot(level)['scenarios'] as List) {
          expect((raw as Map<String, dynamic>)['level'], level);
        }
      }
    });

    test('id 는 코퍼스 전체에서 유일하다', () {
      final ids = allScenarioJson().map((e) => e['id'] as String).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('모든 시나리오에 shelf 와 backdrop 이 있다', () {
      for (final raw in allScenarioJson()) {
        final scenario = Scenario.fromJson(raw);
        expect(
          scenario.shelf,
          startsWith('${scenario.level.code}_'),
          reason: scenario.id,
        );
        expect(backdropKeys, contains(scenario.backdrop), reason: scenario.id);
      }
    });
  });

  group('Scenario 모델의 shelf/backdrop 파싱', () {
    Map<String, dynamic> minimal(Map<String, dynamic> extra) => {
      'id': 'x_probe',
      'level': 'a1',
      ...extra,
    };

    test('필드가 없으면 빈 문자열이다', () {
      final scenario = Scenario.fromJson(minimal(const {}));
      expect(scenario.shelf, '');
      expect(scenario.backdrop, '');
    });

    test('필드가 있으면 그대로 읽는다', () {
      final scenario = Scenario.fromJson(
        minimal(const {'shelf': 'a1_eat', 'backdrop': 'cafe'}),
      );
      expect(scenario.shelf, 'a1_eat');
      expect(scenario.backdrop, 'cafe');
    });

    test('공백은 다듬는다', () {
      final scenario = Scenario.fromJson(
        minimal(const {'shelf': '  a1_eat  ', 'backdrop': ' cafe '}),
      );
      expect(scenario.shelf, 'a1_eat');
      expect(scenario.backdrop, 'cafe');
    });
  });
}
