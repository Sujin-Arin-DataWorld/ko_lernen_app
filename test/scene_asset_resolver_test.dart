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
      expect(
        scn('airport_arrival', backdrop: 'airport').backdropKey,
        'airport',
      );
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
      final runnerMatch = RegExp(
        r'runner\(\s*const\s+KoLernenApp\(\)\s*\)',
      ).firstMatch(source);
      expect(
        runnerMatch,
        isNotNull,
        reason: 'lib/main.dart 에서 KoLernenApp 을 띄우는 지점을 찾지 못했다.',
      );
      final beforeRunner = source.substring(0, runnerMatch!.start);

      const call = 'SceneAssetResolver.load()';
      expect(
        beforeRunner.contains(call),
        isTrue,
        reason: '$call 호출이 runner(const KoLernenApp()) 이전에 있어야 한다.',
      );

      // §W2-Task8 (검수#11): "runner 이전 await 존재" 계약 — 단독
      // await 문이든 Future.wait([...]) 병렬 실행이든, 이 호출이 반드시
      // await 로 다스려져야 한다(fire-and-forget 이면 첫 프레임 전 완료를
      // 보장 못 한다). 리터럴 세미콜론 문장을 통째로 찾지 않아 병렬화
      // 리팩터에도 안전하다.
      final awaited = RegExp(
        r'await\s+(?:Future\.wait(?:<[\s\S]*?>)?\(\s*\[[\s\S]*?' +
            RegExp.escape(call) +
            r'|' +
            RegExp.escape(call) +
            r')',
      ).hasMatch(beforeRunner);
      expect(
        awaited,
        isTrue,
        reason: '$call 는 await 되어야 한다(직접 또는 Future.wait 안에서).',
      );
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

    test('pending-review poster is never a runtime candidate', () {
      SceneAssetResolver.debugSetAssets(<String>{
        'assets/illustrations/scenes/office.png',
        'assets/video/loops/scene_office.mp4',
        'assets_unused/pending_review/scenes/a1_class_pencil.png',
      });
      final s = scn('a1_class_pencil', backdrop: 'office');

      expect(
        SceneAssetResolver.posterAsset(s),
        'assets/illustrations/scenes/office.png',
      );
      expect(
        SceneAssetResolver.loopAsset(s),
        'assets/video/loops/scene_office.mp4',
      );
    });

    test('pubspec never bundles pending-review assets', () {
      final assetDeclarations = File('pubspec.yaml')
          .readAsLinesSync()
          .map((line) => line.trim())
          .where((line) => line.startsWith('- '));

      expect(
        assetDeclarations.any(
          (line) =>
              line.contains('assets_unused') || line.contains('pending_review'),
        ),
        isFalse,
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

    test('theme park uses market until the user poster is bundled', () {
      SceneAssetResolver.debugSetAssets(<String>{
        'assets/illustrations/scenes/market.png',
      });
      final s = scn('a1_theme_park_date_choices', backdrop: 'theme_park');
      expect(
        SceneAssetResolver.posterAsset(s),
        'assets/illustrations/scenes/market.png',
      );
      expect(SceneAssetResolver.loopAsset(s), isNull);
    });

    test('bundled theme park poster automatically wins over its fallback', () {
      SceneAssetResolver.debugSetAssets(<String>{
        'assets/illustrations/scenes/market.png',
        'assets/illustrations/scenes/theme_park.png',
      });
      final s = scn('c2_theme_park_date_reflection', backdrop: 'theme_park');
      expect(
        SceneAssetResolver.posterAsset(s),
        'assets/illustrations/scenes/theme_park.png',
      );
      expect(SceneAssetResolver.loopAsset(s), isNull);
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

    test('쓰이는 모든 카테고리에 canonical 포스터 PNG가 있다', () {
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
