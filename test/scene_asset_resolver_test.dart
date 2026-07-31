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

    test('airport_arrival maps to directions', () {
      expect(scn('airport_arrival').backdropKey, 'directions');
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
        'assets/illustrations/scenes/directions.png',
      );
      expect(
        SceneAssetResolver.loopAsset(s),
        'assets/video/loops/scene_directions.mp4',
      );
    });

    test('dedicated asset present → dedicated path wins over category', () {
      SceneAssetResolver.debugSetAssets(<String>{
        'assets/illustrations/scenes/directions.png',
        'assets/video/loops/scene_directions.mp4',
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
          'assets/illustrations/scenes/directions.png',
          'assets/video/loops/scene_directions.mp4',
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
          'assets/video/loops/scene_directions.mp4',
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
}
