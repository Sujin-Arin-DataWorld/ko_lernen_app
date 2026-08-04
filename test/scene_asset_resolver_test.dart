import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/services/scene_asset_resolver.dart';

/// Minimal Scenario carrying only the id (all other fields default). The
/// resolver + backdropKey only read `id`.
Scenario scn(String id) => Scenario.fromJson(<String, dynamic>{'id': id});

void main() {
  tearDown(SceneAssetResolver.debugReset);

  group('ScenarioBackdrop.backdropKey (category fallback, exact-id map)', () {
    test('mart_grocery maps to market (was the substring-match bug)', () {
      expect(scn('mart_grocery').backdropKey, 'market');
    });

    test('airport_arrival maps to airport (2026-08-04 분리)', () {
      expect(scn('airport_arrival').backdropKey, 'airport');
    });

    test('every previously-uncovered scenario now has a category', () {
      // These 13 returned null under the old substring map (→ mascot-only).
      const previouslyNull = <String>[
        'business_meeting_intro',
        'complaint_delivery',
        'doctor_consultation',
        'ktx_ticket',
        'food_delivery',
        'mart_grocery',
        'gym_signup',
        'bank_account',
        'job_interview',
        'love_confession',
        'feeling_sick',
        'lost_phone',
        'friend_birthday',
      ];
      for (final id in previouslyNull) {
        expect(
          scn(id).backdropKey,
          isNotNull,
          reason: '$id must resolve to a category backdrop',
        );
      }
    });

    test('unregistered id returns null (safety)', () {
      expect(scn('totally_unknown_xyz').backdropKey, isNull);
    });
  });

  group('SceneAssetResolver — convention-first with category fallback', () {
    test('main waits for the manifest before the first app frame', () {
      final source = File('lib/main.dart').readAsStringSync();
      final resolverLoad = source.indexOf('await SceneAssetResolver.load();');
      final firstRunApp = source.indexOf('runApp(const KoLernenApp());');

      expect(resolverLoad, greaterThanOrEqualTo(0));
      expect(firstRunApp, greaterThan(resolverLoad));
    });

    test('no manifest loaded → category poster + loop', () {
      final s = scn('airport_arrival');
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
      final s = scn('airport_arrival');
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
        final s = scn('airport_arrival');
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
      final s = scn('mart_grocery');
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

  group('배경 배선 무결성 가드 (2026-08-04)', () {
    /// `_categoryById` 의 (시나리오 id → 카테고리 키) 쌍을 소스에서 뽑는다.
    /// 맵이 private 이라 리플렉션 대신 소스를 읽는다 — 다른 guard 테스트와 동일 패턴.
    List<MapEntry<String, String>> mapEntries() {
      // Windows 체크아웃은 CRLF 라 '\n  };\n' 로 끝을 못 찾는다. 줄바꿈만
      // 정규화하고 나머지 검색은 그대로 둔다 (2026-08-04 실패 원인).
      final src = File(
        'lib/models/scenario.dart',
      ).readAsStringSync().replaceAll('\r\n', '\n');
      final start = src.indexOf('static const _categoryById');
      expect(start, greaterThanOrEqualTo(0), reason: '_categoryById 를 찾지 못했습니다');
      final end = src.indexOf('\n  };\n', start);
      expect(end, greaterThan(start));
      return RegExp(r"'([a-z0-9_]+)': '([a-z]+)'")
          .allMatches(src.substring(start, end))
          .map((m) => MapEntry(m.group(1)!, m.group(2)!))
          .toList();
    }

    test('scenarios.json 의 모든 시나리오가 카테고리에 등록돼 있다', () {
      final data =
          jsonDecode(File('assets/data/scenarios.json').readAsStringSync())
              as Map<String, dynamic>;
      final ids = (data['scenarios'] as List)
          .map((e) => (e as Map<String, dynamic>)['id'] as String)
          .toSet();
      final mapped = mapEntries().map((e) => e.key).toSet();

      expect(
        ids.difference(mapped),
        isEmpty,
        reason: '미등록 → backdropKey 가 null 이라 배경 없이 마스코트로 떨어집니다',
      );
      expect(
        mapped.difference(ids),
        isEmpty,
        reason: 'scenarios.json 에 없는 id 가 맵에 남아 있습니다 (오타 또는 삭제 잔재)',
      );
    });

    test('모든 카테고리 키에 실제 포스터 PNG 가 있다', () {
      final categories = mapEntries().map((e) => e.value).toSet();
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
