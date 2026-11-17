import 'package:flutter/widgets.dart';

/// Independent user originals; provenance in C5_SCENE_ORIGINALS_20261030.json.
/// Optical regions remove empty authoring canvas at paint time, never source
/// pixels from the locked chrome/navigation originals.
abstract final class C5SceneAssets {
  static const root = 'assets/illustrations/concept_c/c5_scenes';
  static const book = '$root/book-scene.png';
  static const speaker = '$root/bronze-speaker.png';
  static const hangul = '$root/hangul-tiles.png';
  static const review = '$root/review-cards.png';
  static const syllables = '$root/syllable-scene.png';
  static const goldAction = '$root/gold-action.png';
  static const all = [book, speaker, hangul, review, syllables, goldAction];

  static const speakerRegion = Rect.fromLTRB(
    205 / 1312,
    125 / 1199,
    1140 / 1312,
    1080 / 1199,
  );
  static const hangulRegion = Rect.fromLTRB(
    145 / 1536,
    195 / 1024,
    1396 / 1536,
    900 / 1024,
  );
  static const reviewRegion = Rect.fromLTRB(
    170 / 1536,
    70 / 1024,
    1372 / 1536,
    968 / 1024,
  );
  static const goldRegion = Rect.fromLTRB(
    25 / 2117,
    155 / 743,
    2090 / 2117,
    580 / 743,
  );
}
