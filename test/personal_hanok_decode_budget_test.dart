import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/personal_hanok_catalog.dart';

/// The estate map paints every unlocked layer at once and, until this budget
/// existed, decoded each one at the raw display width with no ceiling. The A1
/// map has had `a1HanokDecodeCacheWidth` since PR4; the estate map had no
/// equivalent, so a large viewport at a high device pixel ratio pushed the
/// composite past `runtimeLimits.decodedMemoryMaxBytes`.
void main() {
  group('Personal Hanok decode budget', () {
    test('mirrors the runtime ceiling recorded in the provenance manifest', () {
      final manifest =
          jsonDecode(
                File(
                  'docs/assets/HANOK_V1_ASSET_PROVENANCE.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final limits = manifest['runtimeLimits'] as Map<String, dynamic>;

      // Sibling of `a1ConstructionStates`, not a member of it: the ceiling is
      // runtime-wide and therefore governs the estate map as well.
      expect(limits.containsKey('decodedMemoryMaxBytes'), isTrue);
      expect(
        limits['decodedMemoryMaxBytes'],
        kPersonalHanokDecodedMemoryMaxBytes,
      );

      final camera = manifest['camera'] as Map<String, dynamic>;
      final canvas = camera['canvas'] as Map<String, dynamic>;
      expect(canvas['width'], kPersonalHanokCanvasWidth);
      expect(canvas['height'], kPersonalHanokCanvasHeight);
    });

    test('the fully built estate stays inside the ceiling on a large tablet', () {
      // The widest the map can get: SoriMaxWidth.world 960dp, and the highest
      // device pixel ratio we ship against.
      expect(
        personalHanokWorstCaseResidentBytes(
          displayWidth: 960,
          devicePixelRatio: 3,
        ),
        lessThanOrEqualTo(kPersonalHanokDecodedMemoryMaxBytes),
      );
    });

    test('an unclamped decode would have exceeded the ceiling', () {
      // The pre-fix behaviour: round(displayWidth * dpr) with no cap. This
      // documents the regression the budget prevents rather than asserting on
      // code that no longer exists.
      const tabletMapWidth = 620.0; // 960dp world, Row layout, 280dp detail
      const unclampedWidth = tabletMapWidth * 2;
      expect(
        personalHanokResidentBytes(
          layerCount: kPersonalHanokLayers.length,
          cacheWidth: unclampedWidth.round(),
        ),
        greaterThan(kPersonalHanokDecodedMemoryMaxBytes),
      );
    });

    test('clamping to the master canvas alone is not enough', () {
      // 8 x 1536 x 1152 x 4 = 56.6 MiB. A canvas-width clamp bounds the decode
      // but still leaves the estate at 1.7x the ceiling, which is why the
      // budget is derived from the layer count instead.
      expect(
        personalHanokResidentBytes(
          layerCount: kPersonalHanokLayers.length,
          cacheWidth: kPersonalHanokCanvasWidth,
        ),
        greaterThan(kPersonalHanokDecodedMemoryMaxBytes),
      );
    });

    test('the budget width honours the ceiling and is maximal', () {
      for (final layerCount in <int>[
        1,
        2,
        4,
        kPersonalHanokLayers.length,
        17,
      ]) {
        final width = personalHanokDecodeBudgetWidth(layerCount);
        expect(
          personalHanokResidentBytes(
            layerCount: layerCount,
            cacheWidth: width,
          ),
          lessThanOrEqualTo(kPersonalHanokDecodedMemoryMaxBytes),
          reason: 'layerCount=$layerCount is over the ceiling at $width px',
        );
        if (width < kPersonalHanokCanvasWidth) {
          expect(
            personalHanokResidentBytes(
              layerCount: layerCount,
              cacheWidth: width + 1,
            ),
            greaterThan(kPersonalHanokDecodedMemoryMaxBytes),
            reason:
                'layerCount=$layerCount could have afforded ${width + 1} px',
          );
        }
      }
    });

    test('never decodes above the master canvas', () {
      expect(
        personalHanokDecodeCacheWidth(
          displayWidth: 4000,
          devicePixelRatio: 4,
          layerCount: 1,
        ),
        kPersonalHanokCanvasWidth,
      );
    });

    test('a small phone decodes at its own width, not a downscaled one', () {
      // 390dp x dpr 3 = 1170 px, under the 8-layer budget, so the request wins
      // and nothing is downscaled on the devices most learners are on.
      final width = personalHanokDecodeCacheWidth(
        displayWidth: 390,
        devicePixelRatio: 3,
        layerCount: kPersonalHanokLayers.length,
      );
      expect(width, 1170);
    });

    test('degenerate input falls back to the budget, never to zero', () {
      for (final pair in const <List<double>>[
        <double>[0, 3],
        <double>[-1, 3],
        <double>[390, 0],
        <double>[double.nan, 3],
        <double>[double.infinity, 3],
      ]) {
        expect(
          personalHanokDecodeCacheWidth(
            displayWidth: pair[0],
            devicePixelRatio: pair[1],
            layerCount: kPersonalHanokLayers.length,
          ),
          personalHanokDecodeBudgetWidth(kPersonalHanokLayers.length),
        );
      }
    });

    test('resident bytes are zero for an unpainted estate', () {
      expect(personalHanokResidentBytes(layerCount: 0), 0);
    });
  });
}
