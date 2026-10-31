import 'package:flutter/material.dart';

import '../../services/mission_recommender.dart';
import 'c_gallery/c_materials.dart';

/// Content identity, rather than a translated title, owns Today artwork.
/// Original bytes and semantic checks: today-runtime-assets.json (2026-10-31).
abstract final class TodaySubjectArt {
  static const root = 'assets/illustrations/concept_c/today/';
  static const atlas = '${root}today-props.png';
  static const environments = '${root}today-environments.png';
  static const packAssets = <String, String>{
    'a1_sorry_thanks_1': '${root}sorry-thanks.png',
    'a1_repair_language_1': '${root}repair-language.png',
    'a1_transport': '${root}transport.png',
    'a2_restaurant_1': '${root}restaurant.png',
    'a2_partner_chuseok_basic_1': '${root}chuseok.png',
  };
  static const greetings = Rect.fromLTRB(3 / 1254, 191 / 1254, .5, 530 / 1254);
  static const review = Rect.fromLTRB(641 / 1254, 165 / 1254, 1, 541 / 1254);
  static const hangul = Rect.fromLTRB(3 / 1254, 807 / 1254, .5, 1085 / 1254);
  static const chest = Rect.fromLTRB(.5, 729 / 1254, 1248 / 1254, 1177 / 1254);

  static Widget forPick(MissionPick? pick) {
    final topic = pick is PackPick ? packAssets[pick.pack.id] : null;
    if (topic != null) {
      return Image.asset(
        topic,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      );
    }
    final region = switch (pick) {
      HangulIntroPick() => const Rect.fromLTRB(0, .58, .5, 1),
      ReviewPick() => const Rect.fromLTRB(.5, .08, 1, .5),
      CoursePick(:final unit) when unit.id == 'a1_01_greetings_hangul' =>
        const Rect.fromLTRB(0, .08, .5, .5),
      _ => null,
    };
    return region == null
        ? const CReferenceArt(CReferencePart.book)
        : CAtlasArt(path: environments, region: region);
  }
}
