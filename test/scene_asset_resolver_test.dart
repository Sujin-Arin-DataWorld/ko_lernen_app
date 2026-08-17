import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/services/scene_asset_resolver.dart';

import 'support/scenario_json.dart';

/// Minimal Scenario carrying the id and its backdrop. Since 2026-08-17 the
/// category comes from the record's `backdrop` field, not from an id→category
/// map, so a fixture must state it the same way the shard data does.
Scenario scn(String id, {String backdrop = ''}) =>
    Scenario.fromJson(<String, dynamic>{'id': id, 'backdrop': backdrop});

void main() {
  tearDown(SceneAssetResolver.debugReset);

  group('ScenarioBackdrop.backdropKey (JSON 필드가 정본)', () {
    test('backdrop 필드가 그대로 카테고리 키다', () {
      expect(scn('mart_grocery', backdrop: 'market').backdropKey, 'market');
      expect(scn('airport_arrival', backdrop: 'airport').backdropKey, 'airport');
    });

    test('backdrop 이 비면 null (UI 는 마스코트로 떨어진다)', () {
      expect(scn('totally_unknown_xyz').backdropKey, isNull);
    });

    test('live 데이터의 실제 배정이 유지된다', () {
      // 예전에는 이 값들이 Dart const map 에 있었다. 지금은 샤드 레코드에 있고,
      // 전수 무회귀는 test/scenario_shelf_contract_test.dart 가 기준선으로 지킨다.
      final byId = <String, String>{
        for (final raw in allScenarioJson())
          raw['id'] as String: raw['backdrop'] as String,
      };
      expect(byId['mart_grocery'], 'market');
      expect(byId['airport_arrival'], 'airport');
      // scenes/pharmacy.png 는 한때 카테고리가 없어 렌더된 적 없는 고아였다.
      expect(byId['pharmacy_headache'], 'pharmacy');
      // clinic 전용 배경이 생기기 전에는 market 을 유지해야 배경을 잃지 않는다.
      expect(byId['doctor_consultation'], 'market');
      expect(byId['clinic_safety'], 'market');
    });
  });

  group('SceneAssetResolver — convention-first with category fallback', () {
    test('main waits for the manifest before the first app frame', () {
      final source = File('lib/main.dart').readAsStringSync();
      final resolverLoad = source.indexOf('await SceneAssetResolver.load();');
      final productionRunner = source.indexOf('runner(const KoLernenApp());');

      expect(resolverLoad, greaterThanOrEqualTo(0));
      expect(productionRunner, greaterThan(resolverLoad));
    });

    test('no manifest loaded → category poster + loop', () {
      final s = scn('airport_arrival', backdrop: 'airport');
      expect(
        SceneAssetResolver.posterAsset(s),
        'assets/illustrations/scenes/airport.png',
      );
      expect(
        SceneAssetResolver.loopAsset(s),
        'assets/video/loops/scene_airport.mp4',
      );
    });

    test('dedicated asset present → dedicated path wins over category', () {
      SceneAssetResolver.debugSetAssets(<String>{
        'assets/illustrations/scenes/airport.png',
        'assets/video/loops/scene_airport.mp4',
        'assets/illustrations/scenes/airport_arrival.png',
        'assets/video/loops/scene_airport_arrival.mp4',
      });
      final s = scn('airport_arrival', backdrop: 'airport');
      expect(
        SceneAssetResolver.posterAsset(s),
        'assets/illustrations/scenes/airport_arrival.png',
      );
      expect(
        SceneAssetResolver.loopAsset(s),
        'assets/video/loops/scene_airport_arrival.mp4',
      );
    });

    test(
      'dedicated poster but no dedicated loop → poster dedicated, loop category',
      () {
        SceneAssetResolver.debugSetAssets(<String>{
          'assets/illustrations/scenes/airport.png',
          'assets/video/loops/scene_airport.mp4',
          'assets/illustrations/scenes/airport_arrival.png',
          // deliberately no scene_airport_arrival.mp4
        });
        final s = scn('airport_arrival', backdrop: 'airport');
        expect(
          SceneAssetResolver.posterAsset(s),
          'assets/illustrations/scenes/airport_arrival.png',
        );
        expect(
          SceneAssetResolver.loopAsset(s),
          'assets/video/loops/scene_airport.mp4',
        );
      },
    );

    test('mart_grocery resolves to market category assets', () {
      SceneAssetResolver.debugSetAssets(<String>{
        'assets/illustrations/scenes/market.png',
        'assets/video/loops/scene_market.mp4',
      });
      final s = scn('mart_grocery', backdrop: 'market');
      expect(
        SceneAssetResolver.posterAsset(s),
        'assets/illustrations/scenes/market.png',
      );
      expect(
        SceneAssetResolver.loopAsset(s),
        'assets/video/loops/scene_market.mp4',
      );
    });

    test('unregistered id + empty manifest → null (mascot fallback at UI)', () {
      final s = scn('totally_unknown_xyz');
      expect(SceneAssetResolver.posterAsset(s), isNull);
      expect(SceneAssetResolver.loopAsset(s), isNull);
    });
  });

  group('배경 배선 무결성 가드 (2026-08-17: 소스 맵 → JSON 필드)', () {
    // 2026-08-17 이전에는 `_categoryById` const map 을 소스에서 정규식으로 뽑아
    // 고아·유령을 셌다. 배경이 시나리오 레코드 자체에 붙은 지금은 그 두 상태가
    // 구조적으로 불가능하므로, 남는 계약은 "값이 있고 그 PNG 가 번들에 있다" 뿐이다.

    test('모든 시나리오에 backdrop 이 있다', () {
      for (final raw in allScenarioJson()) {
        expect(
          (raw['backdrop'] as String?) ?? '',
          isNotEmpty,
          reason: '${raw['id']} 에 backdrop 이 없어 배경 없이 마스코트로 떨어집니다',
        );
      }
    });

    test('쓰이는 모든 카테고리에 실제 포스터 PNG 가 있다', () {
      final categories = allScenarioJson()
          .map((raw) => raw['backdrop'] as String)
          .toSet();
      expect(categories, isNotEmpty);
      for (final key in categories) {
        expect(
          File('assets/illustrations/scenes/$key.png').existsSync(),
          isTrue,
          reason:
              'assets/illustrations/scenes/$key.png 없음 — '
              '이 카테고리의 시나리오가 전부 배경을 잃습니다',
        );
      }
    });
  });
}
